-- encoding
vim.o.encoding = "utf-8"
vim.scriptencoding = "utf-8"

-- visual
vim.cmd("language en_US.UTF-8")
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.autoindent = true
vim.o.smartindent = true

vim.o.visualbell = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.showmatch = true
vim.o.matchtime = 1
vim.o.listchars = "eol:$,tab:>.,trail:_,lead:."
vim.o.list = true
vim.o.scrolloff = 5
vim.api.nvim_exec(
	[[
  augroup TrimWhitespace
    autocmd!
    autocmd BufWritePre * :%s/\\s\\+$//e
  augroup END
]],
	false
)
vim.o.sidescrolloff = 5
vim.o.wrap = false

-- dotenv filetype
vim.filetype.add({
	pattern = {
		[".env.*"] = "sh",
	},
})

-- search
vim.o.incsearch = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = true

-- manipulation
vim.g.mapleader = " "
vim.opt.clipboard:append({ "unnamedplus" })
vim.o.ttimeout = true
vim.o.ttimeoutlen = 50

vim.o.undodir = vim.fn.stdpath("cache") .. "/undo"
vim.opt.spelllang = "en_us"
vim.opt.spell = true

-- disable in copilot-chat
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*",
	callback = function()
		if vim.bo.filetype == "copilot-chat" then
			vim.opt_local.spell = false
		end
	end,
})
-- disable in txt
vim.api.nvim_create_autocmd({ "BufEnter" }, {
	pattern = { "*.txt", "*.md" },
	callback = function()
		vim.opt_local.spell = false
		vim.opt_local.wrap = true
		-- j と k に gj と gk を割り当て
		vim.keymap.set("n", "j", "gj", { noremap = true, silent = true })
		vim.keymap.set("n", "k", "gk", { noremap = true, silent = true })
	end,
})
vim.api.nvim_create_autocmd({ "BufLeave" }, {
	pattern = { "*.txt" },
	callback = function()
		vim.opt.spell = true
	end,
})

vim.api.nvim_set_keymap("i", "っｊ", "<ESC>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-s>", ":w<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<C-a>", "<Esc>A", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-a>", "ggVG", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>n", ":bnext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>p", ":bprev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>v", ":vert sball<CR>", { noremap = true, silent = true }) -- splits all buffers

vim.api.nvim_set_keymap("n", "<A-j>", ":m .+1<CR>==", { noremap = true, silent = true }) -- move line down in normal mode
vim.api.nvim_set_keymap("n", "<A-k>", ":m .-2<CR>==", { noremap = true, silent = true }) -- move line up in normal mode
vim.api.nvim_set_keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true }) -- move line down in visual mode
vim.api.nvim_set_keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true }) -- move line up in visual mode

vim.api.nvim_set_keymap("n", "<leader>s", ":set nospell<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>S", ":set spell<CR>", { noremap = true, silent = true })
