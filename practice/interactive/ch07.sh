#!/bin/bash
# K147 第 7 章互動演練：治理、預算與成本控制——預算硬停、核准閘門、董事會推翻，一次跑一步
# 用法：bash ch07.sh <步驟 1-8>
# 呼叫模型：第 3、4、7 步各 1 次（paperclip_lite heartbeat → claude -p haiku），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
WORK="$PRACTICE/ch07/interactive"
CO="ch07/interactive/co"
mkdir -p "$WORK"
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K147 第 7 章｜治理與預算　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }
runsh() { (cd "$PRACTICE" && export PYTHONUTF8=1 && eval "$1"); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "先把煞車調緊：writer 只准呼叫 1 次"
   tip "一開始就刻意把預算設緊。只改公司設定檔 company.json，不動 paperclip_lite.py。"
   P='rm -rf ch07/interactive && mkdir -p ch07/interactive
python paperclip_lite.py init ch07/interactive/co
python - <<EOF
import json; from pathlib import Path
f = Path("ch07/interactive/co/company.json"); c = json.loads(f.read_text(encoding="utf-8"))
w = next(a for a in c["agents"] if a["id"] == "writer")
print("writer max_calls：", w["max_calls"], "→ 1"); w["max_calls"] = 1
f.write_text(json.dumps(c, ensure_ascii=False, indent=2), encoding="utf-8")
EOF
python paperclip_lite.py org ch07/interactive/co'
   show "$P"; runsh "$P" ;;
2) banner "再給 writer 一件不需核准的小任務 T003"
   tip "T002 要人類核准；T003 只是一句比喻，不需核准。兩件都排給只剩 1 次額度的 writer。"
   P='python paperclip_lite.py task ch07/interactive/co --title "寫一句 30 字內、讓新手看懂心跳排程的比喻" --assignee writer
python paperclip_lite.py status ch07/interactive/co'
   show "$P"; runsh "$P" ;;
3) banner "第 1 次呼叫：researcher 交出 T001"
   tip "這一步會呼叫模型 1 次（claude -p haiku），大約 10～30 秒；每次結果可能不同。"
   P='python paperclip_lite.py heartbeat ch07/interactive/co --agent researcher 2>&1 || echo "（心跳沒成功，後面步驟照常示範）"
echo "--- T001 產出 ---"
cat ch07/interactive/co/outputs/T001.md 2>/dev/null || echo "（沒有產出檔）"'
   show "$P"; runsh "$P" ;;
4) banner "第 2 次呼叫：writer 接 T002，停在待核准"
   tip "T002 排在 T003 前面，T001 已完成，所以 writer 先接 T002。寫完不會變 done，而是停在 awaiting_approval。"
   P='import subprocess, sys, re
from pathlib import Path
CO = "ch07/interactive/co"
r = subprocess.run([sys.executable, "paperclip_lite.py", "heartbeat", CO, "--agent", "writer"], capture_output=True, text=True, encoding="utf-8")
print((r.stdout + r.stderr).strip() or "（沒有輸出）")
def strip_extras(text):
    keep = []
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith("```"):
            continue
        if re.fullmatch(r"[（(].*[）)]", s) or s.startswith(("註", "附註", "※", "備註")):
            continue
        keep.append(s)
    return keep
f = Path(CO) / "outputs" / "T002.md"
if f.exists():
    raw = f.read_text(encoding="utf-8")
    clean = strip_extras(raw)
    print()
    print("--- T002 草稿（剝掉圍欄與附註後，前 6 行）---")
    for line in clean[:6]:
        print("  " + line[:70])
    print()
    print("原始行數 {}，剝掉後行數 {}，正文約 {} 字".format(len(raw.splitlines()), len(clean), len("".join(clean))))
else:
    print("（沒有 T002 產出檔）")'
   show "$P"; run "$P" ;;
5) banner "撞牆：writer 額度用完，心跳直接暫停"
   tip "預算是在呼叫模型「之前」檢查的，所以撞牆這一拍不花任何錢。"
   P='python paperclip_lite.py heartbeat ch07/interactive/co --agent writer 2>&1
echo "--- 帳本與任務 ---"
python paperclip_lite.py status ch07/interactive/co'
   show "$P"; runsh "$P" ;;
6) banner "核准閘門：只放行 awaiting_approval"
   tip "先故意核准還沒做的 T003，應該被拒；再核准真正在等的 T002。"
   P='echo "【故意核准 T003】"
python paperclip_lite.py approve ch07/interactive/co T003 2>&1 || echo "→ 被擋是正確的：T003 還沒做，不能核准（非零結束碼屬正常）"
echo
echo "【核准 T002】"
python paperclip_lite.py approve ch07/interactive/co T002 2>&1 || echo "→ T002 不在待核准狀態（可能第 4 步沒成功）"
echo
python paperclip_lite.py status ch07/interactive/co'
   show "$P"; runsh "$P" ;;
7) banner "董事會推翻：明確、留紀錄地拆牆，再跑第 3 次"
   tip "推翻要同時做三件事：改上限、解除暫停、在活動紀錄寫下誰、何時、為什麼。這一步會呼叫模型 1 次。"
   P='import json, re, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path
