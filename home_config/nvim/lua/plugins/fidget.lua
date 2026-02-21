return {
	{
		"j-hui/fidget.nvim",
		opts = {
			-- Options related to the notification window and buffer
			notification = {
				poll_rate = 10, -- How frequently to update and render notifications
				filter = vim.log.levels.INFO, -- Minimum notification level
				history_size = 128, -- Number of removed messages to retain in history
				override_vim_notify = true, -- Automatically override vim.notify() with Fidget

				-- Optional: Customizing the window look
				window = {
					normal_hl = "Comment", -- Base highlight group in the notification window
					winblend = 0, -- Background color opacity in the notification window
					border = "none", -- Border around the notification window
					zindex = 45, -- Stacking priority of the notification window
					max_width = 0, -- Maximum width of the notification window
					max_height = 0, -- Maximum height of the notification window
					x_padding = 1, -- Padding from right edge of window boundary
					y_padding = 0, -- Padding from bottom edge of window boundary
					align = "bottom", -- How to align the notification window
					relative = "editor", -- What the notification window position is relative to
				},
			},
		},
		config = function()
			require("fidget").setup({})
		end,
	},
}
