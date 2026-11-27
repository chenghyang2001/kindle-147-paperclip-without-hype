# K147《Paperclip – Without the Hype》演練教材＋規則草稿

Ronald Geißler 著（ASIN B0H6QRJ7GL），13 章。主題是開源專案 Paperclip（github.com/paperclipai/paperclip，MIT）：把 AI 代理當員工、Paperclip 當公司的「控制層」——組織圖、目標鏈、心跳、預算與核准閘門、機密與匯出。

> 練習內容為依各章重點原創撰寫，不含書籍原文。全書逐章繁中導讀（Step 10）放在私人 repo AutoRead-GoogleBook 的 `kindle-147-paperclip-without-hype/translations/`。

## 不裝官方套件、不用 API 金鑰：paperclip_lite

官方 Paperclip 是 npm 套件 `paperclipai`（Node.js＋React 儀表板＋內建 PostgreSQL）。演練改用 `practice/paperclip_lite.py`：一支 Python 檔做出書中核心零件（組織圖、目標鏈、O_EXCL 任務鎖、心跳、呼叫次數／金額上限、核准閘門、活動紀錄、匯出濾機密），代理的腦是 `claude -p`（Max 訂閱）。

```bash
cd practice
PYTHONUTF8=1 python paperclip_lite.py selftest
PYTHONUTF8=1 python paperclip_lite.py init demo-co
PYTHONUTF8=1 python paperclip_lite.py heartbeat demo-co --dry-run
```

## 結構

```
prompts/chNN.md          各章練習（這章在講什麼、作者的例子、練習提示詞、觀察重點、教練解說要點）
practice/paperclip_lite.py  迷你 Paperclip 控制層
practice/CLAUDE.md       練習視窗規則
practice/chNN/           練習產出（演練時產生）
teaching/drill.json      章節清單
teaching/DRILL-PROMPT.md 教練開場提示詞
teaching/HANDOFF.md      演練進度表＋怎麼開始
rules-extracted/         Step 11 規則草稿（feedback-b147-*.md，待核准後合併到 ~/.claude/instructions/kindle-rules/）
notes/chNN-candidates.md 各章規則／演練候選與書中指令清單
doc/k147-chapter-summary.md  NotebookLM 分章摘要
```

| 章 | 主題 | 練習數 |
| --- | --- | --- |
| ch01 | 從 AI 助理到 AI 公司 | 2 |
| ch02 | Paperclip 是什麼與不是什麼 | 2 |
| ch03 | @dotta 與炒作背後的故事 | 2 |
| ch04 | 架構總覽 | 2 |
| ch05 | 組織圖：目標如何抵達代理 | 2 |
| ch06 | 心跳、例行與排程 | 2 |
| ch07 | 治理、預算與成本控制 | 2 |
| ch08 | 自帶代理：你自己的員工 | 2 |
| ch09 | 你的第一家 AI 公司：逐步實作 | 2 |
| ch10 | 使用案例與自己的實驗 | 2 |
| ch11 | 限制、安全與法律 | 2 |
| ch12 | 生態系與競爭 | 2 |
| ch13 | 展望、結語與附錄 | 2 |

## 怎麼演練

HP1 螢幕 2（橫式）左右兩半：左半「K147 教練」、右半「K147 練習-全書」（工作目錄 practice/）。把 `teaching/DRILL-PROMPT.md` 送進教練視窗，教練一章一章跑完，每章 commit＋push。

> 快速 demo 模式產出：paperclip_lite.py 只跑過 selftest 與真實心跳冒煙測試，未經 QA／審查。
