---
name: web-guide-zh-hk
description: 本機 Web UI 的設定及操作
metadata:
  version: "0.1.0"
  lang: zh-HK
---

# 本機 Web UI

Web UI 顯示本機磁碟結果, 最近的 SMART 計數器歷史紀錄, 執行中的工作及可設定的快速檢查排程. 它透過現有 Bash 工具啟動所選檢查. 部分結果或已過期結果不會成為目前分數. 只有同一批次完整且未過期的評估才能顯示數字分數.

關注卡片直接顯示檢查原因.通電時長僅供參考,不單獨扣分;舊版缺少原始錯誤計數的閾值提示改為待覆核.檢查確認使用頁面內對話框,詳情以型號為標題,裝置路徑在下.

## 多語言

[English](../WEB.md) | [简体中文](../zh-CN/WEB.md) | [繁體中文 (台灣)](../zh-TW/WEB.md) | **繁體中文 (香港)** | [हिन्दी](../hi/WEB.md) | [Español](../es/WEB.md) | [العربية](../ar/WEB.md) | [Français](../fr/WEB.md)

## 文件

- 項目概覽: [README](README.md)

- 設計理據: [DESIGN](DESIGN.md)

- 版本紀錄: [LOG](LOG.md)

- 第三方項目清單: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

- Web UI 指南: [WEB](WEB.md)
## 需求

- Debian 或 Ubuntu,Python 3.10+,與儲存庫內 Vite 版本相容的 Node.js,systemd 及 `systemd-run`.
- 既有檢查器依賴:`smartmontools`,`util-linux`,`coreutils`,以及供 badblocks 使用的選用 `e2fsprogs`.
- Web 服務需要 root 權限.Debian 安裝程式在 IPv4 8765 埠監聽,為 API 提供網頁登入及會話.在相同的可信區域網路存取 `http://<NAS-IP>:8765`;不要將此埠轉送至互聯網.區域網路 HTTP 不會加密密碼;需要加密傳輸時可使用 SSH 本機埠轉送.

## 建置及執行

目前原始碼將 Web UI 程式碼放在 `src/web/`,不追蹤產生的 `dist/web/` 建置結果.歷史 `v3.0.0` 標籤保留原有的 `web/` 布局.在 Debian systemd 主機安裝 Node.js 20.19+ 或 22.12+ 及 npm,建置 UI,然後執行安裝程式:

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/src/web
npm ci
npm run build
cd ../..
sudo bash deploy/install.sh
```

更新檢出目錄後再次執行建置及安裝步驟.Node.js 僅在建置時需要;安裝後的服務使用 Python 和檢查器依賴.以 root 執行前先審查 `deploy/install.sh`.

使用預先建置的 Debian NAS 封存檔時,解壓並進入其目錄,然後執行:

```bash
sudo bash deploy/install.sh
```

安裝程式檢查 Debian,systemd,Python 3.10+,套件檔案及 8765 埠;透過 apt 安裝缺少的套件;將檢查器及建置後的 UI 複製到 `/root/apps/hdd-health-check`;啟用並檢查 `hdd-health-web.service`.它不會啟動磁碟掃描.更新時,安裝程式把舊應用程式和服務單元保存為帶時間戳記的備份,啟動失敗時嘗試還原.它不修改既有磁碟狀態或日誌.預建封存檔在 NAS 上不需要 Node.js 或前端建置.

安裝後,從相同區域網路的電腦開啟 `http://<NAS-IP>:8765`.登入頁要求輸入產生的密碼.在 NAS 執行 `sudo cat /root/apps/hdd-health-check/web-password` 查看;更新時安裝程式會保留它.密碼檔只有 root 可讀.Security Settings 在顯示 IP 清單或密碼變更表單前要求管理員密碼.驗證後,可在五分鐘權限時段內輸入並確認 12–128 字元的新密碼,毋須再次輸入舊密碼.變更令所有 Web 會話失效,須重新登入.若頁面無法開啟,檢查 `sudo systemctl status hdd-health-web.service` 及 NAS 防火牆是否容許區域網路 TCP 8765.安裝程式不修改防火牆規則.

日後可用 `sudo systemctl status hdd-health-web.service` 查看服務狀態.以下手動建置與執行步驟供開發或沒有預建封存檔時使用.

