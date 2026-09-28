---
name: project-overview-zh-cn
description: Project overview and usage
metadata:
  version: "0.1.0"
  lang: zh-CN
---

# hdd-health-check

这款以 root 身份运行的 Bash 工具通过 SMART 数据和只读磁盘检查评估 Debian/Ubuntu 上的 HDD 健康状况.当前 `main` 包含 v3.0.0 核心代码和可选的本地 Web UI.GitHub 提供 `v3.0.0` 源码标签,但没有创建 GitHub Release.Web 服务已在有真实磁盘清单的 Debian NAS 上检查;真实 HDD 的完整评估仍未得到验证.

## 多语言

[English](../../README.md) | **简体中文** | [繁體中文(台灣)](../zh-TW/README.md) | [繁體中文(香港)](../zh-HK/README.md) | [हिन्दी](../hi/README.md) | [Español](../es/README.md) | [العربية](../ar/README.md) | [Français](../fr/README.md)

## 文档

- 项目概览:[README](README.md)

- 设计思路:[DESIGN](DESIGN.md)

- 发布历史:[LOG](LOG.md)

- 第三方声明:[THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## 简介

交互式菜单或批处理 CLI 可选择磁盘,快速评估 SMART,挂载状态和内核日志,并给出启发式 0–100 分及风险等级.其他模块提供 SMART 短测/长测,抽样读速分析,可续扫的全盘读取延迟扫描及可选的针对性 `badblocks` 复查,全盘只读 `badblocks` 检查,以及维修后的接口读取测试.对 HDD,完整评估运行快检,短测,长测,速度和全盘只读扫描;对 SSD,运行快检,短测,长测和全盘只读盘面扫描,不采样速度.两者均不包含独立的全盘 `badblocks` 或接口模块.结果可复用,与 SMART 计数器历史比较并汇总成报告.参见[已知问题](LOG.md#缺陷)和[设计目标](DESIGN.md#设计目标).

完整评估在长时间读取后再次检查快速 SMART/ATA/CRC.只有同一未过期评估批次内所需的快检,短测,长测及完整盘面扫描(以及 HDD 的速度采样)都完成,才显示 0–100 综合分数.复用,中断,过期和旧格式结果仍作为历史证据显示,但等级为部分/未知;查看报告不刷新比较基线.维修接口后,单独进行接口验证并重新完成完整评估,才能得到新分数.已解决的接口检查不会抹去历史错误.没有先前比较值的 ATA 错误总数原因未明,扣 5 分且未解决的风险会在后续检查和完整评估中保留;计数稳定本身不证明风险解除.新增 ATA 错误扣 20 分;未变化的历史计数不算新错误.现有接口验证不能把 ATA 错误归因于接口维修.零星慢读提示复测性能,并非坏扇区证据;确认的读取错误仍属中等风险证据(盘面扣 40 分).通电时长本身不扣健康分;ATA 接近阈值警告需要非零原始错误计数,缺少原始依据的旧阈值提示标为待复查.检查可疑磁盘前请备份重要数据.

**只读指的是目标磁盘数据,并非主机.** 程序会在主机上写入日志,设置,进度和历史记录;可能启用 SMART,启动磁盘内部自检,持续读取整台设备,经确认后安装软件包及启动临时 systemd 单元.不能以此替代备份.本工具不执行破坏性的写入模式盘面扫描,擦除或文件系统写入.

## 要求

- 最低要求:root,Bash 4.3+,Linux 块设备工具(`lsblk`,`blockdev`),`smartctl`(`smartmontools`),`dd`(`coreutils`)及 `flock`;目标平台为 Debian/Ubuntu.其他发行版会收到警告;自动安装依赖使用 `apt-get`.
- 推荐:使用 `badblocks`(`e2fsprogs`)进行盘面检查;使用支持 `systemd-run` 的 systemd 执行分离式任务.缺少软件包时可能提示交互式执行 `apt-get update`/安装(或通过 `-y` 自动确认).无人值守运行前请检查依赖.项目未内置固定版本的第三方代码,也不适用依赖锁文件.
- 评估真实 HDD 健康状况需要实体 HDD 和 SMART 访问.可显式纳入 SSD/NVMe.完成的 SSD 全面评估若 SMART 检查,自检和全盘只读扫描均无异常,得分为 100;实际读取错误和 SMART 异常会降低这一启发式评分.它不是经过校准的故障概率.
## 安装

### 快速安装

在可信的检出目录中运行 `sudo bash ./hdd-health-check.sh --help`,无需启动扫描即可查看选项.不要将未经审查的远程脚本通过管道传给 root shell.

### 常规安装

以下检出当前源码分支.仓库根目录的命令只是简短入口,实现位于 `src/checker/`.
```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check
bash -n hdd-health-check.sh src/checker/hdd-health-check.sh
sudo bash ./hdd-health-check.sh --help
```

扫描前请自行核查并安装所需系统软件包,以免触发脚本的安装提示.升级现有检出目录时,先备份需要保留的主机日志和 `${HDD_STATE_DIR:-/var/lib/hdd-health}`;从经审查的检出目录替换脚本,保留该状态目录以便使用历史记录/续扫,随后查看 `--help` 并执行所选检查.v2.2 仅解析已知的状态数据字段;不符合格式的旧 v2.2 状态可能被拒绝.回滚时需同时恢复旧脚本**及与之匹配的状态备份**;不要假定新版状态向后兼容.不承诺兼容 v1 CLI 行为或迁移 v1 状态.

### 从当前源码安装 Web UI

当前源码不跟踪 `dist/web` 中生成的资源.在 Debian systemd 主机安装 Node.js 20.19+ 或 22.12+ 及 npm,构建界面,然后运行安装器:

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/src/web
npm ci
npm run build
cd ../..
sudo bash deploy/install.sh
```

安装器检查并安装缺少的 Debian 运行依赖,在局域网 8765 端口启动受密码保护的服务,但不会启动磁盘扫描.使用 `sudo cat /root/apps/hdd-health-check/web-password` 查看生成的密码.Node.js 仅用于构建界面.更新,安全边界和回滚说明见 [WEB](WEB.md).

## 指南

只能检查你有权检查的磁盘;持续读取扫描可能造成较大负载.以下命令**仅为示例,并非要求在本环境中验证**:

```bash
sudo bash ./hdd-health-check.sh                 # 终端菜单
sudo bash ./hdd-health-check.sh -a              # 所有机械盘,默认快速检查
sudo bash ./hdd-health-check.sh -d sdb -r quick,short
sudo bash ./hdd-health-check.sh -d sdb -r full -y
sudo bash ./hdd-health-check.sh -d sdb -r iface --duration 30 --detach
sudo bash ./hdd-health-check.sh --status
sudo bash ./hdd-health-check.sh --stop
```

`-d/--disk` 接受逗号分隔的设备名;`-a/--all` 选择机械磁盘,`--include-ssd` 扩展选择范围.`-r/--run` 接受 `quick,short,long,speed,surface,badblocks,iface,full`;默认是 `quick`,批处理模式始终会生成报告.`--duration` 设置接口测试时长(分钟,默认 15).`--rescan` 会重新扫描,而非复用/续扫先前结果;默认情况下,批处理快速检查会重复执行,其他有效结果会复用,中断的盘面扫描会续扫.`-q/--quiet` 抑制终端输出,**但仍写入日志**;`-y/--yes` 自动确认提示,包括安装软件包.`--detach` 要求批处理模式且 `systemd-run` 可用;交互式长任务执行期间终端断开时,也可能转交给 systemd.`--stop` 请求安全停止并保留盘面扫描进度,但**不会**取消磁盘内部的 SMART 自检.`-l/--log FILE` 修改日志路径;`HDD_LOG_DIR` 和 `HDD_STATE_DIR` 覆盖默认目录.`NO_COLOR` 禁用颜色;`HDD_NO_BG` 禁用交互模式下的自动后台转交.菜单设置保存在状态目录中.

解析器还将 `-t short|long` 映射到对应的自检,将 `-s` 映射到速度检查,`-b` 映射到 badblocks;**`-w/--wait` 会被忽略**,不会等待测试完成.这些别名不提供 v1 行为.请以已安装脚本的 `--help` 为准.

退出码:`0` 全部健康;`1` 提示/警告;`2` 危险;`3` 运行时错误.日志默认位于 `/var/log/disk-health/hdd-health-<timestamp>.log`;状态默认位于 `/var/lib/hdd-health`.主机写入及操作边界详见 [DESIGN](DESIGN.md#数据设计).

## 升级

对于当前源码布局,更新检出目录,在 `src/web` 中构建,然后从仓库根目录运行 `sudo bash deploy/install.sh`.安装器将 `src/checker/hdd-health-check.sh`,`src/web/server.py` 和 `dist/web` 复制到现有服务布局,保留 Web 密码,并备份带时间戳的程序及服务单元.以 root 运行安装器前先检查变更.历史 `v3.0.0` 标签仍保留原来的 `web/` 源码布局及其安装说明.

## 卸载

- 删除检出目录或已安装脚本即可移除 CLI,同时保留日志和历史记录.CLI 本身不会永久安装 systemd 服务;若安装了可选 Web 服务,请先按 [WEB](WEB.md) 停止并禁用它.删除脚本前先检查是否仍有运行中的临时任务.
- 要彻底移除,先停止所有任务并备份需要保留的记录,然后核实路径和内容,再手动删除配置的 `HDD_STATE_DIR`(默认 `/var/lib/hdd-health`)和 `HDD_LOG_DIR`(默认 `/var/log/disk-health`).这会删除报告,进度,历史记录,修复记录和日志;切勿盲目删除共用目录或经覆盖的目录.通过 `apt-get` 安装的软件包不会自动卸载.

## 致谢

第三方代码和字体的致谢见 [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md).

## 许可证

MIT(SPDX: MIT);参见 [LICENSE](../../LICENSE).

## 当前固态盘评估与操作

固态盘和 NVMe 的完整评估包括 SMART 快检,短测,长测及全盘只读扫描,不采样速度.单纯慢读不扣健康分;干净完成的批次得 100 分,SMART 异常或实际读取错误可能降低启发式评分.批量控制显示所选磁盘支持的项目并集;仅适用于 HDD 的项目会跳过所选 SSD.点击容量和主机写入量可切换十进制与二进制单位.SATA HDD 可在 SMART 详情页单独唤醒或进入待机.
