return {
	"amekusa/auto-input-switch.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("auto-input-switch").setup({
			restore = { enable = false },
			os_settings = { -- OS-specific settings
				macos = {
					enable = true,
					cmd_get = "macism", -- Command to get the current input source
					cmd_set = "macism %s", -- Command to set the input source (Use `%s` as a placeholder for the input source)
					normal_input = false, -- Name of the input source for Normalize (Set false to auto-detect)
					lang_inputs = {
						Ja = "com.google.inputmethod.Japanese.base",
					},
				},
			},
			match = {
				enable = true, -- Enable Match?
				languages = {
					Ja = { enable = true, priority = 0, pattern = "[\\u3000-\\u30ff\\uff00-\\uffef\\u4e00-\\u9fff]" },
				},
			},
		})
	end,
}