從可信的檢出目錄執行:

```bash
cd src/web
npm ci
npm run build
cd ../..
sudo python3 src/web/server.py --port 8765
```

開啟 `http://127.0.0.1:8765`.這個手動指令令服務只監聽回環位址,毋須密碼.Python 程序提供 UI 建置結果;執行時不需要 Node.請讓原始碼檢出目錄與其 `dist/web` 保持在一起.`npm run dev` 在另一個本機埠執行 Vite,並將 `/api` 代理到 Python 服務.

Codex `site-preview` 位址只提供靜態檔案.它可顯示布局及打包的更新紀錄,但沒有 `/api` 後端,不能顯示磁碟或執行檢查.即時資料應開啟上述 Python 服務位址.從另一部電腦加密存取時,使用 `ssh -L 8765:127.0.0.1:8765 user@nas-host` 轉送 NAS 回環埠,然後在該電腦開啟 `http://127.0.0.1:8765`.透過隧道存取安裝程式部署的服務時仍須密碼登入.

常駐服務請使用上述安裝程式:其 systemd 單元需要安裝時建立的密碼檔.升級前請以對應的腳本版本備份 `/var/lib/hdd-health`.Web UI 不改變腳本的狀態遷移政策.

移除 Web 服務時,執行 `sudo systemctl disable --now hdd-health-web.service`,刪除已安裝的單元檔案,再執行 `sudo systemctl daemon-reload`.刪除檢出目錄前,檢查仍在執行的暫時性工作.狀態及日誌按 CLI 解除安裝說明另行保留或刪除.

## 行為及邊界

- 自動快速檢查預設關閉.啟用後每 6–168 小時執行一次;若先前沒有排定檢查,首次檢查在啟用後不久開始.排程只涵蓋機械硬碟,並透過暫時性 systemd 單元啟動.
- 手動檢查按磁碟選擇.單碟控制亦為 SSD 提供快速檢查,SMART 短測/長測,全碟唯讀掃描及完整評估.批次控制顯示所選磁碟支援項目的聯集;混合 HDD/SSD 選取中,僅適用於 HDD 的項目只在合資格 HDD 上執行,跳過 SSD.只選 SSD 時僅提供其支援的檢查.網頁把兩種媒體的全裝置唯讀檢查清楚標為"全碟唯讀掃描".工具仍可能啟用 SMART 或啟動磁碟內部自我測試.安全停止保留表面掃描進度,但不會取消磁碟內部自我測試.
- Web 服務啟動工作時加入 `--no-install`,不批准安裝套件.缺少的依賴須另外安裝.服務只接受固定的檢查名稱及當時列舉的裝置,組成指令時不使用 shell.
- 私有狀態目錄預設仍為 `/var/lib/hdd-health`,日誌目錄為 `/var/log/disk-health`.`web-schedule.json`,`web-job.json`,`web-job-history/` 中已完成工作的收據,以及 `web-access.json` 中的私人位址允許清單和啟用開關,均以受限權限存放於私有狀態目錄.瀏覽器透過同源 JSON 端點查看健康結果及近期歷史.
- 安裝程式部署監聽所有 IPv4 位址,但只接受與目標 IP 和埠一致的 Host.它檢查 Origin,要求 API 請求有密碼會話或允許清單內的來源 IPv4 位址.靜態資源公開,讓登入頁可以載入.只有最近通過管理員密碼驗證的會話可讀取或編輯私人位址允許清單及其啟用開關;只靠 IP 進入僅可使用一般儀表板功能.登出時會設定瀏覽器 Cookie,抑制自動 IP 登入,直到使用者重新選擇 IP 登入.服務沒有 TLS;能查看區域網路 HTTP 流量的人可能看見密碼.只在可信區域網路或 SSH 隧道內使用,不要向互聯網開放 TCP 8765.手動執行 `python3 src/web/server.py` 時,除非提供 `--bind` 和 `--password-file`,否則仍只監聽回環位址.
- 介面控制支援項目的八種語言.詳細檢查摘要及即時工作日誌來自既有中文 Bash 檢查器,所以無論選擇哪種介面語言,這些內容目前仍是中文.

## API

