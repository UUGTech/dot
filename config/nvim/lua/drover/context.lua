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

return M
