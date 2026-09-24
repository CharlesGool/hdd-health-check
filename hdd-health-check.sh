#!/usr/bin/env bash
#===============================================================================
#  hdd-health-check.sh —— 机械硬盘（HDD）全方位健康评估工具（按键菜单版）
#
#  运行环境 : Debian / Ubuntu，bash ≥ 4.3，需 root
#  依    赖 : smartmontools, util-linux(lsblk/blockdev), coreutils(dd)
#             可选: e2fsprogs(badblocks —— 坏块扫描与异常区域精确复查)
#  安 全 性 : 所有检测均为【只读】，不会向硬盘写入任何数据
#
#  评估维度 :
#   [2] 快速体检   设备/固件/接口、SATA 链路速率、SMART 总体判定、关键属性、
#                  临近阈值属性、温度(当前+历史极值)、寿命与负载、错误日志、
#                  缓存/APM/SCT ERC 配置、只读降级、内核日志 I/O 错误、
#                  与历史记录对比的坏道增长趋势
#   [3][4] SMART 短/长自检   多盘并行、可放后台、自动读取硬盘内部自检日志
#   [5] 读性能曲线           全盘分段采样读速度，识别速度凹陷与整体降速
#   [6] 全盘读延迟扫描       类 Victoria 逐块读取测速：慢块/极慢块/读错误，
#                            可暂停、断点续扫、多盘并行，异常区可 badblocks 复查
#   [7] badblocks 坏块扫描   全盘只读扫描，精确到块
#   [V] 维修后接口复查       记录维修点（重插/换线/换口）→ 持续读取压力测试 →
#                            实时监测 CRC/命令超时/链路速率 → 判定接口问题是否解决
#   [F] 一键完整评估         以上全部，开始前一次问完，之后无人值守
#   [R] 综合报告             各项结果汇总打分 + 评估完整度 + 处理建议
#
#  结果按「型号_序列号」保存在 $STATE_DIR，换接口/换机器后仍能对上同一块盘；
#  再次检测时可选择 重新扫描 / 沿用上次结果 / 跳过。
#
#  后台运行 : 耗时任务（接口复查/全盘扫描/badblocks/完整评估）在终端里问完问题后，
#             自动交给 systemd 作为独立服务运行，与 SSH/sudo/终端完全脱钩，
#             可随时关闭终端。重新登录后:
#               --status  查看后台任务实时进度      --stop  安全暂停（进度保存）
#             批处理可加 --detach 直接交给 systemd 后台运行
#
#  退出码   : 0=全部良好  1=存在注意/警告  2=存在危险盘  3=运行错误
#===============================================================================

set -o pipefail
shopt -s extglob

SCRIPT_VERSION="2.2.0"
SCRIPT_NAME="$(basename "$0")"
SELF="$(readlink -f "$0")"
ORIG_ARGS=("$@")

#------------------------------ 路径与默认设置 --------------------------------
LOG_DIR="${HDD_LOG_DIR:-/var/log/disk-health}"
STATE_DIR="${HDD_STATE_DIR:-/var/lib/hdd-health}"
SETTINGS_FILE="$STATE_DIR/settings.conf"

VALID_DAYS=7            # 结果有效期（天），超期会提示重扫
RESCAN_POLICY="ask"     # 已有结果时: ask=每次询问 | rescan=总是重扫 | reuse=有效期内沿用
PARALLEL=1              # 多块盘同时做全盘扫描
CHUNK_MB=64             # 读延迟扫描的块大小 (MiB)
SAMPLE_POINTS=24        # 读性能曲线采样点数
SAMPLE_MB=128           # 每个采样点读取量 (MiB)
INCLUDE_SSD=0           # 选盘列表是否包含 SSD/NVMe
AUTO_RECHECK="ask"      # 扫描发现异常区域后 badblocks 复查: ask | always | never

#------------------------------ 运行时变量 ------------------------------------
LOG_FILE=""
BATCH=0; QUIET=0; ASSUME_YES=0; FORCE_RESCAN=0
RUN_LIST=""
declare -a REQ_DISKS=() SELECTED=()
declare -A DOPT_CACHE=() DID=() PLAN=()
IN_TASK=0; INTERRUPTED=0; WORST=0; DETACHED=0
RUNINFO=""; CUR_TASK=""; BG_HANDED=0; LOCKED=0; DETACH_REQ=0; PLAN_FILE=""
RUN_DIR=""; CLEANED=0
KEY=""; DEC=""
CUR_DED=0; declare -a CUR_ISS=()
PLAN_RECHECK=""

MODS=(quick selftest_short selftest_long speed surface badblocks iface)
declare -A MOD_LABEL=(
    [quick]="快速体检" [selftest_short]="SMART 短自检" [selftest_long]="SMART 长自检"
    [speed]="读性能曲线" [surface]="全盘读延迟扫描" [badblocks]="badblocks 坏块扫描"
    [iface]="接口复查"
)

#------------------------------ 颜色 ------------------------------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_RED=$'\e[1;31m'; C_YEL=$'\e[1;33m'; C_GRN=$'\e[1;32m'
    C_BLU=$'\e[1;36m'; C_DIM=$'\e[2m'; C_BOLD=$'\e[1m'; C_OFF=$'\e[0m'
else
    C_RED=""; C_YEL=""; C_GRN=""; C_BLU=""; C_DIM=""; C_BOLD=""; C_OFF=""
fi

#------------------------------ 输出函数 --------------------------------------
# out : 终端 + 日志（日志去掉颜色）；say : 仅终端
out() {
    local s="$*"
    [[ $QUIET -eq 0 ]] && printf '%s\n' "$s"
    if [[ -n $LOG_FILE ]]; then
        s=${s//$'\e'\[*([0-9;])m/}
        printf '%s\n' "$s" >> "$LOG_FILE"
    fi
    return 0
}
say()  { [[ $QUIET -eq 0 ]] && printf '%s\n' "$*"; return 0; }
hr()   { out "------------------------------------------------------------------------"; }
head1(){ out ""; out "${C_BOLD}========================================================================${C_OFF}"
         out "${C_BOLD}$*${C_OFF}"
         out "${C_BOLD}========================================================================${C_OFF}"; }
head2(){ out ""; out "${C_BLU}--- $* ---${C_OFF}"; }
info() { out "    $*"; }
ok()   { out "    ${C_GRN}[正常]${C_OFF} $*"; }
warn() { out "    ${C_YEL}[注意]${C_OFF} $*"; }
bad()  { out "    ${C_RED}[危险]${C_OFF} $*"; }
die()  { printf '%s\n' "${C_RED}错误: $*${C_OFF}" >&2; exit 3; }
dump() { local l; while IFS= read -r l; do out "      | $l"; done <<< "$1"; }

# 扣分并记录问题
pen() { CUR_DED=$((CUR_DED + $1)); [[ -n ${2:-} ]] && CUR_ISS+=("$2"); return 0; }
# 用任意（含多字节）分隔符拼接数组
join_by() { local sep=$1 out="" x; shift; for x in "$@"; do out+="${out:+$sep}$x"; done; printf '%s' "$out"; }

#------------------------------ 小工具 ----------------------------------------
now()     { printf '%(%s)T' -1; }
num()     { local v="${1:-}"; v="${v##+([[:space:]])}"; v="${v%%[!0-9]*}"; echo "${v:-0}"; }
mbs()     { local k=${1:-0}; printf '%d.%d' $((k/1024)) $(( (k%1024)*10/1024 )); }
disk_kind(){ [[ "$1" == "1" ]] && echo "机械盘" || echo "固态盘"; }

fmt_dur() {
    local s=${1:-0} d h m
    d=$((s/86400)); h=$((s%86400/3600)); m=$((s%3600/60))
    if   ((d>0)); then printf '%d天%d时' "$d" "$h"
    elif ((h>0)); then printf '%d时%d分' "$h" "$m"
    elif ((m>0)); then printf '%d分' "$m"
    else printf '%d秒' "$s"; fi
}

age_str() {
    local ts=${1:-0} d when
    d=$(( $(now) - ts )); ((d<0)) && d=0
    printf -v when '%(%m-%d %H:%M)T' "$ts"
    if   ((d<3600));  then echo "$when，$((d/60))分钟前"
    elif ((d<86400)); then echo "$when，$((d/3600))小时前"
    else                   echo "$when，$((d/86400))天前"; fi
}

#------------------------------ 按键输入 --------------------------------------
# getkey: 读取单个按键到 KEY（大写；回车=ENTER；方向键等=ESC）
getkey() {
    local k rest
    IFS= read -rsn1 k </dev/tty || { KEY=""; return 1; }
    if [[ $k == $'\e' ]]; then IFS= read -rsn5 -t 0.05 rest </dev/tty; KEY="ESC"; return 0; fi
    [[ -z $k ]] && { KEY="ENTER"; return 0; }
    KEY="${k^^}"
}

# choose "提示" 允许的键...   -> KEY
choose() {
    local prompt="$1"; shift
    local k
    (( DETACHED )) && { KEY=""; return 1; }
    while true; do
        printf '%s' "$prompt" >/dev/tty
        if ! getkey; then
            printf '\n' >/dev/tty; KEY=""; return 1
        fi
        [[ $INTERRUPTED -eq 1 ]] && { printf '\n' >/dev/tty; KEY=""; return 1; }
        for k in "$@"; do
            if [[ $KEY == "$k" ]]; then
                [[ $KEY == ENTER ]] && printf '\n' >/dev/tty || printf '%s\n' "$KEY" >/dev/tty
                return 0
            fi
        done
        printf '\r\e[K' >/dev/tty
    done
}

# ask_yn "问题" [Y|N 默认]
ask_yn() {
    local q="$1" def="${2:-N}" hint
    (( DETACHED )) && return 1           # 终端已断开：不发起需要确认的新操作
    [[ $ASSUME_YES -eq 1 ]] && return 0
    if [[ $BATCH -eq 1 ]]; then [[ $def == Y ]]; return; fi
    [[ $def == Y ]] && hint="[Y/n]" || hint="[y/N]"
    choose "    $q $hint " Y N ENTER || return 1
    [[ $KEY == ENTER ]] && KEY=$def
    [[ $KEY == Y ]]
}

pause_key() {
    [[ $BATCH -eq 1 || $DETACHED -eq 1 ]] && return
    printf '\n%s' "  ${C_DIM}按任意键返回主菜单…${C_OFF}" >/dev/tty
    getkey; printf '\n' >/dev/tty
}

# 非阻塞轮询按键（监控界面用），超时 KEY 为空
poll_key() {
    KEY=""
    if [[ $BATCH -eq 1 || $DETACHED -eq 1 ]]; then sleep "$1"; return; fi
    local k
    if IFS= read -rsn1 -t "$1" k </dev/tty; then KEY="${k^^}"; fi
    return 0
}

# 原地刷新多行状态
DRAWN=0; declare -a REDRAW_LINES=()
redraw() {
    [[ $QUIET -eq 1 || ! -t 1 ]] && return
    (( DRAWN > 0 )) && printf '\e[%dA' "$DRAWN"
    local l
    for l in "${REDRAW_LINES[@]}"; do printf '\r\e[K%s\n' "$l"; done
    DRAWN=${#REDRAW_LINES[@]}
}
cursor() { [[ $QUIET -eq 0 && -t 1 ]] && printf '\e[?25%s' "$1"; return 0; }
# Internal callers pass literal format strings.
# shellcheck disable=SC2059
prog() { [[ $QUIET -eq 0 && -t 1 ]] && printf "$@"; return 0; }
clear_screen() { [[ $QUIET -eq 0 && $BATCH -eq 0 ]] && printf '\e[H\e[2J'; }

#------------------------------ 中断与清理 ------------------------------------
on_int() {
    if (( IN_TASK )); then
        INTERRUPTED=1
        [[ -n $RUN_DIR ]] && : > "$RUN_DIR/stop_all" 2>/dev/null
        printf '\n%s\n' "${C_YEL}收到中断，正在安全停止当前任务（已完成部分会保存）…${C_OFF}" 2>/dev/null >/dev/tty
    else
        printf '\n' 2>/dev/null >/dev/tty
        exit 130
    fi
}
# 终端断开(SIGHUP)：不退出，转入后台模式把当前任务跑完
on_hup() {
    (( DETACHED )) && return
    DETACHED=1; BATCH=1; QUIET=1
    exec </dev/null >/dev/null 2>&1
    [[ -n $LOG_FILE ]] && printf '\n[%s] 终端已断开：当前任务转入后台继续执行，完成后写入报告并退出。\n' \
        "$(printf '%(%F %T)T' -1)" >> "$LOG_FILE"
    write_runinfo
}

# 运行实例信息（供 --status / --stop 使用）
write_runinfo() {
    [[ -n $RUNINFO ]] || return 0
    (( LOCKED )) || return 0
    local mode="前台运行（关闭终端会中断）"
    [[ -n ${INVOCATION_ID:-} ]] && mode="systemd 后台服务（与终端无关）"
    (( DETACHED )) && mode="终端已断开，后台运行中"
    {
        printf 'I_PID=%q\nI_LOG=%q\nI_RUNDIR=%q\nI_TASK=%q\nI_TARGETS=%q\nI_DETACHED=%q\nI_START=%q\nI_MODE=%q\n' \
            "$$" "$LOG_FILE" "$RUN_DIR" "$CUR_TASK" "${SELECTED[*]}" "$DETACHED" "${I_START:-$(now)}" "$mode"
    } > "$RUNINFO.tmp" && mv -f "$RUNINFO.tmp" "$RUNINFO"
}

cleanup() {
    (( CLEANED )) && return; CLEANED=1
    if [[ -n $RUN_DIR && -d $RUN_DIR ]]; then
        : > "$RUN_DIR/stop_all" 2>/dev/null
        wait 2>/dev/null
        [[ $RUN_DIR == /run/hdd-health.* || $RUN_DIR == /tmp/tmp.* ]] && rm -rf -- "$RUN_DIR"
    fi
    [[ -n $RUNINFO && -r $RUNINFO ]] && grep -q "^I_PID=$$\$" "$RUNINFO" && rm -f "$RUNINFO"
    cursor h 2>/dev/null
}

# Persisted records are data, never shell programs. Decode printf %q values.
decode_record_value() {
    local raw=$1 out="" ch i
    if [[ $raw == \$\'*\' ]]; then
        raw=${raw:2:${#raw}-3}
        printf -v RECORD_VALUE '%b' "$raw"
        return 0
    fi
    [[ $raw != *'$'* && $raw != *'`'* ]] || return 1
    for ((i=0; i<${#raw}; i++)); do
        ch=${raw:i:1}
        if [[ $ch == "\\" ]]; then
            ((++i < ${#raw})) || return 1
            ch=${raw:i:1}
        fi
        out+=$ch
    done
    RECORD_VALUE=$out
}

read_record() {
    local file=$1 kind=$2 key raw
    [[ -f $file && ! -L $file ]] || return 1
    while IFS='=' read -r key raw; do
        case "$kind:$key" in
            result:R_TS|result:R_DEDUCT|repair:P_TS|repair:P_CRC|repair:P_CMDTO|run:I_PID|run:I_START|surface:S_NEXT|surface:S_TOTAL|surface:S_CHUNK|surface:S_OK|surface:S_SLOW|surface:S_VSLOW|surface:S_ERR|surface:S_TRANS|surface:S_EMA|surface:S_KBS|surface:S_ELAPSED|surface:S_SIZE|surface:S_DONE|surface:S_TS_START|surface:S_TS_UPD)
                [[ $raw =~ ^(0|[1-9][0-9]{0,14})$ ]] || return 1
                printf -v "$key" '%s' "$raw" ;;
            result:R_STATUS|result:R_ISSUES|result:R_SUMMARY|result:R_CURVE|result:R_LINE|repair:P_NOTE|run:I_DETACHED|run:I_LOG|run:I_RUNDIR|run:I_TASK|run:I_TARGETS|run:I_MODE)
                decode_record_value "$raw" || return 1
                printf -v "$key" '%s' "$RECORD_VALUE" ;;
            iface:W_MB|iface:W_ERR|iface:W_KBS)
                [[ $raw =~ ^(0|[1-9][0-9]{0,14})$ ]] || return 1
                printf -v "$key" '%s' "$raw" ;;
            *) return 1 ;;
        esac
    done < "$file"
}

#------------------------------ 设置读写 --------------------------------------
load_settings() {
    [[ -r $SETTINGS_FILE ]] || return 0
    local k v
    while IFS='=' read -r k v; do
        case $k in
            VALID_DAYS|PARALLEL|CHUNK_MB|SAMPLE_POINTS|SAMPLE_MB|INCLUDE_SSD)
                [[ $v =~ ^(0|[1-9][0-9]{0,8})$ ]] && printf -v "$k" '%s' "$v" ;;
            RESCAN_POLICY) [[ $v =~ ^(ask|rescan|reuse)$ ]] && RESCAN_POLICY=$v ;;
            AUTO_RECHECK)  [[ $v =~ ^(ask|always|never)$ ]] && AUTO_RECHECK=$v ;;
        esac
    done < "$SETTINGS_FILE"
    (( CHUNK_MB < 1 )) && CHUNK_MB=64
    (( SAMPLE_POINTS < 3 )) && SAMPLE_POINTS=24
    (( VALID_DAYS < 1 )) && VALID_DAYS=7
    return 0
}
save_settings() {
    {
        printf 'VALID_DAYS=%s\nRESCAN_POLICY=%s\nPARALLEL=%s\nCHUNK_MB=%s\n' \
            "$VALID_DAYS" "$RESCAN_POLICY" "$PARALLEL" "$CHUNK_MB"
        printf 'SAMPLE_POINTS=%s\nSAMPLE_MB=%s\nINCLUDE_SSD=%s\nAUTO_RECHECK=%s\n' \
            "$SAMPLE_POINTS" "$SAMPLE_MB" "$INCLUDE_SSD" "$AUTO_RECHECK"
    } > "$SETTINGS_FILE"
}

#------------------------------ 磁盘枚举 --------------------------------------
declare -a D_NAME=() D_SIZE=() D_MODEL=() D_ROTA=() D_TRAN=()
enumerate_disks() {
    D_NAME=(); D_SIZE=(); D_MODEL=(); D_ROTA=(); D_TRAN=()
    local n t m tp r
    while read -r n t; do
        [[ $t == disk ]] || continue
        case $n in loop*|ram*|sr*|zram*|md*|dm-*|fd*|nbd*) continue ;; esac
        m=$(lsblk -dno MODEL "/dev/$n" 2>/dev/null); m="${m##+([[:space:]])}"; m="${m%%+([[:space:]])}"
        tp=$(lsblk -dno TRAN "/dev/$n" 2>/dev/null); tp="${tp//[[:space:]]/}"
        r=$(lsblk -dno ROTA "/dev/$n" 2>/dev/null); r="${r//[[:space:]]/}"
        D_NAME+=("$n")
        D_SIZE+=("$(lsblk -dno SIZE "/dev/$n" 2>/dev/null | tr -d ' ')")
        D_MODEL+=("${m:-未知型号}"); D_ROTA+=("${r:-?}"); D_TRAN+=("${tp:-?}")
    done < <(lsblk -dnro NAME,TYPE 2>/dev/null)
}
di() { local i; for i in "${!D_NAME[@]}"; do [[ ${D_NAME[$i]} == "$1" ]] && { echo "$i"; return 0; }; done; echo 0; return 1; }

# 自动探测 smartctl 需要的 -d 参数（USB 盒/桥接常见问题）
detect_dopt() {
    local dev="$1" c
    local -a cands=("" "-d sat" "-d sat,12" "-d scsi" "-d ata" "-d nvme"
                    "-d usbjmicron" "-d usbprolific" "-d usbsunplus" "-d usbasm1352r,0")
    for c in "${cands[@]}"; do
        # shellcheck disable=SC2086
        if smartctl -i $c "$dev" 2>/dev/null \
           | grep -qE '^(Device Model|Model Number|Model Family|Product|Vendor):'; then
            echo "$c"; return 0
        fi
    done
    echo "__FAIL__"; return 1
}

# smartctl 包装：自动带上探测到的 -d 参数
sm() {
    local n=$1; shift
    local -a o=()
    [[ -n ${DOPT_CACHE[$n]:-} && ${DOPT_CACHE[$n]} != "__FAIL__" ]] && read -ra o <<< "${DOPT_CACHE[$n]}"
    ( trap '' HUP; exec smartctl "$@" "${o[@]}" "/dev/$n" )
}

# 识别磁盘身份（型号_序列号），结果目录按身份存放
prepare_disk() {
    local name=$1
    [[ -n ${DID[$name]:-} ]] && return 0
    local dopt serial="" model id i
    dopt=$(detect_dopt "/dev/$name")
    DOPT_CACHE[$name]=$dopt
    if [[ $dopt != "__FAIL__" ]]; then
        serial=$(sm "$name" -i 2>/dev/null | grep -m1 -iE '^Serial [Nn]umber:' | sed 's/.*:[[:space:]]*//')
    fi
    [[ -z $serial ]] && serial=$(lsblk -dno SERIAL "/dev/$name" 2>/dev/null | tr -d ' ')
    i=$(di "$name"); model=${D_MODEL[$i]:-unknown}
    if [[ -n $serial ]]; then id="${model}_${serial}"; else id="noserial_${name}_${model}"; fi
    id=$(printf '%s' "$id" | tr -c 'A-Za-z0-9._-' '_')
    DID[$name]=$id
    [[ ! -L $STATE_DIR/$id ]] || die "磁盘状态目录不能是符号链接"
    if ! mkdir -p "$STATE_DIR/$id" || ! chmod 700 "$STATE_DIR/$id"; then die "无法创建磁盘状态目录"; fi
    {
        printf 'M_NAME=%q\nM_MODEL=%q\nM_SERIAL=%q\nM_SIZE=%q\nM_SEEN=%q\n' \
            "$name" "$model" "$serial" "${D_SIZE[$i]:-?}" "$(now)"
    } > "$STATE_DIR/$id/meta.env"
}

get_poh() { num "$(sm "$1" -A 2>/dev/null | awk '$1==9 && NF>=10 {print $10; exit}')"; }

#------------------------------ 结果存取 --------------------------------------
# save_result <id> <mod> <status> <summary> [K=V ...]   （扣分与问题取自 CUR_DED / CUR_ISS）
# status: good | warn | bad | na | incomplete | running
RES_TS=""
save_result() {
    local id=$1 mod=$2 status=$3 summary=$4; shift 4
    local f="$STATE_DIR/$id/$mod.env" kv iss
    iss=$(join_by ';' "${CUR_ISS[@]}")
    {
        printf 'R_TS=%q\nR_STATUS=%q\nR_DEDUCT=%q\nR_ISSUES=%q\nR_SUMMARY=%q\n' \
            "${RES_TS:-$(now)}" "$status" "$CUR_DED" "$iss" "$summary"
        for kv in "$@"; do printf '%s=%q\n' "${kv%%=*}" "${kv#*=}"; done
    } > "$f.tmp" && mv -f "$f.tmp" "$f"
    RES_TS=""
}
load_result() {
    R_TS=0; R_STATUS=""; R_DEDUCT=0; R_ISSUES=""; R_SUMMARY=""; R_CURVE=""
    local f="$STATE_DIR/$1/$2.env"
    [[ -r $f ]] || return 1
    read_record "$f" result
}
status_of_ded() { if (( CUR_DED == 0 )); then echo good; elif (( CUR_DED < 25 )); then echo warn; else echo bad; fi; }
status_txt() {
    case $1 in
        good) echo "${C_GRN}正常${C_OFF}" ;; warn) echo "${C_YEL}注意${C_OFF}" ;;
        bad)  echo "${C_RED}异常${C_OFF}" ;; na) echo "不可用" ;;
        incomplete) echo "${C_YEL}未完成${C_OFF}" ;; running) echo "${C_BLU}进行中${C_OFF}" ;;
        *) echo "$1" ;;
    esac
}

