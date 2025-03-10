function CopilotChatBuffer()
	local input = vim.fn.input("Quick Chat: ")
	if input ~= "" then
		require("CopilotChat").ask(input, { context = "buffers" })
	end
end
local disable_dirs = { "~/Documents" }
return {
	"CopilotC-Nvim/CopilotChat.nvim",
	branch = "main",
	dependencies = {
		{ "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
		{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
	},
	event = "BufRead",
	cond = function()
		local cwd = vim.fn.getcwd()
		for _, dir in ipairs(disable_dirs) do
			if cwd:find(vim.fn.expand(dir), 1, true) == 1 then
				return false
			end
		end
		return true
	end,
	config = function()
		require("CopilotChat").setup({
			vim.api.nvim_set_keymap(
				"n",
				"<leader>ocb",
				"<cmd>lua CopilotChatBuffer()<cr>",
				{ noremap = true, silent = true, desc = "Quick Chat Buffer" }
			),
			vim.api.nvim_set_keymap(
				"n",
				"<leader>occ",
				"<cmd> CopilotChat<cr>",
				{ noremap = true, silent = true, desc = "Quick Chat" }
			),
		})
	end,
}
