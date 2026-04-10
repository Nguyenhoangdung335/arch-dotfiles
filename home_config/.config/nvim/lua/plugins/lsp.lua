local function read_ini_value(root_dir, key)
	local ini = vim.fs.joinpath(root_dir, ".qmlls.ini")
	if vim.fn.filereadable(ini) ~= 1 then
		return nil
	end

	for _, line in ipairs(vim.fn.readfile(ini)) do
		local value = line:match("^%s*" .. key .. "%s*=%s*(.-)%s*$")
		if value then
			value = value:gsub('^"(.*)"$', "%1")
			value = value:gsub("^'(.*)'$", "%1")
			return value
		end
	end

	return nil
end

return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
			"nvimdev/lspsaga.nvim",
		},
		event = "VeryLazy",
		opts = {
			servers = {
				yamlls = {
					settings = {
						yaml = {
							schemaStore = {
								enable = false,
								url = "https://www.schemastore.org/api/json/catalog.json",
							},
							schemas = {
								["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/v1.32.1-standalone-strict/all.json"] = "/*.k8s.yaml",
								["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose.yml",
								["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
								["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
								["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/**/*.{yml,yaml}",
								["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
								["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
								["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
								["http://json.schemastore.org/circleciconfig"] = ".circleci/**/*.{yml,yaml}",
							},
							validate = true,
							hover = true,
							completion = true,
							format = { enabled = true },
						},
					},
				},
				docker_compose_language_service = {},
				helm_ls = {},
				lua_ls = {
					settings = {
						Lua = {
							runtime = {
								version = "LuaJIT",
							},
							diagnostics = {
								globals = { "vim" },
							},
							workspace = {
								library = vim.api.nvim_get_runtime_file("", true),
								checkThirdParty = false,
							},
							telemetry = {
								enable = false,
							},
						},
					},
				},
				dockerls = {},
				gopls = {
					root_markers = { ".git", "go.mod", "go.sum" },
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
				},
				ts_ls = {},
				rust_analyzer = {
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
				},
				qmlls = {
					cmd = {
						"qmlls6",
						"--no-cmake-calls",
						"-I",
						"/usr/lib/qt6/qml",
						"-I",
						"/run/user/1000/quickshell/vfs/5be5eb4850299160e8c13ad899c0b79c",
						"-b",
						"/run/user/1000/quickshell/vfs/5be5eb4850299160e8c13ad899c0b79c",
					},
					root_markers = { ".qmlls.ini", "qmldir", ".git" },
					on_attach = function(client)
						client.server_capabilities.documentFormattingProvider = false
						client.server_capabilities.documentRangeFormattingProvider = false
					end,
					filetypes = { "qml", "qmljs" },
				},
				cssls = {
					filetypes = { "css", "scss", "less", "markdown" },
				},
				tailwindcss = {
					filetypes = {
						"aspnetcorerazor",
						"astro",
						"astro-markdown",
						"blade",
						"clojure",
						"django-html",
						"htmldjango",
						"edge",
						"eelixir",
						"elixir",
						"ejs",
						"erb",
						"eruby",
						"gohtml",
						"gohtmltmpl",
						"haml",
						"handlebars",
						"hbs",
						"html",
						"html-eex",
						"heex",
						"jade",
						"leaf",
						"liquid",
						"markdown",
						"mdx",
						"mustache",
						"njk",
						"nunjucks",
						"php",
						"razor",
						"slim",
						"twig",
						"css",
						"less",
						"postcss",
						"sass",
						"scss",
						"stylus",
						"sugarss",
						"templ",
						"javascript",
						"javascriptreact",
						"reason",
						"rescript",
						"typescript",
						"typescriptreact",
						"vue",
						"svelte",
					},
					root_dir = function(fname)
						return require("lspconfig.util").root_pattern(
							"tailwind.config.js",
							"tailwind.config.cjs",
							"tailwind.config.mjs",
							"tailwind.config.ts",
							"postcss.config.js",
							"postcss.config.cjs",
							"postcss.config.mjs",
							"postcss.config.ts",
							"package.json",
							"node_modules",
							".git"
						)(fname) or vim.fn.getcwd()
					end,
				},
				-- copilot = {},
				terraformls = {
					cmd = { "terraform-ls", "serve" },
					filetypes = {
						"terraform",
						"terraform-vars",
						"terraform-stack",
						"terraform-deploy",
						"terraform-search",
						"hcl",
					},
					root_markers = { ".terraform", ".git" },
				},
			},
		},
		config = function(_, opts)
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local capabilities = vim.tbl_deep_extend(
				"force",
				{},
				vim.lsp.protocol.make_client_capabilities(),
				cmp_nvim_lsp.default_capabilities()
			)

			local on_attach = function(_, bufnr)
				local buf_opts = { noremap = true, silent = true, buffer = bufnr }

				-- LSP Saga Keymaps
				-- vim.keymap.set("n", "K", vim.lsp.buf.hover, buf_opts)
				vim.keymap.set("n", "K", function()
					for _, win in ipairs(vim.api.nvim_list_wins()) do
						local config = vim.api.nvim_win_get_config(win)

						if config.relative ~= "" then
							local buf = vim.api.nvim_win_get_buf(win)
							local ft = vim.bo[buf].filetype

							if ft == "lspsaga_hover" then
								vim.api.nvim_set_current_win(win)
								return
							end
						end
					end

					vim.cmd("Lspsaga hover_doc")
				end, buf_opts)
				vim.keymap.set("n", "gd", "<cmd>Lspsaga peek_definition<cr>", buf_opts)
				vim.keymap.set("n", "gD", "<cmd>Lspsaga goto_definition<cr>", buf_opts)
				vim.keymap.set("n", "gr", "<cmd>Lspsaga finder<cr>", buf_opts)
				vim.keymap.set("n", "gi", "<cmd>Lspsaga goto_implementation<cr>", buf_opts)
				vim.keymap.set("n", "<leader>rn", "<cmd>Lspsaga rename<cr>", buf_opts)
				vim.keymap.set({ "n", "v" }, "<leader>ca", "<cmd>Lspsaga code_action<cr>", buf_opts)
				vim.keymap.set("n", "<leader>lC", "<cmd>Lspsaga incoming_calls<cr>", buf_opts)
				vim.keymap.set("n", "<leader>lc", "<cmd>Lspsaga outgoing_calls<cr>", buf_opts)

				-- Diagnostics Keymaps (using saga)
				vim.keymap.set("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<cr>", buf_opts)
				vim.keymap.set("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<cr>", buf_opts)

				-- Project Diagnostics (Trouble)
				vim.keymap.set(
					"n",
					"<leader>xx",
					"<cmd>Trouble diagnostics toggle<cr>",
					{ desc = "Project Diagnostics (Trouble)" }
				)
			end

			-- Configure mason-lspconfig
			require("mason-lspconfig").setup({
				ensure_installed = vim.g.is_termux and {} or vim.tbl_keys(opts.servers),
				automatic_enable = false,
			})

			-- Set global defaults for all servers
			vim.lsp.config("*", {
				capabilities = capabilities,
				on_attach = on_attach,
			})

			for server, conf in pairs(opts.servers) do
				conf.capabilities = capabilities
				-- We merge the default on_attach with any server-specific on_attach
				local server_on_attach = conf.on_attach
				conf.on_attach = function(client, bufnr)
					on_attach(client, bufnr)
					if server_on_attach then
						server_on_attach(client, bufnr)
					end
				end

				vim.lsp.config(server, conf)
				vim.lsp.enable(server)
			end

			vim.lsp.log.set_level("ERROR")
		end,
	},
	{
		"mason-org/mason.nvim",
		opts = {
			ui = {
				border = "rounded",
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = { "mason-org/mason.nvim" },
		-- configuration is done in nvim-lspconfig
	},
	{
		"nvimdev/lspsaga.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		event = "VeryLazy",
		opts = {
			ui = {
				border = "rounded",
				devicon = true,
				title = true,
				code_action = "",
			},
			lightbulb = {
				enable = false,
				sign = true,
				virtual_text = true,
				debounce = 10,
				sign_priority = 20,
			},
			hover = {
				max_width = 0.9,
				max_height = 0.9,
				open_link = "gx",
				open_cmd = "!zen-browser",
			},
			code_action = {
				num_shortcut = true,
				show_server_name = true,
				extend_gitsigns = true,
			},
		},
	},
	{
		"onsails/lspkind.nvim",
		opts = {
			mode = "symbol_text",
			preset = "codicons", -- use Codicons instead of old MDI glyphs
			symbol_map = {
				Text = "󰉿",
				Method = "󰆧",
				Function = "󰊕",
				Constructor = "󰒓",
				Field = "󰜢",
				Variable = "󰀫",
				Class = "󰠱",
				Interface = "󰜰",
				Module = "󰕳",
				Property = "󰜢",
				Unit = "󰑭",
				Value = "󰎠",
				Enum = "󰕘",
				Keyword = "󰌋",
				Snippet = "󰘌",
				Color = "󰏘",
				File = "󰈔",
				Reference = "󰈇",
				Folder = "󰉋",
				EnumMember = "󰕘",
				Constant = "󰏿",
				Struct = "󰙅",
				Event = "󱐋",
				Operator = "󰆕",
				TypeParameter = "󰊄",
				Copilot = "",
				Supermaven = "",
			},
		},
		config = function(_, opts)
			require("lspkind").init(opts)
		end,
	},
}
