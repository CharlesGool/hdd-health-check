---
name: third-party-notices-zh-cn
description: Third-party software and asset notices
metadata:
  version: "0.1.0"
  lang: zh-CN
---

# 第三方声明

本清单记录可选 Web UI 使用的第三方材料.

## 多语言

[English](../THIRD_PARTY_NOTICES.md) | **简体中文** | [繁體中文(台灣)](../zh-TW/THIRD_PARTY_NOTICES.md) | [繁體中文(香港)](../zh-HK/THIRD_PARTY_NOTICES.md) | [हिन्दी](../hi/THIRD_PARTY_NOTICES.md) | [Español](../es/THIRD_PARTY_NOTICES.md) | [العربية](../ar/THIRD_PARTY_NOTICES.md) | [Français](../fr/THIRD_PARTY_NOTICES.md)

## 文档

- 项目概览:[README](README.md)

- 设计思路:[DESIGN](DESIGN.md)

- 发布历史:[LOG](LOG.md)

- 第三方声明:[THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## 第三方声明

Web 构建产物包含 Vue (MIT),markdown-it (MIT),Lucide 图标 (ISC)及 Tailwind CSS 输出(MIT).Inter,Noto Sans SC,Noto Sans Arabic 与 Noto Sans Devanagari 字体采用 SIL Open Font License 1.1,由项目自行托管.Vue,Tailwind CSS,markdown-it,图标和字体的许可文本位于 `src/web/public/licenses/`,并包含在构建后的 UI 中.构建依赖及确切版本记录于 `src/web/package-lock.json`.

运行时系统工具(`smartctl`,`lsblk`,`dd`,`badblocks`,`systemd-run`)由主机单独提供,不随本仓库分发.此处不代表上游主张任何许可证或署名信息.项目自身的 [MIT 许可证](../../LICENSE) 与之独立.