`GET /api/auth` 回報登入狀態;`POST /api/auth/login`,`/api/auth/logout` 和 `/api/auth/ip-login` 管理會話.`POST /api/auth/security-verify` 檢查管理員密碼,輪換會話 Cookie,並授予固定五分鐘的 Security Settings 權限.`POST /api/auth/change-password` 需要該權限及相符的新密碼/確認欄位;它以原子方式取代 root 擁有的密碼檔,並令既有會話失效.`GET` 和 `POST /api/access` 需要相同的短時權限;可讀取或編輯啟用開關及精確的 RFC 1918 IPv4 或 IPv6 唯一本地位址.`GET` 和 `POST /api/preferences` 供已驗證訪客讀取及儲存是否在進入頁面時喚醒休眠磁碟.`POST /api/disks/wake-on-visit` 在背景啟動已選擇的喚醒操作.`GET /api/disks/<device>/smart` 按需讀取 SMART 詳情,不喚醒待機 HDD;已驗證的 `POST /api/disks/<device>/wake` 只喚醒目前列舉的機械硬碟.`GET /api/snapshot` 傳回檢查器的結構化磁碟快照.`GET /api/status` 傳回執行中工作的顯示資料及有界的即時日誌末尾.讀取狀態時,已完成,停止,失敗和失效的 Web 收據會從執行中顯示移除;已完成工作收據另行封存.`GET /api/jobs/history` 傳回所有封存 Web 工作摘要;主機日誌仍在時,`GET /api/jobs/history/<id>` 傳回有界日誌末尾.收據已刪除的舊工作無法可靠重建.`GET /api/history/<device>` 為相容性傳回最多 30 行 SMART 計數器.`GET /api/history/samples` 傳回所有已列舉磁碟的 SMART 趨勢樣本,供整合歷史頁使用.已驗證的 `DELETE /api/history/samples/<device>/<index>` 刪除一筆 SMART 樣本;若刪除最後一行,將改變下次比較基準.`DELETE /api/jobs/history/<id>` 刪除已完成 Web 工作收據及關聯日誌.`POST /api/disks/<device>/sleep` 只對目前列舉的 SATA HDD 要求 ATA 待機,檢查執行期間拒絕;正常的作業系統 I/O 可能再次喚醒它.`GET` 和 `POST /api/schedule` 管理快速檢查間隔.`POST /api/jobs` 在列舉裝置上啟動固定檢查;`POST /api/jobs/assess` 接受 `scope` 為 `sata`,`hdd`,`ssd`,`nvme` 或 `all`,以及 `module` 為 `quick`,`short`,`long`,`speed`,`surface`,`badblocks`,`iface` 或 `full`,為符合條件的已列舉磁碟啟動一個批次.`POST /api/jobs/stop` 要求安全停止.未知 API 路由傳回 404.檢查器的 `--json` 輸出是評分來源;Web 服務不重新計算分數.

## 介面與權限

專案名稱旁的獨立版本連結開啟更新紀錄;無標籤建置使用 `test-<sha>` 標記,工作樹有修改時追加 `-dirty`,`/api/build` 傳回建置時嵌入的版本.磁碟列表以型號為標題,另列 `/dev/` 路徑;磁碟詳情亦在標題下顯示 `/dev/` 路徑.儀表板溫度探測預設避免喚醒休眠硬碟;選用的喚醒程序逐碟確認待機狀態,再按順序讀取 SMART 屬性.無法以 `smartctl` 取得的健康欄位仍保持未知.

頂部依次顯示儀表板,更新紀錄及設定.儀表板在硬碟,需要關注,執行工作(包括歷史紀錄)及定時巡檢頁面保持啟用;在這些頁面按儀表板不會改變目前頁面,只有從設定或更新紀錄按下時才返回 `/disks`.左上角 Logo 一直連結到 `/disks`.四張概覽卡分別開啟 `/disks`,`/attention`,`/tasks`,`/schedule`;一鍵評估留在硬碟首頁.更新紀錄入口開啟可直接存取的獨立 `/changelog` 頁面.

