# drover.nvim Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `drover.nvim`, a standalone Neovim module that sends the current file reference, visual selection, or open-buffer list to an existing or newly-created herdr agent pane, without depending on sidekick.nvim.

**Architecture:** A personal Neovim Lua module at `config/nvim/lua/drover/`, wired into `config/nvim/init.lua` exactly like the existing `text_objects` module. It shells out to the `herdr` CLI (JSON output) for all agent/pane operations — no direct socket protocol work. A telescope picker lists existing herdr agents plus a "+ New session" entry; picking an existing agent focuses it and writes text into its pane (no auto-Enter); picking "+ New session" starts a new `herdr agent` pane first.

**Tech Stack:** Neovim Lua (0.10+ APIs: `vim.system`, `vim.fs.relpath`), telescope.nvim (already a dependency in this config), plenary.nvim (already installed, used for tests), the `herdr` CLI binary (`/opt/homebrew/bin/herdr`, v0.7.1+).

## Global Constraints

- No dependency on sidekick.nvim or its `cli.mux` backend — talk to `herdr` directly.
- All herdr interaction goes through the `herdr` CLI's JSON output; never talk to `herdr.sock` directly.
- Sending text never auto-submits (no automatic Enter/newline-as-submit). The user presses Enter themselves.
- The send target is chosen via a telescope picker on every send — no "current/sticky target" memory.
- Current-file reference is `@relative/path` only, no line number.
- Visual-selection payload is the raw selected text only — no file/line reference bundled in.
- Keymaps live under `<leader>h*` so they never collide with sidekick.nvim's `<leader>a*`.
- Follow this repo's existing Lua style: tab indentation, double-quoted strings (see `config/nvim/lua/text_objects.lua`, `config/nvim/lua/options.lua`).

---

### Task 1: Scaffold the `drover` module and wire it into `init.lua`

**Files:**
- Create: `config/nvim/lua/drover/init.lua`
- Modify: `config/nvim/init.lua`

**Interfaces:**
- Produces: `require("drover").setup(opts?)` — merges `opts` over defaults and stores the result on `M.opts`. Later tasks (9) will extend this function to register keymaps; for now it only does the merge.
- Produces: `drover.Opts` shape — `{ keys: table<string, false|string>, agents: string[], agent_cmd: table<string, string[]> }`.

- [ ] **Step 1: Create the module skeleton**

Create `config/nvim/lua/drover/init.lua`:

```lua
local M = {}

---@class drover.Opts
---@field keys table<string, false|string>
---@field agents string[]
---@field agent_cmd table<string, string[]>
local defaults = {
	keys = {
		send_file = "<leader>hf",
		send_selection = "<leader>hv",
		send_buffers = "<leader>hb",
	},
	agents = { "claude", "codex", "opencode" },
	agent_cmd = {
		claude = { "claude" },
		codex = { "codex" },
		opencode = { "opencode" },
	},
}

---@param opts? drover.Opts
function M.setup(opts)
	opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
	M.opts = opts
end

return M
```

- [ ] **Step 2: Wire it into `init.lua`**

Read `config/nvim/init.lua` first — it currently looks like this:

```lua
if vim.loader then
	vim.loader.enable()
end
require("options")
require("text_objects").setup()
require("lazy_nvim")
```

Change it to:

```lua
if vim.loader then
	vim.loader.enable()
end
require("options")
require("text_objects").setup()
require("drover").setup()
require("lazy_nvim")
```

- [ ] **Step 3: Verify Neovim still starts and `drover` is configured**

Run:

```bash
nvim --headless -c "lua assert(require('drover').opts ~= nil, 'drover not configured')" -c "lua assert(require('drover').opts.keys.send_file == '<leader>hf', 'defaults not merged')" -c "lua print('DROVER_OK')" -c "qa" 2>&1
```

Expected output: `DROVER_OK` and nothing else (no error traceback). If you see an `E5113` or similar Lua error instead, the wiring is broken — fix before continuing.

- [ ] **Step 4: Commit**

```bash
cd /Users/iguchi.yuji/Development/dot
git add config/nvim/lua/drover/init.lua config/nvim/init.lua
git commit -m "$(cat <<'EOF'
Scaffold drover module skeleton

Adds the drover.nvim module directory and wires setup() into
init.lua the same way text_objects is loaded, ahead of the real
functionality that later tasks add.
EOF
)"
```

