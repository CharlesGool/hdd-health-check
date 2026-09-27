---
name: web-guide-zh-tw
description: 本機 Web UI 的設定與操作
metadata:
  version: "0.1.0"
  lang: zh-TW
---

# 本機 Web UI

Web UI 顯示本機磁碟結果, 最近的 SMART 計數器歷史紀錄, 執行中的工作及可設定的快速檢查排程. 它透過現有的 Bash 工具啟動所選檢查. 部分結果或已過期結果不會成為目前分數. 只有同批次完整且未過期的評估才能顯示數字分數.

關注卡片直接顯示檢查原因.通電時長僅供參考,不單獨扣分;舊版缺少原始錯誤計數的閾值提示改為待複查.檢查確認使用頁面內對話框,詳情以型號為標題,裝置路徑在下.

## 需求

- Debian 或 Ubuntu, Python 3.10+, 與專案 Vite 版本相容的 Node.js, systemd 及 `systemd-run`.
- 現有檢查器所需的 `smartmontools`, `util-linux`, `coreutils`, 以及可選的 `e2fsprogs` (供 badblocks 使用).
- Web 頁面以密碼登入,API 使用會話;僅在可信區域網路使用 TCP 8765,HTTP 不會加密密碼.

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

## 建置與執行

在 Debian NAS 解壓已建置的測試檔,進入解壓目錄後執行:

```bash
sudo bash deploy/install.sh
```

安裝後開啟 `http://<NAS-IP>:8765`,在網頁登入頁輸入由 `sudo cat /root/apps/hdd-health-check/web-password` 讀取的密碼.安裝器保留原有密碼,並備份舊程式與服務單元;NAS 不需要 Node.js.

在可信任的檢出目錄中:

```bash
cd web
npm ci
npm run build
cd ..
sudo python3 web/server.py --port 8765
```

開啟 `http://127.0.0.1:8765`. Python 程序提供建置後的 UI, 執行期間不需要 Node. 請將原始碼檢出目錄與 `web/dist` 保持在一起. `npm run dev` 會在另一個本機連接埠執行 Vite, 並將 `/api` 轉送至 Python 服務.

常駐服務請使用上述安裝器;systemd 單元需要安裝器產生的密碼檔案.

若要移除 Web 服務, 執行 `sudo systemctl disable --now hdd-health-web.service`, 移除已安裝的服務單元檔案, 再執行 `sudo systemctl daemon-reload`. 移除檢出目錄前, 請檢查是否有執行中的暫時性檢查工作. 狀態與日誌應依命令列工具的解除安裝指引, 另外決定保留或刪除.

Codex 的 `site-preview` 位址只提供靜態檔案.它可顯示介面及內建的更新紀錄,但沒有 `/api` 後端,無法顯示磁碟或啟動檢查.查看實際資料時,請開啟上述 Python 服務位址.從另一台電腦存取 NAS 時,可在該電腦執行 `ssh -L 8765:127.0.0.1:8765 user@nas-host`,再開啟 `http://127.0.0.1:8765`.

## 行為與邊界

- 自動快速檢查預設停用. 啟用後每隔 6-168 小時檢查一次. 若先前未排程檢查, 首次檢查會在啟用後不久開始. 排程只針對機械硬碟, 並透過暫時性的 systemd 單元啟動.
- 手動檢查按磁碟選取. 深度檢查只適用於機械硬碟; 明確列出的 SSD 只能執行快速檢查. 工具仍可能啟用 SMART 或啟動磁碟內部自我測試. 安全停止會保留表面掃描進度, 但不會取消磁碟內部的自我測試.
- `--no-install` 阻止 Web 服務在啟動工作時同意安裝套件. 請另外安裝缺少的依賴套件. Web 服務只接受固定的檢查名稱及目前列出的裝置, 而且不使用 shell 組成命令.
- 私有狀態目錄預設仍為 `/var/lib/hdd-health`, 日誌仍位於 `/var/log/disk-health`. `web-schedule.json` 以 600 權限儲存在狀態目錄. 瀏覽器透過同源 JSON API 查看健康結果及近期歷史紀錄.
- 服務檢查 Host 與 Origin;API 需要密碼會話或允許的來源 IPv4.只有密碼會話可以修改 IP 名單.請勿將連接埠開放至網際網路.
- 控制項提供專案支援的八種語言. 詳細檢查摘要與即時工作日誌來自現有的中文 Bash 檢查器, 因此不論選擇哪種介面語言, 這些內容目前仍以中文顯示.

