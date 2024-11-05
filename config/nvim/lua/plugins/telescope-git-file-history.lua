return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		{
			"isak102/telescope-git-file-history.nvim",
			dependencies = {
				"nvim-lua/plenary.nvim",
				"tpope/vim-fugitive",
			},
		},
	},
}
