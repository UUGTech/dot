return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	dependencies = { "nvim-tree/nvim-web-devicons", opt = true },
	config = function()
		local lsp_component = {
			function()
				local msg = "No Active Lsp"
				local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
				local clients = vim.lsp.get_active_clients()
				if next(clients) == nil then
					return msg
				end
				msg = ""
				for _, client in ipairs(clients) do
					local filetypes = client.config.filetypes
					if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
						if msg ~= "" then
							msg = msg .. ", "
						end
						msg = msg .. client.name
					end
				end
				return msg
			end,
			icon = " LSP:",
			color = { fg = "#179299", gui = "bold" },
		}
		local navic = require("nvim-navic")
		local custom_theme = require("lualine.themes.catppuccin")

		custom_theme.normal.a.bg = "#179299"
		custom_theme.insert.a.bg = "#1e66f5"
		custom_theme.normal.b.bg = "#ccd0da"
		custom_theme.insert.b.bg = "#ccd0da"
		custom_theme.normal.b.fg = "#179299"
		custom_theme.insert.b.fg = "#1e66f5"

		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = custom_theme,
				component_separators = { left = "|", right = "|" },
				section_separators = { left = "", right = "" },
				disabled_filetypes = {
					statusline = {},
					winbar = {},
				},
				ignore_focus = {},
				always_divide_middle = true,
				globalstatus = false,
				refresh = {
					statusline = 1000,
					tabline = 1000,
					winbar = 1000,
				},
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { lsp_component },
				lualine_x = { "encoding", "fileformat", "filetype" },
				lualine_y = { { require("recorder").recordingStatus }, "progress" },
				lualine_z = { "location" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {},
			winbar = {
				lualine_c = {
					{
						function()
							if navic.get_location() == "" then
								return " "
							end
							return navic.get_location()
						end,
					},
				},
			},
			inactive_winbar = {},
			extensions = {},
		})
	end,
}
