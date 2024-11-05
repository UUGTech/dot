local M = {}

function M.setup()
	-- outer /
	vim.api.nvim_set_keymap(
		"o",
		"a/",
		':<C-U>lua require"text_objects".select_delimited("/", true)<CR>',
		{ noremap = true, silent = true }
	)
	vim.api.nvim_set_keymap(
		"x",
		"a/",
		':<C-U>lua require"text_objects".select_delimited("/", true)<CR>',
		{ noremap = true, silent = true }
	)

	-- inner /
	vim.api.nvim_set_keymap(
		"o",
		"i/",
		':<C-U>lua require"text_objects".select_delimited("/", false)<CR>',
		{ noremap = true, silent = true }
	)
	vim.api.nvim_set_keymap(
		"x",
		"i/",
		':<C-U>lua require"text_objects".select_delimited("/", false)<CR>',
		{ noremap = true, silent = true }
	)
end

function M.select_delimited(delimiter, is_outer)
	local line = vim.fn.getline(".")
	local col = vim.fn.col(".")

	-- Find the start and end positions of the delimited text
	local r_start_pos = line:reverse():find(delimiter, #line - col + 1, true)
	if r_start_pos == nil then
		r_start_pos = line:reverse():find(" ", #line - col + 1, true)
	end
	if not r_start_pos then
		r_start_pos = #line + 1
	end
	local start_pos = #line - r_start_pos + 1

	local end_pos = line:find(delimiter, col, true)

	if not end_pos then
		end_pos = #line + 1
	end

	if is_outer then
		vim.fn.setpos(".", { 0, vim.fn.line("."), start_pos, 0 })
		vim.cmd("normal! v")
		vim.fn.setpos(".", { 0, vim.fn.line("."), end_pos, 0 })
	else
		vim.fn.setpos(".", { 0, vim.fn.line("."), start_pos + 1, 0 })
		vim.cmd("normal! v")
		vim.fn.setpos(".", { 0, vim.fn.line("."), end_pos - 1, 0 })
	end
end

return M
