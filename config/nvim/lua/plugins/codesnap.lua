return {
	"mistricky/codesnap.nvim",
	build = "make build_generator",
	event = { "BufReadPre", "BufNewFile" },
	keys = {
		{ "<leader>sc", "<cmd>CodeSnap<cr>", mode = "x", desc = "Save selected code snapshot into clipboard" },
		{ "<leader>ss", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "Save selected code snapshot in ~/Pictures" },
		{ "<leader>sc", "<cmd>CodeSnap<cr>", mode = "v", desc = "Save selected code snapshot into clipboard" },
		{ "<leader>ss", "<cmd>CodeSnapSave<cr>", mode = "v", desc = "Save selected code snapshot in ~/Pictures" },
	},
	config = function()
		require("codesnap").setup({
			bg_theme = "sea",
			watermark = "",
			save_path = "~/Pictures",
			has_breadcrumbs = true,
		})
	end,
}
