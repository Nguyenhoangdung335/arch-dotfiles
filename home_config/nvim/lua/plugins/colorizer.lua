return {
	"brenoprata10/nvim-highlight-colors",
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		render = "background", -- 'background', 'foreground', 'virtual'
		virtual_symbol = "■",
		virtual_symbol_prefix = " ",
		virtual_symbol_suffix = "",
		virtual_symbol_position = "inline", -- 'inline', 'eol', 'eow'
		enable_hex = true,
		enable_short_hex = true,
		enable_rgb = true,
		enable_hsl = true,
		enable_ansi = true,
		enable_xterm256 = true,
		enable_xtermTrueColor = true,
		enable_hsl_without_function = true,
		enable_var_usage = true,
		enable_named_colors = true,
		enable_tailwind = true,
		custom_colors = {},
		exclude_buftypes = {},
		exclude_filetypes = {},
		exclude_buffer = function() end,
	},
	keys = {
		{ "<leader>hl", "<cmd>HighlightColors Toggle<cr>", desc = "Toggle highlight colors" },
	},
}
