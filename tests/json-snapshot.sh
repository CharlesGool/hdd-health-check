#!/usr/bin/env bash
# Synthetic state only; no block device or SMART command is invoked.
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT
export HDD_STATE_DIR="$test_dir/state" HDD_LOG_DIR="$test_dir/log"
mkdir -p "$HDD_STATE_DIR/mock" "$HDD_LOG_DIR"
# shellcheck disable=SC1090
source <(sed '/^#------------------------------ 参数解析 /,$d' src/checker/hdd-health-check.sh)
enumerate_disks() { :; }
prepare_disk() { :; }
DID[mock]=mock
D_NAME=(mock); D_MODEL=(synthetic); D_SIZE=(64MiB); D_ROTA=(1); D_TRAN=(sata)
json_snapshot > "$test_dir/empty.json"
python3 - "$test_dir/empty.json" <<'PY'
import json, sys
disk = json.load(open(sys.argv[1]))['disks'][0]
assert disk['score'] is None and disk['coverage'] == '未评估'
PY
begin_full_batch
CUR_DED=0; CUR_ISS=()
for module in quick selftest_short selftest_long speed surface; do
    save_result mock "$module" good 'quote " 中文'
done
surface_reset_vars
S_TOTAL=100; S_NEXT=100; S_DONE=1; S_CHUNK=64; S_SIZE=67108864
surface_write "$HDD_STATE_DIR/mock/surface.state"
save_result mock full good complete
json_snapshot > "$test_dir/full.json"
python3 - "$test_dir/full.json" <<'PY'
import json, sys
disk = json.load(open(sys.argv[1]))['disks'][0]
assert disk['score'] == 100 and disk['coverage'] == '完整'
assert len(disk['modules']) == 5 and all(item['current'] for item in disk['modules'])
assert disk['modules'][0]['summary'] == 'quote " 中文'
PY
RESULT_BATCH=other
save_result mock iface good repaired
json_snapshot > "$test_dir/after-interface.json"
python3 - "$test_dir/after-interface.json" <<'PY'
import json, sys
disk = json.load(open(sys.argv[1]))['disks'][0]
assert disk['score'] is None and not any(item['current'] for item in disk['modules'])
PY
echo 'json-snapshot: passed'