左上角的 HDD Health 項目名稱連至 `/disks` 磁碟主頁.瀏覽器分頁使用 `src/web/public/favicon.svg` 的項目圖示,並隨正式建置提供.公開快照省略可能包含序號的內部磁碟 ID;快照與 SMART API 只傳送遮蔽的序號.使用者按下顯示控制後,SMART 詳情透過獨立且經驗證的請求取得完整序號;隱藏或關閉詳情時清除它.

一般設定頁提供語言,八種強調色及淺色/深色模式切換,以及硬碟休眠政策與獨立的 Security Settings 頁面連結.強調色及明暗模式分別儲存,重新載入後仍保留選擇.沒有短時驗證權限時,安全頁先要求管理員密碼;驗證後才顯示私人地址允許名單,啟用開關及密碼修改表單.只透過 IP 進入的訪客可使用一般磁碟及休眠政策控制,但須驗證管理員密碼才能開啟受保護的安全頁.修改密碼令所有 Web 會話失效,須重新登入.預設維持機械硬碟休眠,亦可選擇開啟頁面時逐個喚醒並讀取溫度.硬碟詳情提供 SMART 資訊及檢查分頁;更新紀錄在獨立的 `/changelog` 頁面以 Markdown 顯示.

主頁的一鍵評估可分別選擇磁碟範圍及檢測項目.範圍包括 SATA,機械硬碟,固態硬碟,NVMe 或全部磁碟;項目包括快速檢查,SMART 短/長自檢,速度,盤面,badblocks,介面複查及完整評估.服務端按目前列舉結果選碟,在背景執行 `<module> --rescan` 批次.只有 `full` 完整評估可能產生目前綜合分數;SSD/NVMe 評分未有個別校準;SSD 慢讀不扣健康分,無異常完成的批次得 100 分,SMART 異常或實際讀取錯誤可降低啟發式分數.清單按傳輸協定及介質類型顯示 SATA SSD,NVMe SSD 等,並在背景讀取可用溫度,預設以 `smartctl -n standby` 避免喚醒休眠硬碟;啟用喚醒政策後,工作程序先以 `-n standby` 逐碟確認待機狀態.詳情頁只在裝置明確回報時顯示外形規格;不能僅憑 NVMe 或 SATA 判定是否為 M.2.SATA 版本及速率來自 smartctl 或 Linux sysfs;NVMe 的 PCIe 代數,通道數及鏈路速率來自 sysfs.按通電時間可切換小時與年/天/小時.

需要關注卡片篩出有警告或異常紀錄的硬碟.檢查詳情列出原因及扣分;舊紀錄沒有儲存原因時提示重新檢查.工作頁保留執行中的工作及可展開的詳細日誌,另設最近 30 筆工作歷史;結束後從執行區清除收據,並在工作封存目錄保存新收據,保留硬碟檢查結果及主機日誌.返回碼 1 或 2 表示檢查完成但發現問題.

主頁彙總實體硬碟總容量和已掛載檔案系統的已用量,按檔案系統 UUID 去重;RAID,未掛載磁碟區可能令兩者口徑不同.SSD 的 SMART 詳情優先顯示 NVMe 標準寫入量,或具有明確邏輯磁區大小的 ATA 裝置統計寫入量;不猜測廠商自訂計數的單位.;可識別的 ZFS 儲存池配置空間亦計入已用量.容量按鈕可切換 TB/TiB,查看詳情由獨立按鈕開啟.

工作頁保留執行中的工作,另設歷史紀錄,列出最近 30 筆已完成,停止或失敗的 Web 工作,並可查看仍存在的詳細日誌末尾.新收據保存在 工作封存目錄;已刪除的舊收據無法可靠還原.頂部儀表板在硬碟,需要關注,執行工作及定時巡檢頁面保持啟用.

## 目前固態硬碟評估與操作

固態硬碟及 NVMe 的完整評估包括 SMART 快檢,短測,長測及全碟唯讀掃描,不執行速度取樣.單純慢讀不扣健康分;同一批次全部檢查完成而且沒有異常時顯示 100 分,SMART 異常或實際讀取錯誤可能扣分.選取範圍包含固態硬碟時,網頁只提供快速檢查,短測,長測,唯讀掃描及完整評估.按容量或固態硬碟累計寫入量可切換十進制與二進制單位.休眠中的機械硬碟可在 SMART 詳情中單獨喚醒.
