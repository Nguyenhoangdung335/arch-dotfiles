-- Leader Key
vim.g.mapleader = " "

-- General Navigation & Tab Management
-- -----------------------------------
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
-- vim.keymap.set("n", "<leader>t" , ":tabnew +terminal<cr>", {silent = true})
-- vim.keymap.set("n", "<C-t>" , "gt")
-- vim.keymap.set("n", "<C-T>" , "gT")

-- Buffer Navigation
vim.keymap.set("n", "<C-{>", "<cmd>b#<CR>", { desc = "Go to previous buffer" })
vim.keymap.set("n", "<C-}>", "<cmd>bn<CR>", { desc = "Go to next buffer" })
-- vim.keymap.set("n", "]b", ":bnext<CR>")
-- vim.keymap.set("n", "[b", ":bprevious<CR>")

-- Search & Highlight
vim.keymap.set("n", "<leader>nh", ":nohlsearch<CR>", { desc = "No Highlight", silent = true })

-- Cursor & Scrolling
vim.keymap.set("n", "<Leader>ct", function()
	vim.opt.cursorline = not vim.opt.cursorline
end, { desc = "Toggle cursorline" })

local function smooth_center_scroll(key)
	return function()
		local current_scrolloff = vim.o.scrolloff
		vim.o.scrolloff = 999
		local count = vim.v.count > 0 and vim.v.count or ""
		local keycode = vim.api.nvim_replace_termcodes(key, true, false, true)
		vim.cmd("normal! " .. count .. keycode)
		vim.schedule(function()
			vim.o.scrolloff = current_scrolloff
		end)
	end
end

vim.keymap.set(
	"n",
	"<C-d>",
	smooth_center_scroll("<C-d>"),
	{ noremap = true, desc = "Scroll down and center smoothly" }
)
vim.keymap.set("n", "<C-u>", smooth_center_scroll("<C-u>"), { noremap = true, desc = "Scroll up and center smoothly" })
vim.keymap.set(
	"n",
	"G",
	smooth_center_scroll("G"),
	{ noremap = true, desc = "Scroll to the bottom and center smoothly" }
)
vim.keymap.set(
	"n",
	"gg",
	smooth_center_scroll("gg"),
	{ noremap = true, desc = "Scroll to the top and center smoothly" }
)

-- Insert Line Above/Below
vim.keymap.set("n", "<CR>", "myo<Esc>'y", { desc = "Insert line below and return" })
vim.keymap.set("n", "<S-CR>", "myO<Esc>'y", { desc = "Insert line above and return" })
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "qf", "cmdwin", "help", "vim" },
	callback = function()
		vim.keymap.set("n", "<CR>", "<CR>", { buffer = true })
		vim.keymap.set("n", "<S-CR>", "<S-CR>", { buffer = true })
	end,
})

-- Visual Mode: Move, Indent, and Wrap
-- -----------------------------------
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "<Tab>", ">gv")
vim.keymap.set("v", "<S-Tab>", "<gv")

