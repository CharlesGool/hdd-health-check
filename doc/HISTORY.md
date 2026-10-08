---
name: project-history
description: 历史记录
metadata:
  version: "1.0.0"
  lang: "zh-CN"
---

# 历史记录

## 多语言

**简体中文** | [English](en/HISTORY.md) | [Español](es/HISTORY.md)

## 文档

- 项目概览: [README](../README.md)

- 设计思路: [DESIGN](DESIGN.md)

- 项目状态: [LOG](LOG.md)
- 历史记录: [HISTORY](HISTORY.md)
- 变更日志: [CHANGELOG](CHANGELOG.md)

- 第三方声明: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)


## 历史记录

| 日期 | 需求或决定 | 当时状态与证据 |
| --- | --- | --- |
| 2026-08-13 | 公布首个 HDD 检查器并规范化目录 | `v1.0.0` 标签保留初版源码; 当时仅完成语法与帮助检查, 没有受控 HDD/SMART 验证. |
| 2026-09-24 | 整合持久化结果, 历史, 后台任务和批次评分 | `v2.3.0` 标签包含早期 v2.2 整合; 评分与状态使用合成测试, 不承诺 v1 兼容. |
| 2026-09-27 | 引入 Python/Vue Web 控制器 | `v3.0.0` 标签保存原 `web/` 布局; 历史记录报告 Debian NAS 的认证服务及真实磁盘清单验证, 完整 HDD 评估与重启恢复仍未完成. |
| 2026-09-28 | 更新 Web 安全, SSD 评估与源码布局 | `v4.0.0` GitHub Release 已发布; 近期管理员验证, IP 权限隔离和任务历史纳入版本. |
| 2026-09-29 | 更新 Web 外观, 磁盘详情和标签定位 | `v4.1.0` GitHub Release 已发布; 真实 HDD 与重启验证仍未完成. |
| 2026-09-29 | 移除页面过渡 | `5b8e2db` 完成立即导航; 旧返回动画不再作为当前功能. |
| 2026-10-08 | 对齐项目规范, 修复读取环境判定与登录限流 | `a228d8d`, `0d0564f`, `2184495` 已正常提交并推送; 干净检出 CI 通过, 没有部署或创建新 Release. |

旧需求, 原始完成状态和完整源码可通过 `git log` 与上述标签追溯. 本表是依据 Git 与已记录验证范围重新整理的摘要, 不把历史 NAS 检查扩大为硬件全面验证.