#------------------------------ 重扫决策 --------------------------------------
# decide_run <id> <mod> <name>  -> DEC = run | reuse | skip
decide_run() {
    local id=$1 mod=$2 name=$3 key="$2:$3" label=${MOD_LABEL[$2]}
    if [[ -n ${PLAN[$key]:-} ]]; then DEC=${PLAN[$key]}; return 0; fi
    DEC=run
    load_result "$id" "$mod" || return 0
    [[ $R_STATUS == incomplete || $R_STATUS == running ]] && return 0
    local valid=0
    (( $(now) - R_TS < VALID_DAYS*86400 )) && valid=1

    if (( BATCH )); then
        [[ $mod == quick || $FORCE_RESCAN -eq 1 ]] && return 0
        (( valid )) && DEC=reuse
        return 0
    fi
    case $RESCAN_POLICY in
        rescan) return 0 ;;
        reuse)  (( valid )) && DEC=reuse; return 0 ;;
    esac
    say "    /dev/$name 已有「$label」结果（$(age_str "$R_TS")）：$R_SUMMARY"
    (( valid )) || say "    ${C_YEL}该结果已超过 ${VALID_DAYS} 天有效期，建议重新扫描${C_OFF}"
    if choose "    [R] 重新扫描   [U] 沿用上次结果   [S] 跳过  > " R U S; then
        case $KEY in R) DEC=run ;; U) DEC=reuse ;; S) DEC=skip ;; esac
    else
        DEC=skip
    fi
}

dec_note() {  # 打印沿用/跳过说明，返回 0 表示需要执行
    case $DEC in
        reuse) info "/dev/$1 沿用上次「${MOD_LABEL[$2]}」结果"; return 1 ;;
        skip)  info "/dev/$1 跳过「${MOD_LABEL[$2]}」"; return 1 ;;
    esac
    return 0
}

#==============================================================================
#  交给 systemd 后台运行（与登录会话完全脱钩）
#==============================================================================
take_lock() { exec 9>"$STATE_DIR/.lock"; if flock -n 9; then LOCKED=1; return 0; fi; exec 9>&-; LOCKED=0; return 1; }
drop_lock() { exec 9>&-; LOCKED=0; }
tty_ok()    { { : </dev/tty; } 2>/dev/null; }
have_systemd_run() { command -v systemd-run >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; }
bg_available() { (( ! BATCH && ! DETACHED )) && [[ -z ${HDD_NO_BG:-} ]] && have_systemd_run; }

# systemd_launch <unit> <参数...>  —— 以独立服务运行本脚本
systemd_launch() {
    local unit=$1; shift
    systemd-run --quiet --collect --unit="$unit" --description="HDD health check" \
        --setenv=HDD_STATE_DIR="$STATE_DIR" --setenv=HDD_LOG_DIR="$LOG_DIR" \
        --setenv=PATH="$PATH" --setenv=NO_COLOR=1 \
        "$BASH" "$SELF" "$@" >/dev/null 2>&1
}

# bg_launch <逗号分隔磁盘> <批处理参数...>
# 把交互阶段已做的决定(PLAN)交给后台实例，然后在终端显示实时进度
bg_launch() {
    local disks=$1; shift
    local unit planf off i key
    unit="hdd-health-$(now)"
    planf="$STATE_DIR/plan-$unit.env"
    { for key in "${!PLAN[@]}"; do printf '%s\t%s\n' "$key" "${PLAN[$key]}"; done
      printf 'RECHECK\t%s\n' "$PLAN_RECHECK"; } > "$planf"
    off=$(stat -c %s "$LOG_FILE" 2>/dev/null || echo 0)
    drop_lock
    [[ -r $RUNINFO ]] && grep -q "^I_PID=$$\$" "$RUNINFO" && rm -f "$RUNINFO"
    if ! systemd_launch "$unit" -d "$disks" "$@" -q -l "$LOG_FILE" --plan "$planf"; then
        rm -f "$planf"; take_lock; write_runinfo
        warn "无法交给 systemd 后台运行，改为在当前终端执行（关闭终端会中断）"
        return 1
    fi
    for ((i=0; i<40; i++)); do instance_alive && break; sleep 0.25; done
    if ! instance_alive; then
        rm -f "$planf"; take_lock; write_runinfo
        warn "后台任务未能启动（可用 journalctl -u $unit 查看原因），改为在当前终端执行（关闭终端会中断）"
        return 1
    fi
    out ""
    ok "已交给系统后台运行（systemd 单元 ${unit}，PID ${I_PID}）—— 现在可以随时关闭终端"
    info "重新登录后查看进度: $SCRIPT_NAME --status     安全停止: $SCRIPT_NAME --stop"
    say ""
    BG_HANDED=1
    status_view "$off" "$LOG_FILE"
    return 0
}

#==============================================================================
#  模块一：快速体检
#==============================================================================
mount_check() {
    local name=$1 mnts parts ro
    mnts=$(lsblk -nr -o NAME,MOUNTPOINT "/dev/$name" 2>/dev/null | awk 'NF>1{print "/dev/"$1" -> "$2}')
    if [[ -n $mnts ]]; then
        info "挂载点   :"; dump "$mnts"
        parts=$(lsblk -nr -o NAME "/dev/$name" 2>/dev/null | paste -sd'|')
        ro=$(awk -v p="^/dev/(${parts})\$" '$1 ~ p && $4 ~ /(^|,)ro(,|$)/' /proc/mounts 2>/dev/null)
        if [[ -n $ro ]]; then
            bad "该盘上有文件系统被挂载为只读，通常是 I/O 错误导致内核强制降级！"
            dump "$ro"; pen 25 "文件系统被强制只读"
        fi
        MOUNTED=1
    else
        info "挂载点   : 无（未挂载）"; MOUNTED=0
    fi
}

# 内核日志检查起点：有效期起点 与 该盘最近一次维修时间点 取较晚者
klog_since() {
    local id=$1 t
    t=$(( $(now) - VALID_DAYS*86400 ))
    if [[ -r $STATE_DIR/$id/repair.env ]]; then
        local P_TS=0; read_record "$STATE_DIR/$id/repair.env" repair || return 1
        (( P_TS > t )) && t=$P_TS
    fi
    echo "$t"
}

# klog_lines <name> <since_epoch>  -> KL_MED KL_LNK KL_SRC
klog_lines() {
    local name=$1 since=$2 port pat_dev src="" lines
    port=$(readlink -f "/sys/block/$name/device" 2>/dev/null | grep -oE 'ata[0-9]+' | tail -n1)
    pat_dev="\\b${name}[0-9]*\\b"
    [[ -n $port ]] && pat_dev="(${pat_dev}|\\b${port}(\\.[0-9]+)?:)"
    KL_PORT=$port
    if command -v journalctl >/dev/null 2>&1; then
        src=$(journalctl -k -q --no-pager -o short-iso --since "$(printf '%(%F %T)T' "$since")" 2>/dev/null)
        KL_SRC="journalctl，自 $(printf '%(%m-%d %H:%M)T' "$since") 起"
    fi
    if [[ -z $src ]]; then
        # dmesg 用开机相对秒数过滤
        local up boot rel
        up=$(cut -d. -f1 /proc/uptime 2>/dev/null); up=${up:-0}
        boot=$(( $(now) - up )); rel=$(( since - boot )); (( rel < 0 )) && rel=0
        src=$(dmesg 2>/dev/null | awk -v t="$rel" -F'[][]' '{ if ($2+0 >= t) print }')
        KL_SRC="dmesg，自 $(printf '%(%m-%d %H:%M)T' "$(( since > boot ? since : boot ))") 起"
    fi
    lines=$(grep -E "$pat_dev" <<< "$src")
    KL_MED=$(grep -iE 'I/O error|medium error|unrecovered read error|critical medium|UNC|SMART error' <<< "$lines" | tail -n 10)
    KL_LNK=$(grep -iE 'hard resetting link|SATA link down|bus error|failed command|link is slow|limiting SATA link|COMRESET|interface fatal error|BadCRC|ICRC' <<< "$lines" | tail -n 10)
}

klog_check() {
    local name=$1 id=${DID[$1]}
    klog_lines "$name" "$(klog_since "$id")"
    info "日志范围 : $KL_SRC"
    if [[ -r $STATE_DIR/$id/repair.env ]]; then
        local P_TS=0; read_record "$STATE_DIR/$id/repair.env" repair || return 1
        (( P_TS > $(now) - VALID_DAYS*86400 )) && info "  （已从维修时间点起算，维修前的旧错误不再计入）"
    fi
    if [[ -n $KL_MED ]]; then
        bad "内核日志中存在该盘的介质/读写错误（最近 10 条）："; dump "$KL_MED"
        pen 20 "内核日志介质错误"
    fi
    if [[ -n $KL_LNK ]]; then
        warn "内核日志中存在链路复位/CRC/命令失败（多为线缆、供电、背板问题）："; dump "$KL_LNK"
        pen 8 "内核日志链路错误"
    fi
    [[ -z $KL_MED && -z $KL_LNK ]] && ok "内核日志中未发现相关 I/O 错误"
    [[ -n $KL_PORT ]] && info "对应 ATA 端口: $KL_PORT"
}

# 累计型计数的判定: cumu_check <名称> <当前> <上次> <维修基线> <增长扣分> <首次扣分> <说明>
cumu_check() {
    local label=$1 cur=${2:-0} prev=$3 base=$4 pg=$5 pf=$6 why=$7
    (( cur > 0 )) || return 0
    local ref=$prev refname="上次体检"
    if [[ -n $base ]]; then ref=$base; refname="维修时间点"; fi
    if [[ -z $ref ]]; then
        warn "$label 累计 $cur 次 —— 首次记录，无法判断是否仍在发生（$why）"
        info "  处理接口后用 [V] 接口复查 验证；或过几天再体检，看是否增长"
        pen "$pf" "${label}累计 $cur（待复查）"
    elif (( cur > ref )); then
        warn "$label 较${refname}增加 $(( cur - ref )) 次（累计 $cur）—— 问题仍在发生，$why"
        pen "$pg" "${label}增长 +$(( cur - ref ))"
    else
        ok "$label 累计 $cur 次，为历史累计值（不会清零），较${refname}未增长"
    fi
}