-- Wrap visual selection in quotes
vim.keymap.set("v", "'", [[<Esc>`<i'<Esc>`>la'<Esc>]], { desc = "Wrap selection in single quotes" })
vim.keymap.set("v", '"', [[<Esc>`<i"<Esc>`>la"<Esc>]], { desc = "Wrap selection in double quotes" })

-- Paste in Visual Mode without overwriting default register
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without replacing the default register after cursor" })
vim.keymap.set("x", "<leader>P", '"_dp', { desc = "Paste without replacing the default register before cursor" })

-- Substitute in Visual Mode
vim.keymap.set("v", "<leader>s", '"gy:%s/\\V<C-r>g//g<Left><Left>', {
	desc = "Substitute selected text in the current buffer",
	noremap = true,
})
vim.keymap.set("v", "<leader>cs", '"gy:%s/\\V<C-r>g//gc<Left><Left><Left>', {
	desc = "Substitute selected text in the current buffer (case sensitive)",
	noremap = true,
})

-- Yank & Clipboard
-- ----------------
-- Yank absolute path to system register
-- vim.keymap.set("n", "<leader>ya", ':let @+ = expand("%:p")<CR>', { desc = "Yank the absolute path", silent = true })
vim.keymap.set("n", "<leader>ya", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.notify(string.format("Yanked absolute path to system register: %s", path), vim.log.levels.WARN)
end, {
	desc = "Yank the absolute path to system register",
	silent = true,
})

-- Yank relative path to system register
vim.keymap.set("n", "<leader>yr", function()
	local path = vim.fn.expand("%:p:.")
	if path:sub(1, 1) ~= "/" then
		path = "./" .. path
	end
	vim.fn.setreg("+", path)
	vim.notify(string.format("Yanked relative path to system register: %s", path), vim.log.levels.WARN)
end, {
	desc = "Yank the relative path to the system register",
	silent = true,
})

vim.keymap.set("v", "<leader>y", '"+y', { desc = "Yank the selected text into the system register" })

-- Insert Mode
-- -----------
-- Remap Esc key for faster escape
vim.keymap.set("i", "jk", "<Esc>")
-- vim.keymap.set("i", "kj", "<Esc>")

-- Completion
vim.keymap.set("i", "<C-.>", function()
	if require("cmp").visible() then
		require("cmp").select_next_item({ behavior = require("cmp").SelectBehavior.Select })
	else
		require("cmp").complete()
	end
	return ""
end, { expr = true, noremap = true, desc = "Trigger completion" })

-- Miscellaneous
-- -------------
vim.keymap.set("n", "fF", "F", { desc = "Find previous character in the line" })
vim.keymap.set("n", "<C-.>", "<Nop>", { noremap = true, silent = true, desc = "Disable . command for Ctrl+." })
vim.keymap.set("n", "q:", "<Nop>", { noremap = true, silent = true, desc = "Disable q: command" })

-- Text Wrapping
vim.opt.wrap = false
vim.keymap.set("n", "<leader>ww", function()
	---@diagnostic disable-next-line: undefined-field
	if vim.opt.wrap:get() then
		vim.opt.wrap = false
		vim.notify("Wrap disabled", vim.log.levels.INFO)
	else
		vim.opt.wrap = true
		vim.notify("Wrap enabled", vim.log.levels.INFO)
	end
end, { desc = "Toggle wrap" })
vim.keymap.set("n", "j", "v:count == 0 ? ( &wrap ? 'gj' : 'j') : 'j'", { expr = true })
vim.keymap.set("n", "k", "v:count == 0 ? ( &wrap ? 'gk' : 'k') : 'k'", { expr = true })

-- Netrw Custom Mappings
-- ---------------------
local function netrw_copy_with_prompt()
	local current_path = vim.fn.expand("%:p")
	if vim.fn.filereadable(current_path) == 0 and vim.fn.isdirectory(current_path) == 0 then
		print("Error: Cursor not on a valid file or directory.")
		return
	end
	local current_name = vim.fn.expand("%")
	local new_name = vim.fn.input("Copy to: ", current_name)
	if new_name == nil or new_name == "" then
		print("Copy cancelled.")
		return
	end
	local cmd = string.format("cp -r %s %s", vim.fn.shellescape(current_path), vim.fn.shellescape(new_name))
	vim.fn.system(cmd)
	vim.cmd("edit %")
	print(string.format("Copied '%s' to '%s'", current_name, new_name))
end

vim.api.nvim_create_augroup("NetrwCustomMappings", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	pattern = "netrw",
	group = "NetrwCustomMappings",
	callback = function()
		-- Map <leader>cp in normal mode to our custom function.
		-- The keymap is buffer-local, so it won't exist outside of netrw.
		vim.keymap.set("n", "<leader>cp", netrw_copy_with_prompt, {
			buffer = true,
			noremap = true,
			silent = true,
			desc = "Netrw: Copy file/dir with new name",
		})
	end,
})

-- Historical/Disabled Mappings (for reference)
-- --------------------------------------------
-- vim.keymap.set("n", "<leader>t" , ":tabnew +terminal<cr>", {silent = true})
-- vim.keymap.set("n", "<C-t>" , "gt")
-- vim.keymap.set("n", "<C-T>" , "gT")
-- vim.keymap.set("n", "<leader>ya", ':let @+ = expand("%:p")<CR>', { desc = "Yank the absolute path", silent = true })
-- vim.keymap.set("i", "kj", "<Esc>")
-- vim.keymap.set("n", "]b", ":bnext<CR>")
-- vim.keymap.set("n", "[b", ":bprevious<CR>")
