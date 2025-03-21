return {
	"akinsho/git-conflict.nvim",
	lazy = false,
	version = "*",
	config = function()
		require("git-conflict").setup({
			default_mappings = {
				ours = "o",
				theirs = "t",
				none = "0",
				both = "b",
				next = "n",
				prev = "p",
			}, -- disable buffer local mapping created by this plugin
			default_commands = true, -- disable commands created by this plugin
			disable_diagnostics = false, -- This will disable the diagnostics in a buffer whilst it is conflicted
			list_opener = "copen", -- command or function to open the conflicts list
			highlights = { -- They must have background color, otherwise the default color will be used
				incoming = "DiffAdd",
				current = "DiffText",
			},
		})
		vim.api.nvim_create_autocmd("User", {
			pattern = "GitConflictDetected",
			callback = function()
				vim.notify("Conflict detected in " .. vim.fn.expand("<afile>"))
				vim.keymap.set("n", "cww", function()
					engage.conflict_buster()
					create_buffer_local_mappings()
				end)
			end,
		})
		-- leader gc to refresh the conflict
		vim.keymap.set("n", "<leader>gc", "<cmd>GitConflictRefresh<CR>", { noremap = true, silent = true })
		-- when buffer is opened, check if there is a conflict
		vim.api.nvim_create_autocmd("BufReadPost", {
			pattern = "*",
			callback = function()
				-- Wait a bit to ensure buffer is fully loaded
				vim.defer_fn(function()
					-- Check if buffer is still valid
					if vim.api.nvim_buf_is_valid(0) then
						vim.cmd("GitConflictRefresh")
					end
				end, 1000) -- 100ms delay for better reliability
			end,
		})
	end,
}
