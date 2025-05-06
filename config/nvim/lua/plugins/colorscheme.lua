return {
	"maxmx03/solarized.nvim",
	lazy = false,
	priority = 1000,
	---@type solarized.config
	opts = {
		transparent = {
			enabled = true, -- Master switch to enable transparency
			pmenu = true, -- Popup menu (e.g., autocomplete suggestions)
			normal = true, -- Main editor window background
			normalfloat = false, -- Floating windows
			neotree = true, -- Neo-tree file explorer
			nvimtree = true, -- Nvim-tree file explorer
			whichkey = false, -- Which-key popup
			telescope = true, -- Telescope fuzzy finder
			lazy = true, -- Lazy plugin manager UI
			mason = true, -- Mason manage external tooling
		},
		variant = "autumn",
	},
	config = function(_, opts)
		vim.o.termguicolors = true
		vim.o.background = "light"
		require("solarized").setup(opts)
		vim.cmd.colorscheme("solarized")
		-- Explicitly set diff highlights for light theme
		local color = require("solarized.color")
		local colors = require("solarized.utils").get_colors()
		local darken = color.darken
		local lighten = color.lighten
		local blend = color.blend
		local shade = color.shade
		local tint = color.tint
		vim.api.nvim_set_hl(0, "DiffAdd", { bg = lighten(colors.green, 50) })
		vim.api.nvim_set_hl(0, "DiffDelete", { bg = lighten(colors.magenta, 50) })
		vim.api.nvim_set_hl(0, "DiffChange", { bg = lighten(colors.yellow, 50) })
		vim.api.nvim_set_hl(0, "DiffText", { bg = lighten(colors.blue, 50) })
	end,
}