quick_save() {  # id [status] summary
    local id=$1 st=$2 sum=$3
    [[ -z $st ]] && st=$(status_of_ded)
    head2 "本项小结"
    if (( ${#CUR_ISS[@]} )); then
        info "扣分 ${CUR_DED}，问题：$(join_by '，' "${CUR_ISS[@]}")"
    else
        if [[ $st == na ]]; then info "$sum"; else ok "未发现异常"; fi
    fi
    save_result "$id" quick "$st" "$sum"
}

quick_one() {
    local name=$1 dev="/dev/$1" id=${DID[$1]}
    local i; i=$(di "$name")
    local size=${D_SIZE[$i]:-?} model=${D_MODEL[$i]:-?} rota=${D_ROTA[$i]:-?} tran=${D_TRAN[$i]:-?}
    CUR_DED=0; CUR_ISS=()

    head1 "快速体检 · $dev  ($model)"

    #---- 1. 基础信息 ----
    head2 "1. 设备基础信息"
    info "设备节点 : $dev"
    info "容量     : $size"
    info "型号     : $model"
    info "类型     : $(disk_kind "$rota")   接口: $tran"
    [[ $rota != 1 ]] && warn "非旋转介质（SSD/NVMe），部分机械盘指标不适用"
    [[ $tran == usb ]] && info "USB 连接：部分硬盘盒不支持 SMART 直通，或空闲时休眠导致长自检中断"
    mount_check "$name"

    #---- 2. SMART 可用性 ----
    head2 "2. SMART 支持与接口"
    if [[ ${DOPT_CACHE[$name]} == "__FAIL__" ]]; then
        bad "smartctl 无法识别该设备（可能位于 RAID 卡后，或 USB 桥接不支持直通）"
        info "可手动尝试: smartctl -a -d sat $dev    MegaRAID: smartctl -a -d megaraid,0 $dev"
        info "SMART 不可用时仍可用 [5] 读性能曲线 / [6] 全盘读延迟扫描 评估盘面"
        head2 "3. 内核日志 I/O 错误"
        klog_check "$name"
        quick_save "$id" na "SMART 不可读"
        return
    fi
    [[ -n ${DOPT_CACHE[$name]} ]] && info "smartctl 访问方式: ${DOPT_CACHE[$name]}"

    local sinfo serial fw rpm sv
    sinfo=$(sm "$name" -i 2>&1)
    serial=$(grep -m1 -iE '^Serial [Nn]umber:' <<< "$sinfo" | sed 's/.*:[[:space:]]*//')
    fw=$(grep -m1 -E '^(Firmware Version|Revision):' <<< "$sinfo" | sed 's/.*:[[:space:]]*//')
    rpm=$(grep -m1 -E '^Rotation Rate:' <<< "$sinfo" | sed 's/.*:[[:space:]]*//')
    [[ -n $serial ]] && info "序列号   : $serial"
    [[ -n $fw     ]] && info "固件版本 : $fw"
    [[ -n $rpm    ]] && info "转速     : $rpm"

    if grep -q 'SMART support is:.*Unavailable' <<< "$sinfo"; then
        warn "该设备不支持 SMART"
        head2 "3. 内核日志 I/O 错误"; klog_check "$name"
        quick_save "$id" na "不支持 SMART"; return
    fi
    if grep -q 'SMART support is:.*Disabled' <<< "$sinfo"; then
        warn "SMART 已关闭，正在尝试开启…"
        if sm "$name" -s on >/dev/null 2>&1; then ok "SMART 已开启"; else warn "开启 SMART 失败"; fi
    else
        ok "SMART 已启用"
    fi

    # SATA 链路速率
    sv=$(grep -m1 '^SATA Version is:' <<< "$sinfo")
    if [[ -n $sv ]]; then
        local smax scur
        info "SATA 链路 : ${sv#*:  }"
        smax=$(grep -oE '[0-9.]+ Gb/s' <<< "$sv" | head -n1 | cut -d' ' -f1)
        scur=$(grep -oE 'current: [0-9.]+' <<< "$sv" | awk '{print $2}')
        if [[ -n $scur && -n $smax ]] && awk -v a="$scur" -v b="$smax" 'BEGIN{exit !(a<b)}'; then
            warn "链路当前 ${scur} Gb/s 低于硬盘支持的 ${smax} Gb/s —— 可能是线缆/背板接触不良，也可能是主板口或硬盘盒本身只支持该速率"
            pen 3 "SATA 链路降速 ${scur}Gb/s"
        fi
    fi

    local is_nvme=0 is_sas=0
    grep -qE '^NVMe Version|NVM Commands' <<< "$sinfo" && is_nvme=1
    grep -qE 'Transport protocol:.*SAS|^Vendor:' <<< "$sinfo" && is_sas=1

    #---- 3. 总体健康 ----
    head2 "3. SMART 总体健康判定"
    local health
    health=$(sm "$name" -H 2>&1)
    if grep -qE 'PASSED|: OK' <<< "$health"; then
        ok "总体健康自评: PASSED"
    elif grep -qiE 'FAILED|FAILURE' <<< "$health"; then
        bad "总体健康自评: FAILED —— 硬盘自判即将失效，请立即备份并更换！"
        pen 60 "SMART 总体健康 FAILED"
    else
        warn "无法解析总体健康状态"; dump "$(tail -n 3 <<< "$health")"
    fi

    #---- 4. 关键属性 ----
    head2 "4. 关键 SMART 属性"
    local SMART_A
    SMART_A=$(sm "$name" -A 2>/dev/null)
    get_raw() { awk -v id="$1" '$1==id && NF>=10 {print $10; exit}' <<< "$SMART_A"; }

    local reall pend offl runc cmdto crc spinr e2e poh pcyc lcc ssc temp revt
    reall=$(num "$(get_raw 5)");   pend=$(num "$(get_raw 197)"); offl=$(num "$(get_raw 198)")
    runc=$(num "$(get_raw 187)");  cmdto=$(num "$(get_raw 188)"); crc=$(num "$(get_raw 199)")
    spinr=$(num "$(get_raw 10)");  e2e=$(num "$(get_raw 184)");   revt=$(num "$(get_raw 196)")
    poh=$(num "$(get_raw 9)");     pcyc=$(num "$(get_raw 12)");   ssc=$(num "$(get_raw 4)")
    lcc=$(num "$(get_raw 193)");   temp=$(num "$(get_raw 194)")
    [[ $temp == 0 ]] && temp=$(num "$(get_raw 190)")
    [[ $temp == 0 ]] && temp=$(num "$(grep -m1 -iE 'Current Drive Temperature|^Temperature:' <<< "$SMART_A" | sed 's/[^0-9]*\([0-9]*\).*/\1/')")
    # 希捷 188 原始值是打包的多个计数，取低 16 位
    (( cmdto > 65535 )) && cmdto=$(( cmdto & 0xFFFF ))

    # 上次体检记录（history.csv: ts,poh,reall,pend,offl,runc,crc,temp,cmdto）与维修基线
    local hist="$STATE_DIR/$id/history.csv" has_prev=0
    local h_ts="" h_poh="" h_reall="" h_pend="" h_offl="" h_runc="" h_crc="" h_cmdto=""
    if [[ -s $hist ]]; then
        IFS=, read -r h_ts h_poh h_reall h_pend h_offl h_runc h_crc _ h_cmdto < <(tail -n1 "$hist")
        if [[ $h_ts =~ ^[0-9]{1,12}$ && $h_poh =~ ^[0-9]{1,15}$ && $h_reall =~ ^[0-9]{1,15}$ && $h_pend =~ ^[0-9]{1,15}$ && $h_offl =~ ^[0-9]{1,15}$ && $h_runc =~ ^[0-9]{1,15}$ && $h_crc =~ ^[0-9]{1,15}$ && $h_cmdto =~ ^[0-9]{1,15}$ ]]; then
            has_prev=1
        else
            h_crc=""; h_cmdto=""
        fi
    fi
    local P_TS=0 P_NOTE="" P_CRC="" P_CMDTO=""
    [[ -r $STATE_DIR/$id/repair.env ]] && read_record "$STATE_DIR/$id/repair.env" repair

    if (( is_nvme )); then
        local mde pused cw
        mde=$(num "$(grep -m1 -i 'Media and Data Integrity Errors' <<< "$SMART_A" | awk -F: '{print $2}')")
        pused=$(num "$(grep -m1 -i 'Percentage Used' <<< "$SMART_A" | awk -F: '{print $2}')")
        cw=$(grep -m1 -i 'Critical Warning' <<< "$SMART_A" | awk -F: '{gsub(/ /,"",$2);print $2}')
        poh=$(num "$(grep -m1 -i 'Power On Hours' <<< "$SMART_A" | awk -F: '{gsub(/[ ,]/,"",$2);print $2}')")
        info "NVMe 严重警告: ${cw:-?}   介质错误: $mde   寿命已用: ${pused}%"
        [[ -n $cw && $cw != 0x00 ]] && { bad "NVMe 严重警告位非零"; pen 40 "NVMe 严重警告 $cw"; }
        (( mde > 0 )) && { bad "存在介质/数据完整性错误 $mde"; pen 30 "NVMe 介质错误 $mde"; }
        (( pused >= 90 )) && { warn "寿命已用 ${pused}%"; pen 10 "寿命已用 ${pused}%"; }
    elif [[ -z $SMART_A || $is_sas -eq 1 ]] && ! grep -qE '^ *[0-9]+ ' <<< "$SMART_A"; then
        info "SAS/SCSI 盘，使用缺陷表与错误计数评估："
        local sasall grown ruerr
        sasall=$(sm "$name" -a 2>/dev/null)
        grown=$(num "$(grep -m1 -i 'grown defect list' <<< "$sasall" | sed 's/[^0-9]*\([0-9]*\).*/\1/')")
        ruerr=$(grep -m1 '^read:' <<< "$sasall" | awk '{print $NF}')
        info "增长型缺陷表 : $grown    读不可纠正错误: ${ruerr:-N/A}"
        if   (( grown > 50 )); then bad "缺陷表 $grown 条，介质劣化明显"; pen 40 "SAS 缺陷表 $grown"
        elif (( grown > 0 ));  then warn "缺陷表 $grown 条，需持续观察"; pen 15 "SAS 缺陷表 $grown"
        else ok "缺陷表为空"; fi
        (( $(num "${ruerr:-0}") > 0 )) && { bad "存在不可纠正读错误"; pen 30 "读不可纠正错误"; }
        poh=$(num "$(grep -m1 -i 'Accumulated power on time' <<< "$sasall" | sed 's/.*:[[:space:]]*//')")
    else
        pa() { out "$(printf '    %-4s %10s   %s' "$1" "$3" "$2")"; }
        out "$(printf '    %-4s %10s   %s' ID 原始值 属性)"
        pa 5   "重映射扇区"          "$reall"
        pa 196 "重映射事件"          "$revt"
        pa 197 "当前待映射扇区"      "$pend"
        pa 198 "脱机不可校正扇区"    "$offl"
        pa 187 "报告的不可纠正错误"  "$runc"
        pa 188 "命令超时"            "$cmdto"
        pa 199 "接口 CRC 错误"       "$crc"
        pa 10  "主轴启动重试"        "$spinr"
        pa 184 "端到端错误"          "$e2e"
        out ""

        if   (( reall == 0 ));   then ok "无重映射扇区"
        elif (( reall <= 10 ));  then warn "已重映射 $reall 个扇区，盘面开始出现缺陷，关注增长速度"; pen 15 "重映射扇区 $reall"
        elif (( reall <= 100 )); then bad "已重映射 $reall 个扇区，劣化明显，建议尽快更换"; pen 35 "重映射扇区 $reall"
        else                          bad "已重映射 $reall 个扇区，严重劣化，立即更换"; pen 55 "重映射扇区 $reall"
        fi
        if (( pend == 0 )); then ok "无待映射(不稳定)扇区"
        else bad "存在 $pend 个待映射扇区 —— 这些位置当前读不出来，数据风险高"; pen 30 "待映射扇区 $pend"; fi
        if (( offl == 0 )); then ok "无脱机不可校正扇区"
        else bad "存在 $offl 个不可校正扇区，已有数据丢失风险"; pen 30 "不可校正扇区 $offl"; fi
        (( runc > 0 ))  && { warn "报告的不可纠正错误 $runc 次"; pen $(( runc>10 ? 20 : 10 )) "不可纠正错误 $runc"; }
        (( e2e > 0 ))   && { bad "端到端错误 $e2e 次（数据通路/缓存异常）"; pen 15 "端到端错误 $e2e"; }
        (( spinr > 0 )) && { bad "主轴启动重试 $spinr 次（电机/供电异常）"; pen 20 "主轴重试 $spinr"; }
        # CRC(199) 与命令超时(188) 是终身累计值，不会清零：只看是否仍在增长
        cumu_check "接口 CRC 错误" "$crc" "$h_crc" "$P_CRC" 8 3 \
            "多为 SATA 线/供电/背板接触问题"
        (( cmdto > 100 || ( ${#h_cmdto} > 0 && cmdto > h_cmdto ) || ( ${#P_CMDTO} > 0 && cmdto > P_CMDTO ) )) && cumu_check "命令超时" "$cmdto" "$h_cmdto" "$P_CMDTO" 5 0 \
            "供电不足或线缆接触不良也会导致"

        local failed near
        failed=$(awk 'NF>=10 && $1 ~ /^[0-9]+$/ && $9!="-" && $9!="" {print "ID "$1" "$2" (WHEN_FAILED="$9")"}' <<< "$SMART_A")
        if [[ -n $failed ]]; then
            bad "以下属性已越过/曾越过厂商安全阈值："; dump "$failed"
            pen 20 "属性越过阈值"
        fi
        near=$(awk 'NF>=10 && $1 ~ /^[0-9]+$/ && $7=="Pre-fail" && $6+0>0 && $9=="-" && $5+0 <= $6+10 \
                    {print "ID "$1" "$2"  最差值 "$5" / 阈值 "$6}' <<< "$SMART_A")
        if [[ -n $near ]]; then
            warn "以下预失效属性的归一化值已接近阈值："; dump "$near"
            pen 5 "属性接近阈值"
        fi
    fi

    #---- 5. 温度 ----
    head2 "5. 温度"
    if (( temp > 0 )); then
        info "当前温度 : ${temp} °C"
        if   (( temp >= 60 )); then bad "温度过高，机械盘长期 >60°C 显著缩短寿命"; pen 25 "温度 ${temp}°C"
        elif (( temp >= 55 )); then warn "温度偏高，建议改善风道"; pen 15 "温度 ${temp}°C"
        elif (( temp >= 50 )); then warn "温度略高（理想 25-45°C）"; pen 5
        else ok "温度处于健康区间"; fi
    else
        info "未能读取温度"
    fi
    local lt ltmax
    lt=$(sm "$name" -l scttempsts 2>/dev/null | grep -m1 -i 'Lifetime.*Min/Max' | sed 's/.*:[[:space:]]*//')
    if [[ -n $lt ]]; then
        info "历史温度 : 最低/最高 $lt"
        ltmax=$(num "$(awk -F/ '{print $2}' <<< "$lt")")
        (( ltmax >= 65 )) && { warn "历史最高温度曾达 ${ltmax}°C"; pen 3 "历史最高温 ${ltmax}°C"; }
    fi

    #---- 6. 寿命与负载 ----
    head2 "6. 使用寿命与负载"
    if (( poh > 0 )); then
        info "累计通电 : ${poh} 小时 (约 $((poh/24)) 天 / $((poh/8760)) 年)"
        if   (( poh >= 50000 )); then warn "通电超 5 万小时，属超期服役，建议规划替换"; pen 15 "通电 ${poh}h"
        elif (( poh >= 35000 )); then warn "通电时长较高，建议加强备份与巡检"; pen 8
        else ok "通电时长在正常范围"; fi
    fi
    (( pcyc > 0 )) && info "通电次数 : $pcyc"
    (( ssc  > 0 )) && info "启停次数 : $ssc"
    if (( lcc > 0 )); then
        info "磁头加载/卸载 : $lcc"
        (( lcc >= 600000 )) && { warn "负载循环过高（>60 万），多见于激进省电，可 hdparm -B 254 调整"; pen 10 "负载循环 $lcc"; }
    fi

    #---- 7. 错误日志 ----
    head2 "7. SMART 错误日志"
    local elog ecount
    elog=$(sm "$name" -l error 2>/dev/null)
    if grep -qi 'No Errors Logged' <<< "$elog"; then
        ok "错误日志为空"
    else
        ecount=$(num "$(grep -m1 -iE 'ATA Error Count' <<< "$elog" | sed 's/[^0-9]*\([0-9]*\).*/\1/')")
        if (( ecount > 0 )); then
            bad "SMART 错误日志中有 $ecount 条记录（最近几条见下）"
            dump "$(grep -A3 -E '^Error [0-9]+ ' <<< "$elog" | head -n 16)"
            pen $(( ecount>20 ? 20 : 10 )) "错误日志 $ecount 条"
        else
            info "未解析到明确的错误计数（SAS/NVMe 请参考上方计数）"
        fi
    fi

    #---- 8. 自检历史（只读，不启动新自检）----
    head2 "8. 硬盘内部自检记录"
    local slog last
    slog=$(sm "$name" -l selftest 2>/dev/null)
    if grep -qi 'No self-tests have been logged' <<< "$slog"; then
        info "该盘从未执行过自检，建议运行 [3] 短自检 或 [4] 长自检"
    else
        last=$(grep -m1 -E '^#[[:space:]]*1[[:space:]]' <<< "$slog")
        info "最近一次 : ${last:-无记录}"
        grep -qiE 'failure|servo|handling damage' <<< "$slog" && warn "自检历史中存在失败记录（在自检项中计分）"
        record_selftest "$name" "$id" short "$poh" newer
        record_selftest "$name" "$id" long  "$poh" newer
    fi

    #---- 9. 配置项 ----
    head2 "9. 缓存 / 省电 / 错误恢复配置"
    local feats erc
    feats=$(sm "$name" -g wcache -g rcache -g apm 2>/dev/null | grep -E '^(Write cache|Rd look-ahead|Read cache|APM)')
    [[ -n $feats ]] && dump "$feats"
    erc=$(sm "$name" -l scterc 2>/dev/null | grep -E 'Read:|Write:|not supported|Disabled' | head -n 2 | sed 's/^[[:space:]]*//' | paste -sd' ')
    if [[ -n $erc ]]; then
        info "SCT ERC  : $erc"
        grep -qiE 'Disabled|not supported' <<< "$erc" && \
            info "  (组 RAID/ZFS 时建议盘支持并设置 ERC≈7 秒，避免坏道长时间重试被踢出阵列)"
    fi

    #---- 10. 内核日志 ----
    head2 "10. 内核日志 I/O 错误"
    klog_check "$name"

    #---- 11. 趋势 ----
    head2 "11. 坏道增长趋势"
    if (( has_prev )); then
        info "对比上次记录（$(age_str "$h_ts")，通电 ${h_poh}h）："
        local d_r=$((reall-h_reall)) d_p=$((pend-h_pend)) d_o=$((offl-h_offl)) d_u=$((runc-h_runc)) d_c=$((crc-h_crc))
        local changed=0
        (( d_r > 0 )) && { bad "重映射扇区增加 $d_r（$h_reall → $reall），坏道在扩散"; pen 15 "重映射增长 +$d_r"; changed=1; }
        (( d_p > 0 )) && { bad "待映射扇区增加 $d_p（$h_pend → $pend）"; pen 10 "待映射增长 +$d_p"; changed=1; }
        (( d_o > 0 )) && { bad "不可校正扇区增加 $d_o"; pen 10 "不可校正增长 +$d_o"; changed=1; }
        (( d_u > 0 )) && { warn "不可纠正错误增加 $d_u"; changed=1; }
        (( d_c > 0 )) && { warn "CRC 错误增加 $d_c（已在属性项计分）"; changed=1; }
        (( d_p < 0 )) && { info "待映射扇区减少 $((-d_p))（已被重映射或重写恢复）"; changed=1; }
        (( changed )) || ok "关键计数与上次相比无增长"
    else
        info "首次记录，下次体检时会与本次对比坏道增长趋势"
    fi
    if (( P_TS > 0 )); then
        info "维修记录 : $(age_str "$P_TS")，${P_NOTE}；维修后 CRC $(( crc - ${P_CRC:-$crc} >= 0 ? crc - ${P_CRC:-$crc} : 0 )) 次新增"
    fi
    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s\n' "$(now)" "$poh" "$reall" "$pend" "$offl" "$runc" "$crc" "$temp" "$cmdto" >> "$hist"

    local sum="无异常"
    (( ${#CUR_ISS[@]} )) && sum="$(join_by '，' "${CUR_ISS[@]}")"
    quick_save "$id" "" "$sum"
}

mod_quick() {
    local name
    for name in "$@"; do
        [[ $INTERRUPTED -eq 1 ]] && break
        decide_run "${DID[$name]}" quick "$name"
        dec_note "$name" quick || continue
        quick_one "$name"
    done
}

#==============================================================================
#  模块二：SMART 自检
#==============================================================================
# 读取硬盘自检日志中某类型的最近一条 -> ST_LINE ST_LIFE ST_LBA ST_LOG
selftest_latest() {
    local name=$1 type=$2 pat
    [[ $type == short ]] && pat='Short|Background short' || pat='Extended|Background long'
    ST_LOG=$(sm "$name" -l selftest 2>/dev/null)
    ST_LINE=$(grep -E '^#[[:space:]]*[0-9]+' <<< "$ST_LOG" | grep -m1 -E "$pat")
    ST_LIFE=""; ST_LBA=""
    [[ -n $ST_LINE ]] || return 1
    read -r ST_LIFE ST_LBA < <(awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+%$/){print $(i+1), $(i+2); exit}}' <<< "$ST_LINE")
    return 0
}
selftest_classify() {
    case "${ST_LINE,,}" in
        *"completed without error"*|*"background "*"completed "*)      ST_STATUS=good ;;
        *"in progress"*)                                               ST_STATUS=running ;;
        *aborted*|*interrupted*)                                       ST_STATUS=incomplete ;;
        *failure*|*servo*|*"handling damage"*|*failed*)                ST_STATUS=bad ;;
        *)                                                             ST_STATUS=incomplete ;;
    esac
}

# 把硬盘日志里的最近结果写入结果库
# record_selftest <name> <id> <short|long> <poh> [newer]  newer=只在比已存结果新时写入
record_selftest() {
    local name=$1 id=$2 type=$3 poh=${4:-0} mode=${5:-force} mod="selftest_$3" ts d
    selftest_latest "$name" "$type" || return 1
    selftest_classify
    [[ $ST_STATUS == running ]] && return 1
    ts=$(now)
    if (( poh > 0 )) && [[ $ST_LIFE =~ ^[0-9]+$ ]]; then
        d=$(( poh - ST_LIFE )); (( d < 0 )) && d=$(( poh % 65536 - ST_LIFE )); (( d < 0 )) && d=0
        ts=$(( ts - d*3600 ))
    elif [[ $mode == newer ]]; then
        load_result "$id" "$mod" && return 1        # 无法定时间，已有结果则不覆盖
    fi
    if [[ $mode == newer ]] && load_result "$id" "$mod" && (( R_TS >= ts - 3600 )); then
        return 1
    fi
    CUR_DED=0; CUR_ISS=()
    local label=${MOD_LABEL[$mod]} sum
    case $ST_STATUS in
        good) sum="通过" ;;
        bad)  pen "$([[ $type == long ]] && echo 45 || echo 35)" "${label}失败 (首错 LBA ${ST_LBA:--})"
              sum="失败，首个错误 LBA ${ST_LBA:--}" ;;
        incomplete) sum="未完成（被中断或中止）" ;;
    esac
    if [[ $type == long && $ST_STATUS == good ]] \
       && grep -E '^#' <<< "$ST_LOG" | grep -qiE 'failure|servo|handling damage'; then
        pen 5 "自检历史中曾有失败"; sum="$sum（历史中曾有失败记录）"
    fi
    [[ $mode == newer ]] && sum="$sum〔取自硬盘自检日志〕"
    RES_TS=$ts
    save_result "$id" "$mod" "$ST_STATUS" "$sum" "R_LINE=$ST_LINE"
    return 0
}

selftest_running() {
    sm "$1" -c 2>/dev/null | grep -qi 'in progress' && return 0
    sm "$1" -l selftest 2>/dev/null | grep -m1 -E '^#' | grep -qi 'in progress'
}
selftest_remaining() { sm "$1" -c 2>/dev/null | grep -oE '[0-9]+% of test remaining' | grep -oE '^[0-9]+'; }
selftest_minutes() {
    local c pat; c=$(sm "$1" -c 2>/dev/null)
    [[ $2 == short ]] && pat='Short self-test routine' || pat='Extended self-test routine'
    local m; m=$(grep -A1 -i "$pat" <<< "$c" | grep -oE '\( *[0-9]+\)' | tr -dc '0-9')
    if [[ -z $m ]]; then
        m=$(grep -iE "$([[ $2 == short ]] && echo 'Short' || echo 'Long \(extended\)') Self-test duration" <<< "$c" | grep -oE '[0-9]+' | head -n1)
        [[ -n $m ]] && m=$(( m/60 ))
    fi
    echo "${m:-}"
}

# 并行监控多块盘的自检
selftest_monitor() {
    local type=$1 allow_bg=$2; shift 2
    local -a names=("$@")
    local n maxwait start=$SECONDS alive rem last_keep=$SECONDS mins maxmin=0 last_log=$SECONDS
    for n in "${names[@]}"; do mins=$(selftest_minutes "$n" "$type"); (( ${mins:-0} > maxmin )) && maxmin=${mins:-0}; done
    if [[ $type == short ]]; then maxwait=1800; else maxwait=$(( maxmin>0 ? maxmin*60*3+7200 : 86400 )); fi
    MON_RESULT="done"
    IN_TASK=1; DRAWN=0
    say ""
    cursor l
    while true; do
        alive=0; REDRAW_LINES=()
        for n in "${names[@]}"; do
            if selftest_running "$n"; then
                alive=$((alive+1)); rem=$(selftest_remaining "$n")
                REDRAW_LINES+=("  /dev/$n   ${C_BLU}进行中${C_OFF}   剩余 ${rem:-?}%")
            else
                REDRAW_LINES+=("  /dev/$n   ${C_GRN}已结束${C_OFF}")
            fi
        done
        REDRAW_LINES+=("  已等待 $(fmt_dur $((SECONDS-start)))")
        if (( allow_bg )); then
            REDRAW_LINES+=("  ${C_DIM}[X] 中止全部自检   [B] 放到后台继续（自检在硬盘内部运行，可返回菜单）${C_OFF}")
        else
            REDRAW_LINES+=("  ${C_DIM}[X] 中止全部自检并结束评估${C_OFF}")
        fi
        [[ $BATCH -eq 1 ]] || redraw
        if [[ ! -t 1 || $DETACHED -eq 1 ]] && (( SECONDS - last_log >= 1800 )); then
            out "    [$(printf '%(%F %T)T' -1)] 自检进度: ${REDRAW_LINES[*]:0:${#names[@]}}"; last_log=$SECONDS
        fi
        (( alive == 0 )) && break
        if (( SECONDS - start > maxwait )); then MON_RESULT=timeout; break; fi
        # USB 硬盘盒空闲会休眠导致长自检中断，定期读一个扇区保活
        if (( SECONDS - last_keep >= 60 )); then
            for n in "${names[@]}"; do
                [[ ${D_TRAN[$(di "$n")]} == usb ]] && ( trap '' HUP; exec dd if="/dev/$n" of=/dev/null bs=4096 count=1 iflag=direct ) 2>/dev/null
            done
            last_keep=$SECONDS
        fi
        poll_key 5
        if [[ $INTERRUPTED -eq 1 ]]; then MON_RESULT="bg"; break; fi
        [[ -e $RUN_DIR/stop_all ]] && { MON_RESULT="bg"; INTERRUPTED=1; break; }
        case $KEY in
            X) for n in "${names[@]}"; do sm "$n" -X >/dev/null 2>&1; done; MON_RESULT=aborted; sleep 2; break ;;
            B) (( allow_bg )) && { MON_RESULT="bg"; break; } ;;
        esac
    done
    cursor h
    IN_TASK=0
}

