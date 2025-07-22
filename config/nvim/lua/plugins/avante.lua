return {
	"yetone/avante.nvim",
	lazy = false,
	version = "0.0.25",
	cond = function()
		local disable_dirs = { "~/Documents" }
		local cwd = vim.fn.getcwd()
		for _, dir in ipairs(disable_dirs) do
			if cwd:find(vim.fn.expand(dir), 1, true) == 1 then
				return false
			end
		end
		return true
	end,
	opts = {
		provider = "copilot",
		mode = "agentic",
		providers = {
			copilot = {
				endpoint = "https://api.githubcopilot.com",
				model = "claude-sonnet-4",
				disable_tools = false,
				extra_request_body = {
					temperature = 0.75,
					max_tokens = 20480,
				},
			},
		},
		-- add any opts here
		windows = {
			---@type "right" | "left" | "top" | "bottom"
			position = "left", -- the position of the sidebar
			wrap = true, -- similar to vim.o.wrap
			width = 30, -- default % based on available width
			sidebar_header = {
				enabled = true, -- true, false to enable/disable the header
				align = "center", -- left, center, right for title
				rounded = true,
			},
			input = {
				prefix = "> ",
				height = 8, -- Height of the input window in vertical layout
			},
			edit = {
				border = "rounded",
				start_insert = true, -- Start insert mode when opening the edit window
			},
			ask = {
				floating = false, -- Open the 'AvanteAsk' prompt in a floating window
				start_insert = true, -- Start insert mode when opening the ask window
				border = "rounded",
				---@type "ours" | "theirs"
				focus_on_apply = "ours", -- which diff to focus after applying
			},
		},
		highlights = {
			diff = {
				current = "DiffDelete",
				incoming = "DiffAdd",
			},
		},
		custom_tools = function()
			return {
				require("mcphub.extensions.avante").mcp_tool(),
			}
		end,
		suggestion = {
			debounce = 600,
			throttle = 600,
		},
		behaviour = {
			auto_focus_sidebar = true,
			auto_suggestions = false, -- Experimental stage
			auto_suggestions_respect_ignore = false,
			auto_set_highlight_group = true,
			auto_set_keymaps = true,
			auto_apply_diff_after_generation = false,
			jump_result_buffer_on_finish = false,
			support_paste_from_clipboard = false,
			minimize_diff = true,
			enable_token_counting = true,
			use_cwd_as_project_root = true,
			auto_focus_on_diff_view = false,
			---@type boolean | string[] -- true: auto-approve all tools, false: normal prompts, string[]: auto-approve specific tools by name
			auto_approve_tool_permissions = false, -- Default: show permission prompts for all tools
		},
	},
	-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
	build = "make",
	-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
	dependencies = {
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		--- The below dependencies are optional,
		"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		"zbirenbaum/copilot.lua", -- for providers='copilot'
		{
			-- support for image pasting
			"HakonHarnes/img-clip.nvim",
			event = "VeryLazy",
			opts = {
				-- recommended settings
				default = {
					embed_image_as_base64 = false,
					prompt_for_file_name = false,
					drag_and_drop = {
						insert_mode = true,
					},
					-- required for Windows users
					use_absolute_path = true,
				},
			},
		},
		{
			-- Make sure to set this up properly if you have lazy=true
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "Avante" },
			},
			ft = { "markdown", "Avante" },
		},
	},
}
