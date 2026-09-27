---
name: third-party-notices-zh-cn
description: Third-party software and asset notices
metadata:
  version: "0.1.0"
  lang: zh-CN
---

# 第三方声明

本清单记录当前没有需要在项目中声明的内置第三方材料.

## 多语言

[English](../THIRD_PARTY_NOTICES.md) | **简体中文** | [繁體中文](../zh_tw/THIRD_PARTY_NOTICES.md) | [繁體中文(香港)](../zh_hk/THIRD_PARTY_NOTICES.md) | [हिन्दी](../hi/THIRD_PARTY_NOTICES.md) | [Español](../es/THIRD_PARTY_NOTICES.md) | [العربية](../ar/THIRD_PARTY_NOTICES.md) | [Français](../fr/THIRD_PARTY_NOTICES.md)

## 文档

- 项目概览:[README](README.md)
- 设计依据:[DESIGN](DESIGN.md)
- 版本历史:[LOG](LOG.md)
- 第三方清单:[THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

可选 Web UI 构建产物包含 Vue(MIT),Lucide 图标(ISC)及 Tailwind CSS 输出(MIT),并随站点自托管采用 SIL Open Font License 1.1 的 Inter,Noto Sans SC,Noto Sans Arabic 与 Noto Sans Devanagari 字体.图标及字体的许可文本位于 `web/public/licenses/`,构建时一并纳入;依赖精确版本见 `web/package-lock.json`.

运行时系统工具(`smartctl`,`lsblk`,`dd`,`badblocks`,`systemd-run`)由主机单独提供,不随本仓库分发.此处不代表上游主张任何许可证或署名信息.项目自身的 [MIT 许可证](../../LICENSE) 与之独立.

Web 构建还包含用于更新记录 Markdown 渲染的 markdown-it(MIT);其许可证文本位于 `web/public/licenses/Markdown-It-MIT.txt`.
