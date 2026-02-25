return {
	"theprimeagen/harpoon",
	cond = not vim.g.vscode and not vim.g.is_termux,
	keys = {
		{
			"<leader>a",
			function()
				require("harpoon.mark").add_file()
			end,
			desc = "Add file to harpoon list",
		},
		{
			"<C-e>",
			function()
				require("harpoon.ui").toggle_quick_menu()
			end,
			desc = "Toggle harpoon quick menu",
		},
		{
			"<leader>f7",
			function()
				require("harpoon.ui").nav_file(1)
			end,
			desc = "Go to harpoon file 1",
		},
		{
			"<leader>f8",
			function()
				require("harpoon.ui").nav_file(2)
			end,
			desc = "Go to harpoon file 2",
		},
		{
			"<leader>f9",
			function()
				require("harpoon.ui").nav_file(3)
			end,
			desc = "Go to harpoon file 3",
		},
		{
			"<leader>f0",
			function()
				require("harpoon.ui").nav_file(4)
			end,
			desc = "Go to harpoon file 4",
		},
		{
			"<C-[>",
			function()
				require("harpoon.ui").nav_next()
			end,
			desc = "Go to next harpoon file",
		},
		{
			"<C-]>",
			function()
				require("harpoon.ui").nav_prev()
			end,
			desc = "Go to previous harpoon file",
		},
	},
}
