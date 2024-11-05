return {
	"numToStr/FTerm.nvim",
	lazy = false,
	-- cmd = { "FTerm", "FTermToggle", "FTermOpen" },
	config = function()
		vim.keymap.set(
			"n",
			"<C-t><C-t>",
			'<CMD>lua require("FTerm").toggle()<CR>',
			{ noremap = true, silent = true, desc = "FTerm Toggle" }
		)
		vim.keymap.set("t", "<C-j><C-j>", "<C-\\><C-n>", { noremap = true, silent = true, desc = "FTerm Exit" })
		vim.keymap.set(
			"t",
			"<C-t><C-t>",
			'<C-\\><C-n><CMD>lua require("FTerm").toggle()<CR>',
			{ noremap = true, silent = true, desc = "FTerm Toggle" }
		)
		require("FTerm").setup({
			border = "single",
			dimensions = {
				height = 0.9,
				width = 0.9,
			},
		})
	end,
}
