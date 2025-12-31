return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = "nvim-tree/nvim-web-devicons",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local highlights = require("rose-pine.plugins.bufferline")
		require("bufferline").setup({
			highlights = highlights,
		})
	end,
}
