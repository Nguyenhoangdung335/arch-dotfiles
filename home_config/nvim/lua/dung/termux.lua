-- ~/.config/nvim/lua/dung/termux.lua
--
-- termux-specific settings

if vim.g.is_termux then
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
