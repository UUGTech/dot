return {
	"ysmb-wtsg/in-and-out.nvim",
	event = "InsertEnter",
	keys = {
		{
			"<C-CR>",
			function()
				require("in-and-out").in_and_out()
			end,
			mode = "i",
		},
	},
}
