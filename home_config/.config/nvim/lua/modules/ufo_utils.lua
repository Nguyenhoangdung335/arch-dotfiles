local M = {}

M.fold_handler = function(virtText, lnum, endLnum, width, truncate)
	local newVirtText = {}
	local suffix = (" 󰁂 %d "):format(endLnum - lnum)
	local sufWidth = vim.fn.strdisplaywidth(suffix)
	local targetWidth = width - sufWidth
	local curWidth = 0

	-- Check if the folded line is a region marker
	local is_region = vim.fn.getline(lnum):match('^%s*[%#%/%-%"%*]+%s*(end)?region')

	for _, chunk in ipairs(virtText) do
		local chunkText = chunk[1]
		local hlGroup = chunk[2]
		if is_region then
			hlGroup = "@region.marker.folded"
		end

		local chunkWidth = vim.fn.strdisplaywidth(chunkText)
		if targetWidth > curWidth + chunkWidth then
			table.insert(newVirtText, { chunkText, hlGroup })
		else
			chunkText = truncate(chunkText, targetWidth - curWidth)
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
	table.insert(newVirtText, { suffix, "UfoFoldedEllipsis" })
	return newVirtText
end

local function region_fold_provider(bufnr, filetype)
	local prefix = vim.bo.commentstring[filetype] or "//"
	local pattern_start = "^%s*" .. vim.pesc(prefix) .. "%s*region"
	local pattern_end = "^%s*" .. vim.pesc(prefix) .. "%s*endregion"

	local line_count = vim.api.nvim_buf_line_count(bufnr)
	if line_count > 5000 then -- Disable manual regions on massive files to save CPU
		return {}
	end
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local folds = {}
	local stack = {}

	for i, line in ipairs(lines) do
		if line:find("region", 1, true) then
			if line:match(pattern_start) then
				table.insert(stack, i)
			elseif line:match(pattern_end) and #stack > 0 then
				local start = table.remove(stack)
				table.insert(folds, { startLine = start - 1, endLine = i - 1 })
			end
		end
	end

	return folds
end

M.provider_selector = function(_, filetype, _)
	return function(bufnr, _, CancellationToken)
		local custom_folds = region_fold_provider(bufnr, filetype)
		local manual_folds = vim.b[bufnr].ufo_manual_folds or {}
		local all_custom = {}
		vim.list_extend(all_custom, custom_folds)
		vim.list_extend(all_custom, manual_folds)

		local ufo = require("ufo")
		return ufo.getFolds(bufnr, "lsp", CancellationToken)
			:catch(function()
				return ufo.getFolds(bufnr, "treesitter", CancellationToken)
			end)
			:catch(function()
				return ufo.getFolds(bufnr, "indent", CancellationToken)
			end)
			:thenCall(function(folds)
				local final_folds = folds or {}
				-- Append our custom and manual folds to whichever provider succeeded
				vim.list_extend(final_folds, all_custom)
				return final_folds
			end)
	end
end

M.setup_globals = function()
	---@diagnostic disable: duplicate-set-field
	_G.ufo_manual_fold = function(type)
		local startLine, endLine
		if type then
			startLine = vim.fn.line("'[") - 1
			endLine = vim.fn.line("']") - 1
		else
			startLine = vim.fn.line("v") - 1
			endLine = vim.fn.line(".") - 1
		end
		if startLine > endLine then
			startLine, endLine = endLine, startLine
		end
		local bufnr = vim.api.nvim_get_current_buf()
		local manual_folds = vim.b[bufnr].ufo_manual_folds or {}
		table.insert(manual_folds, { startLine = startLine, endLine = endLine })
		vim.b[bufnr].ufo_manual_folds = manual_folds

		require("ufo").enableFold(bufnr)
		vim.defer_fn(function()
			---@diagnostic disable-next-line: param-type-mismatch
			pcall(vim.cmd, string.format("%d,%dfoldclose", startLine + 1, endLine + 1))
		end, 50)
	end

	_G.ufo_clear_manual_folds = function()
		local bufnr = vim.api.nvim_get_current_buf()
		vim.b[bufnr].ufo_manual_folds = nil
		require("ufo").enableFold(bufnr)
	end
	---@diagnostic enable: duplicate-set-field

	-- Force highlight region markers overriding standard comment highlighting
	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileType" }, {
		group = vim.api.nvim_create_augroup("UfoRegionMarkerMatch", { clear = true }),
		callback = function()
			-- Clear previous matches to prevent duplicates
			for _, m in ipairs(vim.fn.getmatches()) do
				if m.group == "@region.marker" then
					vim.fn.matchdelete(m.id)
				end
			end
			-- Match common comment syntax + region/endregion
			pcall(vim.fn.matchadd, "@region.marker", '\\v^\\s*(//|#|--|"|/\\*)\\s*(end)?region.*$')
		end,
	})
end

M.visual_manual_fold = function()
	-- Exit visual mode to save '< and '> marks
	local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
	vim.api.nvim_feedkeys(esc, "x", false)

	vim.schedule(function()
		local startLine = vim.fn.line("'<") - 1
		local endLine = vim.fn.line("'>") - 1
		if startLine > endLine then
			startLine, endLine = endLine, startLine
		end
		local bufnr = vim.api.nvim_get_current_buf()
		local manual_folds = vim.b[bufnr].ufo_manual_folds or {}
		table.insert(manual_folds, { startLine = startLine, endLine = endLine })
		vim.b[bufnr].ufo_manual_folds = manual_folds

		require("ufo").enableFold(bufnr)
		vim.defer_fn(function()
			---@diagnostic disable-next-line: param-type-mismatch
			pcall(vim.cmd, string.format("%d,%dfoldclose", startLine + 1, endLine + 1))
		end, 50)
	end)
end

M.get_opts = function()
	return {
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
		provider_selector = M.provider_selector,
		fold_virt_text_handler = M.fold_handler,
	}
end

return M