return {
	"echasnovski/mini.hipatterns",
	event = { "BufReadPost", "BufNewFile" },
	opts = function()
		local hipatterns = require("mini.hipatterns")

		return {
			highlighters = {
				-- 1. Built-in hex color highlighting
				hex_color = hipatterns.gen_highlighter.hex_color(),

				-- 2. Built-in comment keyword highlighting (New!)
				todo = hipatterns.gen_highlighter.todo(),
				fixme = hipatterns.gen_highlighter.fixme(),
				hack = hipatterns.gen_highlighter.hack(),
				note = hipatterns.gen_highlighter.note(),

				-- 3. Your custom CSS function highlighter
				css_color_fn = {
					pattern = "([%w_]+%(.-%))",
					hl_group = function(match)
						local color_name = match:match("^(%w+)")
						if
							color_name == "rgb"
							or color_name == "rgba"
							or color_name == "hsl"
							or color_name == "hsla"
						then
							return "MiniHipatternsCssFn"
						end
					end,
				},
			},
		}
	end,
	config = function(_, opts)
		-- Define the fallback highlight group for css functions
		vim.api.nvim_set_hl(0, "MiniHipatternsCssFn", { bg = "#3d4256" })

		require("mini.hipatterns").setup(opts)
	end,
}
