#!/bin/bash
# K147 第 5 章互動演練：組織圖——目標如何抵達代理，一次跑一步
# 用法：bash ch05.sh <步驟 1-8>
# 呼叫模型：只有第 6 步會呼叫模型 1 次（paperclip_lite heartbeat → claude -p haiku），其餘步驟全部離線
set -u
STEP="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PRACTICE="$HERE/.."
G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

banner() { clear; printf '%s╔══════════════════════════════════════════════════════╗%s\n' "$C" "$N"; printf '%s  K147 第 5 章｜組織圖　第 %s / 8 步%s\n' "$B" "$STEP" "$N"; printf '%s  %s%s\n' "$B" "$1" "$N"; printf '%s╚══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"; }
tip() { printf '%s💡 %s%s\n\n' "$Y" "$1" "$N"; }
show() { printf '%s▶ 要執行的程式：%s\n' "$G" "$N"; printf '%s' "$1" | sed "s/^/${G}  │ ${N}/"; printf '\n%s▶ 執行結果：%s\n' "$G" "$N"; }
run() { (cd "$PRACTICE" && PYTHONUTF8=1 PYTHONPATH=. python - <<PY
$1
PY
); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }
runsh() { (cd "$PRACTICE" && export PYTHONUTF8=1 && eval "$1"); printf '\n%s👉 第 %s 步完成%s\n' "$C" "$STEP" "$N"; }

case "$STEP" in
1) banner "建公司，看組織圖與呈報線"
   tip "示範公司：ceo 在最上層，researcher 和 writer 向 ceo 呈報；每個代理都有呼叫次數與金額上限。"
   P='rm -rf ch05/interactive && mkdir -p ch05/interactive
python paperclip_lite.py init ch05/interactive/co
python paperclip_lite.py org ch05/interactive/co | tee ch05/interactive/org.txt'
   show "$P"; runsh "$P" ;;
2) banner "乾跑 researcher：提示詞裡有整條目標鏈"
   tip "乾跑不呼叫模型，只印出代理會收到的提示詞。逐行標出：角色、使命、專案、任務。"
   P='import subprocess, sys
from pathlib import Path
co = "ch05/interactive/co"
r = subprocess.run([sys.executable, "paperclip_lite.py", "heartbeat", co, "--agent", "researcher", "--dry-run"],
                   capture_output=True, text=True, encoding="utf-8")
Path("ch05/interactive/chain-T001.txt").write_text(r.stdout, encoding="utf-8")
LABELS = (("你是", "角色"), ("公司目標", "使命"), ("專案", "專案"), ("你的任務", "任務"), ("只產出", "規矩"))
for line in r.stdout.strip().splitlines():
    tag = next((lab for key, lab in LABELS if line.startswith(key)), "")
    print("  [{}] {}".format(tag, line) if tag else line)
print()
print("代理拿到的不只是任務，還有它「為什麼」存在：使命 -> 專案 -> 任務，是程式逐行塞進去的。")'
   show "$P"; run "$P" ;;
3) banner "加專案、掛錯專案、指派不存在的代理"
   tip "P2 是真的專案；P9 根本不存在；cfo 不在組織圖裡。看工具擋下哪一個。"
   P='python - <<EOF
import json
p = "ch05/interactive/co/company.json"
c = json.load(open(p, encoding="utf-8"))
c["projects"].append({"id": "P2", "title": "讀者問答集", "goal": "company"})
json.dump(c, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("已加入專案 P2：讀者問答集")
EOF
python paperclip_lite.py task ch05/interactive/co --title "整理本週 3 則讀者提問" --assignee ceo --project P2
python paperclip_lite.py task ch05/interactive/co --title "研究競品的定價" --assignee ceo --project P9
python paperclip_lite.py task ch05/interactive/co --title "測試" --assignee cfo 2>&1 || echo "（cfo 被擋下是正確的：組織圖裡沒有這個人）"
echo; echo "結果：掛在不存在的 P9 照樣建立成功；只有不存在的代理被擋。"'
   show "$P"; runsh "$P" ;;
4) banner "乾跑 ceo 兩件任務：哪一行不見了"
   tip "ceo 會接第一件 todo（T003）；把它改成 done 再乾跑，就看到 T004 的提示詞。"
   P='import json, subprocess, sys
