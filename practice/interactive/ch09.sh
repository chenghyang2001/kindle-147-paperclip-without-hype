#!/bin/bash
# K147 第 9 章互動演練：你的第一家 AI 公司，逐步實作——安裝、組織圖、接代理、煞車、目標與觀察，一次跑一步
# 用法：bash ch09.sh <步驟 1-8>
# 呼叫模型：只有第 5 步一次真心跳（paperclip_lite heartbeat → claude -p haiku，最多 3 次），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch09/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K147 第 9 章｜第一家 AI 公司　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }
runsh() { (cd "$PRACTICE" && export PYTHONUTF8=1 && eval "$1"); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "步驟一 安裝：先跑冒煙測試，再建公司"
   tip "書裡的安裝是一行 onboard --yes；lite 版只要一支 Python 檔。先 selftest（不呼叫模型），再 init。"
   rm -rf "$WORK"; mkdir -p "$WORK"
   P='python paperclip_lite.py selftest
python paperclip_lite.py init ch09/interactive/co
ls ch09/interactive/co'
   show "$P"; runsh "$P" ;;
2) banner "步驟二 組織圖：一個 CEO、兩個員工，每個角色寫「做得好＝…」"
   tip "角色描述就是職務說明。寫手的任務要人類核准，因為發布是對外動作。"
   P='import json
from pathlib import Path
co = Path("ch09/interactive/co")
company = json.loads((co / "company.json").read_text(encoding="utf-8"))
company["name"] = "第一家 AI 公司（ch09）"
company["goal"] = "針對主題「Node.js 20 的三個重要新功能」，寫一篇研究充分、附來源的部落格文章草稿"
company["projects"] = [{"id": "P1", "title": "部落格草稿：Node.js 20 的三個重要新功能（附來源）", "goal": "company"}]
ROLES = {
    "ceo": "執行長：把目標拆成給研究員與寫手的具體指示。做得好＝指示短、可檢查、不重複",
    "researcher": "研究員：列出事實與官方來源網址。做得好＝每項可追溯，不確定的標「未確認」",
    "writer": "寫手：依研究重點寫 300 字內草稿。做得好＝不加研究員沒給的內容，文末列來源",
}
for a in company["agents"]:
    a["model"] = "haiku"
    a["role"] = ROLES[a["id"]]
tasks = [
    {"id": "T001", "title": "把公司目標拆成給研究員與寫手的兩段具體指示（各 3～5 行）", "assignee": "ceo",
     "project": "P1", "needs_approval": False, "status": "todo"},
    {"id": "T002", "title": "依 CEO 指示列出 Node.js 20 的 3 個重要新功能，每項一句說明＋一個官方來源網址；不確定的標「未確認」",
     "assignee": "researcher", "project": "P1", "needs_approval": False, "depends_on": "T001", "status": "todo"},
    {"id": "T003", "title": "依研究員的重點寫 300 字內的部落格草稿，文末列出來源網址；沒有來源的內容不要寫",
     "assignee": "writer", "project": "P1", "needs_approval": True, "depends_on": "T002", "status": "todo"},
]
ledger = {a["id"]: {"calls": 0, "usd": 0.0, "paused": False} for a in company["agents"]}
for name, data in (("company.json", company), ("tasks.json", tasks), ("ledger.json", ledger)):
    (co / name).write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
print("已改寫 company.json、tasks.json、ledger.json")
for t in tasks:
    print("  {} → {}｜依賴 {}｜要核准 {}".format(t["id"], t["assignee"], t.get("depends_on", "無"), t["needs_approval"]))
print()
import subprocess, sys
sys.stdout.flush()
subprocess.run([sys.executable, "paperclip_lite.py", "org", str(co)])'
   show "$P"; run "$P" ;;
3) banner "步驟三 接代理與金鑰：機密只放 secrets.json"
   tip "金鑰是假值，只示範位置。grep 應該在 company.json、tasks.json 裡找不到它。"
   P='echo "{\"MODEL_ACCESS_KEY\": \"placeholder-not-a-real-key\"}" > ch09/interactive/co/secrets.json
echo "secrets.json 已改成假金鑰（不印出值）"
echo "grep company.json / tasks.json："
grep -rn "placeholder-not-a-real-key" ch09/interactive/co/company.json ch09/interactive/co/tasks.json || echo "  沒有命中：機密沒有混進結構檔"
echo
echo "lite 版的代理走 claude -p（Max 訂閱），程式在呼叫前拿掉 ANTHROPIC_ 開頭的環境變數；"
echo "正式 Paperclip 的金鑰要放進它的機密管理，不寫進組織設定。"'
   show "$P"; runsh "$P" ;;
