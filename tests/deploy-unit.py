#!/usr/bin/env python3
"""Validate systemd dependencies offline; never install or start a service."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
source = (root / 'deploy/hdd-health-web.service').read_text()
assert 'StateDirectoryMode=0700' in source and 'LogsDirectoryMode=0700' in source
assert 'After=network.target' in source
if shutil.which('systemd-analyze'):
    with tempfile.TemporaryDirectory() as directory:
        units = Path(directory)
        for name in ('basic.target', 'sysinit.target', 'network.target', 'shutdown.target'):
            (units / name).write_text('[Unit]\nDescription=Synthetic dependency\nDefaultDependencies=no\n')
        (units / 'multi-user.target').write_text('[Unit]\nDescription=Synthetic target\nWants=hdd-health-web.service\n')
        for name in ('system.slice', '-.slice'):
            (units / name).write_text('[Unit]\nDescription=Synthetic slice\nDefaultDependencies=no\n')
        (units / 'systemd-journald.socket').write_text('[Socket]\nListenStream=/tmp/synthetic-journal.sock\n')
        file = units / 'hdd-health-web.service'
        file.write_text(source)
        result = subprocess.run(['systemd-analyze', 'verify', '--man=no', '--generators=no', str(file), str(units / 'multi-user.target')],
                                env={**os.environ, 'SYSTEMD_UNIT_PATH': directory}, capture_output=True, text=True, timeout=15)
        assert result.returncode == 0, result.stderr
    print('deploy-unit: isolated systemd verification passed')
else:
    print('deploy-unit: dependency structure passed; systemd-analyze unavailable')
