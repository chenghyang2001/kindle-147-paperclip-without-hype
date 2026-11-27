# 第 9 章 候選：規則／演練／原文細節

來源：page_0034～page_0037

## (a) 規則候選

### 規則 1：安裝新工具時先檢查「可連線範圍」與「遙測」兩個開關

- **規則一句話**：幫使用者安裝任何自架服務時，第一次啟動就確認它只綁本機、並關閉遙測，再回報兩者狀態。
- **Why**：第 9 章注意框指出預設值為方便而調、不為謹慎；`--bind lan`／`--bind tailnet` 每擴大一次就擴大攻擊面，遙測預設開啟、應在一開始就關。
- **How to apply**：Claude 安裝後主動查監聽位址（如 `netstat -ano | findstr LISTENING`）確認是 127.0.0.1，查官方文件找關遙測的環境變數並設定，回報中列出「綁定位址／遙測狀態」。

### 規則 2：多代理實驗先裝煞車再開跑

- **規則一句話**：任何多代理或長時程自動化在開跑前，必須先有硬性預算上限、對外動作審批、可讀日誌三件事。
- **Why**：本章步驟四：這一步不是選配，它是受控實驗與空白支票的差別。
- **How to apply**：Claude 派背景代理或啟動工廠前，確認有 `--max-turns`／時間上限或花費上限、對外寄信改成草稿、log 檔路徑已定；缺任一項就先補上再開跑。

### 規則 3：「完成」不等於「正確」，交付前人工或獨立代理查核

- **規則一句話**：代理回報完成後，主管代理要另行驗證事實、來源與可用性，才標為完成。
- **Why**：本章迷思檢查：「代理回報完成，工作就是好的」→ 不是；步驟五強調檢查是最重要、人無可取代的任務。
- **How to apply**：Claude 收到子代理結果後，對含事實或來源的產出抽查網址與數字，或派驗證代理只拿規格＋產出物給 PASS／FAIL。

### 規則 4：從小開始——一個老闆、兩個員工、一份緊預算

- **規則一句話**：新的多代理架構先用最小編制（1 協調者＋2 執行者）跑通一個有範圍的目標，再擴編。
- **Why**：本章迷思檢查「越大越厲害」→ 起步時小比較好：更便宜、更好管、更能學到東西。
- **How to apply**：Claude 設計新工廠或代理團隊時，第一版只放三個角色並全部用同一個便宜模型，跑完一輪才討論加角色或換貴模型。

## (b) 演練候選

### 演練 1：用 claude -p 模擬「CEO＋研究員＋寫手」迷你公司（不需付費 API 帳號，走 Max 訂閱）

1. 建資料夾 `mini-co/`，寫三份角色說明：`ceo.md`（拆解目標、分派、彙整）、`researcher.md`（只找資料並附網址）、`writer.md`（依研究筆記寫 300 字草稿）。每份都寫「怎樣算做得好」。
2. 目標：`針對「Node.js 20 有哪些新功能」寫一篇附來源的部落格草稿`。
3. CEO：`claude -p --append-system-prompt-file ceo.md "目標：...，請輸出給研究員與寫手的兩段任務說明" > plan.md`
4. 研究員：`claude -p --append-system-prompt-file researcher.md --max-turns 5 "$(sed -n '/研究員/,/寫手/p' plan.md)" > research.md`
5. 寫手：`claude -p --append-system-prompt-file writer.md --max-turns 3 "依下列筆記寫草稿：$(cat research.md)" > draft.md`
6. 煞車：每個呼叫都加 `--max-turns`，不給寄信等對外工具；全部輸出存檔當日誌。
7. 人工查核：逐一點開 `draft.md` 的來源網址，標記真偽。

- **預期結果**：看到「拆工→執行→彙整」流程跑通，同時發現至少需要人工確認的地方（來源、數字），親身體會「完成≠正確」。

### 演練 2：Paperclip 本機安裝與安全開關檢查（可選，需 Node.js 20＋pnpm）

1. `node -v`（≥ 20）、`pnpm -v`（約 ≥ 9.15）；沒有 pnpm 用 `npm i -g pnpm`。
2. 快速路線：`npx paperclipai onboard --yes`；或手動路線：`git clone <官方 repo>` → `pnpm install` → `pnpm dev`。
3. 用 `netstat -ano | findstr LISTENING` 確認儀表板只綁 127.0.0.1；查官方文件找關遙測的環境變數並設好。
4. 瀏覽器開儀表板，只建 CEO＋2 員工，不接任何金鑰，先看空公司長什麼樣。

- **預期結果**：一個只在本機、遙測已關的 Paperclip 實例；指令若與書不同，以官方頁為準並記下差異。

## (c) 書中具體細節（逐字）

- 快速啟動指令：`npx paperclipai onboard --yes`（書中寫「something like」，以官方為準）
- `--yes`：確認設定一路跑完、不再提示
- 手動安裝：`git clone …`、`pnpm install`、`pnpm dev`
- 可連線範圍選項：`--bind lan`、`--bind tailnet`
- 遙測關閉方式：透過環境變數（書中未給變數名）
- 儀表板位址：本機位址＋固定連接埠（書中未給埠號）
- 版本需求：Node.js `20` 或更新；pnpm `9.15` 左右以上
- 資料庫：內嵌（embedded）`PostgreSQL`，自動設定
- 組織圖範例角色：`CEO`、`writer`、`researcher`
- 煞車：`hard stop` 總預算、`approval`（寄信、改資料、下訂單）、`log`
- 金鑰：`secret management`
- 範例目標：Create a well-researched draft for a blog article on topic X, with sources.
- 網址：無（只說「official project pages」）
