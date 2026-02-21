return {
	{
		-- Core Debugger
		"mfussenegger/nvim-dap",
		cond = not vim.g.vscode,
		dependencies = {
			-- "leoluz/nvim-dap-go",
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
			"nvim-neotest/nvim-nio",
			"williamboman/mason.nvim",
			"jay-babu/mason-nvim-dap.nvim",
		},
		config = function()
			local dap = require("dap")
			local ui = require("dapui")

			ui.setup({
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.25 },
							{ id = "breakpoints", size = 0.25 },
							{ id = "stacks", size = 0.25 },
							{ id = "watches", size = 0.25 },
						},
						position = "left",
						size = 40,
					},
					{
						elements = {
							{ id = "repl", size = 1.0 }, -- Give REPL full width since Console is useless
							-- { id = "console", size = 0.5 }, -- Remove this
						},
						position = "bottom",
						size = 10,
					},
				},
				controls = { enabled = true },
			})

			require("dapui").setup()
			-- require("dap-go").setup()
			require("nvim-dap-virtual-text").setup({})

			local function get_go_build_package()
				-- 1. If currently inside a main.go file, debug ONLY that folder
				--    This fixes the "UI doesn't show up" issue because it mimics standard behavior
				if vim.fn.expand("%:t") == "main.go" then
					return vim.fn.expand("%:p:h")
				end

				-- 2. Search for directories inside ./cmd
				local cwd = vim.fn.getcwd()
				local cmd_dir = cwd .. "/cmd"

				-- Get list of folders inside cmd/ (e.g., cmd/server, cmd/worker)
				-- glob path/* returns full paths
				local subdirs = vim.fn.glob(cmd_dir .. "/*", false, true)

				-- Filter only actual directories
				local choices = {}
				for _, dir in ipairs(subdirs) do
					if vim.fn.isdirectory(dir) == 1 then
						table.insert(choices, dir)
					end
				end

				-- 3. Decision Logic
				if #choices == 0 then
					-- No cmd folder? Default to current working directory
					return vim.fn.input("Path to main package: ", cwd, "file")
				elseif #choices == 1 then
					-- Only one option? Auto-select it (don't annoy user)
					return choices[1]
				else
					-- Multiple options? Build a nice menu
					local menu_items = { "Select entry point to debug:" }
					for i, path in ipairs(choices) do
						-- Extract just the folder name (e.g., "server") from full path
						local name = vim.fn.fnamemodify(path, ":t")
						table.insert(menu_items, string.format("%d. %s", i, name))
					end

					-- Show menu
					local choice = vim.fn.inputlist(menu_items)
					if choice > 0 and choice <= #choices then
						return choices[choice]
					else
						-- User cancelled or typed garbage
						print("Debug cancelled")
						return dap.ABORT
					end
				end
			end

			-- 1. MASON INTEGRATION
			require("mason-nvim-dap").setup({
				ensure_installed = {
					"delve", -- Go
					"codelldb", -- Rust (You need this for your new project!)
				},
				automatic_installation = true,
				handlers = {
					function(config)
						require("mason-nvim-dap").default_setup(config)
					end,
					-- Custom handler for Go (delve)
					delve = function(config)
						table.insert(config.configurations, {
							type = "delve",
							name = "Debug Project (Root)",
							request = "launch",
							program = get_go_build_package,
							-- buildFlags = "-gcflags=all=-N -l",
							cwd = "${workspaceFolder}",
							console = "integratedTerminal",
							outputMode = "remote",
						})
						require("mason-nvim-dap").default_setup(config)
					end,
				},
			})

			-- 2. KEYMAPS
			vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP Continue" })
			vim.keymap.set("n", "<F6>", dap.terminate, { desc = "DAP Terminate" })
			vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "DAP Toggle Breakpoint" })
			vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP Step Over" })
			vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP Step Into" })
			vim.keymap.set("n", "<F12>", dap.step_out, { desc = "DAP Step Out" })
			vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>gb", dap.run_to_cursor, { desc = "Run to Cursor" })

			vim.keymap.set("n", "<leader>?", function()
				require("dapui").eval(nil, { enter = true })
			end)

			vim.keymap.set("n", "<leader>du", ui.toggle, { desc = "DAP UI Toggle" })
			vim.keymap.set("n", "<leader>dr", ui.open, { desc = "DAP UI Open" })
			vim.keymap.set("n", "<leader>dc", ui.close, { desc = "DAP UI Close" })

			-- 3. LISTENERS (Auto open UI)
			dap.listeners.before.attach.dapui_config = function()
				ui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				ui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				ui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				ui.close()
			end

			-- 4. RUST CONFIGURATION (CodeLLDB)
			-- Since you are starting Rust, you need this manual setup for CodeLLDB
			-- because Mason installs it, but sometimes doesn't auto-configure the path perfectly.
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					-- Ensure this path matches where Mason installs codelldb
					command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
					args = { "--port", "${port}" },
				},
			}

			dap.configurations.rust = {
				{
					name = "Rust: Debug Launch",
					type = "codelldb",
					request = "launch",
					program = function()
						-- This asks you to select the executable to debug
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
			}

			-- dap.adapters.delve = function(callback, config)
			-- 	if config.mode == "remote" and config.request == "attach" then
			-- 		callback({
			-- 			type = "server",
			-- 			host = config.host or "127.0.0.1",
			-- 			port = config.port or "38697",
			-- 		})
			-- 	else
			-- 		callback({
			-- 			type = "server",
			-- 			port = "${port}",
			-- 			executable = {
			-- 				command = "dlv",
			-- 				args = { "dap", "-l", "127.0.0.1:${port}", "--log", "--log-output=dap" },
			-- 				detached = vim.fn.has("win32") == 0,
			-- 			},
			-- 		})
			-- 	end
			-- end
		end,
	},
}
