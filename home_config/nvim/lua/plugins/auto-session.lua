return {
	{
		"rmagatti/auto-session",
		cond = not vim.g.vscode,
		lazy = false,
		keys = {
			{ "<leader>wr", "<cmd>AutoSession restore<CR>", desc = "Session restore" },
			{ "<leader>ws", "<cmd>AutoSession save<CR>", desc = "Session save" },
			{ "<leader>wa", "<cmd>AutoSession toggle<CR>", desc = "Toggle autosave" },
			{ "<leader>sf", "<cmd>AutoSession search<CR>", desc = "Session search" },
		},
		opts = {
			lazy_support = true,
			auto_save = true,
			auto_restore = true,
			auto_create = true,
			auto_restore_last_session = false,
			git_use_branch_name = true,
			root_dir = vim.fn.stdpath("data") .. "/sessions/",

			-- 1. Add "globals" here so vim.g. variables are saved in the session file
			vim.opt.sessionoptions:append("globals"),

			suppressed_dirs = { "~/", "/", "~/Downloads", "~/tmp" },

			session_lens = {
				buftypes_to_ignore = { "nofile", "quickfix" },
				load_on_setup = true,
				theme_conf = { border = true },
				previewer = false,
			},

			-- 2. Use pre_save_cmds to save Tmux info into a Global Variable
			pre_save_cmds = {
				function()
					-- Only run if inside tmux
					if not os.getenv("TMUX") then
						return
					end

					-- Get the Tmux Session Name
					local out = vim.fn.systemlist("tmux display-message -p '#S' 2>/dev/null")
					if out and out[1] then
						-- Save it to a global variable. 'mksession' will save this variable to the file.
						vim.g.AutoSessionTmux = out[1]
					end
				end,
				-- "Neotree close" -- (Optional) Close tree before save
			},

			-- 3. Use post_restore_cmds to read that Global Variable and switch Tmux
			post_restore_cmds = {
				function()
					-- Read the variable we saved earlier
					local tmux_session = vim.g.AutoSessionTmux

					-- If no session data or not in tmux, exit
					if not tmux_session or not os.getenv("TMUX") then
						return
					end

					-- Notify user (optional)
					-- vim.notify("Restoring Tmux session: " .. tmux_session, vim.log.levels.INFO)

					-- Attempt to switch tmux client
					-- We use schedule to ensure UI is ready
					vim.schedule(function()
						local cmd = string.format("tmux switch-client -t %s", vim.fn.shellescape(tmux_session))
						local ok = pcall(vim.fn.system, cmd)
						if not ok then
							vim.notify("Could not switch to tmux session: " .. tmux_session, vim.log.levels.WARN)
						end
					end)

					-- Clear the var so it doesn't persist if we manually save later without tmux
					vim.g.AutoSessionTmux = nil
				end,
				-- "Neotree filesystem show" -- (Optional) Reopen tree
			},
		},
	},
}
