return {
	"akinsho/toggleterm.nvim",
	version = "*",
	event = "VeryLazy",
	config = function()
		require("toggleterm").setup({
			size = 30,
			open_mapping = [[<C-t><C-t>]],
			hide_numbers = true,
			shade_filetypes = {},
			shade_terminals = true,
			start_in_insert = true,
			insert_mappings = true,
			persist_size = true,
			direction = "float",
			close_on_exit = true,
			shell = vim.o.shell,
			winbar = {
				enable = false,
			},
			float_opts = {
				border = "curved",
				title_pos = "center",
			},
		})

		-- escape terminal mode
		vim.api.nvim_set_keymap("t", "<C-t><C-j>", "<C-\\><C-n>", { noremap = true })

		-- nospell on terminal
		vim.api.nvim_create_autocmd("TermOpen", {
			pattern = "*",
			command = "setlocal nospell",
		})
	end,
}
