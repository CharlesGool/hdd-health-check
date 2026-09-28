#!/usr/bin/env python3
"""Verify unified SMART samples and deletions without touching disks."""
import importlib.util
import json
from pathlib import Path
import tempfile
from unittest.mock import patch

root = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('hdd_web_server', root / 'web/server.py')
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)

with tempfile.TemporaryDirectory() as directory:
    base = Path(directory)
    state = base / 'state'
    logs = base / 'logs'
    (state / 'disk-a').mkdir(parents=True)
    (state / 'web-job-history').mkdir()
    logs.mkdir()
    history = state / 'disk-a/history.csv'
    history.write_text('100,1,0,0,0,0,0,40,0\n200,1,2,0,0,0,0,41,0\n')
    job_id = 'a' * 24
    record = state / 'web-job-history' / (job_id + '.json')
    logfile = logs / 'job.log'
    logfile.write_text('example')
    record.write_text(json.dumps({'id': job_id, 'state': 'completed', 'module': 'quick', 'targets': 'sda', 'started': 100, 'finished': 200, 'exitCode': 0, 'log': str(logfile)}))
    with patch.object(app, 'STATE', state), patch.object(app, 'LOG_DIR', logs), patch.object(app, 'web_snapshot', return_value={'disks': [{'name': 'sda', 'id': 'disk-a'}]}):
        assert [sample['values'][0] for sample in app.smart_history_samples()] == [200, 100]
        assert len(app.web_job_history()) == 1
        app.delete_smart_sample('sda', '0')
        assert history.read_text().startswith('200,1,2')
        app.delete_web_job(job_id)
        assert not record.exists() and not logfile.exists()
        assert app.web_job_history() == []
print('web-history: passed')
