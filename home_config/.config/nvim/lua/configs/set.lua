-- Set line number and relative numbering
vim.opt.nu = true
vim.opt.relativenumber = true
-- Hightlight current line
vim.opt.cursorline = true
vim.cmd([[
  highlight CursorLineNr guibg=NONE guifg=#88C0D0
  highlight CursorLine guibg=#17191f gui=NONE
]])

-- Set Tab Number
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.clipboard = "unnamedplus"

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.termguicolors = true

vim.opt.scrolloff = 15
-- vim.opt.scrolloff = 999
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "120"

vim.opt.showmode = true

local undodir = vim.fn.stdpath("data") .. "/undodir"
if vim.fn.isdirectory(undodir) == 0 then
	vim.fn.mkdir(undodir, "p")
end
vim.opt.undodir = undodir
vim.opt.undofile = true
