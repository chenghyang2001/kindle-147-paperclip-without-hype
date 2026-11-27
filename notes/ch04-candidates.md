# 第 4 章 候選規則與演練（架構總覽）

來源：page_0016～page_0020

## (a) 規則候選

### R04-1 平行代理一律「先簽出再動手」，避免重工

- **規則一句話**：派多個子代理平行處理同一批工作時，每個工作單位先登記「誰認領」（簽出／上鎖），沒有認領紀錄的單位不准動手。
- **Why**：本章說明任務系統的原子簽出（atomic checkout）與執行鎖（execution locks），用意是「任務在某代理處理期間只屬於它」，就像圖書館不會把同一本書借兩次；沒有這層鎖，多代理同時作業會互相覆蓋、修改遺失。
- **How to apply**：主 Claude 平行派工前，先在看板（例：`~/.claude/context/supervisor-board.md` 或工作目錄的進度表）為每個單位寫下負責的子代理；子代理開工前先確認自己是該單位的唯一認領者，完成或失敗時釋放。

### R04-2 每個平行寫入者用獨立工作副本，檢查後才合併

- **規則一句話**：會改同一個 repo 的平行子代理，各自在獨立的 git worktree（或分支）作業，經驗證後才合併回主線。
- **Why**：本章第 5 塊積木「工作環境與執行期」用 git worktrees 讓每個代理有自己的乾淨工作台，「只有經過檢查的成果才會合併」，因此多人同時作業時共同成果依然穩定。
- **How to apply**：派兩個以上會寫檔的子代理到同一 repo 時，主動用 `isolation: "worktree"` 或 `/code-session`，並把「合併前驗證」列進完成定義。

### R04-3 「已完成」不等於「做對了」，重要產出另派驗收

- **規則一句話**：子代理回報「完成」只代表流程走完，重要產出必須另有驗證（驗證代理或真實測試）才算完成。
- **Why**：本章「注意」框：Paperclip 能完美記錄代理「完成」任務，但結果對不對架構不會告訴你，那需要檢查，而檢查最終靠人；本章重點也說它「組織工作但不檢查品質」。
- **How to apply**：主 Claude 收到對外、改程式、不可逆類產出時，派驗證代理只拿「規格＋產出物」回 PASS／FAIL；看板只把驗收通過者標為完成。

### R04-4 分享或匯出設定一律先去除機密

- **規則一句話**：把設定、範本、工作流程匯出給別台機器或別人時，先把金鑰、密碼、token 濾掉，接手方自行填入。
- **Why**：本章公司可攜性的「機密清除（secret scrubbing）」：若金鑰隨匯出流傳，每份範本都是資安漏洞，所以刻意把「結構」與「機密」分開。
- **How to apply**：Claude 產出可分享的設定檔（.json、.env 範本、skill 範例）時，自動以 `.env.example` 佔位字取代真值，並在 commit 前 grep 金鑰樣式。

## (b) 演練候選

### D04-1 用 git worktree 體驗「隔離工作台」

- 步驟：
  1. `mkdir wt-demo && cd wt-demo && git init && echo "v1" > doc.txt && git add . && git commit -m init`
  2. `git worktree add ../wt-agent-a -b agent-a`、`git worktree add ../wt-agent-b -b agent-b`
  3. 在兩個目錄各自修改 `doc.txt` 的不同行並 commit。
  4. 回主目錄依序 `git merge agent-a`、`git merge agent-b`，觀察是否衝突；故意讓兩邊改同一行再試一次。
- 預期結果：改不同行時乾淨合併；改同一行時出現衝突——對應本章「鎖能管同一份材料的秩序，但管不了內容上互相矛盾」的提醒。

### D04-2 用檔案鎖模擬原子簽出

- 步驟：寫一個小 Python 腳本，兩個行程同時嘗試以 `os.open(path, os.O_CREAT | os.O_EXCL)` 建立 `task-001.lock`；成功者印「認領」，失敗者印「已被認領，跳過」。用兩個終端機同時執行。
- 預期結果：永遠只有一個行程認領成功，理解「單一、不可中斷的步驟」這個「原子」的意思。

## (c) 書中出現的具體名詞／技術（逐字）

- TypeScript
- Node.js（server）
- PostgreSQL（embedded database）
- git worktrees
- atomic checkout、execution locks
- cron、webhook
- plugins
- secret scrubbing
- 指令、設定檔名、網址、版本號：無（本章未列出；安裝留到 Chapter 9）
