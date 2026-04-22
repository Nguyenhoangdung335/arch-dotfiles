return {
	root_markers = { "go.mod", "go.sum", ".git" },
	root_dir = function(bufnr, on_dir)
		if not vim.fn.bufname(bufnr):match("%.txt$") then
			on_dir(vim.fn.getcwd())
		end
	end,
	settings = {
		gopls = {
			analyses = {
				unusedparams = true,
				unusedwrite = true,
				unreachable = true,
				nilness = true,
				shadow = true,
				unused = true,
				redeclared = true,
				structtag = true,
				printf = true,
				bools = true,
				loop = true,
			},
			completeUnimported = true,
			usePlaceholders = true,
			staticcheck = true,
			matcher = "Fuzzy",
			codelenses = {
				generate = true,
				gc_details = true,
				test = true,
				tidy = true,
				upgrade_dep = true,
				vendor = true,
				init_file = true,
				deep_init_file = true,
			},
			diagnosticsDelay = "500ms",
			diagnosticsTrigger = "Edit",
		},
	},
}
