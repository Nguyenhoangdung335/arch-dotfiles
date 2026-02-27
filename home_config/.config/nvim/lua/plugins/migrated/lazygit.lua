return {
	"kdheepak/lazygit.nvim",
	-- cond = not vim.g.vscode and not vim.g.is_termux,
	cond = false,
	lazy = true,
	cmd = {
		"LazyGit",
		"LazyGitConfig",
		"LazyGitCurrentFile",
		"LazyGitFilter",
		"LazyGitFilterCurrentFile",
	},
	-- optional for floating window border decoration
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	-- setting the keybinding for LazyGit with 'keys' is recommended in
	-- order to load the plugin when the command is run for the first time
	keys = {
		{ "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
	},
	config = function()
		-- Prevent lazygit.nvim from overriding the default config with its own behavior
		vim.g.lazygit_use_custom_config_file_path = 0
	end,
}
