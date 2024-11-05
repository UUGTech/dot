return {
	"echasnovski/mini.splitjoin",
	dependencies = { { "echasnovski/mini.nvim", version = "*" } },
	version = "*",
	event = "VeryLazy",
	config = function()
		require("mini.splitjoin").setup()
	end,
}
