local plenary_dir = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(vim.fn.stdpath("config"))
vim.cmd("runtime plugin/plenary.vim")
