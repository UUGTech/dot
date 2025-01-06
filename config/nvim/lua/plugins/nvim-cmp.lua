return {
	-- Autocompletion
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		-- Snippet Engine & its associated nvim-cmp source
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",

		-- Adds LSP completion capabilities
		"hrsh7th/cmp-nvim-lsp",

		-- Adds a number of user-friendly snippets
		"rafamadriz/friendly-snippets",

		{
			"onsails/lspkind.nvim",
		},
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
	},
	config = function()
		local cmp = require("cmp")
		local luasnip = require("luasnip")
		local lspkind = require("lspkind")
		require("luasnip.loaders.from_vscode").lazy_load()
		luasnip.config.setup({})
		cmp.setup({
			enabled = true,
			completion = {
				completeopt = "menu,menuone,noinsert,noselect",
			},
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			mapping = cmp.mapping.preset.insert({
				["<C-j>"] = cmp.mapping.select_next_item(),
				["<C-k>"] = cmp.mapping.select_prev_item(),
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<Tab>"] = cmp.mapping.confirm({ select = true }),
				["<C-e>"] = cmp.mapping.abort(),
			}),
			window = {
				completion = cmp.config.window.bordered(),
				documentation = cmp.config.window.bordered(),
			},
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "buffer" },
				{ name = "path" },
			}),
			formatting = {
				fields = { "abbr", "kind", "menu" },
				format = lspkind.cmp_format({
					mode = "symbol_text",
					maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
					ellipsis_char = "...", -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
					menu = {
						buffer = "[Buffer]",
						nvim_lsp = "[LSP]",
						luasnip = "[LuaSnip]",
					},

					symbol_map = {
						Constructor = "",
						Field = "ﰠ",
						Variable = "",
						Class = "ﴯ",
						Interface = "",
						Module = "",
						Property = "ﰠ",
						Unit = "塞",
						Value = "",
						Enum = "",
						Keyword = "",
						Snippet = "",
						EnumMember = "",
						Struct = "פּ",
						Event = "",
						TypeParameter = "",
						Copilot = "",
					},
				}),
			},
			experimental = {
				ghost_text = false,
			},
		})

		-- Disable nvim-cmp in telescope prompt
		cmp.setup.filetype("TelescopePrompt", {
			enabled = false,
		})
	end,
}
