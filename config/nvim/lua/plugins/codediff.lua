return {
	"esmuellert/codediff.nvim",
	dependencies = { "MunifTanjim/nui.nvim" },
	cmd = "CodeDiff",
	keys = {
		{ "<leader>dv", "<cmd>CodeDiff<CR>", desc = "Open CodeDiff" },
		{ "<leader>dh", "<cmd>CodeDiff history<CR>", desc = "CodeDiff History" },
	},
	config = function()
		require("codediff").setup({
			-- Diff表示時にinlay hintsを無効化（見やすくするため）
			disable_inlay_hints = true,

			-- 差分計算の最大時間（ミリ秒）
			max_computation_time_ms = 500,

			-- オリジナルファイルの位置（"left" or "right"）
			original_position = "left",

			-- エクスプローラーパネルの設定
			explorer = {
				position = "left", -- "left" or "bottom"
				width = 35,
				height = 16,
				view_mode = "tree", -- "list" or "tree"
			},

			-- ハイライト設定
			highlights = {
				line_insert = "DiffAdd",
				line_delete = "DiffDelete",
				char_insert = "DiffText",
				char_delete = "DiffDelete",
			},

			-- キーマップ設定
			keymaps = {
				view = {
					quit = "q", -- 差分ビューを閉じる
					next_hunk = "]c", -- 次の変更へ
					prev_hunk = "[c", -- 前の変更へ
					diff_get = "do", -- 他方のバッファから変更を取得
					diff_put = "dp", -- 他方のバッファに変更を適用
				},
				explorer = {
					select = "<CR>", -- ファイルの差分を開く
					toggle_view_mode = "i", -- ビューモード切り替え（list/tree）
					toggle_stage = "-", -- ファイルをステージング/アンステージング
					stage_all = "S", -- すべてステージング
					unstage_all = "U", -- すべてアンステージング
					restore = "X", -- ファイルを復元
					quit = "q", -- エクスプローラーを閉じる
				},
				conflict = {
					accept_incoming = "<leader>ct", -- incoming（相手側）の変更を採用
					accept_current = "<leader>co", -- current（自分側）の変更を採用
					next_conflict = "]x", -- 次のコンフリクトへ
					prev_conflict = "[x", -- 前のコンフリクトへ
				},
			},
		})

		-- WORKAROUND: CodeDiffを閉じた後の空バッファを自動削除
		vim.api.nvim_create_autocmd("BufEnter", {
			group = vim.api.nvim_create_augroup("codediff_cleanup", { clear = true }),
			callback = function()
				-- CodeDiffバッファが閉じられた後、[No Name]バッファを削除
				local bufs = vim.api.nvim_list_bufs()
				for _, buf in ipairs(bufs) do
					if vim.api.nvim_buf_is_valid(buf) then
						local name = vim.api.nvim_buf_get_name(buf)
						local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
						-- 空のバッファ名かつ、通常のバッファタイプで、変更がない場合
						if name == "" and buftype == "" and not vim.api.nvim_get_option_value("modified", { buf = buf }) then
							local bufinfo = vim.fn.getbufinfo(buf)[1]
							-- どのウィンドウにも表示されていない場合のみ削除
							if bufinfo and #bufinfo.windows == 0 then
								vim.api.nvim_buf_delete(buf, { force = true })
							end
						end
					end
				end
			end,
		})
	end,
}
