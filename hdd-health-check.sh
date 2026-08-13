#!/usr/bin/env bash
#===============================================================================
#  hdd-health-check.sh —— 机械硬盘（HDD）多维度健康扫描与评估
#
#  运行环境 : Debian / Ubuntu
#  运行用户 : root
#  依  赖   : smartmontools, util-linux(lsblk), coreutils
#             可选: hdparm(读性能), e2fsprogs(badblocks 表面扫描)
#
#  检测维度 :
#    1) 设备/接口/固件基础信息       7) 使用寿命(通电时长/次数/负载循环)
#    2) SMART 支持与开启状态         8) 内核 I/O 错误(dmesg)
#    3) SMART 总体健康判定           9) 挂载状态与只读降级检测
#    4) 关键 SMART 属性(坏道类)     10) 可选: 顺序读性能(hdparm)
#    5) SMART 错误日志              11) 可选: 只读表面扫描(badblocks)
#    6) 自检日志 / 可选主动自检     12) 综合评分与等级结论
#
#  退出码   : 0=全部良好  1=存在注意/警告  2=存在危险盘  3=运行错误
#===============================================================================

set -o pipefail

VERSION="1.0"
SCRIPT_NAME="$(basename "$0")"

#------------------------------ 默认参数 --------------------------------------
LOG_DIR="/var/log/disk-health"
LOG_FILE=""
SELECT_ALL=0
INCLUDE_SSD=0
DO_SPEED=0
DO_BADBLOCKS=0
SELF_TEST="none"          # none | short | long
WAIT_TEST=0
ASSUME_YES=0
QUIET=0
declare -a REQ_DISKS=()   # 命令行 -d 指定的盘

#------------------------------ 颜色 ------------------------------------------
if [[ -t 1 && "${NO_COLOR:-}" == "" ]]; then
    C_RED=$'\e[1;31m'; C_YEL=$'\e[1;33m'; C_GRN=$'\e[1;32m'
    C_BLU=$'\e[1;36m'; C_BOLD=$'\e[1m'; C_OFF=$'\e[0m'
else
    C_RED=""; C_YEL=""; C_GRN=""; C_BLU=""; C_BOLD=""; C_OFF=""
fi

#------------------------------ 输出函数 --------------------------------------
# out: 彩色输出到终端，同时把去掉颜色码的内容写入日志
out() {
    local line="$*"
    [[ $QUIET -eq 0 ]] && printf '%b\n' "$line"
    [[ -n "$LOG_FILE" ]] && printf '%b\n' "$line" \
        | sed -r 's/\x1B\[[0-9;]*[mK]//g' >> "$LOG_FILE"
    return 0
}
hr()   { out "------------------------------------------------------------------------"; }
head1(){ out ""; out "${C_BOLD}========================================================================${C_OFF}";
         out "${C_BOLD}$*${C_OFF}";
         out "${C_BOLD}========================================================================${C_OFF}"; }
head2(){ out ""; out "${C_BLU}--- $* ---${C_OFF}"; }
info() { out "    $*"; }
ok()   { out "    ${C_GRN}[正常]${C_OFF} $*"; }
warn() { out "    ${C_YEL}[注意]${C_OFF} $*"; }
bad()  { out "    ${C_RED}[危险]${C_OFF} $*"; }
die()  { out "${C_RED}错误: $*${C_OFF}"; exit 3; }

# 原样把命令输出写进终端与日志（带缩进）
dump() {
    local text="$1"
    while IFS= read -r l; do out "      | $l"; done <<< "$text"
}

#------------------------------ 帮助 ------------------------------------------
usage() {
cat <<EOF
${SCRIPT_NAME} v${VERSION} —— 机械硬盘健康扫描与评估 (Debian/Ubuntu, 需 root)

用法: ${SCRIPT_NAME} [选项]

选择磁盘:
  -a, --all              扫描所有检测到的机械硬盘
  -d, --disk <列表>      只扫描指定磁盘，逗号分隔
                         例: -d sda,sdc   或  -d /dev/sda,/dev/sdc
      --include-ssd      把 SSD/NVMe 也纳入扫描（默认只扫机械盘）
  (不加 -a/-d 时进入交互式选择菜单)

检测强度:
  -t, --test <short|long>  执行 SMART 自检 (short 约 1-2 分钟, long 数小时)
  -w, --wait               自检开始后等待其完成再出报告
  -s, --speed              附加顺序读性能测试 (hdparm -tT, 只读安全)
  -b, --badblocks          附加只读表面扫描 (badblocks, 极慢, 按 TB 计小时)

其他:
  -l, --log <文件>       指定日志文件 (默认 ${LOG_DIR}/hdd-health-<时间戳>.log)
  -y, --yes              自动确认（自动安装缺失依赖、跳过耗时操作确认）
  -q, --quiet            静默模式，只写日志不打印终端（适合 cron）
  -h, --help             显示本帮助

退出码: 0=全部良好  1=有注意/警告  2=有危险盘  3=运行错误

示例:
  ${SCRIPT_NAME} -a                     # 扫描全部机械盘
  ${SCRIPT_NAME} -d sdb,sdc -t short -w # 只扫 sdb/sdc 并跑短自检
  ${SCRIPT_NAME} -a -q -y               # cron 静默巡检
EOF
}