co = Path("ch07/interactive/co")
c = json.loads((co / "company.json").read_text(encoding="utf-8"))
next(a for a in c["agents"] if a["id"] == "writer")["max_calls"] = 2
(co / "company.json").write_text(json.dumps(c, ensure_ascii=False, indent=2), encoding="utf-8")
led = json.loads((co / "ledger.json").read_text(encoding="utf-8"))
led["writer"]["paused"] = False
(co / "ledger.json").write_text(json.dumps(led, ensure_ascii=False, indent=2), encoding="utf-8")
entry = {"ts": datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds"), "actor": "owner",
         "action": "board_override", "agent": "writer", "reason": "T003 是一句話的小任務，同意多給 1 次", "new_max_calls": 2}
with open(co / "activity.jsonl", "a", encoding="utf-8") as f:
    f.write(json.dumps(entry, ensure_ascii=False) + "\n")
print("董事會推翻：writer 上限 1 → 2、解除暫停、已寫入活動紀錄")
print()
r = subprocess.run([sys.executable, "paperclip_lite.py", "heartbeat", str(co), "--agent", "writer"], capture_output=True, text=True, encoding="utf-8")
print((r.stdout + r.stderr).strip() or "（沒有輸出）")
def strip_extras(text):
    keep = []
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith("```"):
            continue
        if re.fullmatch(r"[（(].*[）)]", s) or s.startswith(("註", "附註", "※", "備註")):
            continue
        keep.append(s)
    return keep
f = co / "outputs" / "T003.md"
print()
if not f.exists():
    print("（沒有 T003 產出檔，跳過規則判定）")
else:
    raw = f.read_text(encoding="utf-8")
    clean = strip_extras(raw)
    main = clean[0] if clean else ""
    n_cn = len(re.findall(r"[一-鿿]", main))
    print("T003 原文：")
    for line in raw.strip().splitlines()[:6]:
        print("  | " + line[:70])
    print()
    print("規則：剝掉圍欄與附註後 ≤ 3 行，且主句中文字數 ≤ 40（題目寫 30，留一點彈性）")
    print("原始行數 {}，剝掉後行數 {}，主句中文 {} 字".format(len(raw.strip().splitlines()), len(clean), n_cn))
    ok = 1 <= len(clean) <= 3 and n_cn <= 40
    print("判定：", "PASS" if ok else "FAIL", "（任務狀態 done 只代表做完，合不合格由規則判）")'
   show "$P"; run "$P" ;;
8) banner "稽核日誌＋帳單四因素：誰、何時、為什麼、花多少"
   tip "日誌只有在有人看時才有用。帳單由代理數、心跳節奏、任務量、模型選擇四個量決定。"
   P='import json
from pathlib import Path
co = Path("ch07/interactive/co")
rows = [json.loads(l) for l in (co / "activity.jsonl").read_text(encoding="utf-8").splitlines() if l.strip()]
print("稽核：關鍵事件（從 activity.jsonl 挑出）")
for r in rows:
    if r["action"] in ("budget_pause", "approve", "board_override", "task_result"):
        extra = r.get("reason") or r.get("task") or ""
        print("  {} | {:<6} | {:<14} | {}".format(r["ts"][11:19], r["actor"], r["action"], extra))
acts = {r["action"] for r in rows}
print()
for name, key in (("撞牆", "budget_pause"), ("核准", "approve"), ("推翻", "board_override")):
    print("  {}：{}".format(name, "有紀錄" if key in acts else "沒有紀錄"))
print("  日誌回答不了：T002 核准前，人有沒有真的讀過草稿（可多記 reviewed_by、read_seconds 欄位）")
led = json.loads((co / "ledger.json").read_text(encoding="utf-8"))
calls = sum(v["calls"] for v in led.values()); usd = sum(v["usd"] for v in led.values())
unit = usd / calls if calls and usd > 0 else 1.0
print()
print("帳本合計 {} 次呼叫、${:.4f}；便宜模型單價 = {:.4f}（若為 0 就用 1 單位），頂級 = 10 倍".format(calls, usd, unit))
AGENTS, BEATS, DAYS, REAL = 5, 24, 30, 150
every = AGENTS * BEATS * DAYS
print()
print("{:<26} | {:>8} | {:>10}".format("配置（5 代理、每天 24 拍）", "月呼叫數", "相對成本"))
print("-" * 52)
base = None
for name, n, mix in (("每拍都問＋全頂級", every, 10), ("每拍都問＋九成便宜一成頂級", every, 0.9 + 0.1 * 10),
                     ("沒事不問＋全頂級", REAL, 10), ("沒事不問＋九成便宜一成頂級", REAL, 0.9 + 0.1 * 10)):
    cost = n * mix * unit
    base = base or cost
    print("{:<26} | {:>8} | {:>9.1f}%".format(name, n, cost / base * 100))
print()
print("最該先調：心跳節奏（每拍都問 → 沒事不問，呼叫數少 {} 倍）".format(every // REAL))
print()
print("第 7 章重點：")
for i, p in enumerate(["預算在呼叫前檢查，硬停那一拍不花錢", "核准閘門只放行 awaiting_approval",
                       "拆牆要改上限、解除暫停、留下理由三件一起做", "完成不等於合格，判定交給規則"], 1):
    print("  {}. {}".format(i, p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac
