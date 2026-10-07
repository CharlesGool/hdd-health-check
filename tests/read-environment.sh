#!/usr/bin/env bash
# Use a fake dd executable; this test never reads a device.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export HDD_STATE_DIR="$tmp/state" HDD_LOG_DIR="$tmp/log"
mkdir -p "$tmp/bin" "$tmp/run" "$HDD_STATE_DIR/mock" "$HDD_LOG_DIR"
cat > "$tmp/bin/dd" <<'MOCK'
#!/usr/bin/env bash
case ${MOCK_READ:-invalid} in
  invalid) echo "dd: failed to open '/dev/mock': Invalid argument" >&2; exit 1 ;;
  io) echo "dd: error reading '/dev/mock': Input/output error" >&2; exit 1 ;;
  good) echo '1048576 bytes (1.0 MB, 1.0 MiB) copied, 0.010 s, 105 MB/s' >&2 ;;
esac
MOCK
chmod +x "$tmp/bin/dd"
export PATH="$tmp/bin:$PATH"
source <(sed '/^#------------------------------ 参数解析 /,$d' src/checker/hdd-health-check.sh)
RUN_DIR="$tmp/run"; QUIET=1
DID[mock]=mock; D_NAME=(mock); D_MODEL=(synthetic); D_SIZE=(8MiB); D_ROTA=(1); D_TRAN=(sata)
di() { echo 0; }
blockdev() { echo 8388608; }
lsblk() { :; }
export MOCK_READ=invalid
set +e
read_mib /dev/mock 0 1
set -e
[[ $RD_OK == 0 && $RD_SETUP_ERROR == 1 ]]
SAMPLE_POINTS=3; SAMPLE_MB=1
set +e
speed_one mock
set -e
load_result mock speed
[[ $R_STATUS == incomplete && $R_DEDUCT == 0 ]]
CHUNK_MB=1
surface_init mock
set +e
surface_worker mock mock
set -e
surface_load "$HDD_STATE_DIR/mock/surface.state"
[[ $S_ERR == 0 && $S_NEXT == 0 && $S_DONE == 0 ]]
surface_finalize mock
load_result mock surface
[[ $R_STATUS == incomplete && $R_DEDUCT == 0 ]]
# The module controller also persists environment failure instead of treating it as a pause.
PLAN[surface:mock]=continue
surface_monitor() { for name in "$@"; do wait "${SW_PID[$name]}" || true; done; }
set +e
mod_surface mock
set -e
load_result mock surface
[[ $R_STATUS == incomplete && $R_DEDUCT == 0 ]]
# A real read failure remains a read error; setup flags reset on each request.
export MOCK_READ=io
set +e
read_mib /dev/mock 0 1
set -e
[[ $RD_OK == 0 && $RD_SETUP_ERROR == 0 ]]
export MOCK_READ=good
set +e
read_mib /dev/mock 0 1
set -e
[[ $RD_OK == 1 && $RD_SETUP_ERROR == 0 && $RD_KBS -gt 0 ]]
# Failed rechecks cannot be represented as successful negative evidence.
cat > "$tmp/bin/badblocks" <<'MOCK'
#!/usr/bin/env bash
case ${MOCK_BB:-failure} in
  failure) exit 1 ;;
  good) exit 0 ;;
  found) echo 12 ;;
esac
MOCK
chmod +x "$tmp/bin/badblocks"
printf '0 E 0\n' > "$HDD_STATE_DIR/mock/surface.map"
S_CHUNK=1; S_SIZE=8388608; INTERRUPTED=0
export MOCK_BB=failure
set +e
bb_recheck mock
set -e
[[ $BB_FOUND == 0 && $BB_COMPLETE == 0 ]]
export MOCK_BB=good
set +e
bb_recheck mock
set -e
[[ $BB_FOUND == 0 && $BB_COMPLETE == 1 ]]
export MOCK_BB=found
set +e
bb_recheck mock
set -e
[[ $BB_FOUND == 1 && $BB_COMPLETE == 1 ]]
# Read errors prevent a resolved-interface verdict even when CRC is unchanged.
printf 'P_TS=1700000000\nP_NOTE=synthetic\nP_CRC=10\nP_CMDTO=0\n' > "$HDD_STATE_DIR/mock/repair.env"
rm -f "$RUN_DIR/mock.read-error"
BATCH=1; IFACE_MIN=0; DOPT_CACHE[mock]='-d sat'
iface_snapshot() { IF_CRC=10; IF_CMDTO=0; IF_LINK_CUR=6; IF_LINK_MAX=6; }
klog_lines() { KL_LNK=''; KL_SRC=synthetic; }
iface_worker() { printf 'W_MB=10240\nW_ERR=1\nW_KBS=10000\n' > "$RUN_DIR/$1.iface"; }
iface_monitor() { shift; for name in "$@"; do wait "${SW_PID[$name]}" || true; done; }
set +e
mod_iface mock
set -e
load_result mock iface
[[ $R_STATUS == incomplete && $R_DEDUCT == 0 && $R_SUMMARY == *读取错误* ]]
echo 'read-environment: passed'
