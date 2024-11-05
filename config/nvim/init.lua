if vim.loader then
	vim.loader.enable()
end
require("options")
require("text_objects").setup()
require("lazy_nvim")
