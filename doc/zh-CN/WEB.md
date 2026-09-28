---
name: web-guide-zh-cn
description: 本地 Web UI 的安装和运行说明
metadata:
  version: "0.1.0"
  lang: zh-CN
---

# 本地 Web UI

Web UI 展示本机磁盘结果,SMART 计数历史,运行中的任务,并可设置定时快速巡检.它调用现有 Bash 检查器执行检查.只有同一批次,完整且未过期的评估才显示当前数字评分;部分结果和历史结果不会被当成当前评分.

关注卡片直接显示检查原因.通电时长仅作参考,不单独扣分;旧版缺少原始错误计数的阈值提示改为待复查.检查确认使用站内弹窗,详情以型号为标题,`/dev/` 设备路径在下.

## 多语言

[English](../WEB.md) | **简体中文** | [繁體中文 (台灣)](../zh-TW/WEB.md) | [繁體中文 (香港)](../zh-HK/WEB.md) | [हिन्दी](../hi/WEB.md) | [Español](../es/WEB.md) | [العربية](../ar/WEB.md) | [Français](../fr/WEB.md)

## 文档

- 项目概览: [README](README.md)

- 设计依据: [DESIGN](DESIGN.md)

- 版本历史: [LOG](LOG.md)

- 第三方清单: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

- Web UI 指南: [WEB](WEB.md)
## 要求

- Debian 或 Ubuntu,Python 3.10+,与仓库内 Vite 版本兼容的 Node.js,systemd 及 `systemd-run`.
- 现有检查器依赖:`smartmontools`,`util-linux`,`coreutils`,以及用于 badblocks 的可选 `e2fsprogs`.
- Web 服务需要 root 权限.Debian 安装器在 IPv4 端口 8765 监听,为 API 提供网页登录及会话.在同一可信局域网访问 `http://<NAS-IP>:8765`;不要把端口转发到互联网.局域网 HTTP 不加密密码;需要加密传输时可使用 SSH 本地端口转发.

## 构建和运行

当前源码将 Web UI 代码放在 `src/web/`,不跟踪生成的 `dist/web/` 构建产物.历史 `v3.0.0` 标签保留原来的 `web/` 布局.在 Debian systemd 主机安装 Node.js 20.19+ 或 22.12+ 及 npm,构建 UI,然后运行安装器:

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/src/web
npm ci
npm run build
cd ../..
sudo bash deploy/install.sh
```

更新检出目录后再次执行构建和安装步骤.Node.js 仅在构建时需要;安装后的服务使用 Python 和检查器依赖.以 root 运行前先审查 `deploy/install.sh`.

使用预构建的 Debian NAS 归档包时,解压并进入目录,然后运行:

```bash
sudo bash deploy/install.sh
```

安装器检查 Debian,systemd,Python 3.10+,软件包文件和端口 8765;通过 apt 安装缺少的软件包;将检查器和已构建的 UI 复制到 `/root/apps/hdd-health-check`;启用并检查 `hdd-health-web.service`.它不会启动磁盘扫描.更新时,安装器将旧应用和服务单元保存为带时间戳的备份,启动失败时尝试恢复.它不修改已有磁盘状态或日志.预构建归档包在 NAS 上无需 Node.js 或前端构建.

安装后,从同一局域网的电脑打开 `http://<NAS-IP>:8765`.登录页面要求输入生成的密码.在 NAS 上运行 `sudo cat /root/apps/hdd-health-check/web-password` 查看;更新时安装器会保留此密码.密码文件仅 root 可读.Security Settings 会在显示 IP 名单或密码修改表单前要求管理员密码.验证后,可在五分钟权限窗口内输入并确认 12–128 字符的新密码,无需再次输入旧密码.修改会使所有 Web 会话失效,需要重新登录.若页面无法打开,检查 `sudo systemctl status hdd-health-web.service`,以及 NAS 防火墙是否允许局域网 TCP 8765.安装器不修改防火墙规则.

