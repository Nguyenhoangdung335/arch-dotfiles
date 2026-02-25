-- Helper function to dynamically create highlight groups
local function hl_color(group_name, hex_color)
	-- Only create the highlight group if it doesn't exist
	if vim.fn.hlexists(group_name) == 0 then
		vim.api.nvim_set_hl(0, group_name, { bg = hex_color })
	end
	return group_name
end

return {
	{
		"echasnovski/mini.hipatterns",
		-- Load it for files where you are likely to see color codes
		event = "BufReadPost",
		opts = {
			highlighters = {
				-- Highlighter for all hex values: #rgb, #rgba, #rrggbb, #rrggbbaa
				hex_color = {
					-- The pattern to match
					pattern = "#[%x_]+",
					-- The 'hl_group' function sets the background to the matched color
					hl_group = function(match)
						return hl_color("MiniHipatternsHex" .. match, match)
					end,
				},
				-- Highlighter for rgb(a) and hsl(a) functions
				css_color_fn = {
					pattern = "([%w_]+%(.-%))",
					hl_group = function(match)
						-- This is a more advanced step: convert css fn to hex
						-- For simplicity, this example just highlights them,
						-- but a full conversion is possible with a helper library.
						-- For now, we just give it a standard color to show it's a match.
						local color_name = match:match("^(%w+)")
						if
							color_name == "rgb"
							or color_name == "rgba"
							or color_name == "hsl"
							or color_name == "hsla"
						then
							-- To keep it simple, we'll just highlight that we found a function
							-- A full implementation would parse the values and convert to hex.
							return "MiniHipatternsCssFn"
						end
					end,
				},
			},
		},
		config = function(_, opts)
			require("mini.hipatterns").setup(opts)

			-- Define the fallback highlight group for css functions
			vim.api.nvim_set_hl(0, "MiniHipatternsCssFn", { bg = "#3d4256" }) -- A neutral highlight
		end,
	},
}