4) banner "步驟四 煞車：每人 1 次、0.10 美元，先乾跑不花錢"
   tip "硬性停止的預算，是「受控實驗」和「空白支票」的差別。乾跑只會看到 CEO 的提示詞。"
   P='python - <<EOF
import json
from pathlib import Path
p = Path("ch09/interactive/co/company.json")
c = json.loads(p.read_text(encoding="utf-8"))
for a in c["agents"]:
    a["max_calls"], a["max_usd"] = 1, 0.10
p.write_text(json.dumps(c, ensure_ascii=False, indent=2), encoding="utf-8")
print("三個代理都設成 max_calls 1、max_usd 0.10")
EOF
python paperclip_lite.py org ch09/interactive/co
echo
python paperclip_lite.py heartbeat ch09/interactive/co --dry-run'
   show "$P"; runsh "$P" ;;
5) banner "步驟五 給目標並觀察：一次真心跳（最多 3 次模型呼叫）"
   tip "這一步呼叫 claude -p（haiku）最多 3 次，約 1 分鐘。CEO → 研究員 → 寫手依依賴在同一拍做完，T003 停在等待核准。"
   P='start=$(date +%s)
python paperclip_lite.py heartbeat ch09/interactive/co 2>&1 || echo "心跳沒有成功，第 7 步會改用內建範例繼續"
echo "（本拍耗時 $(( $(date +%s) - start )) 秒）"
echo
python paperclip_lite.py status ch09/interactive/co'
   show "$P"; runsh "$P" ;;
6) banner "硬性停止生效了嗎？再乾跑一次，然後匯出"
   tip "每個代理都用完 1 次，乾跑也應該被擋下。匯出只帶結構，機密命中數要是 0。"
   P='python paperclip_lite.py heartbeat ch09/interactive/co --dry-run
echo
python paperclip_lite.py export ch09/interactive/co ch09/interactive/export.json
echo -n "export.json 裡的假金鑰命中數："
grep -c "placeholder-not-a-real-key" ch09/interactive/export.json || true'
   show "$P"; runsh "$P" ;;
7) banner "人工查核：「完成」不等於「正確」"
   tip "先剝掉圍欄和附註再判定；網址回 200 只代表網頁存在，不代表內容支持那句話。全部通過才核准 T003。"
   P='import re, subprocess, sys
from pathlib import Path
co = Path("ch09/interactive/co")
out = Path("ch09/interactive")
def strip_extras(text):
    keep = []
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith("```"):
            continue
        if (s.startswith("（") and s.endswith("）")) or (s.startswith("(") and s.endswith(")")):
            continue
        if s.startswith(("註", "附註", "※", "備註")):
            continue
        keep.append(s)
    return keep
FALLBACK = {
    "T002": "1. 內建測試執行器 node:test 轉為穩定。來源：https://nodejs.org/en/blog/release/v20.0.0\n2. 權限模型（實驗性）。來源：https://nodejs.org/api/permissions.html\n3. 單一執行檔應用（實驗性）。來源：https://nodejs.org/api/single-executable-applications.html",
    "T003": "```\nNode.js 20 帶來三個值得注意的新功能：內建測試執行器 node:test 轉為穩定、實驗性的權限模型，以及單一執行檔應用。\n來源：https://nodejs.org/en/blog/release/v20.0.0\n```\n（以上為草稿）",
}
src = {}
for tid in ("T001", "T002", "T003"):
    f = co / "outputs" / (tid + ".md")
    src[tid] = f.read_text(encoding="utf-8") if f.exists() else FALLBACK.get(tid, "")
used_fallback = not (co / "outputs" / "T003.md").exists()
print("資料來源：", "內建範例（第 5 步沒有成功）" if used_fallback else "第 5 步真實模型輸出")
for tid in ("T001", "T002", "T003"):
    raw_n = len([l for l in src[tid].splitlines() if l.strip()])
    print("  {} 原始 {} 行 → 剝掉圍欄與附註後 {} 行".format(tid, raw_n, len(strip_extras(src[tid]))))
draft = "\n".join(strip_extras(src["T003"]))
print()
print("寫手草稿（剝掉後，前 6 行）：")
for l in draft.splitlines()[:6]:
    print("  ", l[:70])
