# Herdr

Config lives here and is linked as `~/.config/herdr`.

## Cursor session restore (Mac reboot)

Herdr restores workspace/tab/pane layout from `session.json`, and with

```toml
[session]
resume_agents_on_restore = true
```

it also runs `cursor-agent --resume <id>` for panes that have a stored session id.

### Why a resume can open a blank chat

Herdr stores whatever session the Cursor `sessionStart` hook last reported for a
pane. Two things report ids that are useless to resume:

- **The restore session itself.** When Herdr brings a pane back it starts a new
  `cursor-agent`, the hook fires, and the fresh (empty) session id overwrites the
  good one. Resuming it later opens a blank chat.
- **Subagents.** Task-tool subagents run in the same pane and fire the same hook,
  so a subagent chat can end up as the pane's stored id.

`cursor-sessions.py` works around this by reading
`~/.cursor/chats/*/*/meta.json` directly. A chat is only resumable when
`hasConversation` is true and `isSubagent` is false; panes are matched to chats by
title, because the pane title is the chat title.

### Commands

```bash
./cursor-sessions.sh ensure      # install/update the Cursor integration hook
./cursor-sessions.sh chats       # list resumable chats
./cursor-sessions.sh status      # per-pane: reported id validity + matched chat
./cursor-sessions.sh sync        # replace provably-bad ids with the matched chat
./cursor-sessions.sh snapshot    # write snapshots/cursor-sessions-latest.{json,md}
./cursor-sessions.sh report w7:p3 <chat-id>   # attach one chat id by hand
```

`status` columns:

| REPORTED | meaning |
|---|---|
| `ok` | Herdr's id points at a real conversation; left untouched |
| `empty` | id points at a chat with no conversation (usually the restore session) |
| `subagent` | id points at a subagent run |
| `unknown` | chat has no `meta.json` yet; brand-new session, left untouched |
| `none` | nothing reported |

`sync` only replaces `empty` / `subagent` / `none`. It never overwrites a live id.

### After reboot

1. Start Herdr. Layout returns.
2. `./cursor-sessions.sh status` — anything marked `empty` lost its real id.
3. `./cursor-sessions.sh sync` to restore matched ids, or open
   `snapshots/cursor-sessions-latest.md` and run the resume command in the
   pane's cwd.
4. Take a fresh `snapshot` once panes are live.

Take a `snapshot` **before** a planned reboot; that file is the fallback when
the stored ids get clobbered.

## Scripts

| Script | Role |
|--------|------|
| `agent-picker.sh` | Fuzzy-pick a live agent pane (`prefix+a`) |
| `agent-preview.sh` | Preview pane for the picker |
| `cursor-sessions.py` | Pane ↔ Cursor chat mapping (`cursor-sessions.sh` wraps it) |
