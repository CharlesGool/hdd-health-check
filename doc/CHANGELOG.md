---
name: project-changelog
description: 变更日志
metadata:
  version: "1.0.0"
  lang: "zh-CN"
---

# 变更日志

## 多语言

**简体中文** | [English](en/CHANGELOG.md) | [Español](es/CHANGELOG.md)

## 文档

- 项目概览: [README](../README.md)

- 设计思路: [DESIGN](DESIGN.md)

- 项目状态: [LOG](LOG.md)
- 历史记录: [HISTORY](HISTORY.md)
- 变更日志: [CHANGELOG](CHANGELOG.md)

- 第三方声明: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)


## 变更日志

这里重述已存在版本的正式变更, 不为本轮文档工作创建新版本. 日期来自现有标签或 GitHub Release; 早期标签没有对应的 GitHub Release 页面.

### v4.1.0 — 2026-09-29

#### 新增

- 扩展磁盘详情, SMART 属性说明和支持的 SSD 主机读写量展示.
- 更新 Web 外观, 主题与控件反馈, 为不同页面提供图标.

#### 变更

- 登录页显示版本, 语言与独立密码显示控件, 登录前可阅读变更记录.

#### 修复

- 校正详情标签下划线的实测定位, 保持 Web 状态目录私有权限.

### v4.0.0 — 2026-09-28

#### 新增

- 独立的近期管理员验证, 密码更新, 精确私有 IP 访问控制和后台任务历史.
- SSD/NVMe 完整评估与单盘唤醒/待机操作.

#### 变更

- 源码移入 `src/checker/` 与 `src/web/`, 前端产物移入 `dist/web/`.
- 混合磁盘批量检查提供支持模块的并集, HDD 专用检查跳过 SSD.

### v3.0.0 — 2026-09-27

#### 新增

- Python Web 服务, Vue 界面, 定时快检, SMART 历史和 Debian 安装器.
- 结构化磁盘快照, Web 任务收据与 `--no-install` 控制.

### v2.3.0 — 2026-09-24

#### 新增

- 每盘结果与历史, 可续扫读取, 维修后接口复查, 批处理与 systemd 后台任务.

#### 变更

- 只有完整, 有效且属于同一批次的检查产生当前综合分数; 旧结果保持历史证据.

#### 修复

- 状态以已知数据字段解析, 避免将持久化记录作为 Shell 代码执行.

### v1.0.0 — 2026-08-13

#### 新增

- SMART 属性, 错误与自检日志, 挂载和内核错误检查, 只读测速与 badblocks 扫描.
- 交互式/批处理选盘, 0–100 启发式评分, 日志及退出码.
