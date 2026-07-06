local M = {}

---@param name string
---@return string
local function relative_path(name)
	local cwd = vim.fn.getcwd()
	local ok, rel = pcall(vim.fs.relpath, cwd, name)
	if ok and rel and rel ~= "" then
		return rel
	end
	return name
end

---@return string? # "@relative/path", or nil if the current buffer has no readable file
function M.current_file()
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" or vim.fn.filereadable(name) ~= 1 then
		return nil
	end
	return "@" .. relative_path(name)
end

---@return string? # newline-joined "@relative/path" list of open file buffers, or nil if none
function M.open_buffers()
	local lines = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == "" then
			local name = vim.api.nvim_buf_get_name(buf)
			if name ~= "" and vim.fn.filereadable(name) == 1 then
				table.insert(lines, "@" .. relative_path(name))
			end
		end
	end
	if #lines == 0 then
		return nil
	end
	return table.concat(lines, "\n")
end

---@return string? # the raw selected text (no file/line reference bundled in), or nil if no selection
function M.visual_selection()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_line, start_col = start_pos[2], start_pos[3]
	local end_line, end_col = end_pos[2], end_pos[3]

	if start_line == 0 or end_line == 0 then
		return nil
	end

	local lines = vim.fn.getline(start_line, end_line)
	if type(lines) == "string" then
		lines = { lines }
	end
	if #lines == 0 then
		return nil
	end

	if vim.fn.visualmode() == "v" then
		if #lines == 1 then
			lines[1] = string.sub(lines[1], start_col, end_col)
		else
			lines[1] = string.sub(lines[1], start_col)
			lines[#lines] = string.sub(lines[#lines], 1, end_col)
		end
	end

	return table.concat(lines, "\n")
end

return M
