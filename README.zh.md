# hdd-health-check

[English](README.md) | **简体中文**

> 译自 `README.md`（v1.0.0）。如有冲突，以英文版为准。

一个用于 Debian/Ubuntu 的机械硬盘（HDD）多维度健康扫描脚本，基于 `smartmontools`，root 权限运行。

## 功能

- 设备/接口/固件基础信息
- SMART 支持与开启状态检测
- SMART 总体健康判定（PASSED/FAILED）
- 关键 SMART 属性解析（重映射扇区、待映射扇区、不可校正扇区、CRC 错误、主轴重试等）
- SMART 错误日志分析
- 自检日志查看，支持发起 short/long 主动自检
- 使用寿命与负载评估（通电时长、通电次数、磁头负载循环）
- 内核日志（dmesg）I/O 错误扫描
- 挂载状态与只读降级检测
- 可选：hdparm 顺序读性能测试（只读，安全）
- 可选：badblocks 只读表面扫描
- 综合评分（0-100）与健康等级结论
- 结果保存到日志文件，支持批量/交互式选盘

## 环境要求

- Debian / Ubuntu
- root 权限
- 依赖：`smartmontools`（脚本会在缺失时提示自动安装），可选 `hdparm`、`e2fsprogs`

## 安装

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check
chmod +x hdd-health-check.sh
```

## 用法

```bash
sudo ./hdd-health-check.sh                  # 交互式选盘
sudo ./hdd-health-check.sh -a               # 扫描全部机械盘
sudo ./hdd-health-check.sh -d sdb,sdc       # 只扫描指定磁盘
sudo ./hdd-health-check.sh -a -t short -w   # 顺带跑短自检并等待结果
sudo ./hdd-health-check.sh -a -q -y         # 静默模式，适合 cron 定时巡检
```

完整参数说明：

```bash
sudo ./hdd-health-check.sh --help
```

## 验证是否装对

对至少一块真实 HDD 跑一遍：

```bash
sudo ./hdd-health-check.sh -a
```

应看到每块盘的报告，以综合评分（0-100）与健康等级结论收尾，并以下方文档的退出码之一结束进程。
若缺少 `smartmontools`，脚本会侦测到并提示安装，而不是静默失败。

## 退出码

| 退出码 | 含义 |
|---|---|
| 0 | 全部磁盘状态良好 |
| 1 | 存在需要关注的注意/警告项 |
| 2 | 存在高风险磁盘，建议立即备份并更换 |
| 3 | 运行错误（权限不足、依赖缺失等） |

## 配置

无需环境变量配置——所有选项都是命令行参数（见 `--help`）。用户常需要覆盖的路径：

| 参数 | 含义 | 默认值 |
|---|---|---|
| `-l, --log <文件>` | 日志文件路径 | `/var/log/disk-health/hdd-health-<时间戳>.log` |

## License

MIT
