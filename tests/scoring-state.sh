#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2154
# Synthetic state only; never enumerates or reads a physical device.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
export HDD_STATE_DIR="$tmp/state" HDD_LOG_DIR="$tmp/log"
mkdir -p "$HDD_STATE_DIR/mock" "$HDD_LOG_DIR"
# Source definitions only, before CLI/bootstrap/hardware logic.
# shellcheck disable=SC1090
source <(sed '/^#------------------------------ 参数解析 /,$d' hdd-health-check.sh)
DID[mock]=mock; D_NAME=(mock); D_MODEL=(synthetic); D_SIZE=(64MiB)
DOPT_CACHE[mock]=''; QUIET=1; PLAN_RECHECK=never
# A firmware log must contain a newly completed entry for this launched test.
if selftest_new_record '# 1 Short Completed without error' '# 1 Short Completed without error'; then exit 1; fi
if selftest_new_record '' '# 1 Short Completed without error'; then exit 1; fi
selftest_new_record '# 1 Short Completed without error' '# 1 Short Aborted'
id=mock
CUR_DED=0; CUR_ISS=()
# Legacy state without a batch must never be a complete current 100.
for m in quick selftest_long surface; do save_result "$id" "$m" good old; done
compute_overall mock
[[ $OV_COVER != 完整 && $OV_SCORE == - ]]
# Consistent new batch, with a completed scan, earns a current score.
begin_full_batch
for m in quick selftest_short selftest_long speed surface; do save_result "$id" "$m" good synthetic; done
surface_reset_vars
S_TOTAL=100; S_NEXT=100; S_DONE=1; S_CHUNK=64; S_SIZE=67108864
surface_write "$HDD_STATE_DIR/$id/surface.state"
CUR_DED=0; CUR_ISS=(); save_result "$id" full good complete
compute_overall mock
[[ $OV_COVER == 完整 && $OV_SCORE == 100 ]]
# Every mandatory measurement and the full marker must remain valid.
for m in quick selftest_short selftest_long speed surface; do
    for status in incomplete bad old; do
        cp "$HDD_STATE_DIR/$id/$m.env" "$tmp/$m.env"
        if [[ $status == old ]]; then
            sed -i 's/^R_BATCH=.*/R_BATCH=other/' "$HDD_STATE_DIR/$id/$m.env"
        elif [[ $status == incomplete ]]; then
            sed -i 's/^R_STATUS=.*/R_STATUS=incomplete/' "$HDD_STATE_DIR/$id/$m.env"
        else
            sed -i 's/^R_TS=.*/R_TS=1/' "$HDD_STATE_DIR/$id/$m.env"
        fi
        compute_overall mock
        [[ $OV_SCORE == - && $OV_COVER != 完整 ]]
        mv "$tmp/$m.env" "$HDD_STATE_DIR/$id/$m.env"
    done
    mv "$HDD_STATE_DIR/$id/$m.env" "$tmp/$m.env"
    compute_overall mock
    [[ $OV_SCORE == - && $OV_COVER != 完整 ]]
    mv "$tmp/$m.env" "$HDD_STATE_DIR/$id/$m.env"
    cp "$HDD_STATE_DIR/$id/$m.env" "$tmp/$m.env"
    sed -i 's/^R_STATUS=.*/R_STATUS=bad/' "$HDD_STATE_DIR/$id/$m.env"
    compute_overall mock
    [[ $OV_SCORE == - && $OV_COVER != 完整 ]]
    mv "$tmp/$m.env" "$HDD_STATE_DIR/$id/$m.env"
