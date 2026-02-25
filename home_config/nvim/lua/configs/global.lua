-- ./lua/dung/global.lua
vim.g.is_termux = vim.env.PREFIX and vim.env.PREFIX:match("com.termux") ~= nil

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

return M
