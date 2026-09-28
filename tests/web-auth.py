#!/usr/bin/env python3
"""Exercise Web sessions and exact-IP access without touching disks."""

import http.client
import importlib.util
import json
import os
from pathlib import Path
import socket
import tempfile
import time
import threading
from http.server import ThreadingHTTPServer
from unittest.mock import patch

root = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('hdd_web_server', root / 'src/web/server.py')
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)

with tempfile.TemporaryDirectory() as directory:
    app.STATE = Path(directory)
    app.SCHEDULE = app.STATE / 'web-schedule.json'
    app.ACCESS = app.STATE / 'web-access.json'
    app.PREFERENCES = app.STATE / 'web-preferences.json'
    app.sessions.clear()
    server = ThreadingHTTPServer(('0.0.0.0', 0), app.Handler)
    server.password = 'test-password'
    server.password_file = app.STATE / 'web-password'
    server.password_file.write_text(server.password + '\n')
    os.chmod(server.password_file, 0o600)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    port = server.server_port

    def request(method, path, *, body=None, cookie=None, host=None, origin=None, connect_host='127.0.0.1', extra=None, csrf=True):
        connection = http.client.HTTPConnection(connect_host, port, timeout=3)
        connection.putrequest(method, path, skip_host=True)
        connection.putheader('Host', host or f'{connect_host}:{port}')
        if origin is not None:
            connection.putheader('Origin', origin)
        if cookie:
            connection.putheader('Cookie', cookie)
        if csrf and method in ('POST', 'DELETE'):
            connection.putheader('X-HDD-CSRF', '1')
        for key, value in (extra or {}).items():
            connection.putheader(key, value)
        payload = json.dumps(body or {}).encode() if method == 'POST' else None
        if payload is not None:
            connection.putheader('Content-Type', 'application/json')
            connection.putheader('Content-Length', str(len(payload)))
        connection.endheaders(payload)
        response = connection.getresponse()
        status = response.status
        headers = response.getheaders()
        raw = response.read()
        connection.close()
        data = json.loads(raw) if dict(headers).get('Content-Type', '').startswith('application/json') else raw
        return status, headers, data

    try:
        assert request('GET', '/')[0] == 200
        for route in ('/disks', '/attention', '/tasks', '/schedule', '/settings', '/security', '/changelog', '/attention/nvme0n1'):
            assert request('GET', route)[0] == 200, route
        status, headers, data = request('GET', '/api/schedule')
        assert status == 401 and not any(k.lower() == 'www-authenticate' for k, _ in headers)
        assert request('GET', '/api/auth')[2]['authenticated'] is False
        assert request('POST', '/api/auth/login', body={'password': 'bad'}, csrf=False)[0] == 403
        assert request('POST', '/api/auth/login', body={'password': 'bad'})[0] == 401
        status, headers, data = request('POST', '/api/auth/login', body={'password': 'test-password'})
        assert status == 200 and data['method'] == 'password' and data['canManageAccess'] is True
        cookie = next(v.split(';')[0] for k, v in headers if k.lower() == 'set-cookie' and v.startswith('hdd_session='))
        assert request('GET', '/api/schedule', cookie=cookie)[0] == 200
        assert request('GET', '/api/build', cookie=cookie)[2] == json.loads((app.ASSETS / 'version.json').read_text())
        with patch.object(app, 'lsblk_details', return_value={'sda': {'serial': 'SERIAL123456'}}):
            assert request('GET', '/api/disks/sda/serial')[0] == 401
            assert request('GET', '/api/disks/sda/serial', cookie=cookie)[2] == {'serial': 'SERIAL123456'}
            assert request('GET', '/api/disks/sdb/serial', cookie=cookie)[0] == 404
        with patch.object(app, 'script', return_value=type('Result', (), {'returncode': 0, 'stdout': '  没有正在运行的实例\n', 'stderr': ''})()), patch.object(app, 'web_job', return_value={'state': 'completed', 'exitCode': 1}) as latest:
            task_status = request('GET', '/api/status', cookie=cookie)[2]
            assert task_status['running'] is False and task_status['job']['state'] == 'completed'
            latest.assert_called_once_with(False)
        assert request('POST', '/api/jobs/assess', body={'scope': 'all', 'module': 'quick'})[0] == 401
        with patch.object(app, 'assess_disks', return_value={'message': 'started', 'disks': ['sda'], 'scope': 'all', 'module': 'quick'}) as assess:
            assert request('POST', '/api/jobs/assess', body={'scope': 'all', 'module': 'quick'}, cookie=cookie)[2]['disks'] == ['sda']
            assess.assert_called_once_with('all', 'quick')
        assert request('GET', '/api/access', cookie=cookie)[2]['ips'] == []
        assert request('GET', '/api/preferences', cookie=cookie)[2] == {'wakeSleepingOnVisit': False}
        assert request('POST', '/api/preferences', body={'wakeSleepingOnVisit': 'yes'}, cookie=cookie)[0] == 400
        assert request('POST', '/api/preferences', body={'wakeSleepingOnVisit': True}, cookie=cookie)[2] == {'wakeSleepingOnVisit': True}
        assert request('GET', '/api/preferences', cookie=cookie)[2]['wakeSleepingOnVisit'] is True
        with patch.object(app, 'start_wake_on_visit', return_value={'started': True}) as wake:
            assert request('POST', '/api/disks/wake-on-visit', cookie=cookie)[2]['started'] is True
            wake.assert_called_once_with()
        assert request('POST', '/api/disks/sdb/wake')[0] == 401
        assert request('POST', '/api/disks/sdb/sleep')[0] == 401
        assert request('DELETE', '/api/jobs/history/' + 'a' * 24)[0] == 401
        assert request('DELETE', '/api/history/samples/sdb/0')[0] == 401
        with patch.object(app, 'wake_disk', return_value={'started': True, 'reason': 'woken'}) as wake:
            assert request('POST', '/api/disks/sdb/wake', cookie=cookie)[2]['reason'] == 'woken'
            wake.assert_called_once_with('sdb')
        with patch.object(app, 'sleep_disk', return_value={'requested': True}) as standby:
            assert request('POST', '/api/disks/sdb/sleep', cookie=cookie)[2]['requested'] is True
            standby.assert_called_once_with('sdb')
        with patch.object(app, 'delete_web_job') as delete_job:
            assert request('DELETE', '/api/jobs/history/' + 'a' * 24, cookie=cookie)[2]['deleted'] is True
            delete_job.assert_called_once()
        with patch.object(app, 'delete_smart_sample') as delete_sample:
            assert request('DELETE', '/api/history/samples/sdb/0', cookie=cookie)[2]['deleted'] is True
            delete_sample.assert_called_once_with('sdb', '0')
        assert request('POST', '/api/auth/change-password', body={'newPassword': 'a-new-password-123', 'confirmPassword': 'mismatch'}, cookie=cookie)[0] == 400
        assert request('POST', '/api/auth/change-password', body={'newPassword': 'short', 'confirmPassword': 'short'}, cookie=cookie)[0] == 400
        status, headers, changed = request('POST', '/api/auth/change-password', body={'newPassword': 'a-new-password-123', 'confirmPassword': 'a-new-password-123'}, cookie=cookie)
        assert status == 200 and changed['changed'] is True
        assert server.password_file.read_text() == 'a-new-password-123\n'
        assert server.password_file.stat().st_mode & 0o777 == 0o600
        assert request('GET', '/api/schedule', cookie=cookie)[0] == 401
        assert request('POST', '/api/auth/login', body={'password': 'test-password'})[0] == 401
        status, headers, _ = request('POST', '/api/auth/login', body={'password': 'a-new-password-123'})
        assert status == 200
        cookie = next(v.split(';')[0] for k, v in headers if k.lower() == 'set-cookie' and v.startswith('hdd_session='))
        assert request('POST', '/api/access', body={'enabled': True, 'ips': ['192.168.1.10']}, cookie=cookie)[2]['ips'] == ['192.168.1.10']
        assert request('POST', '/api/access', body={'enabled': True, 'ips': ['192.168.1.0/24']}, cookie=cookie)[0] == 400
        for forbidden in ('8.8.8.8', '100.64.1.2', '127.0.0.1', '127.42.0.1', '::1', '::ffff:127.0.0.1', 'localhost', '169.254.1.1', '2001:4860::1'):
            assert request('POST', '/api/access', body={'enabled': True, 'ips': [forbidden]}, cookie=cookie)[0] == 400
        assert request('POST', '/api/access', body={'enabled': True, 'ips': ['fd00::abcd']}, cookie=cookie)[2]['ips'] == ['fd00::abcd']
        assert request('POST', '/api/access', body={'enabled': False, 'ips': ['192.168.1.10']}, cookie=cookie)[2]['enabled'] is False
        assert request('GET', '/api/access', cookie=cookie)[2]['ips'] == ['192.168.1.10']
        assert request('POST', '/api/access', body={'enabled': True, 'ips': ['192.168.1.10']}, cookie=cookie)[0] == 200
        app.ACCESS.write_text(json.dumps({'enabled': True, 'ips': ['8.8.8.8', '192.168.1.10']}))
        assert request('GET', '/api/access', cookie=cookie)[2]['ips'] == ['192.168.1.10']
        assert request('POST', '/api/access', body={'enabled': True, 'ips': ['192.168.1.10']}, cookie=cookie)[0] == 200
        assert request('GET', '/api/access')[0] == 401
        assert request('GET', '/api/schedule', cookie=cookie, host=f'other.invalid:{port}')[0] == 403
        assert request('POST', '/api/access', body={'enabled': False, 'ips': []}, cookie=cookie, origin='http://other.invalid')[0] == 403
        assert request('POST', '/api/auth/logout', cookie=cookie)[0] == 200
        assert request('GET', '/api/schedule', cookie=cookie)[0] == 401
        try:
            route = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            route.connect(('1.1.1.1', 80))
            lan_ip = route.getsockname()[0]
            route.close()
        except OSError:
            lan_ip = None
        if lan_ip and not lan_ip.startswith('127.'):
            assert request('GET', '/api/schedule', connect_host=lan_ip, extra={'X-Forwarded-For': '192.168.1.10'})[0] == 401
            status, headers, _ = request('POST', '/api/auth/login', body={'password': 'a-new-password-123'}, connect_host=lan_ip)
            lan_cookie = next(v.split(';')[0] for k, v in headers if k.lower() == 'set-cookie' and v.startswith('hdd_session='))
            assert status == 200
            assert request('POST', '/api/access', body={'enabled': True, 'ips': [lan_ip]}, cookie=lan_cookie, connect_host=lan_ip)[0] == 200
            assert request('GET', '/api/schedule', connect_host=lan_ip)[0] == 200
            assert request('GET', '/api/access', connect_host='127.0.0.1', extra={'X-Forwarded-For': lan_ip})[0] == 401
            assert request('GET', '/api/access', connect_host=lan_ip)[0] == 403
            assert request('POST', '/api/access', body={'enabled': True, 'ips': [lan_ip]}, connect_host=lan_ip)[0] == 403
            assert request('GET', '/api/preferences', connect_host=lan_ip)[2]['wakeSleepingOnVisit'] is True
            assert request('POST', '/api/preferences', body={'wakeSleepingOnVisit': False}, connect_host=lan_ip)[0] == 200
            assert request('POST', '/api/auth/change-password', body={'newPassword': 'another-password-123', 'confirmPassword': 'another-password-123'}, connect_host=lan_ip)[0] == 403
            assert request('POST', '/api/auth/security-verify', body={'password': 'wrong'}, connect_host=lan_ip)[0] == 401
            status, verified_headers, _ = request('POST', '/api/auth/security-verify', body={'password': 'a-new-password-123'}, connect_host=lan_ip)
            assert status == 200
            verified_cookie = next(v.split(';')[0] for k, v in verified_headers if k.lower() == 'set-cookie' and v.startswith('hdd_session='))
            assert request('GET', '/api/access', cookie=verified_cookie, connect_host=lan_ip)[0] == 200
            token = verified_cookie.split('=', 1)[1]
            with app.session_lock:
                app.sessions[token]['security_until'] = time.time() - 1
            assert request('GET', '/api/access', cookie=verified_cookie, connect_host=lan_ip)[0] == 403
            assert request('POST', '/api/auth/change-password', body={'newPassword': 'another-password-123', 'confirmPassword': 'another-password-123'}, cookie=verified_cookie, connect_host=lan_ip)[0] == 403
            status, verified_headers, _ = request('POST', '/api/auth/security-verify', body={'password': 'a-new-password-123'}, cookie=verified_cookie, connect_host=lan_ip)
            assert status == 200
            renewed_cookie = next(v.split(';')[0] for k, v in verified_headers if k.lower() == 'set-cookie' and v.startswith('hdd_session='))
            assert renewed_cookie != verified_cookie
            assert request('GET', '/api/access', cookie=verified_cookie, connect_host=lan_ip)[0] == 403
            assert request('POST', '/api/auth/change-password', body={'newPassword': 'another-password-123', 'confirmPassword': 'another-password-123'}, cookie=renewed_cookie, connect_host=lan_ip)[0] == 200
            assert server.password_file.read_text() == 'another-password-123\n'
            status, headers, _ = request('POST', '/api/auth/logout', connect_host=lan_ip)
            logout_cookie = next(v.split(';')[0] for k, v in headers if k.lower() == 'set-cookie' and v.startswith('hdd_logout='))
            assert status == 200
            assert request('GET', '/api/schedule', cookie=logout_cookie, connect_host=lan_ip)[0] == 401
            assert request('POST', '/api/auth/ip-login', cookie=logout_cookie, connect_host=lan_ip)[0] == 200
    finally:
        server.shutdown()
        server.server_close()

print('web-auth: passed')
