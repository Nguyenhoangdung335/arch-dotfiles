return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		cond = true,
		opts = {
			anti_conceal = { enabled = false },
			-- file_types = { "opencode_output", "codecompanion" },
		},
		ft = { "markdown", "Avante", "copilot-chat", "opencode_output", "codecompanion" },
	},
	{
		"OXY2DEV/markview.nvim",
		ft = "markdown",
		cond = not vim.g.vscode and false,
		opts = {
			preview = {
				filetypes = { "markdown" },
				ignore_buftypes = {},
			},
		},
	},
}
