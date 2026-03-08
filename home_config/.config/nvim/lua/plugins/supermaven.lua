return {
	"supermaven-inc/supermaven-nvim",
	dependencies = { "catppuccin" },
	opts = function()
		local curr_theme = require("catppuccin.palettes.mocha")
		return {
			keymaps = {
				accept_suggestion = "<C-Enter>",
				accept_word = "<C-j>",
				clear_suggestion = "<C-]>",
			},
			ignore_filetypes = {
				["cpp"] = true,
				["codecompanion"] = true,
				["copilot-chat"] = true,
				["opencode_output"] = true,
				["Avante"] = true,
			},
			color = { suggestion_color = curr_theme.rosewater, cterm = 244 },
			log_level = "info", -- set to "off" to disable logging completely
			disable_inline_completion = true, -- disables inline completion for use with cmp
			disable_keymaps = false, -- disables built in keymaps for more manual control
			condition = function()
				return false
			end, -- condition to check for stopping supermaven, `true` means to stop supermaven when the condition is true.
		}
	end,
}
