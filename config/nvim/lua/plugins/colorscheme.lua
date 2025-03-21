return {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = false,
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "latte", -- latte, frappe, macchiato, mocha
			background = { -- :h background
				light = "latte",
				dark = "mocha",
			},
			transparent_background = false, -- disables setting the background color.
			show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
			term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
			dim_inactive = {
				enabled = true, -- dims the background color of inactive window
				shade = "dark",
				percentage = 0.30, -- percentage of the shade to apply to the inactive window
			},
			no_italic = false, -- Force no italic
			no_bold = false, -- Force no bold
			no_underline = false, -- Force no underline
			styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
				comments = { "italic" }, -- Change the style of comments
				conditionals = { "italic" },
				loops = {},
				functions = {},
				keywords = {},
				strings = {},
				variables = {},
				numbers = {},
				booleans = {},
				properties = {},
				types = {},
				operators = {},
			},
			color_overrides = {},
			custom_highlights = function(colors)
				local highlights = {}

				local spell_options = { style = { "bold", "underline" }, fg = colors.pink }
				local spell_groups = { "SpellBad", "SpellCap", "SpellLocal", "SpellRare" }
				for _, v in ipairs(spell_groups) do
					highlights[v] = spell_options
				end

				-- Git conflict markers highlights
				highlights.ConflictMarkerBegin = { bg = colors.red, fg = colors.base }
				highlights.ConflictMarkerOurs = { bg = colors.red, fg = colors.base, style = { "italic" } }
				highlights.ConflictMarkerCommon = { bg = colors.blue, fg = colors.base }
				highlights.ConflictMarkerTheirs = { bg = colors.green, fg = colors.base, style = { "italic" } }
				highlights.ConflictMarkerEnd = { bg = colors.green, fg = colors.base }

				return highlights
			end,
			integrations = {
				render_markdown = true,
				barbar = true,
				cmp = true,
				gitsigns = true,
				nvimtree = true,
				navic = {
					enabled = true,
					custom_bg = "NONE",
				},
				hop = true,
				treesitter = true,
				notify = true,
				mini = {
					enabled = true,
					indentscope_color = "",
				},
				noice = true,
				native_lsp = {
					enabled = true,
					virtual_text = {
						errors = { "italic" },
						hints = { "italic" },
						warnings = { "italic" },
						information = { "italic" },
						ok = { "italic" },
					},
					underlines = {
						errors = { "underline" },
						hints = { "underline" },
						warnings = { "underline" },
						information = { "underline" },
						ok = { "underline" },
					},
					inlay_hints = {
						background = true,
					},
				},
				-- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
			},
		})
	end,
	init = function()
		vim.cmd("colorscheme catppuccin")
	end,
}
