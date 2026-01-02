return {
	"jakobkhansen/journal.nvim",
	cmd = "Journal",
	event = "VeryLazy",
	config = function()
		require("journal").setup({
			root = "~/Documents/diary",
			date_format = "%Y-%m-%d",
		})
	end,
}
