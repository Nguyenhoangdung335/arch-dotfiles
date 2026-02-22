-- ./lua/dung/global.lua

local is_termux = vim.env.PREFIX and vim.env.PREFIX:match("com.termux") ~= nil
vim.g.is_termux = is_termux

if is_termux then
  vim.g.clipboard = {
    name = "termux",
    copy = {
      ["+"] = "termux-clipboard-set",
      ["*"] = "termux-clipboard-set",
    },
    paste = {
      ["+"] = "termux-clipboard-get",
      ["*"] = "termux-clipboard-get",
    },
    cache_enabled = 0,
  }
end

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
