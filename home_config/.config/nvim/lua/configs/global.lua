---@diagnostic disable: undefined-field
vim.g.is_termux = vim.env.PREFIX and vim.env.PREFIX:match("com.termux") ~= nil
vim.g.window_blend = 20

local M = {}

function M.notify(msg, level, opts)
	opts = opts or {}
	level = level or vim.log.levels.INFO
	opts.title = opts.title or "Notification"
	local has_fidget, fidget = pcall(require, "fidget")

	if has_fidget then
		fidget.notify(msg, level, opts)
	else
		vim.notify(msg, level, opts)
	end
end

function M.system_notify(title, message, level)
	-- Map level to urgency for notify-send
	local urgency = {
		[vim.log.levels.INFO] = "normal",
		[vim.log.levels.WARN] = "critical",
		[vim.log.levels.ERROR] = "critical",
	}
	local urgency_level = urgency[level] or "low"
	local cmd = string.format('notify-send -u %s "%s" "%s"', urgency_level, title, message)
	os.execute(cmd)
end

function M.is_neovim_focused()
	local current_pid = vim.fn.getpid()
	local handle = io.popen("hyprctl activewindow -j")
	if not handle then
		return false
	end
	local result = handle:read("*a")
	handle:close()
	local active_pid = tonumber(result:match('"pid":%s*(%d+)'))
	return current_pid == active_pid
end

function M.get_color(group_name, attr)
	local hl = vim.api.nvim_get_hl(0, { name = group_name, link = false })
	while hl.link do
		hl = vim.api.nvim_get_hl(0, { name = hl.link, link = false })
	end
	local color_int = hl[attr]
	if not color_int then
		return nil
	end
	return string.format("#%06x", color_int)
end

return M
