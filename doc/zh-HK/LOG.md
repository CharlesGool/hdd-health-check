---
name: project-log-zh-hk
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: zh-HK
---

# hdd-health-check — 紀錄

本文記錄已採納的歷史決策,已知限制及發佈歷史.目前的大版本為 `v4.1.0`.用戶表示較早的 `v2.2.0` 曾在實機運行,但未提供裝置,環境或測試範圍.修訂後的評分已有模擬測試及 Debian NAS 上的 Web 驗證,但尚未在真實 HDD 上完成受控的完整評估.

## 多語言

[English](../LOG.md) | [简体中文](../zh-CN/LOG.md) | [繁體中文(台灣)](../zh-TW/LOG.md) | **繁體中文(香港)** | [हिन्दी](../hi/LOG.md) | [Español](../es/LOG.md) | [العربية](../ar/LOG.md) | [Français](../fr/LOG.md)

## 文件

- 項目概覽:[README](README.md)

- 設計理據:[DESIGN](DESIGN.md)

- 發佈歷史:[LOG](LOG.md)

- 第三方聲明:[THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

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

2026-09-29.分支 `main`;正式版 `v4.1.0` 已從 `09e6fa5` 發佈並部署到 Debian NAS.未發現項目臨時規則.

- NAS 安裝程式後續檢查:首次安裝 `test-bf14ed5` 時新服務已啟動,但健康檢查因缺少 `X-HDD-CSRF` 請求標頭收到 HTTP 403;其 `die` 報錯路徑亦沒有觸發回復.`cd7d69b` 修正標頭與回復.重新安裝 `test-cd7d69b` 後,健康檢查通過,服務於 `0.0.0.0:8765` 運行並已設為開機啟用.安裝程式保留舊應用程式及服務單元備份;Web 密碼與舊備份一致,`/var/lib/hdd-health` 及 `/var/log/disk-health` 保持原狀.

- 已完成:原始碼整理至 `src/checker/` 及 `src/web/`,產生的 Web 檔案移至 `dist/web/`;保留根目錄 CLI 相容入口,更新安裝程式及測試路徑,統一語言目錄及文件導覽.原始碼安裝沿用既有 Debian 服務目錄.一般設定提供八種主題色與明暗模式,獨立儲存選擇;頂部導覽使用真正的 Changelog 連結.
- 安全:獨立的 Security Settings 頁面由伺服器執行五分鐘管理員密碼驗證時段.驗證會輪換工作階段;僅憑 IP 進入的工作階段不能讀取或修改名單與密碼.時段內修改密碼只需新密碼及確認,並令所有工作階段失效.IP 免密可啟用或停用,只接受精確的 RFC 1918 IPv4 或 ULA IPv6 位址,拒絕不合規的舊項目;依連線對端而非用戶端轉送標頭判定來源,並檢查原始 Host/Origin 及修改請求的同源標頭.
- 私隱及版本:快照及 SMART 回應遮蔽序號;只有使用者明確操作時,才經已驗證請求取得完整序號,隱藏或關閉檢視時清除.項目名稱旁的版本連結開啟 Changelog;無標籤建置使用 `test-<sha>` 標記,`/api/build` 傳回相同值.
- 評估行為:SSD/NVMe 完整評估執行 SMART 快檢,短測,長測及全碟唯讀掃描,不作速度取樣.完整而無異常的批次得 100 分;單純慢讀不扣分.批次選項依所選磁碟類型提供支援的檢查.容量及 SSD 主機寫入量可切換十進位/二進位單位;休眠 HDD 可逐一喚醒.模擬測試通過,此次未啟動真實磁碟完整評估.
- 檢查:Vue 類型檢查及正式建置,全部 Shell 及 Python Web 測試,八種主題色兩種模式的檢查,多語言,文件格式(0 個錯誤,8 個警告),本機連結及項目結構檢查均通過.Shell 語法,Python 編譯及 `git diff --check` 通過.本機 Chromium 在 390 px 無橫向溢出,可顯示 Security Settings 及深色設定;直接開啟 Changelog 時先顯示 v3.0.0.隔離瀏覽器環境沒有檢查器,磁碟狀態請求按預期傳回 503.原始碼封存檔建置使用 `test-archive-<package version>` 標記,不顯示為正式版本.
- NAS 驗證:安裝後的 `/api/build` 與 `test-cd7d69b` 一致.密碼登入,未驗證的安全設定拒絕,管理員驗證,工作階段輪換,受保護名單讀取及 13 隻磁碟快照的序號遮蔽均通過.局域網安全頁面與 favicon 傳回 HTTP 200;未驗證的普通及受保護 API 請求傳回 401.已登入的 Chromium 開啟安全頁面,顯示已儲存的 IP 控件及修改密碼表單;390 px 下頁面寬度等於視口寬度.瀏覽器工作階段與本機暫存密碼檔已清理.未進行磁碟掃描,密碼修改或重啟;已安裝的測試建置不是正式版本.
- 發佈時狀態:實機重啟後的服務復原及真實 HDD 的受控完整評估仍未驗證.根目錄兼容入口及搬遷前基線記錄於限制章節.發佈時 NAS 運行 `test-cd7d69b`;該發佈工作沒有部署正式建置.
- 發佈:`main` 及 `feat/standards-alignment` 已推送至 `3cf9da0`.附註標籤 `v4.0.0` 指向該提交;正式 GitHub Release 包含 6,697,392 位元組的預建 Web 封存檔及 `SHA256SUMS`;封存檔的 SHA-256 為 `491a0c61a99525f9a293b1b49c2de500e47c7b60e20bad5c4e955ecc048121d4`.已匯出 `../snapshots/v4.0.0` 原始碼快照,並在 `My Projects` 下的項目 Notion 子頁面確認完整 Changelog.
- 發佈檢查:所有 Shell 及 Python 測試,Vue 類型檢查,正式建置,文件及連結檢查,多語言及項目結構檢查均通過.從準確的 `v4.0.0` 標籤建置的產物提供 `/api/build`,`version.json`,首頁及深層路由和 favicon,中繼資料均符合 `v4.0.0`.文件檢查報告 0 個錯誤及 8 個現有的英文警告.此次發佈未執行真實磁碟掃描,未修改密碼,亦未重啟.
- 翻譯復原:依照已記錄的復原規則,七種語言的核心文件譯文已與現時英文同步,包括交接及提交歷史.結構及受保護 token 檢查通過;英文發佈文件及譯文一同提交.
- Web 設計標準化:登入頁頁首及卡片現採用共用尺寸.登入卡片底部提供建置版本的 Changelog 連結及登入前可用的語言選擇器.登入密碼,管理員驗證密碼,新密碼及確認密碼欄位預設遮蔽輸入內容,各有獨立而附標籤的顯示/隱藏按鈕,觸控區域為 44 px.按鈕保留輸入值且不移動焦點;語言及密碼按鈕標籤涵蓋全部八種 UI 語言.此次改動未部署至 NAS.
- Web 檢查:在獨立的本機建置目錄中通過 Vue 類型檢查及正式建置.本機 Chromium 中,登入頁在 1280 px 及 320 px 下均無整頁橫向溢出;已檢查中文及阿拉伯文登入版面,英文語言偏好的持續儲存,登入失敗訊息,登入密碼顯示切換,以及新密碼及確認密碼的獨立切換.隔離伺服器未以 root 運行檢查器,因此無法讀取真實磁碟資料;該預期 API 錯誤不在登入版面檢查範圍內.文件及項目檢查隨此次交接提交記錄.
- Changelog 導覽後續修復:登入卡片的版本連結現讓未驗證的訪客開啟隨程式提供的 Changelog;該頁在品牌名稱旁顯示所連結的版本,並提供附標籤的 Changelog 導覽項目.本機 Chromium 點擊版本連結,顯示 v4.0.0 項目,再返回登入頁.未驗證的 `/api/build`,`/api/access` 及 `/api/snapshot` 請求仍傳回 401.此改動後 Vue 類型檢查及正式建置通過.
- NAS UI 部署:在乾淨的本機檢出中將現時 `main` 提交 `2e6201e` 建置為 `test-2e6201e`.Vue 類型檢查及正式建置通過,傳輸的封存檔校驗和一致.Debian 安裝程式升級了端口 8765 上現有的局域網服務,保留 Web 密碼及附時間標記的應用程式及服務單元備份.服務運行中並已設為開機啟用;現有狀態及日誌目錄保持原狀.經驗證的 `/api/build` 傳回 `test-2e6201e`,`/api/snapshot` 列出 13 隻磁碟;局域網磁碟頁及 Changelog 頁傳回 HTTP 200,未驗證的 `/api/build` 傳回 401.局域網 Chromium 顯示更新後的登入頁及其版本連結和語言選擇器,再透過版本連結開啟 v4.0.0 Changelog 項目.未執行磁碟掃描,未修改密碼,亦未重啟.
- 版本與 Changelog 後續:將 v4.0.0 之後的 Web 變更寫入英文 Changelog 和全部七種譯文,並將舊 Handoff 和 Commit History 同步到提交 `3c3451f` 對應的英文源文.乾淨構建嵌入 `test-3c3451f`;Vue 類型檢查和生產構建通過.多語言,項目結構,文檔格式,本機連結和 diff 檢查均通過;格式檢查報告英文導航中語言名稱的一個既有警告.傳輸包的校驗和匹配.NAS 安裝器保留 Web 密碼,應用和服務單元備份,以及已有的狀態和日誌目錄.服務在 8765 端口處於活動且已啓用狀態;認證後的 `/api/build` 返回 `test-3c3451f`,`/api/snapshot` 列出 13 塊磁碟,局域網磁碟頁及 Changelog 頁返回 HTTP 200,未認證的 `/api/build` 返回 401.局域網 Chromium 在登入卡片及 Changelog 頁面看到相同版本,新增簡體中文條目位於 v4.0.0 之前.未執行磁碟掃描,密碼修改或重啓.
- `main` 上的 Web 設計標準化:認證後頁眉按規定順序顯示帶連結的項目名/版本以及首頁,Changelog,設置和退出登入;各子頁面均有返回控制項.設置和受保護的安全設置採用響應式分區導航,各路由使用不同且匹配的 favicon,登入卡片始終提供 IP 存取操作並在服務端拒絕時顯示錯誤.外觀設置包含 Beta 頁面過渡開關,選擇會持久儲存,移動設備默認關閉;瀏覽器歷史,視口尺寸變化及減少動態效果分別處理.所有八種 Web 界面語言在本機化候選版 Changelog 頂部顯示準確的測試構建標識,其後才是正式版本;英文 Changelog 不再有未標版本的發佈後章節.既有 `v4.0.0` 標籤和 Release 均未更改.
- 本次 Web 變更的本機驗證:隔離構建樹中的 Vue 類型檢查和生產構建通過.Chromium 檢查了桌面和 390 px 下的設置及安全設置佈局,各語言位於 `v4.0.0` 之前的候選條目,favicon 切換,瀏覽器後退/前進,關閉頁面動畫時不調用 View Transitions,啓用動畫的路徑,以及從 320 至 1280 px 反覆調整尺寸時沒有橫向溢出或殘留變換.多語言和項目結構檢查通過;文檔及本機連結檢查無錯誤,所查三份英文文檔有五個格式警告.未在真實移動瀏覽器中檢查視覺過渡.
- 部署 `test-c7b6252` 到 NAS:提交 `c7b6252` 的乾淨檢出通過 Vue 類型檢查和生產構建;`version.json` 嵌入相同測試標識.傳輸包的 SHA-256 為 `afe858f9ba2a9e8ea19964bc98382f4068085fd5b042fb76f971fc3e54bc6ceb`,校驗匹配.安裝器升級 `/root/apps/hdd-health-check` 中 8765 端口的局域網服務,Web 密碼未變,保留應用備份 `/root/apps/hdd-health-check.backup-20260929-012509-2525461` 及匹配的服務單元備份.已有 `/var/lib/hdd-health` 和 `/var/log/disk-health` 未被安裝包修改.服務在 systemd 下處於活動且已啓用狀態,監聽 `0.0.0.0:8765`;未重啓主機.認證後的 `/api/build` 返回 `test-c7b6252`;退出後 `/api/build` 返回 401.磁碟,設置,安全設置和 Changelog 局域網頁面及圖標資源返回 HTTP 200;未認證的 `/api/build` 返回 401.實時 Chromium 顯示登入卡片版本,始終可見的 IP 操作及地址被拒說明,隨後打開準確的測試版 Changelog 條目及 `v4.0.0`;390 px 下無橫向溢出.未執行磁碟掃描,密碼修改或重啓;未發現項目臨時規則.
- `main` 上的 Web UI 參考設計 v1.2.3 遷移:將登入,儀表盤,關注,任務,定時,設置,安全設置,Changelog 及磁碟詳情映射到帶標籤的 AI-Configs 參考設計.導入參考樣式表,調整共用頁眉,內容寬度,儀表盤卡片,設置導航和卡片,表單,開關和隱私值狀態,本機化發佈卡片,主題過渡及路由/尺寸變化動畫.在 `doc/DESIGN.md` 記錄頁面映射以及業務,權限和瀏覽器差異.既有 API 調用及服務端權限未改.八種 Web 語言目錄均增加相應標籤和說明.未發現項目臨時規則.
- UI 遷移檢查:隔離的乾淨構建樹通過 Vue 類型檢查和生產構建.主題檢查覆蓋八套配色的兩種模式;多語言,項目結構及本機連結檢查通過.所查英文檔案的文檔格式檢查無錯誤,有四個既有警告.Chromium 在 1280 × 800 下對比參考和目標的登入,儀表盤,關注,任務,定時,設置,安全設置和 Changelog 頁面;設置頁使用相同的 192 px 側欄與 856 px 卡片,Changelog 使用全寬卡片.深色/青綠色切換得到儲存,390 px 設置頁沒有橫向溢出.模擬的單磁碟 API 驗證了詳情抽屜,標籤切換,明確顯示序列號及關閉後清除.靜態預覽和模擬數據不能證明 NAS 實際行為,真實磁碟掃描,密碼修改或重啓恢復.
- 測試主機部署後續:首次安裝 `test-486be47` 暴露 systemd 單元遺漏:重啓服務後 `/var/lib/hdd-health` 權限從 700 變為 755.已立即恢復權限;提交 `ce70010` 增加 `StateDirectoryMode=0700`.對 `ce70010` 的乾淨構建通過 Vue 類型檢查和生產構建,嵌入 `test-ce70010`,並從 SHA-256 匹配的安裝包部署(`e809016f4bd5e01bb5ae3eefcc6c8e1893addf5daec4d796a283c0802b184aa4`).安裝器保留舊應用 `/root/apps/hdd-health-check.backup-20260929-111224-3324946` 和匹配的服務單元備份.服務在 `0.0.0.0:8765` 活動且已啓用;安裝的單元明確保證重啓後狀態目錄權限為 700.Web 密碼檔案權限仍為 600,校驗和未變;現有狀態及日誌路徑保留.局域網磁碟,關注,任務,定時,設置,安全設置,Changelog 及圖標資源均返回 HTTP 200.未認證的受保護 API 返回 401;密碼登入後 `/api/build` 返回 `test-ce70010`,`/api/snapshot` 給出 13 塊序列號遮蔽的磁碟,任務空閒;退出後恢復 401.實時 Chromium 在登入卡片和 Changelog 頂部看到 `test-ce70010`,其後為 `v4.0.0`.未執行磁碟掃描,密碼修改或主機重啓.這是測試構建,不是新的正式版.
- 磁碟詳情改進:預留穩定的滾動條空間,減少打開卡片時最後的輕微位移.管理員驗證卡片現佔滿安全設置頁內容寬度,表單仍易於閲讀.磁碟卡片連結到 `/disks/:id` 或 `/attention/:id` 的完整詳情頁,支持瀏覽器歷史,直接重新加載和窄屏佈局.序列號按鈕直接切換遮蔽/完整值,不另加顯示/隱藏文字;複製操作只在認證顯示後出現,並支持局域網 HTTP 剪貼板回退方案.SMART 屬性有本機化的懸停/聚焦說明和廠商數值差異提示.NVMe Data Units 或 ATA Device Statistics 提供已知單位時,SSD/NVMe 資訊同時顯示主機讀取量和寫入量.八種 Web 語言的候選版 Changelog 描述新的詳情和 SMART 行為;正式 `v4.0.0` 記錄保留為歷史.
- 本次改進的本機檢查:隔離的乾淨 Vue 類型檢查及生產構建通過.`tests/web-smart.py` 和 Python 編譯通過;多語言與項目結構檢查無錯誤.針對性文檔和本機連結檢查無錯誤,有五個既有文檔警告.模擬 Chromium 中磁碟詳情有獨立 URL,可重新加載和使用瀏覽器後退/前進,可遮蔽/顯示/複製/重新隱藏序列號,390 px 下無橫向溢出.HTTP 剪貼板回退方案已實際運行.在 1280 px 視口中,安全驗證卡片位於 1,120 px 主框架內,測得寬 1,072 px;390 px 下無溢出.模擬磁碟不能證明硬件行為.未發現項目臨時規則.
- `test-aa183e4` 測試主機首次檢查:從乾淨提交 `aa183e4` 構建;傳輸包 SHA-256 `fe2ebb97a1524a93f83942d1e157c256185575bbfd6fb34101ba65f714d50605` 匹配.安裝器保留 `/root/apps/hdd-health-check.backup-20260929-114536-3447848` 和匹配的服務單元備份.服務在 `0.0.0.0:8765` 活動且已啓用;`/var/lib/hdd-health` 權限仍為 700,未變的 Web 密碼檔案權限為 600.局域網頁面和直接磁碟詳情路由返回 200;登入前受保護 API 返回 401.認證後的 `/api/build` 返回 `test-aa183e4`;快照列出 13 塊已遮蔽序列號的磁碟,一塊真實 NVMe 的 SMART 詳情同時給出讀取及寫入總量.退出後恢復 401.實時 Chromium 顯示一致的登入及 Changelog 版本,完整磁碟詳情,本機化 SMART 指導,並在局域網 HTTP 下成功顯示/複製/隱藏序列號.390 px 詳情無橫向溢出.四個 NVMe 表格鍵仍使用通用幫助;後續將其改為專門說明.未執行掃描,密碼修改或重啓.
- 修正後的測試主機部署:對乾淨提交 `f0b58be` 運行 Vue 類型檢查及生產構建;`version.json` 嵌入 `test-f0b58be`.6,532,350 字節的安裝包在安裝前匹配 SHA-256 `96a029b49dc9a09bb2b1edad414c682dffb8ef357c2e9d6ee55c9721af7c78e5`.安裝器保留 `/root/apps/hdd-health-check.backup-20260929-115210-3485325` 及匹配的服務單元備份.服務在 `0.0.0.0:8765` 活動且已啓用;狀態目錄權限為 700,未變的密碼檔案權限為 600.局域網磁碟,直接詳情,安全設置和 Changelog 路由返回 200;認證會話前後,未認證的受保護 API 均返回 401.會話中 `/api/build` 返回 `test-f0b58be`,快照列出 13 塊遮蔽序列號的磁碟,真實 NVMe SMART 響應同時給出讀寫總量.實時 Chromium 顯示匹配的登入及 Changelog 標記,兩個新的候選記錄,完整詳情頁,先前四個通用 NVMe 計數器的具體幫助,並在 390 px 下無橫向溢出.預留滾動條空間使卡片路由過渡中的文檔寬度穩定;穩定後路由遮罩和動畫類均已清除.首次安裝構建在局域網 HTTP 下的序列號顯示/複製/隱藏流程通過;本次修正僅改說明標籤.已關閉瀏覽器會話.未執行掃描,密碼修改或重啓.
- 磁碟詳情交互後續:複製反饋暫時把按鈕圖標改為勾號,同時保留成功提示.提示放大,增加進場/退場動畫.頁面返回按鈕和瀏覽器後退均使用反向頁面滑動,避免把磁碟型號拉伸進窄卡片.SMART/Checks 主題色指示線在標籤間滑動;SMART 表格的行,數值和可聚焦浮動幫助圖標更清晰.管理員驗證和密碼修改表單內容居中,填滿可讀區域.`doc/DESIGN.md` 記錄與參考設計不同的詳情返回效果.API 和權限行為未變.
- 本次後續的本機檢查:隔離構建樹中的 Vue 類型檢查及生產構建通過;`tests/web-smart.py`,多語言及項目結構檢查通過.針對性文檔和本機連結檢查無錯誤,有五個既有文檔警告.模擬 Chromium 驗證了臨時複製勾號及提示,SMART 懸停幫助,標籤狀態,兩種返回路徑和路由動畫狀態清理.390 px 下穩定後的磁碟詳情和安全設置頁面無橫向溢出.模擬磁碟不能證明實際硬件行為;未發現項目臨時規則.
- 測試主機部署 `test-b6a0ba7`:從乾淨提交 `b6a0ba7` 構建;Vue 類型檢查及生產構建通過,`version.json` 嵌入準確標識.傳輸包 SHA-256 `81aedb34c94bd607e76025c28927c0f221511f79cf418c0e1800108d50956afe` 匹配.安裝器保留 `/root/apps/hdd-health-check.backup-20260929-120631-3533408` 和匹配的服務單元備份.Web 服務在 `0.0.0.0:8765` 活動且已啓用;`/var/lib/hdd-health` 權限仍為 700,現有 Web 密碼檔案權限為 600,校驗和與備份相同.局域網磁碟及詳情路由返回 200,未認證的構建 API 返回 401.認證後的構建 API 返回 `test-b6a0ba7`,快照列出 13 塊遮蔽序列號的磁碟,真實 NVMe SMART 響應給出主機讀寫總量.實時 Chromium 確認臨時複製勾號及提示,SMART 說明,標籤指示線,返回時反向滑動,且沒有殘留遮罩或動畫類.可見的 Changelog 和版本連結顯示 `test-b6a0ba7`;390 px 下詳情,安全設置和 Changelog 頁面均無橫向溢出.未執行磁碟掃描,密碼修改或重啓.
- 磁碟返回及提示修正:逐幀截圖發現反向滑動將詳情與儀表盤明顯割裂,從詳情點擊首頁會短暫把儀表盤縮成不可讀的微型頁面.現在從詳情到列表或儀表盤的導航依次淡入淡出全尺寸頁面,涵蓋返回按鈕,首頁/品牌/麪包屑連結及瀏覽器歷史;其他路由維持原有動畫.提示現於 4.2 秒後自動關閉,仍可手動關閉.Web UI 規範針對參考設計未涵蓋的密集數據詳情路由加入範圍明確的例外,並記入 `doc/DESIGN.md`.本機 Vue 類型檢查及生產構建通過.模擬 Chromium 檢查了返回過程中的幀,瀏覽器後退/前進,首頁/歷史路徑,關閉動畫路徑,窄屏返回及定時提示消失;臨時路由類和遮罩均已清除.文檔,本機連結,多語言及項目結構檢查無錯誤.未發現項目臨時規則.
- 測試主機部署 `test-08b6370`:從乾淨提交 `08b6370` 構建;生產 Web 資源及 `version.json` 嵌入準確測試標識.傳輸包匹配 SHA-256 `36b04555d54e48dd05ad8a0ef7e5e1cd96e6ea8c99b56580f959a810c5bcb458`.安裝器保留 `/root/apps/hdd-health-check.backup-20260929-124823-3573886` 和匹配的服務單元備份.服務在 `0.0.0.0:8765` 活動且已啓用;`/var/lib/hdd-health` 權限仍為 700,密碼檔案權限為 600,校驗和與備份相同.局域網磁碟及直接詳情路由返回 200;匿名 `/api/build` 返回 401.認證後的 `/api/build` 返回 `test-08b6370`,快照列出 13 塊磁碟.實時 Chromium 顯示相同的頁面版本,檢查了返回及滾動後 SMART 頁面到首頁的中間幀,沒有頁面割裂或縮成微型頁面,也沒有殘留路由遮罩或類.真實序列號複製提示約 4.2 秒後消失.穩定後的 390 px 磁碟列表和 Changelog 無橫向溢出.未執行磁碟掃描,密碼修改或重啓.
- `main` 上的動畫調整:Toast 每次顯示後 3 秒關閉,相同消息重複出現時重啓計時器和入場效果,手動關閉時清除計時器.SMART/Checks 底線在選擇,翻譯及重新排布後按實測標籤位置和寬度定位;標籤文字顏色與指示線同步過渡.調整視口尺寸會清除被中斷路由過渡的副本及臨時樣式.頁面路由動畫,主題動畫和局部反饋分別控制;數據密集的磁碟詳情返回淡入淡出效果仍是已記錄的項目例外.
- 動畫檢查:隔離環境中的 `npm ci`,Vue 類型檢查及生產構建通過;掛載源碼目錄內直接運行 `npm ci` 在刪除已有 `node_modules/lightningcss-linux-x64-gnu` 目錄時失敗.模擬 Chromium 驗證關閉路由動畫時 View Transition 調用數為零,中英文及阿拉伯語 RTL 下桌面和 390 px 的標籤指示線位置與寬度匹配選中按鈕,減少動態效果時指示線和文字過渡消失,重複複製序列號反饋會重啓 3 秒生命週期.手動關閉 Toast 及窄屏佈局已檢查.啓用的詳情過渡被視口尺寸變化中斷後,沒有殘留路由副本,路由類或凍結的變換.這些瀏覽器檢查使用模擬磁碟/API 響應,不能證明 NAS 或真實移動設備行為.此變更沒有部署;未發現項目臨時規則.
- 測試候選版準備:八種 Web 語言目錄中的應用內候選版條目現描述尺寸變化中斷後的清理,已翻譯詳情標籤指示線動畫及重複觸發 Toast 的 3 秒計時器.候選版用於部署當前動畫變更,保留 `test-<commit>` 標識;不是新的正式版.未發現項目臨時規則.
- NAS 部署 `test-771001c`:從乾淨提交 `771001c` 構建;Vue 類型檢查和生產構建通過,`version.json` 嵌入相同測試標識.一比一傳輸包匹配 SHA-256 `1b191dd0aa39a01c41936bca5eba763e5e5d0ebbb5689673b5c5f0d2e3b497e9`.安裝前,檢查器,Python 服務及 systemd 單元哈希與已安裝檔案一致,因此此次部署僅改變 Web 資源及打包的更新記錄,沒有檢查器或狀態格式遷移.安裝器保留 `/root/apps/hdd-health-check.backup-20260929-132147-3619345` 和 `/etc/systemd/system/hdd-health-web.service.backup-20260929-132147-3619345`;新舊 Web 密碼哈希一致,密碼檔案權限仍為 600.服務在 `0.0.0.0:8765` 活動且已啓用;`/var/lib/hdd-health` 權限仍為 700,`/var/log/disk-health` 仍可用.局域網 GET `/disks/sdb` 和 favicon 返回 200;匿名 `/api/build` 返回 401.密碼認證後的 `/api/build` 返回 `test-771001c`,`/api/snapshot` 列出包括 `sdb` 的 13 塊遮蔽序列號磁碟,`/api/status` 無活動任務,退出後 `/api/build` 恢復 401.`sdb` 的 SMART 端點報告磁碟待機,因此沒有喚醒或掃描.實時 Chromium 打開直接 `/disks/sdb` 路由,顯示同一版本,遮蔽的序列號和休眠狀態;390 px 下 SMART/Checks 底線與選中按鈕匹配,頁面無橫向溢出.版本連結打開對應本機化候選版 Changelog;路由遮罩已清除.瀏覽器和臨時部署檔案均已刪除.真實移動瀏覽器渲染及重啓恢復仍未驗證;未發現項目臨時規則.
- 暫緩的視覺問題:用户提供已部署磁碟詳情 UI 的截圖,其中當前 SMART 標籤底線長於標籤的懸停/選中區域.先前 390 px 瀏覽器測量未覆蓋截圖中的視覺狀態.Bugs 章節記錄預期對齊方式和需要重查的配置.報告問題時沒有修改 UI 代碼或 NAS 部署;未發現項目臨時規則.
- 標籤底線後續:以直接測得的寬度取代一像素線條的變換縮放,並將選中按鈕測量精度提高到小數.本機 Chromium 在 390 px,100% 和 200% CSS 縮放,簡體中文,英文及阿拉伯語下確認兩種標籤按鈕均與底線匹配.隔離構建樹中的 Vue 類型檢查和生產構建通過;多語言,項目結構,針對性文檔和本機連結檢查通過,有四個既有文檔警告.用户報告的詳情返回動畫問題仍未解決,本次未改動;未發現項目臨時規則.
- NAS 部署 `test-bd438c4`:從乾淨提交 `bd438c4` 構建,`version.json` 中使用相同標識.傳輸包匹配 SHA-256 `65d10b167552c232be481edd2f60e3359dd5b5d6a03121960229923ec0e211da`;檢查器,Python 服務及服務單元的哈希與此前安裝一致.安裝器將舊應用保留在 `/root/apps/hdd-health-check.backup-20260929-134240-3654021`,並保留匹配的服務單元備份.Web 密碼校驗和未變,權限為 600;`/var/lib/hdd-health` 權限仍為 700,`/var/log/disk-health` 可用.服務在 `0.0.0.0:8765` 活動且已啓用.認證後的 `/api/build` 返回 `test-bd438c4`,`/api/snapshot` 列出 13 塊磁碟,`/api/status` 沒有運行中的任務,退出後 `/api/build` 返回 401.局域網 GET `/disks/sda`,favicon 及 `version.json` 成功;服務端本機 `/changelog` 請求返回 200.實時 Chromium 在 `/disks/sda` 顯示新版本,桌面及 390 px,125% CSS 縮放下兩條標籤底線均與選中按鈕等寬.臨時 NAS 部署檔案和瀏覽器會話已刪除.未執行磁碟掃描,密碼修改或重啓.
- 剩餘工作:用户報告的磁碟詳情返回動畫問題暫緩.真實移動瀏覽器中的動畫,真實主機重啓後的恢復以及真實 HDD 上受控的完整評估仍未驗證.根目錄兼容入口及其遷移前基線已記入 Limitations.
- 發佈準備:用户批准為當前已部署變更發佈正式版本.`v4.1.0` 涵蓋 `v4.0.0` 之後的提交:登入及 Changelog 存取,與參考設計對齊的 Web 頁面,磁碟詳情和 SMART 指導,服務狀態權限,標籤及反饋修復.已知的返回動畫問題按要求暫緩.此前的 `v4.0.0` 標籤和 Release 保持不變;未發現項目臨時規則.
- 正式發佈:發佈時,`main` 和帶註釋的 `v4.1.0` 標籤均指向 `09e6fa5`.GitHub Release 為公開且已發佈的正式版,不是預發佈版;其預構建 Web 安裝包大小為 6,952,186 字節,SHA-256 為 `cf4e94597552c84f36140c1890eb62b379421599ae2a8e0f929ce24c65880a98`,並附有 `SHA256SUMS`.乾淨的標籤構建嵌入 `v4.1.0`;Chromium 檢查顯示相同版本,正式 Changelog 位於 `v4.0.0` 之前,沒有測試候選條目.全部 Shell 和 Python 測試,Vue 類型檢查,生產構建,多語言,項目結構,針對性文檔及本機連結檢查均通過.文檔檢查器仍有五個既有警告.已導出 `../snapshots/v4.1.0` 源碼快照,並將完整 Changelog 同步到 Notion 的 `My Projects` 下經核實的 `hdd-health-check` 子頁面.
- 正式 NAS 部署:傳輸包通過 SHA-256 校驗,安裝器將運行中的 `test-bd438c4` 服務升級為 `v4.1.0`.已保留 `/root/apps/hdd-health-check.backup-20260929-142539-3689967` 和匹配的服務單元備份.Web 密碼校驗和未變,檔案權限仍為 600;`/var/lib/hdd-health` 權限仍為 700,`/var/log/disk-health` 仍可用.服務在 `0.0.0.0:8765` 活動且已啓用.密碼認證後的 `/api/build` 返回 `v4.1.0`,`/api/snapshot` 列出 13 塊磁碟,退出後 `/api/build` 恢復 401.局域網 GET 磁碟詳情,Changelog,版本元數據和 SVG favicon 均返回 200.實時 Chromium 打開 `/disks/sda`,顯示 `v4.1.0`,並測得 SMART 和 Checks 底線與選中按鈕等寬;在 390 px 和 125% CSS 縮放下,重新排布後的寬度誤差小於 0.001 px,偏移誤差小於 0.15 px.實時 Changelog 顯示正式版本及暫緩處理的動畫問題.臨時瀏覽器,密碼及部署檔案已刪除.未執行磁碟掃描,密碼修改或重啓.
- 剩餘工作:用户報告的磁碟詳情返回動畫問題仍暫緩處理.真實 HDD 上受控的完整評估,真實移動瀏覽器動畫及主機重啓後的服務恢復仍未驗證.
- 下一步:用户提出要求後修復暫緩處理的返回動畫,再在實際目標瀏覽器中驗證並更新 Handoff.另外,在可中斷主機運行的時間安排受控 HDD 評估和重啓恢復檢查.

## 歷史原始碼基線

### v2.3.0 — 2026-09-24 (untagged source baseline)

#### 變更

本版包括之前未建立 tag 的 v2.2 整合:持久的每隻磁碟結果,SMART 計數器歷史紀錄,互動及批次模組,可續掃的唯讀表面掃描,介面驗證,可選的暫時性 systemd 工作及更安全的純數據狀態解析.不保證兼容 v1 CLI 或狀態:`-w/--wait` 會被忽略而不會等待;升級前備份主機狀態,還原舊腳本時須還原相應的狀態.以下新版評分只有合成測試,未經真實 HDD 驗證.

#### 修正

- 正確識別首次新完成的 SMART 自我測試紀錄;舊紀錄,未完成紀錄或類型不符的紀錄不算新完成的測試.
- 完整評估將快速,短測試,長測試 SMART,速度和完整表面掃描標為同一批次,最後複查快速 SMART/ATA/CRC.只有同批次完整且有效的結果才有數字綜合評分.重用,中斷,過期,無批次標記的舊狀態及後續介面複查令舊紀錄標為歷史/待複查,整體為部分/未知;報告不更新快速檢查比較基準.介面複查另行記錄已解決或未解決,不重新歸因舊錯誤或令舊批次成為目前批次.無先前快速檢查計數的 ATA 累計數原因未明,未解決的 5 分扣分在後續檢查及全檢中保留;舊紀錄缺少風險欄位時亦按未解決處理.增加扣 20 分;計數穩定不是新錯,也不是修復證據;僅有介面複查不能把舊 ATA 錯誤歸因於介面維修.零星慢讀提示效能重測而非壞磁區診斷;表面讀取錯誤仍扣 40 分.這是啟發式權重而非故障概率.

### v2.2.0 — 未建立 tag 的整合歷史(未發佈)

#### 新增

- 每隻磁碟的持久結果,SMART 計數器歷史紀錄,維修紀錄及報告;互動式選單,抽樣讀取分析,可續掃的表面延遲掃描及針對特定位置的壞區塊複查,全碟唯讀 `badblocks`,介面讀取壓力測試,以及可選的暫時性 systemd 背景執行.

#### 變更

- 預設批次快速檢查,可重用的具時效結果及 `--rescan`;`-r/--run` 選擇模組,`--status`/`--stop` 管理執行中的實例.`-t short|long`,`-s` 及 `-b` 對應至各模組;`-w/--wait` 會被忽略,不會等待.新行為並不兼容 v1 CLI.
- 主機狀態及日誌分開寫入;v2.2.0 不保證兼容 v1 CLI 或狀態.升級前備份主機狀態;還原舊腳本時須一併還原相應的狀態備份.狀態紀錄只接受允許清單中的數據欄位;不兼容紀錄可能被拒絕.

#### 修復

- 拒絕可執行或格式錯誤的狀態紀錄及符號連結狀態輸入;背景計劃只接受已驗證欄位及私人狀態目錄,並驗證裝置名稱及日誌/狀態路徑,減低不安全檔案處理風險.
- 無效或不完整的表面掃描檢查點會觸發重新掃描,不會以零分母計算進度;支援在自訂 `TMPDIR` 下識別運行中的實例及安全停止.

用戶表示已在實機測試 v2.2.0,但未提供裝置,環境或測試範圍;root 執行,套件安裝及 systemd 行為尚未獲獨立確認.

## 變更記錄

### v4.1.0 — 2026-09-29

本次發佈更新 Web 介面及磁碟詳情.先前的測試版本已在列出 13 隻磁碟的 Debian NAS 上檢查;正式版本會在發佈前另行檢查.

#### 新增

- 磁碟卡片可開啟完整詳情頁,包含階層導覽,返回導覽,個別磁碟檢查,SMART 屬性及說明.序號在通過身份驗證並明確顯示之前仍會遮蔽;只有顯示後才可複製.裝置提供單位明確的計數器時,SSD/NVMe 詳情會顯示主機讀取量及寫入量.
- Web 介面的登入頁,儀表板,功能頁,設定,安全設定及變更記錄遵循共用視覺參考.新增響應式版面,本地化控制項,圖示及可選的頁面和視窗大小變化動畫.

#### 變更

- 登入前即可從登入頁開啟 Changelog,當中顯示相應的構建版本.磁碟詳情控制項採用依實測尺寸定位的分頁指示線;重複觸發複製提示時會重新開始其消失倒數.
- NAS 服務單元在重新啟動後仍將 `/var/lib/hdd-health` 保持為 700 權限模式.更新時安裝程式會繼續保留舊應用程式,服務單元及 Web 密碼.

#### 修復

- 修正窄畫面及已測試縮放比例下目前 SMART 和 Checks 分頁底線的寬度及位置,包括 RTL 版面.改善磁碟詳情提示,SMART 計數器說明及路由動畫中斷後的清理.

#### 已知問題及驗證

- 用戶回報從磁碟詳情返回時的動畫問題,現按要求暫緩處理.真實 HDD 的完整評估,實際流動瀏覽器上的動畫及主機重啟後的服務復原仍未驗證.健康評分仍是啟發式指標,並非經校準的故障概率.
- 測試版本通過 Vue 類型檢查,正式環境構建,項目及翻譯檢查,以及本機 Chromium 版面檢查.NAS 測試部署通過身份驗證後的版本及磁碟清單 API 檢查,以及兩個分頁底線的瀏覽器檢查;未執行磁碟掃描,密碼更改或重啟.

### v4.0.0 — 2026-09-28

本次主要版本更新本機 Web 控制器,安全模型及原始碼佈局.已在列出 13 隻磁碟的 Debian NAS 上檢查通過驗證的測試建置.真實 HDD 的完整評估及主機重啟後的服務復原仍未驗證.

#### 新增

- SSD/NVMe 完整評估現在執行 SMART 快檢,短測,長測及全碟唯讀掃描,無需 HDD 速度取樣.依既有啟發式規則,完整且無異常的批次得 100 分;單純慢讀不扣分,真實讀取錯誤及 SMART 異常仍可扣分.混合磁碟的批次控件提供支援檢查的合集,HDD 專用模組跳過不適用的 SSD.
- 工作歷史分別記錄已完成,停止及失敗的 Web 執行,與各磁碟最新檢查結果及 SMART 計數器趨勢分開.磁碟詳情可讓合適的 SATA HDD 進入待機,或逐一喚醒休眠的 HDD.
- 設定提供八種主題色及明暗模式.項目名稱旁的版本連結指向 Changelog;執行時 `/api/build` 傳回相同的內嵌建置標識.一般回應遮蔽磁碟序號,只有用戶通過驗證後明確要求顯示時才取得完整號碼.

#### 變更

- Security Settings 使用獨立路由及伺服器強制執行的五分鐘管理員密碼驗證時段.驗證會輪換工作階段;時段內修改密碼只需新密碼及確認,隨後令所有工作階段失效.IP 免密設有啟用開關,只接受精確的 RFC 1918 IPv4 或 ULA IPv6 位址.免密 IP 工作階段不能讀取或修改安全設定.修改請求需要同源標頭;用戶端轉送標頭不能決定連線對端位址.
- 原始碼移至 `src/checker/` 及 `src/web/`,前端產物位於 `dist/web/`;根目錄 CLI 入口及 NAS 安裝目錄仍相容.文件語言目錄採用 BCP-47 名稱.磁碟概覽按視口寬度重排,儀表板四種功能仍由獨立頁面提供.

#### 修復

- 全碟自我測試期間保持工作狀態回應,分別顯示 SMART 短測及長測結果,保留獨立的歷史工作紀錄.修正 NVMe 溫度顯示區間;只有溫度異常或 SSD 速度變化時不再扣健康分.檢查正常但完整評估覆蓋不足時,不再只因此傳回警告.
- Debian 安裝程式的已驗證健康檢查現傳送必要的請求標頭,並於檔案替換開始後發生明確安裝錯誤時回復.

#### 驗證

- Shell 與 Python 測試,Vue 類型檢查及正式建置,文件與結構檢查,本機瀏覽器檢查通過.NAS 測試部署通過已驗證 API 及 Security Settings 瀏覽器檢查,包括序號遮蔽及 390 px 無橫向溢出的佈局.此次發佈準備沒有執行磁碟掃描,沒有修改密碼,亦沒有重啟;健康分數不是經校準的故障概率.

### v3.0.0 — 2026-09-27

此主要版本在原有磁碟檢查器中加入經驗證的常駐 Web UI 和 Debian 安裝程式.Web 服務已在辨識 13 個磁碟的 Debian NAS 上檢查;實體 HDD 的完整評估與重啟復原仍未驗證.標籤包含原始碼,沒有發佈 GitHub Release 或預建 UI 附件.

#### NAS 後續修復

- 磁碟卡片依瀏覽器可用寬度和縮放重新排列,保持按鈕可見且沒有橫向溢出;寬螢幕最多四欄.
- 將 SSD/NVMe 的速度取樣下降與平均速度變化視為效能資訊,實際讀取故障仍扣分,舊結果亦按新規則解讀.磁碟概覽採用回應式欄;儀表板磁碟卡片可跳至清單.
- 全碟 SMART 自我測試期間,網頁狀態端點只讀取執行紀錄及最近日誌,不再逐碟輪詢,讓工作更新維持流暢.磁碟清單另行更新,一次背景讀取期間沿用上次成功快照.
- NVMe 溫度顯示顏色不參與健康評分.可用時採用控制器警告/臨界門檻,否則使用 70/80 °C 顯示區間;僅溫度觸發的 NVMe 警告不扣分.歷史評估在重新檢查前保持不變.
- 正確解碼空白的已儲存欄位,避免僅因無異常檢查的評估涵蓋不完整而返回警告結束代碼.
- 將儀表板四類內容分成獨立頂層頁面,保留磁碟首頁的一鍵評估.

#### 新增

- Python Web 服務,Vue 介面,排程快速檢查,工作控制,SMART 歷史檢視及部署單元.安裝程式設定經驗證的區域網路存取;手動執行仍只監聽回環位址.
- Web 登入及登出,在設定頁由已驗證使用者管理的精確 IPv4 免密名單,顯示基本硬體資訊的磁碟卡片,以及獨立的 SMART 資訊和檢查分頁.更新記錄以 Markdown 呈現 Changelog 章節.
- 可用的 SATA 版本與協商速度,或 NVMe PCIe 代數,通道寬度及速率;可切換的通電時間顯示;可按 SATA,HDD,SSD,NVMe 或全部磁碟選取八個既有模組之一進行批次檢查.清單標示匯流排和媒體類型並顯示快取溫度;只有裝置報告時才顯示外形規格.只有完整評估可產生目前綜合分數.SSD/NVMe 分數仍面向 HDD,沒有個別校準.
- Debian 安裝程式檢查先決條件,透過 apt 安裝缺少的套件,部署預建 UI 和服務,升級時保留復原副本.
- `--json` 快照重用 Bash 綜合評分函式.`--no-install` 防止 Web 啟動的工作自動安裝依賴.Web 啟動現在持久保存已接受,執行中和終態工作;關注卡片篩選磁碟,檢查詳情顯示已記錄扣分,舊紀錄缺少原因時明確提示.

#### 驗證

- UI 建置及型別檢查,Shell 狀態/評分測試及本機 HTTP 驗證測試通過.經驗證的區域網路服務已在列出 13 個磁碟的 Debian NAS 上安裝並檢查.實體 HDD 完整評估及重啟復原仍未驗證.

### v1.0.0 — 2026-08-08

#### 新增

- 首版 12 個面向的 HDD 健康檢查:裝置/介面數據,SMART 能力及整體判斷,ATA 屬性或 SAS 缺陷/錯誤計數器,錯誤及自我測試日誌,啟動短/長自我測試,壽命/負載,核心 I/O 錯誤,掛載及唯讀狀態偵測,可選的唯讀 `hdparm` 基準測試和 `badblocks` 掃描.
- 啟發式 0–100 分評分及四個等級,對應程序退出碼 0/1/2/3;SMART 透傳自動偵測,互動式及批次磁碟選取,並提議透過 `apt` 安裝缺少的 `smartmontools`.
- 完整的 v1.0.0 設計及用法文件保留於 `v1.0.0` Git 標籤(例如 `git show v1.0.0:DESIGN.md` 及 `git show v1.0.0:README.zh.md`);舊版指令不適用於現時版本.

## 提交記錄

主分支完整歷史: `git log main --stat`.`HEAD` 條目標示本次交接提交.

- 2026-09-29 | intended | `docs(handoff): clarify v4.1.0 release ref status` | this commit
- 2026-09-29 | `59313bb` | `docs(handoff): record v4.1.0 publication and deployment` | `git show 59313bb`
- 2026-09-29 | `09e6fa5` | `chore(release): prepare v4.1.0` | `git show 09e6fa5`
- 2026-09-29 | `1fd8ad3` | `docs(handoff): record underline fix deployment` | `git show 1fd8ad3`
- 2026-09-29 | `bd438c4` | `fix(web): match detail underline to selected tab` | `git show bd438c4`
- 2026-09-29 | `d44f624` | `docs(handoff): record deferred tab underline issue` | `git show d44f624`
- 2026-09-29 | `029e634` | `docs(handoff): record motion test deployment` | `git show 029e634`
- 2026-09-29 | `771001c` | `docs(web): describe motion test candidate` | `git show 771001c`
- 2026-09-29 | `fa77086` | `fix(web): align local motion with current standard` | `git show fa77086`
- 2026-09-29 | `a21783b` | `docs(handoff): record disk return deployment` | `git show a21783b`
- 2026-09-29 | `08b6370` | `fix(web): correct disk return and toast timing` | `git show 08b6370`
- 2026-09-29 | `8633851` | `docs(handoff): record disk detail UI deployment` | `git show 8633851`
- 2026-09-29 | `b6a0ba7` | `fix(web): refine disk detail feedback and motion` | `git show b6a0ba7`
- 2026-09-29 | `c289147` | `docs(handoff): record final disk UI test deployment` | `git show c289147`
- 2026-09-29 | `f0b58be` | `fix(web): explain NVMe SMART counters` | `git show f0b58be`
- 2026-09-29 | `aa183e4` | `feat(web): expand disk details and SMART guidance` | `git show aa183e4`
- 2026-09-29 | `dd4cd84` | `docs(handoff): record corrected test deployment` | `git show dd4cd84`
- 2026-09-29 | `ce70010` | `fix(deploy): keep HDD state directory private` | `git show ce70010`
- 2026-09-29 | `486be47` | `feat(web): migrate UI to reference v1.2.3` | `git show 486be47`
- 2026-09-29 | `d52366b` | `docs(handoff): record NAS Web design deployment` | `git show d52366b`
- 2026-09-29 | `c7b6252` | `feat(web): align pages with current design standard` | `git show c7b6252`
- 2026-09-28 | `c0e7ae7` | `docs(handoff): record version and Changelog deployment` | `git show c0e7ae7`
- 2026-09-28 | `3c3451f` | `docs(changelog): record latest Web update` | `git show 3c3451f`
- 2026-09-28 | `0a91897` | `docs(handoff): record NAS UI deployment` | `git show 0a91897`
- 2026-09-28 | `2e6201e` | `fix(web): open changelog before login` | `git show 2e6201e`
- 2026-09-28 | `c38e6d6` | `fix(web): align login with updated design rules` | `git show c38e6d6`
- 2026-09-28 | `df35b42` | `docs(handoff): record v4.0.0 publication` | `git show df35b42`
- 2026-09-28 | `3cf9da0` | `chore(release): prepare v4.0.0` | `git show 3cf9da0`
- 2026-09-28 | `ebf6e39` | `docs(handoff): record NAS browser verification` | `git show ebf6e39`
- 2026-09-28 | `0b5f053` | `docs(handoff): record NAS installer and security verification` | `git show 0b5f053`
- 2026-09-28 | `cd7d69b` | `fix(deploy): verify authenticated service with CSRF header` | `git show cd7d69b`
- 2026-09-28 | `bf14ed5` | `feat(web): align project layout and security settings` | `git show bf14ed5`
- 2026-09-28 | `35f24e5` | `docs(handoff): record NAS Web update verification` | `git show 35f24e5`
- 2026-09-28 | `a6086ff` | `feat(web): unify history and add per-disk standby` | `git show a6086ff`
- 2026-09-28 | `f5f5dc7` | `docs(handoff): record SSD assessment deployment` | `git show f5f5dc7`
- 2026-09-28 | `c60d602` | `fix(web): defer option watcher until labels initialize` | `git show c60d602`
- 2026-09-28 | `261247f` | `fix(web): initialize assessment scope before options` | `git show 261247f`
- 2026-09-28 | `f882a8d` | `docs: record SSD full assessment behavior` | `git show f882a8d`
- 2026-09-28 | `bfed16f` | `feat: assess SSDs with full read-only scan` | `git show bfed16f`
- 2026-09-27 | `97f775f` | `docs(handoff): record v3.0.0 tag publication` | `git show 97f775f`
- 2026-09-27 | `434ac7d` | `chore(release): prepare v3.0.0 source tag` | `git show 434ac7d`
- 2026-09-27 | `65acbd0` | `docs(install): point source install to main` | `git show 65acbd0`
- 2026-09-27 | `b963e06` | `docs(handoff): confirm source publication` | `git show b963e06`
- 2026-09-27 | `88474d2` | `feat(web): publish LAN dashboard and docs` | `git show 88474d2`
- 2026-09-24 | `a46b392` | `feat(scoring): improve batch assessment for v2.3.0` | `git show a46b392`
- 2026-09-24 | `3126bcc` | `docs: clarify public source and reported real-machine testing` | `git show 3126bcc`
- 2026-09-24 | `7e69fdd` | `feat!: integrate unreleased v2.2.0 HDD health checks` | `git show 7e69fdd`
- 2026-08-13 | `7b18ca7` | `docs(status): record v1.0.0 release completion` | `git show 7b18ca7`
- 2026-08-13 | `4e01f52` | `chore(release): v1.0.0 (clean history)` | `git show 4e01f52`
