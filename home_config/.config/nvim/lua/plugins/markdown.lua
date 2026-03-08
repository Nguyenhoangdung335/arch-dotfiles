return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		cond = true,
		opts = {
			anti_conceal = { enabled = false },
			-- file_types = { "opencode_output", "codecompanion" },
		},
		ft = { "Avante", "copilot-chat", "opencode_output", "codecompanion" },
	},
	{
		"OXY2DEV/markview.nvim",
		ft = "markdown",
		cond = not vim.g.vscode,
		opts = {
			preview = {
				filetypes = { "markdown" },
				ignore_buftypes = {},
			},
		},
	},
}
