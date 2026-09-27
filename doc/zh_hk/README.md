---
name: project-overview-zh-hk
description: Project overview and usage
metadata:
  version: "0.1.0"
  lang: zh-HK
---

# hdd-health-check

這款以 root 執行的 Bash 工具透過 SMART 數據及唯讀磁碟檢查,評估 Debian/Ubuntu 上的 HDD 健康狀況.目前 `main` 包含 v3.0.0 核心程式碼及可選本機 Web UI.GitHub 提供 `v3.0.0` 原始碼標籤;本次不建立 GitHub Release.用戶表示舊版 `v2.2.0` 曾在實機執行,但未提供裝置,環境及測試範圍;新版評分只經隔離模擬驗證,未經真實 HDD 驗證.

通電時長僅作使用資訊,不單獨扣除健康分.ATA 預失效屬性接近閾值時,只有原始錯誤計數非零才提示關注;舊紀錄若沒有保存原始依據,則標為待覆核且不扣分.關注卡片顯示已記錄的具體原因.

## 多語言

[English](../../README.md) | [简体中文](../zh_cn/README.md) | [繁體中文](../zh_tw/README.md) | **繁體中文(香港)** | [हिन्दी](../hi/README.md) | [Español](../es/README.md) | [العربية](../ar/README.md) | [Français](../fr/README.md)

## 文件

