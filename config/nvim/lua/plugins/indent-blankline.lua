return {
	"lukas-reineke/indent-blankline.nvim",
	event = { "BufReadPre", "BufNewFile" },
	main = "ibl",
	---@module "ibl"
	---@type ibl.config
	opts = {
		indent = { char = "|", tab_char = "▸" },
		whitespace = { highlight = { "Whitespace", "NonText" } },
		scope = { enabled = false },
	},
	config = function()
		require("ibl").setup(require("plugins.indent-blankline").opts)
	end,
}
