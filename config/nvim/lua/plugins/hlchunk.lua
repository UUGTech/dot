return {
	"shellRaining/hlchunk.nvim",
	event = { "BufReadPre", "BufNewFile" },
	tag = "v1.3.0",
	config = function()
		require("hlchunk").setup({
			chunk = {
				style = {
					{ fg = "#7287fd" },
					{ fg = "#c21f30" },
				},
				priority = 9,
				enable = true,
				delay = 0,
			},
			indent = {
				enable = true,
				priority = 2,
				chars = {
					"|",
					"┆",
					"┊",
				},
			},
			-- blank is in issue https://github.com/shellRaining/hlchunk.nvim/issues/123
			-- it doesnt work from v1.2.1
			-- blank = {
			-- 	enable = true,
			-- 	priority = 1,
			-- 	chars = {
			-- 		"․",
			-- 	},
			-- },
		})
	end,
}
