-- ./lua/dung/autocmd.lua
local global = require("dung.global")
local M = {}

-- Select box for swap files
--[[ vim.api.nvim_create_autocmd("SwapExists", {
	group = vim.api.nvim_create_augroup("SnacksSwapSilent", { clear = true }),
	callback = function()
		local swapname = vim.v.swapname
		local bufnr = vim.api.nvim_get_current_buf()

		-- 1. Silently open as Read-Only to skip the initial ugly prompt
		vim.v.swapchoice = "o"

		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(bufnr) then
				return
			end

			local choices = {
				"Recover (Load lost changes)",
				"Delete (Discard swap file)",
				"Edit Anyway (Ignore swap)",
				"Read-Only (View only)",
			}

			vim.ui.select(choices, {
				prompt = "⚠️ Swap detected: " .. vim.fn.fnamemodify(swapname, ":t"),
			}, function(choice)
				if not choice then
					return
				end

				if choice:find("Recover") then
					-- PREVENT UFO CRASH: Disable UFO for this buffer before recovering
					local ufo_status, ufo = pcall(require, "ufo")
					if ufo_status then
						ufo.detach(bufnr)
					end

					-- SILENT RECOVERY: Capture output to a variable instead of printing to cmdline
					local success, result = pcall(function()
						-- nvim_exec2 with output = true redirects messages to the return value
						return vim.api.nvim_exec2("recover", { output = true }).output
					end)

					-- CLEAR COMMAND LINE: Force a redraw to wipe any residual text or "Press Enter"
					vim.cmd("redraw")
					vim.cmd("echo ''")

					if success then
						-- Send the captured internal message to Fidget
						local msg = (result and result ~= "") and result or "Recovery successful!"
						-- if has_fidget then
						-- 	fidget.notify(msg, vim.log.levels.INFO, { title = "Recovery Result" })
						-- else
						-- 	vim.notify(msg, vim.log.levels.INFO, { title = "Recovery Result" })
						-- end
						global.notify(msg, vim.log.levels.INFO, { title = "Recovery Result" })
					else
						-- if has_fidget then
						-- 	fidget.notify(
						-- 		"Recovery failed: " .. tostring(result),
						-- 		vim.log.levels.ERROR,
						-- 		{ title = "Swap Error" }
						-- 	)
						-- else
						-- 	vim.notify(
						-- 		"Recovery failed: " .. tostring(result),
						-- 		vim.log.levels.ERROR,
						-- 		{ title = "Swap Error" }
						-- 	)
						-- end
						global.notify(
							"Recovery failed: " .. tostring(result),
							vim.log.levels.ERROR,
							{ title = "Swap Error" }
						)
					end

					-- RE-ENABLE UFO
					if ufo_status then
						vim.defer_fn(function()
							ufo.attach(bufnr)
						end, 100)
					end
				elseif choice:find("Delete") then
					vim.fn.delete(swapname)
					vim.cmd("e!")
					-- if has_fidget then
					-- 	fidget.notify("Swap file deleted", vim.log.levels.INFO, { title = "Swap" })
					-- else
					-- 	vim.notify("Swap file deleted", vim.log.levels.INFO, { title = "Swap" })
					-- end
					global.notify("Swap file deleted", vim.log.levels.INFO, { title = "Swap" })
				elseif choice:find("Edit Anyway") then
					vim.cmd("e!")
				end
			end)
		end)
	end,
}) ]]

-- Helper: Find all swap files using absolute paths
function M.get_swap_files(filepath, current_swap)
	if filepath == "" then
		return { current_swap }
	end

	local dir = vim.fn.fnamemodify(filepath, ":p:h") -- Absolute directory
	local name = vim.fn.fnamemodify(filepath, ":t") -- Filename
	local pattern = dir .. "/." .. name .. ".sw*"

	local swaps = vim.fn.glob(pattern, true, true)

	-- Ensure the swap Neovim found is in the list
	if current_swap ~= "" and not vim.tbl_contains(swaps, current_swap) then
		table.insert(swaps, 1, current_swap)
	end

	-- Filter out empty strings
	return vim.tbl_filter(function(s)
		return s ~= ""
	end, swaps)
end

