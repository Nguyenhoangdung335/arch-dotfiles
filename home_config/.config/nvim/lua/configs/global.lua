---@diagnostic disable: undefined-field
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
