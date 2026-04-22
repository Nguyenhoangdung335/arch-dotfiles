return {
	settings = {
		lua = {
			runtime = {
				version = "luajit",
			},
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
				checkthirdparty = false,
			},
			telemetry = {
				enable = false,
			},
		},
	},
}
