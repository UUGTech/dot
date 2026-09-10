#!/usr/bin/env python3
"""Herdr pane <-> Cursor Agent chat mapping.

Herdr's Cursor hook reports whatever session starts in a pane, so the stored id
can end up pointing at a subagent chat or at the empty session created during
restore. This tool treats ~/.cursor/chats/*/*/meta.json as the source of truth
and matches panes to real chats by title, so a resume command always points at a
conversation that actually has content.

Commands:
  ensure                 Install/update the Cursor Herdr integration
  chats                  List resumable Cursor chats
  status                 Pane table with reported id validity + best match
  snapshot [PATH|-]      Write JSON + Markdown map
  sync                   Push the matched chat id into Herdr for each pane
  report PANE_ID CHAT_ID Attach one chat id to a pane (validated)
"""

from __future__ import annotations

import datetime as dt
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_SNAPSHOT_DIR = Path(
    os.environ.get("HERDR_CURSOR_SNAPSHOT_DIR", SCRIPT_DIR / "snapshots")
)
CHATS_DIR = Path(os.environ.get("CURSOR_CONFIG_DIR", Path.home() / ".cursor")) / "chats"

# Titles Cursor shows before a chat earns a real one. They carry no signal, so a
# cwd guess against them would just attach some unrelated conversation.
GENERIC_TITLES = {"cursor agent", "cursor-agent", "agent", "shell", "zsh"}


def is_generic_title(title: str | None, cwd: str | None) -> bool:
    name = (title or "").strip()
    if not name:
        return True
    if name.lower() in GENERIC_TITLES or name.startswith("~/") or name.startswith("/"):
        return True
    return bool(cwd) and name in {cwd, os.path.basename(cwd)}


def die(msg: str, code: int = 1) -> None:
    print(f"cursor-sessions: {msg}", file=sys.stderr)
    raise SystemExit(code)


def need_herdr() -> None:
    if shutil.which("herdr") is None:
        die("herdr not on PATH")
    if os.environ.get("HERDR_ENV") != "1":
        die("not inside a Herdr pane (HERDR_ENV!=1)")


def ts(ms: int | None) -> str:
    if not ms:
        return "-"
    return dt.datetime.fromtimestamp(ms / 1000).strftime("%Y-%m-%d %H:%M")


def load_chats() -> list[dict]:
    """Every chat Cursor knows about, newest first."""
    chats = []
    if not CHATS_DIR.is_dir():
        return chats
    for meta_path in CHATS_DIR.glob("*/*/meta.json"):
        try:
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        chats.append(
            {
                "id": meta_path.parent.name,
                "workspace_hash": meta_path.parent.parent.name,
                "title": meta.get("title"),
                "cwd": meta.get("cwd"),
                "has_conversation": bool(meta.get("hasConversation")),
                "is_subagent": bool(meta.get("isSubagent")),
                "updated_at_ms": meta.get("updatedAtMs") or 0,
            }
        )
    chats.sort(key=lambda c: c["updated_at_ms"], reverse=True)
    return chats


def resumable(chats: list[dict]) -> list[dict]:
    return [c for c in chats if c["has_conversation"] and not c["is_subagent"]]


# Only "empty" and "subagent" are provably wrong to resume into. "unknown" is a
# chat whose meta.json has not landed yet, which a brand-new session hits, so it
# is left alone rather than overwritten.
BAD_STATES = {"empty", "subagent", "none"}


def classify(chat: dict | None) -> str:
    if chat is None:
        return "unknown"
    if chat["is_subagent"]:
        return "subagent"
    if not chat["has_conversation"]:
        return "empty"
    return "ok"


def herdr_json(*args: str) -> dict:
    proc = subprocess.run(
        ["herdr", *args], check=False, capture_output=True, text=True
    )
    if proc.returncode != 0:
        err = (proc.stderr or proc.stdout or "").strip()
        die(f"herdr {' '.join(args)} failed: {err or proc.returncode}")
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        die(f"invalid JSON from herdr {' '.join(args)}: {exc}")
    return {}


