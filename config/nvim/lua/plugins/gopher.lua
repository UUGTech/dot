return {
	"olexsmir/gopher.nvim",
	ft = "go",
	event = "VeryLazy",
	config = function()
		require("gopher").setup({})
	end,
	build = function()
		vim.cmd([[silent! GoInstallDeps]])
	end,
}
