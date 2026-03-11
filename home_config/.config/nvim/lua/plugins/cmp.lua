local function apply_cmp_highlights()
	local cat_ok, cat_palettes = pcall(require, "catppuccin.palettes")
	if cat_ok then
		local flavor = require("catppuccin").flavour or "mocha"
		local colors = cat_palettes.get_palette(flavor)
		if colors then
			vim.api.nvim_set_hl(0, "CmpGhostText", { fg = colors.surface1, bold = true })
			vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = colors.mauve, bold = true })
			vim.api.nvim_set_hl(0, "CmpItemKindSupermaven", { fg = colors.peach, italic = true })
		end
	else
		vim.api.nvim_set_hl(0, "CmpGhostText", { fg = "#808080" })
		vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })
		vim.api.nvim_set_hl(0, "CmpItemKindSupermaven", { fg = "#6CC644" })
	end
end

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
		},
		opts = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			-- Helper for Tab mappings (checks for words before cursor)
			local has_words_before = function()
				unpack = unpack or table.unpack
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(1, col):match("%s") == nil
			end

			local cmp_select = { behavior = cmp.SelectBehavior.Select }

			return {
				experimental = {
					ghost_text = true,
					native_menu = false,
				},
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				view = {
					entries = { name = "custom", selection_order = "top_down" },
				},
				window = {
					completion = cmp.config.window.bordered({
						border = "rounded",
						winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
						col_offset = -3,
						side_padding = 0,
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
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<C-CR>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.confirm({ select = true })
						else
							fallback()
						end
					end, { "i", "s" }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() and has_words_before() then
							cmp.select_next_item(cmp_select)
						elseif luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
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
				}),
				sorting = {
					priority_weight = 2,
					comparators = {
						require("copilot_cmp.comparators").prioritize,
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
				},
				formatting = {
					format = function(entry, item)
						local source_names = {
							nvim_lsp = "[LSP]",
							luasnip = "[LuaSnip]",
							copilot = "[Copilot]",
							supermaven = "[Supermaven]",
							buffer = "[Buffer]",
							path = "[Path]",
							cmdline = "[Cmd]",
						}

						local original_kind = item.kind or ""
						local label = entry:get_completion_item().label or ""

						-- 1. Use "symbol_text" to ensure BOTH the icon and the text (e.g. "Struct") appear!
						item = require("lspkind").cmp_format({
							mode = "symbol_text",
							maxwidth = 50,
							show_labelDetails = true, -- Fetch the crate path from rust-analyzer
						})(entry, item)

						-- Add nice padding to the left column
						if item.kind then
							item.kind = item.kind .. " "
						end

						-- 2. Extract and smartly format the Rust Path
						local raw_menu = item.menu or ""
						local clean_path = ""

						-- Extract the inside text from "(use tokio::io::WriteHalf)"
						local use_match = raw_menu:match("%(use (.-)%)")
						if use_match then
							clean_path = use_match

							-- SMART SUBTRACTION: Remove the struct name from the end of the module path
							-- Find the last segment of the path (e.g. "WriteHalf" from "tokio::io::WriteHalf")
							local last_segment = clean_path:match("::([^:]+)$")

							-- If the completion label (e.g. "WriteHalf<...>") starts with that segment,
							-- we dynamically slice it off the end of the path!
							if last_segment and vim.startswith(label, last_segment) then
								-- Subtract the length of the segment and the "::"
								clean_path = string.sub(clean_path, 1, #clean_path - #last_segment - 2)
							end
						end

						-- 3. Construct the right-side menu column
						local source = source_names[entry.source.name] or ("[" .. entry.source.name .. "]")

						-- No more duplicate "Struct". ONLY show the source and the subtracted path!
						if clean_path ~= "" then
							item.menu = " " .. source .. " " .. clean_path
						else
							item.menu = " " .. source
						end

						-- 4. Support for nvim-highlight-colors (Tailwind/CSS rendering)
						local color_item = require("nvim-highlight-colors").format(entry, { kind = original_kind })
						if color_item and color_item.abbr_hl_group then
							item.kind_hl_group = color_item.abbr_hl_group
							item.kind = "Color " .. color_item.abbr .. " "
						end

						return item
					end,
				},
			}
		end,
		config = function(_, opts)
			apply_cmp_highlights()

			local cmp = require("cmp")
			require("luasnip.loaders.from_vscode").lazy_load()
			require("luasnip.loaders.from_vscode").lazy_load({
				paths = {
					vim.fn.stdpath("config") .. "/snippets/vscode-kubernetes-tools/snippets",
				},
			})

			cmp.setup(opts)

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