done
cp "$HDD_STATE_DIR/$id/full.env" "$tmp/full.env"
sed -i 's/^R_STATUS=.*/R_STATUS=incomplete/' "$HDD_STATE_DIR/$id/full.env"
compute_overall mock
[[ $OV_SCORE == - && $OV_COVER != 完整 ]]
mv "$tmp/full.env" "$HDD_STATE_DIR/$id/full.env"
cp "$HDD_STATE_DIR/$id/full.env" "$tmp/full.env"
sed -i 's/^R_TS=.*/R_TS=1/' "$HDD_STATE_DIR/$id/full.env"
compute_overall mock
[[ $OV_SCORE == - && $OV_COVER != 完整 ]]
mv "$tmp/full.env" "$HDD_STATE_DIR/$id/full.env"
cp "$HDD_STATE_DIR/$id/surface.state" "$tmp/surface.state"
S_DONE=0; surface_write "$HDD_STATE_DIR/$id/surface.state"
compute_overall mock
[[ $OV_SCORE == - && $OV_COVER != 完整 ]]
mv "$tmp/surface.state" "$HDD_STATE_DIR/$id/surface.state"
# Viewing a report is read-only with respect to the result files.
before=$(find "$HDD_STATE_DIR/$id" -type f -name '*.env' -exec sha256sum {} + | sort)
mod_report mock
[[ $(find "$HDD_STATE_DIR/$id" -type f -name '*.env' -exec sha256sum {} + | sort) == "$before" ]]
# An interface verification after full invalidates the old snapshot; verification
# before the full run does not get charged again in that full run.
RESULT_BATCH=other; CUR_DED=0; CUR_ISS=()
RES_TS=1700000001; save_result "$id" iface good resolved
compute_overall mock
[[ $OV_SCORE == - && $OV_COVER != 完整 ]]
rm "$HDD_STATE_DIR/$id/iface.env"
RESULT_BATCH=$FULL_BATCH
# A running, interrupted, stale, legacy or mismatched result cannot fill a new batch.
CUR_DED=0; CUR_ISS=(); RESULT_BATCH=other; save_result "$id" surface running paused
compute_overall mock
[[ $OV_COVER != 完整 && $OV_SCORE == - ]]
RESULT_BATCH=$FULL_BATCH
CUR_DED=20; CUR_ISS=('read error'); save_result "$id" surface bad 'read error'
compute_overall mock
[[ $OV_COVER == 完整 && $OV_SCORE == 80 ]]
# No batch marker: historical evidence stays visible, but is not a healthy current score.
rm "$HDD_STATE_DIR/$id/full.env"
compute_overall mock
[[ $OV_SCORE == - && $OV_COVER != 完整 && ${#OV_ROWS[@]} -gt 0 ]]
# Synthetic SMART counters: baseline, steady historical ATA, scan-time ATA/CRC,
# and current pending sectors. Nothing here calls smartctl or a block device.
now() { echo 1700000000; }
di() { echo 0; }
mount_check() { :; }
klog_check() { :; }
sm() {
    case "$2" in
        -i) printf 'Device Model: synthetic\nSMART support is: Enabled\n' ;;
        -H) echo 'SMART overall-health self-assessment test result: PASSED' ;;
        -A) printf '197 Current_Pending_Sector 0x0032 100 100 000 Old_age Always - %s\n199 UDMA_CRC_Error_Count 0x003e 200 200 000 Old_age Always - %s\n' "${pending:-0}" "${crc:-16}" ;;
        -l) case "$3" in error) printf '%s\n' "${error_log-ATA Error Count: ${ata:-16}}" ;; selftest) printf '%s\n' "${selftest_log:-No self-tests have been logged}" ;; esac ;;
        -t) [[ ${start_ok:-1} == 1 ]] ;;
    esac
}
RESULT_BATCH=new; ata=16; crc=16; pending=0
set +e  # optional SMART fields are probed with grep; absence is expected
quick_one mock
load_result mock quick
[[ $R_ATA == 16 && $R_DEDUCT -ge 5 ]] || exit 1
quick_one mock
load_result mock quick
[[ $R_DEDUCT -ge 5 && $R_ISSUES == *ATA* ]] || exit 1
RESULT_BATCH=another_run
quick_one mock
load_result mock quick
[[ $R_DEDUCT -ge 5 && $R_ATA_PENDING == 1 ]] || exit 1
RESULT_BATCH=new
# Legacy quick result without the unresolved-risk field is conservatively retained.
sed -i '/^R_ATA_PENDING=/d' "$HDD_STATE_DIR/$id/quick.env"
quick_one mock
load_result mock quick
[[ $R_DEDUCT -ge 5 && $R_ISSUES == *ATA* ]] || exit 1
# A later good interface check does not establish attribution of old ATA errors.
CUR_DED=0; CUR_ISS=(); save_result mock iface good resolved
quick_one mock
load_result mock quick
[[ $R_DEDUCT -ge 5 && $R_ATA_PENDING == 1 ]] || exit 1
ata=17; crc=17; quick_one mock
load_result mock quick
[[ $R_DEDUCT -ge 20 && $R_ISSUES == *ATA* && $R_ISSUES == *CRC* ]] || exit 1
[[ $R_ATA_PENDING == 1 && $R_DEDUCT -ge 25 ]] || exit 1
# A cleared, missing or malformed log cannot erase a trusted count or its warning.
for error_log in 'No Errors Logged' '' 'malformed output'; do
    quick_one mock
    load_result mock quick
    [[ $R_ATA == 17 && $R_ATA_PENDING == 1 && $R_DEDUCT -ge 5 && $R_ISSUES == *ATA* ]] || exit 1
