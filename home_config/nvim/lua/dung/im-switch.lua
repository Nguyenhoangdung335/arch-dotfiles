-- Auto-switch to English (Fcitx) when leaving Insert Mode
local fcitx_cmd = "fcitx5-remote"

-- Check if fcitx5-remote exists to avoid errors on other machines
if vim.fn.executable(fcitx_cmd) == 1 then
	vim.api.nvim_create_autocmd("InsertLeave", {
		pattern = "*",
		callback = function()
			-- Call fcitx5-remote -c (close/English) asynchronously
			vim.fn.jobstart({ fcitx_cmd, "-c" }, { detach = true })
		end,
	})

	-- Optional: Switch to English when you focus the window
	vim.api.nvim_create_autocmd("FocusGained", {
		pattern = "*",
		callback = function()
			vim.fn.jobstart({ fcitx_cmd, "-c" }, { detach = true })
		end,
	})
end
