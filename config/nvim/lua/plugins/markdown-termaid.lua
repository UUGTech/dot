return {
	"UUGTech/markdown-termaid.nvim",
	main = "markdown_termaid",
	ft = { "markdown" },
	cmd = { "TermaidPreview" },
	opts = {
		auto_install = true,
		keymaps = {
			preview = "<leader>ma",
		},
		integrations = {
			hover = true,
		},
	},
}