done
error_log='ATA Error Count: 16'; quick_one mock
load_result mock quick
[[ $R_ATA == 17 && $R_ATA_PENDING == 1 && $R_ISSUES == *ATA* ]] || exit 1
error_log='ATA Error Count: 17'; quick_one mock
load_result mock quick
[[ $R_ATA == 17 && $R_ATA_PENDING == 1 ]] || exit 1
# Unreadable new-device logs must not appear to have verified ATA health.
cp "$HDD_STATE_DIR/$id/quick.env" "$tmp/pending-quick.env"
rm "$HDD_STATE_DIR/$id/quick.env"
error_log=''; quick_one mock
load_result mock quick
[[ -z $R_ATA && $R_ISSUES == *ATA* && $R_DEDUCT -gt 0 ]] || exit 1
error_log='No Errors Logged'; quick_one mock
load_result mock quick
[[ $R_ATA == 0 && $R_ATA_PENDING == 0 && $R_ISSUES != *ATA* ]] || exit 1
mv "$tmp/pending-quick.env" "$HDD_STATE_DIR/$id/quick.env"
error_log='ATA Error Count: 17'; quick_one mock
pending=1; quick_one mock
load_result mock quick
[[ $R_DEDUCT -ge 30 && $R_ISSUES == *待映射* ]] || exit 1
# The final quick probe in a complete assessment must retain unknown ATA risk.
rm "$HDD_STATE_DIR/$id/iface.env"
pending=0; ata=16; crc=16
begin_full_batch
for m in selftest_short selftest_long speed surface; do
    CUR_DED=0; CUR_ISS=(); save_result mock "$m" good synthetic
done
surface_reset_vars
S_TOTAL=100; S_NEXT=100; S_DONE=1; S_CHUNK=64; S_SIZE=67108864
surface_write "$HDD_STATE_DIR/$id/surface.state"
finish_full_batch mock
compute_overall mock
[[ $OV_COVER == 完整 && $OV_SCORE -le 95 ]] || exit 1
# Sparse latency is a performance hint; genuine read error remains severe.
RESULT_BATCH=new; surface_reset_vars
S_TOTAL=1000; S_NEXT=1000; S_DONE=1; S_SIZE=67108864000; S_CHUNK=64
S_VSLOW=1; S_SLOW=30; S_ERR=0; S_ELAPSED=500
surface_write "$HDD_STATE_DIR/$id/surface.state"
surface_finalize mock
load_result mock surface
[[ $R_DEDUCT -lt 15 && $R_ISSUES != *弱扇区* ]] || exit 1
S_ERR=1; surface_write "$HDD_STATE_DIR/$id/surface.state"
surface_finalize mock
load_result mock surface
[[ $R_DEDUCT -ge 40 && $R_ISSUES == *读错误* ]] || exit 1
# Mock a newly launched firmware test and its first matching completed record.
selftest_monitor() { MON_RESULT='done'; }
sleep() { :; }
get_poh() { echo 100; }
decide_run() { :; }
dec_note() { return 0; }
RESULT_BATCH=first; BATCH=1; INTERRUPTED=0
selftest_log='No self-tests have been logged'
selftest_running() { return 1; }
start_ok=1
sm() {
    case "$2" in
        -l) [[ $3 == selftest ]] && printf '%s\n' "$selftest_log" ;;
        -t) [[ $start_ok == 1 ]] || return 1
            selftest_log=${next_selftest_log-'# 1 Extended offline Completed without error 00% 100 -'} ;;
    esac
}
mod_selftest long 0 mock
load_result mock selftest_long
[[ $R_STATUS == good ]] || exit 1
# A pre-existing matching record, or another test type, is not new evidence.
selftest_log='# 1 Extended offline Completed without error 00% 100 -'
mod_selftest long 0 mock
load_result mock selftest_long
[[ $R_STATUS == incomplete ]] || exit 1
selftest_log='# 1 Short offline Completed without error 00% 100 -'
next_selftest_log='# 1 Short offline Completed without error 00% 101 -'
mod_selftest long 0 mock
load_result mock selftest_long
[[ $R_STATUS == incomplete ]] || exit 1
selftest_log='No self-tests have been logged'
next_selftest_log='# 1 Extended offline Self-test routine in progress 90% 101 -'
mod_selftest long 0 mock
load_result mock selftest_long
[[ $R_STATUS == incomplete ]] || exit 1
next_selftest_log='# 1 Extended offline Completed: read failure 90% 101 42'
mod_selftest long 0 mock
load_result mock selftest_long
[[ $R_STATUS == bad && $R_DEDUCT -ge 45 ]] || exit 1
start_ok=0; mod_selftest long 0 mock
load_result mock selftest_long
[[ $R_STATUS == bad ]] || exit 1
set -e
printf 'scoring-state: passed\n'
