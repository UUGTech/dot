return {
	"aaronik/treewalker.nvim",

	event = "VeryLazy",

	-- The following options are the defaults.
	-- Treewalker aims for sane defaults, so these are each individually optional,
	-- and setup() does not need to be called, so the whole opts block is optional as well.
	opts = {
		-- Whether to briefly highlight the node after jumping to it
		highlight = true,

		-- How long should above highlight last (in ms)
		highlight_duration = 250,

		-- The color of the above highlight. Must be a valid vim highlight group.
		-- (see :h highlight-group for options)
		highlight_group = "CursorLine",
	},

	config = function()
		-- movement
		vim.keymap.set({ "n", "v" }, "<C-k>", "<cmd>Treewalker Up<cr>", { silent = true })
		vim.keymap.set({ "n", "v" }, "<C-j>", "<cmd>Treewalker Down<cr>", { silent = true })
		vim.keymap.set({ "n", "v" }, "<C-l>", "<cmd>Treewalker Right<cr>", { silent = true })
		vim.keymap.set({ "n", "v" }, "<C-h>", "<cmd>Treewalker Left<cr>", { silent = true })

		-- swapping
		vim.keymap.set("n", "<leader><C-j>", "<cmd>Treewalker SwapDown<cr>", { silent = true })
		vim.keymap.set("n", "<leader><C-k>", "<cmd>Treewalker SwapUp<cr>", { silent = true })
		vim.keymap.set("n", "<leader><C-l>", "<cmd>Treewalker SwapRight<CR>", { silent = true })
		vim.keymap.set("n", "<leader><C-h>", "<cmd>Treewalker SwapLeft<CR>", { silent = true })
	end,
}
