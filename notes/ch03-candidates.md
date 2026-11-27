# 第 3 章 規則與演練候選（page_0013～page_0015）

## (a) 規則候選

### R3-1 熱門不等於成熟：評估開源依賴要看維護者與資金

- 規則一句話：推薦或導入開源工具時，除了星數，還要回報維護者人數、近期提交集中度、資金狀況與版本型態，並把「單人維護」列為風險。
- Why：本章迷思檢查指出星數衡量關注不衡量品質、受歡迎不等於成熟；一位匿名單人維護、無資金是集中風險，專案可能消失得跟出現一樣快（page_0013～page_0015）。
- How to apply：Claude 建議新工具時固定附一行「健康度」：stars／forks、主要貢獻者占比、最後 release、授權、是否有公司或資金；單人維護時明講並建議備援方案。

### R3-2 業務關鍵依賴要先有退場計畫

- 規則一句話：好奇試用可以；要把年輕工具放進關鍵流程前，先寫好「它停更或改授權時怎麼辦」。
- Why：「對你的意義」直說：帶著好奇心試用可以，但沒有備援計畫就建立業務關鍵依賴不行；且無付費模式今天沒有不代表明天沒有（page_0015）。
- How to apply：Claude 把新工具接進排程、部署或正式專案時，同時記錄鎖定版本與替代方案（例如回退到既有 claude -p 腳本），寫進專案 README 或記憶。

### R3-3 起源故事當傳說看：未證實的說法要標示

- 規則一句話：轉述專案背景、軼事、數據時，區分「有文件佐證」與「看似合理但未證實」。
- Why：作者把 @dotta 的交易背景與 HEARTBEATS.md 故事明確定位為「plausible origin legend, not a documented fact」（page_0013）。
- How to apply：Claude 撰寫研究摘要時，對無法查證的說法加註「未證實」，不把傳說寫成事實。

## (b) 演練候選

### D3-1 開源專案健康度體檢（只需 gh CLI 或瀏覽器）

- 步驟：
  1. `gh repo view paperclipai/paperclip --json stargazerCount,forkCount,licenseInfo,updatedAt`（或直接開網頁）。
  2. `gh api repos/paperclipai/paperclip/contributors --jq '.[0:5] | .[] | "\(.login) \(.contributions)"'` 看前 5 名貢獻者占比。
  3. `gh release list -R paperclipai/paperclip -L 5` 看版本號格式（是否為 v2026.517.0 這種日期式）。
  4. 對照本書 2026 年 6 月中的數字（約 70,000 stars、約 13,000 forks、97.8% TypeScript），寫下變化與你的風險判斷。
- 預期結果：得到一張健康度表，並能說明「熱門」與「成熟」的差別；若 repo 名稱或數字已變，正好驗證版權頁「變動很快、要回官方核對」的提醒。

### D3-2 HEARTBEATS.md 概念小實驗（不需付費帳號）

- 步驟：在本機寫一份 `HEARTBEATS.md`，列 2 個角色與醒來間隔（例：researcher 每 10 分鐘、writer 每 15 分鐘）；用 Windows 排程或一個簡單迴圈腳本，在每次「心跳」時讀 `inbox/<角色>.md`，有任務才呼叫 `claude -p` 處理、沒任務就記一行「無事」到 log。
- 預期結果：理解「定期醒來檢查有沒有事」的心跳模式，也看到沒事時幾乎不花成本，為第 6 章做準備。

## (c) 書中具體指令、設定檔名、CLI、網址、版本號（逐字）

- 設定檔名：`HEARTBEATS.md`
- 版本號：`v2026.517.0`（2026 年 5 月中）
- 發布日：March 2, 2026；授權：MIT license
- 數字：前六週 over 50,000 stars；2026 年 6 月中 around 70,000 stars、nearly 13,000 forks；程式碼 roughly 97.8 percent TypeScript；over a thousand code changes
- 品牌：Paperclip Labs；作者化名 @dotta
- 本章無 CLI 指令（演練中的 gh 指令為本筆記自擬，非書中內容）。
