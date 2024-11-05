return {
	"jay-babu/mason-null-ls.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"nvimtools/none-ls.nvim",
	},
	config = function()
		require("mason-null-ls").setup({
			ensure_installed = { "goimports" },
			automatic_setup = true,
			handlers = {
				goimports = function(source, types)
					local null_ls = require("null-ls")
					local goimports_local = os.getenv("GOPRIVATE") or ""
					null_ls.register(null_ls.builtins.formatting.goimports.with({
						command = "goimports",
						args = { "-srcdir", "$DIRNAME", "-local", goimports_local },
					}))
				end,
			},
		})
		require("null-ls").setup({})
	end,
}
