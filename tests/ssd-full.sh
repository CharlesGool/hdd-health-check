#!/usr/bin/env bash
# Synthetic SSD assessment state; no physical device is opened.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export HDD_STATE_DIR="$tmp/state" HDD_LOG_DIR="$tmp/log"
mkdir -p "$HDD_STATE_DIR/ssd" "$HDD_LOG_DIR"
# shellcheck disable=SC1090
source <(sed '/^#------------------------------ 参数解析 /,$d' hdd-health-check.sh)
DID[ssd]=ssd; D_NAME=(ssd); D_MODEL=(synthetic); D_SIZE=(64MiB); D_ROTA=(0); D_TRAN=(nvme)
QUIET=1; PLAN_RECHECK=never
quick_one() { CUR_DED=0; CUR_ISS=(); save_result "${DID[$1]}" quick good 'SMART clear'; }

for errors in 0 1; do
    begin_full_batch
    quick_one ssd
    for module in selftest_short selftest_long; do
        CUR_DED=0; CUR_ISS=()
        save_result ssd "$module" good 'SMART self-test complete'
    done
    surface_reset_vars
    S_TOTAL=10; S_NEXT=10; S_DONE=1; S_CHUNK=64; S_SIZE=67108864
    S_OK=8; S_SLOW=1; S_VSLOW=1; S_ERR=$errors; S_ELAPSED=100
    surface_write "$HDD_STATE_DIR/ssd/surface.state"
    surface_finalize ssd
    load_result ssd surface
    [[ $R_DEDUCT == $((errors*40)) ]]
    finish_full_batch ssd
    [[ -f $HDD_STATE_DIR/ssd/full.env ]]
    [[ ! -f $HDD_STATE_DIR/ssd/speed.env ]]
    compute_overall ssd
    [[ $OV_COVER == 完整 && $OV_SCORE == $((100-errors*40)) ]]
done
printf '%s\n' 'ssd-full: passed'
