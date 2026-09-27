#!/usr/bin/env python3
"""Validate task receipt, log tail and missing-worker visibility."""
import importlib.util
import json
from pathlib import Path
import tempfile
import time
from unittest.mock import patch

root = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('hdd_web_server', root / 'web/server.py')
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)

with tempfile.TemporaryDirectory() as directory:
    base = Path(directory)
    state, logs = base / 'state', base / 'logs'
    state.mkdir(); logs.mkdir()
    log = logs / 'check.log'
    log.write_text('started\ncompleted with attention\n')
    receipt = state / 'web-job.json'
    job = {'id': '0123456789abcdef01234567', 'state': 'completed', 'module': 'quick',
           'targets': 'nvme0n1 nvme1n1', 'started': int(time.time()) - 5,
           'finished': int(time.time()), 'exitCode': 1, 'log': str(log)}
    with patch.object(app, 'STATE', state), patch.object(app, 'LOG_DIR', logs):
        receipt.write_text(json.dumps(job))
        result = app.web_job(False)
        assert result is None and not receipt.exists()
        archived = state / 'web-job-history' / (job['id'] + '.json')
        assert archived.is_file()
        assert app.web_job_history()[0]['id'] == job['id']
        assert app.web_job_history()[0]['exitCode'] == 1
        (state / 'web-job-history' / 'invalid.json').write_text('{')
        assert len(app.web_job_history()) == 1
        job.update(state='accepted', started=int(time.time()) - 30, finished=0)
        receipt.write_text(json.dumps(job))
        assert app.web_job(False) is None and not receipt.exists()
        receipt.write_text(json.dumps(job))
        running = app.web_job(True)
        assert running['state'] == 'accepted' and 'completed with attention' in running['output']
        receipt.write_text('invalid')
        assert app.web_job(False) is None
print('web-jobs: passed')
