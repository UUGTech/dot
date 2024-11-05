return {
	"anuvyklack/windows.nvim",
	event = { "BufReadPre", "BufAdd", "BufNewFile" },
	dependencies = {
		"anuvyklack/middleclass",
		"anuvyklack/animation.nvim",
	},
	config = function()
		vim.o.winwidth = 10
		vim.o.winminwidth = 10
		vim.o.equalalways = false
		require("windows").setup({
			autowidth = {
				enable = true,
				winwidth = 0.5,
			},
		})
	end,
}
