#!/usr/bin/env python3
"""Check parallel login limits and Unicode passwords without disk access."""
import importlib.util
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

root = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('hdd_web_rate_limit', root / 'src/web/server.py')
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)

app.login_attempts.clear()
with ThreadPoolExecutor(max_workers=32) as pool:
    verdicts = list(pool.map(lambda _: app.verify_password_attempt('test-ip', 'bad', 'secret', now=1000), range(64)))
assert verdicts.count(401) == 10 and verdicts.count(429) == 54
assert len(app.login_attempts['test-ip']) == 10
assert app.verify_password_attempt('test-ip', 'secret', 'secret', now=1600) == 200
assert not app.login_attempts
assert app.verify_password_attempt('unicode', '磁盘密码 🔒', '磁盘密码 🔒', now=2000) == 200
assert app.verify_password_attempt('unicode', '错误密码', '磁盘密码 🔒', now=2000) == 401
assert app.verify_password_attempt('unicode', None, '磁盘密码 🔒', now=2000) == 401
app.login_attempts = {str(i): [2000] for i in range(4096)}
assert app.verify_password_attempt('new', 'bad', 'secret', now=2001) == 429
assert len(app.login_attempts) == 4096
assert app.verify_password_attempt('new', 'secret', 'secret', now=2001) == 200
assert app.verify_password_attempt('new', 'bad', 'secret', now=2600) == 401
assert len(app.login_attempts) == 1
print('web-rate-limit: passed')
