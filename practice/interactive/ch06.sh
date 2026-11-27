#!/bin/bash
# K147 第 6 章互動演練：心跳、例行與排程——乾跑、真心跳、空心跳、任務鎖、節奏成本，一次跑一步
# 用法：bash ch06.sh <步驟 1-8>
# 呼叫模型：只有第 3 步（第 1 拍真心跳）會呼叫模型 2 次（researcher＋writer，經 paperclip_lite 走 claude -p haiku），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch06/interactive"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K147 第 6 章｜心跳與排程　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }
runsh() { (cd "$PRACTICE" && export PYTHONUTF8=1 && eval "$1"); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "建公司，第 0 拍乾跑：誰會醒、誰繼續睡"
   tip "乾跑只看「這一拍會做什麼」，不呼叫模型、不花錢。注意 writer 為什麼沒接 T002。"
   rm -rf "$WORK"; mkdir -p "$WORK"
   P='python paperclip_lite.py init ch06/interactive/co
python paperclip_lite.py heartbeat ch06/interactive/co --dry-run | tee ch06/interactive/beat0-dry.txt'
   show "$P"; runsh "$P" ;;
2) banner "第 0 拍之後的帳本：全部是 0"
   tip "乾跑不記帳。先把這時的帳本存一份，等一下拿來比對真心跳花了幾次呼叫。"
   P='python paperclip_lite.py status ch06/interactive/co
cp ch06/interactive/co/ledger.json ch06/interactive/ledger0.json
echo "已存帳本快照 ch06/interactive/ledger0.json"'
   show "$P"; runsh "$P" ;;
3) banner "第 1 拍真心跳：研究員交件，寫手同一拍接手"
   tip "這一步會呼叫模型 2 次（claude -p haiku），約 30～60 秒；每次結果可能不同，照實記錄。"
   P='time python paperclip_lite.py heartbeat ch06/interactive/co 2>&1 | tee ch06/interactive/beat1.txt
cp ch06/interactive/co/ledger.json ch06/interactive/ledger1.json
grep -q "完成 T001" ch06/interactive/beat1.txt || echo "（這一拍沒有完成 T001，後面步驟會照常往下，只是沒有產出可以判定）"'
   show "$P"; runsh "$P" ;;
4) banner "看帳本差，再用程式規則判定：完成不等於合格"
   tip "判定前先剝掉程式碼圍欄、括號附註、「註／附註／※／備註」開頭的行，再數行數和字數。"
   P='import json, re
from pathlib import Path
d = Path("ch06/interactive")
co = d / "co"
def load(p):
    try:
        return json.loads(Path(p).read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}
before, after = load(d / "ledger0.json"), load(d / "ledger1.json")
print("帳本差（第 1 拍前 → 後）：")
for aid in ("ceo", "researcher", "writer"):
    b = before.get(aid, {}).get("calls", 0); a = after.get(aid, {}).get("calls", 0)
    print("  {:<10} {} → {} 次（+{}）".format(aid, b, a, a - b))
print()
print("任務狀態：")
for t in load(co / "tasks.json") or []:
    print("  {} [{}] {}".format(t["id"], t["status"], t["assignee"]))
NOTE = re.compile(r"^\s*(註|附註|※|備註)")
PAREN = re.compile(r"^\s*[（(].*[）)]\s*$")
def strip_extras(text):
    keep = []
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith("\x60\x60\x60") or PAREN.match(s) or NOTE.match(s):
            continue
        keep.append(s)
    return keep
print()
t1 = co / "outputs" / "T001.md"
if t1.exists():
    raw = t1.read_text(encoding="utf-8")
    lines = strip_extras(raw)
    items = [x for x in lines if re.match(r"^(\d+[.、)）]|[-*•]\s)", x)]
    print("T001 研究員（規則：3 個重點、各一句話 = 剝掉後剛好 3 行，或剛好 3 條條列）")
    print("  原始非空行數 {} → 剝掉後 {} 行，其中條列 {} 條".format(len([x for x in raw.splitlines() if x.strip()]), len(lines), len(items)))
    for x in lines[:6]:
        print("   |", x[:60])
    ok = len(lines) == 3 or len(items) == 3
    print("  判定：", "PASS" if ok else "FAIL（行數和條列數都不是 3）")
else:
    print("T001 沒有產出檔，無法判定")
print()
t2 = co / "outputs" / "T002.md"
if t2.exists():
    raw = t2.read_text(encoding="utf-8")
    body = "".join(strip_extras(raw))
    chars = len(re.sub(r"[\s#*>\-]", "", body))
    print("T002 寫手（規則：200 字左右，不超過 300 字）")
    print("  原始 {} 字元 → 剝掉後正文 {} 字".format(len(raw), chars))
    print("  判定：", "PASS" if 120 <= chars <= 300 else "FAIL（字數不在 120～300）")
    print("  狀態停在 awaiting_approval：寫手做完了，但要人類 approve 才算數")
else:
    print("T002 沒有產出檔，無法判定")
print()
print("代理說「完成」只是狀態；合不合格，要交給程式規則和人來判定。")'
   show "$P"; run "$P" ;;
