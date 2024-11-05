return {
	"jinh0/eyeliner.nvim",
	config = function()
		require("eyeliner").setup({
			highlight_on_key = true,
			dim = false,
			max_length = 9999,
			disable_filetypes = {},
			disable_buftypes = {},
			default_keymaps = true,
		})
	end,
	event = { "BufReadPre", "BufAdd", "BufNewFile" },
}