#------------------------------ 参数解析 --------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)         SELECT_ALL=1 ;;
        -d|--disk)        [[ -n "${2:-}" ]] || die "$1 需要参数"
                          IFS=',' read -ra REQ_DISKS <<< "$2"; shift ;;
        --include-ssd)    INCLUDE_SSD=1 ;;
        -t|--test)        [[ -n "${2:-}" ]] || die "$1 需要参数"
                          SELF_TEST="$2"; shift
                          [[ "$SELF_TEST" =~ ^(short|long|none)$ ]] || die "--test 只能为 short/long" ;;
        -w|--wait)        WAIT_TEST=1 ;;
        -s|--speed)       DO_SPEED=1 ;;
        -b|--badblocks)   DO_BADBLOCKS=1 ;;
        -l|--log)         [[ -n "${2:-}" ]] || die "$1 需要参数"; LOG_FILE="$2"; shift ;;
        -y|--yes)         ASSUME_YES=1 ;;
        -q|--quiet)       QUIET=1 ;;
        -h|--help)        usage; exit 0 ;;
        *)                echo "未知参数: $1"; usage; exit 3 ;;
    esac
    shift
done

#------------------------------ 前置检查 --------------------------------------
[[ $EUID -eq 0 ]] || die "本脚本必须以 root 运行 (sudo $SCRIPT_NAME ...)"

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    case "${ID}${ID_LIKE}" in
        *debian*|*ubuntu*) : ;;
        *) out "${C_YEL}警告: 当前系统 (${PRETTY_NAME:-unknown}) 非 Debian/Ubuntu，依赖安装可能失败${C_OFF}" ;;
    esac
fi

# 依赖检查与安装
declare -a MISS_PKG=()
command -v lsblk    >/dev/null 2>&1 || MISS_PKG+=(util-linux)
command -v smartctl >/dev/null 2>&1 || MISS_PKG+=(smartmontools)
[[ $DO_SPEED     -eq 1 ]] && ! command -v hdparm    >/dev/null 2>&1 && MISS_PKG+=(hdparm)
[[ $DO_BADBLOCKS -eq 1 ]] && ! command -v badblocks >/dev/null 2>&1 && MISS_PKG+=(e2fsprogs)

