return {
	"mrded/nvim-lsp-notify",
	requires = { "rcarriga/nvim-notify" },
	config = function()
		require("lsp-notify").setup({
			notify = require("notify"),
			icons = {
				spinner = { "|", "/", "-", "\\" }, -- `= false` to disable only this icon
				done = "!", -- `= false` to disable only this icon
			},
		})
	end,
	event = "VeryLazy",
}
