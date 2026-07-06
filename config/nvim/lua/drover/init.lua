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
