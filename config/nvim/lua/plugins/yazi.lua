return {
	"mikavilpas/yazi.nvim",
	event = "VeryLazy",
	keys = {
		-- 👇 in this section, choose your own keymappings!
		{
			"<leader>fy",
			"<cmd>Yazi<cr>",
			desc = "Open yazi at the current file",
		},
		{
			-- Open in the current working directory
			"<leader>fY",
			"<cmd>Yazi cwd<cr>",
			desc = "Open the file manager in nvim's working directory",
		},
		-- {
		-- 	-- NOTE: this requires a version of yazi that includes
		-- 	-- https://github.com/sxyazi/yazi/pull/1305 from 2024-07-18
		-- 	"<c-y>",
		-- 	"<cmd>Yazi toggle<cr>",
		-- 	desc = "Resume the last yazi session",
		-- },
	},
	---@type YaziConfig
	opts = {},
}
