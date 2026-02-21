return {
	{
		"nvimdev/lspsaga.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("lspsaga").setup({
				ui = {
					border = "rounded",
                    devicon = true,
                    title = true,
                    code_action = "",
				},
                lightbulb = {
                    enable = false,
                    sign = true,
                    virtual_text = true,
                    debounce = 10,
                    sign_priority = 20,
                },
                hover = {
                    max_width = 0.9,
                    max_height = 0.9,
                    open_link = "gx",
                    open_cmd = "!zen-browser"
                },
			})
		end,
	},
}
