local fold_handler = function(virtText, lnum, endLnum, width, truncate)
	local newVirtText = {}
	local suffix = (" 󰁂 %d "):format(endLnum - lnum)
	local sufWidth = vim.fn.strdisplaywidth(suffix)
	local targetWidth = width - sufWidth
	local curWidth = 0
	for _, chunk in ipairs(virtText) do
		local chunkText = chunk[1]
		local chunkWidth = vim.fn.strdisplaywidth(chunkText)
		if targetWidth > curWidth + chunkWidth then
			table.insert(newVirtText, chunk)
		else
			chunkText = truncate(chunkText, targetWidth - curWidth)
			local hlGroup = chunk[2]
			table.insert(newVirtText, { chunkText, hlGroup })
			chunkWidth = vim.fn.strdisplaywidth(chunkText)
			-- str width returned from truncate() may less than 2nd argument, need padding
			if curWidth + chunkWidth < targetWidth then
				suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
			end
			break
		end
		curWidth = curWidth + chunkWidth
	end
	table.insert(newVirtText, { suffix, "MoreMsg" })
	return newVirtText
end

-- Custom fold provider for Go regions with // region and // endregion comments
local comment_prefixes = {
	go = "//",
	c = "//",
	cpp = "//",
	java = "//",
	javascript = "//",
	typescript = "//",
	python = "#",
	lua = "--",
	vim = '"',
	sh = "#",
	bash = "#",
	zsh = "#",
	ruby = "#",
	rust = "//",
	toml = "#",
	yaml = "#",
	json = "//", -- not standard but some comments exist
}
local function region_fold_provider(bufnr, filetype)
	local prefix = comment_prefixes[filetype] or "//"
	local pattern_start = "^%s*" .. vim.pesc(prefix) .. "%s*region"
	local pattern_end = "^%s*" .. vim.pesc(prefix) .. "%s*endregion"

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local folds = {}
	local stack = {}

	for i, line in ipairs(lines) do
		if line:match(pattern_start) then
			table.insert(stack, i)
		elseif line:match(pattern_end) and #stack > 0 then
			local start = table.remove(stack)
			table.insert(folds, { startLine = start - 1, endLine = i - 1 })
		end
	end

	return folds
end

return {
	{
		"kevinhwang91/nvim-ufo",
		cond = not vim.g.vscode,
		dependencies = {
			"kevinhwang91/promise-async",
		},
		config = function()
			vim.opt.foldcolumn = "1" -- '0' is not bad

			vim.optfoldlevel = 99 -- Using ufo provider need a large value, otherwise the fold will not open
			vim.opt.foldlevelstart = 99 -- Using ufo provider need a large value, otherwise the fold will not open
			vim.opt.foldenable = true -- Enable folding by default
			vim.opt.fillchars = {
				fold = " ",
				foldopen = "",
				foldclose = "",
				foldsep = " ",
				diff = "╱",
			}
			local ufo = require("ufo")

			ufo.setup({
				open_fold_hl_timeout = 150,
				close_fold_kinds_for_ft = {
					default = { "imports", "comment" },
					json = { "array" },
					c = { "comment", "region" },
				},
				close_fold_current_line_for_ft = {
					default = true,
					c = false,
				},
				preview = {
					win_config = {
						border = { "", "─", "", "", "", "─", "", "" },
						winhighlight = "Normal:Folded",
						winblend = 0,
					},
					mappings = {
						scrollU = "<C-u>",
						scrollD = "<C-d>",
						jumpTop = "[",
						jumpBot = "]",
					},
				},
				provider_selector = function(_, filetype, _)
					return {
						function(bufnr, _, CancellationToken)
							local custom_folds = region_fold_provider(bufnr, filetype)
							local lsp_promise = require("ufo").getFolds(bufnr, "lsp", CancellationToken)

							-- This promise can be rejected (e.g., no LSP), so we must handle it.
							return lsp_promise
								:thenCall(function(lsp_folds)
									-- SUCCESS CASE: The LSP returned folds (or nil).
									-- Now we merge our custom folds into the LSP folds.
									local all_folds = lsp_folds or {}
									if custom_folds and #custom_folds > 0 then
										for _, fold in ipairs(custom_folds) do
											table.insert(all_folds, fold)
										end
									end
									return all_folds
								end)
								:catch(function()
									-- FAILURE CASE: The LSP promise was rejected.
									-- This happens in buffers like netrw.
									-- In this case, we just return our custom folds.
									return custom_folds
								end)
						end,
					}
				end,
				fold_virt_text_handler = fold_handler,
			})

			-- Highlight the fold column
			-- vim.api.nvim_set_hl(0, "Folded", { fg = "#88C0D0", bg = "#2E3440", bold = true })
			vim.api.nvim_set_hl(0, "FoldColumn", { fg = "#EBCB8B", bg = "#282828" })
			vim.opt.runtimepath:append("~/.config/nvim/lua")
			vim.api.nvim_set_hl(0, "@region.marker", { fg = "#88C0D0", bold = true, italic = true })

			vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
			vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })
			vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds)
			vim.keymap.set("n", "zm", require("ufo").closeFoldsWith)
			vim.keymap.set("n", "zK", function()
				local winid = require("ufo").peekFoldedLinesUnderCursor()
				if not winid then
					-- choose one of coc.nvim and nvim lsp
					-- vim.fn.CocActionAsync("definitionHover") -- coc.nvim
					vim.lsp.buf.hover()
				end
			end)
		end,
	},
}
