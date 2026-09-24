# hdd-health-check

这款以 root 身份运行的 Bash 工具通过 SMART 数据和只读磁盘检查评估 Debian/Ubuntu 上的 HDD 健康状况。v2.2.0 脚本已整合至此，但**尚未发布，也未在真实硬件上验证**。

## 多语言

[English](../../README.md) | **简体中文** | [繁體中文](../zh_tw/README.md) | [繁體中文（香港）](../zh_hk/README.md) | [हिन्दी](../hi/README.md) | [Español](../es/README.md) | [العربية](../ar/README.md) | [Français](../fr/README.md)

## 文档

- 项目概览：[README](README.md)
- 设计依据及对主机的影响：[DESIGN](DESIGN.md)
- 决策、缺陷与版本历史：[LOG](LOG.md)
- 第三方清单：[THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## 简介

通过交互式菜单或批处理 CLI 选择磁盘，执行快速 SMART、挂载状态及内核日志评估，并给出启发式 0–100 分及风险等级。其他模块支持 SMART 短程／长程自检、抽样读取速度分析、可续扫的全盘读取延迟扫描（可选择针对性地用 `badblocks` 复查）、全盘只读 `badblocks` 检查，以及修复后的接口读取测试。完整评估依次运行快速、短程、长程、速度和盘面检查；不包含独立的全盘 `badblocks` 或接口模块。结果可复用、与 SMART 计数器历史进行比较，并汇总为报告。参见[已知问题](LOG.md#已知问题)和[设计目标](DESIGN.md#设计目标)。

**只读指的是目标磁盘数据，不是主机。**程序会在主机上写入日志、设置、进度和历史记录；还可能启用 SMART、启动磁盘内部自检、在持续负载下读取整个设备、经确认后安装软件包，以及启动临时 systemd 单元。不可用它替代备份。本工具未实现破坏性的写入模式盘面扫描、擦除或文件系统写入。

## 运行要求

- 最低要求：root、Bash 4.3+、Linux 块设备工具（`lsblk`、`blockdev`）、`smartctl`（`smartmontools`）、`dd`（`coreutils`）及 `flock`；目标平台为 Debian/Ubuntu。其他发行版会收到警告；自动安装依赖使用 `apt-get`。
- 推荐：使用 `badblocks`（`e2fsprogs`）进行盘面检查；使用支持 `systemd-run` 的 systemd 执行分离式任务。缺少软件包时可能提示交互式执行 `apt-get update`／安装（或通过 `-y` 自动确认）。无人值守运行前请检查依赖。项目未内置固定版本的第三方代码，也不适用依赖锁文件。
- 要评估实际健康状况，需有真实 HDD 和 SMART 访问权限。可显式纳入 SSD/NVMe，但面向 HDD 的评分并非经过校准的 SSD/NVMe 评估。

## 安装

### 快速安装

在可信的检出目录中运行 `sudo bash ./hdd-health-check.sh --help`，无需启动扫描即可查看选项。不要将未经审查的远程脚本通过管道传给 root shell。

### 常规安装

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check
bash -n hdd-health-check.sh
sudo bash ./hdd-health-check.sh --help
```

扫描前请自行核查并安装所需系统软件包，以免触发脚本的安装提示。升级现有检出目录时，先备份需要保留的主机日志和 `${HDD_STATE_DIR:-/var/lib/hdd-health}`；从经审查的检出目录替换脚本，保留该状态目录以便使用历史记录／续扫，随后查看 `--help` 并执行所选检查。v2.2 仅解析已知的状态数据字段；不符合格式的旧 v2.2 状态可能被拒绝。回滚时必须同时恢复旧脚本**及与之匹配的状态备份**；不要假定新版状态向后兼容。不承诺兼容 v1 CLI 行为或迁移 v1 状态。

## 使用指南

只能检查你有权检查的磁盘；持续读取扫描可能造成较大负载。以下命令**仅为示例，并非要求在本环境中验证**：

```bash
sudo bash ./hdd-health-check.sh                 # terminal menu
sudo bash ./hdd-health-check.sh -a              # all rotational disks, default quick scan
sudo bash ./hdd-health-check.sh -d sdb -r quick,short
sudo bash ./hdd-health-check.sh -d sdb -r full -y
sudo bash ./hdd-health-check.sh -d sdb -r iface --duration 30 --detach
sudo bash ./hdd-health-check.sh --status
sudo bash ./hdd-health-check.sh --stop
```

`-d/--disk` 接受逗号分隔的设备名；`-a/--all` 选择机械磁盘，`--include-ssd` 扩展选择范围。`-r/--run` 接受 `quick,short,long,speed,surface,badblocks,iface,full`；默认是 `quick`，批处理模式始终会生成报告。`--duration` 设置接口测试时长（分钟，默认 15）。`--rescan` 会重新扫描，而非复用／续扫先前结果；默认情况下，批处理快速检查会重复执行，其他有效结果会复用，中断的盘面扫描会续扫。`-q/--quiet` 禁止终端输出，**但不禁止写日志**；`-y/--yes` 自动确认提示，包括安装软件包。`--detach` 要求批处理模式且 `systemd-run` 可用；交互式长任务执行期间终端断开时，也可能转交给 systemd。`--stop` 请求安全停止并保留盘面扫描进度，但**不会**取消磁盘内部的 SMART 自检。`-l/--log FILE` 修改日志路径；`HDD_LOG_DIR` 和 `HDD_STATE_DIR` 覆盖默认目录。`NO_COLOR` 禁用颜色；`HDD_NO_BG` 禁用交互模式下的自动后台转交。菜单设置保存在状态目录中。

解析器还将 `-t short|long` 映射到对应的自检，将 `-s` 映射到速度检查、`-b` 映射到 badblocks；**`-w/--wait` 会被忽略**，不会等待测试完成。这些别名不提供 v1 行为。请以已安装脚本的 `--help` 为准。

退出码：`0` 全部健康；`1` 提示／警告；`2` 危险；`3` 运行时错误。日志默认位于 `/var/log/disk-health/hdd-health-<timestamp>.log`；状态默认位于 `/var/lib/hdd-health`。主机写入及操作边界详见 [DESIGN](DESIGN.md#数据设计)。

## 卸载

- 删除检出目录或已安装脚本即可移除工具，同时保留日志和历史记录。工具不会永久安装 systemd 服务；删除脚本前先检查是否仍有运行中的临时任务。
- 要彻底移除，先停止所有任务并备份需要保留的记录，然后核实路径和内容，再手动删除配置的 `HDD_STATE_DIR`（默认 `/var/lib/hdd-health`）和 `HDD_LOG_DIR`（默认 `/var/log/disk-health`）。这会删除报告、进度、历史记录、修复记录和日志；切勿盲目删除共用目录或经覆盖的目录。通过 `apt-get` 安装的软件包不会自动卸载。

## 许可证

MIT（SPDX: MIT）；参见 [LICENSE](../../LICENSE)。
