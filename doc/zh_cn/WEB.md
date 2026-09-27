---
name: web-guide-zh-cn
description: 本地 Web UI 的安装和运行说明
metadata:
  version: "0.1.0"
  lang: zh-CN
---

# 本地 Web UI

Web UI 展示本机磁盘结果,SMART 计数历史,运行中的任务,并可设置定时快速巡检.它调用现有 Bash 检查器执行检查.只有同一批次,完整且未过期的评估才显示当前数字评分;部分结果和历史结果不会被当成当前评分.

关注卡片直接显示检查原因.通电时长仅作参考,不单独扣分;旧版缺少原始错误计数的阈值提示改为待复查.检查确认使用站内弹窗,详情以型号为标题,设备路径在下.

## 构建和运行

在 Debian NAS 上解压已构建的测试包,进入解压目录后运行:

```bash
sudo bash deploy/install.sh
```

安装脚本会检查 Debian,systemd,Python 3.10+,安装文件和 8765 端口,通过 apt 安装缺失依赖,将检查器及已构建的界面复制到 `/root/apps/hdd-health-check`,启用并检查 `hdd-health-web.service`.安装过程不会扫描磁盘.重新安装时会保留旧程序和服务单元的带时间戳备份;若启动失败,会尝试恢复.脚本不会改动已有的磁盘状态和日志.NAS 上不需要 Node.js 或前端构建.之后可用 `sudo systemctl status hdd-health-web.service` 查看状态.

安装后,从同一局域网的电脑打开 `http://<NAS-IP>:8765`.网页登录页会要求输入随机生成的密码.在 NAS 上运行 `sudo cat /root/apps/hdd-health-check/web-password` 查看密码;重新安装时会保留它.密码文件只有 root 可读.若页面打不开,检查服务状态以及 NAS 防火墙是否允许局域网访问 TCP 8765.安装脚本不会修改防火墙.

以下手动构建步骤适用于开发或没有已构建测试包的情况.

需要 Debian/Ubuntu,Python 3.10+,systemd,`systemd-run`,项目原有检查依赖,以及与项目 Vite 版本兼容的 Node.js.检查器与 Web 服务均需 root 权限.在可信的检出目录中运行:

```bash
cd web
npm ci
npm run build
cd ..
sudo python3 web/server.py --port 8765
```

访问 `http://127.0.0.1:8765`.这条手动命令只监听本机,不要求密码.运行时不需要 Node,但需将检出目录与 `web/dist` 放在一起.常驻运行请使用上面的安装脚本;systemd 单元需要安装时生成的密码文件.升级前应备份与脚本版本匹配的 `/var/lib/hdd-health`.

Codex 的 `site-preview` 地址只提供静态文件.它可以展示界面和打包进前端的更新记录,但没有 `/api` 后端,因此不能显示磁盘或启动检查.查看真实数据时请打开上面的 Python 服务地址.如需加密传输,可在另一台电脑执行 `ssh -L 8765:127.0.0.1:8765 user@nas-host`,再打开 `http://127.0.0.1:8765`.安装器部署的服务即使通过隧道访问,也会要求密码.

卸载 Web 服务时,先运行 `sudo systemctl disable --now hdd-health-web.service`,删除已安装的服务单元,再运行 `sudo systemctl daemon-reload`.删除检出目录前先检查是否仍有临时检查任务;状态和日志可按 CLI 卸载说明单独保留或删除.

## 从 main 分支源码安装 Web UI

`main` 分支不包含构建产物 `web/dist`.在 Debian systemd 主机上先安装 Node.js 20.19+ 或 22.12+ 和 npm,再构建网页并运行安装器.Node.js 仅用于构建;服务运行时不需要.

```bash
git clone --branch main --depth 1 https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/web
npm ci
npm run build
cd ..
sudo bash deploy/install.sh
```

## 使用边界

