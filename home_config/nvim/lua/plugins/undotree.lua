return {
	{
		"jiaoshijie/undotree",
		cond = not vim.g.vscode,
		keys = { -- load the plugin only when using it's keybinding:
			{ "<leader>u", "<cmd>lua require('undotree').toggle()<cr>" },
		},
		config = function()
			require("undotree").setup({
				float_diff = true, -- set this `true` will disable layout option
				--- @type "left_bottom" | "left_left_bottom"
				layout = "left_bottom", -- {left}_{bottom} {left}_{left_bottom}
				--- @type "left" | "right"
				position = "left",
				window = {
					width = 0.25, -- the `undotree` window width percentage related to the editor
					height = 0.25, -- the `preview`(not floating) window height percentage related to the editor
					border = "rounded", -- float window
				},

				ignore_filetype = {},
				--- @type "compact" | "legacy"
				parser = "compact",

				keymaps = {
					["j"] = "move_next",
					["k"] = "move_prev",
					["gj"] = "move2parent",
					["J"] = "move_change_next",
					["K"] = "move_change_prev",
					["<cr>"] = "action_enter",
					["p"] = "enter_diffbuf", -- this can switch between preview and undotree window
					["q"] = "quit",
					["S"] = "update_undotree_view",
				},
			})
		end,
	},
}

--[[ return {
	{
		"mbbill/undotree",
		cond = not vim.g.vscode,
		config = function()
			vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
		end,
	},
} ]]
