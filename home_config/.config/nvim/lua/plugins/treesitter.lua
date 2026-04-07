local cache_file = vim.fn.stdpath("data") .. "/ts_unsupported"
local function load_cache()
	local set = {}
	local ok, lines = pcall(vim.fn.readfile, cache_file)
	if ok then
		for _, line in ipairs(lines) do
			if line ~= "" then
				set[line] = true
			end
		end
	end
	return set
end

local function save_cache(set)
	local lines = {}
	for ft, _ in pairs(set) do
		table.insert(lines, ft)
	end
	table.sort(lines)
	vim.fn.writefile(lines, cache_file)
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		event = { "BufReadPre", "BufNewFile" },
		build = ":TSUpdate",
		init = function()
			-- Ensure installed after loading treesitter
			local ensure_installed = {
				"c",
				"lua",
				"vim",
				"vimdoc",
				"query",
				"markdown",
				"markdown_inline",
				"go",
				"yaml",
				"json",
				"helm",
				"typescript",
				"git_rebase",
				"bash",
			}
			local alreadyInstalled = require("nvim-treesitter.config").get_installed()
			local parsersToInstall = vim.iter(ensure_installed)
				:filter(function(parser)
					return not vim.tbl_contains(alreadyInstalled, parser)
				end)
				:totable()
			require("nvim-treesitter").install(parsersToInstall)

			-- Installed parsers that are not part of the ensure_installed list, skipping filetypes that are not supported (cached)
			-- Start treesitter safely and configure indentexpr
			local unsupported = load_cache()
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local buf = args.buf
					local ft = vim.bo[buf].filetype

					-- Skip cached unsupported
					if unsupported[ft] then
						return
					end

					local lang = vim.treesitter.language.get_lang(ft)
					if not lang then
						unsupported[ft] = true
						save_cache(unsupported)
						return
					end

					local has_parser = #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) > 0

					if not has_parser then
						local ok = pcall(require("nvim-treesitter").install, { lang })

						if not ok then
							unsupported[ft] = true
							save_cache(unsupported)
							return
						end
					end

					local ok = pcall(vim.treesitter.start, buf, lang)
					if not ok then
						unsupported[ft] = true
						save_cache(unsupported)
						return
					end

					vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		after = "nvim-treesitter",
		opts = {
			enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
			multiwindow = false, -- Enable multiwindow support.
			max_lines = 10, -- How many lines the window should span. Values <= 0 mean no limit.
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
		},
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		config = function()
			require("nvim-treesitter-textobjects").setup({
				include_surrounding_whitespace = false,
				select = {
					enable = true,
					lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
					selection_modes = {
						["@parameter.outer"] = "v", -- charwise
						["@function.outer"] = "V", -- linewise
						["@class.outer"] = "<c-v>", -- blockwise
					},
				},
				move = { set_jumps = true },
			})
			-- region: keymaps to select certain text objects (function, class)

			local to_select = require("nvim-treesitter-textobjects.select")
			vim.keymap.set({ "x", "o" }, "af", function()
				to_select.select_textobject("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "if", function()
				to_select.select_textobject("@function.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ac", function()
				to_select.select_textobject("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ic", function()
				to_select.select_textobject("@class.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "as", function()
				to_select.select_textobject("@statement.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "al", function()
				to_select.select_textobject("@loop.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "il", function()
				to_select.select_textobject("@loop.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "aa", function()
				to_select.select_textobject("@parameter.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ia", function()
				to_select.select_textobject("@parameter.inner", "textobjects")
			end)

			-- endregion

			-- region: keymaps to move to a certain text objects (function, class)
			local move = require("nvim-treesitter-textobjects.move")

			-- region: keymaps to move to functions positions
			vim.keymap.set({ "n", "x", "o" }, "]f", function()
				move.goto_next_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]F", function()
				move.goto_next_end("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[f", function()
				move.goto_previous_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[F", function()
				move.goto_previous_end("@function.outer", "textobjects")
			end)
			-- endregion

			-- region: keymaps to move to class positions
			vim.keymap.set({ "n", "x", "o" }, "]c", function()
				move.goto_next_start("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]C", function()
				move.goto_next_end("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[c", function()
				move.goto_previous_start("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[C", function()
				move.goto_previous_end("@class.outer", "textobjects")
			end)
			-- endregion

			-- endregion
		end,
	},
}
