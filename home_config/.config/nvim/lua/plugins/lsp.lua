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
				yamlls = {},
				docker_compose_language_service = {},
				helm_ls = {},
				lua_ls = {},
				dockerls = {},
				gopls = {},
				ts_ls = {},
				rust_analyzer = {},
				qmlls = {},
				cssls = {},
				tailwindcss = {},
				-- copilot = {},
				terraformls = {},
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
	},
	-- region: lspsaga
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
	--  endregion
	-- region: lspkind
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
	-- endregion
}
