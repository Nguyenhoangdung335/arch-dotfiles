return {
	"christoomey/vim-tmux-navigator",
	event = "VeryLazy",
	cond = not vim.g.vscode,
	config = function()
		vim.g.tmux_navigator_no_mappings = 1
		vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { silent = true })
		vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { silent = true })
		vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { silent = true })
		vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { silent = true })
	end,
}
