-- ~/.config/nvim/after/ftplugin/typescript.lua

-- 2 spaces for tab
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.expandtab = true -- Use spaces instead of tabs

-- Optional: Set specific indent behavior if treesitter behaves oddly
-- vim.opt_local.smartindent = true
