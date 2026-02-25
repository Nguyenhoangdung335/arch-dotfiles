return {
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"OXY2DEV/markview.nvim",
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		-- lazy = false,
		-- priority = 1000,
		event = { "BufReadPre", "BufNewFile" },
		build = ":TSUpdate",
		opts = {
			-- A list of parser names, or "all" (the listed parsers MUST always be installed)
			ensure_installed = {
				"c",
				"lua",
				"vim",
				"vimdoc",
				"query",
				-- "markdown",
				-- "markdown_inline",
				"go",
				"yaml",
				"json",
				"helm",
				"typescript",
				"git_rebase",
				"bash",
			},
			sync_install = false,
			auto_install = true,
			highlight = {
				enable = true,
				disable = function(_, buf)
					local max_filesize = 500 * 1024 -- 500 KB
					local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
					if ok and stats and stats.size > max_filesize then
						vim.notify(
							"File larger than 500KB has treesitter disabled by default for performance",
							vim.log.level.WARN,
							{ title = "Treesitter" }
						)
						return true
					end
				end,
				-- additional_vim_regex_highlighting = { "markdown" },
				additional_vim_regex_highlighting = {},
			},
			textobjects = {
				select = {
					enable = true,
					lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
					keymaps = {
						-- You can use the capture groups defined in textobjects.scm
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
						["ic"] = "@class.inner",
						["al"] = "@loop.outer",
						["il"] = "@loop.inner",
						["aa"] = "@parameter.outer",
						["ia"] = "@parameter.inner",
						["as"] = "@statement.outer",
					},
				},
				move = {
					enable = true,
					set_jumps = true, -- whether to set jumps in the jumplist
					goto_next_start = {
						["]f"] = "@function.outer",
						["]c"] = "@class.outer",
					},
					-- goto_next_end = {
					--     ["]M"] = "@function.outer",
					--     ["]["] = "@class.outer",
					-- },
					goto_previous_start = {
						["[f"] = "@function.outer",
						["[c"] = "@class.outer",
					},
					-- goto_previous_end = {
					--     ["[M"] = "@function.outer",
					--     ["[]"] = "@class.outer",
					-- },
				},
			},
			indent = {
				enable = true,
			},
		},
		config = function(_, opts)
			require("nvim-treesitter").setup(opts)
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		after = "nvim-treesitter",
		config = function()
			require("treesitter-context").setup({
				enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
				multiwindow = false, -- Enable multiwindow support.
				max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
				min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
				line_numbers = true,
				multiline_threshold = 20, -- Maximum number of lines to show for a single context
				trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
				mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
				-- Separator between context and content. Should be a single character string, like '-'.
				-- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
				separator = nil,
				zindex = 20, -- The Z-index of the context window
				on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
			})
		end,
	},
}
