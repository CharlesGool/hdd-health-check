# hdd-health-check

這款以 root 身分執行的 Bash 工具透過 SMART 資料與唯讀磁碟檢查,評估 Debian/Ubuntu 上的 HDD 健康狀態.`v4.1.0` 版本包含檢查器與選用的本機 Web UI;GitHub 提供原始碼及預先建置的 Debian Web 安裝封存檔.Web 服務已在 Debian NAS 上以實際磁碟清單及通過身分驗證的 Security Settings 完成檢查,但實體 HDD 的完整評估與主機重新啟動後的服務復原仍未驗證.

## 多語言

[English](../../README.md) | [简体中文](../../README.md) | **繁體中文(台灣)** | [繁體中文(香港)](../zh-HK/README.md) | [हिन्दी](../hi/README.md) | [Español](../es/README.md) | [العربية](../ar/README.md) | [Français](../fr/README.md)

## 文件

- 專案概覽:[README](README.md)

- 設計考量:[DESIGN](DESIGN.md)

- 發行歷史:[LOG](LOG.md)

- 第三方聲明:[THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## 簡介

互動式選單或批次命令列可選取磁碟,快速評估 SMART,掛載狀態和核心紀錄,並提供啟發式 0–100 分數及風險等級.其他模組提供 SMART 短測/長測,抽樣讀速分析,可續掃的全碟讀取延遲掃描及選用的針對性 `badblocks` 複查,全碟唯讀 `badblocks`,以及維修後的介面讀取測試.對 HDD,完整評估執行快速檢查,短測,長測,速度和全碟唯讀掃描;對 SSD,執行快速檢查,短測,長測和全碟唯讀表面掃描,不取樣速度.兩者均不包含獨立的全碟 `badblocks` 或介面模組.結果可重複使用,與 SMART 計數器歷史比較並彙整為報告.請參閱[已知問題](LOG.md#錯誤)與[設計目標](DESIGN.md#設計目標).

完整評估在長時間讀取後再次檢查快速 SMART/ATA/CRC.只有同一未逾期評估批次中所需的快速檢查,短測,長測及完整表面掃描(以及 HDD 的速度取樣)都完成,才顯示 0–100 綜合分數.重複使用,中斷,逾期或舊格式結果仍作歷史證據顯示,但等級為部分/未知;檢視報告不更新比較基準.維修介面後,單獨進行介面驗證並重新完成完整評估,才能取得新分數.已解決的介面檢查不會抹除歷史錯誤.沒有先前比較值的 ATA 錯誤總數原因未明,扣 5 分,其未解決風險會在後續檢查和完整評估中保留;計數穩定本身不能證明風險解除.新增 ATA 錯誤扣 20 分;未變動的歷史計數不算新錯誤.現有介面驗證不能把 ATA 錯誤歸因於介面維修.零星慢讀提示重測效能,並非壞磁區證據;確認的讀取錯誤仍屬中等風險證據(表面扣 40 分).通電時長本身不扣健康分;ATA 接近閾值警告需要非零原始錯誤計數,缺乏原始依據的舊閾值提示標為待複查.檢查可疑磁碟前請備份重要資料.

**唯讀僅指目標磁碟資料,並非主機.** 程式會在主機寫入日誌,設定,進度及歷史紀錄;可能啟用 SMART,啟動磁碟內部自我測試,持續讀取整個裝置,經確認後安裝套件及啟動暫時性 systemd 單元.不能以此取代備份.本工具不執行具破壞性的寫入模式表面掃描,清除資料或寫入檔案系統.

## 需求

- 最低需求:root,Bash 4.3+,Linux 區塊裝置工具(`lsblk`,`blockdev`),`smartctl`(`smartmontools`),`dd`(`coreutils`)及 `flock`;預期使用平台為 Debian/Ubuntu.其他發行版會收到警告;自動安裝相依套件時使用 `apt-get`.
- 建議配備:用於磁碟表面檢查的 `badblocks`(`e2fsprogs`);用於分離執行工作的 systemd 與 `systemd-run`.缺少套件時,程式可能提供互動式 `apt-get update`/安裝選項(或透過 `-y` 自動確認).無人值守執行前請先檢查相依套件.專案未內附固定版本的第三方程式碼,亦不適用相依套件鎖定檔.
- 評估實體 HDD 健康狀態需要 HDD 與 SMART 存取權.可明確納入 SSD/NVMe.完成的 SSD 全面評估若 SMART 檢查,自我測試和全碟唯讀掃描均無異常,得分為 100;實際讀取錯誤和 SMART 異常會降低此啟發式分數.它不是經校準的故障機率.
## 安裝

### 快速安裝

從可信任的儲存庫檢出版本執行 `sudo bash ./hdd-health-check.sh --help`,在不啟動掃描的情況下查看選項.不要將未經檢查的遠端腳本直接導入 root shell 執行.

### 一般安裝

以下檢出 `v4.1.0` 發行標籤.儲存庫根目錄的命令只是簡短入口,實作位於 `src/checker/`.

```bash
git clone --branch v4.1.0 --depth 1 https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check
bash -n hdd-health-check.sh src/checker/hdd-health-check.sh
sudo bash ./hdd-health-check.sh --help
```

掃描前請自行檢查並安裝必要的作業系統套件,以免腳本提示安裝套件.若要升級既有的檢出版本,請先備份需要保留的主機日誌與 `${HDD_STATE_DIR:-/var/lib/hdd-health}`;接著以經過檢查的檢出版本替換腳本,保留該狀態目錄以供歷史紀錄/續掃使用,再查看 `--help` 並執行所選檢查.v2.2 的狀態解析僅接受已知資料欄位;先前不符合格式的 v2.2 狀態可能遭拒.回復舊版需還原先前的腳本**及其對應的狀態備份**;不要假設較新版本的狀態能向下相容.不保證相容 v1 命令列行為,也不提供 v1 狀態移轉.

### 從 v4.1.0 標籤安裝 Web UI

原始碼標籤不追蹤 `dist/web` 內產生的資源.在 Debian systemd 主機安裝 Node.js 20.19+ 或 22.12+ 及 npm,建置介面,然後執行安裝程式.GitHub Release 另提供預先建置的 Web 封存檔,在 NAS 安裝時無需 Node.js.

```bash
git clone --branch v4.1.0 --depth 1 https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/src/web
npm ci
npm run build
cd ../..
sudo bash deploy/install.sh
```

安裝程式會檢查並安裝缺少的 Debian 執行相依套件,在區域網路 8765 埠啟動受密碼保護的服務,但不會啟動磁碟掃描.使用 `sudo cat /root/apps/hdd-health-check/web-password` 查看產生的密碼.Node.js 僅用於建置介面.更新,安全邊界及復原說明請參閱 [WEB](WEB.md).

## 指南

只對您獲授權檢查的磁碟執行;持續讀取掃描可能造成顯著負載.以下指令**僅為範例,並非要求在此環境驗證**:

```bash
sudo bash ./hdd-health-check.sh                 # 終端機選單
sudo bash ./hdd-health-check.sh -a              # 所有機械硬碟,預設快速檢查
sudo bash ./hdd-health-check.sh -d sdb -r quick,short
sudo bash ./hdd-health-check.sh -d sdb -r full -y
sudo bash ./hdd-health-check.sh -d sdb -r iface --duration 30 --detach
sudo bash ./hdd-health-check.sh --status
sudo bash ./hdd-health-check.sh --stop
```

`-d/--disk` 接受以逗號分隔的裝置名稱;`-a/--all` 選取機械式磁碟,`--include-ssd` 則擴大選取範圍.`-r/--run` 接受 `quick,short,long,speed,surface,badblocks,iface,full`;預設為 `quick`,批次模式一律另行產生報告.`--duration` 設定介面測試分鐘數(預設 15 分鐘).`--rescan` 會重新開始,而非重複使用或續接先前結果;預設情況下,批次快速檢查會重新執行,其他結果在有效期間內會重複使用,中斷的磁碟表面掃描則會續掃.`-q/--quiet` 會抑制終端機輸出,**不會停止寫入日誌**;`-y/--yes` 會自動確認提示,包括安裝套件.`--detach` 需要批次模式及可用的 `systemd-run`;符合條件的互動式長時間工作,在終端機中斷連線時也可能交由 systemd 執行.`--stop` 會要求安全停止並保留磁碟表面掃描進度,但**不會**取消磁碟內部的 SMART 自我測試.`-l/--log FILE` 變更日誌路徑;`HDD_LOG_DIR` 與 `HDD_STATE_DIR` 可覆寫預設目錄.`NO_COLOR` 停用色彩;`HDD_NO_BG` 停用互動式工作自動轉為背景執行.選單設定儲存在狀態目錄中.

解析器也會將 `-t short|long` 對應至相應的自我測試,`-s` 對應至速度測試,`-b` 對應至 badblocks;**`-w/--wait` 會被忽略**,不會等待測試完成.這些別名不提供 v1 行為.請以已安裝腳本的 `--help` 查看選項.

結束代碼:`0` 全部健康;`1` 注意/警告;`2` 危險;`3` 執行階段錯誤.日誌預設寫入 `/var/log/disk-health/hdd-health-<timestamp>.log`;狀態預設寫入 `/var/lib/hdd-health`.主機寫入行為與操作邊界詳見[設計文件](DESIGN.md#資料設計).

## 升級

就目前原始碼布局而言,更新檢出目錄,在 `src/web` 中建置,然後從儲存庫根目錄執行 `sudo bash deploy/install.sh`.安裝程式將 `src/checker/hdd-health-check.sh`,`src/web/server.py` 和 `dist/web` 複製到既有服務布局,保留 Web 密碼,並備份帶時間戳記的程式與服務單元.以 root 執行前先檢查變更.歷史 `v3.0.0` 標籤仍保留原本的 `web/` 原始碼布局及其安裝說明.

## 解除安裝

- 移除儲存庫檢出目錄或已安裝的腳本, 即可移除命令列工具而保留日誌與歷史紀錄. 命令列工具不會永久安裝 systemd 服務; 若已安裝選用的 Web 服務, 請先依照 [WEB](WEB.md) 停止並停用服務. 移除腳本前請檢查是否有執行中的暫時性工作.
- 如需完整移除,請先停止所有工作並備份欲保留的紀錄,再確認路徑及內容後,手動刪除設定的 `HDD_STATE_DIR`(預設 `/var/lib/hdd-health`)和 `HDD_LOG_DIR`(預設 `/var/log/disk-health`).這會刪除報告,進度,歷史紀錄,修復註記與日誌;切勿不經確認就刪除共用目錄或覆寫後的目錄.透過 `apt-get` 安裝的套件不會自動移除.

## 致謝

第三方程式碼和字型的致謝列於 [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md).

## 授權條款

MIT(SPDX: MIT);請參閱 [LICENSE](../../LICENSE).

## 目前固態硬碟評估與操作

固態硬碟和 NVMe 的完整評估包含 SMART 快速檢查,短測,長測及全碟唯讀掃描,不取樣速度.單純慢讀不扣健康分;無異常而完成的批次得 100 分,SMART 異常或實際讀取錯誤可能降低啟發式分數.批次控制顯示所選磁碟支援的項目聯集;僅適用於 HDD 的項目會跳過選取的 SSD.點擊容量及主機寫入量可切換十進位與二進位單位.SATA HDD 可在 SMART 詳細資料中單獨喚醒或進入待機.