-- NEW: Preview using Snacks.win
function M.snacks_preview_diff(swap_path, original_bufnr)
	local snacks_ok, Snacks = pcall(require, "snacks")
	if not snacks_ok then
		global.notify("Snacks.nvim not found, falling back to basic preview", vim.log.levels.WARN)
		return -- You could fall back to the tab version here if you like
	end

	local original_path = vim.api.nvim_buf_get_name(original_bufnr)

	-- 1. Create scratch buffer for swap content
	local swap_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(swap_buf, "Swap: " .. vim.fn.fnamemodify(swap_path, ":t"))

	-- 2. Recover swap content into the scratch buffer
	vim.api.nvim_buf_call(swap_buf, function()
		vim.cmd("silent recover " .. vim.fn.fnameescape(swap_path))
	end)

	-- 3. Create the Floating Window
	Snacks.win({
		style = "swap_diff", -- Use the style we defined in config
		file = original_path, -- Start by showing the disk version
		on_mount = function(self)
			-- This runs inside the float
			local disk_win = self.win
			-- local disk_buf = self.buf

			-- Create a vertical split for the Swap content
			vim.cmd("leftabove vertical sbuffer " .. swap_buf)
			local swap_win = vim.api.nvim_get_current_win()

			-- Enable Diff Mode for both windows in the float
			vim.api.nvim_win_call(swap_win, function()
				vim.cmd("diffthis")
			end)
			vim.api.nvim_win_call(disk_win, function()
				vim.cmd("diffthis")
			end)

			-- Sync scrolling
			vim.wo[swap_win].scrollbind = true
			vim.wo[disk_win].scrollbind = true

			-- Set focus back to the swap side
			vim.api.nvim_set_current_win(swap_win)
		end,
	})
end

vim.api.nvim_create_autocmd("SwapExists", {
	group = vim.api.nvim_create_augroup("SnacksSwapSilent", { clear = true }),
	callback = function()
		-- 1. CAPTURE EVERYTHING IMMEDIATELY
		-- Variables inside vim.v can change or disappear once the event finishes
		local captured_swap = vim.v.swapname
		local bufnr = vim.api.nvim_get_current_buf()
		local filepath = vim.api.nvim_buf_get_name(bufnr)

		-- 2. SILENCE THE INITIAL PROMPT
		vim.v.swapchoice = "o"

		-- 3. SCHEDULE THE UI
		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(bufnr) then
				return
			end

			local swap_files = require("dung.autocmd").get_swap_files(filepath, captured_swap)

			-- Fail-safe: If glob failed, at least use the captured swap
			if #swap_files == 0 and captured_swap ~= "" then
				table.insert(swap_files, captured_swap)
			end

			if #swap_files == 0 then
				global.notify("Swap detected, but could not locate swap file on disk.", vim.log.levels.WARN)
				return
			end

			vim.ui.select(swap_files, {
				prompt = "⚠️ Swap detected. Choose a file to inspect:",
				kind = "swap_files",
				format_item = function(item)
					local mtime = vim.fn.getftime(item)
					local time_str = mtime > 0 and os.date("%Y-%m-%d %H:%M", mtime) or "Unknown time"
					return string.format("%s (%s)", vim.fn.fnamemodify(item, ":e"), time_str)
				end,
			}, function(selected_swap)
				if not selected_swap then
					return
				end

				-- Second menu for actions
				vim.ui.select({ "Recover", "Preview (Popup)", "Delete", "Cancel" }, {
					prompt = "Action for " .. vim.fn.fnamemodify(selected_swap, ":t") .. ":",
				}, function(action)
					if action == "Recover" then
						local ufo_status, ufo = pcall(require, "ufo")
						if ufo_status then
							ufo.detach(bufnr)
						end

						local success, result = pcall(function()
							return vim.api.nvim_exec2(
								"recover " .. vim.fn.fnameescape(selected_swap),
								{ output = true }
							).output
						end)

						vim.cmd("redraw | echo ''")
						global.notify(success and (result ~= "" and result or "Recovered!") or "Error: " .. result)
						if ufo_status then
							vim.defer_fn(function()
								ufo.attach(bufnr)
							end, 100)
						end
					elseif action == "Preview (Popup)" then
						-- The function we defined in the previous step
						local snacks_ok, _ = pcall(require, "snacks")
						if snacks_ok then
							require("dung.autocmd").snacks_preview_diff(selected_swap, bufnr)
						end
					elseif action == "Delete" then
						vim.fn.delete(selected_swap)
						global.notify("Deleted swap file.")
						vim.cmd("e!")
					end
				end)
			end)
		end)
	end,
})

-- Disable cursorline for large files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "slowfiletype",
	callback = function()
		vim.opt.cursorline = false
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "netrw",
	callback = function()
		-- Unbinding <C-H>
		vim.keymap.set("n", "<C-H>", "<NOP>", { buffer = true })

		vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { buffer = true, silent = true })
		vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { buffer = true, silent = true })
		vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { buffer = true, silent = true })
		vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { buffer = true, silent = true })
	end,
})

return M
