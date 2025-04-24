return {
	"phaazon/hop.nvim",
	branch = "v2", -- optional but strongly recommended
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		-- you can configure Hop the way you like here; see :h hop-config
		require("hop").setup({ keys = "etovxqpdygfblzhckisuran" })
		vim.keymap.set("n", "ss", "<cmd>HopWord<cr>", { silent = true, desc = "Hop Word" })
		vim.keymap.set("n", "sl", "<cmd>HopLine<cr>", { silent = true, desc = "Hop Line" })
		vim.keymap.set("n", "sc", "<cmd>HopChar1<cr>", { silent = true, desc = "Hop Char" })
		vim.keymap.set("n", "sv", "<cmd>HopVerticel<cr>", { silent = true, desc = "Hop Vertical" })
	end,
}