以后可用 `sudo systemctl status hdd-health-web.service` 查看服务状态.以下手动构建和运行步骤供开发或没有预构建归档包时使用.

在可信的检出目录中运行:

```bash
cd src/web
npm ci
npm run build
cd ../..
sudo python3 src/web/server.py --port 8765
```

打开 `http://127.0.0.1:8765`.这条手动命令使服务只监听回环地址,无需密码.Python 进程提供 UI 构建产物;运行时不需要 Node.请将源码检出目录及其 `dist/web` 保持在一起.`npm run dev` 在另一个本地端口运行 Vite,并将 `/api` 代理到 Python 服务.

Codex `site-preview` 地址只提供静态文件.它可显示布局和打包的更新记录,但没有 `/api` 后端,不能显示磁盘或执行检查.实时数据应打开上面的 Python 服务地址.从其他电脑加密访问时,使用 `ssh -L 8765:127.0.0.1:8765 user@nas-host` 转发 NAS 回环端口,然后在该电脑打开 `http://127.0.0.1:8765`.通过隧道访问安装器部署的服务时仍需登录密码.

常驻服务请使用上面的安装器:其 systemd 单元依赖安装时创建的密码文件.升级前请用匹配的脚本版本备份 `/var/lib/hdd-health`.Web UI 不改变脚本的状态迁移政策.

移除 Web 服务时,运行 `sudo systemctl disable --now hdd-health-web.service`,删除已安装的单元文件,再运行 `sudo systemctl daemon-reload`.删除检出目录前,检查仍在运行的临时任务.状态和日志按 CLI 卸载说明另行保留或删除.

## 行为与边界

- 自动快速检查默认关闭.启用后每 6–168 小时运行一次;若此前没有排定检查,首次检查会在启用后不久开始.计划只覆盖机械盘,并通过临时 systemd 单元启动.
- 手动检查按磁盘选择.单盘控件也为 SSD 提供快检,SMART 短测/长测,全盘只读扫描及完整评估.批次控件显示所选磁盘支持项目的并集;混合 HDD/SSD 选择中,仅适用于 HDD 的项目在符合条件的 HDD 上运行,跳过 SSD.固态盘单独选择时只提供支持的检查.网页将两种介质的全设备只读检查明确标为“全盘只读扫描”.工具仍可能启用 SMART 或启动磁盘内部自检.安全停止保留盘面进度,但不取消磁盘内部自检.
- Web 服务启动任务时附加 `--no-install`,不批准安装软件包.缺少的依赖需单独安装.服务只接受固定的检查名称和当前枚举的设备,构造命令时不使用 shell.
- 私有状态目录默认仍为 `/var/lib/hdd-health`,日志目录为 `/var/log/disk-health`.`web-schedule.json`,`web-job.json`,`web-job-history/` 中已完成任务的收据,以及 `web-access.json` 中的私有地址允许名单和启用开关,均以受限权限存放在私有状态目录.浏览器通过同源 JSON 接口查看健康结果和最近历史.
- 安装器部署监听所有 IPv4 地址,但只接受与目标 IP 和端口一致的 Host.它检查 Origin,要求 API 请求有密码会话或允许名单内的来源 IPv4 地址.静态资源公开以供登录页加载.只有近期通过管理员密码验证的会话才能读取或编辑私有地址允许名单及其启用开关;仅靠 IP 进入只能访问普通仪表盘功能.退出时设置浏览器 Cookie,抑制自动 IP 登录,直到用户重新选择 IP 登录.服务不提供 TLS;能查看局域网 HTTP 流量的人可能看见密码.只在可信局域网或 SSH 隧道中使用,不要向互联网开放 TCP 8765.手动运行 `python3 src/web/server.py` 时,除非提供 `--bind` 和 `--password-file`,否则仍只监听回环地址.
- 界面控件支持项目的八种语言.详细检查摘要和实时任务日志来自现有中文 Bash 检查器,因此无论选择哪种界面语言,这些内容目前仍为中文.

