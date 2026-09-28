---
name: project-log-zh-cn
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: zh-CN
---

# hdd-health-check — 日志

本文记录已采纳的历史决策,已知限制和发布历史.当前大版本为 `v4.0.0`.用户报告较早的 `v2.2.0` 曾在实机运行,但未提供设备,环境或测试覆盖范围.修订后的评分已有模拟测试及 Debian NAS 上的 Web 验证,但尚未在真实 HDD 上完成受控的完整评估.

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

2026-09-28.分支 `main`;`v4.0.0` 已发布.未发现临时项目规则.

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
- 剩余事项:适时观察实机重启后的服务恢复.真实 HDD 的受控完整评估仍未验证.根目录兼容入口及搬迁前基线记录在限制章节.
- 下一步:检查 NAS 上已部署的登录页和 Changelog 外观;另行安排重启和受控 HDD 评估.已发布的 `v4.0.0` 标签和 Release 保持不变.

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

### 未发布的 Web 更新 — 2026-09-28

#### 变更

- 登录页页眉与卡片现在遵循统一布局尺寸.版本链接和语言选择器位于卡片底部,访客可在登录前选择语言.
- 登录密码,管理员验证密码,新密码及确认密码字段默认隐藏输入内容,各有带标签的显示/隐藏控件.切换显示状态时保留字段内容和焦点.
- 登录页版本链接无需认证即可打开随程序提供的 Changelog.磁盘和设置 API 仍受保护.

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

- 2026-09-28 | intended | `docs(changelog): record latest Web update` | this commit
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
