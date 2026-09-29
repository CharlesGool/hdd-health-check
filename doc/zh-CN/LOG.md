---
name: project-log-zh-cn
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: zh-CN
---

# hdd-health-check — 日志

本文记录已采纳的历史决策,已知限制和发布历史.当前大版本为 `v4.1.0`.用户报告较早的 `v2.2.0` 曾在实机运行,但未提供设备,环境或测试覆盖范围.修订后的评分已有模拟测试及 Debian NAS 上的 Web 验证,但尚未在真实 HDD 上完成受控的完整评估.

## 多语言

[English](../LOG.md) | **简体中文** | [繁體中文(台灣)](../zh-TW/LOG.md) | [繁體中文(香港)](../zh-HK/LOG.md) | [हिन्दी](../hi/LOG.md) | [Español](../es/LOG.md) | [العربية](../ar/LOG.md) | [Français](../fr/LOG.md)

## 文档

- 项目概览:[README](README.md)

- 设计思路:[DESIGN](DESIGN.md)

- 发布历史:[LOG](LOG.md)

- 第三方声明:[THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## 缺陷

- [ ] 用户报告已在实机测试 v2.2.0,但未提供设备,环境或测试范围;不能确认 root/软件包安装或 systemd 行为已测;此前 v1.0.0 发布检查也没有真实 HDD 和 SMART 数据(仅检查语法及帮助).据称原始目录规范化之前使用过此脚本,但这不能代替受控的硬件测试.
- [ ] 修订后的批次评分及末尾 SMART/ATA/CRC 复查只通过合成测试,尚未经真实 HDD 验证.固件自检日志时间精度及跨运行续扫可能导致部分/未知;维修后无法自动重新归因旧错误. 此硬件验证局限仍予以披露;仍建议在获授权 HDD 上复测.
- [ ] 启发式健康评分权重并非经过校准的故障概率;SAS/SCSI 评分比 ATA 验证得少,USB/RAID SMART 透传可能失败.依赖厂商数据的温度报告尚不完整.
- [ ] 已在 Debian NAS 上检查带认证的局域网 Web 服务和真实磁盘清单;真实 HDD 完整评估及重启后恢复仍未验证.不符合格式的旧 v2.2 状态会被拒绝;目前不提供 CSV 导出.
- [x] 用户提供的 `test-771001c` 截图显示,磁盘详情中当前标签的下划线超出所选标签.旧指示线按整数按钮宽度缩放一像素线条.现在直接动画调整到按钮测得的精确宽度;本地 Chromium 在窄屏,缩放和 RTL 情况下,下划线均与选中的 SMART 和 Checks 按钮匹配.无法取得截图的确切浏览器配置以复现.
- [ ] 用户报告从磁盘详情返回时的动画有问题,并要求留待以后处理.修复标签下划线时没有修改返回动画代码.
- [x] v1.0.0 目录规范化修正了克隆说明中指向不存在的 `hdd-health-check-repo/main` 路径,以及简体中文 README 中混用繁体字的问题.

## 限制

- 已安装的 Debian 服务为兼容升级,仍使用 `/root/apps/hdd-health-check/web/` 主机目录布局;源码位于 `src/web/`,生成的构建产物位于 `dist/web/`.

### 兼容入口

基线: `35f24e5`
原因: 现有 CLI 命令及安装说明调用仓库根目录的 Shell 入口;实现现位于 `src/checker/`.
更新边界: 保留根目录调度入口,直到另行告知的 CLI 路径迁移取代现有命令.

- `hdd-health-check.sh` -> `src/checker/hdd-health-check.sh`

## 决策

| 决策 | 原因 |
| --- | --- |
| 2026-08-12:将本地项目拆分为 Git 工作树和独立快照;不采用扁平化的本地目录结构. | 历史发布快照需要与跟踪的源代码分开.当时使用的 `main/` 名称仅存在于本地,从未成为 GitHub 检出目录的一部分;当时计划使用 tag 和 `git archive` 快照. |
| 2026-08-13:将本地 `main/` 重命名为 `repo/`;修正安装路径,双语标题和 `.gitignore`;不在公开状态信息中显示私有镜像和快照路径.拒绝原样提交已暂存的过时文档. | GitHub 检出目录的根目录中即有脚本.克隆后旧命令片段会立即失败;本地路径和翻译错误不应出现在公开文档中. |
| 2026-08-13:不在现有虚拟磁盘上模拟真实 HDD 发布检查;披露验证程度较低. | 当时没有可用的 SMART 硬件或 `smartmontools`;安装软件包并扫描虚拟磁盘无法测试 HDD 逻辑. |
| 2026-08-13:以一个使用 noreply 身份的干净提交及附注标签替换公开的 v1.0.0 历史,并将原始历史保存在重命名后的私有归档中;拒绝强制推送之前的公开仓库,也不保留已被取代的中间提交. | 此前的公开提交在 Git 元数据中含有个人电子邮箱.现有克隆/派生仓库不会自动迁移,也无法保证缓存中先前暴露的信息已被删除.这是历史记录,并非再次改写历史的授权. |
| 当前整合:采用提供的 v2.2.0 行为,不保证兼容 v1,并保留现有 MIT 许可证. | 新脚本增加持久化状态和可选后台任务;`-w` 会被忽略.整合当时并未声称已经发布,打标签或通过硬件验证. |

## 交接

2026-09-29.分支 `main`;正式版 `v4.1.0` 已从 `09e6fa5` 发布并部署到 Debian NAS.未发现项目临时规则.

- NAS 安装器后续检查:首次安装 `test-bf14ed5` 时新服务已启动,但健康探针因缺少 `X-HDD-CSRF` 请求头收到 HTTP 403;其 `die` 报错路径也未触发回滚.`cd7d69b` 修复了请求头和回滚.重新安装 `test-cd7d69b` 后,健康检查通过,服务在 `0.0.0.0:8765` 运行且已设为开机启用.安装器保留旧应用和服务单元备份;Web 密码与旧备份一致,`/var/lib/hdd-health` 和 `/var/log/disk-health` 保持原状.

- 已完成:源码整理到 `src/checker/` 和 `src/web/`,生成的 Web 文件移到 `dist/web/`;保留根目录 CLI 兼容入口,更新安装器及测试路径,规范语言目录和文档导航.源码安装沿用现有 Debian 服务目录.普通设置页提供八种主题色和明暗模式,分别保存选择;顶部导航使用真正的 Changelog 链接.
- 安全:独立的 Security Settings 页面由服务端实施五分钟管理员密码验证窗口.验证会轮换会话;仅凭 IP 进入的会话不能读取或修改名单及密码.窗口内修改密码只需新密码及确认,并使所有会话失效.IP 免密可开关,只接受精确的 RFC 1918 IPv4 或 ULA IPv6 地址,拒绝不合规的旧条目;连接对端而非客户端转发头决定来源,并检查原始 Host/Origin 和变更请求的同源头.
- 隐私和版本:快照及 SMART 响应遮蔽序列号;只有用户明确操作时,才通过经认证的请求取得完整序列号,隐藏或关闭视图时清除.项目名旁的版本链接打开 Changelog;未打标签的构建使用 `test-<sha>` 标识,`/api/build` 返回相同值.
- 评估行为:SSD/NVMe 完整评估运行 SMART 快检,短测,长测和全盘只读扫描,不采样速度.完成且无异常的批次得 100 分;单纯慢读不扣分.批量选择依所选磁盘类型提供可用检查.容量和 SSD 主机写入量可切换十进制/二进制单位;休眠 HDD 可单独唤醒.模拟测试通过,此次未启动真实磁盘的完整评估.
- 检查:Vue 类型检查及生产构建,全部 Shell 和 Python Web 测试,八种主题色两种模式的检查,多语言,文档格式(0 个错误,8 个警告),本地链接及项目结构检查均通过.Shell 语法,Python 编译及 `git diff --check` 通过.本地 Chromium 在 390 px 无横向溢出,可显示 Security Settings 和深色设置;直接打开 Changelog 时先显示 v3.0.0.隔离浏览器环境缺少检查器,磁盘状态请求按预期返回 503.源码包构建以 `test-archive-<package version>` 标识,不显示为正式版本.
- NAS 验证:安装后的 `/api/build` 与 `test-cd7d69b` 一致.密码登录,未认证的安全设置拒绝,管理员验证,会话轮换,受保护名单读取及 13 块磁盘快照的序列号遮蔽均通过.局域网安全页面和 favicon 返回 HTTP 200;未认证的普通及受保护 API 请求返回 401.已登录的 Chromium 打开安全页面,显示保存的 IP 控件和密码修改表单;390 px 下页面宽度等于视口宽度.浏览器会话及本地临时密码文件已清理.未进行磁盘扫描,密码修改或重启;安装的测试构建不是正式版本.
- 发布时状态:实机重启后的服务恢复和真实 HDD 的受控完整评估仍未验证.根目录兼容入口及搬迁前基线记录在限制章节.发布时 NAS 运行 `test-cd7d69b`;该发布任务没有部署正式构建.
- 发布:`main` 和 `feat/standards-alignment` 已推送至 `3cf9da0`.附注标签 `v4.0.0` 指向该提交;正式 GitHub Release 包含 6,697,392 字节的预构建 Web 归档和 `SHA256SUMS`;归档的 SHA-256 为 `491a0c61a99525f9a293b1b49c2de500e47c7b60e20bad5c4e955ecc048121d4`.已导出 `../snapshots/v4.0.0` 源码快照,并在 `My Projects` 下的项目 Notion 子页面验证完整 Changelog.
- 发布检查:全部 Shell 和 Python 测试,Vue 类型检查,生产构建,文档与链接检查,多语言及项目结构检查均通过.从精确的 `v4.0.0` 标签构建的产物提供 `/api/build`,`version.json`,主页及深层路由和 favicon,元数据均匹配 `v4.0.0`.文档检查报告 0 个错误和 8 个现有英文警告.此次发布未运行真实磁盘扫描,未修改密码,也未重启.
- 翻译恢复:依据记录在案的恢复规则,七种语言的核心文档译文已与当前英文同步,包括交接和提交历史.结构与受保护 token 检查通过;英文发布文档和译文一同提交.
- Web 设计规范化:登录页页眉及卡片现在采用统一尺寸.登录卡片底部提供构建版本的 Changelog 链接和登录前可用的语言选择器.登录密码,管理员验证密码,新密码及确认密码字段默认隐藏输入内容,各有独立的带标签显示/隐藏控件,触控区域为 44 px.控件保留输入值且不移动焦点;语言和密码控件标签覆盖全部八种 UI 语言.此次变更未部署到 NAS.
- Web 检查:在单独的本地构建目录中通过 Vue 类型检查和生产构建.本地 Chromium 中,登录页在 1280 px 和 320 px 下均无页面级横向溢出;已检查中文及阿拉伯文登录布局,英文语言偏好的持久保存,登录失败提示,登录密码显示切换,以及新密码和确认密码的独立切换.隔离服务器未以 root 运行检查器,因此无法读取真实磁盘数据;该预期 API 错误不属于登录布局检查范围.文档和项目检查随本次交接提交记录.
- Changelog 导航后续修复:登录卡片的版本链接现在允许未认证访客打开随程序提供的 Changelog;该页面在品牌名旁显示所链接版本,并有带标签的 Changelog 导航入口.本地 Chromium 点击版本链接,显示 v4.0.0 条目,并返回登录页.未认证的 `/api/build`,`/api/access` 和 `/api/snapshot` 请求仍返回 401.此变更后 Vue 类型检查和生产构建通过.
- NAS UI 部署:在干净的本地检出中将当前 `main` 提交 `2e6201e` 构建为 `test-2e6201e`.Vue 类型检查和生产构建通过,传输的归档校验和一致.Debian 安装器升级了端口 8765 上现有的局域网服务,保留 Web 密码以及带时间戳的应用和服务单元备份.服务运行中且已设为开机启用;现有状态和日志目录保持原状.经认证的 `/api/build` 返回 `test-2e6201e`,`/api/snapshot` 列出 13 块磁盘;局域网磁盘页和 Changelog 页返回 HTTP 200,未认证的 `/api/build` 返回 401.局域网 Chromium 显示更新后的登录页及其版本链接和语言选择器,随后通过版本链接打开 v4.0.0 Changelog 条目.未运行磁盘扫描,未修改密码,也未重启.
- 版本与 Changelog 后续:将 v4.0.0 之后的 Web 变更写入英文 Changelog 和全部七种译文,并将旧 Handoff 和 Commit History 同步到提交 `3c3451f` 对应的英文源文.干净构建嵌入 `test-3c3451f`;Vue 类型检查和生产构建通过.多语言,项目结构,文档格式,本地链接和 diff 检查均通过;格式检查报告英文导航中语言名称的一个既有警告.传输包的校验和匹配.NAS 安装器保留 Web 密码,应用和服务单元备份,以及已有的状态和日志目录.服务在 8765 端口处于活动且已启用状态;认证后的 `/api/build` 返回 `test-3c3451f`,`/api/snapshot` 列出 13 块磁盘,局域网磁盘页及 Changelog 页返回 HTTP 200,未认证的 `/api/build` 返回 401.局域网 Chromium 在登录卡片及 Changelog 页面看到相同版本,新增简体中文条目位于 v4.0.0 之前.未执行磁盘扫描,密码修改或重启.
- `main` 上的 Web 设计标准化:认证后页眉按规定顺序显示带链接的项目名/版本以及首页,Changelog,设置和退出登录;各子页面均有返回控件.设置和受保护的安全设置采用响应式分区导航,各路由使用不同且匹配的 favicon,登录卡片始终提供 IP 访问操作并在服务端拒绝时显示错误.外观设置包含 Beta 页面过渡开关,选择会持久保存,移动设备默认关闭;浏览器历史,视口尺寸变化及减少动态效果分别处理.所有八种 Web 界面语言在本地化候选版 Changelog 顶部显示准确的测试构建标识,其后才是正式版本;英文 Changelog 不再有未标版本的发布后章节.既有 `v4.0.0` 标签和 Release 均未更改.
- 本次 Web 变更的本地验证:隔离构建树中的 Vue 类型检查和生产构建通过.Chromium 检查了桌面和 390 px 下的设置及安全设置布局,各语言位于 `v4.0.0` 之前的候选条目,favicon 切换,浏览器后退/前进,关闭页面动画时不调用 View Transitions,启用动画的路径,以及从 320 至 1280 px 反复调整尺寸时没有横向溢出或残留变换.多语言和项目结构检查通过;文档及本地链接检查无错误,所查三份英文文档有五个格式警告.未在真实移动浏览器中检查视觉过渡.
- 部署 `test-c7b6252` 到 NAS:提交 `c7b6252` 的干净检出通过 Vue 类型检查和生产构建;`version.json` 嵌入相同测试标识.传输包的 SHA-256 为 `afe858f9ba2a9e8ea19964bc98382f4068085fd5b042fb76f971fc3e54bc6ceb`,校验匹配.安装器升级 `/root/apps/hdd-health-check` 中 8765 端口的局域网服务,Web 密码未变,保留应用备份 `/root/apps/hdd-health-check.backup-20260929-012509-2525461` 及匹配的服务单元备份.已有 `/var/lib/hdd-health` 和 `/var/log/disk-health` 未被安装包修改.服务在 systemd 下处于活动且已启用状态,监听 `0.0.0.0:8765`;未重启主机.认证后的 `/api/build` 返回 `test-c7b6252`;退出后 `/api/build` 返回 401.磁盘,设置,安全设置和 Changelog 局域网页面及图标资源返回 HTTP 200;未认证的 `/api/build` 返回 401.实时 Chromium 显示登录卡片版本,始终可见的 IP 操作及地址被拒说明,随后打开准确的测试版 Changelog 条目及 `v4.0.0`;390 px 下无横向溢出.未执行磁盘扫描,密码修改或重启;未发现项目临时规则.
- `main` 上的 Web UI 参考设计 v1.2.3 迁移:将登录,仪表盘,关注,任务,定时,设置,安全设置,Changelog 及磁盘详情映射到带标签的 AI-Configs 参考设计.导入参考样式表,调整共用页眉,内容宽度,仪表盘卡片,设置导航和卡片,表单,开关和隐私值状态,本地化发布卡片,主题过渡及路由/尺寸变化动画.在 `doc/DESIGN.md` 记录页面映射以及业务,权限和浏览器差异.既有 API 调用及服务端权限未改.八种 Web 语言目录均增加相应标签和说明.未发现项目临时规则.
- UI 迁移检查:隔离的干净构建树通过 Vue 类型检查和生产构建.主题检查覆盖八套配色的两种模式;多语言,项目结构及本地链接检查通过.所查英文文件的文档格式检查无错误,有四个既有警告.Chromium 在 1280 × 800 下对比参考和目标的登录,仪表盘,关注,任务,定时,设置,安全设置和 Changelog 页面;设置页使用相同的 192 px 侧栏与 856 px 卡片,Changelog 使用全宽卡片.深色/青绿色切换得到保存,390 px 设置页没有横向溢出.模拟的单磁盘 API 验证了详情抽屉,标签切换,明确显示序列号及关闭后清除.静态预览和模拟数据不能证明 NAS 实际行为,真实磁盘扫描,密码修改或重启恢复.
- 测试主机部署后续:首次安装 `test-486be47` 暴露 systemd 单元遗漏:重启服务后 `/var/lib/hdd-health` 权限从 700 变为 755.已立即恢复权限;提交 `ce70010` 增加 `StateDirectoryMode=0700`.对 `ce70010` 的干净构建通过 Vue 类型检查和生产构建,嵌入 `test-ce70010`,并从 SHA-256 匹配的安装包部署(`e809016f4bd5e01bb5ae3eefcc6c8e1893addf5daec4d796a283c0802b184aa4`).安装器保留旧应用 `/root/apps/hdd-health-check.backup-20260929-111224-3324946` 和匹配的服务单元备份.服务在 `0.0.0.0:8765` 活动且已启用;安装的单元明确保证重启后状态目录权限为 700.Web 密码文件权限仍为 600,校验和未变;现有状态及日志路径保留.局域网磁盘,关注,任务,定时,设置,安全设置,Changelog 及图标资源均返回 HTTP 200.未认证的受保护 API 返回 401;密码登录后 `/api/build` 返回 `test-ce70010`,`/api/snapshot` 给出 13 块序列号遮蔽的磁盘,任务空闲;退出后恢复 401.实时 Chromium 在登录卡片和 Changelog 顶部看到 `test-ce70010`,其后为 `v4.0.0`.未执行磁盘扫描,密码修改或主机重启.这是测试构建,不是新的正式版.
- 磁盘详情改进:预留稳定的滚动条空间,减少打开卡片时最后的轻微位移.管理员验证卡片现占满安全设置页内容宽度,表单仍易于阅读.磁盘卡片链接到 `/disks/:id` 或 `/attention/:id` 的完整详情页,支持浏览器历史,直接重新加载和窄屏布局.序列号按钮直接切换遮蔽/完整值,不另加显示/隐藏文字;复制操作只在认证显示后出现,并支持局域网 HTTP 剪贴板回退方案.SMART 属性有本地化的悬停/聚焦说明和厂商数值差异提示.NVMe Data Units 或 ATA Device Statistics 提供已知单位时,SSD/NVMe 信息同时显示主机读取量和写入量.八种 Web 语言的候选版 Changelog 描述新的详情和 SMART 行为;正式 `v4.0.0` 记录保留为历史.
- 本次改进的本地检查:隔离的干净 Vue 类型检查及生产构建通过.`tests/web-smart.py` 和 Python 编译通过;多语言与项目结构检查无错误.针对性文档和本地链接检查无错误,有五个既有文档警告.模拟 Chromium 中磁盘详情有独立 URL,可重新加载和使用浏览器后退/前进,可遮蔽/显示/复制/重新隐藏序列号,390 px 下无横向溢出.HTTP 剪贴板回退方案已实际运行.在 1280 px 视口中,安全验证卡片位于 1,120 px 主框架内,测得宽 1,072 px;390 px 下无溢出.模拟磁盘不能证明硬件行为.未发现项目临时规则.
- `test-aa183e4` 测试主机首次检查:从干净提交 `aa183e4` 构建;传输包 SHA-256 `fe2ebb97a1524a93f83942d1e157c256185575bbfd6fb34101ba65f714d50605` 匹配.安装器保留 `/root/apps/hdd-health-check.backup-20260929-114536-3447848` 和匹配的服务单元备份.服务在 `0.0.0.0:8765` 活动且已启用;`/var/lib/hdd-health` 权限仍为 700,未变的 Web 密码文件权限为 600.局域网页面和直接磁盘详情路由返回 200;登录前受保护 API 返回 401.认证后的 `/api/build` 返回 `test-aa183e4`;快照列出 13 块已遮蔽序列号的磁盘,一块真实 NVMe 的 SMART 详情同时给出读取及写入总量.退出后恢复 401.实时 Chromium 显示一致的登录及 Changelog 版本,完整磁盘详情,本地化 SMART 指导,并在局域网 HTTP 下成功显示/复制/隐藏序列号.390 px 详情无横向溢出.四个 NVMe 表格键仍使用通用帮助;后续将其改为专门说明.未执行扫描,密码修改或重启.
- 修正后的测试主机部署:对干净提交 `f0b58be` 运行 Vue 类型检查及生产构建;`version.json` 嵌入 `test-f0b58be`.6,532,350 字节的安装包在安装前匹配 SHA-256 `96a029b49dc9a09bb2b1edad414c682dffb8ef357c2e9d6ee55c9721af7c78e5`.安装器保留 `/root/apps/hdd-health-check.backup-20260929-115210-3485325` 及匹配的服务单元备份.服务在 `0.0.0.0:8765` 活动且已启用;状态目录权限为 700,未变的密码文件权限为 600.局域网磁盘,直接详情,安全设置和 Changelog 路由返回 200;认证会话前后,未认证的受保护 API 均返回 401.会话中 `/api/build` 返回 `test-f0b58be`,快照列出 13 块遮蔽序列号的磁盘,真实 NVMe SMART 响应同时给出读写总量.实时 Chromium 显示匹配的登录及 Changelog 标记,两个新的候选记录,完整详情页,先前四个通用 NVMe 计数器的具体帮助,并在 390 px 下无横向溢出.预留滚动条空间使卡片路由过渡中的文档宽度稳定;稳定后路由遮罩和动画类均已清除.首次安装构建在局域网 HTTP 下的序列号显示/复制/隐藏流程通过;本次修正仅改说明标签.已关闭浏览器会话.未执行扫描,密码修改或重启.
- 磁盘详情交互后续:复制反馈暂时把按钮图标改为勾号,同时保留成功提示.提示放大,增加进场/退场动画.页面返回按钮和浏览器后退均使用反向页面滑动,避免把磁盘型号拉伸进窄卡片.SMART/Checks 主题色指示线在标签间滑动;SMART 表格的行,数值和可聚焦浮动帮助图标更清晰.管理员验证和密码修改表单内容居中,填满可读区域.`doc/DESIGN.md` 记录与参考设计不同的详情返回效果.API 和权限行为未变.
- 本次后续的本地检查:隔离构建树中的 Vue 类型检查及生产构建通过;`tests/web-smart.py`,多语言及项目结构检查通过.针对性文档和本地链接检查无错误,有五个既有文档警告.模拟 Chromium 验证了临时复制勾号及提示,SMART 悬停帮助,标签状态,两种返回路径和路由动画状态清理.390 px 下稳定后的磁盘详情和安全设置页面无横向溢出.模拟磁盘不能证明实际硬件行为;未发现项目临时规则.
- 测试主机部署 `test-b6a0ba7`:从干净提交 `b6a0ba7` 构建;Vue 类型检查及生产构建通过,`version.json` 嵌入准确标识.传输包 SHA-256 `81aedb34c94bd607e76025c28927c0f221511f79cf418c0e1800108d50956afe` 匹配.安装器保留 `/root/apps/hdd-health-check.backup-20260929-120631-3533408` 和匹配的服务单元备份.Web 服务在 `0.0.0.0:8765` 活动且已启用;`/var/lib/hdd-health` 权限仍为 700,现有 Web 密码文件权限为 600,校验和与备份相同.局域网磁盘及详情路由返回 200,未认证的构建 API 返回 401.认证后的构建 API 返回 `test-b6a0ba7`,快照列出 13 块遮蔽序列号的磁盘,真实 NVMe SMART 响应给出主机读写总量.实时 Chromium 确认临时复制勾号及提示,SMART 说明,标签指示线,返回时反向滑动,且没有残留遮罩或动画类.可见的 Changelog 和版本链接显示 `test-b6a0ba7`;390 px 下详情,安全设置和 Changelog 页面均无横向溢出.未执行磁盘扫描,密码修改或重启.
- 磁盘返回及提示修正:逐帧截图发现反向滑动将详情与仪表盘明显割裂,从详情点击首页会短暂把仪表盘缩成不可读的微型页面.现在从详情到列表或仪表盘的导航依次淡入淡出全尺寸页面,涵盖返回按钮,首页/品牌/面包屑链接及浏览器历史;其他路由维持原有动画.提示现于 4.2 秒后自动关闭,仍可手动关闭.Web UI 规范针对参考设计未涵盖的密集数据详情路由加入范围明确的例外,并记入 `doc/DESIGN.md`.本地 Vue 类型检查及生产构建通过.模拟 Chromium 检查了返回过程中的帧,浏览器后退/前进,首页/历史路径,关闭动画路径,窄屏返回及定时提示消失;临时路由类和遮罩均已清除.文档,本地链接,多语言及项目结构检查无错误.未发现项目临时规则.
- 测试主机部署 `test-08b6370`:从干净提交 `08b6370` 构建;生产 Web 资源及 `version.json` 嵌入准确测试标识.传输包匹配 SHA-256 `36b04555d54e48dd05ad8a0ef7e5e1cd96e6ea8c99b56580f959a810c5bcb458`.安装器保留 `/root/apps/hdd-health-check.backup-20260929-124823-3573886` 和匹配的服务单元备份.服务在 `0.0.0.0:8765` 活动且已启用;`/var/lib/hdd-health` 权限仍为 700,密码文件权限为 600,校验和与备份相同.局域网磁盘及直接详情路由返回 200;匿名 `/api/build` 返回 401.认证后的 `/api/build` 返回 `test-08b6370`,快照列出 13 块磁盘.实时 Chromium 显示相同的页面版本,检查了返回及滚动后 SMART 页面到首页的中间帧,没有页面割裂或缩成微型页面,也没有残留路由遮罩或类.真实序列号复制提示约 4.2 秒后消失.稳定后的 390 px 磁盘列表和 Changelog 无横向溢出.未执行磁盘扫描,密码修改或重启.
- `main` 上的动画调整:Toast 每次显示后 3 秒关闭,相同消息重复出现时重启计时器和入场效果,手动关闭时清除计时器.SMART/Checks 底线在选择,翻译及重新排布后按实测标签位置和宽度定位;标签文字颜色与指示线同步过渡.调整视口尺寸会清除被中断路由过渡的副本及临时样式.页面路由动画,主题动画和局部反馈分别控制;数据密集的磁盘详情返回淡入淡出效果仍是已记录的项目例外.
- 动画检查:隔离环境中的 `npm ci`,Vue 类型检查及生产构建通过;挂载源码目录内直接运行 `npm ci` 在删除已有 `node_modules/lightningcss-linux-x64-gnu` 目录时失败.模拟 Chromium 验证关闭路由动画时 View Transition 调用数为零,中英文及阿拉伯语 RTL 下桌面和 390 px 的标签指示线位置与宽度匹配选中按钮,减少动态效果时指示线和文字过渡消失,重复复制序列号反馈会重启 3 秒生命周期.手动关闭 Toast 及窄屏布局已检查.启用的详情过渡被视口尺寸变化中断后,没有残留路由副本,路由类或冻结的变换.这些浏览器检查使用模拟磁盘/API 响应,不能证明 NAS 或真实移动设备行为.此变更没有部署;未发现项目临时规则.
- 测试候选版准备:八种 Web 语言目录中的应用内候选版条目现描述尺寸变化中断后的清理,已翻译详情标签指示线动画及重复触发 Toast 的 3 秒计时器.候选版用于部署当前动画变更,保留 `test-<commit>` 标识;不是新的正式版.未发现项目临时规则.
- NAS 部署 `test-771001c`:从干净提交 `771001c` 构建;Vue 类型检查和生产构建通过,`version.json` 嵌入相同测试标识.一比一传输包匹配 SHA-256 `1b191dd0aa39a01c41936bca5eba763e5e5d0ebbb5689673b5c5f0d2e3b497e9`.安装前,检查器,Python 服务及 systemd 单元哈希与已安装文件一致,因此此次部署仅改变 Web 资源及打包的更新记录,没有检查器或状态格式迁移.安装器保留 `/root/apps/hdd-health-check.backup-20260929-132147-3619345` 和 `/etc/systemd/system/hdd-health-web.service.backup-20260929-132147-3619345`;新旧 Web 密码哈希一致,密码文件权限仍为 600.服务在 `0.0.0.0:8765` 活动且已启用;`/var/lib/hdd-health` 权限仍为 700,`/var/log/disk-health` 仍可用.局域网 GET `/disks/sdb` 和 favicon 返回 200;匿名 `/api/build` 返回 401.密码认证后的 `/api/build` 返回 `test-771001c`,`/api/snapshot` 列出包括 `sdb` 的 13 块遮蔽序列号磁盘,`/api/status` 无活动任务,退出后 `/api/build` 恢复 401.`sdb` 的 SMART 端点报告磁盘待机,因此没有唤醒或扫描.实时 Chromium 打开直接 `/disks/sdb` 路由,显示同一版本,遮蔽的序列号和休眠状态;390 px 下 SMART/Checks 底线与选中按钮匹配,页面无横向溢出.版本链接打开对应本地化候选版 Changelog;路由遮罩已清除.浏览器和临时部署文件均已删除.真实移动浏览器渲染及重启恢复仍未验证;未发现项目临时规则.
- 暂缓的视觉问题:用户提供已部署磁盘详情 UI 的截图,其中当前 SMART 标签底线长于标签的悬停/选中区域.先前 390 px 浏览器测量未覆盖截图中的视觉状态.Bugs 章节记录预期对齐方式和需要重查的配置.报告问题时没有修改 UI 代码或 NAS 部署;未发现项目临时规则.
- 标签底线后续:以直接测得的宽度取代一像素线条的变换缩放,并将选中按钮测量精度提高到小数.本地 Chromium 在 390 px,100% 和 200% CSS 缩放,简体中文,英文及阿拉伯语下确认两种标签按钮均与底线匹配.隔离构建树中的 Vue 类型检查和生产构建通过;多语言,项目结构,针对性文档和本地链接检查通过,有四个既有文档警告.用户报告的详情返回动画问题仍未解决,本次未改动;未发现项目临时规则.
- NAS 部署 `test-bd438c4`:从干净提交 `bd438c4` 构建,`version.json` 中使用相同标识.传输包匹配 SHA-256 `65d10b167552c232be481edd2f60e3359dd5b5d6a03121960229923ec0e211da`;检查器,Python 服务及服务单元的哈希与此前安装一致.安装器将旧应用保留在 `/root/apps/hdd-health-check.backup-20260929-134240-3654021`,并保留匹配的服务单元备份.Web 密码校验和未变,权限为 600;`/var/lib/hdd-health` 权限仍为 700,`/var/log/disk-health` 可用.服务在 `0.0.0.0:8765` 活动且已启用.认证后的 `/api/build` 返回 `test-bd438c4`,`/api/snapshot` 列出 13 块磁盘,`/api/status` 没有运行中的任务,退出后 `/api/build` 返回 401.局域网 GET `/disks/sda`,favicon 及 `version.json` 成功;服务端本地 `/changelog` 请求返回 200.实时 Chromium 在 `/disks/sda` 显示新版本,桌面及 390 px,125% CSS 缩放下两条标签底线均与选中按钮等宽.临时 NAS 部署文件和浏览器会话已删除.未执行磁盘扫描,密码修改或重启.
- 剩余工作:用户报告的磁盘详情返回动画问题暂缓.真实移动浏览器中的动画,真实主机重启后的恢复以及真实 HDD 上受控的完整评估仍未验证.根目录兼容入口及其迁移前基线已记入 Limitations.
- 发布准备:用户批准为当前已部署变更发布正式版本.`v4.1.0` 涵盖 `v4.0.0` 之后的提交:登录及 Changelog 访问,与参考设计对齐的 Web 页面,磁盘详情和 SMART 指导,服务状态权限,标签及反馈修复.已知的返回动画问题按要求暂缓.此前的 `v4.0.0` 标签和 Release 保持不变;未发现项目临时规则.
- 正式发布:发布时,`main` 和带注释的 `v4.1.0` 标签均指向 `09e6fa5`.GitHub Release 为公开且已发布的正式版,不是预发布版;其预构建 Web 安装包大小为 6,952,186 字节,SHA-256 为 `cf4e94597552c84f36140c1890eb62b379421599ae2a8e0f929ce24c65880a98`,并附有 `SHA256SUMS`.干净的标签构建嵌入 `v4.1.0`;Chromium 检查显示相同版本,正式 Changelog 位于 `v4.0.0` 之前,没有测试候选条目.全部 Shell 和 Python 测试,Vue 类型检查,生产构建,多语言,项目结构,针对性文档及本地链接检查均通过.文档检查器仍有五个既有警告.已导出 `../snapshots/v4.1.0` 源码快照,并将完整 Changelog 同步到 Notion 的 `My Projects` 下经核实的 `hdd-health-check` 子页面.
- 正式 NAS 部署:传输包通过 SHA-256 校验,安装器将运行中的 `test-bd438c4` 服务升级为 `v4.1.0`.已保留 `/root/apps/hdd-health-check.backup-20260929-142539-3689967` 和匹配的服务单元备份.Web 密码校验和未变,文件权限仍为 600;`/var/lib/hdd-health` 权限仍为 700,`/var/log/disk-health` 仍可用.服务在 `0.0.0.0:8765` 活动且已启用.密码认证后的 `/api/build` 返回 `v4.1.0`,`/api/snapshot` 列出 13 块磁盘,退出后 `/api/build` 恢复 401.局域网 GET 磁盘详情,Changelog,版本元数据和 SVG favicon 均返回 200.实时 Chromium 打开 `/disks/sda`,显示 `v4.1.0`,并测得 SMART 和 Checks 底线与选中按钮等宽;在 390 px 和 125% CSS 缩放下,重新排布后的宽度误差小于 0.001 px,偏移误差小于 0.15 px.实时 Changelog 显示正式版本及暂缓处理的动画问题.临时浏览器,密码及部署文件已删除.未执行磁盘扫描,密码修改或重启.
- 剩余工作:用户报告的磁盘详情返回动画问题仍暂缓处理.真实 HDD 上受控的完整评估,真实移动浏览器动画及主机重启后的服务恢复仍未验证.
- 下一步:用户提出要求后修复暂缓处理的返回动画,再在实际目标浏览器中验证并更新 Handoff.另外,在可中断主机运行的时间安排受控 HDD 评估和重启恢复检查.

## 历史源码基线

### v2.3.0 — 2026-09-24 (untagged source baseline)

#### 变更

本版包含此前未打标签的 v2.2 整合:持久化每盘结果,SMART 计数器历史,交互及批处理模块,可续扫的只读盘面扫描,接口复查,可选的临时 systemd 任务及更安全的仅数据状态解析.不保证兼容 v1 CLI 或状态:`-w/--wait` 会被忽略而不会等待;升级前备份主机状态,恢复旧脚本时须恢复匹配的状态.下述新版评分仅有合成测试,未经真实 HDD 验证.

#### 修复

- 正确识别首次新完成的 SMART 自检记录;旧记录,未完成记录或类型不符的记录不算新完成的自检.
- 完整评估将快速,短程,长程 SMART,速度和完整盘面扫描标为同一批次,末尾复查快速 SMART/ATA/CRC.仅同批次完整且有效的结果才有数字综合分数.复用,中断,过期,无批次标记的旧状态及后续接口复查会使旧记录标为历史/待复查,总体为部分/未知;报告不更新快速体检比较基线.接口复查单独记录已解决或未解决,不重新归因旧错误或使旧批次变成当前.无先前快速体检计数的 ATA 累计数原因未知,未解决的 5 分扣分在后续体检及全检中保留;旧记录缺少风险字段时也按未解决处理.新增扣 20 分;计数稳定不是新错,也不是修复证据;仅有接口复查不能把旧 ATA 错误归因于接口维修.零星慢读提示性能复测而非坏扇区诊断;盘面读错仍扣 40 分.这是启发式权重而非故障概率.

### v2.2.0 — 未打标签的整合历史(未发布)

#### 新增

- 持久化的每盘结果,SMART 计数器历史,修复记录和报告;交互式菜单,抽样读取分析,带针对性坏块复查的可续扫盘面延迟扫描,全盘只读 `badblocks`,接口读取压力检查,以及可选的临时 systemd 后台执行.

#### 变更

- 默认的批处理快速检查,可复用的限时有效结果和 `--rescan`;`-r/--run` 选择模块,`--status`/`--stop` 管理运行中实例.`-t short|long`,`-s` 和 `-b` 映射到模块;`-w/--wait` 会被忽略,不会等待.新行为并不兼容 v1 CLI.
- 主机状态和日志分别写入;v2.2.0 不保证与 v1 CLI 或状态兼容.升级前备份主机状态;恢复旧脚本须同时恢复匹配的状态备份.状态记录只接受白名单中的数据字段;不兼容的记录可能被拒绝.

#### 修复

- 拒绝可执行或格式错误的状态记录及符号链接状态输入;限制后台计划只能使用经验证的字段和私有状态目录,并验证设备名称及日志/状态路径,以减少不安全的文件处理.
- 无效或不完整的盘面检查点会触发重新扫描,而不会用零分母计算进度;支持在自定义 `TMPDIR` 下识别运行中实例并安全停止.

用户报告已在实机测试 v2.2.0,但未提供设备,环境或测试范围;root 执行,软件包安装及 systemd 行为尚未得到独立确认.

## 变更日志

### v4.1.0 — 2026-09-29

本次发布更新 Web 界面和磁盘详情.此前的测试构建已在枚举出 13 块磁盘的 Debian NAS 上检查;正式构建将在发布前另行检查.

#### 新增

- 磁盘卡片可打开完整详情页,包含面包屑,返回导航,单盘检查,SMART 属性及说明.序列号在认证后明确显示前保持遮蔽;只有显示后才可复制.设备提供单位明确的计数器时,SSD/NVMe 详情显示主机读取量和写入量.
- Web 界面的登录页,仪表盘,功能页,设置,安全设置和更新日志遵循共用视觉参考.新增响应式布局,本地化控件,图标以及可选的页面和调整大小动画.

#### 变更

- 登录前即可从登录页打开 Changelog,其中显示对应的构建版本.磁盘详情控件使用按实测尺寸定位的标签指示线;重复触发复制反馈时会重启其消失计时器.
- NAS 服务单元在重启后仍将 `/var/lib/hdd-health` 保持为 700 权限模式.更新时安装器继续保留旧应用,服务单元和 Web 密码.

#### 修复

- 修正窄屏及已测试缩放比例下当前 SMART 和 Checks 标签底线的宽度与位置,包括 RTL 布局.改进磁盘详情反馈,SMART 计数器说明及路由动画中断后的清理.

#### 已知问题与验证

- 用户报告从磁盘详情返回时的动画问题,现按要求暂缓处理.真实 HDD 的完整评估,真实移动浏览器中的动画以及主机重启后的服务恢复仍未验证.健康评分仍是启发式指标,并非经过校准的故障概率.
- 测试构建通过了 Vue 类型检查,生产构建,项目与翻译检查以及本地 Chromium 布局检查.NAS 测试部署通过了认证后的版本和磁盘列表 API 检查,以及两个标签底线的浏览器检查;未执行磁盘扫描,密码修改或重启.

### v4.0.0 — 2026-09-28

本次大版本更新本地 Web 控制器,安全模型和源码布局.已在列出 13 块磁盘的 Debian NAS 上检查经认证的测试构建.真实 HDD 的完整评估及主机重启后的服务恢复仍未验证.

#### 新增

- SSD/NVMe 完整评估现在执行 SMART 快检,短测,长测和全盘只读扫描,无需 HDD 速度采样.按照既有启发式规则,完整且无异常的批次得 100 分;单纯慢读不扣分,真实读取错误及 SMART 异常仍可扣分.混合磁盘的批量控件提供支持检查的并集,HDD 专用模块跳过不适用的 SSD.
- 任务历史分别记录已完成,停止和失败的 Web 运行,与各磁盘最新检查结果及 SMART 计数器趋势分开.磁盘详情可让符合条件的 SATA HDD 进入待机,或逐一唤醒休眠的 HDD.
- 设置提供八种主题色及明暗模式.项目名旁的版本链接指向 Changelog;运行时 `/api/build` 返回相同的内嵌构建标识.普通响应遮蔽磁盘序列号,仅在用户通过认证后明确请求显示时获取完整号码.

#### 变更

- Security Settings 使用独立路由和服务端强制执行的五分钟管理员密码验证窗口.验证轮换会话;窗口内修改密码只需新密码和确认,随后使所有会话失效.IP 免密有启用开关,只接受精确的 RFC 1918 IPv4 或 ULA IPv6 地址.免密 IP 会话不能读取或修改安全设置.变更请求需要同源头;客户端转发头不能确定连接对端地址.
- 源码移入 `src/checker/` 和 `src/web/`,前端产物位于 `dist/web/`;根目录 CLI 入口及 NAS 安装目录仍兼容.文档语言目录采用 BCP-47 名称.磁盘概览随视口宽度重排,仪表盘四种功能仍由独立页面承载.

#### 修复

- 全盘自检期间保持任务状态响应,分别显示 SMART 短测及长测结果,保留独立的历史任务记录.修正 NVMe 温度显示区间;仅温度异常或 SSD 速度变化不再扣健康分.检查干净但完整评估覆盖不足时,不再仅因此返回警告.
- Debian 安装器的认证健康探针现发送必需的请求头,并在文件替换开始后的明确安装错误中回滚.

#### 验证

- Shell 与 Python 测试,Vue 类型检查与生产构建,文档和结构检查,本地浏览器检查通过.NAS 测试部署通过认证 API 和 Security Settings 浏览器检查,包括序列号遮蔽和 390 px 无横向溢出的布局.此次发布准备未运行磁盘扫描,未修改密码,也未重启;健康分不是校准过的故障概率.

### v3.0.0 — 2026-09-27

本次大版本在原有磁盘检查器中加入带认证的常驻 Web UI 和 Debian 安装器.Web 服务已在识别 13 块磁盘的 Debian NAS 上检查;真实 HDD 的完整评估和重启恢复仍未验证.标签包含源码,没有发布 GitHub Release 或预构建 UI 附件.

#### NAS 后续修复

- 磁盘卡片随浏览器可用宽度及缩放重新排列,保持按钮可见且无横向溢出;宽屏最多四列.
- 将 SSD/NVMe 的速度采样下降和平均速度变化视为性能信息,实际读取故障仍扣分,旧结果也按新规则解释.磁盘概览改为响应式列;仪表盘磁盘卡片可跳转到列表.
- 全盘 SMART 自检时,网页状态接口只读运行记录及最近日志,不再逐盘轮询,以保持任务更新响应.磁盘列表另行刷新,一次后台读取期间沿用上次成功快照.
- NVMe 温度显示颜色不参与健康评分.可用时采用控制器警告/临界阈值,否则使用 70/80 °C 显示区间;仅温度触发的 NVMe 警告不扣分.历史评分在重新检查前保持不变.
- 正确解码空白保存字段,并避免仅因干净检查的评估覆盖不完整而返回警告退出码.
- 将仪表盘四类内容分成独立顶层页面,保留磁盘主页的一键评估.

#### 新增

- Python Web 服务,Vue 界面,定时快速检查,任务控制,SMART 历史视图及部署单元.安装器配置带认证的局域网访问;手动运行仍只监听回环地址.
- Web 登录和退出,在设置页由已认证用户管理的精确 IPv4 免密名单,显示基本硬件信息的磁盘卡片,以及独立的 SMART 信息和检查标签.更新记录以 Markdown 渲染 Changelog 章节.
- 可用的 SATA 版本及协商速度,或 NVMe PCIe 代际,通道宽度和速率;可切换的通电时长显示;可按 SATA,HDD,SSD,NVMe 或全部磁盘选择八个既有模块之一进行批次检查.列表标出总线和介质类型并显示缓存温度;仅在设备报告时显示外形规格.只有完整评估可产生当前综合评分.SSD/NVMe 分数仍面向 HDD,未经独立校准.
- Debian 安装器检查先决条件,通过 apt 安装缺少的软件包,部署预构建 UI 和服务,升级时保留回滚副本.
- `--json` 快照复用 Bash 综合评分函数.`--no-install` 阻止 Web 启动的任务自动安装依赖.Web 启动现在持久保存已接受,运行中和终态任务;关注卡片筛选磁盘,检查详情显示已记录扣分,旧记录缺少原因时明确提示.

#### 验证

- UI 构建和类型检查,Shell 状态/评分测试及本地 HTTP 认证测试通过.带认证的局域网服务已在列出 13 块磁盘的 Debian NAS 上安装并检查.真实 HDD 完整评估及重启恢复仍未验证.

### v1.0.0 — 2026-08-08

#### 新增

- 最初的 12 维 HDD 健康检查:设备/接口数据,SMART 功能及整体判定,ATA 属性或 SAS 缺陷/错误计数器,错误及自检日志,短程/长程自检启动,寿命/负载,内核 I/O 错误,挂载与只读状态检测,以及可选的只读 `hdparm` 基准测试和 `badblocks` 扫描.
- 启发式 0–100 分与四级评级,进程退出码 0/1/2/3,SMART 透传自动检测,交互式和批处理磁盘选择,以及提供安装缺少的 `smartmontools` 的 `apt` 选项.
- 完整的 v1.0.0 设计及用法文档保留在 `v1.0.0` Git 标签中(例如 `git show v1.0.0:DESIGN.md` 和 `git show v1.0.0:README.zh.md`);旧版命令不适用于当前版本.

## 提交历史

主分支完整历史: `git log main --stat`.`HEAD` 条目标识本次交接提交.

- 2026-09-29 | intended | `docs(handoff): clarify v4.1.0 release ref status` | this commit
- 2026-09-29 | `59313bb` | `docs(handoff): record v4.1.0 publication and deployment` | `git show 59313bb`
- 2026-09-29 | `09e6fa5` | `chore(release): prepare v4.1.0` | `git show 09e6fa5`
- 2026-09-29 | `1fd8ad3` | `docs(handoff): record underline fix deployment` | `git show 1fd8ad3`
- 2026-09-29 | `bd438c4` | `fix(web): match detail underline to selected tab` | `git show bd438c4`
- 2026-09-29 | `d44f624` | `docs(handoff): record deferred tab underline issue` | `git show d44f624`
- 2026-09-29 | `029e634` | `docs(handoff): record motion test deployment` | `git show 029e634`
- 2026-09-29 | `771001c` | `docs(web): describe motion test candidate` | `git show 771001c`
- 2026-09-29 | `fa77086` | `fix(web): align local motion with current standard` | `git show fa77086`
- 2026-09-29 | `a21783b` | `docs(handoff): record disk return deployment` | `git show a21783b`
- 2026-09-29 | `08b6370` | `fix(web): correct disk return and toast timing` | `git show 08b6370`
- 2026-09-29 | `8633851` | `docs(handoff): record disk detail UI deployment` | `git show 8633851`
- 2026-09-29 | `b6a0ba7` | `fix(web): refine disk detail feedback and motion` | `git show b6a0ba7`
- 2026-09-29 | `c289147` | `docs(handoff): record final disk UI test deployment` | `git show c289147`
- 2026-09-29 | `f0b58be` | `fix(web): explain NVMe SMART counters` | `git show f0b58be`
- 2026-09-29 | `aa183e4` | `feat(web): expand disk details and SMART guidance` | `git show aa183e4`
- 2026-09-29 | `dd4cd84` | `docs(handoff): record corrected test deployment` | `git show dd4cd84`
- 2026-09-29 | `ce70010` | `fix(deploy): keep HDD state directory private` | `git show ce70010`
- 2026-09-29 | `486be47` | `feat(web): migrate UI to reference v1.2.3` | `git show 486be47`
- 2026-09-29 | `d52366b` | `docs(handoff): record NAS Web design deployment` | `git show d52366b`
- 2026-09-29 | `c7b6252` | `feat(web): align pages with current design standard` | `git show c7b6252`
- 2026-09-28 | `c0e7ae7` | `docs(handoff): record version and Changelog deployment` | `git show c0e7ae7`
- 2026-09-28 | `3c3451f` | `docs(changelog): record latest Web update` | `git show 3c3451f`
- 2026-09-28 | `0a91897` | `docs(handoff): record NAS UI deployment` | `git show 0a91897`
- 2026-09-28 | `2e6201e` | `fix(web): open changelog before login` | `git show 2e6201e`
- 2026-09-28 | `c38e6d6` | `fix(web): align login with updated design rules` | `git show c38e6d6`
- 2026-09-28 | `df35b42` | `docs(handoff): record v4.0.0 publication` | `git show df35b42`
- 2026-09-28 | `3cf9da0` | `chore(release): prepare v4.0.0` | `git show 3cf9da0`
- 2026-09-28 | `ebf6e39` | `docs(handoff): record NAS browser verification` | `git show ebf6e39`
- 2026-09-28 | `0b5f053` | `docs(handoff): record NAS installer and security verification` | `git show 0b5f053`
- 2026-09-28 | `cd7d69b` | `fix(deploy): verify authenticated service with CSRF header` | `git show cd7d69b`
- 2026-09-28 | `bf14ed5` | `feat(web): align project layout and security settings` | `git show bf14ed5`
- 2026-09-28 | `35f24e5` | `docs(handoff): record NAS Web update verification` | `git show 35f24e5`
- 2026-09-28 | `a6086ff` | `feat(web): unify history and add per-disk standby` | `git show a6086ff`
- 2026-09-28 | `f5f5dc7` | `docs(handoff): record SSD assessment deployment` | `git show f5f5dc7`
- 2026-09-28 | `c60d602` | `fix(web): defer option watcher until labels initialize` | `git show c60d602`
- 2026-09-28 | `261247f` | `fix(web): initialize assessment scope before options` | `git show 261247f`
- 2026-09-28 | `f882a8d` | `docs: record SSD full assessment behavior` | `git show f882a8d`
- 2026-09-28 | `bfed16f` | `feat: assess SSDs with full read-only scan` | `git show bfed16f`
- 2026-09-27 | `97f775f` | `docs(handoff): record v3.0.0 tag publication` | `git show 97f775f`
- 2026-09-27 | `434ac7d` | `chore(release): prepare v3.0.0 source tag` | `git show 434ac7d`
- 2026-09-27 | `65acbd0` | `docs(install): point source install to main` | `git show 65acbd0`
- 2026-09-27 | `b963e06` | `docs(handoff): confirm source publication` | `git show b963e06`
- 2026-09-27 | `88474d2` | `feat(web): publish LAN dashboard and docs` | `git show 88474d2`
- 2026-09-24 | `a46b392` | `feat(scoring): improve batch assessment for v2.3.0` | `git show a46b392`
- 2026-09-24 | `3126bcc` | `docs: clarify public source and reported real-machine testing` | `git show 3126bcc`
- 2026-09-24 | `7e69fdd` | `feat!: integrate unreleased v2.2.0 HDD health checks` | `git show 7e69fdd`
- 2026-08-13 | `7b18ca7` | `docs(status): record v1.0.0 release completion` | `git show 7b18ca7`
- 2026-08-13 | `4e01f52` | `chore(release): v1.0.0 (clean history)` | `git show 4e01f52`
