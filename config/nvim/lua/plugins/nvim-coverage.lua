return {
	"andythigpen/nvim-coverage",
	version = "*",
	event = "VeryLazy",
	config = function()
		require("coverage").setup({
			auto_reload = true,
		})
	end,
}
