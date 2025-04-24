return {
	"folke/zen-mode.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {},
	config = function()
		require("zen-mode").setup({})
	end,
}
