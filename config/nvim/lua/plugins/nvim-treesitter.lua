return {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "python", "go", "gomod", "python" },
			auto_install = true,
			highlight = {
				enable = true,
				disable = { "c", "rust" },
				additional_vim_regex_highlighting = false,
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<leader>n",
					node_incremental = "<leader>k",
					scope_incremental = "<leader>c",
					node_decremental = "<leader>j",
				},
			},
		})
		vim.treesitter.language.register("markdown", "octo")
	end,
}
