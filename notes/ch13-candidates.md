# K147 第 13 章 候選：規則／演練／具體指令

來源：page_0049～page_0058（展望、結語、附錄 A～F）

## (a) 規則候選

### 規則 1：上線前跑安全與控制檢查清單

- **規則一句話**：任何會長時間自動執行的代理人或排程，啟用前依附錄 D 的 11 項逐條打勾（本機執行、遙測、最小權限、硬性預算、對外審批、金鑰不落明文、結果先查、個資本地、不做陌生開發、應變計畫、記錄版本與設定），未過的項目先補。
- **Why**：附錄 D「Security and control checklist」與附錄 A「Securing operation」把全書紀律濃縮成可檢查的清單。
- **How to apply**：Claude 協助部署 VPS 排程、claude -p 無頭代理、長時程工廠時，在交付回報中附上這 11 項的狀態表；有「否」的項目列為待修，不宣稱完成。

### 規則 2：金鑰進機密管理，不隨程式、匯出或對話外流

- **規則一句話**：存取金鑰只放機密管理（環境變數、憑證檔、secret store），不寫進程式碼、匯出檔、報告或對話；回報時只說來源與長度。
- **Why**：附錄 A 第 3 步「deposit access keys in the secret management」，附錄 D「Are access keys kept securely in the secret management (not in plain text)?」。
- **How to apply**：Claude 建立設定檔或匯出專案時，先掃描是否含金鑰字樣；需要金鑰時用環境變數讀取並在 .gitignore 排除。

### 規則 3：人類是品質權威——可驗證的工作才交給代理人

- **規則一句話**：只把結果容易驗證的工作交給無人監督的代理人；需要長期可靠性才成立的工作，保留人類定期驗收，並在報告中區分「已驗證」與「未驗證」。
- **Why**：本章「reliability question as the bottleneck」：編排組織工作但不保證品質，「done」不等於「correct」，目前這個權威是人類，且是可預見未來的常態。
- **How to apply**：Claude 規劃長時程任務時，為每個產出定義可檢查的完成條件；無法客觀驗證的產出標記「需使用者驗收」，不自行標為完成。

### 規則 4：所有發現標註版本與日期

- **規則一句話**：記錄工具行為、設定或測試結果時，一律附工具版本、模型與日期，當成「截至今天」的事實。
- **Why**：本章建議「note the version state in everything」「Treat every finding as 'as of today'」，附錄 F 也聲明所有資訊以 2026 年年中為準。
- **How to apply**：Claude 寫記憶、踩坑紀錄或教材時，在條目加上版本號（例如 CLI 版本）與日期；引用舊紀錄前先確認版本是否仍相同。

## (b) 演練候選

### 演練 1：用 claude -p 模擬附錄 C 的三人迷你公司

- **步驟**：
  1. 建立暫存資料夾，寫三份角色提示檔：`ceo.md`（拆解目標、分派、整合，有後果的步驟要求核准）、`researcher.md`（蒐集事實並標出不確定處）、`writer.md`（只根據研究寫稿，不編造）。
  2. 給一個小而明確的目標，例如「整理 3 個本機已安裝 CLI 的用途，寫成 200 字說明」。
  3. 依序以 `claude -p --append-system-prompt-file <角色檔>` 執行研究員、撰稿員，最後由 CEO 角色整合；限制工具只開讀取（不給寄送、push）。
  4. 自己逐句核對最後說明是否與研究員的來源一致。
- **預期結果**：得到一份可用短文，並至少找到一處需要人類修正或標註不確定的地方，體會「編輯代理只能補充、不能取代人類查核」。

### 演練 2：對自己的一個排程跑附錄 D 檢查清單

- **步驟**：挑一個正在運作的自動化（例如 VPS cron 或本機排程），把附錄 D 的 11 項做成 Markdown 勾選表逐條填寫，「否」的項目寫出修正動作。
- **預期結果**：一張狀態表＋至少 1～2 個具體改善項（例如補應變計畫、記錄版本）。

### 演練 3：開源專案與同名託管產品的區分練習

- **步驟**：搜尋三篇談 Paperclip 的評測或文章，逐篇判斷講的是開源專案（github.com/paperclipai）還是同名託管產品，記下判斷依據。
- **預期結果**：能說出至少一篇的對象，並理解附錄 E／F 為何強調兩者常被混淆。

## (c) 書中具體指令／設定檔／網址／版本號

逐字列出截圖中出現者：

- 網址：`github.com/paperclipai`（附錄 E、附錄 F）
- 帳號：`@dotta`（附錄 F，開源專案維護者）
- 軟體／需求：`Node.js`（current version）、`a package manager`、`GitHub`
- 流程名詞：`quick-start command`（會自動建立 `embedded database`）、`dashboard`、`telemetry`（可關閉）、可連線範圍 `"local/trustworthy"`、`secret management`、`hard stop`、`log`
- 授權：`MIT license`
- 術語：`Adapter`、`Bring Your Own Agent (BYOA)`、`Heartbeat`、`OpenClaw`、`Routine / schedule`
- 時間標記：「Paperclip in the summer of 2026」、「all information is as of mid-2026」
- 具體 CLI 指令字面、設定檔名、版本號：**無**（附錄 A 明言只列流程，不列保證不變的指令字面，請以官方專案頁為準）。
