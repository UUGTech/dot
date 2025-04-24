return {
	"echasnovski/mini.splitjoin",
	dependencies = { { "echasnovski/mini.nvim", version = "*" } },
	version = "*",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("mini.splitjoin").setup()
	end,
}
