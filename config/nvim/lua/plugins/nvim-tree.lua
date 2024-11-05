return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		vim.keymap.set(
			"n",
			"<leader>e",
			":NvimTreeToggle<cr>",
			{ noremap = true, silent = true, desc = "Toggle NvimTree" }
		)
		require("nvim-tree").setup({
			update_focused_file = {
				enable = true,
			},
		})
	end,
}
