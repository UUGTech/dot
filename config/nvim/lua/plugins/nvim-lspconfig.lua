local function goto_definition()
	local params = vim.lsp.util.make_position_params()

	vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result, ctx)
		if err then
			vim.notify("Error finding definition: " .. err.message, vim.log.levels.ERROR)
			return
		end

		if result == nil or vim.tbl_isempty(result) then
			vim.notify("Definition not found", vim.log.levels.WARN)
			return
		end

		local target = result[1]
		if vim.tbl_islist(result) then
			target = result[1]
		else
			target = result
		end

		local uri = target.uri or target.targetUri
		local range = target.range or target.targetSelectionRange
		local fname = vim.uri_to_fname(uri)

		-- ファイルが既に開いているか確認
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.api.nvim_buf_get_name(buf) == fname then
				-- ファイルが既に開いていたらそのウィンドウに移動
				vim.api.nvim_set_current_win(win)
				vim.api.nvim_win_set_cursor(win, { range.start.line + 1, range.start.character })
				return
			end
		end

		-- ファイルが開いていない場合、新しく開く
		vim.cmd("edit " .. fname)
		vim.api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
	end)
end

return {
	-- LSP Configuration & Plugins
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		{
			"williamboman/mason-lspconfig.nvim",
			cmd = { "LspInstall", "LspUninstall" },
			config = function()
				local mason_lspconfig = require("mason-lspconfig")
				local capabilities = require("cmp_nvim_lsp").default_capabilities()
				local navic = require("nvim-navic")
				local on_attach = function(client, bufnr)
					if client.server_capabilities.documentSymbolProvider then
						navic.attach(client, bufnr)
					end
				end
				mason_lspconfig.setup_handlers({
					function(server)
						local opt = {
							capabilities = capabilities,
							on_attach = on_attach,
						}
						require("lspconfig")[server].setup(opt)
					end,
				})
			end,
		},
	},
	config = function()
		-- IMPORTANT: make sure to setup neodev BEFORE lspconfig
		require("neodev").setup({
			-- add any options here, or leave empty to use the default settings
		})

		-- then setup your lsp server as usual
		local lspconfig = require("lspconfig")

		-- example to setup lua_ls and enable call snippets
		lspconfig.lua_ls.setup({
			settings = {
				Lua = {
					completion = {
						callSnippet = "Replace",
					},
				},
			},
		})
		-- keyboard shortcut
		vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
		vim.keymap.set(
			"n",
			"gf",
			"<cmd>lua vim.lsp.buf.format({ filter = function(client) return client.name == 'null-ls' or client.name == 'rust_analyzer' end, timeout_ms = 2000})<CR>"
		)
		vim.api.nvim_create_autocmd({ "BufWritePre" }, {
			pattern = { "*.go", "*.lua", "*.proto", "*.py", "*.rs", "*.json", "*.tsx", "*.ts", "*.tf" },
			callback = function()
				vim.lsp.buf.format({
					filter = function(client)
						return client.name == "null-ls"
							or client.name == "rust_analyzer"
							or client.name == "terraformls"
							or client.name == "tflint"
					end,
					timeout_ms = 2000,
				})
			end,
		})
		-- vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>") -- use telescope
		vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
		vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
		vim.keymap.set("n", "gd", goto_definition, { noremap = true, silent = true })
		-- vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>") -- use telescope
		vim.keymap.set({ "n", "v" }, "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>")
		-- vim.keymap.set('n', 'gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
		vim.keymap.set("n", "<space>rn", "<cmd>lua vim.lsp.buf.rename()<CR>")
		vim.keymap.set("n", "<space>lr", "<cmd>LspRestart<CR>")
		vim.keymap.set("n", "ge", "<cmd>lua vim.diagnostic.open_float()<CR>")
		-- vim.keymap.set('n', 'g]', '<cmd>lua vim.diagnostic.goto_next()<CR>')
		-- vim.keymap.set('n', 'g[', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
		-- LSP handlers
		vim.lsp.handlers["textDocument/publishDiagnostics"] =
			vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, { virtual_text = true })
		vim.diagnostic.config({
			signs = {
				priority = 1,
			},
		})
	end,
}
