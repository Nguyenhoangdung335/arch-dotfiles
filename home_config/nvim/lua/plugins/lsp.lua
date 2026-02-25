local language_servers = {
	"yamlls",
	"docker_compose_language_service",
	"helm_ls",
	"lua_ls",
	"dockerls",
	"gopls",
	"ts_ls",
	"rust_analyzer",
	"qmlls",
}

return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
			"nvimdev/lspsaga.nvim",
		},
		config = function()
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local capabilities = vim.tbl_deep_extend(
				"force",
				{},
				vim.lsp.protocol.make_client_capabilities(),
				cmp_nvim_lsp.default_capabilities()
			)

			local on_attach = function(_, bufnr)
				-- local saga = require("lspsaga")
				local opts = { noremap = true, silent = true, buffer = bufnr }

				-- LSP Saga Keymaps
				vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<cr>", opts)
				vim.keymap.set("n", "gd", "<cmd>Lspsaga peek_definition<cr>", opts)
				vim.keymap.set("n", "gD", "<cmd>Lspsaga goto_definition<cr>", opts)
				-- vim.keymap.set("n", "GD", "<cmd>b#", opts)
				vim.keymap.set("n", "gr", "<cmd>Lspsaga finder<cr>", opts)
				vim.keymap.set("n", "gi", "<cmd>Lspsaga goto_implementation<cr>", opts)
				vim.keymap.set("n", "<leader>rn", "<cmd>Lspsaga rename<cr>", opts)
				vim.keymap.set({ "n", "v" }, "<leader>ca", "<cmd>Lspsaga code_action<cr>", opts)
				vim.keymap.set("n", "<leader>lC", "<cmd>Lspsaga incoming_calls<cr>", opts)
				vim.keymap.set("n", "<leader>lc", "<cmd>Lspsaga outgoing_calls<cr>", opts)

				-- Diagnostics Keymaps (using saga)
				-- vim.keymap.set("n", "gl", "<cmd>Lspsaga show_line_diagnostics<cr>", opts)
				vim.keymap.set("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<cr>", opts)
				vim.keymap.set("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<cr>", opts)

				-- You can still keep your Trouble keymap for project-wide diagnostics
				vim.keymap.set(
					"n",
					"<leader>xx",
					"<cmd>Trouble diagnostics toggle<cr>",
					{ desc = "Project Diagnostics (Trouble)" }
				)
			end

			local servers = language_servers
			local servers_config = {
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
				rust_analyzer = {
					settings = {
						["rust-analyzer"] = {
							cargo = {
								allFeatures = true,
								loadOutDirsFromCheck = true,
								buildScripts = {
									enable = true,
								},
							},
							checkOnSave = true,
							check = {
								command = "clippy",
								extraArgs = { "--no-deps" },
								features = "all",
							},
							procMacro = {
								enable = true,
								ignored = {
									["async-trait"] = { "async_trait" },
									["napi-derive"] = { "napi" },
									["async-recursion"] = { "async_recursion" },
								},
							},
							inlayHints = {
								bindingModeHints = {
									enable = false,
								},
								chainingHints = {
									enable = true,
								},
								closingBraceHints = {
									enable = true,
									minLines = 25,
								},
								closureReturnTypeHints = {
									enable = "never",
								},
								lifetimeElisionHints = {
									enable = "never",
								},
								parameterHints = {
									enable = true,
								},
								reborrowHints = {
									enable = "never",
								},
								renderColons = true,
								typeHints = {
									enable = true,
									hideClosureInitialization = false,
									hideNamedConstructor = false,
								},
							},
							imports = {
								granularity = {
									group = "module",
								},
								prefix = "self",
							},
						},
					},
				},
				qmlls = {
					cmd = {
						"qmlls",
						"-I",
						"/usr/lib/qt6/qml",
						"-I",
						"/usr/lib/qt/qml",
					},
					root_markers = { ".git", "qmldir", ".qmlls.ini" },
					on_attach = function(client)
						client.server_capabilities.documentFormattingProvider = false
						client.server_capabilities.documentRangeFormattingProvider = false
					end,
				},
			}

			-- Set global defaults for all servers
			vim.lsp.config("*", {
				capabilities = capabilities,
				on_attach = on_attach,
			})

			for _, server in ipairs(servers) do
				local conf = servers_config[server] or {}
				conf.capabilities = capabilities
				conf.on_attach = on_attach
				vim.lsp.config(server, conf)
				vim.lsp.enable(server)
				vim.lsp.set_log_level("ERROR")
			end
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
		opts = {
			ensure_installed = vim.g.is_termux and {} or language_servers,
			automatic_enable = false,
		},
	},
	{
		"nvimdev/lspsaga.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
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
				Text = "󰉿", -- nf-cod-symbol_string
				Method = "󰆧", -- nf-cod-symbol_method
				Function = "󰊕", -- nf-cod-symbol_function
				Constructor = "󰒓", -- nf-cod-symbol_constructor
				Field = "󰜢", -- nf-cod-symbol_field
				Variable = "󰀫", -- nf-cod-symbol_variable
				Class = "󰠱", -- nf-cod-symbol_class
				Interface = "󰜰", -- nf-cod-symbol_interface
				Module = "󰕳", -- nf-cod-symbol_namespace
				Property = "󰜢", -- nf-cod-symbol_property
				Unit = "󰑭", -- nf-cod-symbol_unit
				Value = "󰎠", -- nf-cod-symbol_numeric
				Enum = "󰕘", -- nf-cod-symbol_enum
				Keyword = "󰌋", -- nf-cod-symbol_keyword
				Snippet = "󰘌", -- nf-cod-symbol_snippet
				Color = "󰏘", -- nf-cod-symbol_color
				File = "󰈔", -- nf-cod-symbol_file
				Reference = "󰈇", -- nf-cod-references
				Folder = "󰉋", -- nf-cod-folder
				EnumMember = "󰕘", -- nf-cod-symbol_enum_member
				Constant = "󰏿", -- nf-cod-symbol_constant
				Struct = "󰙅", -- nf-cod-symbol_structure
				Event = "󱐋", -- nf-cod-symbol_event
				Operator = "󰆕", -- nf-cod-symbol_operator
				TypeParameter = "󰊄", -- nf-cod-symbol_type_parameter
				Supermaven = "",
			},
		},
		config = function(_, opts)
			require("lspkind").init(opts)
		end,
	},
}
