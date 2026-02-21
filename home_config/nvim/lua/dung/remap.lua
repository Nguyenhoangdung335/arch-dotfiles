-- Set Leader key
vim.g.mapleader = " "

-- Set Vim KeyMap, In normal mode, if press a combination of <leader> key (space - as above) + p + v, execute the Vim Ex command
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
-- vim.keymap.set("n", "<leader>t" , ":tabnew +terminal<cr>", {silent = true})
-- vim.keymap.set("n", "<C-t>" , "gt")
-- vim.keymap.set("n", "<C-T>" , "gT")

-- Move Selected block of text in Visual Mode up or down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Yank the absolute path of the current file in the buffer into the system register
-- vim.keymap.set("n", "<leader>ya", ':let @+ = expand("%:p")<CR>', { desc = "Yank the absolute path", silent = true })
vim.keymap.set("n", "<leader>ya", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.notify(string.format("Yanked absolute path to system register: %s", path), vim.log.levels.WARN)
end, {
	desc = "Yank the absolute path to system register",
	silent = true,
})
-- Yank the relative path of the current file in the buffer into the system register
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

vim.keymap.set("v", "<Tab>", ">gv")
vim.keymap.set("v", "<S-Tab>", "<gv")

vim.keymap.set("n", "<Leader>ct", function()
	vim.opt.cursorline = not vim.opt.cursorline
end, { desc = "Toggle cursorline" })

-- Remap Esc key for faster escape
vim.keymap.set("i", "jk", "<Esc>")
-- vim.keymap.set("i", "kj", "<Esc>")

vim.keymap.set("n", "<leader>nh", ":nohlsearch<CR>", { desc = "No Highlight", silent = true })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
vim.keymap.set("n", "G", "Gzz", { desc = "Scroll to the bottom and center" })
vim.keymap.set("n", "gg", "ggzz", { desc = "Scroll to the top and center" })

vim.keymap.set("n", "<CR>", "myo<Esc>'y", { desc = "Insert line below and return" })
-- vim.keymap.set("n", "<S-CR>", "myO<Esc>'y", { desc = "Insert line above and return" })

vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without replacing the default register after cursor" })
vim.keymap.set("x", "<leader>P", '"_dp', { desc = "Paste without replacing the default register before cursor" })

vim.keymap.set("v", "<leader>s", '"gy:%s/\\V<C-r>g//g<Left><Left>', {
	desc = "Substitute selected text in the current buffer",
	noremap = true,
})
vim.keymap.set("v", "<leader>cs", '"gy:%s/\\V<C-r>g//gc<Left><Left><Left>', {
	desc = "Substitute selected text in the current buffer (case sensitive)",
	noremap = true,
})

vim.keymap.set("n", "fF", "F", { desc = "Find previous character in the line" })

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

vim.keymap.set("n", "<C-.>", "<Nop>", { noremap = true, silent = true, desc = "Disable . command for Ctrl+." })
vim.keymap.set("i", "<C-.>", function()
	if require("cmp").visible() then
		require("cmp").select_next_item({ behavior = require("cmp").SelectBehavior.Select })
	else
		require("cmp").complete()
	end
	return ""
end, { expr = true, noremap = true, desc = "Trigger completion" })

vim.opt.wrap = false
vim.keymap.set("n", "<leader>ww", function()
	if vim.opt.wrap:get() then
		vim.opt.wrap = false
		vim.notify("Wrap disabled", vim.log.levels.INFO)
	else
		vim.opt.wrap = true
		vim.notify("Wrap enabled", vim.log.levels.INFO)
	end
end, { desc = "Toggle wrap" })

vim.keymap.set("n", "<C-{>", "<cmd>b#<CR>", { desc = "Go to previous buffer" })
vim.keymap.set("n", "<C-}>", "<cmd>bn<CR>", { desc = "Go to next buffer" })

-- Double quotes when select text in visual mode
-- Wrap visual selection in single quotes
vim.keymap.set("v", "'", [[<Esc>`<i'<Esc>`>la'<Esc>]], { desc = "Wrap selection in single quotes" })

-- Wrap visual selection in double quotes
vim.keymap.set("v", '"', [[<Esc>`<i"<Esc>`>la"<Esc>]], { desc = "Wrap selection in double quotes" })

-- Unmap q: in normal mode to prevent accidental usage
vim.keymap.set("n", "q:", "<Nop>", { noremap = true, silent = true, desc = "Disable q: command" })

-- vim.keymap.set("n", "]b", ":bnext<CR>")
-- vim.keymap.set("n", "[b", ":bprevious<CR>")
