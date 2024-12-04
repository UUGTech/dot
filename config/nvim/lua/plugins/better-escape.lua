return {
	"max397574/better-escape.nvim",
	lazy = false,
	config = function()
		require("better_escape").setup({
			timeout = vim.o.timeoutlen,
			default_mappings = false,
			mappings = {
				i = {
					j = {
						j = "<Esc>",
					},
				},
				c = {},
				t = {},
				v = {},
				n = {},
			},
		})
	end,
}
