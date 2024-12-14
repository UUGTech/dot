return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.4",
	dependencies = { "nvim-lua/plenary.nvim" },
	event = { "VimEnter" },
	config = function()
		local gfh_actions = require("telescope").extensions.git_file_history.actions

		local select_one_or_multi = function(prompt_bufnr)
			local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
			local multi = picker:get_multi_selection()
			if not vim.tbl_isempty(multi) then
				require("telescope.actions").close(prompt_bufnr)
				for _, j in pairs(multi) do
					if j.path ~= nil then
						vim.cmd(string.format("%s %s", "edit", j.path))
					end
				end
			else
				require("telescope.actions").select_default(prompt_bufnr)
			end
		end

		require("telescope").setup({
			pickers = {
				colorscheme = {
					enable_preview = true,
				},
			},
			defaults = {
				mappings = {
					i = {
						["<C-k>"] = require("telescope.actions").move_selection_previous,
						["<C-j>"] = require("telescope.actions").move_selection_next,
						["<CR>"] = select_one_or_multi,
					},
					n = {
						["<C-k>"] = require("telescope.actions").move_selection_previous,
						["<C-j>"] = require("telescope.actions").move_selection_next,
						["jj"] = require("telescope.actions").close,
						["<CR>"] = select_one_or_multi,
					},
				},
			},
			extensions = {
				windows = {},
				git_file_history = {
					-- Keymaps inside the picker
					mappings = {
						i = {
							["<C-g>"] = gfh_actions.open_in_browser,
						},
						n = {
							["<C-g>"] = gfh_actions.open_in_browser,
						},
					},

					-- The command to use for opening the browser (nil or string)
					-- If nil, it will check if xdg-open, open, start, wslview are available, in that order.
					browser_command = nil,
				},
			},
		})
		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>fc", builtin.colorscheme, {
			desc = "Change colorscheme",
		})
		vim.keymap.set("n", "<leader>ff", builtin.find_files, {
			desc = "Find files",
		})
		vim.keymap.set("n", "<leader>fF", builtin.current_buffer_fuzzy_find, {
			desc = "Find in current buffer",
		})
		vim.keymap.set("n", "<leader>fr", builtin.live_grep, {
			desc = "Live grep",
		})
		vim.keymap.set("n", "<leader>fb", builtin.buffers, {
			desc = "Buffers",
		})
		vim.keymap.set("n", "<leader>fg", builtin.grep_string, {
			desc = "Grep string",
		})
		vim.keymap.set("n", "<leader>fo", builtin.oldfiles, {
			desc = "Old files",
		})
		vim.keymap.set("n", "<leader>fp", builtin.registers, {
			desc = "Registers",
		})
		vim.keymap.set("n", "<leader>ft", builtin.treesitter, {
			desc = "Treesitter",
		})
		vim.keymap.set("n", "<leader>fd", builtin.diagnostics, {
			desc = "Diagnostics",
		})
		vim.keymap.set("n", "<leader>fm", builtin.marks, {
			desc = "Marks",
		})
		vim.keymap.set("n", "<leader>fn", require("telescope").extensions.notify.notify, {
			desc = "Notify",
		})
		vim.keymap.set("n", "gr", builtin.lsp_references, {
			desc = "LSP references",
		})
		vim.keymap.set("n", "gi", builtin.lsp_implementations, {
			desc = "LSP implementations",
		})
		vim.keymap.set("n", "<leader>fw", require("telescope").extensions.windows.list, {
			desc = "Windows",
		})
		vim.keymap.set("n", "<leader>fh", require("telescope").extensions.git_file_history.git_file_history, {
			desc = "Git file history",
		})

		require("telescope").load_extension("git_file_history")
	end,
}
