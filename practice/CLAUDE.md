# K147 練習視窗說明（工作目錄＝practice/）

你是 K147《Paperclip – Without the Hype》演練的「練習」視窗。教練會送來每章的練習提示詞，照做並把結果存到 `chNN/`。一律繁體中文。

## 可用工具：paperclip_lite.py

書中 Paperclip（官方 npm 套件 `paperclipai`，Node.js 伺服器＋React 儀表板）的迷你 Python 版，只保留書裡的核心零件，讓你在本機親手體驗：

| 指令 | 對應書中零件 |
| --- | --- |
| `python paperclip_lite.py init <公司目錄>` | 建公司：3 個代理（ceo／researcher／writer）、2 個任務、1 份機密 |
| `python paperclip_lite.py org <公司目錄>` | 組織圖＋呈報線＋每個代理的預算上限 |
| `python paperclip_lite.py task <公司目錄> --title ... --assignee ... [--approval]` | 新增任務（可要求人類核准） |
| `python paperclip_lite.py heartbeat <公司目錄> [--agent X] [--dry-run]` | 心跳：每個代理醒來一次、接一件任務（O_EXCL 任務鎖）、呼叫 `claude -p`、記帳 |
| `python paperclip_lite.py approve <公司目錄> <任務ID>` | 人類核准閘門 |
| `python paperclip_lite.py status <公司目錄>` | 任務狀態＋預算帳本 |
| `python paperclip_lite.py export <公司目錄> <輸出.json>` | 匯出結構，機密一律濾掉 |
| `python paperclip_lite.py selftest` | 不呼叫模型的冒煙測試 |

公司目錄裡的檔案：`company.json`（目標、代理、專案）、`tasks.json`、`ledger.json`（每個代理的呼叫次數與金額）、`secrets.json`、`activity.jsonl`（活動紀錄）、`outputs/<任務ID>.md`、`locks/`。

## 規則

1. 每個練習的公司目錄一律建在 `chNN/` 底下（例：`chNN/co`），不要動別章的資料夾。
2. 執行 Python 一律加 `PYTHONUTF8=1`。
3. 代理的模型呼叫走 `claude -p`（Max 訂閱），**不要設定或讀取任何 API 金鑰**。每次 `heartbeat`（非乾跑）約 1～3 次呼叫，練習提示詞寫的呼叫上限要遵守。
4. 不修改 `paperclip_lite.py`；要改行為時，複製到 `chNN/` 底下改副本。
5. 不安裝官方 `paperclipai`（套件很大、會內建 PostgreSQL），除非練習明確要求。
6. 把實際指令輸出存成 `.txt`，讓教練確認是真的跑出來的。
