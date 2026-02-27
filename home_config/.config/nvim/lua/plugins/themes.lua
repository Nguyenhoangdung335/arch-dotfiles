return {
	"catppuccin/nvim",
	cond = not vim.g.vscode,
	name = "catppuccin",
	priority = 2000,
	opts = {
		flavour = "auto", -- latte, frappe, macchiato, mocha
		background = { -- :h background
			light = "latte",
			dark = "mocha",
		},
		transparent_background = true, -- disables setting the background color.
		float = {
			transparent = true, -- enable transparent floating windows
			solid = true, -- use solid styling for floating windows, see |winborder|
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
		lsp_styles = { -- Handles the style of specific lsp hl groups (see `:h lsp-highlight`).
			virtual_text = {
				errors = { "italic" },
				hints = { "italic" },
				warnings = { "italic" },
				information = { "italic" },
				ok = { "italic" },
			},
			underlines = {
				errors = { "underline" },
				hints = { "underline" },
				warnings = { "underline" },
				information = { "underline" },
				ok = { "underline" },
			},
			inlay_hints = {
				background = true,
			},
		},
		color_overrides = {},
		custom_highlights = function(colors)
			return {
				-- Snacks Indent highlight groups
				SnacksIndent1 = { fg = colors.red },
				SnacksIndent2 = { fg = colors.peach },
				SnacksIndent3 = { fg = colors.yellow },
				SnacksIndent4 = { fg = colors.green },
				SnacksIndent5 = { fg = colors.sapphire },
				SnacksIndent6 = { fg = colors.lavender },
				SnacksIndent7 = { fg = colors.mauve },
				SnacksIndent8 = { fg = colors.blue },
				SnacksIndentScope = { fg = colors.lavender, bold = true },
				SnacksIndentChunk = { fg = colors.lavender, bold = true },

				-- Ufo folding highlight groups
				Folded = { fg = colors.surface1, bg = colors.mantle },
				FoldColumn = { fg = colors.surface1, bg = colors.mantle },
				["@region.marker"] = { fg = colors.peach, bold = true, italic = true },
				["@region.marker.folded"] = { fg = colors.peach, bg = colors.mantle, bold = true, italic = true },
				UfoFoldedEllipsis = { fg = colors.lavender, bg = colors.mantle, bold = true },
				UfoPreviewSbar = { bg = colors.crust },
				UfoPreviewThumb = { bg = colors.surface2 },
			}
		end,
		default_integrations = true,
		auto_integrations = true,
		integrations = {
			cmp = true,
			gitsigns = true,
			treesitter = true,
			nvimtree = false,
			notify = false,
			-- mini = {
			-- 	enabled = true,
			-- 	indentscope_color = "",
			-- },
			snacks = {
				enabled = true,
				indent_scope_color = "",
			},
		},
	},
	config = function(_, opts)
		require("catppuccin").setup(opts)
		vim.cmd.colorscheme("catppuccin")
	end,
}
