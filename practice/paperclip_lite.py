"""paperclip_lite：K147 演練用的迷你「AI 公司控制層」。

用最少的程式把書中 Paperclip 的核心零件做出來，方便在本機親手體驗：
  - 組織圖（org chart）與呈報線：每個代理有角色、上司、預算
  - 目標鏈（goal ancestry）：任務往上追到公司目標，代理收到的提示詞含整條鏈
  - 任務鎖（checkout）：用 O_EXCL 鎖檔，同一任務不會被兩個代理同時接走
  - 心跳（heartbeat）：代理被叫醒一次只處理一件任務，做完就睡
  - 治理：每個代理有呼叫次數與金額上限，超過就暫停；需核准的任務停在 awaiting_approval
  - 活動紀錄（activity log）：每個動作寫進 activity.jsonl
  - 匯出（export）：只匯出結構，機密（secrets.json）一律濾掉

代理的「腦」是 Claude Code 無頭模式 `claude -p`（走 Max 訂閱，不用 API 金鑰）。
這是學習用的簡化版，不是官方 Paperclip（官方是 npm 套件 paperclipai，Node.js＋React 儀表板）。

用法（在 practice/ 底下）：
  python paperclip_lite.py init demo-co
  python paperclip_lite.py org demo-co
  python paperclip_lite.py task demo-co --title "..." --assignee writer [--approval]
  python paperclip_lite.py heartbeat demo-co [--agent writer] [--dry-run]
  python paperclip_lite.py approve demo-co T002
  python paperclip_lite.py status demo-co
  python paperclip_lite.py export demo-co out.json
  python paperclip_lite.py selftest
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

# 拿掉金鑰（成本鐵律：不可讓 claude -p 改扣 API Credits）與巢狀 session 變數
STRIP_ENV_PREFIXES = ("ANTHROPIC_", "CLAUDECODE", "CLAUDE_")
CLI_TIMEOUT_SEC = int(os.environ.get("PCL_TIMEOUT", "180"))

SAMPLE_COMPANY = {
    "name": "示範內容工作室",
    "goal": "每週產出一篇讓台灣工程師看得懂的 AI 代理入門短文",
    "agents": [
        {"id": "ceo", "role": "執行長：把公司目標拆成本週任務並審稿", "reports_to": None,
         "model": "haiku", "max_calls": 3, "max_usd": 0.30},
        {"id": "researcher", "role": "研究員：整理事實與重點，標明不確定處", "reports_to": "ceo",
         "model": "haiku", "max_calls": 3, "max_usd": 0.30},
        {"id": "writer", "role": "寫手：依研究重點寫 300 字內繁體中文短文", "reports_to": "ceo",
         "model": "haiku", "max_calls": 2, "max_usd": 0.20},
    ],
    "projects": [
        {"id": "P1", "title": "本週短文：什麼是 AI 代理的心跳排程", "goal": "company"},
    ],
}
SAMPLE_TASKS = [
    {"id": "T001", "title": "列出「心跳排程」的 3 個重點，各一句話", "assignee": "researcher",
     "project": "P1", "needs_approval": False},
    {"id": "T002", "title": "依 T001 的重點寫 200 字短文", "assignee": "writer",
     "project": "P1", "needs_approval": True, "depends_on": "T001"},
]


def now_iso():
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")


# ---------- 檔案存取 ----------
def load_json(path, default=None):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except FileNotFoundError:
        if default is not None:
            return default
        raise
    except json.JSONDecodeError as exc:
        raise SystemExit(f"錯誤：{path} 不是合法 JSON：{exc}")


def save_json(path, data):
    Path(path).write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def log_activity(co_dir, actor, action, **detail):
    entry = {"ts": now_iso(), "actor": actor, "action": action, **detail}
    with open(Path(co_dir) / "activity.jsonl", "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def company_paths(co_dir):
    d = Path(co_dir)
    if not (d / "company.json").exists():
        raise SystemExit(f"錯誤：{d} 不是公司目錄（找不到 company.json），先跑 init")
    return d / "company.json", d / "tasks.json", d / "ledger.json"


# ---------- 指令：init / org ----------
def cmd_init(co_dir):
    d = Path(co_dir)
    if (d / "company.json").exists():
        raise SystemExit(f"錯誤：{d} 已經有公司了，換一個目錄名稱")
    (d / "outputs").mkdir(parents=True, exist_ok=True)
    (d / "locks").mkdir(exist_ok=True)
    save_json(d / "company.json", SAMPLE_COMPANY)
    save_json(d / "tasks.json", [dict(t, status="todo") for t in SAMPLE_TASKS])
    save_json(d / "ledger.json", {a["id"]: {"calls": 0, "usd": 0.0, "paused": False}
                                  for a in SAMPLE_COMPANY["agents"]})
    # 機密另放一檔，export 時不會帶出去
    save_json(d / "secrets.json", {"NEWSLETTER_TOKEN": "demo-not-a-real-secret"})
    log_activity(d, "owner", "init", company=SAMPLE_COMPANY["name"])
    print(f"已建立公司目錄 {d}（3 個代理、2 個任務、1 份機密）")


def org_lines(agents, parent=None, depth=0):
    lines = []
    for a in agents:
        if a["reports_to"] == parent:
            lines.append("  " * depth + f"- {a['id']}｜{a['role']}｜上限 {a['max_calls']} 次／${a['max_usd']}")
            lines.extend(org_lines(agents, a["id"], depth + 1))
    return lines


def goal_chain(company, task):
    """從任務一路往上：任務 → 專案 → 公司目標（代理拿到的『為什麼』）。"""
    project = next((p for p in company["projects"] if p["id"] == task.get("project")), None)
    chain = [f"公司目標：{company['goal']}"]
    if project:
        chain.append(f"專案：{project['title']}")
    chain.append(f"你的任務：{task['title']}")
    return chain


def cmd_org(co_dir):
    company = load_json(company_paths(co_dir)[0])
    print(f"公司：{company['name']}\n目標：{company['goal']}\n組織圖：")
    print("\n".join(org_lines(company["agents"])))


# ---------- 指令：task / approve / status ----------
def cmd_task(co_dir, title, assignee, approval, project):
    company_file, tasks_file, _ = company_paths(co_dir)
    company = load_json(company_file)
    if assignee not in {a["id"] for a in company["agents"]}:
        raise SystemExit(f"錯誤：沒有代理 {assignee}，可用：{[a['id'] for a in company['agents']]}")
    tasks = load_json(tasks_file)
    new_id = f"T{len(tasks) + 1:03d}"
    tasks.append({"id": new_id, "title": title, "assignee": assignee, "project": project,
                  "needs_approval": approval, "status": "todo"})
    save_json(tasks_file, tasks)
    log_activity(co_dir, "owner", "task_add", task=new_id, assignee=assignee)
    print(f"已新增 {new_id} → {assignee}（需核准：{approval}）")


def cmd_approve(co_dir, task_id):
    _, tasks_file, _ = company_paths(co_dir)
    tasks = load_json(tasks_file)
    task = next((t for t in tasks if t["id"] == task_id), None)
    if task is None:
        raise SystemExit(f"錯誤：找不到任務 {task_id}")
    if task["status"] != "awaiting_approval":
        raise SystemExit(f"錯誤：{task_id} 狀態是 {task['status']}，不是 awaiting_approval")
    task["status"] = "done"
    task["approved_at"] = now_iso()
    save_json(tasks_file, tasks)
    log_activity(co_dir, "owner", "approve", task=task_id)
    print(f"已核准 {task_id}，狀態改為 done")


def cmd_status(co_dir):
    _, tasks_file, ledger_file = company_paths(co_dir)
    print("任務：")
    for t in load_json(tasks_file):
        print(f"  {t['id']} [{t['status']}] {t['assignee']}：{t['title']}")
    print("預算帳本：")
    for agent_id, row in load_json(ledger_file).items():
        print(f"  {agent_id}: {row['calls']} 次 ${row['usd']:.4f} 暫停={row['paused']}")


# ---------- 任務鎖 ----------
def try_checkout(co_dir, task_id, agent_id):
    """O_EXCL 建鎖檔：建得出來才算接到任務；別人已經接走就回 False。"""
    lock = Path(co_dir) / "locks" / f"{task_id}.lock"
    try:
        fd = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
    except FileExistsError:
        return False
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(agent_id)
    return True


def release(co_dir, task_id):
    try:
        (Path(co_dir) / "locks" / f"{task_id}.lock").unlink()
    except FileNotFoundError:
        pass


# ---------- 代理的腦：claude -p ----------
def clean_env():
    return {k: v for k, v in os.environ.items() if not k.startswith(STRIP_ENV_PREFIXES)}


def call_claude(prompt, model):
    exe = shutil.which("claude")
    if exe is None:
        raise RuntimeError("找不到 claude 指令（Claude Code CLI）")
    work_dir = Path(tempfile.gettempdir()) / "k147-cli-cwd"   # 空目錄：不讀任何 CLAUDE.md
    work_dir.mkdir(exist_ok=True)
    cmd = [exe, "-p", "--output-format", "json", "--model", model, "--tools", ""]
    try:
        proc = subprocess.run(cmd, input=prompt, capture_output=True, text=True, encoding="utf-8",
                              errors="replace", env=clean_env(), cwd=str(work_dir),
                              timeout=CLI_TIMEOUT_SEC, check=False)
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(f"claude -p 超過 {CLI_TIMEOUT_SEC} 秒沒有回應") from exc
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        detail = (proc.stderr or proc.stdout or "").strip()[:300]
        raise RuntimeError(f"claude -p 回傳不是 JSON（exit {proc.returncode}）：{detail}") from exc
    if data.get("is_error") or proc.returncode != 0:
        raise RuntimeError(f"claude -p 失敗：{str(data.get('result'))[:300]}")
    return data.get("result", ""), float(data.get("total_cost_usd") or 0.0)


def build_prompt(company, agent, task, upstream_text):
    lines = [f"你是「{company['name']}」的 {agent['id']}，角色：{agent['role']}。",
             *goal_chain(company, task)]
    if upstream_text:
        lines.append(f"上游任務的產出：\n{upstream_text}")
    lines.append("只產出這個任務要的內容，用繁體中文，不要多問問題。")
    return "\n".join(lines)


# ---------- 指令：heartbeat ----------
def pick_task(tasks, agent_id):
    done_ids = {t["id"] for t in tasks if t["status"] == "done" or t["status"] == "awaiting_approval"}
    for t in tasks:
        if t["assignee"] == agent_id and t["status"] == "todo":
            if t.get("depends_on") and t["depends_on"] not in done_ids:
                continue
            return t
    return None


def budget_block_reason(agent, row):
    if row["paused"]:
        return "已暫停"
    if row["calls"] >= agent["max_calls"]:
        return f"呼叫次數達上限 {agent['max_calls']}"
    if row["usd"] >= agent["max_usd"]:
        return f"金額達上限 ${agent['max_usd']}"
    return None


def heartbeat_one(co_dir, company, agent, tasks, ledger, dry_run):
    row = ledger[agent["id"]]
    reason = budget_block_reason(agent, row)
    if reason:
        row["paused"] = True
        log_activity(co_dir, agent["id"], "budget_pause", reason=reason)
        return f"{agent['id']}：{reason} → 暫停，不做事"
    task = pick_task(tasks, agent["id"])
    if task is None:
        return f"{agent['id']}：沒有可做的任務，繼續睡"
    if not try_checkout(co_dir, task["id"], agent["id"]):
        return f"{agent['id']}：{task['id']} 已被別人鎖住，跳過"
    try:
        upstream = ""
        if task.get("depends_on"):
            up_file = Path(co_dir) / "outputs" / f"{task['depends_on']}.md"
            upstream = up_file.read_text(encoding="utf-8") if up_file.exists() else ""
        prompt = build_prompt(company, agent, task, upstream)
        if dry_run:
            return f"{agent['id']}：[乾跑] 會接 {task['id']}，提示詞如下\n{prompt}"
        text, cost = call_claude(prompt, agent["model"])
        row["calls"] += 1
        row["usd"] = round(row["usd"] + cost, 6)
        (Path(co_dir) / "outputs" / f"{task['id']}.md").write_text(text, encoding="utf-8")
        # 治理閘門：需核准的任務停在 awaiting_approval，等人類 approve
        task["status"] = "awaiting_approval" if task["needs_approval"] else "done"
        log_activity(co_dir, agent["id"], "task_result", task=task["id"], status=task["status"],
                     usd=cost)
        return f"{agent['id']}：完成 {task['id']} → {task['status']}（${cost:.4f}）"
    finally:
        release(co_dir, task["id"])


def cmd_heartbeat(co_dir, only_agent, dry_run):
    company_file, tasks_file, ledger_file = company_paths(co_dir)
    company = load_json(company_file)
    tasks, ledger = load_json(tasks_file), load_json(ledger_file)
    agents = [a for a in company["agents"] if only_agent in (None, a["id"])]
    if not agents:
        raise SystemExit(f"錯誤：沒有代理 {only_agent}")
    for agent in agents:
        try:
            print(heartbeat_one(co_dir, company, agent, tasks, ledger, dry_run))
        except RuntimeError as exc:
            log_activity(co_dir, agent["id"], "error", message=str(exc))
            print(f"{agent['id']}：錯誤 {exc}", file=sys.stderr)
    if not dry_run:
        save_json(tasks_file, tasks)
        save_json(ledger_file, ledger)


# ---------- 指令：export ----------
def cmd_export(co_dir, out_file):
    company_file, tasks_file, _ = company_paths(co_dir)
    bundle = {"exported_at": now_iso(), "company": load_json(company_file),
              "tasks": [{k: v for k, v in t.items() if k != "status"} for t in load_json(tasks_file)],
              "secrets": "（已濾除：機密不隨匯出，到新環境要重新設定）"}
    save_json(out_file, bundle)
    log_activity(co_dir, "owner", "export", file=str(out_file))
    print(f"已匯出結構到 {out_file}（不含 secrets.json）")


# ---------- 冒煙測試（不呼叫模型） ----------
def cmd_selftest():
    with tempfile.TemporaryDirectory() as tmp:
        co = Path(tmp) / "co"
        cmd_init(co)
        assert try_checkout(co, "T001", "researcher") is True
        assert try_checkout(co, "T001", "writer") is False, "任務鎖失效"
        release(co, "T001")
        tasks = load_json(co / "tasks.json")
        assert pick_task(tasks, "writer") is None, "T002 依賴 T001，不該先被接"
        agent = SAMPLE_COMPANY["agents"][2]
        assert budget_block_reason(agent, {"calls": 2, "usd": 0, "paused": False})
        out = Path(tmp) / "export.json"
        cmd_export(co, out)
        assert "demo-not-a-real-secret" not in out.read_text(encoding="utf-8"), "機密外洩"
    print("selftest 全部通過（任務鎖、依賴、預算上限、匯出濾機密）")


def main():
    parser = argparse.ArgumentParser(description="K147 迷你 AI 公司控制層")
    sub = parser.add_subparsers(dest="cmd", required=True)
    for name in ("init", "org", "status"):
        sub.add_parser(name).add_argument("company")
    p = sub.add_parser("task")
    p.add_argument("company")
    p.add_argument("--title", required=True)
    p.add_argument("--assignee", required=True)
    p.add_argument("--project", default="P1")
    p.add_argument("--approval", action="store_true")
    p = sub.add_parser("heartbeat")
    p.add_argument("company")
    p.add_argument("--agent")
    p.add_argument("--dry-run", action="store_true")
    p = sub.add_parser("approve")
    p.add_argument("company")
    p.add_argument("task_id")
    p = sub.add_parser("export")
    p.add_argument("company")
    p.add_argument("out")
    sub.add_parser("selftest")
    args = parser.parse_args()
    handlers = {
        "init": lambda: cmd_init(args.company), "org": lambda: cmd_org(args.company),
        "status": lambda: cmd_status(args.company),
        "task": lambda: cmd_task(args.company, args.title, args.assignee, args.approval, args.project),
        "heartbeat": lambda: cmd_heartbeat(args.company, args.agent, args.dry_run),
        "approve": lambda: cmd_approve(args.company, args.task_id),
        "export": lambda: cmd_export(args.company, args.out), "selftest": cmd_selftest,
    }
    handlers[args.cmd]()


if __name__ == "__main__":
    main()
