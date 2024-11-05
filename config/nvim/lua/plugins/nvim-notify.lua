return {
	"rcarriga/nvim-notify",
	event = "VeryLazy",
	opts = {
		timeout = 2000,
		max_height = function()
			return math.floor(vim.o.lines * 0.75)
		end,
		max_width = function()
			return math.floor(vim.o.columns * 0.75)
		end,
		-- transparent same with background
		background_colour = "#000000",
		render = "default",
		top_down = false,
	},
}
