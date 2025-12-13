return {
	"Mr-LLLLL/cool-chunk.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		local ft = require("cool-chunk.utils.filetype").support_filetypes
		require("cool-chunk").setup({
			chunk = {
				notify = true,
				support_filetypes = ft.support_filetypes,
				exclude_filetypes = ft.exclude_filetypes,
				hl_group = {
					chunk = "Function",
					error = "Warning",
				},
				chars = {
					horizontal_line = "─",
					vertical_line = "│",
					left_top = "┌",
					left_bottom = "└",
					left_arrow = "<",
					bottom_arrow = "v",
					right_arrow = ">",
				},
				textobject = "ah",
				animate_duration = 0, -- if don't want to animation, set to 0.
				fire_event = { "CursorMoved" },
			},
			context = {
				notify = true,
				chars = {
					"│",
				},
				hl_group = {
					context = "Constant",
				},
				exclude_filetypes = ft.exclude_filetypes,
				support_filetypes = ft.support_filetypes,
				textobject = "ih",
				jump_support_filetypes = { "lua", "python" },
				jump_start = "[{",
				jump_end = "]}",
				fire_event = { "CursorMoved" },
			},
			line_num = {
				notify = true,
				hl_group = {
					chunk = "Function",
					context = "LineNr",
					error = "Warning",
				},
				support_filetypes = ft.support_filetypes,
				exclude_filetypes = ft.exclude_filetypes,
				fire_event = { "CursorMoved" },
			},
		})
	end,
}