def cursor_panes() -> list[dict]:
    # `agent list` omits agent_session; `pane list` carries it.
    entries = herdr_json("pane", "list").get("result", {}).get("panes", [])
    panes = []
    for entry in entries:
        if (entry.get("agent") or "").lower() != "cursor":
            continue
        sess = entry.get("agent_session")
        sess = sess if isinstance(sess, dict) else {}
        panes.append(
            {
                "pane_id": entry.get("pane_id"),
                "tab_id": entry.get("tab_id"),
                "workspace_id": entry.get("workspace_id"),
                "title": entry.get("terminal_title_stripped")
                or entry.get("terminal_title"),
                "cwd": entry.get("cwd") or entry.get("foreground_cwd"),
                "agent_status": entry.get("agent_status"),
                "reported_session_id": sess.get("value")
                or sess.get("id")
                or sess.get("agent_session_id")
                or sess.get("session_id"),
            }
        )
    panes.sort(
        key=lambda p: (
            p.get("workspace_id") or "",
            p.get("tab_id") or "",
            p.get("pane_id") or "",
        )
    )
    return panes


def build_map() -> dict:
    chats = load_chats()
    by_id = {c["id"]: c for c in chats}
    pool = resumable(chats)
    panes = cursor_panes()

    # Pane titles come from the Cursor chat title, so an exact title match is the
    # strongest signal. Resolve every title match before falling back to cwd,
    # otherwise a generically-named pane steals a titled chat by recency.
    claimed: set[str] = set()
    pane_titles = {
        (p["title"] or "").strip().lower() for p in panes if (p["title"] or "").strip()
    }
    matches: dict[str, tuple[dict, str]] = {}

    # A reported id that resolves to a real conversation describes the chat the
    # pane is running right now, so it outranks any guess.
    for pane in panes:
        reported = pane["reported_session_id"]
        chat = by_id.get(reported) if reported else None
        if chat and classify(chat) == "ok":
            matches[pane["pane_id"]] = (chat, "reported")
            claimed.add(chat["id"])

    for pane in panes:
        if pane["pane_id"] in matches:
            continue
        pane_title = (pane["title"] or "").strip().lower()
        if not pane_title:
            continue
        titled = [
            c
            for c in pool
            if (c["title"] or "").strip().lower() == pane_title
            and c["id"] not in claimed
        ]
        if titled:
            matches[pane["pane_id"]] = (titled[0], "title")
            claimed.add(titled[0]["id"])

    for pane in panes:
        if pane["pane_id"] in matches or not pane["cwd"]:
            continue
        if is_generic_title(pane["title"], pane["cwd"]):
            continue
        # Skip chats named after another pane; those belong to that pane even if
        # its agent has not reported a session yet.
        same_cwd = [
            c
            for c in pool
            if c["cwd"] == pane["cwd"]
            and c["id"] not in claimed
            and (c["title"] or "").strip().lower() not in pane_titles
        ]
        if same_cwd:
            matches[pane["pane_id"]] = (same_cwd[0], "cwd")
            claimed.add(same_cwd[0]["id"])

    rows = []
    for pane in panes:
        reported = pane["reported_session_id"]
        reported_chat = by_id.get(reported) if reported else None
        reported_state = classify(reported_chat) if reported else "none"

        match, confidence = matches.get(pane["pane_id"], (None, "none"))
        resume_id = match["id"] if match else None
        rows.append(
            {
                **pane,
                "reported_state": reported_state,
                "match_confidence": confidence,
                "chat_id": resume_id,
                "chat_title": match["title"] if match else None,
                "chat_cwd": match["cwd"] if match else None,
                "chat_updated": ts(match["updated_at_ms"]) if match else None,
                "reported_is_stale": reported_state in BAD_STATES,
                "resume_cmd": (
                    f"cursor-agent --resume {resume_id}" if resume_id else None
                ),
            }
        )

    return {
        "captured_at": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "cursor_pane_count": len(rows),
        "resolved_count": sum(1 for r in rows if r["chat_id"]),
        "stale_reported_count": sum(1 for r in rows if r["reported_is_stale"]),
        "chat_totals": {
            "all": len(chats),
            "resumable": len(pool),
            "subagent": sum(1 for c in chats if c["is_subagent"]),
            "empty": sum(1 for c in chats if not c["has_conversation"]),
        },
        "panes": rows,
    }