## API

`GET /api/auth` 报告登录状态;`POST /api/auth/login`,`/api/auth/logout` 和 `/api/auth/ip-login` 管理会话.`POST /api/auth/security-verify` 检查管理员密码,轮换会话 Cookie,并授予固定五分钟的 Security Settings 权限.`POST /api/auth/change-password` 要求该权限及匹配的新密码/确认字段;它以原子操作替换 root 所有的密码文件,并使现有会话失效.`GET` 和 `POST /api/access` 要求同样的短时权限;可读取或编辑启用开关及精确的 RFC 1918 IPv4 或 IPv6 唯一本地地址.`GET` 和 `POST /api/preferences` 供已认证访客读取和保存是否在进入页面时唤醒休眠盘.`POST /api/disks/wake-on-visit` 在后台启动已选择的唤醒操作.`GET /api/disks/<device>/smart` 按需读取 SMART 详情,不唤醒待机 HDD;已认证的 `POST /api/disks/<device>/wake` 只唤醒当前枚举的机械盘.`GET /api/snapshot` 返回检查器的结构化磁盘快照.`GET /api/status` 返回运行中任务显示和有界的实时日志末尾.读取状态时,已完成,停止,失败及失效的 Web 收据会从运行中显示移除;已完成任务收据另行归档.`GET /api/jobs/history` 返回所有归档 Web 任务摘要;主机日志仍在时,`GET /api/jobs/history/<id>` 返回有界日志末尾.已经删除收据的旧任务无法可靠重建.`GET /api/history/<device>` 为兼容性返回最多 30 行 SMART 计数器.`GET /api/history/samples` 返回所有已枚举磁盘的 SMART 趋势样本,供统一历史页使用.已认证的 `DELETE /api/history/samples/<device>/<index>` 删除一条 SMART 样本;若删除最后一行,将改变下一次比较基线.`DELETE /api/jobs/history/<id>` 删除已完成 Web 任务收据及关联日志.`POST /api/disks/<device>/sleep` 只对当前枚举的 SATA HDD 请求 ATA 待机,检查运行时拒绝;正常的操作系统 I/O 可能再次唤醒它.`GET` 和 `POST /api/schedule` 管理快检间隔.`POST /api/jobs` 在枚举设备上启动固定检查;`POST /api/jobs/assess` 接受 `scope` 为 `sata`,`hdd`,`ssd`,`nvme` 或 `all`,以及 `module` 为 `quick`,`short`,`long`,`speed`,`surface`,`badblocks`,`iface` 或 `full`,并为匹配的已枚举磁盘启动一个批次.`POST /api/jobs/stop` 请求安全停止.未知 API 路由返回 404.检查器的 `--json` 输出是评分来源;Web 服务不重新计算分数.

## 界面与权限

顶部依次显示仪表盘,更新记录和设置.仪表盘在磁盘,需要关注,运行任务(包括历史记录)及定时巡检页面保持激活;在这些页面点击仪表盘不会改变当前页面,只有从设置或更新记录点击时才返回 `/disks`.左上角 Logo 始终链接到 `/disks`.四张概览卡分别打开 `/disks`,`/attention`,`/tasks`,`/schedule`;一键评估留在磁盘主页.更新记录入口打开可直接访问的独立 `/changelog` 页面.

左上角的 HDD Health 项目名称链接到 `/disks` 磁盘主页.相邻的独立版本链接打开更新记录;无标签构建显示为 `test-<sha>`,修改过的工作树追加 `-dirty`,`/api/build` 返回构建时嵌入的版本.浏览器标签页使用 `src/web/public/favicon.svg` 中的项目图标,并随正式构建一起提供.磁盘列表将型号作为标题,另列 `/dev/` 路径;公开快照省略可能包含序列号的内部磁盘 ID;快照和 SMART API 只发送遮蔽的序列号.用户按下显示控件后,SMART 详情通过独立认证请求取得完整序列号;隐藏或关闭详情时清除它.

