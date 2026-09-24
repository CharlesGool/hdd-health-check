# hdd-health-check

這款以 root 身分執行的 Bash 工具透過 SMART 資料與唯讀磁碟檢查，在 Debian/Ubuntu 上評估 HDD 健康狀態。v2.2.0 原始碼已在公開的 GitHub 儲存庫提供。使用者表示已在實機測試，但未提供裝置、環境及測試範圍；目前沒有 v2.2.0 標籤或 GitHub Release。

## 多語言

[English](../../README.md) | [简体中文](../zh_cn/README.md) | **繁體中文** | [繁體中文（香港）](../zh_hk/README.md) | [हिन्दी](../hi/README.md) | [Español](../es/README.md) | [العربية](../ar/README.md) | [Français](../fr/README.md)

## 文件

- 專案概覽：[README](README.md)
- 設計依據與對主機的影響：[DESIGN](DESIGN.md)
- 決策、已知問題與版本歷程：[LOG](LOG.md)
- 第三方素材清單：[THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## 簡介

互動式選單或批次命令列介面可選取磁碟，快速評估 SMART、掛載狀態及核心紀錄，並提供啟發式的 0–100 分數與風險等級。其他模組提供 SMART 短／長自我測試、抽樣讀取速度分析、可續掃的全碟讀取延遲掃描（可選擇針對特定區域以 `badblocks` 重新檢查）、全碟唯讀 `badblocks` 檢查，以及修復後的介面讀取測試。完整評估會執行快速、短測、長測、速度與磁碟表面檢查；不包含獨立的全碟 `badblocks` 或介面模組。結果可重複使用、與 SMART 計數器歷史紀錄比較，並彙整成報告。請參閱[已知問題](LOG.md#已知問題)與[設計目標](DESIGN.md#設計目標)。

**唯讀僅指目標磁碟上的資料，不代表不會更動主機。**程式會在主機上寫入日誌、設定、進度與歷史紀錄；它可能啟用 SMART、啟動磁碟內部的自我測試、持續負載讀取整個裝置、在確認後安裝套件，以及啟動暫時性 systemd 單元。請勿用它取代備份。本工具未實作具破壞性的寫入模式磁碟表面掃描、清除資料或寫入檔案系統。

## 系統需求

- 最低需求：root、Bash 4.3+、Linux 區塊裝置工具（`lsblk`、`blockdev`）、`smartctl`（`smartmontools`）、`dd`（`coreutils`）及 `flock`；預期使用平台為 Debian/Ubuntu。其他發行版會收到警告；自動安裝相依套件時使用 `apt-get`。
- 建議配備：用於磁碟表面檢查的 `badblocks`（`e2fsprogs`）；用於分離執行工作的 systemd 與 `systemd-run`。缺少套件時，程式可能提供互動式 `apt-get update`／安裝選項（或透過 `-y` 自動確認）。無人值守執行前請先檢查相依套件。專案未內附固定版本的第三方程式碼，亦不適用相依套件鎖定檔。
- 評估實際健康狀態需要實體 HDD 與 SMART 存取權。可明確指定納入 SSD/NVMe，但針對 HDD 設計的評分並非經過校準的 SSD/NVMe 評估。

## 安裝

### 快速安裝

從可信任的儲存庫檢出版本執行 `sudo bash ./hdd-health-check.sh --help`，在不啟動掃描的情況下查看選項。不要將未經檢查的遠端腳本直接導入 root shell 執行。

### 一般安裝

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check
bash -n hdd-health-check.sh
sudo bash ./hdd-health-check.sh --help
```

掃描前請自行檢查並安裝必要的作業系統套件，以免腳本提示安裝套件。若要升級既有的檢出版本，請先備份需要保留的主機日誌與 `${HDD_STATE_DIR:-/var/lib/hdd-health}`；接著以經過檢查的檢出版本替換腳本，保留該狀態目錄以供歷史紀錄／續掃使用，再查看 `--help` 並執行所選檢查。v2.2 的狀態解析僅接受已知資料欄位；先前不符合格式的 v2.2 狀態可能遭拒。回復舊版必須還原先前的腳本**及其對應的狀態備份**；不要假設較新版本的狀態能向下相容。不保證相容 v1 命令列行為，也不提供 v1 狀態移轉。

## 使用指引

只對您獲授權檢查的磁碟執行；持續讀取掃描可能造成顯著負載。以下指令**僅為範例，並非要求在此環境驗證**：

```bash
sudo bash ./hdd-health-check.sh                 # terminal menu
sudo bash ./hdd-health-check.sh -a              # all rotational disks, default quick scan
sudo bash ./hdd-health-check.sh -d sdb -r quick,short
sudo bash ./hdd-health-check.sh -d sdb -r full -y
sudo bash ./hdd-health-check.sh -d sdb -r iface --duration 30 --detach
sudo bash ./hdd-health-check.sh --status
sudo bash ./hdd-health-check.sh --stop
```

`-d/--disk` 接受以逗號分隔的裝置名稱；`-a/--all` 選取機械式磁碟，`--include-ssd` 則擴大選取範圍。`-r/--run` 接受 `quick,short,long,speed,surface,badblocks,iface,full`；預設為 `quick`，批次模式一律另行產生報告。`--duration` 設定介面測試分鐘數（預設 15 分鐘）。`--rescan` 會重新開始，而非重複使用或續接先前結果；預設情況下，批次快速檢查會重新執行，其他結果在有效期間內會重複使用，中斷的磁碟表面掃描則會續掃。`-q/--quiet` 會抑制終端機輸出，**不會停止寫入日誌**；`-y/--yes` 會自動確認提示，包括安裝套件。`--detach` 需要批次模式及可用的 `systemd-run`；符合條件的互動式長時間工作，在終端機中斷連線時也可能交由 systemd 執行。`--stop` 會要求安全停止並保留磁碟表面掃描進度，但**不會**取消磁碟內部的 SMART 自我測試。`-l/--log FILE` 變更日誌路徑；`HDD_LOG_DIR` 與 `HDD_STATE_DIR` 可覆寫預設目錄。`NO_COLOR` 停用色彩；`HDD_NO_BG` 停用互動式工作自動轉為背景執行。選單設定儲存在狀態目錄中。

解析器也會將 `-t short|long` 對應至相應的自我測試、`-s` 對應至速度測試、`-b` 對應至 badblocks；**`-w/--wait` 會被忽略**，不會等待測試完成。這些別名不提供 v1 行為。請以已安裝腳本的 `--help` 查看選項。

結束代碼：`0` 全部健康；`1` 注意／警告；`2` 危險；`3` 執行階段錯誤。日誌預設寫入 `/var/log/disk-health/hdd-health-<timestamp>.log`；狀態預設寫入 `/var/lib/hdd-health`。主機寫入行為與操作邊界詳見[設計文件](DESIGN.md#資料設計)。

## 解除安裝

- 移除儲存庫檢出目錄或已安裝的腳本，即可移除工具而保留日誌與歷史紀錄。程式不會永久安裝 systemd 服務；移除腳本前請檢查是否有執行中的暫時性工作。
- 如需完整移除，請先停止所有工作並備份欲保留的紀錄，再確認路徑及內容後，手動刪除設定的 `HDD_STATE_DIR`（預設 `/var/lib/hdd-health`）和 `HDD_LOG_DIR`（預設 `/var/log/disk-health`）。這會刪除報告、進度、歷史紀錄、修復註記與日誌；切勿不經確認就刪除共用目錄或覆寫後的目錄。透過 `apt-get` 安裝的套件不會自動移除。

## 授權條款

MIT（SPDX: MIT）；請參閱 [LICENSE](../../LICENSE)。