if [[ ${#MISS_PKG[@]} -gt 0 ]]; then
    echo "缺少依赖: ${MISS_PKG[*]}"
    if [[ $ASSUME_YES -eq 1 ]]; then
        ans="y"
    else
        read -rp "是否立即用 apt 安装? [Y/n] " ans </dev/tty
        ans="${ans:-y}"
    fi
    if [[ "$ans" =~ ^[Yy] ]]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq && apt-get install -y -qq "${MISS_PKG[@]}" \
            || die "依赖安装失败，请手动执行: apt install ${MISS_PKG[*]}"
    else
        die "依赖缺失，退出"
    fi
fi

# 日志文件
if [[ -z "$LOG_FILE" ]]; then
    mkdir -p "$LOG_DIR" || die "无法创建日志目录 $LOG_DIR"
    LOG_FILE="${LOG_DIR}/hdd-health-$(date +%Y%m%d-%H%M%S).log"
else
    mkdir -p "$(dirname "$LOG_FILE")" || die "无法创建日志目录"
fi
: > "$LOG_FILE" || die "无法写入日志文件 $LOG_FILE"
chmod 640 "$LOG_FILE" 2>/dev/null

#------------------------------ 工具函数 --------------------------------------
# 取字符串开头的数字，非法/空返回 0
num() { local v="${1:-}"; v="${v%%[!0-9]*}"; echo "${v:-0}"; }

# 枚举磁盘 -> DISK_* 数组
declare -a D_NAME=() D_SIZE=() D_MODEL=() D_ROTA=() D_TRAN=()
enumerate_disks() {
    local line NAME TYPE ROTA SIZE MODEL TRAN
    while IFS= read -r line; do
        NAME=""; TYPE=""; ROTA=""; SIZE=""; MODEL=""; TRAN=""
        eval "$line"
        [[ "$TYPE" == "disk" ]] || continue
        case "$NAME" in loop*|ram*|sr*|zram*|md*|dm-*|fd*) continue ;; esac
        D_NAME+=("$NAME"); D_SIZE+=("$SIZE")
        D_MODEL+=("${MODEL:-未知型号}"); D_ROTA+=("$ROTA"); D_TRAN+=("${TRAN:-?}")
    done < <(lsblk -dP -o NAME,TYPE,ROTA,SIZE,MODEL,TRAN 2>/dev/null)
}

disk_kind() { [[ "$1" == "1" ]] && echo "机械盘" || echo "固态盘"; }

# 自动探测 smartctl 需要的 -d 参数（USB 盒/桥接常见问题）
detect_dopt() {
    local dev="$1" c
    local -a cands=("" "-d sat" "-d sat,12" "-d scsi" "-d ata"
                    "-d usbjmicron" "-d usbprolific" "-d usbsunplus" "-d usbasm1352r,0")
    for c in "${cands[@]}"; do
        if smartctl -i $c "$dev" 2>/dev/null \
           | grep -qE '^(Device Model|Model Number|Model Family|Product|Vendor):'; then
            echo "$c"; return 0
        fi
    done
    echo "__FAIL__"; return 1
}

#------------------------------ 交互式选择 ------------------------------------
declare -a TARGETS=()

select_targets() {
    local i n
    # 命令行显式指定
    if [[ ${#REQ_DISKS[@]} -gt 0 ]]; then
        for n in "${REQ_DISKS[@]}"; do
            n="${n#/dev/}"; n="${n// /}"
            [[ -b "/dev/$n" ]] || die "设备 /dev/$n 不存在或不是块设备"
            TARGETS+=("$n")
        done
        return
    fi

    # 候选列表（按 --include-ssd 过滤）
    local -a cand=()
    for i in "${!D_NAME[@]}"; do
        [[ $INCLUDE_SSD -eq 0 && "${D_ROTA[$i]}" != "1" ]] && continue
        cand+=("$i")
    done
    [[ ${#cand[@]} -gt 0 ]] || die "未检测到可扫描的磁盘（机械盘）。如需包含 SSD 请加 --include-ssd"

    if [[ $SELECT_ALL -eq 1 || $QUIET -eq 1 ]]; then
        for i in "${cand[@]}"; do TARGETS+=("${D_NAME[$i]}"); done
        return
    fi

    # 交互菜单
    echo
    echo "检测到以下磁盘："
    printf "  %-4s %-10s %-8s %-8s %-7s %s\n" "编号" "设备" "容量" "类型" "接口" "型号"
    local k=1
    declare -a MAP=()
    for i in "${cand[@]}"; do
        printf "  %-4s %-10s %-8s %-8s %-7s %s\n" \
            "$k" "/dev/${D_NAME[$i]}" "${D_SIZE[$i]}" "$(disk_kind "${D_ROTA[$i]}")" \
            "${D_TRAN[$i]}" "${D_MODEL[$i]}"
        MAP+=("${D_NAME[$i]}")
        ((k++))
    done
    echo
    echo "请输入要扫描的编号（支持 1 3 5 / 1-3 / all）："
    local reply tok a b
    read -rp "> " reply </dev/tty
    reply="${reply//,/ }"
    [[ -z "$reply" || "$reply" == "all" || "$reply" == "ALL" ]] && reply="1-${#MAP[@]}"
    for tok in $reply; do
        if [[ "$tok" =~ ^[0-9]+-[0-9]+$ ]]; then
            a="${tok%-*}"; b="${tok#*-}"
            for ((n=a; n<=b; n++)); do
                [[ $n -ge 1 && $n -le ${#MAP[@]} ]] && TARGETS+=("${MAP[$((n-1))]}")
            done
        elif [[ "$tok" =~ ^[0-9]+$ ]]; then
            [[ $tok -ge 1 && $tok -le ${#MAP[@]} ]] && TARGETS+=("${MAP[$((tok-1))]}")
        fi
    done
    [[ ${#TARGETS[@]} -gt 0 ]] || die "未选择任何磁盘"
}

#------------------------------ 单盘检测 --------------------------------------
declare -a SUMMARY=()
WORST=0     # 0 好 / 1 注意警告 / 2 危险

check_disk() {
    local name="$1" dev="/dev/$1"
    local SCORE=100
    local -a ISSUES=()
    local dopt_str; local -a DOPT=()

    head1 "磁盘 $dev"

    # ---------- 1. 基础信息 ----------
    head2 "1. 设备基础信息"
    local size model rota tran serial idx
    size="?"; model="?"; rota="?"; tran="?"
    for idx in "${!D_NAME[@]}"; do
        if [[ "${D_NAME[$idx]}" == "$name" ]]; then
            size="${D_SIZE[$idx]}"; model="${D_MODEL[$idx]}"
            rota="${D_ROTA[$idx]}"; tran="${D_TRAN[$idx]}"
        fi
    done
    info "设备节点 : $dev"
    info "容量     : $size"
    info "型号     : $model"
    info "类型     : $(disk_kind "$rota")   接口: $tran"
    if [[ "$rota" != "1" ]]; then
        warn "该设备为非旋转介质（SSD/NVMe），部分机械盘专用指标不适用"
    fi

    # 挂载情况
    local mnts
    mnts=$(lsblk -nr -o NAME,MOUNTPOINT "/dev/$name" 2>/dev/null | awk 'NF>1{print "  /dev/"$1" -> "$2}')
    if [[ -n "$mnts" ]]; then
        info "挂载点   :"
        dump "$mnts"
        # 只读降级检测（文件系统被内核强制 ro 通常意味着硬件出错）
        local ro
        ro=$(awk -v d="$name" '$1 ~ d {print $2, $4}' /proc/mounts 2>/dev/null | grep -c '\bro\b')
        if [[ "$ro" -gt 0 ]]; then
            bad "检测到该盘上有文件系统被挂载为只读，通常是 I/O 错误导致的降级！"
            ISSUES+=("文件系统被强制只读"); SCORE=$((SCORE-25))
        fi
    else
        info "挂载点   : 无（未挂载）"
    fi

    # ---------- 2. SMART 可用性 ----------
    head2 "2. SMART 支持与状态"
    dopt_str="$(detect_dopt "$dev")"
    if [[ "$dopt_str" == "__FAIL__" ]]; then
        bad "smartctl 无法识别该设备（可能位于 RAID 控制器后或 USB 桥接不支持直通）"
        info "可尝试手动指定，例如: smartctl -a -d sat /dev/$name"
        info "               MegaRAID: smartctl -a -d megaraid,0 /dev/$name"
        SUMMARY+=("$name|$model|N/A|无法读取")
        [[ $WORST -lt 1 ]] && WORST=1
        return
    fi
    read -ra DOPT <<< "$dopt_str"
    [[ -n "$dopt_str" ]] && info "smartctl 访问方式: $dopt_str" || info "smartctl 访问方式: 自动"

    local sinfo
    sinfo=$(smartctl -i "${DOPT[@]}" "$dev" 2>&1)
    serial=$(grep -m1 -E 'Serial [Nn]umber' <<< "$sinfo" | sed 's/.*:[[:space:]]*//')
    local fw rpm
    fw=$(grep -m1 -E 'Firmware Version|Revision' <<< "$sinfo" | sed 's/.*:[[:space:]]*//')
    rpm=$(grep -m1 -E 'Rotation Rate' <<< "$sinfo" | sed 's/.*:[[:space:]]*//')
    [[ -n "$serial" ]] && info "序列号   : $serial"
    [[ -n "$fw"     ]] && info "固件版本 : $fw"
    [[ -n "$rpm"    ]] && info "转速     : $rpm"

    if grep -q 'SMART support is:.*Unavailable' <<< "$sinfo"; then
        warn "该设备不支持 SMART，后续指标不可用"
        SUMMARY+=("$name|$model|N/A|不支持SMART")
        [[ $WORST -lt 1 ]] && WORST=1
        return
    fi
    if grep -q 'SMART support is:.*Disabled' <<< "$sinfo"; then
        warn "SMART 已关闭，正在尝试开启..."
        smartctl -s on "${DOPT[@]}" "$dev" >/dev/null 2>&1 \
            && ok "SMART 已开启" || warn "开启 SMART 失败"
    else
        ok "SMART 已启用"
    fi

    local is_sas=0
    grep -qE 'Transport protocol:.*SAS|Vendor:' <<< "$sinfo" && is_sas=1

    # ---------- 3. 总体健康 ----------
    head2 "3. SMART 总体健康判定"
    local health
    health=$(smartctl -H "${DOPT[@]}" "$dev" 2>&1)
    if grep -qE 'PASSED|OK' <<< "$health"; then
        ok "总体健康自评: PASSED"
    elif grep -qiE 'FAILED|FAILURE' <<< "$health"; then
        bad "总体健康自评: FAILED —— 硬盘已判定为即将失效，请立即备份并更换！"
        ISSUES+=("SMART 总体健康 FAILED"); SCORE=$((SCORE-60))
    else
        warn "无法解析总体健康状态"
        dump "$health"
    fi

    # ---------- 4. 关键属性 ----------
    head2 "4. 关键 SMART 属性"
    local SMART_A
    SMART_A=$(smartctl -A "${DOPT[@]}" "$dev" 2>/dev/null)

    get_raw() { awk -v id="$1" '$1==id && NF>=10 {print $10; exit}' <<< "$SMART_A"; }

    local reall pend offl runc cmdto crc spinr e2e poh pcyc lcc ssc temp seek
    reall=$(num "$(get_raw 5)")     # 重映射扇区数
    pend=$(num  "$(get_raw 197)")   # 当前待映射扇区
    offl=$(num  "$(get_raw 198)")   # 无法校正扇区
    runc=$(num  "$(get_raw 187)")   # 报告的不可纠正错误
    cmdto=$(num "$(get_raw 188)")   # 命令超时
    crc=$(num   "$(get_raw 199)")   # UDMA CRC 错误(线缆/接口)
    spinr=$(num "$(get_raw 10)")    # 主轴重试
    e2e=$(num   "$(get_raw 184)")   # 端到端错误
    poh=$(num   "$(get_raw 9)")     # 通电小时
    pcyc=$(num  "$(get_raw 12)")    # 通电次数
    ssc=$(num   "$(get_raw 4)")     # 启停次数
    lcc=$(num   "$(get_raw 193)")   # 磁头负载/卸载循环
    seek=$(num  "$(get_raw 7)")
    temp=$(num  "$(get_raw 194)")
    [[ "$temp" == "0" ]] && temp=$(num "$(get_raw 190)")
    if [[ "$temp" == "0" ]]; then
        temp=$(num "$(grep -m1 -iE 'Current Drive Temperature' <<< "$SMART_A" | sed 's/[^0-9]*\([0-9]*\).*/\1/')")
    fi

    if [[ -z "$SMART_A" || $is_sas -eq 1 ]] && ! grep -qE '^ *[0-9]+ ' <<< "$SMART_A"; then
        info "该盘为 SAS/SCSI 类型，使用缺陷表与错误计数评估："
        local sasall grown ruerr wuerr
        sasall=$(smartctl -a "${DOPT[@]}" "$dev" 2>/dev/null)
        grown=$(num "$(grep -m1 -i 'grown defect list' <<< "$sasall" | sed 's/[^0-9]*\([0-9]*\).*/\1/')")
        ruerr=$(grep -m1 '^read:' <<< "$sasall" | awk '{print $NF}')
        wuerr=$(grep -m1 '^write:' <<< "$sasall" | awk '{print $NF}')
        info "增长型缺陷表条目 : ${grown}"
        info "读不可纠正错误   : ${ruerr:-N/A}   写不可纠正错误: ${wuerr:-N/A}"
        if [[ "$grown" -gt 0 ]]; then
            if [[ "$grown" -gt 50 ]]; then
                bad "缺陷表条目 $grown，介质劣化明显"; SCORE=$((SCORE-40)); ISSUES+=("SAS 缺陷表 $grown")
            else
                warn "缺陷表条目 $grown，需持续观察"; SCORE=$((SCORE-15)); ISSUES+=("SAS 缺陷表 $grown")
            fi
        else
            ok "缺陷表为空"
        fi
        [[ "$(num "${ruerr:-0}")" -gt 0 ]] && { bad "存在不可纠正读错误"; SCORE=$((SCORE-30)); ISSUES+=("读不可纠正错误"); }
    else
        printf_attr() { out "$(printf '    %-28s %s' "$1" "$2")"; }
        printf_attr "05 重映射扇区数"        "$reall"
        printf_attr "197 当前待映射扇区"     "$pend"
        printf_attr "198 脱机无法校正扇区"   "$offl"
        printf_attr "187 报告的不可纠正错误" "$runc"
        printf_attr "188 命令超时"           "$cmdto"
        printf_attr "199 接口 CRC 错误"      "$crc"
        printf_attr "10  主轴启动重试"       "$spinr"
        printf_attr "184 端到端错误"         "$e2e"
        out ""

        # ---- 逐项评分 ----
        if   [[ $reall -eq 0 ]]; then ok "无重映射扇区"
        elif [[ $reall -le 10  ]]; then warn "已重映射 $reall 个扇区，盘面开始出现缺陷，建议观察增长速度"
             SCORE=$((SCORE-15)); ISSUES+=("重映射扇区 $reall")
        elif [[ $reall -le 100 ]]; then bad "已重映射 $reall 个扇区，劣化明显，建议尽快更换"
             SCORE=$((SCORE-35)); ISSUES+=("重映射扇区 $reall")
        else bad "已重映射 $reall 个扇区，磁盘严重劣化，立即更换"
             SCORE=$((SCORE-55)); ISSUES+=("重映射扇区 $reall")
        fi

        if [[ $pend -eq 0 ]]; then ok "无待映射(不稳定)扇区"
        else bad "存在 $pend 个待映射扇区 —— 读取该区域会失败，数据风险高"
             SCORE=$((SCORE-30)); ISSUES+=("待映射扇区 $pend")
        fi

        if [[ $offl -eq 0 ]]; then ok "无脱机不可校正扇区"
        else bad "存在 $offl 个不可校正扇区，已发生数据丢失风险"
             SCORE=$((SCORE-30)); ISSUES+=("不可校正扇区 $offl")
        fi

        if [[ $runc -gt 0 ]]; then
            warn "报告的不可纠正错误 $runc 次"
            SCORE=$((SCORE- (runc>10 ? 20 : 10) )); ISSUES+=("不可纠正错误 $runc")
        fi
        if [[ $e2e -gt 0 ]]; then
            bad "端到端错误 $e2e 次（数据通路/缓存异常）"
            SCORE=$((SCORE-15)); ISSUES+=("端到端错误 $e2e")
        fi
        if [[ $spinr -gt 0 ]]; then
            bad "主轴启动重试 $spinr 次（电机/供电异常）"
            SCORE=$((SCORE-20)); ISSUES+=("主轴重试 $spinr")
        fi
        if [[ $cmdto -gt 100 ]]; then
            warn "命令超时 $cmdto 次（供电不足或线缆接触不良也会导致）"
            SCORE=$((SCORE-5)); ISSUES+=("命令超时 $cmdto")
        fi
        if [[ $crc -gt 0 ]]; then
            warn "接口 CRC 错误 $crc 次 —— 通常是 SATA 线/供电/背板问题，先换线再观察"
            SCORE=$((SCORE-8)); ISSUES+=("CRC 错误 $crc")
        fi

        # 已越过厂商阈值的属性
        local failed_attrs
        failed_attrs=$(awk 'NF>=10 && $1 ~ /^[0-9]+$/ && $9!="-" && $9!="" {print "  ID "$1" "$2" (WHEN_FAILED="$9")"}' <<< "$SMART_A")
        if [[ -n "$failed_attrs" ]]; then
            bad "以下属性已越过厂商安全阈值："
            dump "$failed_attrs"
            SCORE=$((SCORE-20)); ISSUES+=("属性越过阈值")
        fi
    fi

    # ---------- 5. 温度 ----------
    head2 "5. 温度"
    if [[ "$temp" -gt 0 ]]; then
        info "当前温度 : ${temp} °C"
        if   [[ $temp -ge 60 ]]; then bad "温度过高，机械盘长期 >60°C 会显著缩短寿命"
             SCORE=$((SCORE-25)); ISSUES+=("温度 ${temp}°C")
        elif [[ $temp -ge 55 ]]; then warn "温度偏高，建议改善机箱风道"
             SCORE=$((SCORE-15)); ISSUES+=("温度 ${temp}°C")
        elif [[ $temp -ge 50 ]]; then warn "温度略高（理想区间 25-45°C）"
             SCORE=$((SCORE-5))
        else ok "温度处于健康区间"
        fi
    else
        info "未能读取温度"
    fi

    # ---------- 6. 寿命与负载 ----------
    head2 "6. 使用寿命与负载"
    if [[ $poh -gt 0 ]]; then
        info "累计通电 : ${poh} 小时 (约 $((poh/24)) 天 / $((poh/8760)) 年)"
        if   [[ $poh -ge 50000 ]]; then warn "通电时长已超 5 万小时，属超期服役，建议规划替换"
             SCORE=$((SCORE-15)); ISSUES+=("通电 ${poh}h")
        elif [[ $poh -ge 35000 ]]; then warn "通电时长较高，建议加强备份与巡检"
             SCORE=$((SCORE-8))
        else ok "通电时长在正常范围"
        fi
    fi
    [[ $pcyc -gt 0 ]] && info "通电次数 : $pcyc"
    [[ $ssc  -gt 0 ]] && info "启停次数 : $ssc"
    if [[ $lcc -gt 0 ]]; then
        info "磁头负载循环 : $lcc"
        if [[ $lcc -ge 600000 ]]; then
            warn "负载循环次数过高（>60 万），常见于开启激进省电(APM)的盘，建议用 hdparm -B 254 调整"
            SCORE=$((SCORE-10)); ISSUES+=("负载循环 $lcc")
        fi
    fi

    # ---------- 7. 错误日志 ----------
    head2 "7. SMART 错误日志"
    local elog ecount
    elog=$(smartctl -l error "${DOPT[@]}" "$dev" 2>/dev/null)
    if grep -qi 'No Errors Logged' <<< "$elog"; then
        ok "错误日志为空"
    else
        ecount=$(num "$(grep -m1 -iE 'ATA Error Count' <<< "$elog" | sed 's/[^0-9]*\([0-9]*\).*/\1/')")
        if [[ $ecount -gt 0 ]]; then
            bad "SMART 错误日志中有 $ecount 条记录（最近 5 条见下）"
            dump "$(grep -A3 -E '^Error [0-9]+ ' <<< "$elog" | head -n 24)"
            SCORE=$((SCORE- (ecount>20 ? 20 : 10) )); ISSUES+=("错误日志 $ecount 条")
        else
            info "未解析到明确的错误计数"
        fi
    fi

    # ---------- 8. 自检 ----------
    head2 "8. SMART 自检"
    if [[ "$SELF_TEST" != "none" ]]; then
        info "正在启动 ${SELF_TEST} 自检..."
        smartctl -t "$SELF_TEST" "${DOPT[@]}" "$dev" >/dev/null 2>&1
        if [[ "$SELF_TEST" == "short" || $WAIT_TEST -eq 1 ]]; then
            local maxwait=900 waited=0 prog
            [[ "$SELF_TEST" == "long" ]] && maxwait=43200
            while [[ $waited -lt $maxwait ]]; do
                sleep 20; waited=$((waited+20))
                prog=$(smartctl -c "${DOPT[@]}" "$dev" 2>/dev/null | grep -i 'of test remaining')
                [[ -z "$prog" ]] && break
                [[ $QUIET -eq 0 ]] && printf '\r    自检进行中... 已等待 %ss  %s' "$waited" "${prog//[[:space:]]+/ }"
            done
            [[ $QUIET -eq 0 ]] && printf '\r%*s\r' 100 ''
            info "自检结束（等待 ${waited}s）"
        else
            info "长自检已在后台启动，稍后可用以下命令查看结果："
            info "  smartctl -l selftest $dopt_str $dev"
        fi
    fi

    local slog last
    slog=$(smartctl -l selftest "${DOPT[@]}" "$dev" 2>/dev/null)
    if grep -qi 'No self-tests have been logged' <<< "$slog"; then
        warn "该盘从未执行过自检，建议加 -t short 跑一次基础自检"
        SCORE=$((SCORE-3))
    else
        last=$(grep -m1 -E '^#[[:space:]]*1' <<< "$slog")
        info "最近一次自检: ${last:-无记录}"
        if grep -qiE 'read failure|Completed: failure|unknown failure|electrical failure|servo|handling damage' <<< "$slog"; then
            bad "自检历史中存在失败记录"
            dump "$(grep -E '^#' <<< "$slog" | head -n 5)"
            SCORE=$((SCORE-25)); ISSUES+=("自检失败记录")
        else
            ok "自检历史无失败记录"
        fi
    fi

    # ---------- 9. 内核 I/O 错误 ----------
    head2 "9. 内核日志 (dmesg) I/O 错误"
    local kerr
    kerr=$(dmesg -T 2>/dev/null | grep -iE "\b${name}\b" \
           | grep -iE 'I/O error|medium error|unrecovered read error|failed command|SMART error|ata bus error|hard resetting' \
           | tail -n 10)
    if [[ -n "$kerr" ]]; then
        bad "内核日志中存在与该盘相关的 I/O 错误（最近 10 条）："
        dump "$kerr"
        SCORE=$((SCORE-20)); ISSUES+=("内核 I/O 错误")
    else
        ok "内核日志中未发现相关 I/O 错误"
    fi

    # ---------- 10. 读性能 ----------
    if [[ $DO_SPEED -eq 1 ]]; then
        head2 "10. 顺序读性能 (hdparm，只读)"
        local sp
        sp=$(hdparm -tT "$dev" 2>&1 | grep -E 'Timing')
        dump "${sp:-测试失败}"
        local mbs
        mbs=$(grep 'buffered disk reads' <<< "$sp" | sed -n 's/.*= *\([0-9.]*\) MB\/sec.*/\1/p')
        if [[ -n "$mbs" ]]; then
            local mbi="${mbs%%.*}"
            if [[ "${mbi:-0}" -lt 40 && "$rota" == "1" ]]; then
                warn "顺序读仅 ${mbs} MB/s，明显低于健康机械盘水平，可能存在坏道重试或降速"
                SCORE=$((SCORE-10)); ISSUES+=("读取速度偏低 ${mbs}MB/s")
            else
                ok "顺序读 ${mbs} MB/s"
            fi
        fi
    fi

    # ---------- 11. 表面扫描 ----------
    if [[ $DO_BADBLOCKS -eq 1 ]]; then
        head2 "11. 只读表面扫描 (badblocks)"
        local goscan="y"
        if [[ $ASSUME_YES -eq 0 && $QUIET -eq 0 ]]; then
            read -rp "    $dev 全盘只读扫描可能耗时数小时，确认执行? [y/N] " goscan </dev/tty
        fi
        if [[ "$goscan" =~ ^[Yy] ]]; then
            local bbout bbcount
            bbout=$(badblocks -b 4096 -s -v "$dev" 2>&1)
            bbcount=$(grep -c '^[0-9]\+$' <<< "$bbout")
            if [[ $bbcount -gt 0 ]]; then
                bad "表面扫描发现 $bbcount 个坏块"
                dump "$(head -n 20 <<< "$bbout")"
                SCORE=$((SCORE-40)); ISSUES+=("表面坏块 $bbcount")
            else
                ok "表面扫描未发现坏块"
            fi
        else
            info "已跳过表面扫描"
        fi
    fi

    # ---------- 12. 结论 ----------
    [[ $SCORE -lt 0 ]] && SCORE=0
    local grade color
    if   [[ $SCORE -ge 90 ]]; then grade="良好";              color="$C_GRN"
    elif [[ $SCORE -ge 75 ]]; then grade="注意(建议观察)";    color="$C_YEL"; [[ $WORST -lt 1 ]] && WORST=1
    elif [[ $SCORE -ge 50 ]]; then grade="警告(尽快备份)";    color="$C_YEL"; [[ $WORST -lt 1 ]] && WORST=1
    else                            grade="危险(建议更换)";   color="$C_RED"; WORST=2
    fi

    head2 "综合结论"
    out "    健康评分 : ${color}${SCORE}/100${C_OFF}"
    out "    健康等级 : ${color}${grade}${C_OFF}"
    if [[ ${#ISSUES[@]} -gt 0 ]]; then
        out "    发现问题 :"
        local it
        for it in "${ISSUES[@]}"; do out "      - $it"; done
        out "    建议     : 立即确认备份完整；若存在待映射/不可校正扇区或自检失败，请更换硬盘。"
    else
        out "    发现问题 : 无"
    fi

    SUMMARY+=("$name|$model|$SCORE|$grade")
}

#------------------------------ 主流程 ----------------------------------------
enumerate_disks
[[ ${#D_NAME[@]} -gt 0 ]] || die "未检测到任何块设备"
select_targets

# 日志头
out "########################################################################"
out "#  机械硬盘健康检测报告"
out "#  生成时间 : $(date '+%Y-%m-%d %H:%M:%S %Z')"
out "#  主机名   : $(hostname)"
out "#  系统     : ${PRETTY_NAME:-$(uname -s)}   内核: $(uname -r)"
out "#  脚本版本 : ${SCRIPT_NAME} v${VERSION}"
out "#  日志文件 : ${LOG_FILE}"
out "#  本次目标 : ${TARGETS[*]}"
out "########################################################################"

for t in "${TARGETS[@]}"; do
    check_disk "$t"
done

# ---------- 汇总表 ----------
head1 "汇总"
out "$(printf '  %-10s %-26s %-8s %s' '设备' '型号' '评分' '等级')"
hr
for row in "${SUMMARY[@]}"; do
    IFS='|' read -r n m s g <<< "$row"
    out "$(printf '  %-10s %-26.26s %-8s %s' "/dev/$n" "$m" "$s" "$g")"
done
hr
out ""
out "完整日志已保存至: ${C_BOLD}${LOG_FILE}${C_OFF}"
case $WORST in
    0) out "${C_GRN}总体结论: 所有受检磁盘状态良好。${C_OFF}" ;;
    1) out "${C_YEL}总体结论: 存在需要关注的磁盘，请核对上方明细并确保备份可用。${C_OFF}" ;;
    2) out "${C_RED}总体结论: 存在高风险磁盘，请立即备份数据并准备更换！${C_OFF}" ;;
esac

exit $WORST
