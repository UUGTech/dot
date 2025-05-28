return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	event = "VeryLazy",
	config = function()
		require("nvim-treesitter.configs").setup({
			textobjects = {
				move = {
					enable = true,
					set_jumps = true, -- whether to set jumps in the jumplist
					goto_next_start = {
						["]f"] = "@function.outer",
						["]c"] = "@class.outer",
						["]i"] = "@conditional.outer",
						["]l"] = "@loop.outer",
						["]p"] = "@parameter.outer",
						["]b"] = "@block.outer",

						-- Moving to comments, statements, etc.
						["]s"] = "@statement.outer",
						["]z"] = "@fold",
						["]o"] = "@comment.outer",

						-- Use Lua patterns to group queries
						["]a"] = "@parameter.inner",
					},

					goto_next_end = {
						["]F"] = "@function.outer",
						["]C"] = "@class.outer",
						["]I"] = "@conditional.outer",
						["]L"] = "@loop.outer",
					},

					goto_previous_start = {
						["[f"] = "@function.outer",
						["[c"] = "@class.outer",
						["[i"] = "@conditional.outer",
						["[l"] = "@loop.outer",
						["[p"] = "@parameter.outer",
						["[o"] = "@comment.outer",
					},

					goto_previous_end = {
						["[F"] = "@function.outer",
						["[C"] = "@class.outer",
						["[I"] = "@conditional.outer",
						["[L"] = "@loop.outer",
					},

					-- Go to closest object (start or end)
					goto_next = {
						["]d"] = "@conditional.outer",
					},
					goto_previous = {
						["[d"] = "@conditional.outer",
					},
				},
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						-- you can use the capture groups defined in textobjects.scm
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
						-- you can optionally set descriptions to the mappings (used in the desc parameter of
						-- nvim_buf_set_keymap) which plugins like which-key display
						["ic"] = { query = "@class.inner", desc = "select inner part of a class region" },
					},
				},
				swap = {
					enable = true,
					swap_next = {
						["<leader>sp"] = "@parameter.inner", -- swap parameter with next
						["<leader>sf"] = "@function.outer", -- swap function with next
						["<leader>sa"] = "@assignment.outer", -- swap assignment with next
					},
					swap_previous = {
						["<leader>sP"] = "@parameter.inner", -- swap parameter with previous
						["<leader>sF"] = "@function.outer", -- swap function with previous
						["<leader>sA"] = "@assignment.outer", -- swap assignment with previous
					},
				},
				lsp_interop = {
					enable = true,
					border = "none",
					floating_preview_opts = {},
					peek_definition_code = {
						["<leader>df"] = "@function.outer",
						["<leader>dF"] = "@class.outer",
					},
				},
			},
		})
		local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

		-- Make basic movements repeatable
		vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
		vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)

		-- Optionally, make builtin f, F, t, T also repeatable with ; and ,
		vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
		vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
		vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
		vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })

		local gs = require("gitsigns")
		local next_hunk_repeat, prev_hunk_repeat = ts_repeat_move.make_repeatable_move_pair(gs.next_hunk, gs.prev_hunk)

		vim.keymap.set({ "n", "x", "o" }, "]h", next_hunk_repeat)
		vim.keymap.set({ "n", "x", "o" }, "[h", prev_hunk_repeat)
	end,
}
