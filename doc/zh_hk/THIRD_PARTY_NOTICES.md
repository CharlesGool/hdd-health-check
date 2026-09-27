---
name: third-party-notices-zh-hk
description: Third-party software and asset notices
metadata:
  version: "0.1.0"
  lang: zh-HK
---

# 第三方聲明

本清單記錄可選 Web UI 使用的第三方材料.

## 多語言

[English](../THIRD_PARTY_NOTICES.md) | [简体中文](../zh_cn/THIRD_PARTY_NOTICES.md) | [繁體中文](../zh_tw/THIRD_PARTY_NOTICES.md) | **繁體中文(香港)** | [हिन्दी](../hi/THIRD_PARTY_NOTICES.md) | [Español](../es/THIRD_PARTY_NOTICES.md) | [العربية](../ar/THIRD_PARTY_NOTICES.md) | [Français](../fr/THIRD_PARTY_NOTICES.md)

## 文件

- 項目概覽:[README](README.md)
- 設計理據:[DESIGN](DESIGN.md)
- 版本紀錄:[LOG](LOG.md)
- 第三方項目清單:[THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

Web 建置結果包含 Vue (MIT), Lucide 圖示 (ISC) 及 Tailwind CSS 輸出 (MIT). Inter, Noto Sans SC, Noto Sans Arabic 及 Noto Sans Devanagari 字型採用 SIL Open Font License 1.1, 並由專案自行託管. 圖示及字型的授權文字存放於 `web/public/licenses/`, 亦包含在建置後的 UI. 建置依賴套件及確切版本記錄於 `web/package-lock.json`.

執行時使用的系統工具 (`smartctl`, `lsblk`, `dd`, `badblocks`, `systemd-run`) 由主機另外提供, 並非由本儲存庫分發. 本專案不會在此代其主張上游授權或署名要求. 專案本身的 [MIT 授權](../../LICENSE) 則另行適用.

Web 建置亦包含以 Markdown 顯示更新紀錄的 markdown-it(MIT);授權條款位於 `web/public/licenses/Markdown-It-MIT.txt`.
