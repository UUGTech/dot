return {
	"zbirenbaum/copilot.lua",
	event = "InsertEnter",
	cond = function()
		local disable_dirs = { "~/Documents" }
		local cwd = vim.fn.getcwd()
		for _, dir in ipairs(disable_dirs) do
			if cwd:find(vim.fn.expand(dir), 1, true) == 1 then
				return false
			end
		end
		return true
	end,
	config = function()
		require("copilot").setup({
			panel = {
				enabled = true,
				auto_refresh = false,
				keymap = {
					jump_prev = "[[",
					jump_next = "]]",
					accept = "<CR>",
					refresh = "gr",
					open = "<M-CR>",
				},
				layout = {
					position = "bottom", -- | top | left | right
					ratio = 0.4,
				},
			},
			suggestion = {
				enabled = true,
				auto_trigger = true,
				debounce = 75,
				keymap = {
					accept = "<C-l>",
					accept_word = false,
					accept_line = false,
					next = "<C-]>",
					prev = "<C-[>",
					dismiss = "<Esc>",
				},
			},
			filetypes = {
				yaml = false,
				markdown = false,
				help = false,
				gitcommit = false,
				gitrebase = false,
				hgcommit = false,
				svn = false,
				cvs = false,
				["."] = false,
			},
			copilot_node_command = "node", -- Node.js version must be > 18.x
			server_opts_overrides = {},
		})
	end,
}
