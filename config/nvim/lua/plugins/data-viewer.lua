return {
	"vidocqh/data-viewer.nvim",
	event = "VeryLazy",
	ft = { "csv" },
	opts = {},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"kkharji/sqlite.lua", -- Optional, sqlite support
	},
}
