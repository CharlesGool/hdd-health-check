#!/usr/bin/env bash
# Pure state/CLI checks: no disk, service, or host mutation.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export HDD_STATE_DIR="$tmp/state" HDD_LOG_DIR="$tmp/log"
mkdir -m 700 "$HDD_STATE_DIR" "$HDD_LOG_DIR"
bash ./hdd-health-check.sh --help > "$tmp/help"
grep -q 'v2.2.0' "$tmp/help"
bash ./hdd-health-check.sh -w --help > "$tmp/wait-help"
grep -q 'v2.2.0' "$tmp/wait-help"
bash ./hdd-health-check.sh -t short --help > "$tmp/test-help"
grep -q 'v2.2.0' "$tmp/test-help"
# Unknown CLI flags fail before dependency and disk probes.
if bash ./hdd-health-check.sh --not-an-option > "$tmp/unknown" 2>&1; then exit 1; fi
grep -q '未知参数' "$tmp/unknown"
# Load only pure declarations and record helpers; never enter the main workflow.
# shellcheck source=hdd-health-check.sh
source <(sed '/^#------------------------------ 磁盘枚举 /,$d' hdd-health-check.sh)
printf -v payload "\$(touch %s)" "$tmp/unsafe-marker"
printf 'R_TS=123\nR_STATUS=%s\n' "$payload" > "$tmp/evil.env"
if read_record "$tmp/evil.env" result; then echo 'accepted executable syntax' >&2; exit 1; fi
[[ ! -e $tmp/unsafe-marker ]]
printf 'R_TS=123\nR_STATUS=good\nR_SUMMARY=hello\\ world\n' > "$tmp/good.env"
read_record "$tmp/good.env" result
[[ $R_SUMMARY == 'hello world' && $R_TS == 123 ]]
printf 'S_NEXT=1\nS_TOTAL=20\n' > "$tmp/surface.state"
read_record "$tmp/surface.state" surface
[[ $S_NEXT == 1 && $S_TOTAL == 20 ]]
printf 'S_NEXT=1\nS_TOTAL=0);touch %s\n' "$tmp/unsafe-marker" > "$tmp/surface.state"
if read_record "$tmp/surface.state" surface; then exit 1; fi
[[ ! -e $tmp/unsafe-marker ]]
ln -s "$tmp/good.env" "$tmp/link.env"
if read_record "$tmp/link.env" result; then exit 1; fi
# Load isolated state/progress helpers; no workflow or hardware probes.
# shellcheck disable=SC1090
source <(sed -n '/^surface_reset_vars()/,/^surface_init()/p' hdd-health-check.sh | sed '$d')
# shellcheck disable=SC1090
source <(sed -n '/^surface_decide()/,/^# badblocks /p' hdd-health-check.sh | sed '$d')
# shellcheck disable=SC1090
source <(sed -n '/^instance_alive()/,/^status_lines()/p' hdd-health-check.sh | sed '$d')
# shellcheck disable=SC1090
source <(sed -n '/^status_lines()/,/^stop_instance()/p' hdd-health-check.sh | sed '$d')
# shellcheck disable=SC1090
source <(sed -n '/^stop_instance()/,/^status_view()/p' hdd-health-check.sh | sed '$d')

# Zero/zero represents a not-yet-initialized scan; progress without a
# denominator (or with missing chunk size) must not reach any percentage path.
S_CHUNK=64
printf 'S_NEXT=0\nS_TOTAL=0\n' > "$tmp/surface.state"
surface_load "$tmp/surface.state"
[[ $S_NEXT == 0 && $S_TOTAL == 0 ]]
for record in 'S_NEXT=1' 'S_NEXT=1 S_TOTAL=0' 'S_NEXT=1 S_TOTAL=20' \
              'S_NEXT=21 S_TOTAL=20 S_CHUNK=64'; do
    printf '%s\n' "${record// /$'\n'}" > "$tmp/surface.state"
    if surface_load "$tmp/surface.state"; then echo "accepted invalid progress: $record" >&2; exit 1; fi
done
printf 'S_NEXT=1\nS_TOTAL=20\nS_CHUNK=64\n' > "$tmp/surface.state"
surface_load "$tmp/surface.state"
DID[mock]=mock
mkdir -p "$HDD_STATE_DIR/mock"
cp "$tmp/surface.state" "$HDD_STATE_DIR/mock/surface.state"
BATCH=1; FORCE_RESCAN=0; PLAN=(); RESCAN_POLICY=ask
surface_decide mock
[[ $DEC == continue ]]
printf 'S_NEXT=1\nS_TOTAL=0\n' > "$HDD_STATE_DIR/mock/surface.state"
decide_run() { DEC=run; }
surface_decide mock
[[ $DEC == run ]]

# Force /run failure and custom TMPDIR without invoking actual disk or service.
export TMPDIR="$tmp/custom"
mkdir "$TMPDIR"
mktemp() {
    if [[ $* == *'/run/hdd-health.'* ]]; then return 1; fi
    command mktemp "$@"
}
# shellcheck disable=SC1090,SC2016
source <(sed -n '/^RUN_DIR=\$(mktemp -d /p' hdd-health-check.sh)
[[ $RUN_DIR == /tmp/tmp.* && -d $RUN_DIR ]]
RUNINFO="$HDD_STATE_DIR/running.env"
printf 'I_PID=%s\nI_RUNDIR=%s\nI_TARGETS=mock\nI_LOG=%s\n' "$$" "$RUN_DIR" "$tmp/nonexistent" > "$RUNINFO"
instance_alive
[[ $I_RUNDIR == "$RUN_DIR" ]]
DOPT_CACHE[mock]=__FAIL__
prepare_disk() { :; }
now() { printf '1\n'; }
printf 'S_NEXT=1\nS_TOTAL=0\n' > "$HDD_STATE_DIR/mock/surface.state"
status_lines
[[ ${REDRAW_LINES[0]} == *"PID $$"* ]]
# Mock signals and waits: stop must write only the isolated run directory.
kill() {
    if [[ $1 == -0 ]]; then [[ ${stopped:-0} == 0 ]]; else stopped=1; fi
}
pkill() { :; }
sleep() { :; }
stop_instance > "$tmp/stop-output"
[[ -f $RUN_DIR/stop_all ]]
rm -rf -- "$RUN_DIR"
printf 'safe-state: passed\n'
