---
name: project-overview-zh-hk
description: Project overview and usage
metadata:
  version: "0.1.0"
  lang: zh-HK
---

# hdd-health-check

這款以 root 身分運行的 Bash 工具透過 SMART 資料與唯讀磁碟檢查,評估 Debian/Ubuntu 上的 HDD 健康狀態.目前 `main` 包含 v3.0.0 核心程式碼及可選的本機 Web UI.GitHub 提供 `v3.0.0` 原始碼標籤,但沒有建立 GitHub Release.Web 服務已在具有實際磁碟清單的 Debian NAS 上檢查;實體 HDD 的完整評估仍未驗證.

## 多語言

[English](../../README.md) | [简体中文](../zh-CN/README.md) | [繁體中文(台灣)](../zh-TW/README.md) | **繁體中文(香港)** | [हिन्दी](../hi/README.md) | [Español](../es/README.md) | [العربية](../ar/README.md) | [Français](../fr/README.md)

## 文件

- 項目概覽:[README](README.md)

- 設計理據:[DESIGN](DESIGN.md)

- 發佈歷史:[LOG](LOG.md)

- 第三方聲明:[THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## 簡介

互動式選單或批次命令列可選取磁碟,快速評估 SMART,掛載狀態和核心紀錄,並提供啟發式 0–100 分數及風險等級.其他模組提供 SMART 短測/長測,抽樣讀速分析,可續掃的全碟讀取延遲掃描及可選的針對性 `badblocks` 複查,全碟唯讀 `badblocks`,以及維修後的介面讀取測試.對 HDD,完整評估執行快速檢查,短測,長測,速度和全碟唯讀掃描;對 SSD,執行快速檢查,短測,長測和全碟唯讀表面掃描,不取樣速度.兩者均不包含獨立的全碟 `badblocks` 或介面模組.結果可重複使用,與 SMART 計數器歷史比較並彙整為報告.請參閱[已知問題](LOG.md#錯誤)與[設計目標](DESIGN.md#設計目標).

完整評估在長時間讀取後再次檢查快速 SMART/ATA/CRC.只有同一未過期評估批次中所需的快速檢查,短測,長測及完整表面掃描(以及 HDD 的速度取樣)都完成,才顯示 0–100 綜合分數.重複使用,中斷,過期或舊格式結果仍作歷史證據顯示,但等級為部分/未知;檢視報告不更新比較基準.維修介面後,單獨進行介面驗證並重新完成完整評估,才能取得新分數.已解決的介面檢查不會抹除歷史錯誤.沒有先前比較值的 ATA 錯誤總數原因未明,扣 5 分,其未解決風險會在後續檢查和完整評估中保留;計數穩定本身不能證明風險解除.新增 ATA 錯誤扣 20 分;未變動的歷史計數不算新錯誤.現有介面驗證不能把 ATA 錯誤歸因於介面維修.零星慢讀提示重測效能,並非壞磁區證據;確認的讀取錯誤仍屬中等風險證據(表面扣 40 分).通電時長本身不扣健康分;ATA 接近閾值警告需要非零原始錯誤計數,缺乏原始依據的舊閾值提示標為待複查.檢查可疑磁碟前請備份重要資料.

**唯讀僅指目標磁碟資料,並非主機.** 程式會在主機寫入日誌,設定,進度及歷史紀錄;可能啟用 SMART,啟動磁碟內部自我測試,持續讀取整個裝置,經確認後安裝套件及啟動暫時性 systemd 單元.不能以此取代備份.本工具不執行具破壞性的寫入模式表面掃描,清除資料或寫入檔案系統.

## 要求

- 最低需求:root,Bash 4.3+,Linux 區塊裝置工具(`lsblk`,`blockdev`),`smartctl`(`smartmontools`),`dd`(`coreutils`)及 `flock`;目標平台為 Debian/Ubuntu.其他發行版會收到警告;自動安裝依賴套件使用 `apt-get`.
- 建議配置:用於表面檢查的 `badblocks`(`e2fsprogs`);用於脫離終端執行工作的 systemd 及 `systemd-run`.缺少套件時,程式可能互動式提議執行 `apt-get update`/安裝(或透過 `-y` 自動確認).無人值守執行前請檢查依賴套件.專案並無隨附鎖定版本的第三方程式碼,亦不適用依賴鎖定檔.
- 評估實體 HDD 健康狀態需要 HDD 與 SMART 存取權.可明確納入 SSD/NVMe.完成的 SSD 全面評估若 SMART 檢查,自我測試和全碟唯讀掃描均無異常,得分為 100;實際讀取錯誤和 SMART 異常會降低此啟發式分數.它不是經校準的故障機率.
## 安裝

### 快速安裝

在可信任的檢出目錄中執行 `sudo bash ./hdd-health-check.sh --help`,無須啟動掃描即可查看選項.不要將未經審核的遠端腳本直接透過管道交給 root shell 執行.

### 一般安裝

以下檢出目前的原始碼分支.儲存庫根目錄的命令只是簡短入口,實作位於 `src/checker/`.
```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check
bash -n hdd-health-check.sh src/checker/hdd-health-check.sh
sudo bash ./hdd-health-check.sh --help
```

掃描前請自行檢查及安裝所需系統套件,避免腳本彈出套件安裝提示.如要升級現有檢出版本,先備份需要保留的主機日誌及 `${HDD_STATE_DIR:-/var/lib/hdd-health}`;再以經審核檢出版本的腳本取代原腳本,保留該狀態目錄以供歷史紀錄/續掃使用,然後查看 `--help` 並執行所選檢查.v2.2 狀態解析只接受已知數據欄位;既有但不符合規範的 v2.2 狀態可能被拒絕.如要回退,須還原舊腳本**及與其配套的狀態備份**;不可假設較新版本的狀態向下兼容.不保證保留 v1 CLI 行為或提供狀態遷移.

### 從目前原始碼安裝 Web UI

目前原始碼不追蹤 `dist/web` 內產生的資源.在 Debian systemd 主機安裝 Node.js 20.19+ 或 22.12+ 及 npm,建置介面,然後執行安裝程式:

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/src/web
npm ci
npm run build
cd ../..
sudo bash deploy/install.sh
```

安裝程式會檢查並安裝缺少的 Debian 執行相依套件,在區域網路 8765 埠啟動受密碼保護的服務,但不會啟動磁碟掃描.使用 `sudo cat /root/apps/hdd-health-check/web-password` 查看產生的密碼.Node.js 僅用於建置介面.更新,安全邊界及復原說明請參閱 [WEB](WEB.md).

## 指引

只可對獲授權檢查的磁碟執行;持續讀取掃描可能造成大量負載.以下指令**只是例子,並非要求在目前環境執行驗證**:

```bash
sudo bash ./hdd-health-check.sh                 # 終端機選單
sudo bash ./hdd-health-check.sh -a              # 所有機械硬碟,預設快速檢查
sudo bash ./hdd-health-check.sh -d sdb -r quick,short
sudo bash ./hdd-health-check.sh -d sdb -r full -y
sudo bash ./hdd-health-check.sh -d sdb -r iface --duration 30 --detach
sudo bash ./hdd-health-check.sh --status
sudo bash ./hdd-health-check.sh --stop
```

`-d/--disk` 接受以逗號分隔的裝置名稱;`-a/--all` 選取機械硬碟,`--include-ssd` 則擴大選取範圍.`-r/--run` 接受 `quick,short,long,speed,surface,badblocks,iface,full`;預設為 `quick`,批次模式一律附加報告.`--duration` 設定介面測試時間(分鐘,預設 15).`--rescan` 重新開始,而不重用/接續先前結果;預設情況下,批次快速檢查會重做,其他仍有效的結果會重用,中斷的表面掃描則會續掃.`-q/--quiet` 停止向終端輸出,**但不會停止寫入日誌**;`-y/--yes` 自動確認提示,包括安裝套件.`--detach` 需要批次模式及可用的 `systemd-run`;符合條件的互動式長時間工作,亦可能在終端斷線時交由 systemd 執行.`--stop` 要求安全停止並保留表面掃描進度,但**不會**取消磁碟內部的 SMART 自我測試.`-l/--log FILE` 更改日誌路徑;`HDD_LOG_DIR` 及 `HDD_STATE_DIR` 覆蓋預設目錄.`NO_COLOR` 停用彩色輸出;`HDD_NO_BG` 停用互動模式自動轉交背景執行.選單設定會儲存在狀態目錄.

解析器亦會將 `-t short|long` 對應至相關自我測試,`-s` 對應至速度測試,`-b` 對應至 badblocks;**`-w/--wait` 會被忽略**,不會等待測試完成.這些別名並不提供 v1 行為.請以已安裝腳本的 `--help` 為選項依據.

退出碼:`0` 全部健康;`1` 提示/警告;`2` 危險;`3` 執行時錯誤.日誌預設寫入 `/var/log/disk-health/hdd-health-<timestamp>.log`;狀態預設位於 `/var/lib/hdd-health`.主機寫入內容及操作邊界詳見 [DESIGN](../DESIGN.md#data-design).

## 升級

就目前原始碼佈局而言,更新檢出目錄,在 `src/web` 中建置,然後從儲存庫根目錄執行 `sudo bash deploy/install.sh`.安裝程式將 `src/checker/hdd-health-check.sh`,`src/web/server.py` 和 `dist/web` 複製到既有服務佈局,保留 Web 密碼,並備份帶時間戳記的程式與服務單元.以 root 執行前先檢查變更.歷史 `v3.0.0` 標籤仍保留原本的 `web/` 原始碼佈局及其安裝說明.

## 移除

- 移除檢出目錄或已安裝腳本, 即可移除命令列工具並保留日誌及歷史紀錄. 命令列工具不會永久安裝 systemd service; 如已安裝可選的 Web 服務, 請先依照 [WEB](WEB.md) 停止及停用服務. 移除腳本前請檢查有否正在執行的暫時性工作.
- 要完全移除,先停止所有工作並備份需要保留的紀錄,再核對路徑及內容,手動刪除已設定的 `HDD_STATE_DIR`(預設 `/var/lib/hdd-health`)和 `HDD_LOG_DIR`(預設 `/var/log/disk-health`).這會刪除報告,進度,歷史紀錄,維修紀錄及日誌;切勿盲目刪除共用或已覆蓋預設值的目錄.透過 `apt-get` 安裝的套件不會自動移除.

## 致謝

第三方程式碼和字體的致謝列於 [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md).

## 授權條款

MIT(SPDX: MIT);詳見 [LICENSE](../../LICENSE).

## 目前固態硬碟評估與操作

固態硬碟和 NVMe 的完整評估包含 SMART 快速檢查,短測,長測及全碟唯讀掃描,不取樣速度.單純慢讀不扣健康分;無異常而完成的批次得 100 分,SMART 異常或實際讀取錯誤可能降低啟發式分數.批次控制顯示所選磁碟支援的項目聯集;僅適用於 HDD 的項目會跳過選取的 SSD.點擊容量及主機寫入量可切換十進位與二進位單位.SATA HDD 可在 SMART 詳細資料中單獨喚醒或進入待機.
