return {
	{
		"kevinhwang91/nvim-ufo",
		cond = not vim.g.vscode,
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"kevinhwang91/promise-async",
		},
		init = function()
			vim.opt.foldcolumn = "1" -- '0' is not bad
			vim.opt.foldlevel = 99 -- Using ufo provider need a large value, otherwise the fold will not open
			vim.opt.foldlevelstart = 99 -- Using ufo provider need a large value, otherwise the fold will not open
			vim.opt.foldenable = true -- Enable folding by default
			vim.opt.fillchars = {
				fold = " ",
				foldopen = "",
				foldclose = "",
				foldsep = " ",
				diff = "╱",
			}

			require("modules.ufo_utils").setup_globals()
		end,
		opts = function()
			return require("modules.ufo_utils").get_opts()
		end,
		keys = {
			{
				"zR",
				function()
					require("ufo").openAllFolds()
				end,
				desc = "Open all folds",
			},
			{
				"zM",
				function()
					require("ufo").closeAllFolds()
				end,
				desc = "Close all folds",
			},
			{
				"zr",
				function()
					require("ufo").openFoldsExceptKinds()
				end,
				desc = "Fold less",
			},
			{
				"zm",
				function()
					require("ufo").closeFoldsWith()
				end,
				desc = "Fold more",
			},
			{
				"zK",
				function()
					local winid = require("ufo").peekFoldedLinesUnderCursor()
					if not winid then
						vim.lsp.buf.hover()
					end
				end,
				desc = "Peek fold",
			},
			{
				"zf",
				"<cmd>set opfunc=v:lua.ufo_manual_fold<CR>g@",
				mode = "n",
				desc = "Create manual fold (operator)",
			},
			{
				"zf",
				function()
					require("modules.ufo_utils").visual_manual_fold()
				end,
				mode = "v",
				desc = "Create manual fold (visual)",
			},
			{ "zE", "<cmd>lua _G.ufo_clear_manual_folds()<CR>", mode = "n", desc = "Clear manual folds" },
		},
	},
}