## API

`GET /api/snapshot` 傳回檢查器的結構化磁碟快照. `GET /api/status` 傳回執行中工作的顯示資料. `GET /api/history/<device>` 傳回最多 30 筆 SMART 計數器紀錄. `GET` 與 `POST /api/schedule` 管理快速檢查間隔. `POST /api/jobs` 對已列出的裝置啟動指定檢查; `POST /api/jobs/stop` 要求安全停止. 未知 API 路由傳回 404. 檢查器的 `--json` 輸出是評分來源; Web 服務不會重新計算分數.

SMART 明確確認休眠時,清單與詳情顯示"休眠中";讀取中的溫度顯示"讀取中",讀取失敗仍為未知.喚醒策略保存在 `/var/lib/hdd-health/web-preferences.json`,預設關閉.任何已登入使用者都可編輯 IP 名單及休眠策略;變更密碼仍需目前密碼.

## 介面與權限

頂部依次顯示儀表板,更新紀錄及設定.儀表板在磁碟,需要關注,執行工作(包括歷史紀錄)及定時巡檢頁面保持啟用;在這些頁面點選儀表板不會改變目前頁面,只有從設定或更新紀錄點選時才返回 `/disks`.左上角 Logo 一直連結到 `/disks`.四張概覽卡分別開啟 `/disks`,`/attention`,`/tasks`,`/schedule`;一鍵評估留在磁碟首頁.更新紀錄入口開啟可直接存取的獨立 `/changelog` 頁面.

左上角的 HDD Health 專案名稱連至 `/disks` 磁碟首頁.瀏覽器分頁使用 `web/public/favicon.svg` 的專案圖示, 並隨正式建置提供.

設定頁管理外觀,精確 IPv4 免密名單,硬碟休眠策略與登入密碼.已進入頁面的使用者可直接編輯 IP 名單及休眠策略;透過 IP 免密進入時也直接顯示變更密碼表單,提交時由伺服器驗證目前密碼.預設維持機械硬碟休眠,也可選擇開啟頁面時逐顆喚醒並讀取溫度.磁碟詳情提供 SMART 資訊和檢查分頁;更新紀錄在獨立頁面以 Markdown 顯示.

首頁的一鍵評估可分別選擇磁碟範圍及檢測項目.範圍包括 SATA,機械硬碟,固態硬碟,NVMe 或全部磁碟;項目包括快速檢查,SMART 短/長自檢,速度,盤面,badblocks,介面複查及完整評估.服務端按目前列舉結果選碟,在背景執行所選項目.只有完整評估可能產生目前綜合分數;SSD/NVMe 評分仍沿用機械硬碟規則,未另行校準.清單依傳輸協定及介質類型顯示 SATA SSD,NVMe SSD 等,並在背景讀取可用溫度,避免喚醒休眠硬碟.詳情頁只在裝置明確回報時顯示外形規格;不能僅憑 NVMe 或 SATA 判定是否為 M.2.SATA 版本與速率來自 smartctl 或 Linux sysfs;NVMe 的 PCIe 代數,通道數及鏈路速率來自 sysfs.按通電時間可切換小時與年/天/小時.

需要關注卡片篩出有警告或異常紀錄的磁碟.檢查詳情列出原因與扣分;舊紀錄沒有儲存原因時提示重新檢查.工作頁保留執行中的工作與可展開的詳細日誌,另設最近 30 筆工作歷史;結束後從執行區清除收據,並在 `web-job-history/` 保存新收據,保留磁碟檢查結果與主機日誌.返回碼 1 或 2 表示檢查完成但發現問題.

主頁彙總實體硬碟總容量和已掛載檔案系統的已用量,按檔案系統 UUID 去重;RAID,未掛載磁碟區可能造成兩者口徑不同.SSD 的 SMART 詳情優先顯示 NVMe 標準寫入量,或具有明確邏輯磁區大小的 ATA 裝置統計寫入量;不猜測廠商自訂計數的單位.;可識別的 ZFS 儲存池配置空間也計入已用量.容量按鈕可切換 TB/TiB,查看詳情由獨立按鈕開啟.

工作頁保留執行中的工作,另設歷史紀錄,列出最近 30 筆已完成,停止或失敗的 Web 工作,並可查看仍存在的詳細日誌末尾.新收據保存在 `web-job-history/`;已刪除的舊收據無法可靠還原.頂部儀表板在磁碟,需要關注,執行工作及定時巡檢頁面維持啟用.
