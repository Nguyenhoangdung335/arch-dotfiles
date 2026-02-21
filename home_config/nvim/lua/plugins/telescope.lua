return {
	{
		"nvim-telescope/telescope.nvim",
		-- tag = "0.1.8",
		cond = not vim.g.vscode,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"BurntSushi/ripgrep",
			"sharkdp/fd",
		},
		config = function()
			local telescope = require("telescope")
			telescope.load_extension("fidget")
			telescope.setup({})

			local builtin = require("telescope.builtin")

			vim.keymap.set("n", "<leader>pf", builtin.find_files, { desc = "Telescope find all files" })
			vim.keymap.set("n", "<leader>pg", builtin.live_grep, { desc = "Telescope live grep" })
			vim.keymap.set("n", "<leader>pb", builtin.buffers, { desc = "Telescope buffers" })
			vim.keymap.set("n", "<C-p>", builtin.git_files, { desc = "find Git files" })
			vim.keymap.set("n", "<leader>ps", function()
				builtin.grep_string({ search = vim.fn.input("Grep > ") })
			end)

			-- local trouble_telescope = require("trouble.sources.telescope")
		end,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		cond = not vim.g.vscode,
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			require("telescope").load_extension("ui-select")
		end,
	},
}
