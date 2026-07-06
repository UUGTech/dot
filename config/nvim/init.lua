if vim.loader then
	vim.loader.enable()
end
require("options")
require("text_objects").setup()
require("drover").setup()
require("lazy_nvim")
