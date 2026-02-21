return {
	{
		"catppuccin/nvim",
		cond = not vim.g.vscode,
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "auto", -- latte, frappe, macchiato, mocha
				background = { -- :h background
					light = "latte",
					dark = "mocha",
				},
				transparent_background = true, -- disables setting the background color.
				float = {
					transparent = true, -- enable transparent floating windows
					solid = false, -- use solid styling for floating windows, see |winborder|
				},
				show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
				term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
				dim_inactive = {
					enabled = false, -- dims the background color of inactive window
					shade = "dark",
					percentage = 0.15, -- percentage of the shade to apply to the inactive window
				},
				no_italic = false, -- Force no italic
				no_bold = false, -- Force no bold
				no_underline = false, -- Force no underline
				styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
					comments = { "italic" }, -- Change the style of comments
					conditionals = { "italic" },
					loops = {},
					functions = {},
					keywords = {},
					strings = {},
					variables = {},
					numbers = {},
					booleans = {},
					properties = {},
					types = {},
					operators = {},
					-- miscs = {}, -- Uncomment to turn off hard-coded styles
				},
				color_overrides = {},
				custom_highlights = {},
				default_integrations = false,
				auto_integrations = true,
				-- integrations = {
				-- 	cmp = true,
				-- 	gitsigns = true,
				-- 	treesitter = true,
				-- },
				-- integrations = {
				--     cmp = true,
				--     gitsigns = true,
				--     treesitter = true,
				--     nvimtree = false,
				--     notify = false,
				--     mini = {
				--         enabled = true,
				--         indentscope_color = "",
				--     },
				--     -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
				-- },
			})

			-- setup must be called before loading
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
-- function ColorMyPencils (color)
-- 	color = color or "rose-pine"
-- 	vim.cmd.colorscheme(color)

-- 	vim.api.nvim_set_hl(0, "Normal", {bg = "none" })
-- 	vim.api.nvim_set_hl(0, "NormalFloat", {bg = "none" })
-- end

-- return {
-- 	{
-- 	  "rose-pine/neovim",
-- 	  name = "rose-pine",
-- 	  config = function()
-- 		  require('rose-pine').setup({
-- 		  disable_background = true,
-- 		  styles = {
-- 			  italic = false,
-- 		  }
-- 	  })

-- 	  ColorMyPencils()
-- 	  end
-- 	}
-- }
