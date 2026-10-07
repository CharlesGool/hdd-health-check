---
name: project-log-zh-hk
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: "zh-HK"
---

# hdd-health-check — 紀錄

本文記錄已採納的歷史決策,已知限制及發佈歷史.目前的大版本為 `v4.1.0`.用戶表示較早的 `v2.2.0` 曾在實機運行,但未提供裝置,環境或測試範圍.修訂後的評分已有模擬測試及 Debian NAS 上的 Web 驗證,但尚未在真實 HDD 上完成受控的完整評估.

## 多語言

[English](../en/LOG.md) | [简体中文](../LOG.md) | [繁體中文(台灣)](../zh-TW/LOG.md) | **繁體中文(香港)** | [हिन्दी](../hi/LOG.md) | [Español](../es/LOG.md) | [العربية](../ar/LOG.md) | [Français](../fr/LOG.md)

## 文件

- 項目概覽:[README](README.md)

- 設計理據:[DESIGN](DESIGN.md)

- 發佈歷史:[LOG](LOG.md)

- 第三方聲明:[THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## 記錄

- [HISTORY](HISTORY.md)
- [CHANGELOG](CHANGELOG.md)

## 錯誤

- [ ] 用戶表示已在實機測試 v2.2.0,但未提供裝置,環境或測試範圍;未能確認 root/套件安裝或 systemd 行為已測;先前 v1.0.0 發佈檢查亦沒有實體 HDD 和 SMART 數據(只檢查了語法及說明).據報原始版本在標準化前曾被使用,但不能代替受控的硬件測試.
- [ ] 修訂後的批次評分及最後 SMART/ATA/CRC 複查只經合成測試,尚未於真實 HDD 驗證.韌體自我測試日誌時間精度及跨次執行續掃可能導致部分/未知;維修後無法自動重新歸因舊錯誤. 此硬件驗證限制仍予以披露;仍建議在獲授權 HDD 上重測.
- [ ] 啟發式健康權重並非經校準的故障概率;SAS/SCSI 評分的測試程度低於 ATA,USB/RAID SMART 透傳亦可能失敗.依賴廠商資料的溫度報告尚不完整.
- [ ] 已在 Debian NAS 上檢查經認證的局域網 Web 服務及真實磁碟清單;真實 HDD 完整評估及重新啟動後復原仍未驗證.不合格式的舊 v2.2 狀態會被拒;目前不提供 CSV 匯出.
- [x] 用戶提供的 `test-771001c` 截圖顯示,磁碟詳情中目前分頁的底線超出所選分頁.舊指示線按整數按鈕寬度縮放一像素線條.現時直接以量得的精確寬度執行動畫;本機 Chromium 在窄畫面,縮放及 RTL 情況下,底線均與選取的 SMART 和 Checks 按鈕一致.無法取得截圖當時的確切瀏覽器設定以重現.
- [ ] 用戶回報從磁碟詳情返回時的動畫有問題,並要求留待日後處理.修正分頁底線時並無更改返回動畫程式碼.
- [x] v1.0.0 標準化修正了指向不存在的 `hdd-health-check-repo/main` 路徑的 clone 說明,以及簡體中文 README 混用繁體字的問題.

## 限制

- 已安裝的 Debian 服務為了升級兼容,仍使用 `/root/apps/hdd-health-check/web/` 主機目錄佈局;原始碼位於 `src/web/`,產生的建置結果位於 `dist/web/`.

### 兼容入口

基線: `35f24e5`
原因: 既有 CLI 命令及安裝說明呼叫儲存庫根目錄的 Shell 入口;實作現位於 `src/checker/`.
更新界線: 保留根目錄分派入口,直到另行通知的 CLI 路徑遷移取代既有命令.

- `hdd-health-check.sh` -> `src/checker/hdd-health-check.sh`

## 決策

| 決策 | 原因 |
| --- | --- |
| 2026-08-12:將本地項目分為 Git 工作目錄及獨立快照;拒絕扁平式本地佈局. | 過往版本快照需要與追蹤中的原始碼分開.當時的 `main/` 名稱只用於本地,從未屬於 GitHub 檢出目錄;原計劃使用 tag 及 `git archive` 快照. |
| 2026-08-13:將本地 `main/` 改名為 `repo/`;修正安裝路徑,雙語標題及 `.gitignore`;不在公開狀態中顯示私人鏡像及快照路徑.拒絕原封不動提交已暫存的過時文件. | GitHub 檢出目錄會將腳本放在根目錄.舊指令片段在 clone 後會即時失效;本地路徑及翻譯錯誤不應出現在公開文件中. |
| 2026-08-13:不以現有虛擬磁碟模擬實際 HDD 發佈檢查;如實披露較弱的驗證結果. | 當時沒有可用的 SMART 硬件或 `smartmontools`;安裝套件掃描虛擬磁碟亦無法測試 HDD 邏輯. |
| 2026-08-13:以使用 noreply 身份的一筆乾淨 commit 及附註 tag 取代公開的 v1.0.0 歷史,原有歷史保留於已改名的私人封存;拒絕強制推送舊的公開儲存庫或保留已被取代的中間 commit. | 先前公開的 commit 在 Git metadata 中包含個人電郵地址.現有 clone/fork 不會自動遷移,亦不能保證先前洩露的資料已從快取清除.這是歷史紀錄,並非再次改寫歷史的授權. |
| 目前整合:採用所提供的 v2.2.0 行為,不保證兼容 v1,並保留現有 MIT 授權. | 新腳本加入持久狀態及可選的背景工作;`-w` 會被忽略.整合當時並未聲稱已發佈,建立 tag 或完成硬件驗證. |

## 交接

[简体中文](../LOG.md#交接)