def render_table(data: dict) -> str:
    lines = [
        f"captured: {data['captured_at']}",
        (
            f"panes: {data['cursor_pane_count']}  "
            f"resolved: {data['resolved_count']}  "
            f"stale herdr ids: {data['stale_reported_count']}"
        ),
        (
            f"chats: {data['chat_totals']['all']} total, "
            f"{data['chat_totals']['resumable']} resumable, "
            f"{data['chat_totals']['subagent']} subagent, "
            f"{data['chat_totals']['empty']} empty"
        ),
        "",
    ]
    hdr = f"{'PANE':<9} {'TITLE':<28} {'REPORTED':<10} {'VIA':<9} CHAT_ID"
    lines += [hdr, "-" * len(hdr)]
    for row in data["panes"]:
        lines.append(
            f"{row.get('pane_id') or '-':<9} "
            f"{(row.get('title') or '-')[:28]:<28} "
            f"{row.get('reported_state'):<10} "
            f"{row.get('match_confidence'):<9} "
            f"{row.get('chat_id') or '(none)'}"
        )
    if data["stale_reported_count"]:
        lines += [
            "",
            "Some panes report an id Herdr cannot resume into a real conversation",
            "(subagent chat, or the empty session created during restore).",
            "Run `cursor-sessions sync` to store the matched chat id instead.",
        ]
    return "\n".join(lines) + "\n"


def render_markdown(data: dict) -> str:
    lines = [
        "# Herdr Cursor session map",
        "",
        f"- captured_at: `{data['captured_at']}`",
        f"- panes: {data['cursor_pane_count']} (resolved {data['resolved_count']})",
        f"- stale herdr ids: {data['stale_reported_count']}",
        "",
        "| pane | title | cwd | chat_id | matched via | resume |",
        "|---|---|---|---|---|---|",
    ]
    for row in data["panes"]:
        lines.append(
            f"| `{row.get('pane_id')}` | {row.get('title') or ''} "
            f"| `{row.get('cwd') or ''}` | `{row.get('chat_id') or ''}` "
            f"| {row.get('match_confidence')} | `{row.get('resume_cmd') or ''}` |"
        )
    lines += [
        "",
        "## Restore after reboot",
        "",
        "1. Start Herdr (`herdr`). Layout returns from `session.json`.",
        "2. For each pane that came back as a bare shell, `cd` to its cwd and run "
        "the resume command above.",
        "3. Re-run `cursor-sessions sync` once the panes are live so Herdr stores "
        "the right ids again.",
        "",
        "`cursor-agent --resume <id>` only restores a conversation when that chat "
        "has content. Ids taken from a subagent run or from the empty session "
        "created during restore open a blank chat.",
        "",
    ]
    return "\n".join(lines)


def cmd_ensure(_: list[str]) -> None:
    need_herdr()
    subprocess.run(["herdr", "integration", "install", "cursor"], check=False)
    status = subprocess.run(
        ["herdr", "integration", "status"], check=False, capture_output=True, text=True
    )
    for line in (status.stdout or "").splitlines():
        if line.lower().startswith("cursor:"):
            print(line)


def cmd_chats(_: list[str]) -> None:
    chats = resumable(load_chats())
    hdr = f"{'UPDATED':<17} {'ID':<38} TITLE | CWD"
    print(hdr)
    print("-" * len(hdr))
    for chat in chats:
        print(
            f"{ts(chat['updated_at_ms']):<17} {chat['id']:<38} "
            f"{chat['title'] or '(no title)'} | {chat['cwd'] or '-'}"
        )


def cmd_status(_: list[str]) -> None:
    need_herdr()
    sys.stdout.write(render_table(build_map()))