- 定时快速巡检默认关闭.启用后每 6–168 小时检查一次机械盘;首次启用后会在短时间内启动第一次巡检.
- 手动和批量检查可选择现有检测项目,包括固态盘的完整评估.长测和盘面读取会增加负载.安全停止会保存盘面扫描进度,但不会取消磁盘内部的 SMART 自检.
- Web 服务启动任务时附加 `--no-install`,不会自动批准安装软件包.请预先安装所需依赖.
- 安装器部署的服务监听所有 IPv4 地址,但只接受与实际访问地址一致的 Host,检查 Origin,并对 API 使用网页会话登录或指定来源 IPv4 免密访问.它没有 TLS;能查看局域网 HTTP 流量的人也能看到密码.仅在可信局域网使用,不要把 TCP 8765 转发到公网;需要加密传输时使用 SSH 隧道.手动运行 `python3 web/server.py` 默认仍只监听本机.
- 定时设置保存在私有状态目录内的 `web-schedule.json`.Web API 通过同源 JSON 提供结果,评分由 Bash 脚本的 `--json` 模式计算,Web 服务不会自行重算.
- 界面控件支持项目的八种语言.详细检查摘要及实时任务日志仍来自现有中文 Bash 检查器,因此无论选用哪种界面语言,这些内容仍为中文.

休眠盘经 SMART 明确确认后,列表和详情显示“休眠中”;读取中的温度显示“读取中”,读取失败仍显示未知.唤醒策略保存在 `/var/lib/hdd-health/web-preferences.json`,默认关闭.任何已登录用户都可编辑 IP 名单和休眠策略;修改密码仍需当前密码.

## 界面与权限

顶部依次显示仪表盘,更新记录和设置.仪表盘在磁盘,需要关注,运行任务(包括历史记录)及定时巡检页面保持激活;在这些页面点击仪表盘不会改变当前页面,只有从设置或更新记录点击时才返回 `/disks`.左上角 Logo 始终链接到 `/disks`.四张概览卡分别打开 `/disks`,`/attention`,`/tasks`,`/schedule`;一键评估留在磁盘主页.更新记录入口打开可直接访问的独立 `/changelog` 页面.

左上角的 HDD Health 项目名称链接到 `/disks` 磁盘主页.浏览器标签页使用 `web/public/favicon.svg` 中的项目图标, 并随正式构建一起提供.

设置页管理外观,精确 IPv4 免密名单,硬盘休眠策略和登录密码.已进入页面的用户可直接编辑 IP 名单和休眠策略;通过 IP 免密进入时也会直接显示修改密码表单,提交时由服务端校验当前密码.默认保持机械硬盘休眠;也可选择打开网页时逐块唤醒休眠盘并读取温度.磁盘详情提供 SMART 信息与检测两个标签;更新记录在独立页面按 Markdown 渲染.

主页的一键评估可分别选择磁盘范围和检测项目.范围包括 SATA,机械盘,固态盘,NVMe 或全部磁盘;项目包括快速,SMART 短/长自检,速度,盘面,badblocks,接口复查和完整评估.服务端按当前枚举结果选盘,运行所选项目的后台任务.只有完整评估可能生成当前综合分数;SSD/NVMe 评分仍沿用机械盘规则,未单独校准.列表按传输协议和介质类型显示 SATA SSD,NVMe SSD 等,并在后台读取可用温度,避免唤醒休眠机械盘.详情页仅在设备明确报告时显示外形规格;不能仅凭 NVMe 或 SATA 判断是否为 M.2.SATA 版本和速率来自 smartctl 或 Linux sysfs;NVMe 的 PCIe 代际,通道数和链路速率来自 sysfs.点击通电时长可切换小时与年/天/小时.

需要关注卡片筛出有警告或异常记录的磁盘.检测详情列出原因和扣分;旧记录扣分但未保存原因时提示重新检查.任务页保留正在运行的任务和可展开的详细日志,另设最近 30 条任务历史;任务结束后从运行区清除收据,在 `web-job-history/` 保存新任务收据,并保留磁盘检测结果和主机日志.返回码 1 或 2 表示检测完成但发现问题,并非启动失败.

主页面汇总物理硬盘总容量和已挂载文件系统的已用量,按文件系统 UUID 去重;RAID,未挂载卷可能造成两者口径不同.SSD 的 SMART 详情优先显示 NVMe 标准写入量,或具有明确逻辑扇区大小的 ATA 设备统计写入量;厂商自定义计数不猜测单位.可识别的 ZFS 池分配空间也计入已用量.容量按钮可切换 TB/TiB,查看详情由独立按钮打开.

任务页保留运行中任务,另设历史记录,展示最近 30 条已完成,停止或失败的 Web 任务,并可查看有存留日志时的详细末尾.新的任务收据保存在 `web-job-history/`;已删除的旧收据无法可靠恢复.顶部“仪表盘”在磁盘,需要关注,运行任务和定时巡检页面保持激活.
