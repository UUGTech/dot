return {
	"nvim-mini/mini.bufremove",
	version = "*",
	event = "VeryLazy",
	config = function()
		require("mini.bufremove").setup()
		vim.api.nvim_create_user_command("Bufdelete", function()
			MiniBufremove.delete()
		end, { desc = "Remove buffer" })
		vim.api.nvim_set_keymap("n", "<C-w>d", ":Bufdelete<CR>", { noremap = true, silent = true })
	end,
}