from pathlib import Path
co = Path("ch05/interactive/co")
def dry():
    r = subprocess.run([sys.executable, "paperclip_lite.py", "heartbeat", str(co), "--agent", "ceo", "--dry-run"],
                       capture_output=True, text=True, encoding="utf-8")
    return r.stdout
def set_done(tid):
    tasks = json.loads((co / "tasks.json").read_text(encoding="utf-8"))
    for t in tasks:
        if t["id"] == tid:
            t["status"] = "done"
    (co / "tasks.json").write_text(json.dumps(tasks, ensure_ascii=False, indent=2), encoding="utf-8")
a = dry(); Path("ch05/interactive/chain-ceo.txt").write_text(a, encoding="utf-8")
set_done("T003")
b = dry(); Path("ch05/interactive/chain-ceo-2.txt").write_text(b, encoding="utf-8")
for name, text in (("T003（掛 P2）", a), ("T004（掛 P9）", b)):
    print("──", name)
    for line in text.strip().splitlines()[1:]:
        print("   ", line)
    has = any(l.startswith("專案：") for l in text.splitlines())
    print("    -> 有「專案」那一行：", "有" if has else "沒有，鏈斷了")
    print()
print("工具沒有任何警告：P9 的任務照樣被接、照樣能送給模型。鏈斷了，要靠人看出來。")
print("可加的檢查（只寫設計）：cmd_task 建立前確認 project 存在於 company.json 的 projects，否則拒絕。")'
   show "$P"; run "$P" ;;
5) banner "練習 2 準備：交給 ceo 一件「拆目標」任務"
   tip "先把練習 1 的 ceo 任務全改成 done，避免 ceo 接到舊任務；再乾跑確認它接的是新任務。"
   P='python - <<EOF
import json
p = "ch05/interactive/co/tasks.json"
tasks = json.load(open(p, encoding="utf-8"))
for t in tasks:
    if t["assignee"] == "ceo":
        t["status"] = "done"
json.dump(tasks, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("ceo 舊任務已全部改成 done")
EOF
python paperclip_lite.py task ch05/interactive/co --assignee ceo --title "把公司目標拆成 3 個專案、每個專案 2 個任務；每個任務寫明服務哪個專案、交給 researcher 或 writer；用 Markdown 條列"
python paperclip_lite.py heartbeat ch05/interactive/co --agent ceo --dry-run | tee ch05/interactive/plan-dryrun.txt'
   show "$P"; runsh "$P" ;;
6) banner "真心跳：讓 ceo 真的拆一次目標"
   tip "這一步會呼叫模型 1 次（claude -p haiku），最多等 180 秒；每次結果可能不同，照實記錄。"
   P='python paperclip_lite.py heartbeat ch05/interactive/co --agent ceo 2>&1 | tee ch05/interactive/plan-heartbeat.txt
echo
if [ -f ch05/interactive/co/outputs/T005.md ]; then
  echo "── ceo 的產出 outputs/T005.md（前 30 行）──"; head -n 30 ch05/interactive/co/outputs/T005.md
else
  echo "（這次沒有拿到產出，第 7 步會改用內建範例繼續）"
fi
echo; python paperclip_lite.py status ch05/interactive/co'
   show "$P"; runsh "$P" ;;
7) banner "用程式規則驗收拆解"
   tip "委派不免除檢查：先剝掉程式碼框和附註，再數專案、任務、指派對象，最後核對帳本。"
   P='import json, re
from pathlib import Path
co = Path("ch05/interactive/co")
FALLBACK = """## 專案一：心跳排程短文
- 任務 1-1：整理心跳排程的 3 個重點（researcher）
- 任務 1-2：依重點寫 200 字短文（writer）
## 專案二：讀者問答
- 任務 2-1：蒐集 3 則讀者提問（researcher）
- 任務 2-2：寫出回答（writer）
## 專案三：術語小辭典
- 任務 3-1：列出 5 個代理術語（researcher）
- 任務 3-2：每個術語寫一句白話解釋（writer）"""
out = co / "outputs" / "T005.md"
text, source = (out.read_text(encoding="utf-8"), "第 6 步模型輸出") if out.exists() else (FALLBACK, "內建範例（第 6 步沒有成功）")
def strip_extras(t):
    keep = []
    for line in t.splitlines():
        s = line.strip()
        if not s or s.startswith("```"):
            continue
        if re.fullmatch(r"[（(].*[）)]", s):
            continue
        if s.startswith(("註", "附註", "※", "備註")):
            continue
        keep.append(s)
    return keep
