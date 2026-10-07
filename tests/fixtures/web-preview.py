import importlib.util,threading,json,tempfile
from pathlib import Path
from http.server import ThreadingHTTPServer
r=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('hdd_preview',r/'src/web/server.py');app=importlib.util.module_from_spec(spec);spec.loader.exec_module(app)
# This runner has no scheduler or disk access; only static assets and session handlers.
temp=tempfile.TemporaryDirectory();app.STATE=Path(temp.name);app.SCHEDULE=app.STATE/'schedule.json';app.ACCESS=app.STATE/'access.json';app.PREFERENCES=app.STATE/'preferences.json'
app.public_snapshot=lambda:{'version':'4.1.0','disks':[]}
def disabled(*args, **kwargs):
    raise RuntimeError('Disk operations are disabled in the preview')
app.script = disabled
app.subprocess.run = disabled
app.subprocess.Popen = disabled
app.Handler.log_message = lambda *args: None
server=ThreadingHTTPServer(('127.0.0.1',0),app.Handler);server.password='synthetic-preview-password';server.password_file=None
print(server.server_port,flush=True)
server.serve_forever()
