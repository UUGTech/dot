local function load_workspace_dap_config()
	local dap = require("dap")
	local workspace_folder = vim.fn.getcwd()
	local config_file = workspace_folder .. "/.nvim-dap.json"

	if vim.fn.filereadable(config_file) == 1 then
		local config_content = vim.fn.readfile(config_file)
		local config = vim.fn.json_decode(table.concat(config_content, "\n"))

		-- delete existing configurations
		dap.configurations.go = {}
		for _, configuration in ipairs(config.configurations) do
			dap.configurations.go = dap.configurations.go or {}
			table.insert(dap.configurations.go, configuration)
		end
	end
end

return {
	"jay-babu/mason-nvim-dap.nvim",
	dependencies = {
		"williamboman/mason.nvim",
		"mfussenegger/nvim-dap",
		"rcarriga/nvim-dap-ui",
		"leoluz/nvim-dap-go",
	},
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("mason").setup()
		require("mason-nvim-dap").setup({
			handlers = {
				function(config)
					require("mason-nvim-dap").default_setup(config)
				end,
			},
		})
		require("dapui").setup({
			icons = {
				expanded = "⯆",
				collapsed = "⯈",
				circular = "↺",
			},
			mappings = {
				expand = "<CR>",
				open = "o",
				remove = "d",
			},
			sidebar = {
				elements = {
					"scopes",
					"scopes",
					"watches",
				},
				width = 40,
				position = "left",
			},
			tray = {
				elements = {
					"repl",
				},
				height = 10,
				position = "bottom",
			},
		})
		require("dap-go").setup({
			delve = {
				path = "dlv",
				initialize_timeout_sec = 20,
				port = "${port}",
				args = {},
				build_flags = {},
				detached = vim.fn.has("win32") == 0,
				cwd = nil,
			},
		})
		load_workspace_dap_config()
		vim.keymap.set("n", "<leader>dd", ":lua require'dapui'.toggle()<CR>", { silent = true })
		vim.keymap.set("n", "<leader>w", ":lua require'dapui'.elements.watches.add()<CR>", { silent = true })
		vim.keymap.set("n", "<F4>", ":lua load_launchjs()<CR>", { silent = true })
		vim.keymap.set("n", "<leader><leader>df", ":lua require'dapui'.eval()<CR>", { silent = true })
		vim.keymap.set("n", "<F5>", ":lua require'dap'.continue()<CR>", { silent = true })
		vim.keymap.set("n", "<F10>", ":lua require'dap'.step_over()<CR>", { silent = true })
		vim.keymap.set("n", "<F11>", ":lua require'dap'.step_into()<CR>", { silent = true })
		vim.keymap.set("n", "<F12>", ":lua require'dap'.step_out()<CR>", { silent = true })
		vim.keymap.set("n", "<leader>b", ":lua require'dap'.toggle_breakpoint()<CR>", { silent = true })
		vim.keymap.set("n", "<leader>dq", ":lua require'dap'.terminate()<CR>", { silent = true })
		vim.keymap.set(
			"n",
			"<leader>bc",
			":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>",
			{ silent = true }
		)
		vim.keymap.set(
			"n",
			"<leader>l",
			":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>",
			{ silent = true }
		)

		-- Custom highlight groups for breakpoints
		vim.api.nvim_set_hl(0, "DapBreakpoint", { ctermbg = 0, fg = "#993939", bg = "#31353f" })
		vim.api.nvim_set_hl(0, "DapLogPoint", { ctermbg = 0, fg = "#61afef", bg = "#31353f" })
		vim.api.nvim_set_hl(0, "DapStopped", { ctermbg = 0, fg = "#98c379", bg = "#31353f" })

		-- Sign definitions for breakpoints
		vim.fn.sign_define("DapBreakpoint", { text = "🛑", texthl = "DapBreakpoint", linehl = "", numhl = "" })
		vim.fn.sign_define("DapLogPoint", { text = "🔍", texthl = "DapLogPoint", linehl = "", numhl = "" })
		vim.fn.sign_define("DapStopped", { text = "👉", texthl = "DapStopped", linehl = "DapStopped", numhl = "" })
	end,
}
