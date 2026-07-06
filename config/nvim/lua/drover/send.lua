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

		local focus_ok, focus_err = herdr.focus(new_pane_id)
		if not focus_ok then
			vim.notify("drover: " .. (focus_err or "failed to focus"), vim.log.levels.WARN)
		end
		local unzoom_ok, unzoom_err = herdr.unzoom(new_pane_id)
		if not unzoom_ok then
			vim.notify("drover: " .. (unzoom_err or "failed to unzoom"), vim.log.levels.WARN)
		end
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
	local focus_ok, focus_err = herdr.focus(target.pane_id)
	if not focus_ok then
		vim.notify("drover: " .. (focus_err or "failed to focus"), vim.log.levels.WARN)
	end
	local unzoom_ok, unzoom_err = herdr.unzoom(target.pane_id)
	if not unzoom_ok then
		vim.notify("drover: " .. (unzoom_err or "failed to unzoom"), vim.log.levels.WARN)
	end
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
