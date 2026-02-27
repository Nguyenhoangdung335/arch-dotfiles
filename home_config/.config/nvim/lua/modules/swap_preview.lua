-- ./lua/modules/swap_preview.lua
local global = require("configs.global")
local M = {}

-- Safely extract binary swap data in the background
function M.fetch_swap_infos_async(swap_paths, disk_text, callback)
	local results = {}
	local completed = 0

	if #swap_paths == 0 then
		callback(results)
		return
	end

	for _, path in ipairs(swap_paths) do
		local temp_out = vim.fn.tempname()
		local script_path = vim.fn.tempname() .. ".lua"
		local temp_swap = vim.fn.tempname() .. ".swp"

		---@diagnostic disable-next-line: undefined-field
		(vim.uv or vim.loop).fs_copyfile(path, temp_swap)

		local script_code = string.format(
			[[
			vim.opt.shortmess:append("AWc")
			pcall(function()
				vim.cmd("silent! recover " .. vim.fn.fnameescape(%q))
				vim.cmd("silent! write! " .. vim.fn.fnameescape(%q))
			end)
		]],
			temp_swap,
			temp_out
		)

		vim.fn.writefile(vim.split(script_code, "\n"), script_path)

		local cmd = {
			vim.v.progpath,
			"--headless",
			"--clean",
			"-n",
			"--cmd",
			"luafile " .. script_path,
			"-c",
			"qa!",
		}

		local function on_exit()
			vim.schedule(function()
				vim.fn.delete(script_path)
				vim.fn.delete(temp_swap)

				local lines = {}
				if vim.fn.filereadable(temp_out) == 1 then
					lines = vim.fn.readfile(temp_out)
					vim.fn.delete(temp_out)
				end

				local added, deleted = 0, 0
				local diff_str = "No changes"

				if #lines > 0 then
					local swap_text = table.concat(lines, "\n") .. "\n"
					if swap_text ~= disk_text then
						local ok, diff_indices = pcall(vim.diff, disk_text, swap_text, { result_type = "indices" })
						if ok and diff_indices and type(diff_indices) == "table" then
							for _, hunk in ipairs(diff_indices) do
								deleted = deleted + hunk[2]
								added = added + hunk[4]
							end
							diff_str = string.format("+%d/-%d lines", added, deleted)
						end
					end
				else
					diff_str = "Empty swap / Error"
				end

				table.insert(results, {
					path = path,
					lines = lines,
					diff_str = diff_str,
					mtime = vim.fn.getftime(path),
				})

				completed = completed + 1
				if completed == #swap_paths then
					table.sort(results, function(a, b)
						return a.mtime > b.mtime
					end)
					callback(results)
				end
			end)
		end

		if vim.system then
			vim.system(cmd, { text = true }, on_exit)
		else
			vim.fn.jobstart(cmd, { on_exit = on_exit })
		end
	end
end

-- Deduplicate and resolve swap paths
function M.get_unique_swap_files(filepath, current_swap)
	local raw_swaps = {}
	if current_swap and current_swap ~= "" then
		table.insert(raw_swaps, current_swap)
	end

	if filepath and filepath ~= "" then
		local dirs = vim.opt.directory:get()
		local name = vim.fn.fnamemodify(filepath, ":t")
		local abs_path = vim.fn.fnamemodify(filepath, ":p")

		for _, dir in ipairs(dirs) do
			local expanded_dir = vim.fn.expand(dir)
			local pattern = expanded_dir:match("//$") and (expanded_dir .. abs_path:gsub("[/\\]", "%%") .. ".sw*")
				or (expanded_dir .. "/." .. name .. ".sw*")

			for _, f in ipairs(vim.fn.glob(pattern, true, true)) do
				if f ~= "" and vim.fn.isdirectory(f) == 0 then
					table.insert(raw_swaps, f)
				end
			end
		end
	end

	local unique_swaps, seen = {}, {}
	for _, raw_path in ipairs(raw_swaps) do
		local resolved = vim.fn.resolve(vim.fn.fnamemodify(raw_path, ":p"))
		if not seen[resolved] then
			seen[resolved] = true
			table.insert(unique_swaps, resolved)
		end
	end

	return unique_swaps
end

