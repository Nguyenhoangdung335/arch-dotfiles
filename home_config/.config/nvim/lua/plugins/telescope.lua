local focus_preview = function(prompt_bufnr)
	local action_state = require("telescope.actions.state")
	local picker = action_state.get_current_picker(prompt_bufnr)
	local prompt_win = picker.prompt_win
	local previewer = picker.previewer
	local winid = previewer.state.winid
	local bufnr = previewer.state.bufnr

	-- Lock preview buffer
	vim.bo[bufnr].modifiable = false
	vim.bo[bufnr].readonly = true
	vim.bo[bufnr].buftype = "nofile"

	-- Return to prompt input buffer
	vim.keymap.set("n", "<Tab>", function()
		vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", prompt_win))
	end, { buffer = bufnr })

	vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", winid))
end

return {
	{
		"nvim-telescope/telescope.nvim",
		cond = not vim.g.vscode,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"BurntSushi/ripgrep",
			"sharkdp/fd",
			"nvim-telescope/telescope-ui-select.nvim",
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
			{
				"<leader>pn",
				function()
					require("telescope").extensions.fidget.fidget()
				end,
				desc = "Fidget Notifications",
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
					-- "--follow",
				},
				mappings = {
					n = {
						["<M-p>"] = require("telescope.actions.layout").toggle_preview,
						["<Esc>"] = require("telescope.actions").close,
						["<Tab>"] = focus_preview,
					},
					i = {
						["<M-p>"] = require("telescope.actions.layout").toggle_preview,
						["<Esc>"] = require("telescope.actions").close,
						["<Tab>"] = focus_preview,
						-- ["<C-w>"] = function()
						-- 	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>", true, false, true), "n", true)
						-- end,

						-- -- Similarly for <C-u> to ensure it's clean:
						-- ["<C-u>"] = function()
						-- 	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-u>", true, false, true), "n", true)
						-- end,
					},
				},
				layout_strategy = "horizontal", -- important
				layout_config = {
					horizontal = { preview_width = 0.6 },
					vertical = { preview_height = 0.6 },
				},
			},
			pickers = {
				find_files = { --[[ follow = true, ]]
					hidden = true,
				},
			},
			extensions = {
				["ui-select"] = { require("telescope.themes").get_dropdown({}) },
			},
		},
		config = function(_, opts)
			local telescope = require("telescope")
			local has_fidget = pcall(require, "fidget")
			local has_ui_select = pcall(require, "telescope-ui-select")
			local has_harpoon = pcall(require, "harpoon")

			if has_fidget then
				telescope.load_extension("fidget")
			end
			if has_ui_select then
				telescope.load_extension("ui-select")
			end
			if has_harpoon then
				telescope.load_extension("harpoon")
			end
			telescope.setup(opts)
			-- local trouble_telescope = require("trouble.sources.telescope")
		end,
	},
}
