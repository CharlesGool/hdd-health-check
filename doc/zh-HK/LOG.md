---
name: project-log-zh-hk
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: zh-HK
---

# hdd-health-check — 紀錄

本文記錄已採納的歷史決策,已知限制及發佈歷史.目前的大版本為 `v4.0.0`.用戶表示較早的 `v2.2.0` 曾在實機運行,但未提供裝置,環境或測試範圍.修訂後的評分已有模擬測試及 Debian NAS 上的 Web 驗證,但尚未在真實 HDD 上完成受控的完整評估.

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

2026-09-28.分支 `feat/standards-alignment`;標準對齊修改已在本機提交.未發現暫時性項目規則.

- NAS 安裝程式後續檢查:首次安裝 `test-bf14ed5` 時新服務已啟動,但健康檢查因缺少 `X-HDD-CSRF` 請求標頭收到 HTTP 403;其 `die` 報錯路徑亦沒有觸發回復.`cd7d69b` 修正標頭與回復.重新安裝 `test-cd7d69b` 後,健康檢查通過,服務於 `0.0.0.0:8765` 運行並已設為開機啟用.安裝程式保留舊應用程式及服務單元備份;Web 密碼與舊備份一致,`/var/lib/hdd-health` 及 `/var/log/disk-health` 保持原狀.
- 已完成:原始碼整理至 `src/checker/` 及 `src/web/`,產生的 Web 檔案移至 `dist/web/`;保留根目錄 CLI 相容入口,更新安裝程式及測試路徑,統一語言目錄及文件導覽.原始碼安裝沿用既有 Debian 服務目錄.一般設定提供八種主題色與明暗模式,獨立儲存選擇;頂部導覽使用真正的 Changelog 連結.
- 安全:獨立的 Security Settings 頁面由伺服器執行五分鐘管理員密碼驗證時段.驗證會輪換工作階段;僅憑 IP 進入的工作階段不能讀取或修改名單與密碼.時段內修改密碼只需新密碼及確認,並令所有工作階段失效.IP 免密可啟用或停用,只接受精確的 RFC 1918 IPv4 或 ULA IPv6 位址,拒絕不合規的舊項目;依連線對端而非用戶端轉送標頭判定來源,並檢查原始 Host/Origin 及修改請求的同源標頭.
- 私隱及版本:快照及 SMART 回應遮蔽序號;只有使用者明確操作時,才經已驗證請求取得完整序號,隱藏或關閉檢視時清除.項目名稱旁的版本連結開啟 Changelog;無標籤建置使用 `test-<sha>` 標記,`/api/build` 傳回相同值.
- 評估行為:SSD/NVMe 完整評估執行 SMART 快檢,短測,長測及全碟唯讀掃描,不作速度取樣.完整而無異常的批次得 100 分;單純慢讀不扣分.批次選項依所選磁碟類型提供支援的檢查.容量及 SSD 主機寫入量可切換十進位/二進位單位;休眠 HDD 可逐一喚醒.模擬測試通過,此次未啟動真實磁碟完整評估.
- 檢查:Vue 類型檢查及正式建置,全部 Shell 及 Python Web 測試,八種主題色兩種模式的檢查,多語言,文件格式(0 個錯誤,8 個警告),本機連結及項目結構檢查均通過.Shell 語法,Python 編譯及 `git diff --check` 通過.本機 Chromium 在 390 px 無橫向溢出,可顯示 Security Settings 及深色設定;直接開啟 Changelog 時先顯示 v3.0.0.隔離瀏覽器環境沒有檢查器,磁碟狀態請求按預期傳回 503.原始碼封存檔建置使用 `test-archive-<package version>` 標記,不顯示為正式版本.
- NAS 驗證:安裝後的 `/api/build` 與 `test-cd7d69b` 一致.密碼登入,未驗證的安全設定拒絕,管理員驗證,工作階段輪換,受保護名單讀取及 13 隻磁碟快照的序號遮蔽均通過.局域網安全頁面與 favicon 傳回 HTTP 200;未驗證的普通及受保護 API 請求傳回 401.已登入的 Chromium 開啟安全頁面,顯示已儲存的 IP 控件及修改密碼表單;390 px 下頁面寬度等於視口寬度.瀏覽器工作階段與本機暫存密碼檔已清理.未進行磁碟掃描,密碼修改或重啟;已安裝的測試建置不是正式版本.
- 剩餘工作:適時觀察實機重啟後的服務復原.真實 HDD 的受控完整評估仍未驗證.根目錄相容入口及搬遷前基線載於限制章節.本機分支尚未發佈.
- 發佈準備:`v4.0.0` 是下一個正式版本.Changelog 包含 `v3.0.0` 後的提交;發佈提交,標籤,GitHub Release,快照及 Notion 同步仍待完成.NAS 仍運行 `test-cd7d69b`,除非另外部署.
- 翻譯復原:目前七種語言的核心文件譯文落後於只更新英文的交接及提交歷史,因此本次發佈沒有可供 `check-doc-difference.py` 使用的結構同步基線.依照文件規定的復原規則,受影響文件正以目前英文原文為準完整同步;仍須涵蓋全部七種語言並保留受保護的導覽內容.
- 下一步:完成翻譯及發佈檢查,再從 `main` 發佈 `v4.0.0`;重啟檢查及受控 HDD 評估另行安排.

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

- 2026-09-28 | intended | `chore(release): prepare v4.0.0` | this commit
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
