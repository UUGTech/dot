return {
	"NTBBloodbath/color-converter.nvim",
	event = "BufRead",
	config = function()
		vim.keymap.set(
			"n",
			"<leader>cc",
			"<cmd>lua require('color-converter').cycle()<cr>",
			{ noremap = true, silent = true }
		)
	end,
}
