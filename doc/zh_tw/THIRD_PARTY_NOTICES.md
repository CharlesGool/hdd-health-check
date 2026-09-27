---
name: third-party-notices-zh-tw
description: Third-party software and asset notices
metadata:
  version: "0.1.0"
  lang: zh-TW
---

# 第三方聲明

本清單記錄選用 Web UI 使用的第三方素材.

## 多語言

[English](../THIRD_PARTY_NOTICES.md) | [简体中文](../zh_cn/THIRD_PARTY_NOTICES.md) | **繁體中文** | [繁體中文(香港)](../zh_hk/THIRD_PARTY_NOTICES.md) | [हिन्दी](../hi/THIRD_PARTY_NOTICES.md) | [Español](../es/THIRD_PARTY_NOTICES.md) | [العربية](../ar/THIRD_PARTY_NOTICES.md) | [Français](../fr/THIRD_PARTY_NOTICES.md)

## 文件

- 專案概覽:[README](README.md)
- 設計依據:[DESIGN](DESIGN.md)
- 版本歷程:[LOG](LOG.md)
- 第三方素材清單:[THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

Web 建置結果包含 Vue (MIT), Lucide 圖示 (ISC) 及 Tailwind CSS 輸出 (MIT). Inter, Noto Sans SC, Noto Sans Arabic 與 Noto Sans Devanagari 字型採用 SIL Open Font License 1.1, 並由專案自行託管. 圖示與字型的授權文字存放於 `web/public/licenses/`, 也包含在建置後的 UI 中. 建置依賴套件與確切版本記錄於 `web/package-lock.json`.

執行階段使用的系統工具 (`smartctl`, `lsblk`, `dd`, `badblocks`, `systemd-run`) 另由主機提供, 不隨本儲存庫散布. 本文件不代上游宣稱其授權或歸屬. 本專案自身的 [MIT 授權條款](../../LICENSE) 與這些工具分開.

Web 建置亦包含以 Markdown 顯示更新紀錄的 markdown-it(MIT);授權條款位於 `web/public/licenses/Markdown-It-MIT.txt`.
