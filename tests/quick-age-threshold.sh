#!/usr/bin/env bash
# Historical age-only and threshold-only notices must not imply disk failure.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1090
source <(sed '/^#------------------------------ 参数解析 /,$d' hdd-health-check.sh)

R_STATUS=warn R_DEDUCT=15 R_ISSUES='通电 50666h' R_SUMMARY='通电 50666h'
normalize_quick_result
[[ $R_STATUS == good && $R_DEDUCT == 0 && -z $R_ISSUES ]]
[[ $R_SUMMARY == *'仅供参考'* ]]

R_STATUS=warn R_DEDUCT=5 R_ISSUES='属性接近阈值' R_SUMMARY='属性接近阈值'
normalize_quick_result
[[ $R_STATUS == incomplete && $R_DEDUCT == 0 && -z $R_ISSUES ]]
[[ $R_SUMMARY == *'缺少原始错误依据'* ]]

R_STATUS=warn R_DEDUCT=38 R_ISSUES='通电 39345h（较高）;属性接近阈值;待映射扇区 2' R_SUMMARY='通电 39345h（较高），属性接近阈值，待映射扇区 2'
normalize_quick_result
[[ $R_STATUS == bad && $R_DEDUCT == 25 && $R_ISSUES == '待映射扇区 2' ]]

R_STATUS=warn R_DEDUCT=5 R_ISSUES='SMART 属性接近阈值：ID 10 Spin_Retry_Count 最差值 95 / 阈值 97' R_SUMMARY='SMART 属性接近阈值'
normalize_quick_result
[[ $R_STATUS == warn && $R_DEDUCT == 5 && $R_ISSUES == SMART* ]]

echo 'quick-age-threshold: passed'
