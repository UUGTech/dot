return {
	"jghauser/fold-cycle.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("fold-cycle").setup()
		vim.keymap.set("n", "<tab>", function()
			return require("fold-cycle").open()
		end, { silent = true, desc = "Fold-cycle: open folds" })
		vim.keymap.set("n", "<s-tab>", function()
			return require("fold-cycle").close()
		end, { silent = true, desc = "Fold-cycle: close folds" })
		vim.keymap.set("n", "za", function()
			return require("fold-cycle").toggle_all()
		end, { remap = true, silent = true, desc = "Fold-cycle: toggle all folds" })
	end,
}