普通设置页提供语言,八种主题色和浅色/深色模式切换,以及硬盘休眠策略与 Security Settings 入口.主题色和明暗模式分别保存,重新加载页面后仍保持选择.只有近期通过管理员密码验证的会话可查看和修改私有地址允许名单及其启用开关,并在五分钟窗口内更改密码.仅通过 IP 进入的用户仍可使用普通磁盘和休眠策略功能,但需验证管理员密码后才能进入安全设置.默认保持机械硬盘休眠;也可选择打开网页时逐块唤醒休眠盘并读取温度.磁盘详情提供 SMART 信息与检测两个标签;更新记录在独立的 `/changelog` 页面按 Markdown 渲染.

主页的一键评估可分别选择磁盘范围和检测项目.范围包括 SATA,机械盘,固态盘,NVMe 或全部磁盘;项目包括快速,SMART 短/长自检,速度,盘面,badblocks,接口复查和完整评估.服务端按当前枚举结果选盘,运行 `<module> --rescan` 后台批次.只有 `full` 完整评估可能生成当前综合分数;SSD/NVMe 评分未经单独校准;SSD 的慢读不扣健康分,干净完成的批次得 100 分,SMART 异常或实际读取错误会降低启发式评分.列表按传输协议和介质类型显示 SATA SSD,NVMe SSD 等,并在后台读取可用温度,默认使用 `smartctl -n standby` 避免唤醒休眠机械盘;选择唤醒策略后,工作进程先用 `-n standby` 逐盘确认待机状态,再按顺序读取 SMART 属性.无法读取的温度仍保持未知,不会据此判定设备健康.详情页仅在设备明确报告时显示外形规格;不能仅凭 NVMe 或 SATA 判断是否为 M.2.SATA 版本和速率来自 `smartctl` 或 Linux sysfs;NVMe 的 PCIe 代际,通道数和链路速率来自 sysfs.点击通电时长可切换小时与年/天/小时.

需要关注卡片筛出有警告或异常记录的磁盘.详情以型号为标题,`/dev/` 路径在下.检测详情列出原因和扣分;旧记录扣分但未保存原因时提示重新检查.任务页保留正在运行的任务和可展开的详细日志,另设最近 30 条任务历史;任务结束后从运行区清除收据,在 任务归档目录 保存新任务收据,并保留磁盘检测结果和主机日志.返回码 1 或 2 表示检测完成但发现问题,并非启动失败.

主页面汇总物理硬盘总容量和已挂载文件系统的已用量,按文件系统 UUID 去重;RAID,未挂载卷可能造成两者口径不同.SSD 的 SMART 详情优先显示 NVMe 标准写入量,或具有明确逻辑扇区大小的 ATA 设备统计写入量;厂商自定义计数不猜测单位.可识别的 ZFS 池分配空间也计入已用量.容量按钮可切换 TB/TiB,查看详情由独立按钮打开.

任务页保留运行中任务,另设历史记录,展示最近 30 条已完成,停止或失败的 Web 任务,并可查看有存留日志时的详细末尾.新的任务收据保存在 任务归档目录;已删除的旧收据无法可靠恢复.顶部“仪表盘”在磁盘,需要关注,运行任务和定时巡检页面保持激活.

## 当前固态盘评估与操作

固态盘与 NVMe 的完整评估包括 SMART 快检,短测,长测和全盘只读扫描,不运行速度采样.单纯慢读不扣健康分;同一批次全部检查完成且无异常时显示 100 分,SMART 异常或实际读取错误可能扣分.选中范围含固态盘时,网页仅提供快速检查,短测,长测,只读扫描及完整评估.点击容量或固态盘累计写入量可切换十进制与二进制单位.休眠机械盘的 SMART 详情可单独唤醒该盘.