URL = re.compile(r"https?://[^\s（）()\[\]<>\"`，。、]+")
d_urls = sorted(set(u.rstrip(".,") for u in URL.findall(draft)))
r_urls = set(u.rstrip(".,") for u in URL.findall(src["T002"]))
body = re.sub(URL, "", draft)
n_chars = len(re.sub(r"[\s#*`>|-]", "", body))  # 不算 Markdown 符號
extra = [u for u in d_urls if u not in r_urls]
checks = [
    ("草稿 300 字內（不含網址）", n_chars <= 300, "{} 字".format(n_chars)),
    ("有來源網址", bool(d_urls), "{} 個".format(len(d_urls))),
    ("網址都出自研究員 T002（沒加料）", not extra, "多出 {}".format(extra) if extra else "全部出自 T002"),
]
codes = []
for u in d_urls[:3]:
    try:
        r = subprocess.run(["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "-L", "--max-time", "8", u],
                           capture_output=True, text=True, timeout=15)
        codes.append((u, r.stdout.strip() or "000"))
    except (OSError, subprocess.TimeoutExpired):
        codes.append((u, "逾時"))
checks.append(("網址打得開（HTTP 200）", bool(codes) and all(c == "200" for _, c in codes),
               "、".join(c for _, c in codes) or "沒有網址可查"))
print()
for name, ok, why in checks:
    print("  [{}] {}：{}".format("通過" if ok else "不通過", name, why))
for u, c in codes:
    print("      {}  {}".format(c, u[:70]))
print()
print("提醒：200 只證明網頁存在，不證明內容支持那句話；這一欄仍要人打開來讀。")
report = ["# 第 9 章查核報告", ""] + ["- {}：{}（{}）".format(n, "通過" if ok else "不通過", w) for n, ok, w in checks]
if all(ok for _, ok, _ in checks) and not used_fallback:
    r = subprocess.run([sys.executable, "paperclip_lite.py", "approve", str(co), "T003"], capture_output=True, text=True)
    print("結論：全部通過 →", r.stdout.strip() or r.stderr.strip())
    report.append("結論：核准 T003")
else:
    bad = [n for n, ok, _ in checks if not ok] or ["使用內建範例，不能核准"]
    print("結論：不核准，T003 保持 awaiting_approval。退回修改：" + "；".join(bad))
    report.append("結論：不核准，退回修改：" + "；".join(bad))
(out / "check-report.md").write_text("\n".join(report) + "\n", encoding="utf-8")
print("已寫入", out / "check-report.md")'
   show "$P"; run "$P" ;;
8) banner "練習 2：書中五步 vs lite 版，對照與總結"
   tip "知道 lite 省略了什麼，正式上線時才知道要補什麼。"
   P='from pathlib import Path
ROWS = [
    ("安裝", "onboard --yes 或 clone→install→dev；Node 20＋pnpm", "一支 paperclip_lite.py＋selftest", "儀表板、內嵌 PostgreSQL"),
    ("可連線範圍", "預設只在本機，要刻意選", "只在本機檔案系統", "網路服務、登入"),
    ("遙測", "預設開啟，一開始就關", "沒有遙測", "（不需補）"),
    ("機密", "機密管理，不寫進組織設定", "secrets.json，匯出時濾掉", "加密、權限、輪替"),
    ("預算", "80% 警告、100% 硬停、董事會推翻", "max_calls／max_usd 硬停", "80% 警告、月度重置"),
    ("審批", "對外動作一律送審", "needs_approval＋approve", "多層審批、退回理由欄位"),
    ("日誌", "完整活動日誌，要有人看", "activity.jsonl", "查詢介面、警示"),
]
print("{:<6}｜{:<28}｜{:<24}｜{}".format("項目", "書中正式版", "lite 版", "lite 省略、上線要補"))
print("-" * 92)
for r in ROWS:
    print("{:<6}｜{:<28}｜{:<24}｜{}".format(*r))
print()
points = [
    "從小開始：一個 CEO、兩個員工、一份很緊的預算。",
    "每個角色寫「存在目的＋做得好＝…」，三個代理先用同一個便宜模型。",
    "煞車不是選配：硬停預算、對外動作要審批、看日誌。",
    "最重要的一步屬於人：先剝掉多餘內容再用規則判定，網址 200 也不等於內容正確。",
]
print("第 9 章重點：")
for i, p in enumerate(points, 1):
    print("  {}. {}".format(i, p))
print()
print("本章產出檔案：")
for name in ("co/company.json", "co/tasks.json", "co/ledger.json", "co/activity.jsonl", "co/outputs/T003.md", "export.json", "check-report.md"):
    p = Path("ch09/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac
