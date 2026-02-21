return {
	"theprimeagen/harpoon",
	cond = not vim.g.vscode,
	config = function()
		require("telescope").load_extension("harpoon")
		local mark = require("harpoon.mark")
		local ui = require("harpoon.ui")

		vim.keymap.set("n", "<leader>a", mark.add_file)
		vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

		vim.keymap.set("n", "<leader>f7", function()
			ui.nav_file(1)
		end)
		vim.keymap.set("n", "<leader>f8", function()
			ui.nav_file(2)
		end)
		vim.keymap.set("n", "<leader>f9", function()
			ui.nav_file(3)
		end)
		vim.keymap.set("n", "<leader>f0", function()
			ui.nav_file(4)
		end)
		vim.keymap.set("n", "<C-[>", function()
			ui.nav_next()
		end)
		vim.keymap.set("n", "<C-]>", function()
			ui.nav_prev()
		end)
	end,
}
