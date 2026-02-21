return {
	{
		"numToStr/Comment.nvim",
		dependencies = {
			"JoosepAlviste/nvim-ts-context-commentstring",
		},
		opts = {
			-- Your existing settings
			padding = true,
			sticky = true,
			ignore = "^$",
			toggler = {
				line = "gcc",
				block = "gbc",
			},
			opleader = {
				line = "gc",
				block = "gb",
			},
			extra = {
				above = "gcO",
				below = "gco",
				eol = "gcA",
			},
			mappings = {
				basic = true,
				extra = true,
				extended = false,
			},
		},
		config = function(_, opts)
			-- 1. Setup the context plugin first
			require("ts_context_commentstring").setup({
				enable_autocmd = false,
			})

			-- 2. Integrate with Comment.nvim using the pre_hook
			opts.pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()

			-- 3. Run the standard setup
			require("Comment").setup(opts)
		end,
	},
}
