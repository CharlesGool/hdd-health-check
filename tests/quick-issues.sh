#!/usr/bin/env bash
# A warm NVMe drive is informational and must not lose health points.
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT
export HDD_STATE_DIR="$test_dir/state" HDD_LOG_DIR="$test_dir/log"
mkdir -p "$HDD_STATE_DIR/mock" "$HDD_LOG_DIR"
# shellcheck disable=SC1090
source <(sed '/^#------------------------------ 参数解析 /,$d' src/checker/hdd-health-check.sh)
DID[mock]=mock; D_NAME=(mock); D_MODEL=(synthetic); D_SIZE=(1TB); D_ROTA=(0); D_TRAN=(nvme); DOPT_CACHE[mock]=''
QUIET=1
mock_temperature=52 mock_warning=0x00 mock_health=PASSED
now() { echo 1700000000; }
di() { echo 0; }
mount_check() { :; }
klog_check() { :; }
sm() {
    case "${2:-}" in
        -i) printf 'Model Number: synthetic\nNVMe Version: 1.4\nSMART support is: Enabled\n' ;;
        -H) printf 'SMART overall-health self-assessment test result: %s\n' "$mock_health" ;;
        -A) printf 'Temperature: %s Celsius\nCritical Warning: %s\nMedia and Data Integrity Errors: 0\nPercentage Used: 10%%\nPower On Hours: 1000\n' "$mock_temperature" "$mock_warning" ;;
        -l) case "${3:-}" in error) echo 'No Errors Logged';; selftest) echo 'No self-tests have been logged';; esac ;;
    esac
}
set +e
quick_one mock
set -e
load_result mock quick
[[ $R_STATUS == good && $R_DEDUCT == 0 && -z $R_ISSUES ]]
WORST=0
report_table mock
[[ $WORST == 0 ]]
mock_temperature=72 mock_warning=0x02 mock_health=FAILED
set +e
quick_one mock
set -e
load_result mock quick
[[ $R_STATUS == good && $R_DEDUCT == 0 ]]
mock_warning=0x04
set +e
quick_one mock
set -e
load_result mock quick
[[ $R_STATUS == bad && $R_DEDUCT -ge 40 ]]
echo 'quick-issues: passed'
