return {
	"folke/snacks.nvim",
	opts = {
		input = {
			enabled = true,
			icon = " ",
			icon_hl = "SnacksInputIcon",
			icon_pos = "left",
			expand = true,
			win = {
				relative = "cursor",
				border = "rounded",
				blend = 10, -- Reduces opacity of input background (0 is opaque, 100 transparent)
			},
		},
		picker = {
			enabled = true,
			ui_select = true, -- Ensures vim.ui.select uses snacks picker
			win = {
				input = {
					keys = {
						["<Esc>"] = { "close", mode = { "n", "i" } },
						["<C-q>"] = { "close", mode = { "n", "i" } },
					},
					blend = 20, -- Reduces opacity of picker input background
				},
				list = {
					blend = 20, -- Also apply blend to the choices list
				},
			},
			sources = {
				select = {
					layout = {
						preset = "vscode",
						relative = "editor",
						-- Override the layout to use border for the list
						layout = {
							backdrop = false,
							row = 1,
							width = 0.4,
							min_width = 80,
							height = 0.4,
							blend = 20,
							border = "none",
							box = "vertical",
							{
								win = "input",
								height = 1,
								border = "rounded",
								title = "{title} {live} {flags}",
								title_pos = "center",
							},
							{ win = "list", border = "rounded" },
							{ win = "preview", title = "{preview}", border = "rounded" },
						},
					},
				},
			},
			formatters = {
				file = {
					filename_first = true,
					truncate = "center",
				},
			},
			matcher = {
				frecency = true,
			},
		},
		styles = {
			swap_diff = {
				width = 0.9,
				height = 0.8,
				border = "rounded",
				title = " 󰁯 Swap Diff Preview (Left: Swap | Right: Disk) ",
				title_pos = "center",
				backdrop = 60, -- Dims the background
				keys = {
					["q"] = "close",
					["<Esc>"] = "close",
				},
			},
		},
		scroll = {
			enabled = true,
			animate = {
				duration = { step = 10, total = 80 },
				easing = "linear",
			},
			-- faster animation when repeating scroll after delay
			animate_repeat = {
				delay = 100, -- delay in ms before using the repeat animation
				duration = { step = 5, total = 50 },
				easing = "linear",
			},
			-- what buffers to animate
			filter = function(buf)
				return vim.g.snacks_scroll ~= false
					and vim.b[buf].snacks_scroll ~= false
					and vim.bo[buf].buftype ~= "terminal"
			end,
		},
		indent = {
			indent = {
				priority = 1,
				enabled = true, -- enable indent guides
				char = "│",
				only_scope = false, -- only show indent guides of the scope
				only_current = false, -- only show indent guides in the current window
				hl = "SnacksIndent", ---@type string|string[] hl groups for indent guides
			},
			animate = {
				enabled = vim.fn.has("nvim-0.10") == 1,
				style = "out",
				easing = "linear",
				duration = {
					step = 20, -- ms per step
					total = 500, -- maximum duration
				},
			},
			scope = {
				enabled = true, -- enable highlighting the current scope
				priority = 200,
				char = "│",
				underline = false, -- underline the start of the scope
				only_current = false, -- only show scope in the current window
				hl = "SnacksIndentScope", ---@type string|string[] hl group for scopes
			},
			chunk = {
				enabled = true,
				only_current = false,
				priority = 200,
				hl = "SnacksIndentChunk", ---@type string|string[] hl group for chunk scopes
				char = {
					corner_top = "╭", -- or "┌", "╔", "╒", "╓", "┏"
					corner_bottom = "╰", -- or "└", "╚", "╘", "╙", "┗"
					horizontal = "─",
					vertical = "│",
					arrow = ">",
				},
			},
			filter = function(buf)
				return vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false and vim.bo[buf].buftype == ""
			end,
		},
		animate = { enabled = true },
		bigfile = {
			enabled = true,
			notify = true, -- show notification when big file detected
			size = 2 * 1024 * 1024, -- 2MB
			line_length = 1000, -- average line length (useful for minified files)
			setup = function(ctx)
				if vim.fn.exists(":NoMatchParen") ~= 0 then
					vim.cmd([[NoMatchParen]])
				end
				require("snacks").util.wo(0, { foldmethod = "manual", statuscolumn = "", conceallevel = 0 })
				vim.b.completion = false
				vim.b.minianimate_disable = true
				vim.b.minihipatterns_disable = true
				vim.schedule(function()
					if vim.api.nvim_buf_is_valid(ctx.buf) then
						vim.bo[ctx.buf].syntax = ctx.ft
					end
				end)
			end,
		},
	},
}
