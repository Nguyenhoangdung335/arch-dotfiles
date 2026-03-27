return {
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			{
				"windwp/nvim-ts-autotag",
				opts = {
					opts = {
						enable_close = true,
						enable_rename = true,
						enable_close_on_slash = false,
					},
				},
			},
		},
		config = function()
			local npairs = require("nvim-autopairs")
			local Rule = require("nvim-autopairs.rule")
			local cond = require("nvim-autopairs.conds")

			npairs.setup({
				disable_filetype = { "text" },
				ignored_next_char = "[%w%(%[%{%<]",
				map_cr = true,
				map_c_w = false, -- False due to conflict with telescope picker prompt
				check_ts = true,
				ts_config = {
					lua = { "string" },
					javascript = { "string", "template_string" }, -- Don't pair inside JS strings
				},
				fast_wrap = {
					map = false, -- Disable default <M-e> to allow custom pre-hook
					chars = { "{", "[", "(", '"', "'", "`", "<" },
					pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
					offset = 0,
					end_key = "$",
					keys = "qwertyuiopzxcvbnmasdfghjkl",
					check_comma = true,
					highlight = "PmenuSel",
					highlight_grey = "LineNr",
				},
			})

			-- Add rule for html tag to auto indent on Enter and auto space on space in between tags
			npairs.add_rules({
				Rule(" ", " ", { "html", "xml", "javascript", "javascriptreact", "typescript", "typescriptreact" })
					:with_pair(function(opts)
						local pair = opts.line:sub(opts.col - 1, opts.col)
						return vim.tbl_contains({ "()", "[]", "{}", "><" }, pair)
					end)
					:with_move(cond.none())
					:with_cr(cond.none())
					:with_del(function(opts)
						local col = vim.api.nvim_win_get_cursor(0)[2]
						local context = opts.line:sub(col - 1, col + 2)
						return vim.tbl_contains({ "(  )", "[  ]", "{  }", ">  <" }, context)
					end),
				Rule(">", "<"):with_pair(cond.none()):with_move(cond.none()):with_cr(function(opts)
					local pair = opts.line:sub(opts.col - 1, opts.col)
					if pair == "><" then
						return true
					end
				end),
			})

			-- Add code block rule "```" for markdown file
			npairs.add_rules({
				Rule("```", "```", { "markdown", "rmd", "md" }):with_move(cond.none()):with_cr(cond.after_regex("```")), -- Only expand if '```' is after the cursor
			})

			-- Generic <> pair (exclude markup/tag filetypes)
			npairs.add_rules({
				Rule("<", ">")
					:with_pair(cond.not_filetypes({
						"html",
						"xml",
						"markdown",
					}))
					:with_pair(cond.before_regex("[%a_:]"))
					:with_pair(cond.not_after_regex("[%w%(%[%{%<]"))
					:with_move(function(opts)
						return opts.char == ">" and opts.next_char == ">"
					end),
			})
		end,
		keys = {
			{
				"<M-e>",
				mode = "i",
				function()
					local ok, sk = pcall(require, "sidekick.nes")
					if ok then
						if sk.have() then
							sk.clear()
						end
						sk.disable()
						-- Temporarily disable sidekick nes, and enabled again when the next character is inserted
						vim.api.nvim_create_autocmd("InsertCharPre", {
							buffer = 0,
							once = true,
							callback = function()
								sk.enable()
							end,
						})
					end
					return "<Esc>l<cmd>lua require('nvim-autopairs.fastwrap').show()<CR>"
				end,
				expr = true,
				desc = "Autopairs Fast Wrap",
			},
		},
	},
}
