return {
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-nvim-lsp-document-symbol",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"zbirenbaum/copilot-cmp",
			"supermaven-inc/supermaven-nvim",
			-- Optional: Add for Neovim Lua API completions if desired
			-- "hrsh7th/cmp-nvim-lua",
		},
		config = function()
			vim.api.nvim_set_hl(0, "CmpGhostText", { fg = "#808080" })
			-- Add highlights for AI sources (from copilot-cmp and supermaven docs)
			vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })
			vim.api.nvim_set_hl(0, "CmpItemKindSupermaven", { fg = "#6CC644" })

			local cmp = require("cmp")
			require("luasnip.loaders.from_vscode").lazy_load()
			require("luasnip.loaders.from_vscode").lazy_load({
				paths = {
					vim.fn.stdpath("config") .. "/snippets/vscode-kubernetes-tools/snippets",
				},
			})
			local luasnip = require("luasnip")
			local lspkind = require("lspkind")

			-- Helper for Tab mappings (checks for words before cursor)
			local has_words_before = function()
				unpack = unpack or table.unpack
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(1, col):match("%s") == nil
			end

			local cmp_select = { behavior = cmp.SelectBehavior.Select }
			cmp.setup({
				experimental = {
					ghost_text = true,
					native_menu = false,
				},
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered({
						border = "rounded",
						winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
					}),
					documentation = cmp.config.window.bordered({
						border = "rounded",
						winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
					}),
				},
				mapping = cmp.mapping.preset.insert({
					["<C-d>"] = cmp.mapping.scroll_docs(-4),
					["<C-u>"] = cmp.mapping.scroll_docs(4),
					["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
					["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
					-- Add standard trigger for completion
					["<C-Space>"] = cmp.mapping.complete(),
					-- -- Alternative for Ctrl + .
					-- ["<CSI>46;5u"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<C-CR>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.confirm({ select = true })
						else
							fallback() -- fall back to normal behavior (insert newline)
						end
					end, { "i", "s" }),
					-- Add Super-Tab like mapping for next item or snippet jump
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() and has_words_before() then
							cmp.select_next_item(cmp_select)
						elseif luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					-- Add for previous item or snippet jump back
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item(cmp_select)
						elseif luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp", priority = 1000 },
					{ name = "luasnip", priority = 750 },
					{ name = "copilot", priority = 700 },
					{ name = "supermaven", priority = 700 },
					{ name = "buffer", priority = 500 },
					{ name = "path", priority = 400 },
					-- Optional: For Lua files
					-- { name = "nvim_lua", priority = 800 },
				}),
				sorting = {
					priority_weight = 2,
					comparators = {
						-- Add copilot prioritize comparator
						require("copilot_cmp.comparators").prioritize,
						-- Fixed custom comparator using .option.priority
						function(entry1, entry2)
							local priority1 = entry1.source.priority or 0
							local priority2 = entry2.source.priority or 0
							if priority1 == priority2 then
								return nil
							end
							return priority1 > priority2
						end,
						cmp.config.compare.offset,
						cmp.config.compare.exact,
						cmp.config.compare.score,
						-- cmp.config.compare.recently_used,
						cmp.config.compare.source,
						cmp.config.compare.locality,
						cmp.config.compare.kind,
						cmp.config.compare.sort_text,
						cmp.config.compare.length,
						cmp.config.compare.order,
					},
				},
				completion = {
					completeopt = "menu,menuone,noinsert",
					-- keyword_pattern = [[\%(\S\+\)]],
				},
				formatting = {
					format = lspkind.cmp_format({
						mode = "symbol_text",
						maxwidth = 50,
						ellipsis_char = "...",
						show_labelDetails = true,
						symbol_map = {
							-- Add symbols for AI sources
							Copilot = "",
							Supermaven = "",
						},
						before = function(entry, vim_item)
							-- Add the source name to the completion menu
							vim_item.menu = "[" .. entry.source.name .. "]"
							return vim_item
						end,
					}),
				},
			})

			-- Use buffer sources for '/' and '?' commands
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
					{ name = "path" },
				},
			})

			-- Use cmdline & path source for ':' commands
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),
				matching = { disallow_symbol_nonprefix_matching = false },
			})
		end,
	},
}
