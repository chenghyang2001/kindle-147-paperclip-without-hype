# K147 章節關係知識地圖：NotebookLM 三件套 ID 紀錄

- 來源文件：`doc/knowledge-map/k147-knowledge-map.md`（唯一來源）
- 筆記本：K147 Paperclip 章節關係知識地圖（新建，不是 K147 原本的筆記本 676e79c6）
- notebook_id：`2ec6bd5f-c92b-424b-a3ed-c1e767c77cfa`
- 筆記本連結：<https://notebook.google.com/notebook/2ec6bd5f-c92b-424b-a3ed-c1e767c77cfa>
- source_id：`bbe1d39e-2159-4216-8443-3acc16b73e22`
- 觸發時間：2026-11-28 02:23（台灣時間），在 VPS 觸發，語言 zh_Hant

| 類型 | artifact_id | 格式 |
| --- | --- | --- |
| 語音 | `79d9c50f-79fc-407c-87c8-57f335b75447` | deep-dive |
| 影片 | `654475c5-42c7-46ff-b689-fb8574d66912` | explainer |
| 簡報 | `4dff3203-0d23-4be5-b5ec-ccadc5691c36` | slide-deck（白底黑字） |

## 收尾與查進度

- VPS 工作目錄：`~/k147-knowledge-map-nlm/`（觸發腳本 `trigger.sh`、收尾腳本 `finish-trio.sh`）
- tmux：`k147-kmap-nlm`
- 進度：`ssh claude@187.127.109.145 'tail -5 ~/k147-knowledge-map-nlm/out/run.log'`
- 結束碼：`~/k147-knowledge-map-nlm/finish.exit`；結果：`~/k147-knowledge-map-nlm/out/summary.json`

## 交付紀錄

- 完成時間：2026-11-28 02:37（台灣時間），finish.sh 結束碼 0，`all_completed: true`，約 14 分鐘
- 語音 mp3（約 22 分 29 秒）：<https://drive.google.com/open?id=1Bu-nq8MCsWb1DZP6q-shvBIKxVDY6D2N>
- 影片 mp4（約 6 分 50 秒，explainer）：<https://drive.google.com/open?id=1rz2hMek2_A6chhjoivk3STWXJ41bh_cV>
- 簡報 PDF：<https://drive.google.com/open?id=1deiV3yRh-0jwkGtsM0rPL3ClC2WcAY2G>
- 簡報 PPTX：<https://drive.google.com/open?id=1dF16EY5MMjOTErWe35TXHgGBC4k91uJw>
- Drive 資料夾：`gdrive:NotebookLM/2026-11-28-k147-knowledge-map`
- Gmail：message id `1a21e4cdde1d4c1a`（寄給本人）
- LINE：n8n-peter 發送成功
- 抽查：簡報第 1 頁是「大綱」（6 項，白底）；影片第 1 個畫面是標題卡「Paperclip 無炒作知識地圖」，約第 8 秒才出現 5 張編號大綱卡（【開場規定】只部分生效）
