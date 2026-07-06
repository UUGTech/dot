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

	if opts.keys.send_file then
		vim.keymap.set("n", opts.keys.send_file, function()
			require("drover.send").send_file(opts)
		end, { desc = "drover: send current file reference" })
	end

	if opts.keys.send_selection then
		vim.keymap.set("x", opts.keys.send_selection, function()
			require("drover.send").send_selection(opts)
		end, { desc = "drover: send visual selection" })
	end

	if opts.keys.send_buffers then
		vim.keymap.set("n", opts.keys.send_buffers, function()
			require("drover.send").send_buffers(opts)
		end, { desc = "drover: send open buffers list" })
	end
end

return M