5) banner "第 2 拍真心跳：沒事可做，就不呼叫模型"
   tip "這一拍是真跑，不是乾跑；但沒有可做的任務，模型一次都不會被叫醒。"
   P='python paperclip_lite.py heartbeat ch06/interactive/co | tee ch06/interactive/beat2.txt
cp ch06/interactive/co/ledger.json ch06/interactive/ledger2.json
if python -c "import sys,pathlib; a,b=[pathlib.Path(f).read_bytes() for f in sys.argv[1:]]; sys.exit(a!=b)" ch06/interactive/ledger1.json ch06/interactive/ledger2.json; then echo "帳本完全沒變：第 2 拍 0 次模型呼叫"; else echo "帳本有變動，請檢查"; fi
echo "呼叫模型之前的便宜檢查（paperclip_lite.py）："
grep -n "def budget_block_reason\|def pick_task\|沒有可做的任務" paperclip_lite.py'
   show "$P"; runsh "$P" ;;
6) banner "任務鎖：別人接走的任務，我不會重接"
   tip "try_checkout 用 O_EXCL 建鎖檔，建得出來才算接到；接不到時不碰別人的鎖。"
   P='python paperclip_lite.py init ch06/interactive/co2
echo other-agent > ch06/interactive/co2/locks/T001.lock
echo "── 鎖被別人拿著時乾跑 researcher："
python paperclip_lite.py heartbeat ch06/interactive/co2 --agent researcher --dry-run | head -1
echo "── 鎖檔還在嗎？"; ls ch06/interactive/co2/locks; cat ch06/interactive/co2/locks/T001.lock
rm ch06/interactive/co2/locks/T001.lock
echo "── 刪掉鎖之後再乾跑："
python paperclip_lite.py heartbeat ch06/interactive/co2 --agent researcher --dry-run | head -1
echo "── 乾跑結束後 locks/ 內容（應為空，鎖已被 release）："; ls ch06/interactive/co2/locks; echo "（以上空白＝沒有殘留鎖）"'
   show "$P"; runsh "$P" ;;
7) banner "節奏成本試算：節奏紀律就是預算紀律"
   tip "3 個代理，心跳每 5 分鐘、每小時、每天 1 次；比較「沒事不呼叫」和「檢查也要問模型」。"
   P='import json
from pathlib import Path
d = Path("ch06/interactive")
try:
    led = json.loads((d / "co" / "ledger.json").read_text(encoding="utf-8"))
except (OSError, ValueError):
    led = {}
calls = sum(r.get("calls", 0) for r in led.values())
usd = sum(r.get("usd", 0.0) for r in led.values())
unit = usd / calls if calls else 0.0
print("ch06 實際帳本：{} 次呼叫、${:.4f} → 單價約 ${:.4f}／次".format(calls, usd, unit))
if unit == 0:
    print("（單價是 0：訂閱模式下 claude -p 可能不回報真實價格，下面成本也會是 0，看次數即可）")
print()
AGENTS, REAL_TASKS, DAYS = 3, 60, 30
print("{:<10} | {:>10} | {:>14} | {:>14} | {:>10} | {:>10}".format("節奏", "每月心跳", "沒事不呼叫(次)", "檢查也問(次)", "前者$", "後者$"))
print("-" * 84)
for name, per_day in (("每 5 分鐘", 24 * 12), ("每小時", 24), ("每天 1 次", 1)):
    beats = AGENTS * per_day * DAYS
    lazy = min(beats, REAL_TASKS)
    eager = beats
    print("{:<10} | {:>10,} | {:>14,} | {:>14,} | {:>10.2f} | {:>10.2f}".format(name, beats, lazy, eager, lazy * unit, eager * unit))
print()
print("沒事不呼叫：不論節奏多密，上限就是真正的任務數 {} 件".format(REAL_TASKS))
print("檢查也問模型：每 5 分鐘一拍是每天 1 次的 288 倍，失控迴圈就是這樣燒錢")
print("結論：每天整理收件匣選「每小時」或「每天」就夠，必要時才頻繁，能少就少")'
   show "$P"; run "$P" ;;
8) banner "總結：心跳是檢查邀請，不是行動命令"
   tip "本章四個重點，加上這次留下的產出檔。"
   P='from pathlib import Path
points = [
    "心跳是計時守門人：每一拍先看有沒有自己的事，沒事就再睡。",
    "同一拍內 researcher 一完成，writer 就接手：這是「內部事件」觸發的交接，不用人轉交。",
    "lite 版在呼叫模型前先做便宜檢查（預算、pick_task），所以沒事的心跳 0 次呼叫、0 元。",
    "任務鎖讓「誰在做」只有一個答案：鎖不住內容衝突，但鎖住了重工。",
    "節奏太密會悄悄燒錢；完成不等於合格，判定交給程式規則和人。",
]
print("第 6 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("本章產出檔案：")
d = Path("ch06/interactive")
for name in ("beat0-dry.txt", "ledger0.json", "beat1.txt", "ledger1.json", "beat2.txt", "ledger2.json",
             "co/outputs/T001.md", "co/outputs/T002.md", "co/activity.jsonl"):
    p = d / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac
