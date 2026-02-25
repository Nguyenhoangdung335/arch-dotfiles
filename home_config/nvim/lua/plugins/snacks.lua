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
				},
			},
			sources = {
				select = {
					layout = { preset = "vscode", relative = "editor" }, -- A more compact layout
				},
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
	},
}