mod_selftest() {
    local type=$1 allow_bg=$2; shift 2
    local mod="selftest_$type" label name id poh mins
    label=${MOD_LABEL[$mod]}
    local -a run=()
    head1 "$label"
    [[ $type == long ]] && info "长自检由硬盘固件逐扇区读取整个盘面，期间硬盘可正常使用，但会变慢"
    for name in "$@"; do
        [[ $INTERRUPTED -eq 1 ]] && break
        id=${DID[$name]}
        if [[ ${DOPT_CACHE[$name]} == "__FAIL__" ]]; then warn "/dev/$name SMART 不可用，跳过"; continue; fi
        poh=$(get_poh "$name")
        record_selftest "$name" "$id" "$type" "$poh" newer

        if selftest_running "$name"; then
            info "/dev/$name 当前已有自检在进行（剩余 $(selftest_remaining "$name")%）"
            if (( BATCH )) || [[ -n ${PLAN["$mod:$name"]:-} ]]; then run+=("$name"); continue; fi
            choose "    [W] 等待其完成   [X] 中止并重新开始   [S] 跳过  > " W X S || continue
            case $KEY in
                W) run+=("$name"); continue ;;
                S) continue ;;
                X) sm "$name" -X >/dev/null 2>&1; sleep 2 ;;
            esac
        else
            decide_run "$id" "$mod" "$name"
            dec_note "$name" "$mod" || continue
        fi
        mins=$(selftest_minutes "$name" "$type")
        if sm "$name" -t "$type" >/dev/null 2>&1; then
            ok "/dev/$name 已启动，硬盘预计需要 ${mins:-?} 分钟"
            run+=("$name")
        else
            bad "/dev/$name 启动自检失败"
        fi
    done
    (( ${#run[@]} )) || return 0
    sleep 2
    selftest_monitor "$type" "$allow_bg" "${run[@]}"

    head2 "$label 结果"
    case $MON_RESULT in
        aborted) warn "已按要求中止自检" ;;
        timeout) warn "等待超时，自检可能仍在硬盘内部运行" ;;
        bg)      info "自检仍在硬盘内部继续运行，稍后在 [R] 综合报告 中会自动读取结果" ;;
    esac
    for name in "${run[@]}"; do
        id=${DID[$name]}
        if selftest_running "$name"; then
            CUR_DED=0; CUR_ISS=()
            save_result "$id" "$mod" running "运行中（开始于 $(printf '%(%m-%d %H:%M)T' -1)）"
            info "/dev/$name  仍在运行"
            continue
        fi
        record_selftest "$name" "$id" "$type" "$(get_poh "$name")" force
        load_result "$id" "$mod"
        case $R_STATUS in
            good) ok  "/dev/$name  $R_SUMMARY" ;;
            bad)  bad "/dev/$name  $R_SUMMARY" ;;
            *)    warn "/dev/$name  $R_SUMMARY" ;;
        esac
    done
    [[ $MON_RESULT == aborted ]] && INTERRUPTED=1
    return 0
}

