-- ./lua/configs/autocmd.lua
vim.api.nvim_create_autocmd("SwapExists", {
	group = vim.api.nvim_create_augroup("SnacksSwapSilent", { clear = true }),
	callback = require("modules.swap_preview").swap_preview_autocmd_callback,
})

-- Disable cursorline for large files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "slowfiletype",
	callback = function()
		vim.opt.cursorline = false
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "netrw",
	callback = function()
		vim.keymap.set("n", "<C-H>", "<Nop>", { buffer = true })
		vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { buffer = true, silent = true })
		vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { buffer = true, silent = true })
		vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { buffer = true, silent = true })
		vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { buffer = true, silent = true })
	end,
})