def cmd_snapshot(args: list[str]) -> None:
    need_herdr()
    data = build_map()
    if args and args[0] == "-":
        json.dump(data, sys.stdout, indent=2, ensure_ascii=False)
        print()
        return

    DEFAULT_SNAPSHOT_DIR.mkdir(parents=True, exist_ok=True)
    if args:
        base = Path(args[0])
        base = base.with_suffix("") if base.suffix == ".json" else base
    else:
        stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        base = DEFAULT_SNAPSHOT_DIR / f"cursor-sessions-{stamp}"

    json_path, md_path = Path(f"{base}.json"), Path(f"{base}.md")
    json_path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    md_path.write_text(render_markdown(data), encoding="utf-8")
    shutil.copyfile(json_path, DEFAULT_SNAPSHOT_DIR / "cursor-sessions-latest.json")
    shutil.copyfile(md_path, DEFAULT_SNAPSHOT_DIR / "cursor-sessions-latest.md")

    sys.stdout.write(render_table(data))
    print()
    print(f"wrote: {json_path}")
    print(f"wrote: {md_path}")
    print(f"latest: {DEFAULT_SNAPSHOT_DIR / 'cursor-sessions-latest.md'}")


def push_session(pane_id: str, chat_id: str) -> bool:
    # The Cursor hook stamps its reports with time.time_ns(); Herdr drops any
    # report carrying a lower seq, so ours has to be stamped the same way.
    proc = subprocess.run(
        [
            "herdr", "pane", "report-agent-session", pane_id,
            "--source", "herdr:cursor",
            "--agent", "cursor",
            "--agent-session-id", chat_id,
            "--seq", str(time.time_ns()),
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        print(
            f"  failed {pane_id}: {(proc.stderr or proc.stdout).strip()}",
            file=sys.stderr,
        )
        return False
    return True


def cmd_sync(_: list[str]) -> None:
    need_herdr()
    data = build_map()
    pushed = 0
    for row in data["panes"]:
        chat_id = row.get("chat_id")
        # Only replace ids that are provably unusable; a live or not-yet-written
        # chat stays as reported.
        if not chat_id or row.get("reported_state") not in BAD_STATES:
            continue
        if chat_id == row.get("reported_session_id"):
            continue
        if push_session(row["pane_id"], chat_id):
            pushed += 1
            print(f"  {row['pane_id']} -> {chat_id}  ({row.get('title') or '-'})")
    print(f"synced {pushed} pane(s)")
    sys.stdout.write(render_table(build_map()))


def cmd_report(args: list[str]) -> None:
    need_herdr()
    if len(args) < 2:
        die("usage: cursor-sessions report <pane_id> <chat_id>")
    pane_id, chat_id = args[0], args[1]
    chat = {c["id"]: c for c in load_chats()}.get(chat_id)
    state = classify(chat)
    if state == "unknown":
        die(f"chat {chat_id} not found under {CHATS_DIR}")
    if state != "ok":
        die(f"chat {chat_id} is {state}; resuming it opens a blank conversation")
    if push_session(pane_id, chat_id):
        print(f"reported {chat_id} ({chat['title'] or 'untitled'}) onto {pane_id}")


def usage() -> None:
    print(
        f"""Usage: cursor-sessions <command>

  ensure                    Install/update the Cursor Herdr integration hook
  chats                     List resumable Cursor chats
  status                    Pane table: reported id validity + matched chat
  snapshot [PATH|-]         Save JSON+Markdown map (default: {DEFAULT_SNAPSHOT_DIR})
  sync                      Store the matched chat id in Herdr for each pane
  report <pane> <chat_id>   Attach one chat id to a pane (validated)

Env:
  HERDR_CURSOR_SNAPSHOT_DIR   Override snapshot directory
  CURSOR_CONFIG_DIR           Override ~/.cursor
"""
    )


def main(argv: list[str]) -> None:
    if not argv or argv[0] in {"-h", "--help", "help"}:
        usage()
        return
    cmd, *args = argv
    handlers = {
        "ensure": cmd_ensure,
        "chats": cmd_chats,
        "status": cmd_status,
        "snapshot": cmd_snapshot,
        "sync": cmd_sync,
        "report": cmd_report,
    }
    handler = handlers.get(cmd)
    if handler is None:
        die(f"unknown command: {cmd} (try --help)")
    handler(args)


if __name__ == "__main__":
    main(sys.argv[1:])
