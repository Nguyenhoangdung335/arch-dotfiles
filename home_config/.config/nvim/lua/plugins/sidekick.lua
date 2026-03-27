local disabled_filetypes = {
	markdown = true,
	help = true,
	txt = true,
}

return {
	"folke/sidekick.nvim",
	name = "sidekick",
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		-- add any options here
		nes = {
			-- enabled = vim.g.sidekick_nes ~= false and vim.b.sidekick_nes ~= false,
			enabled = function()
				if disabled_filetypes[vim.bo.filetype] then
					vim.notify("Sidekick is disabled for this file type (" .. vim.bo.filetype .. ")")
					return false
				end
				return vim.g.sidekick_nes ~= false and vim.b.sidekick_nes ~= false
			end,
			debounce = 100,
			trigger = {
				events = { "CursorHoldI", "User SidekickNesDone" },
			},
			-- Enable inline diffs ("words"|"chars"|false)
			diff = { inline = "words" },
		},
		cli = { mux = { enabled = false } },
	},
	keys = {
		{
			"<C-Cr>",
			function()
				-- if there is a next edit, jump to it, otherwise apply it if any
				if not require("sidekick").nes_jump_or_apply() then
					return "<C-Cr>" -- fallback to normal tab
				end
			end,
			expr = true,
			desc = "Goto/Apply Next Edit Suggestion",
		},
		{
			"<S-Tab>",
			function()
				if not require("sidekick.nes").update() then
					return "<S-Tab>" -- fallback to normal tab
				end
			end,
			expr = true,
			desc = "Update Next Edit Suggestions",
		},
		{
			"Esc",
			function()
				local sk = require("sidekick.nes")
				if sk.have() then
					sk.clear()
					-- Temporarily disable sidekick nes, and enabled again when the next character is inserted
					sk.disable()
					vim.api.nvim_create_autocmd("InsertCharPre", {
						buffer = 0,
						once = true,
						callback = function()
							sk.enable()
						end,
					})
				else
					return "Esc"
				end
			end,
			desc = "Cancel Edit Suggestion",
		},
	},
}
