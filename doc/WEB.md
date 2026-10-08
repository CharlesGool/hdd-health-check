---
name: web
description: 本地 Web 控制器的安装, 访问与接口说明
metadata:
  version: "1.0.0"
  lang: "zh-CN"
---

# Web 指南

## 多语言

**简体中文** | [English](en/WEB.md) | [Español](es/WEB.md)

## 范围

本指南说明当前源码的本地 Web 控制器, 安装与访问方式. 它不保证旧发布包包含所有当前源码修复.

## 构建与安装

在已审查的源码根目录执行:

```bash
cd src/web
npm ci
npm run check
cd ../..
sudo bash deploy/install.sh
```

构建需要 Node.js 22.12+ 或 24+ 和 npm 10+. 运行服务需要 Python 3.10+, SMART 与块设备工具. 安装器仅支持运行 systemd 的 Debian, 会安装缺少的运行依赖, 将应用放入 `/root/apps/hdd-health-check`, 单元放入 `/etc/systemd/system/hdd-health-web.service`, 并启用 TCP 8765 的密码保护服务. 主机状态和日志保留.

从可信 LAN 访问 `http://<NAS-IP>:8765`, 用管理员从主机读取的 `web-password` 登录. HTTP 不加密凭据, 不向互联网暴露该端口. 也可通过 SSH 隧道访问服务. 服务校验目标 Host 与同源 Origin, 不根据任意转发头授予访问.

仅用于开发的手动运行:

```bash
sudo python3 src/web/server.py --bind 127.0.0.1 --port 8765
```

该模式只监听回环, 未提供密码文件时使用本机访问模式. 非回环绑定要求 `--password-file` 指向 root 所有且权限受限的普通文件. 安装器提供的 LAN 单元始终传入密码文件.

## 页面与权限

| 页面 | 用途 |
| --- | --- |
| `/disks` | 仪表盘, 容量, 磁盘卡片和批量检查 |
| `/disks/<device>`, `/attention/<device>` | SMART 详情, 检测结果, 序列号显示和支持的盘电源操作 |
| `/attention` | 异常证据与需复查的记录 |
| `/tasks` | 当前任务, 已完成/停止/失败的收据及可用日志 |
| `/schedule` | 每 6–168 小时执行一次快检的定时配置 |
| `/settings` | 语言, 明暗模式, 八种主题色, 休眠策略与安全入口 |
| `/security` | 管理员密码更新与 IP 访问控制 |
| `/changelog` | 构建标识与正式变更, 登录前可阅读 |

密码登录建立会话. 安全 API 需要服务器为该会话保存的五分钟密码验证; 修改密码会使现有会话失效. IP 访问只接受精确的 RFC 1918 IPv4 或 `fc00::/7` 地址, 只授予普通权限; 进入安全设置需重新验证密码. 删除允许地址立即撤销其访问. 浏览器在注销或被拒后清除 IP 访问记录.

页面立即导航. 设置分区只滚动到对应卡片, 安全入口另行验证. 私有序列号默认遮蔽, 显示操作通过独立认证 API 获取原文; 切换标签或离开详情恢复遮蔽. 界面语言为八种, 文档变更记录提供简中/英/西, 其他语言回退到英文.

## 检查与数据边界

批量请求由服务器按当前设备清单与范围选盘, 只接受固定模块. SSD 支持快检, 短测, 长测, 盘面和完整评估; 混合选择对 HDD 专用检查跳过 SSD. Web 调用附加 `--no-install`, 不自动批准系统包安装.

定时配置启用后继续保存并运行, 更新安装不重置它. 关闭 Web 服务不等于停止独立 systemd 检查; 在页面或 CLI 中请求安全停止, 仍不取消磁盘内部自检.

SMART 原始健康状态, 温度与计数器不替代批次综合评分. 缺失字段保持未知, 不猜测厂商计数单位. 主机日志与趋势数据可能包含设备标识; 删除最后一条 SMART 样本会改变下一次比较基线.

## API

除认证状态和静态页面外, API 要求有效访问. 密码认证模式下改变状态的 JSON 请求还需要 `X-HDD-CSRF: 1`; 安全相关路径另查近期密码权限.

| 路径 | 职责 |
| --- | --- |
| `GET /api/auth`, `POST /api/auth/login`, `/ip-login`, `/logout` | 访问状态与会话 |
| `POST /api/auth/security-verify`, `/change-password` | 近期验证与密码更新 |
| `GET/POST /api/access` | 受保护的 IP 名单与开关 |
| `GET /api/build`, `/api/changelog?lang=<lang>` | 产物内嵌版本与相应的变更记录 |
| `GET /api/snapshot`, `/api/disks/<device>/smart`, `/serial` | 磁盘快照, SMART 与按需序列号 |
| `POST /api/disks/<device>/wake`, `/sleep`, `/api/disks/wake-on-visit` | 支持的单盘或访问唤醒操作 |
| `GET/POST /api/preferences`, `/api/schedule` | 休眠偏好与定时配置 |
| `POST /api/jobs`, `/api/jobs/assess`, `/api/jobs/stop` | 检查, 批次与安全停止 |
| `GET /api/status`, `/api/jobs/history`, `/api/jobs/history/<id>` | 当前任务, 历史收据与有界日志末尾 |
| `GET /api/history/<device>`, `/api/history/samples` | SMART 趋势数据 |
| `DELETE /api/jobs/history/<id>`, `/api/history/samples/<device>/<index>` | 删除收据/关联日志或单条趋势样本 |

`/api/jobs/assess` 接受范围 `sata,hdd,ssd,nvme,all` 和模块 `quick,short,long,speed,surface,badblocks,iface,full`. 不接受浏览器提交的任意命令. 运行返回码 `1` 或 `2` 表示已完成但发现问题, 不是任务启动失败.

## 升级与回滚

1. 先结束或停止检查并备份私有状态与日志; 核对当前版本和服务单元.
2. 更新并构建源码后重跑安装器. 它保留密码, 旧应用和匹配的单元备份, 启动失败时尝试恢复; 包安装本身不属于应用文件回滚范围.
3. 检查服务活动状态, 密码登录, `/api/build` 与磁盘清单. 不用查看页面来代替完整设备评估.

需要回退时, 先停止服务与独立检查, 恢复匹配的应用, 单元和需要回退的状态备份, 执行 `sudo systemctl daemon-reload` 后启动服务. 不盲目删除或覆盖状态目录. 实际 NAS 更新与重启恢复仍需目标主机验证.

## 开发验证

从源码根运行 `bash scripts/check.sh`. 在 `src/web/` 运行 `npm run check`, 安装 Playwright Chromium 后运行 `npm run test:ui`. 浏览器测试使用隔离会话服务和合成设备, 会验证版本, 语言回退, 响应式布局, 权限展示, 键盘与仿真触摸; 不启动真实检查.