-- Preview Diff using a Fullscreen Native Tab Page
function M.preview_diff(swap_info, original_bufnr, on_close_cb)
	local ft = vim.bo[original_bufnr].filetype
	local disk_lines = vim.api.nvim_buf_get_lines(original_bufnr, 0, -1, false)

	local swap_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(swap_buf, "Swap Version")
	vim.api.nvim_buf_set_lines(swap_buf, 0, -1, false, swap_info.lines)
	vim.bo[swap_buf].filetype = ft
	vim.bo[swap_buf].modifiable = false

	local disk_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(disk_buf, "Disk Version")
	vim.api.nvim_buf_set_lines(disk_buf, 0, -1, false, disk_lines)
	vim.bo[disk_buf].filetype = ft
	vim.bo[disk_buf].modifiable = false

	-- 1. Create a native Neovim Tab for full-screen diffing
	vim.cmd("tabnew")
	local disk_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(disk_win, disk_buf)

	-- 2. Split vertically and place the swap version on the left
	vim.cmd("leftabove vertical sbuffer " .. swap_buf)
	local swap_win = vim.api.nvim_get_current_win()

	-- ==========================================================
	-- UI ENHANCEMENT 1: Sticky Window Bars (Winbar)
	-- This completely solves the "which side is which" problem
	-- ==========================================================
	local red_fg = global.get_color("DiagnosticError", "fg")
	local green_fg = global.get_color("DiagnosticOk", "fg")
	local base_bg = global.get_color("CursorLine", "bg")
	if not base_bg then
		base_bg = global.get_color("Normal", "bg")
	end
	vim.api.nvim_set_hl(0, "SwapWinbarRed", { fg = base_bg, bg = red_fg, bold = true })
	vim.api.nvim_set_hl(0, "SwapWinbarGreen", { fg = base_bg, bg = green_fg, bold = true })

	vim.wo[swap_win].winbar = "%#SwapWinbarRed# Swap Version"
	vim.wo[disk_win].winbar = "%#SwapWinbarGreen# Disk Version"

	-- ==========================================================
	-- UI ENHANCEMENT 2: Force high-quality word-level diffing
	-- ==========================================================
	local original_diffopt = vim.opt.diffopt:get()
	vim.opt.diffopt:append("linematch:60")

	-- 3. Lock window options to keep the diff strictly side-by-side
	vim.wo[swap_win].foldenable = false
	vim.wo[disk_win].foldenable = false
	vim.wo[swap_win].wrap = false
	vim.wo[disk_win].wrap = false

	-- 4. Enable Native Diffing
	vim.api.nvim_win_call(swap_win, function()
		vim.cmd("diffthis")
	end)
	vim.api.nvim_win_call(disk_win, function()
		vim.cmd("diffthis")
	end)

	-- Sync cursor movements explicitly
	vim.wo[swap_win].cursorbind = true
	vim.wo[disk_win].cursorbind = true

	-- 5. Unified cleanup logic
	local callback_triggered = false
	local function close_preview()
		if callback_triggered then
			return
		end
		callback_triggered = true

		-- Restore the user's original diffopt settings
		vim.opt.diffopt = original_diffopt

		pcall(vim.api.nvim_win_close, swap_win, true)
		pcall(vim.api.nvim_win_close, disk_win, true)

		pcall(vim.api.nvim_buf_delete, swap_buf, { force = true })
		pcall(vim.api.nvim_buf_delete, disk_buf, { force = true })

		if on_close_cb then
			vim.schedule(on_close_cb)
		end
	end

	for _, key in ipairs({ "q", "<Esc>" }) do
		vim.keymap.set("n", key, close_preview, { buffer = swap_buf, silent = true, nowait = true })
		vim.keymap.set("n", key, close_preview, { buffer = disk_buf, silent = true, nowait = true })
	end

	local group = vim.api.nvim_create_augroup("SwapDiffCleanup", { clear = true })
	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = { tostring(disk_win), tostring(swap_win) },
		group = group,
		callback = close_preview,
	})
end

