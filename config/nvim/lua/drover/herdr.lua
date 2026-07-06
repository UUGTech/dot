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
