#!/usr/bin/env bash
# Synthetic speed readings and saved results; never opens a block device.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export HDD_STATE_DIR="$tmp/state" HDD_LOG_DIR="$tmp/log"
mkdir -p "$HDD_STATE_DIR/mock" "$HDD_LOG_DIR" "$tmp/run"
# shellcheck disable=SC1090
source <(sed '/^#------------------------------ 参数解析 /,$d' src/checker/hdd-health-check.sh)
DID[mock]=mock; D_NAME=(mock); D_MODEL=(synthetic); D_SIZE=(8MiB); D_ROTA=(0); D_TRAN=(nvme)
QUIET=1; RUN_DIR="$tmp/run"; SAMPLE_POINTS=4; SAMPLE_MB=1
now() { echo 1700000000; }
di() { echo 0; }
blockdev() { echo 8388608; }
lsblk() { :; }
read_number=0; inject_read_error=0
read_mib() {
    read_number=$((read_number+1))
    RD_OK=1; RD_KBS=10000
    (( read_number == 2 || read_number == 5 )) && RD_KBS=1000
    if (( inject_read_error && read_number == 2 )); then RD_OK=0; RD_KBS=0; fi
    return 0
}
set +e
speed_one mock
set -e
load_result mock speed
[[ $R_STATUS == good && $R_DEDUCT == 0 && -z $R_ISSUES ]]
[[ $R_SUMMARY == *'采样波动 1 处'* ]]
read_number=0; inject_read_error=1
set +e
speed_one mock
set -e
load_result mock speed
[[ $R_STATUS == bad && $R_DEDUCT == 30 && $R_ISSUES == '采样点读取出错 1' ]]
# An earlier SSD result with only speed dips becomes informational in both
# overall scoring and the JSON snapshot, without rewriting its saved record.
CUR_DED=20; CUR_ISS=('速度凹陷 4 处')
save_result mock speed warn '峰值 500 / 平均 300 MB/s，凹陷 4 处'
compute_overall mock
[[ ${#OV_ISS[@]} == 0 && $OV_ROWS[0] == *'|0|峰值 500 / 平均 300 MB/s，采样波动 4 处'* ]]
enumerate_disks() { :; }
prepare_disk() { :; }
json_snapshot | python3 -c 'import json,sys; d=json.load(sys.stdin)["disks"][0]; m=d["modules"][0]; assert m["status"]=="good" and m["deduction"]==0 and m["issues"]==""'
load_result mock speed
[[ $R_STATUS == warn && $R_DEDUCT == 20 ]] # The saved record is untouched.
# Genuine read failures remain visible and keep their 30-point penalty.
CUR_DED=50; CUR_ISS=('采样点读取出错 1' '速度凹陷 4 处')
save_result mock speed bad '读取失败并有速度波动'
load_result mock speed; normalize_ssd_speed_result mock
[[ $R_STATUS == bad && $R_DEDUCT == 30 && $R_ISSUES == '采样点读取出错 1' ]]
# A rotational disk retains the original speed-dip scoring.
D_ROTA=(1)
CUR_DED=20; CUR_ISS=('速度凹陷 4 处')
save_result mock speed warn '凹陷 4 处'
load_result mock speed; normalize_ssd_speed_result mock
[[ $R_STATUS == warn && $R_DEDUCT == 20 && $R_ISSUES == '速度凹陷 4 处' ]]
echo 'speed-ssd: passed'
