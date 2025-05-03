return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = "nvim-tree/nvim-web-devicons",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("bufferline").setup({
			-- highlights = require("catppuccin.groups.integrations.bufferline").get(),
		})
	end,
}