- 項目概覽:[README](README.md)
- 設計理據及對主機的影響:[DESIGN](DESIGN.md)
- 本機 Web UI 設定及 API:[WEB](WEB.md)
- 決策,已知問題及版本紀錄:[LOG](LOG.md)
- 第三方項目清單:[THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## 簡介

互動式選單或批次 CLI 可選擇磁碟,進行快速 SMART,掛載狀態及核心日誌評估,並給出啟發式 0–100 分評分與風險等級.其他模組提供 SMART 短測試/長測試,抽樣讀取速度分析,可續掃的全碟讀取延遲掃描(可選擇針對特定位置以 `badblocks` 複查),全碟唯讀 `badblocks` 檢查,以及維修後的介面讀取測試.完整評估會執行快速,短測試,長測試,速度及表面檢查;不包括獨立的全碟 `badblocks` 或介面模組.結果可重用,與 SMART 計數器歷史紀錄比較,並整理成報告.請參閱[已知問題](../LOG.md#bugs)及[設計目標](../DESIGN.md#design-goals).

**"唯讀"只針對目標磁碟數據,並非主機.**程式會在主機寫入日誌,設定,進度及歷史紀錄;亦可啟用 SMART,啟動磁碟內部自我測試,持續讀取整個裝置,經確認後安裝套件,以及啟動暫時性 systemd unit.不可用它代替備份.本工具沒有實作破壞性的寫入模式表面掃描,清除磁碟或檔案系統寫入.

完整評估在長時間讀取後複查 SMART/ATA/CRC.只有同批次,未過期,已完成的快速,短測試,長測試,速度和表面檢查才顯示 0–100 綜合評分.重用,中斷,過期或舊格式結果仍作歷史顯示,但整體為部分/未知;查看報告不更新基準.維修後應先做獨立介面複查,再重新完成全檢取得新評分;已解決不等於抹去舊錯誤.首次 ATA 累計錯誤原因未明,未解決風險的 5 分扣分在後續複查及全檢後仍會保留.新增錯誤扣 20 分;歷史計數穩定既不是新錯,也不能證明風險已解除.僅有介面複查不能證明舊 ATA 錯誤源於已修復的介面.零星慢讀提示效能重測,並非壞磁區;確認的表面讀取錯誤仍扣 40 分.檢查可疑磁碟前先備份.

## 系統需求

- 最低需求:root,Bash 4.3+,Linux 區塊裝置工具(`lsblk`,`blockdev`),`smartctl`(`smartmontools`),`dd`(`coreutils`)及 `flock`;目標平台為 Debian/Ubuntu.其他發行版會收到警告;自動安裝依賴套件使用 `apt-get`.
- 建議配置:用於表面檢查的 `badblocks`(`e2fsprogs`);用於脫離終端執行工作的 systemd 及 `systemd-run`.缺少套件時,程式可能互動式提議執行 `apt-get update`/安裝(或透過 `-y` 自動確認).無人值守執行前請檢查依賴套件.專案並無隨附鎖定版本的第三方程式碼,亦不適用依賴鎖定檔.
- 要評估實際健康狀況,需有實體 HDD 及 SMART 存取權限.可以明確選入 SSD/NVMe,但針對 HDD 的評分並非經校準的 SSD/NVMe 評估.

## 安裝

### 快速安裝

在可信任的檢出目錄中執行 `sudo bash ./hdd-health-check.sh --help`,無須啟動掃描即可查看選項.不要將未經審核的遠端腳本直接透過管道交給 root shell 執行.

### 一般安裝

以下檢出 `v3.0.0` 原始碼標籤.

```bash
git clone --branch v3.0.0 --depth 1 https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check
bash -n hdd-health-check.sh
sudo bash ./hdd-health-check.sh --help
```

掃描前請自行檢查及安裝所需系統套件,避免腳本彈出套件安裝提示.如要升級現有檢出版本,先備份需要保留的主機日誌及 `${HDD_STATE_DIR:-/var/lib/hdd-health}`;再以經審核檢出版本的腳本取代原腳本,保留該狀態目錄以供歷史紀錄/續掃使用,然後查看 `--help` 並執行所選檢查.v2.2 狀態解析只接受已知數據欄位;既有但不符合規範的 v2.2 狀態可能被拒絕.如要回退,必須還原舊腳本**及與其配套的狀態備份**;不可假設較新版本的狀態向下兼容.不保證保留 v1 CLI 行為或提供狀態遷移.

## 從 v3.0.0 標籤原始碼安裝 Web UI

`v3.0.0` 標籤包含 Web UI 原始碼,但不包含建置產物 `web/dist`.在 Debian systemd 主機先安裝 Node.js 20.19+ 或 22.12+ 和 npm,再建置介面並執行安裝程式:

```bash
git clone --branch v3.0.0 --depth 1 https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/web
npm ci
npm run build
cd ..
sudo bash deploy/install.sh
```

## 使用指引

只可對獲授權檢查的磁碟執行;持續讀取掃描可能造成大量負載.以下指令**只是例子,並非要求在目前環境執行驗證**:

```bash
sudo bash ./hdd-health-check.sh                 # terminal menu
sudo bash ./hdd-health-check.sh -a              # all rotational disks, default quick scan
sudo bash ./hdd-health-check.sh -d sdb -r quick,short
sudo bash ./hdd-health-check.sh -d sdb -r full -y
sudo bash ./hdd-health-check.sh -d sdb -r iface --duration 30 --detach
sudo bash ./hdd-health-check.sh --status
sudo bash ./hdd-health-check.sh --stop
```

`-d/--disk` 接受以逗號分隔的裝置名稱;`-a/--all` 選取機械硬碟,`--include-ssd` 則擴大選取範圍.`-r/--run` 接受 `quick,short,long,speed,surface,badblocks,iface,full`;預設為 `quick`,批次模式一律附加報告.`--duration` 設定介面測試時間(分鐘,預設 15).`--rescan` 重新開始,而不重用/接續先前結果;預設情況下,批次快速檢查會重做,其他仍有效的結果會重用,中斷的表面掃描則會續掃.`-q/--quiet` 停止向終端輸出,**但不會停止寫入日誌**;`-y/--yes` 自動確認提示,包括安裝套件.`--detach` 需要批次模式及可用的 `systemd-run`;符合條件的互動式長時間工作,亦可能在終端斷線時交由 systemd 執行.`--stop` 要求安全停止並保留表面掃描進度,但**不會**取消磁碟內部的 SMART 自我測試.`-l/--log FILE` 更改日誌路徑;`HDD_LOG_DIR` 及 `HDD_STATE_DIR` 覆蓋預設目錄.`NO_COLOR` 停用彩色輸出;`HDD_NO_BG` 停用互動模式自動轉交背景執行.選單設定會儲存在狀態目錄.

解析器亦會將 `-t short|long` 對應至相關自我測試,`-s` 對應至速度測試,`-b` 對應至 badblocks;**`-w/--wait` 會被忽略**,不會等待測試完成.這些別名並不提供 v1 行為.請以已安裝腳本的 `--help` 為選項依據.

退出碼:`0` 全部健康;`1` 提示/警告;`2` 危險;`3` 執行時錯誤.日誌預設寫入 `/var/log/disk-health/hdd-health-<timestamp>.log`;狀態預設位於 `/var/lib/hdd-health`.主機寫入內容及操作邊界詳見 [DESIGN](../DESIGN.md#data-design).

## 解除安裝

- 移除檢出目錄或已安裝腳本, 即可移除命令列工具並保留日誌及歷史紀錄. 命令列工具不會永久安裝 systemd service; 如已安裝可選的 Web 服務, 請先依照 [WEB](WEB.md) 停止及停用服務. 移除腳本前請檢查有否正在執行的暫時性工作.
- 要完全移除,先停止所有工作並備份需要保留的紀錄,再核對路徑及內容,手動刪除已設定的 `HDD_STATE_DIR`(預設 `/var/lib/hdd-health`)和 `HDD_LOG_DIR`(預設 `/var/log/disk-health`).這會刪除報告,進度,歷史紀錄,維修紀錄及日誌;切勿盲目刪除共用或已覆蓋預設值的目錄.透過 `apt-get` 安裝的套件不會自動移除.

## 授權

MIT(SPDX: MIT);詳見 [LICENSE](../../LICENSE).
