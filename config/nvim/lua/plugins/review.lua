return {
	evernt = "VeryLazy",
	"georgeguimaraes/review.nvim",
	dependencies = {
		"esmuellert/codediff.nvim",
		"MunifTanjim/nui.nvim",
	},
	cmd = { "Review" },
	keys = {
		{ "<leader>r", "<cmd>Review<cr>", desc = "Review" },
		{ "<leader>R", "<cmd>Review commits<cr>", desc = "Review commits" },
	},
	opts = {},
}
