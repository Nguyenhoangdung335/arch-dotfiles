-- ===========================
-- UI: Line Numbers & Cursor
-- ===========================
vim.opt.nu = true -- Show absolute line numbers
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.cursorline = true -- Highlight current line

vim.cmd([[
  highlight CursorLineNr guibg=NONE guifg=#88C0D0
  highlight CursorLine guibg=#17191f gui=NONE
]])

-- ===========================
-- Tabs & Indentation
-- ===========================
vim.opt.tabstop = 4 -- Number of spaces per tab
vim.opt.softtabstop = 4 -- Number of spaces for editing operations
vim.opt.shiftwidth = 4 -- Number of spaces for autoindent
vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.smartindent = true -- Smart autoindenting

-- ===========================
-- Clipboard
-- ===========================
vim.opt.clipboard = "unnamedplus" -- Use system clipboard

-- ===========================
-- Display & Colors
-- ===========================
vim.opt.termguicolors = true -- Enable 24-bit RGB colors
vim.opt.wrap = false -- Disable line wrap
vim.opt.colorcolumn = "120" -- Highlight column 120

-- ===========================
-- Scrolling & Sign Column
-- ===========================
vim.opt.scrolloff = 15 -- Minimum lines above/below cursor
-- vim.opt.scrolloff = 999         -- Uncomment for centered cursor
vim.opt.signcolumn = "yes" -- Always show sign column

-- ===========================
-- Filename Characters
-- ===========================
vim.opt.isfname:append("@-@") -- Allow @ in file names

-- ===========================
-- Performance
-- ===========================
vim.opt.updatetime = 50 -- Faster completion
-- vim.opt.pumheight = 10 -- Maximum number of items to show in the popup menu

-- ===========================
-- Mode Display
-- ===========================
vim.opt.showmode = true -- Show mode in command line

-- ===========================
-- Undo History
-- ===========================
local undodir = vim.fn.stdpath("data") .. "/undodir"
if vim.fn.isdirectory(undodir) == 0 then
	vim.fn.mkdir(undodir, "p")
end
vim.opt.undodir = undodir -- Set undo directory
vim.opt.undofile = true -- Enable persistent undo

-- ===========================
-- Custom File Type
-- ===========================
vim.filetype.add({
	pattern = {
		[".*%.js"] = {
			priority = 10,
			function(_, bufnr)
				if not bufnr then
					return
				end
				-- Read the first line of the buffer
				local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)
				if lines[1] and lines[1]:match("^%.pragma library") then
					return "qmljs"
				end
				-- If it's not a Quickshell file, fallback to default 'javascript'
			end,
		},
	},
})
