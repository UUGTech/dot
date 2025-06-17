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
		plugins = {
			indent_blankline = true, -- Indent-blankline plugin support
		},
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
		vim.api.nvim_set_hl(0, "DiffAdd", { fg = colors.base03, bg = lighten(colors.green, 70) })
		vim.api.nvim_set_hl(0, "DiffDelete", { fg = colors.base03, bg = lighten(colors.magenta, 70) })
		vim.api.nvim_set_hl(0, "DiffChange", { fg = colors.base03, bg = lighten(colors.yellow, 70) })
		vim.api.nvim_set_hl(0, "DiffText", { fg = colors.base03, bg = lighten(colors.blue, 70) })
		vim.api.nvim_set_hl(0, "GitSignsAddInLine", { fg = colors.base03, bg = lighten(colors.green, 70) })
		vim.api.nvim_set_hl(0, "GitSignsDeleteInLine", { fg = colors.base03, bg = lighten(colors.magenta, 70) })
		vim.api.nvim_set_hl(0, "GitSignsChangeInLine", { fg = colors.base03, bg = lighten(colors.yellow, 70) })
		vim.api.nvim_set_hl(0, "NeotestPassed", { fg = colors.green })
		vim.api.nvim_set_hl(0, "NeotestRunning", { fg = colors.yellow })
		vim.api.nvim_set_hl(0, "NeotestSkipped", { fg = colors.blue })
		vim.api.nvim_set_hl(0, "NeotestFile", { fg = colors.blue })
		vim.api.nvim_set_hl(0, "NeotestDir", { fg = colors.blue })
		vim.api.nvim_set_hl(0, "NeotestWinSelect", { fg = colors.blue })
		vim.api.nvim_set_hl(0, "NeotestNamespace", { fg = colors.magenta })
		vim.api.nvim_set_hl(0, "NeotestFailed", { fg = colors.red })
		vim.api.nvim_set_hl(0, "SpellBad", { underline = true, fg = colors.magenta })
		-- $base03:    #002b36;
		-- $base02:    #073642;
		-- $base01:    #586e75;
		-- $base00:    #657b83;
		-- $base0:     #839496;
		-- $base1:     #93a1a1;
		-- $base2:     #eee8d5;
		-- $base3:     #fdf6e3;
		-- $yellow:    #b58900;
		-- $orange:    #cb4b16;
		-- $red:       #dc322f;
		-- $magenta:   #d33682;
		-- $violet:    #6c71c4;
		-- $blue:      #268bd2;
		-- $cyan:      #2aa198;
		-- $green:     #859900;
	end,
}
