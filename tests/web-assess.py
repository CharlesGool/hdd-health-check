#!/usr/bin/env python3
"""Validate server-side group and check selection for detached assessments."""
import importlib.util
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

root = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('hdd_web_server', root / 'web/server.py')
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)

disks = [
    {'name': 'sda', 'rotation': '1', 'transport': 'sata'},
    {'name': 'sdb', 'rotation': '0', 'transport': 'sata'},
    {'name': 'sdc', 'rotation': '1', 'transport': 'usb'},
    {'name': 'nvme0n1', 'rotation': '0', 'transport': 'nvme'},
]
expected = {
    'sata': ['sda', 'sdb'],
    'hdd': ['sda', 'sdc'],
    'ssd': ['sdb', 'nvme0n1'],
    'nvme': ['nvme0n1'],
    'all': ['sda', 'sdb', 'sdc', 'nvme0n1'],
}
with patch.object(app, 'snapshot', return_value={'disks': disks}), patch.object(app, 'script', return_value=SimpleNamespace(returncode=0, stdout='started', stderr='')) as run:
    for scope, names in expected.items():
        result = app.assess_disks(scope, 'full')
        args = run.call_args.args
        assert result['disks'] == names
        assert args[:4] == ('-d', ','.join(names), '-r', 'full')
        assert '--rescan' in args and '--detach' in args and '--no-install' in args
        assert ('--include-ssd' in args) == any(d['rotation'] == '0' for d in disks if d['name'] in names)
    try:
        app.assess_disks('unknown', 'full')
        assert False
    except ValueError:
        pass
    for module in app.SSD_MODULES:
        result = app.assess_disks('ssd', module)
        assert result['module'] == module
        assert run.call_args.args[2:4] == ('-r', module)
        assert '--include-ssd' in run.call_args.args
    for module in app.MODULES - app.SSD_MODULES:
        try:
            app.assess_disks('ssd', module)
            assert False
        except ValueError as exc:
            assert 'support this check' in str(exc)
        assert app.assess_disks('sata', module)['disks'] == ['sda']
        result = app.assess_disks('all', module)
        assert result['disks'] == ['sda', 'sdc']
        assert result['skipped'] == ['sdb', 'nvme0n1']
    assert app.assess_disks('hdd', 'speed')['module'] == 'speed'
    for module in app.SSD_MODULES:
        assert app.start_job('nvme0n1', module)['jobId']
    for module in app.MODULES - app.SSD_MODULES:
        try:
            app.start_job('nvme0n1', module)
            assert False
        except ValueError as exc:
            assert 'limited to HDDs' in str(exc)
    try:
        app.assess_disks('all', 'invalid')
        assert False
    except ValueError:
        pass
with patch.object(app, 'snapshot', return_value={'disks': disks}), patch.object(app, 'script', return_value=SimpleNamespace(returncode=1, stdout='', stderr='busy')):
    try:
        app.assess_disks('all', 'quick')
        assert False
    except RuntimeError as exc:
        assert str(exc) == 'busy'
with patch.object(app, 'snapshot', return_value={'disks': [disks[0]]}), patch.object(app, 'script') as run:
    try:
        app.assess_disks('nvme', 'full')
        assert False
    except ValueError as exc:
        assert 'No disks' in str(exc)
    run.assert_not_called()
print('web-assess: passed')
