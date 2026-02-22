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
		keys = {
			{
				"<leader>pf",
				function()
					require("telescope.builtin").find_files({ hidden = true })
				end,
				desc = "Find Files",
			},
			{
				"<leader>pg",
				function()
					require("telescope.builtin").live_grep()
				end,
				desc = "Live Grep",
			},
			{
				"<leader>pb",
				function()
					require("telescope.builtin").buffers()
				end,
				desc = "Buffers",
			},
			{
				"<leader>ph",
				function()
					require("telescope.builtin").help_tags()
				end,
				desc = "Help",
			},
			{
				"<leader>po",
				function()
					require("telescope.builtin").oldfiles()
				end,
				desc = "Old Files",
			},
			{
				"<leader>pp",
				function()
					require("telescope.builtin").git_files()
				end,
				desc = "Git Files",
			},
			{
				"<leader>pr",
				function()
					require("telescope.builtin").registers()
				end,
				desc = "Registers",
			},
			{
				"<leader>pm",
				function()
					require("telescope.builtin").marks()
				end,
				desc = "Marks",
			},
			{
				"<leader>pc",
				function()
					require("telescope.builtin").commands()
				end,
				desc = "Commands",
			},
			{
				"<leader>pw",
				function()
					vim.ui.input({
						prompt = "Grep > ",
						default = "",
					}, function(input)
						require("telescope.builtin").grep_string({ search = input })
					end)
				end,
				desc = "Grep String",
			},
			{
				"<leader>pt",
				function()
					require("telescope.builtin").tags()
				end,
				desc = "Tags",
			},
		},
		opts = {
			defaults = {
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--follow", -- 👈 follow symlinks
				},
				mappings = {
					n = {
						["<M-p>"] = require("telescope.actions.layout").toggle_preview,
						["<C-q>"] = require("telescope.actions").close,
					},
					i = {
						["<M-p>"] = require("telescope.actions.layout").toggle_preview,
						["<C-q>"] = require("telescope.actions").close,
					},
				},
			},
			pickers = {
				find_files = {
					-- find_command = {
					-- 	"fd",
					-- 	"--type",
					-- 	"f",
					-- 	"--hidden",
					-- 	"--follow",
					-- 	"--exclude",
					-- 	".git",
					-- },
					follow = true,
					hidden = true,
				},
			},
		},
		config = function(_, opts)
			local telescope = require("telescope")
			telescope.load_extension("fidget")
			telescope.setup(opts)

			--[[ local builtin = require("telescope.builtin")

			vim.keymap.set("n", "<leader>pf", builtin.find_files, { desc = "Telescope find all files" })
			vim.keymap.set("n", "<leader>pg", builtin.live_grep, { desc = "Telescope live grep" })
			vim.keymap.set("n", "<leader>pb", builtin.buffers, { desc = "Telescope buffers" })
			vim.keymap.set("n", "<C-p>", builtin.git_files, { desc = "find Git files" })
			vim.keymap.set("n", "<leader>ps", function() end) ]]
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