#==============================================================================
#  模块三：读性能曲线
#==============================================================================
# read_mib <dev> <offset_MiB> <count_MiB> -> RD_OK RD_KBS RD_USEC
# 计时优先用 bash 5 的 EPOCHREALTIME（墙钟，微秒），否则解析 dd 自报耗时
read_mib() {
    local o rc t0="" t1 b=0
    [[ -n ${EPOCHREALTIME:-} ]] && t0=${EPOCHREALTIME//[!0-9]/}
    o=$(trap '' HUP; LC_ALL=C exec dd if="$1" of=/dev/null bs=1M count="$3" skip="$2" iflag=direct 2>&1); rc=$?
    [[ -n $t0 ]] && t1=${EPOCHREALTIME//[!0-9]/}
    RD_KBS=0; RD_USEC=0
    if [[ $o =~ ([0-9]+)\ bytes.*copied,\ ([0-9]+)(\.([0-9]+))?\ s ]]; then
        local si=${BASH_REMATCH[2]} sf=${BASH_REMATCH[4]}
        b=${BASH_REMATCH[1]}
        if [[ -n $t0 ]]; then
            RD_USEC=$(( 10#$t1 - 10#$t0 ))
        else
            sf="${sf}000000"; sf=${sf:0:6}
            RD_USEC=$(( 10#$si*1000000 + 10#$sf ))
        fi
        (( RD_USEC < 1 )) && RD_USEC=1
        RD_KBS=$(( b * 1000000 / RD_USEC / 1024 ))
    fi
    (( rc == 0 )) && RD_OK=1 || RD_OK=0
}

speed_one() {
    local name=$1 dev="/dev/$1" id=${DID[$1]}
    local size tot_mib pts=$SAMPLE_POINTS mb=$SAMPLE_MB k off
    size=$(blockdev --getsize64 "$dev" 2>/dev/null); size=${size:-0}
    tot_mib=$(( size / 1048576 ))
    CUR_DED=0; CUR_ISS=()
    head1 "读性能曲线 · $dev"
    if (( tot_mib < mb * 2 )); then warn "容量过小，跳过"; return; fi
    MOUNTED=0
    [[ -n $(lsblk -nr -o MOUNTPOINT "$dev" 2>/dev/null | tr -d '[:space:]') ]] && MOUNTED=1
    (( MOUNTED )) && warn "该盘已挂载，若有其它读写，速度会偏低（已对异常点自动复测）"
    info "在全盘 ${pts} 个等距位置各读取 ${mb} MiB（O_DIRECT，只读）"
    local -a sp=()
    local errs=0
    for ((k=0; k<pts; k++)); do
        [[ -e $RUN_DIR/stop_all ]] && INTERRUPTED=1
        [[ $INTERRUPTED -eq 1 ]] && { warn "已中断"; return; }
        off=$(( (tot_mib - mb) * k / (pts-1) ))
        IN_TASK=1; read_mib "$dev" "$off" "$mb"; IN_TASK=0
        (( RD_OK )) || { RD_KBS=0; errs=$((errs+1)); }
        sp+=("$RD_KBS")
        prog '\r    采样 %d/%d  当前 %s MB/s \e[K' "$((k+1))" "$pts" "$(mbs "$RD_KBS")"
    done
    prog '\r\e[K'

    # 异常点复测：低于两侧均值 60% 的点再读一次取较大值
    local -a flag=()
    local nb anom=0
    for ((k=0; k<pts; k++)); do
        flag[k]=0
        if (( k==0 )); then nb=${sp[1]}; elif (( k==pts-1 )); then nb=${sp[k-1]}
        else nb=$(( (sp[k-1]+sp[k+1])/2 )); fi
        if (( sp[k]*100 < nb*60 )); then
            off=$(( (tot_mib - mb) * k / (pts-1) ))
            read_mib "$dev" "$off" "$mb"
            (( RD_OK && RD_KBS > sp[k] )) && sp[k]=$RD_KBS
            if (( sp[k]*100 < nb*60 )); then flag[k]=1; anom=$((anom+1)); fi
            : # First-pass failures are counted above even when a retry succeeds.
        fi
    done

    local max=0 min=999999999 sum=0 w bar pos mark
    for k in "${sp[@]}"; do (( k>max )) && max=$k; (( k<min )) && min=$k; sum=$((sum+k)); done
    (( max == 0 )) && { bad "所有采样点读取失败"; pen 30 "读取失败"; save_result "$id" speed bad "读取失败"; return; }
    head2 "速度曲线（外圈 → 内圈）"
    for ((k=0; k<pts; k++)); do
        w=$(( sp[k] * 40 / max )); printf -v bar '%*s' "$w" ''; bar=${bar// /█}
        pos=$(( k*100/(pts-1) ))
        mark=""; (( flag[k] )) && mark="  ${C_RED}◀ 凹陷${C_OFF}"
        out "$(printf '    %3d%%  %-40s %6s MB/s' "$pos" "$bar" "$(mbs "${sp[k]}")")$mark"
    done
    local avg=$(( sum/pts )) outer=${sp[0]} inner=${sp[pts-1]}
    out ""
    info "峰值 $(mbs $max) MB/s   最低 $(mbs $min) MB/s   平均 $(mbs $avg) MB/s   内/外圈比 $(( outer>0 ? inner*100/outer : 0 ))%"

    local rota=${D_ROTA[$(di "$name")]} tran=${D_TRAN[$(di "$name")]}
    if [[ $rota == 1 ]] && (( max < 60*1024 )); then
        warn "整体读速度偏低（峰值 < 60 MB/s）"
        [[ $tran == usb ]] && info "  USB 连接：若为 USB 2.0 口/盒，上限约 35-40 MB/s，属正常"
        pen 10 "整体读速度偏低"
    fi
    if (( errs > 0 )); then bad "有 $errs 个采样点读取出错"; pen 30 "采样点读取出错 $errs"; fi
    if (( anom > 0 )); then
        warn "速度曲线有 $anom 处明显凹陷，可能是弱扇区反复重试，建议做 [6] 全盘读延迟扫描定位"
        local p=$(( anom*8 )); (( p > 20 )) && p=20; pen $p "速度凹陷 $anom 处"
    else
        ok "速度曲线平滑，无明显凹陷"
    fi
    [[ $rota == 1 ]] && (( outer > 0 && inner*100/outer < 25 )) && { warn "内圈速度不足外圈 25%，偏离正常衰减规律"; pen 5 "内圈速度异常低"; }

    # 与上次曲线对比
    if load_result "$id" speed && [[ -n $R_CURVE ]]; then
        local oldsum=0 c cnt=0
        for c in $R_CURVE; do
            [[ $c =~ ^[0-9]{1,12}$ ]] || { cnt=0; break; }
            oldsum=$((oldsum+c)); cnt=$((cnt+1))
        done
        if (( cnt > 0 )); then
            local oldavg=$(( oldsum/cnt ))
            if (( oldavg > 0 && avg*100 < oldavg*75 )); then
                warn "平均速度较上次（$(age_str "$R_TS")）下降 $(( 100 - avg*100/oldavg ))%"
                pen 5 "读速度较上次下降"
            else
                info "与上次（$(age_str "$R_TS")）相比平均速度变化 $(( avg*100/oldavg - 100 ))%"
            fi
        fi
    fi
    local sum_txt
    sum_txt="峰值 $(mbs $max) / 平均 $(mbs $avg) MB/s，凹陷 $anom 处"
    save_result "$id" speed "$(status_of_ded)" "$sum_txt" "R_CURVE=${sp[*]}"
}

mod_speed() {
    local name
    for name in "$@"; do
        [[ $INTERRUPTED -eq 1 ]] && break
        decide_run "${DID[$name]}" speed "$name"
        dec_note "$name" speed || continue
        speed_one "$name"
    done
}

#==============================================================================
#  模块四：全盘读延迟扫描（类 Victoria，可续扫、可并行）
#==============================================================================
surface_reset_vars() {
    S_NEXT=0; S_TOTAL=0; S_CHUNK=$CHUNK_MB; S_OK=0; S_SLOW=0; S_VSLOW=0; S_ERR=0; S_TRANS=0
    S_EMA=0; S_KBS=0; S_ELAPSED=0; S_SIZE=0; S_DONE=0; S_TS_START=0; S_TS_UPD=0
}
surface_write() {
    printf -v S_TS_UPD '%(%s)T' -1
    printf 'S_NEXT=%s\nS_TOTAL=%s\nS_CHUNK=%s\nS_OK=%s\nS_SLOW=%s\nS_VSLOW=%s\nS_ERR=%s\nS_TRANS=%s\nS_EMA=%s\nS_KBS=%s\nS_ELAPSED=%s\nS_SIZE=%s\nS_DONE=%s\nS_TS_START=%s\nS_TS_UPD=%s\n' \
        "$S_NEXT" "$S_TOTAL" "$S_CHUNK" "$S_OK" "$S_SLOW" "$S_VSLOW" "$S_ERR" "$S_TRANS" \
        "$S_EMA" "$S_KBS" "$S_ELAPSED" "$S_SIZE" "$S_DONE" "$S_TS_START" "$S_TS_UPD" > "$1.tmp" \
        && mv -f "$1.tmp" "$1"
}
surface_load() {
    surface_reset_vars
    [[ -r $1 ]] || return 1
    read_record "$1" surface || return 1
    # Zero total is valid before initialization, but never with saved progress.
    (( S_NEXT == 0 )) && return 0
    (( S_TOTAL > 0 && S_CHUNK > 0 && S_NEXT <= S_TOTAL )) && grep -q '^S_CHUNK=' "$1"
}

surface_init() {
    local name=$1 id=${DID[$1]} size
    size=$(blockdev --getsize64 "/dev/$name" 2>/dev/null); size=${size:-0}
    surface_reset_vars
    S_CHUNK=$CHUNK_MB; S_SIZE=$size
    S_TOTAL=$(( (size + CHUNK_MB*1048576 - 1) / (CHUNK_MB*1048576) ))
    S_TS_START=$(now)
    : > "$STATE_DIR/$id/surface.map"
    surface_write "$STATE_DIR/$id/surface.state"
}

# 后台工作进程：逐块读取、测速、分类，每块写一次进度（可随时停下续扫）
surface_worker() {
    local name=$1 id=$2 dev="/dev/$1"
    local st="$STATE_DIR/$id/surface.state" map="$STATE_DIR/$id/surface.map"
    trap '' HUP
    surface_load "$st" || return
    local base=$S_ELAPSED t0=$SECONDS k k2
    while (( S_NEXT < S_TOTAL )); do
        [[ -e $RUN_DIR/stop_all || -e $RUN_DIR/$name.stop ]] && break
        read_mib "$dev" $(( S_NEXT * S_CHUNK )) "$S_CHUNK"
        if (( RD_OK == 0 )); then
            read_mib "$dev" $(( S_NEXT * S_CHUNK )) "$S_CHUNK"         # 复读确认
            if (( RD_OK == 0 )); then
                S_ERR=$((S_ERR+1)); echo "$S_NEXT E 0" >> "$map"; RD_KBS=0
            else
                S_TRANS=$((S_TRANS+1)); S_OK=$((S_OK+1))
            fi
        else
            k=$RD_KBS
            (( S_EMA == 0 )) && S_EMA=$k
            if (( k*100 >= S_EMA*50 )); then
                S_OK=$((S_OK+1)); S_EMA=$(( (S_EMA*7 + k) / 8 ))
            else
                read_mib "$dev" $(( S_NEXT * S_CHUNK )) "$S_CHUNK"     # 慢块复测，排除偶发干扰
                k2=$RD_KBS; (( RD_OK && k2 > k )) && k=$k2
                if   (( k*100 >= S_EMA*50 )); then S_TRANS=$((S_TRANS+1)); S_OK=$((S_OK+1))
                elif (( k*100 >= S_EMA*20 )); then S_SLOW=$((S_SLOW+1));   echo "$S_NEXT S $k" >> "$map"
                else                               S_VSLOW=$((S_VSLOW+1)); echo "$S_NEXT V $k" >> "$map"
                fi
                RD_KBS=$k
            fi
        fi
        S_KBS=$RD_KBS
        S_NEXT=$((S_NEXT+1))
        S_ELAPSED=$(( base + SECONDS - t0 ))
        surface_write "$st"
    done
    (( S_NEXT >= S_TOTAL )) && { S_DONE=1; surface_write "$st"; }
}

# 监控界面
declare -A SW_PID=() SW_START=()
surface_monitor() {
    local -a names=("$@")
    local n alive pct w bar eta done_s t0=$SECONDS stopping=0 last_log=$SECONDS
    IN_TASK=1; DRAWN=0
    say ""
    cursor l
    while true; do
        alive=0; REDRAW_LINES=()
        for n in "${names[@]}"; do
            kill -0 "${SW_PID[$n]}" 2>/dev/null && alive=$((alive+1))
            surface_load "$STATE_DIR/${DID[$n]}/surface.state"
            (( S_TOTAL > 0 )) || continue
            pct=$(( S_NEXT*1000 / S_TOTAL ))
            w=$(( pct*24/1000 )); printf -v bar '%*s' "$w" ''; bar=${bar// /#}
            printf -v bar '%-24s' "$bar"; bar=${bar// /-}
            done_s=$(( S_NEXT - ${SW_START[$n]:-0} ))
            if (( done_s > 0 )); then eta="剩$(fmt_dur $(( (SECONDS-t0) * (S_TOTAL-S_NEXT) / done_s )))"; else eta="剩余估算中"; fi
            (( S_DONE )) && eta="完成"
            REDRAW_LINES+=("$(printf '  %-5s [%s] %3d.%d%% %6sMB/s  慢%-4d 极慢%-4d 错%-3d %s' \
                "$n" "$bar" $((pct/10)) $((pct%10)) "$(mbs "$S_KBS")" "$S_SLOW" "$S_VSLOW" "$S_ERR" "$eta")")
        done
        if (( stopping )); then REDRAW_LINES+=("  ${C_YEL}正在停止（当前块读完即停并保存进度）…${C_OFF}")
        else REDRAW_LINES+=("  ${C_DIM}[P] 暂停并保存进度（下次可从断点继续）${C_OFF}"); fi
        [[ $BATCH -eq 1 ]] || redraw
        if [[ ! -t 1 || $DETACHED -eq 1 ]] && (( SECONDS - last_log >= 600 )); then
            for n in "${REDRAW_LINES[@]:0:${#names[@]}}"; do out "    [$(printf '%(%F %T)T' -1)]$n"; done
            last_log=$SECONDS
        fi
        (( alive == 0 )) && break
        poll_key 1
        if [[ $KEY == P || $INTERRUPTED -eq 1 ]]; then : > "$RUN_DIR/stop_all"; stopping=1; fi
        [[ -e $RUN_DIR/stop_all ]] && stopping=1
    done
    for n in "${names[@]}"; do wait "${SW_PID[$n]}" 2>/dev/null; done
    cursor h
    IN_TASK=0
    [[ -e $RUN_DIR/stop_all ]] && INTERRUPTED=1
}

# 决定续扫/重扫 -> DEC = continue | restart | run | reuse | skip
surface_decide() {
    local name=$1 id=${DID[$1]} key="surface:$1"
    if [[ -n ${PLAN[$key]:-} ]]; then DEC=${PLAN[$key]}; return; fi
    if surface_load "$STATE_DIR/$id/surface.state" && (( S_DONE == 0 && S_NEXT > 0 )); then
        local pct=$(( S_NEXT*1000 / S_TOTAL ))
        say "    /dev/$name 有未完成的扫描：已完成 $((pct/10)).$((pct%10))%（块 ${S_CHUNK}MiB，最后进度于 $(age_str "$S_TS_UPD")）"
        (( S_CHUNK != CHUNK_MB )) && say "    ${C_DIM}（续扫将沿用当时的块大小 ${S_CHUNK}MiB）${C_OFF}"
        if (( BATCH )); then
            (( FORCE_RESCAN )) && DEC="restart" || DEC="continue"; return
        fi
        case $RESCAN_POLICY in
            rescan) DEC="restart"; return ;;
            reuse)  DEC="continue"; return ;;
        esac
        if choose "    [C] 从断点继续   [R] 从头重新扫描   [S] 跳过  > " C R S; then
            case $KEY in C) DEC="continue" ;; R) DEC="restart" ;; S) DEC=skip ;; esac
        else DEC=skip; fi
        return
    fi
    decide_run "$id" surface "$name"
}

# badblocks 块大小：保证块号 < 2^32（>16TB 盘必须加大）
bb_bs() { local size=$1 bs=4096; while (( size / bs > 4294967295 )); do bs=$((bs*2)); done; echo "$bs"; }

# 用 badblocks 精确复查异常块 -> BB_FOUND
bb_recheck() {
    local name=$1 id=${DID[$1]} dev="/dev/$1" map
    map="$STATE_DIR/$id/surface.map"
    BB_FOUND=0
    command -v badblocks >/dev/null 2>&1 || { warn "未安装 badblocks (e2fsprogs)，跳过复查"; return; }
    local bs per first last maxb idx t k=0 n tmp
    bs=$(bb_bs "$S_SIZE"); per=$(( S_CHUNK*1048576 / bs )); maxb=$(( S_SIZE / bs - 1 ))
    mapfile -t _chunks < <(awk '$2=="E"||$2=="V"{print $1}' "$map" | sort -n -u | head -n 64)
    n=${#_chunks[@]}
    (( n )) || return
    info "用 badblocks 复查 $n 个错误/极慢块（每块 ${S_CHUNK}MiB，块大小 ${bs}B）…"
    tmp=$(mktemp)
    IN_TASK=1
    for idx in "${_chunks[@]}"; do
        [[ $INTERRUPTED -eq 1 ]] && break
        k=$((k+1)); first=$(( idx*per )); last=$(( first+per-1 )); (( last > maxb )) && last=$maxb
        prog '\r    复查 %d/%d …\e[K' "$k" "$n"
        ( trap '' HUP; exec badblocks -b "$bs" "$dev" "$last" "$first" ) 2>/dev/null >> "$tmp"
    done
    IN_TASK=0
    prog '\r\e[K'
    BB_FOUND=$(grep -c '^[0-9]' "$tmp")
    if (( BB_FOUND > 0 )); then
        bad "badblocks 确认 $BB_FOUND 个坏块（块大小 ${bs}B，前 10 个）："
        dump "$(head -n 10 "$tmp" | paste -sd' ')"
        cp "$tmp" "$STATE_DIR/$id/recheck-badblocks.txt"
    else
        ok "badblocks 复查未发现不可读块（极慢块属于弱扇区：能读出但需多次重试）"
    fi
    rm -f "$tmp"
}

surface_finalize() {
    local name=$1 id=${DID[$1]}
    local map="$STATE_DIR/$id/surface.map"
    surface_load "$STATE_DIR/$id/surface.state"
    CUR_DED=0; CUR_ISS=()
    head2 "全盘读延迟扫描结果 · /dev/$name"
    local avg=$(( S_SIZE / 1024 / (S_ELAPSED>0 ? S_ELAPSED : 1) ))
    info "块大小 ${S_CHUNK} MiB，共 ${S_TOTAL} 块，用时 $(fmt_dur "$S_ELAPSED")，平均 $(mbs $avg) MB/s"
    info "正常 ${S_OK}（其中复测后正常 ${S_TRANS}）  慢 ${S_SLOW}  极慢 ${S_VSLOW}  读错误 ${S_ERR}"
    info "${C_DIM}判定: 慢 = 低于附近正常速度 50%；极慢 = 低于 20%；读错误 = 连续两次读取失败${C_OFF}"

    if [[ -s $map ]]; then
        info "异常区域（相邻块已合并，最多列 20 段）："
        dump "$(sort -n "$map" | awk -v c="$S_CHUNK" '
            function flush(){ if(s!=""){ t=(ty=="E")?"读错误":(ty=="V")?"极慢":"慢";
                printf "%-6s %10.2f GB - %10.2f GB  (%d 块)\n", t, s*c*1.048576/1000, (e+1)*c*1.048576/1000, e-s+1 } }
            { if($1==e+1 && $2==ty){e=$1} else {flush(); s=$1; e=$1; ty=$2} }
            END{flush()}' | head -n 20)"
    fi

    (( S_ERR > 0 ))   && { bad "发现 $S_ERR 个不可读块 —— 存在实际坏道"; pen 40 "表面读错误 $S_ERR 块"; }
    if   (( S_VSLOW > 5 )); then bad "极慢块 $S_VSLOW 个，存在较多弱扇区"; pen 25 "极慢块 $S_VSLOW"
    elif (( S_VSLOW > 0 )); then warn "极慢块 $S_VSLOW 个（弱扇区征兆）"; pen 15 "极慢块 $S_VSLOW"; fi
    if   (( S_SLOW > S_TOTAL/200 && S_SLOW > 0 )); then warn "慢块 $S_SLOW 个，占比偏高"; pen 10 "慢块 $S_SLOW"
    elif (( S_SLOW > 0 )); then info "慢块 $S_SLOW 个，占比很小，可结合其它项判断"; pen 3; fi
    (( S_TRANS >= 5 && S_TRANS*100 > S_TOTAL )) && info "复测后恢复正常的块较多（${S_TRANS}），扫描期间可能有其它 I/O 干扰"
    (( S_ERR + S_VSLOW + S_SLOW == 0 )) && ok "全盘读取无慢块、无错误"

    if (( S_ERR + S_VSLOW > 0 )); then
        local doit=0 pol=${PLAN_RECHECK:-$AUTO_RECHECK}
        case $pol in
            always) doit=1 ;;
            never)  doit=0 ;;
            *) ask_yn "是否用 badblocks 精确复查这些异常块?" Y && doit=1 ;;
        esac
        if (( doit )); then
            bb_recheck "$name"
            if (( BB_FOUND > 0 && S_ERR == 0 )); then pen 30 "badblocks 确认坏块 $BB_FOUND"; fi
            (( BB_FOUND == 0 && S_ERR > 0 )) && info "复查未复现读错误：可能已被硬盘重映射，请看 SMART 05/197 是否变化"
        fi
    fi
    local sum
    sum="错误 $S_ERR · 极慢 $S_VSLOW · 慢 $S_SLOW · 均速 $(mbs $avg) MB/s"
    save_result "$id" surface "$(status_of_ded)" "$sum"
}

mod_surface() {
    local name id size est=0 maxest=0 e
    local -a torun=()
    head1 "全盘读延迟扫描（类 Victoria，只读）"
    info "逐块读取整个盘面并计时：能发现 badblocks 发现不了的「能读但很慢」的弱扇区"
    for name in "$@"; do
        [[ $INTERRUPTED -eq 1 ]] && return
        id=${DID[$name]}
        surface_decide "$name"
        case $DEC in
            skip)     info "/dev/$name 跳过"; continue ;;
            reuse)    info "/dev/$name 沿用上次扫描结果"; continue ;;
            continue) info "/dev/$name 将从断点继续" ;;
            restart|run) surface_init "$name" ;;
        esac
        surface_load "$STATE_DIR/$id/surface.state"
        e=$(( (S_TOTAL - S_NEXT) * S_CHUNK / 150 ))     # 按 150MB/s 粗估
        est=$((est+e)); (( e > maxest )) && maxest=$e
        [[ -n $(lsblk -nr -o MOUNTPOINT "/dev/$name" 2>/dev/null | tr -d '[:space:]') ]] && \
            warn "/dev/$name 已挂载：扫描是只读的，但会占用磁盘带宽，结果也会受其它读写干扰"
        torun+=("$name")
    done
    (( ${#torun[@]} )) || return 0
    if (( PARALLEL && ${#torun[@]} > 1 )); then
        info "多盘并行扫描，预计约 $(fmt_dur "$maxest")（按 150MB/s 粗估，实际视盘而定）"
    else
        info "预计约 $(fmt_dur "$est")（按 150MB/s 粗估，实际视盘而定）"
    fi
    if [[ -z ${PLAN["surface:${torun[0]}"]:-} ]]; then
        ask_yn "确认开始?" Y || return 0
        if bg_available; then
            for name in "${torun[@]}"; do PLAN["surface:$name"]="continue"; done   # 进度文件已就绪
            bg_launch "$(join_by , "${torun[@]}")" -r surface && { PLAN=(); return 0; }
            PLAN=()
        fi
    fi
    rm -f "$RUN_DIR"/stop_all "$RUN_DIR"/*.stop

    if (( PARALLEL )); then
        for name in "${torun[@]}"; do
            surface_load "$STATE_DIR/${DID[$name]}/surface.state"; SW_START[$name]=$S_NEXT
            surface_worker "$name" "${DID[$name]}" & SW_PID[$name]=$!
        done
        surface_monitor "${torun[@]}"
    else
        for name in "${torun[@]}"; do
            [[ -e $RUN_DIR/stop_all ]] && break
            say ""; say "  扫描 /dev/$name …"
            surface_load "$STATE_DIR/${DID[$name]}/surface.state"; SW_START[$name]=$S_NEXT
            surface_worker "$name" "${DID[$name]}" & SW_PID[$name]=$!
            surface_monitor "$name"
        done
    fi

    local was_int=$INTERRUPTED
    INTERRUPTED=0      # 让结果汇总与复查能正常进行
    for name in "${torun[@]}"; do
        surface_load "$STATE_DIR/${DID[$name]}/surface.state"
        if (( S_DONE )); then
            surface_finalize "$name"
        else
            local pct=0; (( S_TOTAL )) && pct=$(( S_NEXT*1000 / S_TOTAL ))
            head2 "/dev/$name"
            info "已暂停于 $((pct/10)).$((pct%10))%，进度已保存；再次运行本项可选择「从断点继续」"
        fi
    done
    INTERRUPTED=$was_int
    rm -f "$RUN_DIR"/stop_all
}

#==============================================================================
#  模块五：badblocks 全盘只读扫描
#==============================================================================
mod_badblocks() {
    local name id dev size bs tmp rc cnt
    local -a torun=()
    head1 "badblocks 全盘只读坏块扫描"
    command -v badblocks >/dev/null 2>&1 || { bad "未安装 badblocks，请执行: apt install e2fsprogs"; return; }
    info "badblocks 只报告读不出的块，不能续扫；若想同时找弱扇区并支持断点，用 [6]"
    for name in "$@"; do
        decide_run "${DID[$name]}" badblocks "$name"
        dec_note "$name" badblocks || continue
        size=$(blockdev --getsize64 "/dev/$name" 2>/dev/null); size=${size:-0}
        info "/dev/$name  块大小 $(bb_bs "$size")B，预计约 $(fmt_dur $(( size/1048576/150 )))"
        torun+=("$name")
    done
    (( ${#torun[@]} )) || return 0
    if [[ -z ${PLAN["badblocks:${torun[0]}"]:-} ]]; then
        ask_yn "开始扫描?（多块盘依次扫描）" Y || return 0
        if bg_available; then
            for name in "${torun[@]}"; do PLAN["badblocks:$name"]=run; done
            bg_launch "$(join_by , "${torun[@]}")" -r badblocks && { PLAN=(); return 0; }
            PLAN=()
        fi
    fi
    for name in "${torun[@]}"; do
        [[ $INTERRUPTED -eq 1 ]] && break
        id=${DID[$name]}; dev="/dev/$name"
        size=$(blockdev --getsize64 "$dev" 2>/dev/null); size=${size:-0}
        bs=$(bb_bs "$size")
        head2 "/dev/$name  (块大小 ${bs}B)"
        tmp=$(mktemp)
        IN_TASK=1
        if [[ $QUIET -eq 0 ]]; then
            ( trap '' HUP; exec badblocks -b "$bs" -s -o "$tmp" "$dev" ); rc=$?
        else
            ( trap '' HUP; exec badblocks -b "$bs" -o "$tmp" "$dev" ) 2>/dev/null; rc=$?
        fi
        IN_TASK=0
        cnt=$(grep -c '^[0-9]' "$tmp")
        CUR_DED=0; CUR_ISS=()
        if [[ $INTERRUPTED -eq 1 || $rc -ne 0 ]]; then
            warn "扫描未完成（被中断或出错），未记录结果"
            rm -f "$tmp"; break
        fi
        if (( cnt > 0 )); then
            bad "发现 $cnt 个坏块（前 20 个）："; dump "$(head -n 20 "$tmp" | paste -sd' ')"
            pen 40 "badblocks 坏块 $cnt"
            cp "$tmp" "$STATE_DIR/$id/badblocks-list.txt"
        else
            ok "未发现坏块"
        fi
        save_result "$id" badblocks "$(status_of_ded)" "坏块 $cnt 个（块大小 ${bs}B）"
        rm -f "$tmp"
    done
}

#==============================================================================
#  模块六：维修后接口复查
#==============================================================================
REPAIR_NOTES=("" "重新插拔接头" "更换线缆" "更换主板接口/背板槽位" "检查/更换供电" "更换硬盘盒/转接卡" "其它处理")

# 接口计数快照 -> IF_CRC IF_CMDTO IF_LINK_MAX IF_LINK_CUR
iface_snapshot() {
    local name=$1 A sv
    IF_CRC=0; IF_CMDTO=0; IF_LINK_MAX=""; IF_LINK_CUR=""
    [[ ${DOPT_CACHE[$name]} == "__FAIL__" ]] && return
    A=$(sm "$name" -A 2>/dev/null)
    IF_CRC=$(num "$(awk '$1==199 && NF>=10 {print $10; exit}' <<< "$A")")
    IF_CMDTO=$(num "$(awk '$1==188 && NF>=10 {print $10; exit}' <<< "$A")")
    (( IF_CMDTO > 65535 )) && IF_CMDTO=$(( IF_CMDTO & 0xFFFF ))
    sv=$(sm "$name" -i 2>/dev/null | grep -m1 '^SATA Version is:')
    IF_LINK_MAX=$(grep -oE '[0-9.]+ Gb/s' <<< "$sv" | head -n1 | cut -d' ' -f1)
    IF_LINK_CUR=$(grep -oE 'current: [0-9.]+' <<< "$sv" | awk '{print $2}')
}
link_degraded() { [[ -n $IF_LINK_CUR && -n $IF_LINK_MAX ]] && awk -v a="$IF_LINK_CUR" -v b="$IF_LINK_MAX" 'BEGIN{exit !(a<b)}'; }

record_repair() {  # <name> <id> <说明>
    local name=$1 id=$2 note=$3
    iface_snapshot "$name"
    printf 'P_TS=%q\nP_NOTE=%q\nP_CRC=%q\nP_CMDTO=%q\n' "$(now)" "$note" "$IF_CRC" "$IF_CMDTO" > "$STATE_DIR/$id/repair.env"
    printf '%s  %s  CRC=%s 命令超时=%s\n' "$(printf '%(%F %T)T' -1)" "$note" "$IF_CRC" "$IF_CMDTO" >> "$STATE_DIR/$id/repairs.log"
}

has_results() { compgen -G "$STATE_DIR/$1/*.env" | grep -qvE '/(meta|repair)\.env$'; }

# 清除检测结果与报告；保留 SMART 计数历史(history.csv)与维修记录
clear_results() {
    local id=$1
    rm -f "$STATE_DIR/$id"/{quick,selftest_short,selftest_long,speed,surface,badblocks,iface}.env \
          "$STATE_DIR/$id"/surface.state "$STATE_DIR/$id"/surface.map \
          "$STATE_DIR/$id"/*.txt "$STATE_DIR/$id/reports.log"
}

iface_worker() {
    trap '' HUP
    local name=$1 dur=$2 dev="/dev/$1" f="$RUN_DIR/$1.iface" size tot r mb=0 errs=0 end
    end=$(( SECONDS + dur ))
    size=$(blockdev --getsize64 "$dev" 2>/dev/null); tot=$(( ${size:-0} / 1048576 - 64 )); (( tot > 0 )) || tot=1
    while (( SECONDS < end )); do
        [[ -e $RUN_DIR/stop_all || -e $RUN_DIR/$name.stop ]] && break
        r=$(( ((RANDOM << 15) | RANDOM) % tot ))
        read_mib "$dev" "$r" 64
        if (( RD_OK )); then mb=$(( mb + 64 )); else errs=$(( errs + 1 )); fi
        printf 'W_MB=%s\nW_ERR=%s\nW_KBS=%s\n' "$mb" "$errs" "$RD_KBS" > "$f.tmp" && mv -f "$f.tmp" "$f"
    done
}

iface_monitor() {
    local dur=$1; shift
    local -a names=("$@")
    local n alive t0=$SECONDS last_poll=-100 last_log=$SECONDS stopping=0 dc dm c1 c2
    local -A LC=() LM=()
    IN_TASK=1; DRAWN=0
    say ""; cursor l
    while true; do
        alive=0; REDRAW_LINES=()
        for n in "${names[@]}"; do kill -0 "${SW_PID[$n]}" 2>/dev/null && alive=$((alive+1)); done
        if (( SECONDS - last_poll >= 20 )); then
            for n in "${names[@]}"; do iface_snapshot "$n"; LC[$n]=$IF_CRC; LM[$n]=$IF_CMDTO; done
            last_poll=$SECONDS
        fi
        REDRAW_LINES+=("  已进行 $(fmt_dur $((SECONDS-t0))) / $(fmt_dur "$dur")")
        for n in "${names[@]}"; do
            W_MB=0; W_ERR=0; W_KBS=0
            [[ -r $RUN_DIR/$n.iface ]] && read_record "$RUN_DIR/$n.iface" iface
            dc=$(( ${LC[$n]:-0} - ${IB_CRC[$n]:-0} )); dm=$(( ${LM[$n]:-0} - ${IB_CMD[$n]:-0} ))
            c1=""; c2=""; (( dc > 0 )) && c1=$C_RED; (( dm > 0 )) && c2=$C_RED
            REDRAW_LINES+=("$(printf '  %-5s 已读 %6s GB  %6sMB/s  读错误 %-3d ' "$n" "$(mbs "$W_MB")" "$(mbs "$W_KBS")" "$W_ERR")${c1}CRC +${dc}${c1:+$C_OFF}  ${c2}超时 +${dm}${c2:+$C_OFF}")
        done
        if (( stopping )); then REDRAW_LINES+=("  ${C_YEL}正在结束…${C_OFF}")
        else REDRAW_LINES+=("  ${C_DIM}[P] 提前结束（已读取的数据量仍用于判定）  CRC/超时每 20 秒刷新${C_OFF}"); fi
        [[ $BATCH -eq 1 ]] || redraw
        if [[ ! -t 1 || $DETACHED -eq 1 ]] && (( SECONDS - last_log >= 300 )); then
            for n in "${REDRAW_LINES[@]:1:${#names[@]}}"; do out "    [$(printf '%(%F %T)T' -1)]$n"; done
            last_log=$SECONDS
        fi
        (( alive == 0 )) && break
        poll_key 1
        if [[ $KEY == P || $INTERRUPTED -eq 1 ]]; then : > "$RUN_DIR/stop_all"; stopping=1; fi
        [[ -e $RUN_DIR/stop_all ]] && stopping=1
    done
    for n in "${names[@]}"; do wait "${SW_PID[$n]}" 2>/dev/null; done
    cursor h
    IN_TASK=0
}

declare -A IB_CRC=() IB_CMD=()
mod_iface() {
    local name id note dur=$(( ${IFACE_MIN:-15} * 60 )) n
    local -a torun=()
    head1 "维修后接口复查"
    info "用途：处理过接头 / 线缆 / 接口 / 供电后，验证 CRC 错误、链路复位是否还会发生"
    info "原理：CRC 错误只在传输数据时产生，所以施加持续读取压力，同时监测计数是否增长（全程只读）"

    # 1) 维修时间点
    for name in "$@"; do
        [[ $INTERRUPTED -eq 1 ]] && return
        id=${DID[$name]}
        local P_TS=0 P_NOTE=""
        [[ -r $STATE_DIR/$id/repair.env ]] && read_record "$STATE_DIR/$id/repair.env" repair
        say ""
        [[ ${DOPT_CACHE[$name]} == "__FAIL__" ]] && warn "/dev/$name SMART 不可用：只能依据内核日志与读取错误判断"
        if (( P_TS > 0 )); then
            info "/dev/$name 已有维修记录：$(age_str "$P_TS")，$P_NOTE"
            if (( BATCH )); then torun+=("$name"); continue; fi
            choose "    [U] 就是这次维修   [N] 记录一次新的维修   [S] 跳过此盘  > " U N S || continue
            case $KEY in U) torun+=("$name"); continue ;; S) continue ;; esac
        elif (( BATCH )); then
            record_repair "$name" "$id" "批处理复查（未注明）"; torun+=("$name"); continue
        else
            info "/dev/$name 尚无维修记录"
        fi
        say "    刚才对 /dev/$name 做了什么处理？"
        say "      [1] 重新插拔接头   [2] 更换线缆   [3] 更换主板接口/背板槽位"
        say "      [4] 检查/更换供电  [5] 更换硬盘盒/转接卡   [6] 其它   [S] 跳过此盘"
        choose "    > " 1 2 3 4 5 6 S || continue
        [[ $KEY == S ]] && continue
        note=${REPAIR_NOTES[$KEY]}
        record_repair "$name" "$id" "$note"
        ok "已记录维修时间点 $(printf '%(%m-%d %H:%M)T' -1)：$note（当前 CRC 累计 $IF_CRC，作为基线）"
        if has_results "$id"; then
            if ask_yn "维修前的检测结果已不能代表现状，是否清除?（保留 SMART 计数历史用于对比）" Y; then
                clear_results "$id"; ok "已清除维修前的检测结果与报告"
            fi
        fi
        torun+=("$name")
    done
    (( ${#torun[@]} )) || return 0

    # 2) 压力时长
    if (( ! BATCH )); then
        say ""
        say "    读取压力测试时长（越长越可靠；期间硬盘可正常使用）："
        choose "    [1] 5 分钟   [2] 15 分钟(推荐)   [3] 30 分钟   [4] 60 分钟  > " 1 2 3 4 || return 0
        case $KEY in 1) dur=300 ;; 2) dur=900 ;; 3) dur=1800 ;; 4) dur=3600 ;; esac
    fi

    if bg_available; then
        bg_launch "$(join_by , "${torun[@]}")" -r iface --duration $(( dur / 60 )) && return 0
    fi

    # 3) 基线 + 压力测试
    rm -f "$RUN_DIR"/stop_all "$RUN_DIR"/*.stop "$RUN_DIR"/*.iface
    for name in "${torun[@]}"; do
        iface_snapshot "$name"; IB_CRC[$name]=$IF_CRC; IB_CMD[$name]=$IF_CMDTO;
        iface_worker "$name" "$dur" & SW_PID[$name]=$!
    done
    info "开始对 ${torun[*]} 施加 $(fmt_dur "$dur") 随机读取压力…"
    iface_monitor "$dur" "${torun[@]}"

    # 4) 判定
    local was_int=$INTERRUPTED; INTERRUPTED=0
    for name in "${torun[@]}"; do
        id=${DID[$name]}
        local P_TS=0 P_NOTE="" P_CRC="" P_CMDTO=""
        read_record "$STATE_DIR/$id/repair.env" repair || { warn "维修记录不可读取"; continue; }
        W_MB=0; W_ERR=0; [[ -r $RUN_DIR/$name.iface ]] && read_record "$RUN_DIR/$name.iface" iface
        iface_snapshot "$name"
        klog_lines "$name" "$P_TS"
        local d_rep=$(( IF_CRC - ${P_CRC:-$IF_CRC} )) d_test=$(( IF_CRC - ${IB_CRC[$name]} ))
        local m_rep=$(( IF_CMDTO - ${P_CMDTO:-$IF_CMDTO} )) gb=$(( W_MB / 1024 ))
        (( d_rep < 0 )) && d_rep=0; (( m_rep < 0 )) && m_rep=0
        local fails=0 nlnk=0
        [[ -n $KL_LNK ]] && nlnk=$(grep -c . <<< "$KL_LNK")
        CUR_DED=0; CUR_ISS=()
        head2 "接口复查结果 · /dev/$name"
        info "维修记录   : $(age_str "$P_TS")，$P_NOTE"
        if [[ -n $IF_LINK_CUR ]]; then
            if link_degraded; then bad "链路速率   : 当前 ${IF_LINK_CUR} Gb/s，低于硬盘支持的 ${IF_LINK_MAX} Gb/s"; fails=$((fails+1))
            else ok "链路速率   : ${IF_LINK_CUR} Gb/s（满速）"; fi
        fi
        if [[ ${DOPT_CACHE[$name]} != "__FAIL__" ]]; then
            if (( d_rep > 0 )); then bad "CRC 错误   : 维修时 ${P_CRC} → 现在 ${IF_CRC}（维修后 +${d_rep}，其中压力测试期间 +${d_test}）"; fails=$((fails+1))
            else ok "CRC 错误   : 维修时 ${P_CRC} → 现在 ${IF_CRC}（维修后无新增）"; fi
            if (( m_rep > 0 )); then warn "命令超时   : 维修后 +${m_rep}"; fails=$((fails+1))
            else ok "命令超时   : 维修后无新增"; fi
        fi
        if (( nlnk > 0 )); then bad "内核日志   : 维修后有 ${nlnk} 条链路复位/CRC/命令失败记录："; dump "$KL_LNK"; fails=$((fails+1))
        else ok "内核日志   : 维修后无链路错误（$KL_SRC）"; fi
        info "压力测试   : 读取 ${gb} GB，读错误 ${W_ERR} 次"
        (( W_ERR > 0 )) && warn "读取出错属于介质问题而非接口问题，建议做 [6] 全盘读延迟扫描定位"

        local st sum
        if (( fails > 0 )); then
            out ""; bad "结论：接口问题【未解决】"
            info "建议按顺序排查：换一根线 → 换主板口/背板槽位 → 换供电线或去掉转接头/一拖多 →"
            info "                换硬盘盒/转接卡 → 以上都换过仍增长，可能是硬盘自身接口板问题"
            pen 15 "接口问题未解决"
            st=bad; sum="未解决：CRC 维修后 +${d_rep}，链路错误 ${nlnk} 条"
        elif (( gb < 5 && W_ERR == 0 )); then
            out ""; warn "结论：读取量仅 ${gb} GB，数据量不足，建议延长时间再测一次"
            st=incomplete; sum="验证不足（仅读取 ${gb} GB）"
        else
            out ""; ok "结论：接口问题【已解决】 —— 读取 ${gb} GB 期间及维修后均无 CRC / 链路错误"
            info "建议过几天正常使用后再做一次 [2] 快速体检，确认日常使用中 CRC 也不再增长"
            st=good; sum="已解决：维修后读取 ${gb} GB 无 CRC/链路错误"
        fi
        save_result "$id" iface "$st" "$sum"
    done
    INTERRUPTED=$was_int
    rm -f "$RUN_DIR"/stop_all "$RUN_DIR"/*.iface
}

#==============================================================================
#  综合报告
#==============================================================================
compute_overall() {
    local name=$1 id=${DID[$1]} m age have_q=0 have_l=0 have_s=0 have_o=0 stale=0 any=0 it
    OV_SCORE=100; OV_ISS=(); OV_ROWS=()
    for m in "${MODS[@]}"; do
        load_result "$id" "$m" || continue
        if [[ $m == selftest_* && $R_STATUS == running && ${DOPT_CACHE[$name]} != "__FAIL__" ]]; then
            if ! selftest_running "$name"; then
                record_selftest "$name" "$id" "${m#selftest_}" "$(get_poh "$name")" force
                load_result "$id" "$m"
            fi
        fi
        any=1
        age=$(( $(now) - R_TS ))
        (( age > VALID_DAYS*86400 )) && stale=1
        OV_ROWS+=("$m|$R_TS|$R_STATUS|$R_DEDUCT|$R_SUMMARY")
        case $R_STATUS in
            good|warn|bad)
                OV_SCORE=$(( OV_SCORE - R_DEDUCT ))
                if [[ -n $R_ISSUES ]]; then
                    local -a arr; IFS=';' read -ra arr <<< "$R_ISSUES"
                    for it in "${arr[@]}"; do OV_ISS+=("$it"); done
                fi
                case $m in
                    quick) have_q=1 ;;
                    selftest_long) have_l=1 ;;
                    surface|badblocks) have_s=1 ;;
                    *) have_o=1 ;;
                esac ;;
        esac
    done
    (( OV_SCORE < 0 )) && OV_SCORE=0
    OV_STALE=$stale
    if   (( ! any )); then OV_COVER="未评估"
    elif (( have_q && have_l && have_s )); then OV_COVER="完整"
    elif (( have_q && (have_l || have_s || have_o) )); then OV_COVER="标准"
    elif (( have_q )); then OV_COVER="基础"
    else OV_COVER="部分"; fi
    if   (( ! any ));          then OV_GRADE="未评估";        OV_COLOR=""; OV_LEVEL=0
    elif (( OV_SCORE >= 90 )); then OV_GRADE="良好";          OV_COLOR=$C_GRN; OV_LEVEL=0
    elif (( OV_SCORE >= 75 )); then OV_GRADE="注意(建议观察)"; OV_COLOR=$C_YEL; OV_LEVEL=1
    elif (( OV_SCORE >= 50 )); then OV_GRADE="警告(尽快备份)"; OV_COLOR=$C_YEL; OV_LEVEL=1
    else                            OV_GRADE="危险(建议更换)"; OV_COLOR=$C_RED; OV_LEVEL=2; fi
    (( ! any )) && OV_SCORE="-"
}

report_table() {
    local name i
    head1 "汇总"
    out "$(printf '  %-10s %-24s %-6s %-6s %s' '设备' '型号' '评分' '完整度' '等级')"
    hr
    for name in "$@"; do
        compute_overall "$name"; i=$(di "$name")
        out "$(printf '  %-10s %-24.24s %-6s %-6s ' "/dev/$name" "${D_MODEL[$i]}" "$OV_SCORE" "$OV_COVER")${OV_COLOR}${OV_GRADE}${OV_COLOR:+$C_OFF}"
        (( OV_LEVEL > WORST )) && WORST=$OV_LEVEL
    done
    hr
}

mod_report() {
    local name id i row m ts st ded sm_ it
    for name in "$@"; do
        id=${DID[$name]}; i=$(di "$name")
        compute_overall "$name"
        head1 "综合报告 · /dev/$name  ${D_MODEL[$i]}  (${D_SIZE[$i]})"
        info "身份标识 : $id"
        if [[ $OV_COVER == 未评估 ]]; then info "尚无任何检测结果"; continue; fi
        head2 "各项结果"
        for row in "${OV_ROWS[@]}"; do
            IFS='|' read -r m ts st ded sm_ <<< "$row"
            out "$(printf '    %-14s %-12s ' "${MOD_LABEL[$m]}" "$(printf '%(%m-%d %H:%M)T' "$ts")")$(status_txt "$st")  扣${ded}  ${C_DIM}${sm_}${C_OFF}"
        done
        head2 "结论"
        out "    健康评分 : ${OV_COLOR}${OV_SCORE}/100${OV_COLOR:+$C_OFF}"
        out "    健康等级 : ${OV_COLOR}${OV_GRADE}${OV_COLOR:+$C_OFF}"
        out "    评估完整度: ${OV_COVER}  ${C_DIM}(完整 = 快速体检 + 长自检 + 全盘扫描)${C_OFF}"
        (( OV_STALE )) && warn "部分结果已超过 ${VALID_DAYS} 天有效期，建议重新检测"
        if (( ${#OV_ISS[@]} )); then
            out "    发现问题 :"; for it in "${OV_ISS[@]}"; do out "      - $it"; done
        else
            out "    发现问题 : 无"
        fi
        head2 "建议"
        local joined; joined=$(printf '%s;' "${OV_ISS[@]}")
        [[ $joined == *待映射* || $joined == *不可校正* || $joined == *读错误* || $joined == *坏块* || $joined == *FAILED* || $joined == *自检失败* ]] && \
            info "• 盘面已有不可读区域：立即确认备份完整；此盘不宜再存放重要数据，建议更换"
        [[ $joined == *增长* ]] && info "• 坏道计数在增长：劣化仍在进行，缩短巡检间隔（如每周快速体检）并尽快更换"
        if [[ $joined == *CRC* || $joined == *链路* || $joined == *接口问题* || $joined == *命令超时* ]]; then
            info "• 接口类问题：更换 SATA 线/换口/检查供电与背板后，用 [V] 维修后接口复查 验证是否解决"
        fi
        if load_result "$id" iface && [[ $R_STATUS == good || $R_STATUS == bad ]]; then
            info "• 接口复查（$(age_str "$R_TS")）：$R_SUMMARY"
        fi
        [[ $joined == *温度* ]] && info "• 温度问题：改善风道或加装风扇，机械盘理想工作温度 25-45°C"
        [[ $joined == *极慢块* || $joined == *慢块* || $joined == *凹陷* ]] && info "• 存在弱扇区：目前能读出但需重试，属早期劣化信号，重要数据需多份备份"
        case $OV_COVER in
            基础|部分) info "• 目前只做了基础检查，看不到盘面状态；建议运行 [F] 一键完整评估" ;;
            标准) info "• 尚未完成长自检或全盘扫描，结论置信度中等；可运行 [F] 补齐" ;;
        esac
        (( ${#OV_ISS[@]} == 0 )) && [[ $OV_COVER == 完整 ]] && info "• 各项检测均正常，建议每 1-3 个月快速体检一次、每半年做一次全盘扫描"
        {
            printf '%s  %s  评分 %s  等级 %s  完整度 %s\n' "$(printf '%(%F %T)T' -1)" "$name" "$OV_SCORE" "$OV_GRADE" "$OV_COVER"
        } >> "$STATE_DIR/$id/reports.log"
    done
    report_table "$@"
}

#==============================================================================
#  历史 / 清除 / 设置 / 选盘
#==============================================================================
mod_history() {
    local name id hist m
    for name in "$@"; do
        id=${DID[$name]}; hist="$STATE_DIR/$id/history.csv"
        head1 "历史记录 · /dev/$name  ($id)"
        head2 "各项最近结果"
        for m in "${MODS[@]}"; do
            if load_result "$id" "$m"; then
                out "$(printf '    %-14s ' "${MOD_LABEL[$m]}")$(age_str "$R_TS")  $(status_txt "$R_STATUS")  ${C_DIM}${R_SUMMARY}${C_OFF}"
            else
                out "$(printf '    %-14s ' "${MOD_LABEL[$m]}")${C_DIM}未做过${C_OFF}"
            fi
        done
        if surface_load "$STATE_DIR/$id/surface.state" && (( ! S_DONE && S_NEXT > 0 )); then
            info "全盘扫描有未完成进度：$(( S_NEXT*100 / S_TOTAL ))%"
        fi
        head2 "SMART 关键计数趋势（最近 15 次快速体检）"
        if [[ -s $hist ]]; then
            out "$(printf '    %-12s %8s %6s %6s %6s %6s %6s %4s' 时间 通电h 重映射 待映射 不可校 不可纠 CRC 温度)"
            tail -n 15 "$hist" | while IFS=, read -r ts poh r p o u c t; do
                out "$(printf '    %-12s %8s %6s %6s %6s %6s %6s %4s' "$(printf '%(%m-%d %H:%M)T' "$ts")" "$poh" "$r" "$p" "$o" "$u" "$c" "$t")"
            done
        else
            info "暂无记录"
        fi
        [[ -s $STATE_DIR/$id/reports.log ]] && { head2 "历次综合评分"; dump "$(tail -n 10 "$STATE_DIR/$id/reports.log")"; }
    done
}

mod_clear() {
    local name id
    head1 "清除检测结果"
    info "${C_BOLD}推荐 [A]${C_OFF}：SMART 计数历史（CRC、坏道等每次体检的数值）是判断问题「修好了没有」的依据，"
    info "删掉后下次体检无法对比增长。维修记录也会保留，内核日志从维修时间点起算。"
    for name in "$@"; do
        id=${DID[$name]}
        say ""
        say "  /dev/$name  ($id)"
        choose "    [A] 清除检测结果与报告(保留计数历史)   [H] 全部清除(含历史与维修记录)   [S] 跳过  > " A H S || continue
        case $KEY in
            A) clear_results "$id"; ok "已清除检测结果与报告" ;;
            H) find "$STATE_DIR/$id" -mindepth 1 ! -name meta.env -delete 2>/dev/null; ok "已全部清除" ;;
        esac
    done
    local -a logs=()
    mapfile -t logs < <(find "$LOG_DIR" -maxdepth 1 -name 'hdd-health-*.log' ! -path "$LOG_FILE" 2>/dev/null)
    if (( ${#logs[@]} )); then
        say ""
        if ask_yn "同时删除 $LOG_DIR 下 ${#logs[@]} 个旧日志文件（$(du -ch "${logs[@]}" 2>/dev/null | tail -n1 | cut -f1)）?" N; then
            rm -f "${logs[@]}"; ok "已删除旧日志（本次会话日志保留）"
        fi
    fi
}

menu_settings() {
    local -a days=(1 3 7 14 30) chunks=(16 32 64 128 256) pts=(12 24 48 96)
    cyc() { local cur=$1; shift; local a=("$@") i; for i in "${!a[@]}"; do [[ ${a[$i]} == "$cur" ]] && { echo "${a[$(( (i+1) % ${#a[@]} ))]}"; return; }; done; echo "${a[0]}"; }
    local pol_txt rc_txt
    while true; do
        clear_screen
        case $RESCAN_POLICY in ask) pol_txt="每次询问";; rescan) pol_txt="总是重新扫描";; reuse) pol_txt="有效期内自动沿用";; esac
        case $AUTO_RECHECK in ask) rc_txt="询问";; always) rc_txt="自动复查";; never) rc_txt="不复查";; esac
        say "${C_BOLD}  设置${C_OFF}   ${C_DIM}（按数字键切换，自动保存到 $SETTINGS_FILE）${C_OFF}"
        say ""
        say "  [1] 结果有效期            : ${VALID_DAYS} 天"
        say "  [2] 已有结果时            : ${pol_txt}"
        say "  [3] 多盘并行全盘扫描      : $([[ $PARALLEL == 1 ]] && echo 开 || echo 关)"
        say "  [4] 全盘扫描块大小        : ${CHUNK_MB} MiB   ${C_DIM}(越小定位越细，总耗时略增)${C_OFF}"
        say "  [5] 读性能曲线采样点      : ${SAMPLE_POINTS}"
        say "  [6] 选盘列表包含 SSD/NVMe : $([[ $INCLUDE_SSD == 1 ]] && echo 是 || echo 否)"
        say "  [7] 异常区 badblocks 复查 : ${rc_txt}"
        say ""
        say "  [Q] 返回"
        choose "  > " 1 2 3 4 5 6 7 Q ENTER ESC || return
        case $KEY in
            1) VALID_DAYS=$(cyc "$VALID_DAYS" "${days[@]}") ;;
            2) RESCAN_POLICY=$(cyc "$RESCAN_POLICY" ask rescan reuse) ;;
            3) PARALLEL=$(( 1 - PARALLEL )) ;;
            4) CHUNK_MB=$(cyc "$CHUNK_MB" "${chunks[@]}") ;;
            5) SAMPLE_POINTS=$(cyc "$SAMPLE_POINTS" "${pts[@]}") ;;
            6) INCLUDE_SSD=$(( 1 - INCLUDE_SSD )) ;;
            7) AUTO_RECHECK=$(cyc "$AUTO_RECHECK" ask always never) ;;
            *) return ;;
        esac
        save_settings
    done
}

candidates() {
    CAND=()
    local i
    for i in "${!D_NAME[@]}"; do
        [[ $INCLUDE_SSD -eq 0 && ${D_ROTA[$i]} != 1 ]] && continue
        CAND+=("$i")
    done
}

disk_status_line() {  # 选盘列表中每块盘的上次状态
    local name=$1 id=${DID[$1]:-}
    [[ -z $id ]] && return
    local s=""
    if load_result "$id" quick; then s="体检 $(age_str "$R_TS" | sed 's/.*，//') $(status_txt "$R_STATUS")"; fi
    if surface_load "$STATE_DIR/$id/surface.state" && (( ! S_DONE && S_NEXT > 0 )); then
        s="$s  ${C_YEL}扫描中断于 $(( S_NEXT*100/S_TOTAL ))%${C_OFF}"
    fi
    printf '%s' "$s"
}

menu_select() {
    enumerate_disks; candidates
    if (( ${#CAND[@]} == 0 )); then
        say "  未检测到机械盘。如需包含 SSD，请在 [S] 设置中打开。"; pause_key; return
    fi
    local -A mark=()
    local i n k
    for n in "${SELECTED[@]}"; do mark[$n]=1; done
    say "  正在识别磁盘…"
    for i in "${CAND[@]}"; do prepare_disk "${D_NAME[$i]}"; done

    if (( ${#CAND[@]} > 9 )); then
        # 盘多于 9 块时用输入方式
        say ""
        k=1
        for i in "${CAND[@]}"; do
            n=${D_NAME[$i]}
            printf '  %2d  /dev/%-8s %-8s %-6s %-26.26s %s\n' "$k" "$n" "${D_SIZE[$i]}" "${D_TRAN[$i]}" "${D_MODEL[$i]}" "$(disk_status_line "$n")"
            k=$((k+1))
        done
        local reply tok a b
        read -rp "  输入编号（如 1 3 5 / 1-4 / all）: " reply </dev/tty
        SELECTED=()
        reply="${reply//,/ }"
        [[ -z $reply || ${reply,,} == all ]] && reply="1-${#CAND[@]}"
        for tok in $reply; do
            if [[ $tok =~ ^([0-9]+)-([0-9]+)$ ]]; then
                for ((a=BASH_REMATCH[1]; a<=BASH_REMATCH[2]; a++)); do
                    (( a>=1 && a<=${#CAND[@]} )) && SELECTED+=("${D_NAME[${CAND[a-1]}]}")
                done
            elif [[ $tok =~ ^[0-9]+$ ]] && (( tok>=1 && tok<=${#CAND[@]} )); then
                SELECTED+=("${D_NAME[${CAND[tok-1]}]}")
            fi
        done
        return
    fi

    local -a keys=()
    while true; do
        clear_screen
        say "${C_BOLD}  选择要检测的磁盘${C_OFF}"
        say ""
        k=1; keys=()
        for i in "${CAND[@]}"; do
            n=${D_NAME[$i]}
            local box="[ ]"; [[ -n ${mark[$n]:-} ]] && box="[${C_GRN}x${C_OFF}]"
            printf '  %s %d  /dev/%-8s %-8s %-6s %-6s %-26.26s %s\n' "$box" "$k" "$n" "${D_SIZE[$i]}" \
                "$(disk_kind "${D_ROTA[$i]}")" "${D_TRAN[$i]}" "${D_MODEL[$i]}" "$(disk_status_line "$n")"
            keys+=("$k"); k=$((k+1))
        done
        say ""
        say "  ${C_DIM}[数字] 选中/取消   [A] 全选   [N] 全不选   [Enter] 确认   [Q] 放弃修改${C_OFF}"
        choose "  > " "${keys[@]}" A N ENTER Q ESC || return
        case $KEY in
            [1-9]) n=${D_NAME[${CAND[KEY-1]}]}
                   if [[ -n ${mark[$n]:-} ]]; then unset "mark[$n]"; else mark[$n]=1; fi ;;
            A) for i in "${CAND[@]}"; do mark[${D_NAME[$i]}]=1; done ;;
            N) mark=() ;;
            Q|ESC) return ;;
            ENTER)
                SELECTED=()
                for i in "${CAND[@]}"; do [[ -n ${mark[${D_NAME[$i]}]:-} ]] && SELECTED+=("${D_NAME[$i]}"); done
                return ;;
        esac
    done
}

#==============================================================================
#  一键完整评估
#==============================================================================
plan_full() {
    PLAN=(); PLAN_RECHECK=""
    local name id poh
    head1 "完整评估 · 先确认各项是否重新检测（之后全程无需值守）"
    for name in "$@"; do
        id=${DID[$name]}
        say ""; say "  ${C_BOLD}/dev/$name${C_OFF}"
        decide_run "$id" quick "$name"; PLAN["quick:$name"]=$DEC
        if [[ ${DOPT_CACHE[$name]} != "__FAIL__" ]]; then
            poh=$(get_poh "$name")
            record_selftest "$name" "$id" short "$poh" newer
            record_selftest "$name" "$id" long  "$poh" newer
            decide_run "$id" selftest_short "$name"; PLAN["selftest_short:$name"]=$DEC
            decide_run "$id" selftest_long  "$name"; PLAN["selftest_long:$name"]=$DEC
        fi
        decide_run "$id" speed "$name"; PLAN["speed:$name"]=$DEC
        surface_decide "$name"; PLAN["surface:$name"]=$DEC
    done
    if [[ $AUTO_RECHECK == ask ]]; then
        say ""
        if ask_yn "全盘扫描若发现异常块，是否自动用 badblocks 精确复查?" Y; then PLAN_RECHECK=always; else PLAN_RECHECK=never; fi
    fi
}

mod_full() {
    local -a names=("$@")
    local name mins maxmin=0 est=0 maxest=0 e
    plan_full "${names[@]}"
    [[ $INTERRUPTED -eq 1 || $DETACHED -eq 1 ]] && { PLAN=(); return; }
    for name in "${names[@]}"; do
        if [[ ${PLAN["selftest_long:$name"]:-} == run ]]; then
            mins=$(selftest_minutes "$name" long); (( ${mins:-0} > maxmin )) && maxmin=${mins:-0}
        fi
        case ${PLAN["surface:$name"]} in
            run|restart) e=$(( $(blockdev --getsize64 "/dev/$name" 2>/dev/null || echo 0) / 1048576 / 150 )) ;;
            continue) surface_load "$STATE_DIR/${DID[$name]}/surface.state"; e=$(( (S_TOTAL-S_NEXT)*S_CHUNK/150 )) ;;
            *) e=0 ;;
        esac
        est=$((est+e)); (( e>maxest )) && maxest=$e
    done
    (( PARALLEL )) && est=$maxest
    head1 "一键完整评估"
    info "流程 : 快速体检 → 短自检 → 长自检 → 读性能曲线 → 全盘读延迟扫描(+异常复查) → 综合报告"
    info "预计 : 长自检约 $(fmt_dur $((maxmin*60)))（多盘并行）＋ 全盘扫描约 $(fmt_dur "$est")"
    info "全程只读，不写入硬盘；中途按 Ctrl+C 可停止，已完成的项目会保存，下次可沿用/续扫"
    ask_yn "开始?" Y || { PLAN=(); return; }
    if bg_available; then
        bg_launch "$(join_by , "${names[@]}")" -r full && { PLAN=(); PLAN_RECHECK=""; return; }
    fi

    mod_quick "${names[@]}";                       [[ $INTERRUPTED -eq 1 ]] && { PLAN=(); return; }
    mod_selftest short 0 "${names[@]}";            [[ $INTERRUPTED -eq 1 ]] && { PLAN=(); return; }
    mod_selftest long 0 "${names[@]}";             [[ $INTERRUPTED -eq 1 ]] && { PLAN=(); return; }
    mod_speed "${names[@]}";                       [[ $INTERRUPTED -eq 1 ]] && { PLAN=(); return; }
    mod_surface "${names[@]}";                     [[ $INTERRUPTED -eq 1 ]] && { PLAN=(); return; }
    PLAN=(); PLAN_RECHECK=""
    mod_report "${names[@]}"
}

#==============================================================================
#  后台实例：状态查看 / 安全停止
#==============================================================================
instance_alive() {
    I_PID=""; I_LOG=""; I_RUNDIR=""; I_TASK=""; I_TARGETS=""; I_START=0; I_MODE=""
    [[ -r $RUNINFO ]] || return 1
    read_record "$RUNINFO" run || return 1
    [[ $I_PID =~ ^[1-9][0-9]*$ ]] || return 1
    [[ $I_RUNDIR =~ ^/run/hdd-health\.[A-Za-z0-9]{6}$ || $I_RUNDIR =~ ^/tmp/tmp\.[A-Za-z0-9]{6,}$ ]] || return 1
    kill -0 "$I_PID" 2>/dev/null
}

status_lines() {
    REDRAW_LINES=()
    if ! instance_alive; then REDRAW_LINES+=("  没有正在运行的实例"); return 1; fi
    REDRAW_LINES+=("  PID ${I_PID}   已运行 $(fmt_dur $(( $(now) - I_START )))   ${I_MODE:-运行中}")
    REDRAW_LINES+=("  当前任务: ${I_TASK:-（在菜单中，空闲）}   目标: ${I_TARGETS}")
    REDRAW_LINES+=("  日志: ${I_LOG}")
    local n id pct line
    for n in $I_TARGETS; do
        prepare_disk "$n"; id=${DID[$n]}; line=""
        if surface_load "$STATE_DIR/$id/surface.state" && (( ! S_DONE && S_NEXT > 0 && $(now) - S_TS_UPD < 120 )); then
            pct=$(( S_NEXT*1000 / S_TOTAL ))
            line="全盘扫描 $((pct/10)).$((pct%10))%  $(mbs "$S_KBS")MB/s  慢${S_SLOW} 极慢${S_VSLOW} 错${S_ERR}"
        elif [[ -r $I_RUNDIR/$n.iface ]]; then
            W_MB=0; W_ERR=0; read_record "$I_RUNDIR/$n.iface" iface
            line="接口压力测试  已读 $(mbs "$W_MB") GB  读错误 ${W_ERR}"
        elif [[ ${DOPT_CACHE[$n]} != "__FAIL__" ]] && selftest_running "$n"; then
            line="SMART 自检进行中  剩余 $(selftest_remaining "$n")%"
        fi
        [[ -n $line ]] && REDRAW_LINES+=("  /dev/$(printf '%-6s' "$n") $line")
    done
    REDRAW_LINES+=("  ── 最近日志 ──")
    if [[ -r $I_LOG ]]; then
        while IFS= read -r line; do REDRAW_LINES+=("  | ${line:0:100}"); done < <(grep -v '^\s*$' "$I_LOG" | tail -n 6)
    fi
    return 0
}

stop_instance() {
    instance_alive || { say "  没有正在运行的实例"; return 1; }
    [[ -d $I_RUNDIR && ! -L $I_RUNDIR ]] && : > "$I_RUNDIR/stop_all"
    kill -TERM "$I_PID" 2>/dev/null
    pkill -TERM -P "$I_PID" -x badblocks 2>/dev/null
    say "  已通知 PID $I_PID 安全停止：全盘扫描读完当前块后停下并保存进度（下次可续扫）。"
    say "  注：SMART 自检在硬盘内部运行，不受影响；如需中止请执行 smartctl -X /dev/sdX"
    local i
    for ((i=0; i<60; i++)); do kill -0 "$I_PID" 2>/dev/null || { say "  已停止。"; return 0; }; sleep 1; done
    say "  仍在收尾，可稍后用 --status 查看"
}

status_view() {   # status_view [日志偏移 日志文件]：实时刷新；任务结束后显示本次结果
    local off=${1:-} lf=${2:-} finished=0
    if [[ ! -t 1 ]]; then status_lines; printf '%s\n' "${REDRAW_LINES[@]}"; return; fi
    DRAWN=0; cursor l
    printf '%s\n\n' "${C_BOLD}  后台任务状态${C_OFF}   ${C_DIM}[P] 安全暂停后台任务   [Q] 返回（后台任务继续运行）${C_OFF}"
    while true; do
        if ! status_lines; then finished=1; break; fi
        redraw
        KEY=""
        IFS= read -rsn1 -t 2 KEY </dev/tty 2>/dev/null || { tty_ok || break; }
        KEY=${KEY^^}
        case $KEY in
            Q) break ;;
            P) cursor h; say ""; stop_instance; finished=1; break ;;
        esac
    done
    cursor h
    if (( finished )) && [[ -n $off && -r $lf ]]; then
        say ""
        say "${C_BOLD}  ── 后台任务已结束，本次输出如下 ──${C_OFF}"
        tail -c +"$(( off + 1 ))" "$lf" | grep -vE '^[[:space:]]*\[[0-9-]+ [0-9:]+\]  |^#' | sed 's/^/  /'
    elif (( finished )); then
        printf '%s\n' "${REDRAW_LINES[@]}"
    fi
}

#==============================================================================
#  主菜单
#==============================================================================
banner() {
    say "${C_BOLD}  ╔════════════════════════════════════════════════════════════╗${C_OFF}"
    say "${C_BOLD}  ║   机械硬盘全方位健康评估  v${SCRIPT_VERSION}        只读检测 · 不写盘   ║${C_OFF}"
    say "${C_BOLD}  ╚════════════════════════════════════════════════════════════╝${C_OFF}"
}

run_task() {
    local fn=$1; shift
    if (( ! LOCKED )) && [[ $fn != mod_report && $fn != mod_history ]] && ! take_lock; then
        clear_screen
        say ""; say "  ${C_YEL}后台任务仍在运行，完成前不能开始新的检测${C_OFF}"; say ""
        status_view; pause_key; return
    fi
    if (( ${#SELECTED[@]} == 0 )); then
        menu_select
        (( ${#SELECTED[@]} )) || return
    fi
    clear_screen
    INTERRUPTED=0
    local name
    for name in "${SELECTED[@]}"; do prepare_disk "$name"; done
    local -A TL=([mod_quick]="快速体检" [mod_selftest]="SMART 自检" [mod_speed]="读性能曲线" [mod_surface]="全盘读延迟扫描"
                 [mod_badblocks]="badblocks 扫描" [mod_full]="一键完整评估" [mod_report]="综合报告" [mod_history]="历史与趋势" [mod_clear]="清除结果")
    TL[mod_iface]="维修后接口复查"
    CUR_TASK=${TL[$fn]:-$fn}; write_runinfo
    out ""; out "######## $(printf '%(%F %T)T' -1)  ${CUR_TASK}  目标: ${SELECTED[*]} ########"
    "$fn" "$@" "${SELECTED[@]}"
    [[ $fn != mod_report && $fn != mod_full && $fn != mod_history && $fn != mod_clear ]] && report_table "${SELECTED[@]}"
    say ""; say "  ${C_DIM}日志: $LOG_FILE${C_OFF}"
    CUR_TASK=""; write_runinfo
    if (( DETACHED && BG_HANDED )); then exit 0; fi    # 任务已由 systemd 托管，前台静默退出
    BG_HANDED=0
    if (( DETACHED )); then
        [[ $fn != mod_report && $fn != mod_full ]] && mod_report "${SELECTED[@]}"
        out ""; out "[$(printf '%(%F %T)T' -1)] 后台任务结束，脚本退出。"
        exit "$WORST"
    fi
    INTERRUPTED=0
    pause_key
}

main_menu() {
    local name i
    while true; do
        clear_screen
        banner
        say ""
        if (( ${#SELECTED[@]} )); then
            say "  已选磁盘:"
            for name in "${SELECTED[@]}"; do
                i=$(di "$name")
                say "    /dev/$(printf '%-8s %-8s %-26.26s' "$name" "${D_SIZE[$i]}" "${D_MODEL[$i]}") $(disk_status_line "$name")"
            done
        else
            say "  ${C_YEL}尚未选择磁盘，请先按 [1]${C_OFF}"
        fi
        say ""
        say "  [1] 选择磁盘"
        say "  [2] 快速体检      SMART 数据 / 温度 / 日志 / 趋势            ${C_DIM}约 30 秒${C_OFF}"
        say "  [3] SMART 短自检  固件快速自检                               ${C_DIM}约 2 分钟${C_OFF}"
        say "  [4] SMART 长自检  固件逐扇区检查全盘（可放后台）             ${C_DIM}数小时${C_OFF}"
        say "  [5] 读性能曲线    全盘分段采样测速                           ${C_DIM}约 1-3 分钟${C_OFF}"
        say "  [6] 全盘读延迟扫描 找坏道+弱扇区，可暂停续扫、多盘并行      ${C_DIM}数小时${C_OFF}"
        say "  [7] badblocks 扫描 全盘只读坏块扫描                          ${C_DIM}数小时${C_OFF}"
        say "  [V] 维修后接口复查 重插/换线后验证 CRC、链路错误是否解决     ${C_DIM}5-60 分钟${C_OFF}"
        say ""
        say "  ${C_BOLD}[F] 一键完整评估${C_OFF}  2→3→4→5→6→报告，开始前一次问完"
        say "  [R] 综合报告      [H] 历史与趋势      [C] 清除结果"
        if (( ! LOCKED )) && instance_alive; then
            say ""; say "  ${C_YEL}● 后台任务进行中：${I_TASK:-检测}（${I_TARGETS}）  按 [W] 查看进度${C_OFF}"
        fi
        say "  [S] 设置          [Q] 退出"
        say ""
        choose "  请按键 > " 1 2 3 4 5 6 7 V F R H C S W Q || { { (( DETACHED )) || ! tty_ok; } && exit "$WORST"; continue; }
        case $KEY in
            1) menu_select ;;
            2) run_task mod_quick ;;
            3) run_task mod_selftest short 1 ;;
            4) run_task mod_selftest long 1 ;;
            5) run_task mod_speed ;;
            6) run_task mod_surface ;;
            7) run_task mod_badblocks ;;
            V) run_task mod_iface ;;
            W) clear_screen; status_view; pause_key ;;
            F) run_task mod_full ;;
            R) run_task mod_report ;;
            H) run_task mod_history ;;
            C) run_task mod_clear ;;
            S) menu_settings ;;
            Q) break ;;
        esac
    done
    clear_screen
}

#------------------------------ 帮助 ------------------------------------------
usage() {
cat <<EOF
${SCRIPT_NAME} v${SCRIPT_VERSION} —— 机械硬盘全方位健康评估 (Debian/Ubuntu，需 root，全程只读)

交互模式（推荐）:
  sudo ${SCRIPT_NAME}              直接运行，进入按键菜单

批处理模式（cron / 脚本调用）:
  -a, --all                扫描所有机械盘
  -d, --disk <列表>        指定磁盘，逗号分隔，如 sda,sdc
      --include-ssd        包含 SSD/NVMe
  -r, --run <项目>         逗号分隔: quick,short,long,speed,surface,badblocks,iface,full
                           （默认 quick；每次都会在最后输出综合报告）
      --duration <分钟>    [V] 接口复查的读取压力时长（默认 15）
      --rescan             已有结果/中断进度一律重新开始（默认: quick 总是重做，
                           其它项有效期内沿用，全盘扫描从断点继续）
  -y, --yes                自动确认（安装依赖、异常区复查等）
  -q, --quiet              只写日志不输出终端
  -l, --log <文件>         日志文件（默认 ${LOG_DIR}/hdd-health-<时间>.log）
  -h, --help               帮助

后台任务（终端断开后任务会自动转入后台跑完）:
      --status             查看后台任务实时进度
      --stop               安全停止后台任务（全盘扫描进度保存，可续扫）
      --detach             批处理任务交给 systemd 后台运行（与终端/SSH 脱钩）

  兼容 v1 参数: -t short|long → --run short/long；-s → speed；-b → badblocks；-w 忽略

数据目录: ${STATE_DIR}（可用环境变量 HDD_STATE_DIR 修改）
退出码  : 0=全部良好  1=有注意/警告  2=有危险盘  3=运行错误

示例:
  sudo ${SCRIPT_NAME} -a -q                         # cron 每日快速巡检
  sudo ${SCRIPT_NAME} -d sdb -r full -y             # 对 sdb 无人值守完整评估
  sudo ${SCRIPT_NAME} -a -r long,surface -y         # 长自检 + 全盘扫描
  sudo ${SCRIPT_NAME} -d sdb -r iface --duration 30 --detach   # 换线后接口复查，后台运行
  sudo ${SCRIPT_NAME} --status                      # 断开重连后查看后台进度
EOF
}

#------------------------------ 参数解析 --------------------------------------
add_run() { RUN_LIST="${RUN_LIST:+$RUN_LIST,}$1"; BATCH=1; }
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)        BATCH=1; REQ_DISKS=() ;;
        -d|--disk)       [[ -n "${2:-}" ]] || die "$1 需要参数"
                         IFS=',' read -ra REQ_DISKS <<< "$2"; BATCH=1; shift ;;
        --include-ssd)   INCLUDE_SSD_CLI=1 ;;
        -r|--run)        [[ -n "${2:-}" ]] || die "$1 需要参数"; add_run "$2"; shift ;;
        -t|--test)       [[ ${2:-} =~ ^(short|long)$ ]] || die "--test 只能为 short/long"; add_run "$2"; shift ;;
        -s|--speed)      add_run speed ;;
        -b|--badblocks)  add_run badblocks ;;
        -w|--wait)       : ;;
        --rescan)        FORCE_RESCAN=1 ;;
        --duration)      [[ ${2:-} =~ ^[0-9]+$ ]] || die "--duration 需要分钟数"; IFACE_MIN=$2; shift ;;
        -l|--log)        [[ -n "${2:-}" ]] || die "$1 需要参数"; LOG_FILE="$2"; shift ;;
        -y|--yes)        ASSUME_YES=1 ;;
        -q|--quiet)      QUIET=1; BATCH=1 ;;
        --status)        CLI_MODE=status ;;
        --detach)        DETACH_REQ=1 ;;
        --plan)          [[ -n "${2:-}" ]] || die "$1 需要参数"; PLAN_FILE=$2; shift ;;
        --stop)          CLI_MODE=stop ;;
        -h|--help)       usage; exit 0 ;;
        *)               echo "未知参数: $1"; usage; exit 3 ;;
    esac
    shift
done

#------------------------------ 前置检查 --------------------------------------
[[ $EUID -eq 0 ]] || die "本脚本必须以 root 运行 (sudo $SCRIPT_NAME)"
(( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 3) )) || die "需要 bash ≥ 4.3"
if (( ! BATCH )) && [[ -z ${CLI_MODE:-} ]]; then
    [[ -t 0 && -t 1 ]] || die "交互模式需要终端；非交互调用请加 -a / -d / --run"
fi

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}${ID_LIKE:-}" in
        *debian*|*ubuntu*) : ;;
        *) say "${C_YEL}警告: 当前系统 (${PRETTY_NAME:-unknown}) 非 Debian/Ubuntu，依赖安装可能失败${C_OFF}" ;;
    esac
fi

declare -a MISS_PKG=()
command -v lsblk    >/dev/null 2>&1 || MISS_PKG+=(util-linux)
command -v blockdev >/dev/null 2>&1 || MISS_PKG+=(util-linux)
command -v smartctl >/dev/null 2>&1 || MISS_PKG+=(smartmontools)
command -v dd       >/dev/null 2>&1 || MISS_PKG+=(coreutils)
command -v badblocks >/dev/null 2>&1 || MISS_PKG+=(e2fsprogs)
if (( ${#MISS_PKG[@]} )); then
    mapfile -t MISS_PKG < <(printf '%s\n' "${MISS_PKG[@]}" | sort -u)
    say "缺少依赖: ${MISS_PKG[*]}"
    if ask_yn "是否用 apt 安装?" Y; then
        export DEBIAN_FRONTEND=noninteractive
        if ! apt-get update -qq || ! apt-get install -y -qq "${MISS_PKG[@]}"; then
            die "依赖安装失败，请手动执行: apt install ${MISS_PKG[*]}"
        fi
    else
        if ! command -v smartctl >/dev/null 2>&1 || ! command -v lsblk >/dev/null 2>&1; then
            die "缺少必需依赖 smartmontools / util-linux，退出"
        fi
        say "将在缺少 badblocks 的情况下继续（坏块扫描与异常复查不可用）"
    fi
fi

[[ ! -L $STATE_DIR ]] || die "数据目录不能是符号链接"
if ! mkdir -p "$STATE_DIR" || ! chmod 700 "$STATE_DIR"; then die "无法创建数据目录 $STATE_DIR"; fi
load_settings
[[ ${INCLUDE_SSD_CLI:-0} -eq 1 ]] && INCLUDE_SSD=1
RUNINFO="$STATE_DIR/running.env"

case ${CLI_MODE:-} in
    status) enumerate_disks; status_view; exit 0 ;;
    stop)   stop_instance; exit 0 ;;
esac

if (( DETACH_REQ )); then
    (( BATCH )) || die "--detach 需配合 -a / -d / --run 使用"
    have_systemd_run || die "本机没有可用的 systemd-run，无法后台运行"
    instance_alive && die "已有实例在运行（PID $I_PID，任务: ${I_TASK:-空闲}）"
    declare -a PASS=()
    for a in "${ORIG_ARGS[@]}"; do [[ $a == --detach ]] || PASS+=("$a"); done
    if [[ -z $LOG_FILE ]]; then mkdir -p "$LOG_DIR"; LOG_FILE="${LOG_DIR}/hdd-health-$(date +%Y%m%d-%H%M%S).log"; PASS+=(-l "$LOG_FILE"); fi
    unit="hdd-health-$(now)"
    systemd_launch "$unit" "${PASS[@]}" -q || die "systemd-run 启动失败"
    echo "已交给系统后台运行（systemd 单元 ${unit}），可以关闭终端。"
    echo "  查看进度: $SCRIPT_NAME --status"
    echo "  安全停止: $SCRIPT_NAME --stop"
    echo "  日志文件: $LOG_FILE"
    exit 0
fi

# 同一时间只允许一个实例（避免两个实例同时扫同一块盘、写同一份进度）
exec 9>"$STATE_DIR/.lock"
if flock -n 9; then LOCKED=1; else
    instance_alive
    if (( BATCH )) || [[ ! -t 0 ]]; then
        die "已有实例在运行（PID ${I_PID:-?}，任务: ${I_TASK:-空闲}）。查看: $SCRIPT_NAME --status  停止: $SCRIPT_NAME --stop"
    fi
    say ""
    say "  ${C_YEL}检测到另一个实例正在运行${C_OFF}（PID ${I_PID:-?}，任务: ${I_TASK:-空闲}，${I_MODE:-运行中}）"
    say ""
    choose "  [W] 查看实时进度   [P] 安全暂停它   [Q] 退出  > " W P Q || exit 0
    case $KEY in
        W) enumerate_disks; status_view ;;
        P) stop_instance ;;
    esac
    exit 0
fi
unset -v a unit 2>/dev/null

if [[ -z $LOG_FILE ]]; then
    [[ ! -L $LOG_DIR ]] || die "日志目录不能是符号链接"
    mkdir -p "$LOG_DIR" || die "无法创建日志目录 $LOG_DIR"
    LOG_FILE="${LOG_DIR}/hdd-health-$(date +%Y%m%d-%H%M%S).log"
else
    [[ ! -L $(dirname "$LOG_FILE") ]] || die "日志目录不能是符号链接"
    mkdir -p "$(dirname "$LOG_FILE")" || die "无法创建日志目录"
fi
[[ ! -L $LOG_FILE ]] || die "日志文件不能是符号链接"
: >> "$LOG_FILE" || die "无法写入日志文件 $LOG_FILE"
chmod 640 "$LOG_FILE" 2>/dev/null

RUN_DIR=$(mktemp -d /run/hdd-health.XXXXXX 2>/dev/null || mktemp -d /tmp/tmp.XXXXXXXXXX) || die "无法创建临时目录"
trap on_int INT TERM
trap on_hup HUP
trap cleanup EXIT
I_START=$(now)

{
    echo "########################################################################"
    echo "#  机械硬盘健康评估日志"
    echo "#  开始时间 : $(date '+%F %T %Z')    主机: $(hostname)"
    echo "#  系统     : ${PRETTY_NAME:-$(uname -s)}   内核: $(uname -r)"
    echo "#  脚本版本 : ${SCRIPT_NAME} v${SCRIPT_VERSION}"
    echo "########################################################################"
} >> "$LOG_FILE"

enumerate_disks
(( ${#D_NAME[@]} )) || die "未检测到任何磁盘"

#------------------------------ 批处理模式 ------------------------------------
if (( BATCH )); then
    RESCAN_POLICY=reuse
    if (( ${#REQ_DISKS[@]} )); then
        for n in "${REQ_DISKS[@]}"; do
            n="${n#/dev/}"; n="${n// /}"
            [[ $n =~ ^[a-zA-Z0-9_-]+$ ]] || die "非法设备名"
            [[ -b "/dev/$n" ]] || printf '%s\n' "${D_NAME[@]}" | grep -qx "$n" || die "设备 /dev/$n 不存在或不是块设备"
            SELECTED+=("$n")
        done
    else
        candidates
        for i in "${CAND[@]}"; do SELECTED+=("${D_NAME[$i]}"); done
    fi
    (( ${#SELECTED[@]} )) || die "没有可检测的磁盘（机械盘）。如需包含 SSD 请加 --include-ssd"
    for n in "${SELECTED[@]}"; do prepare_disk "$n"; done
    out "目标磁盘: ${SELECTED[*]}"
    CUR_TASK="批处理: ${RUN_LIST:-quick}"; write_runinfo
    [[ -z $RUN_LIST ]] && RUN_LIST=quick
    PLAN_RECHECK=$([[ $ASSUME_YES -eq 1 ]] && echo always || echo never)
    if [[ -n $PLAN_FILE && -r $PLAN_FILE ]]; then
        # Only accept plans created in the private state directory.
        [[ $PLAN_FILE == "$STATE_DIR"/plan-hdd-health-*.env && -f $PLAN_FILE && ! -L $PLAN_FILE ]] || die "非法计划文件"
        while IFS=$'\t' read -r key choice; do
            if [[ $key == RECHECK && $choice =~ ^(always|never|ask|)$ ]]; then
                PLAN_RECHECK=$choice
            elif [[ $key =~ ^(quick|selftest_short|selftest_long|speed|surface|badblocks|iface):[a-zA-Z0-9_-]+$ && $choice =~ ^(run|reuse|skip|restart|continue)$ ]]; then
                PLAN[$key]=$choice
            else die "非法计划内容"; fi
        done < "$PLAN_FILE"
        rm -f -- "$PLAN_FILE"
    fi
    IFS=',' read -ra RUNS <<< "$RUN_LIST"
    for r in "${RUNS[@]}"; do
        [[ $INTERRUPTED -eq 1 ]] && break
        case $r in
            quick)     mod_quick "${SELECTED[@]}" ;;
            short)     mod_selftest short 0 "${SELECTED[@]}" ;;
            long)      mod_selftest long 0 "${SELECTED[@]}" ;;
            speed)     mod_speed "${SELECTED[@]}" ;;
            surface)   mod_surface "${SELECTED[@]}" ;;
            badblocks) mod_badblocks "${SELECTED[@]}" ;;
            full)      mod_quick "${SELECTED[@]}"; mod_selftest short 0 "${SELECTED[@]}"
                       mod_selftest long 0 "${SELECTED[@]}"; mod_speed "${SELECTED[@]}"
                       mod_surface "${SELECTED[@]}" ;;
            iface)     mod_iface "${SELECTED[@]}" ;;
            report)    : ;;
            *)         out "未知检测项: $r（可用 quick,short,long,speed,surface,badblocks,full）" ;;
        esac
    done
    mod_report "${SELECTED[@]}"
    out ""; out "完整日志: $LOG_FILE"
    exit "$WORST"
fi

#------------------------------ 交互模式 --------------------------------------
# 默认预选全部机械盘
candidates
for i in "${CAND[@]}"; do SELECTED+=("${D_NAME[$i]}"); done
say "  正在识别磁盘…"
for n in "${SELECTED[@]}"; do prepare_disk "$n"; done
write_runinfo
main_menu
exit "$WORST"
