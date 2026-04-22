return {
	root_markers = { "Cargo.toml", "Cargo.lock", ".git" },
	root_dir = function(bufnr, on_dir)
		if not vim.fn.bufname(bufnr):match("%.txt$") then
			on_dir(vim.fn.getcwd())
		end
	end,
	settings = {
		["rust-analyzer"] = {
			cargo = {
				allFeatures = true,
				loadOutDirsFromCheck = true,
				buildScripts = { enable = true },
			},
			completion = { fullFunctionSignature = true },
			hover = {
				show = { traitAssocItems = 10 },
				documentation = { enable = true },
				links = { enable = true },
			},
			checkOnSave = true,
			check = {
				command = "clippy",
				extraArgs = { "--no-deps" },
				features = "all",
			},
			inlayHints = {
				bindingModeHints = { enable = false },
				chainingHints = { enable = true },
				closingBraceHints = { enable = true, minLines = 25 },
				closureReturnTypeHints = { enable = "never" },
				lifetimeElisionHints = { enable = "never" },
				parameterHints = { enable = true },
				reborrowHints = { enable = "never" },
				renderColons = true,
				typeHints = {
					enable = true,
					hideClosureInitialization = false,
					hideNamedConstructor = false,
				},
			},
			imports = {
				granularity = { group = "module" },
				prefix = "self",
			},
		},
	},
}
