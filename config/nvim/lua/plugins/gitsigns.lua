return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("gitsigns").setup({
			sign_priority = 6,
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation
				map("n", "]h", function()
					if vim.wo.diff then
						return "]h"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "<Ignore>"
				end, { expr = true })

				map("n", "[h", function()
					if vim.wo.diff then
						return "[h"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "<Ignore>"
				end, { expr = true })

				-- Actions
				map("n", "<leader>hs", gs.stage_hunk, { desc = "stage_hunk" })
				map("n", "<leader>hr", gs.reset_hunk, { desc = "reset_hunk" })
				map("v", "<leader>hs", function()
					gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "stage_hunk" })
				map("v", "<leader>hr", function()
					gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "reset_hunk" })
				map("n", "<leader>hS", gs.stage_buffer, { desc = "stage_buffer" })
				map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "undo_stage_hunk" })
				map("n", "<leader>hR", gs.reset_buffer, { desc = "reset_buffer" })
				map("n", "<leader>hp", gs.preview_hunk, { desc = "preview_hunk" })
				map("n", "<leader>hb", function()
					gs.blame_line({ full = true })
				end, { desc = "blame_line" })
				map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "toggle_current_line_blame" })
				map("n", "<leader>hd", function()
					-- master or main
					local m_branch = vim.fn.system("git branch -l master main")
					-- m_branch contains "master"
					if string.match(m_branch, "master") then
						m_branch = "master"
					else
						m_branch = "main"
					end
					if m_branch == "master" then
						gs.diffthis("master")
					else
						gs.diffthis("main")
					end
				end, { desc = "diffthis" })
				map("n", "<leader>hD", function()
					gs.diffthis("~")
				end, { desc = "diffthis" })
				map("n", "<leader>td", gs.toggle_deleted, { desc = "toggle_deleted" })

				-- Text object
				map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
			end,
		})
	end,
}