raw_lines = [l for l in text.splitlines()]
lines = strip_extras(text)
print("資料來源：", source)
print("原始行數 {}，剝掉程式碼框、空行、附註後 {} 行".format(len(raw_lines), len(lines)))
proj = [l for l in lines if re.match(r"^(#+\s*|[-*]\s*|\d+[.、)]\s*)?\**\s*專案\s*[一二三四五六1-9A-Za-z]", l)]
blocks = []
for l in lines:
    if re.match(r"^([-*]\s*|#+\s*|\d+[.、)]\s*)?\**\s*任務\s*[0-9一二三四五六]", l):
        blocks.append([l])
    elif blocks and not re.match(r"^(#+\s*|[-*]\s*)?\**\s*專案", l):
        blocks[-1].append(l)
tasks = [b[0] for b in blocks]
assigned = [b for b in blocks if re.search(r"researcher|writer|研究員|寫手", " ".join(b), re.I)]
print()
print("偵測到的專案：")
for p in proj: print("   ", p[:70])
print("偵測到的任務：")
for b in blocks:
    who = re.search(r"researcher|writer|研究員|寫手", " ".join(b), re.I)
    print("    {} -> {}".format(b[0][:52], who.group(0) if who else "（沒有指派）"))
ledger = json.loads((co / "ledger.json").read_text(encoding="utf-8"))
ceo_calls = ledger["ceo"]["calls"]
checks = [("專案數 = 3", len(proj) == 3, len(proj)),
          ("任務數 = 6", len(tasks) == 6, len(tasks)),
          ("每個任務都指派 researcher 或 writer", len(tasks) > 0 and len(assigned) == len(tasks), "{}/{}".format(len(assigned), len(tasks))),
          ("帳本 ceo 只多 1 次呼叫", ceo_calls == (1 if out.exists() else 0), ceo_calls)]
print()
for name, ok, val in checks:
    print("  {} {}（實際：{}）".format("PASS" if ok else "FAIL", name, val))
verdict = "PASS" if all(c[1] for c in checks) else "FAIL"
print()
print("整份拆解判定：", verdict)
print("提醒：lite 版的 ceo 產出只是文字，不會自動變成新任務；真正的委派要靠人或程式再建任務。")
(Path("ch05/interactive") / "decomposition-review.md").write_text(
    "# 第 5 章：CEO 拆解驗收\n\n資料來源：{}\n\n".format(source)
    + "\n".join("- {} {}（實際：{}）".format("PASS" if ok else "FAIL", n, v) for n, ok, v in checks)
    + "\n\n判定：{}\n".format(verdict), encoding="utf-8")
print("已寫入 ch05/interactive/decomposition-review.md")'
   show "$P"; run "$P" ;;
8) banner "總結：策略在你設的目標裡，不在組織本身"
   tip "目標鏈是被「交付」的；鏈斷了沒有警告；最便宜的攔截點在最上層的拆解。"
   P='from pathlib import Path
points = [
    "目標鏈是被交付的：build_prompt 把公司目標、專案、任務逐行塞進提示詞，代理才知道為什麼要做。",
    "工具照樣接下掛錯專案的任務，只是提示詞少了「專案」那行；鏈斷了沒有警告，要靠人看。",
    "不存在的代理會被擋下，但不存在的專案不會——檢查要補在 cmd_task。",
    "角色描述就是職務說明：role 寫得越具體，產出越不會漫無目的。",
    "委派不免除檢查：CEO 拆錯，錯誤沿鏈往下傳；用程式規則驗收拆解，別只看「看起來不錯」。",
]
print("第 5 章重點：")
for i, p in enumerate(points, 1):
    print(f"  {i}. {p}")
print()
print("層級不要超過任務所需：3 個代理的小公司，不必硬補 CTO、CMO 這種中間層。")
print()
print("本章產出檔案：")
for name in ("org.txt", "chain-T001.txt", "chain-ceo.txt", "chain-ceo-2.txt", "plan-dryrun.txt",
             "plan-heartbeat.txt", "co/outputs/T005.md", "decomposition-review.md"):
    p = Path("ch05/interactive") / name
    print("  {} {}".format("OK" if p.exists() else "缺", p))'
   show "$P"; run "$P" ;;
*) echo "步驟要 1～8" ;;
esac