---

### Task 2: Spike — confirm how herdr handles multi-line text sent via `agent send`

**Files:** none (investigation only; the finding is written into Task 6's implementation).

**Interfaces:** none.

This determines whether `herdr agent send <target> <text>` (or `herdr pane send-text`) treats embedded `\n` characters as literal newlines (good — nothing special needed) or as Enter/submit keystrokes (bad — multi-line payloads like the buffer list would get partially executed against the CLI instead of just sitting in its input box). This must be resolved before Task 6 implements `herdr.lua`'s `send()`.

- [ ] **Step 1: Create a disposable workspace and a throwaway claude pane**

```bash
herdr workspace create --cwd /tmp --label drover-spike --no-focus
```

Note the `workspace_id` printed in the JSON result (field `result.workspace.id` or similar — read the actual output, it varies by herdr version).

```bash
herdr agent start claude --cwd /tmp --workspace <workspace_id_from_above> -- claude
```

- [ ] **Step 2: Find the new pane's id**

```bash
herdr agent list | python3 -c "
import json,sys
data = json.load(sys.stdin)
for a in data['result']['agents']:
    if a.get('cwd') == '/tmp':
        print(a['pane_id'])
"
```

This should print exactly one pane id (e.g. `w5:p1`). If it prints nothing, wait a couple seconds and retry — claude needs a moment to start and report itself to herdr.

- [ ] **Step 3: Send multi-line text and observe**

```bash
herdr agent send <pane_id_from_above> $'Line A\nLine B'
sleep 2
herdr pane focus <pane_id_from_above>
sleep 1
herdr pane read <pane_id_from_above> --lines 30 --format text
```

(The `pane focus` call is there because — as discovered while designing this plan — `pane read` can return empty content for a pane that has never been rendered by an attached client. Focusing it forces a render.)

- [ ] **Step 4: Interpret the result**

- **If** claude's input box shows `Line A` and `Line B` sitting together as unsent, unsubmitted text (no response generated, no "thinking" indicator) → newlines are literal. Record: **Branch A applies.**
- **If** claude has already started responding, or you see two separate submissions/echoes → the newline triggered a submit. Record: **Branch B applies.**

Write down which branch applies — Task 6 has explicit code for both. If genuinely ambiguous, err on the side of Branch B (the bracketed-paste wrapping is harmless even if not required).

- [ ] **Step 5: Clean up the disposable pane**

```bash
herdr pane close <pane_id_from_above>
herdr workspace close <workspace_id_from_above>
```

- [ ] **Step 6: Commit the finding**

No files changed yet, so nothing to commit here — carry the Branch A/B conclusion into Task 6's commit message.

---

### Task 3: `context.lua` — `current_file()`, with the plenary test harness

**Files:**
- Create: `config/nvim/lua/drover/context.lua`
- Create: `config/nvim/lua/drover/tests/minimal_init.lua`
- Create: `config/nvim/lua/drover/tests/context_spec.lua`

**Interfaces:**
- Produces: `require("drover.context").current_file()` → `string?` (`"@relative/path"` or `nil` for unnamed/unreadable buffers).

- [ ] **Step 1: Create the plenary test bootstrap**

Create `config/nvim/lua/drover/tests/minimal_init.lua`:

```lua
local plenary_dir = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(vim.fn.stdpath("config"))
vim.cmd("runtime plugin/plenary.vim")
```

- [ ] **Step 2: Write the failing test**

Create `config/nvim/lua/drover/tests/context_spec.lua`:

```lua
local context = require("drover.context")

describe("drover.context", function()
	local tmpdir
	local cwd_before

	before_each(function()
		tmpdir = vim.fn.tempname()
		vim.fn.mkdir(tmpdir, "p")
		cwd_before = vim.fn.getcwd()
		vim.cmd.cd(tmpdir)
	end)

	after_each(function()
		vim.cmd("silent! %bwipeout!")
		vim.cmd.cd(cwd_before)
		vim.fn.delete(tmpdir, "rf")
	end)

	local function write_file(relpath, lines)
		local abspath = tmpdir .. "/" .. relpath
		vim.fn.writefile(lines, abspath)
		return abspath
	end

	describe("current_file", function()
		it("returns an @-prefixed path relative to cwd", function()
			local abspath = write_file("foo.txt", { "hello" })
			vim.cmd.edit(abspath)
			assert.equals("@foo.txt", context.current_file())
		end)

		it("returns nil for an unnamed buffer", function()
			vim.cmd.enew()
			assert.is_nil(context.current_file())
		end)
	end)
end)
```

- [ ] **Step 3: Run the test to verify it fails**

```bash
cd /Users/iguchi.yuji/Development/dot/config/nvim
nvim --headless --noplugin -u lua/drover/tests/minimal_init.lua -c "PlenaryBustedDirectory lua/drover/tests/ { minimal_init = 'lua/drover/tests/minimal_init.lua', sequential = true }" 2>&1
```

Expected: failure output mentioning `module 'drover.context' not found` (the file doesn't exist yet).

- [ ] **Step 4: Implement `current_file()`**

Create `config/nvim/lua/drover/context.lua`:

```lua
local M = {}

---@param name string
---@return string
local function relative_path(name)
	local cwd = vim.fn.getcwd()
	local ok, rel = pcall(vim.fs.relpath, cwd, name)
	if ok and rel and rel ~= "" then
		return rel
	end
	return name
end

---@return string? # "@relative/path", or nil if the current buffer has no readable file
function M.current_file()
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" or vim.fn.filereadable(name) ~= 1 then
		return nil
	end
	return "@" .. relative_path(name)
end

return M
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
cd /Users/iguchi.yuji/Development/dot/config/nvim
nvim --headless --noplugin -u lua/drover/tests/minimal_init.lua -c "PlenaryBustedDirectory lua/drover/tests/ { minimal_init = 'lua/drover/tests/minimal_init.lua', sequential = true }" 2>&1
```

Expected: `Success: 2` (or similar plenary summary showing both tests passing, 0 failures).

- [ ] **Step 6: Commit**

```bash
cd /Users/iguchi.yuji/Development/dot
git add config/nvim/lua/drover/context.lua config/nvim/lua/drover/tests/
git commit -m "$(cat <<'EOF'
Add drover.context.current_file() with plenary test harness

Sets up the plenary-based test bootstrap for drover.nvim and
implements the first context builder: an @-prefixed, cwd-relative
file reference with no line number, per spec.
EOF
)"
```

---

### Task 4: `context.lua` — `open_buffers()`

**Files:**
- Modify: `config/nvim/lua/drover/context.lua`
- Modify: `config/nvim/lua/drover/tests/context_spec.lua`

**Interfaces:**
- Consumes: `relative_path(name)` (local helper already in `context.lua`, Task 3).
- Produces: `require("drover.context").open_buffers()` → `string?` (newline-joined `@relative/path` entries for every buflisted, on-disk buffer; `nil` if there are none).

- [ ] **Step 1: Write the failing test**

Add inside the `describe("drover.context", ...)` block in `config/nvim/lua/drover/tests/context_spec.lua`, after the `current_file` describe block:

```lua
	describe("open_buffers", function()
		it("lists all buflisted file buffers as @-prefixed paths", function()
			vim.fn.mkdir(tmpdir .. "/sub", "p")
			local a = write_file("a.txt", { "a" })
			local b = write_file("sub/b.txt", { "b" })
			vim.cmd.edit(a)
			vim.cmd.edit(b)
			local result = context.open_buffers()
			assert.is_not_nil(result)
			assert.is_true(result:find("@a.txt", 1, true) ~= nil)
			assert.is_true(result:find("@sub/b.txt", 1, true) ~= nil)
		end)

		it("returns nil when there are no file buffers", function()
			vim.cmd("silent! %bwipeout!")
			vim.cmd.enew()
			assert.is_nil(context.open_buffers())
		end)
	end)
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd /Users/iguchi.yuji/Development/dot/config/nvim
nvim --headless --noplugin -u lua/drover/tests/minimal_init.lua -c "PlenaryBustedDirectory lua/drover/tests/ { minimal_init = 'lua/drover/tests/minimal_init.lua', sequential = true }" 2>&1
```

Expected: failure — `attempt to call field 'open_buffers' (a nil value)`.

- [ ] **Step 3: Implement `open_buffers()`**

Add to `config/nvim/lua/drover/context.lua`, before `return M`:

```lua

---@return string? # newline-joined "@relative/path" list of open file buffers, or nil if none
function M.open_buffers()
	local lines = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == "" then
			local name = vim.api.nvim_buf_get_name(buf)
			if name ~= "" and vim.fn.filereadable(name) == 1 then
				table.insert(lines, "@" .. relative_path(name))
			end
		end
	end
	if #lines == 0 then
		return nil
	end
	return table.concat(lines, "\n")
end
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd /Users/iguchi.yuji/Development/dot/config/nvim
nvim --headless --noplugin -u lua/drover/tests/minimal_init.lua -c "PlenaryBustedDirectory lua/drover/tests/ { minimal_init = 'lua/drover/tests/minimal_init.lua', sequential = true }" 2>&1
```

Expected: `Success: 4`, 0 failures.

- [ ] **Step 5: Commit**

```bash
cd /Users/iguchi.yuji/Development/dot
git add config/nvim/lua/drover/context.lua config/nvim/lua/drover/tests/context_spec.lua
git commit -m "Add drover.context.open_buffers()"
```

---

### Task 5: `context.lua` — `visual_selection()`

**Files:**
- Modify: `config/nvim/lua/drover/context.lua`
- Modify: `config/nvim/lua/drover/tests/context_spec.lua`

**Interfaces:**
- Produces: `require("drover.context").visual_selection()` → `string?`. For a charwise (`v`) selection, returns exactly the selected characters (trimming the first/last line to the selected columns). For linewise (`V`) or blockwise selections, returns the full lines spanned (no column trimming — kept simple deliberately, see spec's non-goals). Returns `nil` if there is no selection (marks unset).

- [ ] **Step 1: Write the failing test**

Add inside the `describe("drover.context", ...)` block, after the `open_buffers` describe block:

```lua
	describe("visual_selection", function()
		it("returns the exact charwise selection", function()
			local abspath = write_file("sel.txt", { "hello world" })
			vim.cmd.edit(abspath)
			vim.api.nvim_win_set_cursor(0, { 1, 6 })
			vim.cmd("normal! v$\27")
			assert.equals("world", context.visual_selection())
		end)

		it("returns full lines for a linewise selection", function()
			local abspath = write_file("sel2.txt", { "line one", "line two", "line three" })
			vim.cmd.edit(abspath)
			vim.api.nvim_win_set_cursor(0, { 1, 0 })
			vim.cmd("normal! Vj\27")
			assert.equals("line one\nline two", context.visual_selection())
		end)
	end)
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd /Users/iguchi.yuji/Development/dot/config/nvim
nvim --headless --noplugin -u lua/drover/tests/minimal_init.lua -c "PlenaryBustedDirectory lua/drover/tests/ { minimal_init = 'lua/drover/tests/minimal_init.lua', sequential = true }" 2>&1
```

Expected: failure — `attempt to call field 'visual_selection' (a nil value)`.

- [ ] **Step 3: Implement `visual_selection()`**

Add to `config/nvim/lua/drover/context.lua`, before `return M`:

```lua

---@return string? # the raw selected text (no file/line reference bundled in), or nil if no selection
function M.visual_selection()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_line, start_col = start_pos[2], start_pos[3]
	local end_line, end_col = end_pos[2], end_pos[3]

	if start_line == 0 or end_line == 0 then
		return nil
	end

	local lines = vim.fn.getline(start_line, end_line)
	if type(lines) == "string" then
		lines = { lines }
	end
	if #lines == 0 then
		return nil
	end

	if vim.fn.visualmode() == "v" then
		if #lines == 1 then
			lines[1] = string.sub(lines[1], start_col, end_col)
		else
			lines[1] = string.sub(lines[1], start_col)
			lines[#lines] = string.sub(lines[#lines], 1, end_col)
		end
	end

	return table.concat(lines, "\n")
end
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd /Users/iguchi.yuji/Development/dot/config/nvim
nvim --headless --noplugin -u lua/drover/tests/minimal_init.lua -c "PlenaryBustedDirectory lua/drover/tests/ { minimal_init = 'lua/drover/tests/minimal_init.lua', sequential = true }" 2>&1
```

Expected: `Success: 6`, 0 failures.

- [ ] **Step 5: Commit**

```bash
cd /Users/iguchi.yuji/Development/dot
git add config/nvim/lua/drover/context.lua config/nvim/lua/drover/tests/context_spec.lua
git commit -m "Add drover.context.visual_selection()"
```

---

### Task 6: `herdr.lua` — the CLI wrapper

**Files:**
- Create: `config/nvim/lua/drover/herdr.lua`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces:
  - `require("drover.herdr").list_agents()` → `drover.Agent[]?, string?` (agents array, or `nil` + error message)
  - `require("drover.herdr").send(target, text)` → `boolean, string?`
  - `require("drover.herdr").focus(target)` → `boolean, string?`
  - `require("drover.herdr").unzoom(target)` → `boolean, string?`
  - `require("drover.herdr").start(name, argv, opts)` → `boolean, string?` where `opts` is `{ cwd?: string, workspace?: string }`
  - `---@class drover.Agent` with fields `pane_id: string`, `agent?: string`, `agent_status?: string`, `cwd?: string`, `focused?: boolean`

No unit tests for this module (it is a thin, mostly untestable CLI-invocation wrapper — see spec's Testing section). It gets exercised for real in Task 10's manual smoke test.

**Before writing `send()`, check Task 2's finding.** The code below shows both branches — keep the one Task 2 concluded and delete the other's comment block.

- [ ] **Step 1: Write the module**

Create `config/nvim/lua/drover/herdr.lua`:

```lua
local M = {}

---@param cmd string[]
---@return string[]? lines
---@return string? err
local function exec(cmd)
	local result = vim.system(cmd, { text = true }):wait()
	if result.code ~= 0 then
		local msg = result.stderr
		if not msg or msg == "" then
			msg = "herdr exited with code " .. result.code
		end
		return nil, vim.trim(msg)
	end
	return vim.split(result.stdout or "", "\n", { trimempty = true })
end

---@param cmd string[]
---@return table? decoded
---@return string? err
local function exec_json(cmd)
	local lines, err = exec(cmd)
	if not lines then
		return nil, err
	end
	local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
	if not ok or type(decoded) ~= "table" then
		return nil, "failed to parse herdr JSON output for: " .. table.concat(cmd, " ")
	end
	return decoded, nil
end

---@class drover.Agent
---@field pane_id string
---@field agent? string
---@field agent_status? string
---@field cwd? string
---@field focused? boolean

---@return drover.Agent[]? agents
---@return string? err
function M.list_agents()
	local decoded, err = exec_json({ "herdr", "agent", "list" })
	if not decoded then
		return nil, err
	end
	return (decoded.result and decoded.result.agents) or {}
end

---@param target string
---@param text string
---@return boolean ok
---@return string? err
function M.send(target, text)
	-- Branch A (newlines are literal, no Enter is triggered): pass the text through as-is.
	local _, err = exec({ "herdr", "agent", "send", target, text })
	return err == nil, err

	-- Branch B (newlines are treated as Enter/submit): wrap in bracketed-paste
	-- markers so the receiving TUI treats embedded newlines as literal text
	-- instead of submitting each line.
	-- local wrapped = "\27[200~" .. text .. "\27[201~"
	-- local _, err = exec({ "herdr", "agent", "send", target, wrapped })
	-- return err == nil, err
end

---@param target string
---@return boolean ok
---@return string? err
function M.focus(target)
	local _, err = exec({ "herdr", "agent", "focus", target })
	return err == nil, err
end

---@param target string
---@return boolean ok
---@return string? err
function M.unzoom(target)
	local _, err = exec({ "herdr", "pane", "zoom", target, "--off" })
	return err == nil, err
end

---@param name string
---@param argv string[]
---@param opts? { cwd?: string, workspace?: string }
---@return boolean ok
---@return string? err
function M.start(name, argv, opts)
	opts = opts or {}
	local cmd = { "herdr", "agent", "start", name }
	if opts.cwd then
		vim.list_extend(cmd, { "--cwd", opts.cwd })
	end
	if opts.workspace then
		vim.list_extend(cmd, { "--workspace", opts.workspace })
	end
	table.insert(cmd, "--")
	vim.list_extend(cmd, argv)
	local _, err = exec(cmd)
	return err == nil, err
end

return M
```

Note: `M.send`'s two branches are both written above with the unused one commented out — **delete the branch that doesn't match Task 2's finding** rather than leaving both in place; don't leave dead code behind.

- [ ] **Step 2: Sanity-check it loads and can list agents**

```bash
nvim --headless -c "lua local h = require('drover.herdr'); local agents, err = h.list_agents(); assert(agents ~= nil, err); print('LIST_OK count=' .. #agents)" -c "qa" 2>&1
```

Expected: `LIST_OK count=<N>` where N matches the number of panes from `herdr agent list | jq '.result.agents | length'` run separately for comparison.

- [ ] **Step 3: Commit**

```bash
cd /Users/iguchi.yuji/Development/dot
git add config/nvim/lua/drover/herdr.lua
git commit -m "$(cat <<'EOF'
Add drover.herdr CLI wrapper

Thin vim.system() wrapper around the herdr CLI's JSON output:
list_agents/send/focus/unzoom/start. send() uses <branch A: passes
text through literally | branch B: wraps text in bracketed-paste
markers> per the spike in the previous commit's investigation
(newlines <were|were not> treated as Enter by herdr agent send).
EOF
)"
```

(Fill in the `<...>` in the commit message with whichever branch you actually kept.)

---

### Task 7: `picker.lua` — the telescope picker

**Files:**
- Create: `config/nvim/lua/drover/picker.lua`

**Interfaces:**
- Consumes: `drover.Agent[]` (Task 6's shape).
- Produces: `require("drover.picker").pick(agents, on_choice)` where `on_choice` is `fun(choice: drover.Agent)`. `choice.pane_id == "__new__"` signals the user picked "+ New session"; export that sentinel as `require("drover.picker").NEW_SESSION_ID` for Task 8 to reuse.

- [ ] **Step 1: Write the module**

Create `config/nvim/lua/drover/picker.lua`:

```lua
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

M.NEW_SESSION_ID = "__new__"

---@type drover.Agent
local NEW_SESSION_ENTRY = {
	pane_id = M.NEW_SESSION_ID,
	agent = "+ New session",
	agent_status = "",
	cwd = "",
}

---@param agents drover.Agent[]
---@param on_choice fun(choice: drover.Agent)
function M.pick(agents, on_choice)
	local entries = { NEW_SESSION_ENTRY }
	vim.list_extend(entries, agents)

	pickers
		.new({}, {
			prompt_title = "drover: send to",
			finder = finders.new_table({
				results = entries,
				entry_maker = function(entry)
					local label = string.format(
						"%-8s %-12s %s",
						entry.agent_status or "",
						entry.agent or "unknown",
						entry.cwd or ""
					)
					return {
						value = entry,
						display = label,
						ordinal = label,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selection then
						on_choice(selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

return M
```

- [ ] **Step 2: Sanity-check it loads**

```bash
nvim --headless -c "lua assert(require('drover.picker').NEW_SESSION_ID == '__new__')" -c "lua print('PICKER_OK')" -c "qa" 2>&1
```

Expected: `PICKER_OK`. (The picker UI itself can't be exercised headlessly — that happens in Task 10.)

- [ ] **Step 3: Commit**

```bash
cd /Users/iguchi.yuji/Development/dot
git add config/nvim/lua/drover/picker.lua
git commit -m "Add drover.picker telescope picker for herdr agents"
```

---

### Task 8: `send.lua` — orchestration

**Files:**
- Create: `config/nvim/lua/drover/send.lua`

**Interfaces:**
- Consumes: `require("drover.herdr")` (Task 6: `list_agents`, `send`, `focus`, `unzoom`, `start`), `require("drover.picker")` (Task 7: `pick`, `NEW_SESSION_ID`), `require("drover.context")` (Tasks 3-5: `current_file`, `open_buffers`, `visual_selection`), `drover.Opts` (Task 1: `agents`, `agent_cmd`).
- Produces: `require("drover.send").send_file(opts)`, `.send_selection(opts)`, `.send_buffers(opts)` — all `fun(opts: drover.Opts)`, called directly from keymaps in Task 9.

- [ ] **Step 1: Write the module**

Create `config/nvim/lua/drover/send.lua`:

```lua
local herdr = require("drover.herdr")
local picker = require("drover.picker")
local context = require("drover.context")

local M = {}

---@param opts drover.Opts
---@param text string
local function start_new_and_send(opts, text)
	vim.ui.select(opts.agents, { prompt = "Start which agent?" }, function(name)
		if not name then
			return
		end
		local argv = opts.agent_cmd[name]
		if not argv then
			vim.notify("drover: no agent_cmd configured for " .. name, vim.log.levels.ERROR)
			return
		end

		local before, list_err = herdr.list_agents()
		if not before then
			vim.notify("drover: " .. (list_err or "failed to list agents"), vim.log.levels.ERROR)
			return
		end
		local before_ids = {}
		for _, a in ipairs(before) do
			before_ids[a.pane_id] = true
		end

		local ok, start_err = herdr.start(name, argv, { cwd = vim.fn.getcwd() })
		if not ok then
			vim.notify("drover: " .. (start_err or "failed to start agent"), vim.log.levels.ERROR)
			return
		end

		local new_pane_id
		vim.wait(3000, function()
			local agents = herdr.list_agents()
			if not agents then
				return false
			end
			for _, a in ipairs(agents) do
				if not before_ids[a.pane_id] then
					new_pane_id = a.pane_id
					return true
				end
			end
			return false
		end, 100)

		if not new_pane_id then
			vim.notify("drover: timed out waiting for new agent pane", vim.log.levels.ERROR)
			return
		end

		herdr.focus(new_pane_id)
		local sent_ok, send_err = herdr.send(new_pane_id, text)
		if not sent_ok then
			vim.notify("drover: " .. (send_err or "failed to send"), vim.log.levels.ERROR)
		end
	end)
end

---@param opts drover.Opts
---@param target drover.Agent
---@param text string
local function send_to_existing(opts, target, text)
	herdr.focus(target.pane_id)
	herdr.unzoom(target.pane_id)
	local ok, err = herdr.send(target.pane_id, text)
	if not ok then
		vim.notify("drover: " .. (err or "failed to send"), vim.log.levels.ERROR)
	end
end

---@param opts drover.Opts
---@param text? string
local function send_text(opts, text)
	if not text then
		vim.notify("drover: nothing to send", vim.log.levels.WARN)
		return
	end
	local agents, err = herdr.list_agents()
	if not agents then
		vim.notify("drover: " .. (err or "failed to list agents"), vim.log.levels.ERROR)
		return
	end
	picker.pick(agents, function(choice)
		if choice.pane_id == picker.NEW_SESSION_ID then
			start_new_and_send(opts, text)
		else
			send_to_existing(opts, choice, text)
		end
	end)
end

---@param opts drover.Opts
function M.send_file(opts)
	send_text(opts, context.current_file())
end

---@param opts drover.Opts
function M.send_selection(opts)
	send_text(opts, context.visual_selection())
end

---@param opts drover.Opts
function M.send_buffers(opts)
	send_text(opts, context.open_buffers())
end

return M
```

- [ ] **Step 2: Sanity-check it loads**

```bash
nvim --headless -c "lua require('drover.send')" -c "lua print('SEND_OK')" -c "qa" 2>&1
```

Expected: `SEND_OK`, no errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/iguchi.yuji/Development/dot
git add config/nvim/lua/drover/send.lua
git commit -m "Add drover.send orchestration (existing-target and new-session flows)"
```

---

### Task 9: Wire the keymaps

**Files:**
- Modify: `config/nvim/lua/drover/init.lua`

**Interfaces:**
- Consumes: `require("drover.send")` (Task 8: `send_file`, `send_selection`, `send_buffers`).
- Produces: three keymaps — `<leader>hf` (normal), `<leader>hv` (visual), `<leader>hb` (normal) — configurable/disable-able via `opts.keys`.

- [ ] **Step 1: Extend `M.setup`**

Replace the body of `M.setup` in `config/nvim/lua/drover/init.lua` (currently just the `opts = ...` merge and `M.opts = opts` line) with:

```lua
---@param opts? drover.Opts
function M.setup(opts)
	opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
	M.opts = opts

	local send = require("drover.send")

	if opts.keys.send_file then
		vim.keymap.set("n", opts.keys.send_file, function()
			send.send_file(opts)
		end, { desc = "drover: send current file reference" })
	end

	if opts.keys.send_selection then
		vim.keymap.set("x", opts.keys.send_selection, function()
			send.send_selection(opts)
		end, { desc = "drover: send visual selection" })
	end

	if opts.keys.send_buffers then
		vim.keymap.set("n", opts.keys.send_buffers, function()
			send.send_buffers(opts)
		end, { desc = "drover: send open buffers list" })
	end
end
```

(Only this function body changes — `local M = {}`, the `defaults` table, and `return M` stay as they are.)

- [ ] **Step 2: Verify the keymaps are registered**

```bash
nvim --headless -c "lua local m = vim.fn.maparg('<leader>hf', 'n', false, true); assert(m and m.lhs and m.lhs ~= '', 'send_file keymap missing')" -c "lua local m = vim.fn.maparg('<leader>hb', 'n', false, true); assert(m and m.lhs and m.lhs ~= '', 'send_buffers keymap missing')" -c "lua local m = vim.fn.maparg('<leader>hv', 'x', false, true); assert(m and m.lhs and m.lhs ~= '', 'send_selection keymap missing')" -c "lua print('KEYMAPS_OK')" -c "qa" 2>&1
```

Expected: `KEYMAPS_OK`.

- [ ] **Step 3: Commit**

```bash
cd /Users/iguchi.yuji/Development/dot
git add config/nvim/lua/drover/init.lua
git commit -m "Wire drover keymaps (<leader>hf/hv/hb)"
```

---

### Task 10: Manual end-to-end smoke test against real herdr

**Files:** none — this is verification only, no code changes.

This is the step where you actually open Neovim and use the feature, per the "verify UI/feature behavior for real" requirement — headless assertions in earlier tasks only proved the Lua loads and wires together, not that the herdr side-effects are correct.

- [ ] **Step 1: Existing-session flow — send current file**

1. Open real Neovim (`nvim` in this repo, not `--headless`).
2. Open any file, e.g. `nvim config/nvim/lua/drover/context.lua`.
3. Press `<leader>hf`. The telescope picker should open showing `+ New session` plus the live herdr agents from `herdr agent list`.
4. Pick an existing **idle** agent (check `agent_status` in the picker — don't pick one that's `working`, to avoid interrupting real work).
5. In a terminal, run `herdr pane read <that pane's id> --lines 5 --format text` and confirm `@config/nvim/lua/drover/context.lua` appears in its input box, **not yet submitted** (no response started).

- [ ] **Step 2: Existing-session flow — send visual selection**

1. In the same buffer, visually select a few lines (`V` then move, or `v` for a partial line) and press `<leader>hv`.
2. Pick the same idle agent again.
3. Confirm via `herdr pane read` that the exact selected text landed in its input box, appended after (or alongside) the previous unsent text.
4. Manually press Enter in that agent's actual terminal (attach with `herdr agent attach <pane_id>` or switch to it in your terminal UI) to clear the input box, so you don't leave a stray real agent pane in a dirty state.

- [ ] **Step 3: Existing-session flow — send open buffers**

1. Open 2-3 files in splits/tabs (`:e path/to/other/file`).
2. Press `<leader>hb`, pick the same idle agent.
3. Confirm via `herdr pane read` that all open file paths appear as `@path` lines.

- [ ] **Step 4: New-session flow**

1. Press `<leader>hf` again, this time pick `+ New session`.
2. Pick `claude` (or whichever `opts.agents` entry you have installed) from the `vim.ui.select` prompt.
3. Wait for it to start — you should see a notification only on failure; on success it just focuses the new pane.
4. Confirm with `herdr agent list` that a new pane exists with `cwd` matching your Neovim cwd, and `herdr pane read <new_pane_id>` shows the `@file` reference sitting unsent in its input box.
5. Close the scratch pane you created for this test: `herdr pane close <new_pane_id>`.

- [ ] **Step 5: Record the outcome**

If all five checks above pass, the feature is done. If anything diverges (e.g., text landed but with stray escape characters visible, meaning Task 6's Branch A/B choice was wrong), go back to Task 6, flip the branch, and re-run this task from Step 1.

No commit for this task — it's verification, not a code change.