-- Second-level Action Menu
function M.prompt_swap_action(swap_info, all_swap_infos, bufnr)
	local prompt_title = string.format("Action for Swap (%s):", swap_info.diff_str)
	local choices = { "Preview Diff", "Recover", "Delete Swap", "Edit Anyway (Ignore Swap)" }

	if #all_swap_infos > 1 then
		table.insert(choices, "Back to Swap List")
	end
	table.insert(choices, "Cancel")

	vim.ui.select(choices, { prompt = prompt_title }, function(action)
		if not action or action == "Cancel" then
			global.notify("Buffer remains read-only to protect changes.", vim.log.levels.INFO)
			return
		end

		if action == "Back to Swap List" then
			M.show_main_menu(all_swap_infos, bufnr)
		elseif action == "Preview Diff" then
			M.preview_diff(swap_info, bufnr, function()
				vim.schedule(function()
					M.prompt_swap_action(swap_info, all_swap_infos, bufnr)
				end)
			end)
		elseif action == "Recover" then
			vim.bo[bufnr].readonly = false
			vim.bo[bufnr].modifiable = true

			local ufo_status, ufo = pcall(require, "ufo")
			if ufo_status then
				pcall(ufo.detach, bufnr)
			end

			local success, err = pcall(function()
				vim.api.nvim_buf_call(bufnr, function()
					local orig_name = vim.api.nvim_buf_get_name(bufnr)
					local temp_swap = vim.fn.tempname() .. ".swp"

					---@diagnostic disable-next-line: undefined-field
					(vim.uv or vim.loop).fs_copyfile(swap_info.path, temp_swap)

					vim.cmd("silent! recover " .. vim.fn.fnameescape(temp_swap))

					-- Ensure the buffer name wasn't ruined by the recovery parsing
					if vim.api.nvim_buf_get_name(bufnr) ~= orig_name then
						vim.api.nvim_buf_set_name(bufnr, orig_name)
					end

					vim.fn.delete(temp_swap)
				end)
			end)

			if success then
				global.notify("Recovered successfully!")
				vim.schedule(function()
					vim.ui.select({ "Yes", "No" }, { prompt = "Delete the swap file now?" }, function(del)
						if del == "Yes" then
							vim.fn.delete(swap_info.path)
							global.notify("Deleted swap file.")
						end
					end)
				end)
			else
				global.notify("Error recovering: " .. tostring(err), vim.log.levels.ERROR)
			end

			if ufo_status then
				vim.defer_fn(function()
					pcall(ufo.attach, bufnr)
				end, 100)
			end
		elseif action == "Edit Anyway (Ignore Swap)" then
			vim.bo[bufnr].readonly = false
			vim.bo[bufnr].modifiable = true
			global.notify("Buffer is now writable. Swap file kept.")
		elseif action == "Delete Swap" then
			vim.fn.delete(swap_info.path)
			vim.bo[bufnr].readonly = false
			vim.bo[bufnr].modifiable = true
			global.notify("Deleted swap file.")
		end
	end)
end

-- Top-level Initial Menu
function M.show_main_menu(swap_infos, bufnr)
	if #swap_infos == 1 then
		M.prompt_swap_action(swap_infos[1], swap_infos, bufnr)
		return
	end

	local choices = { unpack(swap_infos) }
	table.insert(choices, { is_meta = true, action = "edit_anyway", label = "👉 Edit Anyway (Ignore All Swaps)" })

	vim.ui.select(choices, {
		prompt = "⚠️ Multiple Swaps detected. Choose one to inspect:",
		kind = "swap_files",
		format_item = function(item)
			if item.is_meta then
				return item.label
			end
			local time_str = item.mtime > 0 and os.date("%Y-%m-%d %H:%M", item.mtime) or "Unknown time"
			return string.format("[%s] %s", time_str, item.diff_str)
		end,
	}, function(selected)
		if not selected then
			return
		end

		if selected.is_meta then
			if selected.action == "edit_anyway" then
				vim.bo[bufnr].readonly = false
				vim.bo[bufnr].modifiable = true
				global.notify("Buffer is now writable. Swap files kept.")
			end
			return
		end

		M.prompt_swap_action(selected, swap_infos, bufnr)
	end)
end

function M.swap_preview_autocmd_callback()
	local captured_swap = vim.v.swapname
	local bufnr = vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)

	-- Default to opening read-only in the background to prevent immediate overwrites
	vim.v.swapchoice = "o"

	-- Check if the swap file is owned by a LIVING process
	local info = vim.fn.swapinfo(captured_swap)
	if info and type(info.pid) == "number" then
		---@diagnostic disable-next-line: undefined-field
		local ok, res = pcall((vim.uv or vim.loop).kill, info.pid, 0)
		if ok and res == 0 then
			-- The process is actively running in another Tmux pane/terminal!
			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(bufnr) then
					return
				end

				vim.ui.select({
					"1. Open Read-Only",
					"2. Edit Anyway (Ignore Swap)",
					"3. Quit Buffer",
				}, {
					prompt = string.format("File is actively open in another Neovim instance (PID: %d)", info.pid),
				}, function(choice)
					if not choice or choice:match("Read%-Only") then
						vim.notify("Opened Read-Only. Another instance is editing this file.", vim.log.levels.WARN)
					elseif choice:match("Edit Anyway") then
						vim.bo[bufnr].readonly = false
						vim.bo[bufnr].modifiable = true
						vim.notify("Buffer is writable. Be careful not to overwrite the other instance!")
					elseif choice:match("Quit") then
						vim.cmd("bdelete! " .. bufnr)
					end
				end)
			end)
			-- Abort here! We DO NOT want to preview or delete an active swap file.
			return
		end
	end

	-- If process is dead (Stale Swap), proceed with Diff Preview
	vim.schedule(function()
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end

		local swap_paths = M.get_unique_swap_files(filepath, captured_swap)
		if #swap_paths == 0 then
			return
		end

		local disk_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local disk_text = table.concat(disk_lines, "\n") .. "\n"

		M.fetch_swap_infos_async(swap_paths, disk_text, function(swap_infos)
			if not vim.api.nvim_buf_is_valid(bufnr) then
				return
			end
			M.show_main_menu(swap_infos, bufnr)
		end)
	end)
end

return M
