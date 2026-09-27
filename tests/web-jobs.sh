#!/usr/bin/env bash
# Verify durable Web task receipts and explainable deductions without hardware.
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT
export HDD_STATE_DIR="$test_dir/state" HDD_LOG_DIR="$test_dir/log"
mkdir -p "$HDD_STATE_DIR/mock" "$HDD_LOG_DIR"
# shellcheck disable=SC1090
source <(sed '/^#------------------------------ 参数解析 /,$d' hdd-health-check.sh)
WEB_JOB_ID=0123456789abcdef01234567
WEB_JOB_STARTED=1700000000
REQ_DISKS=(nvme0n1 nvme1n1)
RUN_LIST=quick
LOG_FILE="$HDD_LOG_DIR/check.log"
job_write accepted
python3 - "$HDD_STATE_DIR/web-job.json" <<'PY'
import json,sys
job=json.load(open(sys.argv[1]))
assert job['state']=='accepted' and job['targets']=='nvme0n1 nvme1n1'
assert job['module']=='quick' and job['exitCode']==0
PY
job_finish 1
python3 - "$HDD_STATE_DIR/web-job.json" <<'PY'
import json,sys
job=json.load(open(sys.argv[1]))
assert job['state']=='completed' and job['exitCode']==1 and job['finished']>0
archive=json.load(open(sys.argv[1].replace('web-job.json','web-job-history/0123456789abcdef01234567.json')))
assert archive['state']=='completed' and archive['exitCode']==1
PY
job_finish 3
python3 - "$HDD_STATE_DIR/web-job.json" <<'PY'
import json,sys
job=json.load(open(sys.argv[1]))
assert job['state']=='failed' and job['exitCode']==3
PY
CUR_DED=5; CUR_ISS=()
save_result mock quick warn 无异常
load_result mock quick
[[ $R_STATUS == warn && $R_DEDUCT == 5 && $R_SUMMARY != 无异常 && -n $R_ISSUES ]]
I_PID=123; I_START=1699999900; I_MODE=systemd; I_TASK='批处理: short'; I_TARGETS='sda nvme0n1'; I_LOG="$LOG_FILE"
printf '%s\n' 'short self-test started' > "$I_LOG"
instance_alive() { return 0; }
prepare_disk() { echo 'unexpected SMART probe' >&2; return 1; }
brief=$(status_brief)
[[ $brief == *'sda nvme0n1'* && $brief == *'short self-test started'* ]]
echo 'web-jobs: passed'
