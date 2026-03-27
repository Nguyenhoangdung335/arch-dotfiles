return {
	{
		-- Core Debugger
		"mfussenegger/nvim-dap",
		cond = not vim.g.vscode and not vim.g.is_termux,
		dependencies = {
			-- UI
			{
				"rcarriga/nvim-dap-ui",
				dependencies = { "nvim-neotest/nvim-nio" },
				opts = {
					controls = { enabled = true },
					mappings = {
						expand = { "<CR>", "<2-LeftMouse>" },
						open = "o",
						remove = "d",
						edit = "e",
						repl = "r",
						toggle = "t",
					},
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
								{ id = "repl", size = 1.0 },
								{ id = "console", size = 0.5 },
							},
							position = "bottom",
							size = 12,
						},
					},
				},
				config = function(_, opts)
					local dap = require("dap")
					local dapui = require("dapui")
					dapui.setup(opts)

					dap.listeners.before.attach.dapui_config = function()
						dapui.open()
					end
					dap.listeners.before.launch.dapui_config = function()
						dapui.open()
					end
					dap.listeners.before.event_terminated.dapui_config = function()
						dapui.close()
					end
					dap.listeners.before.event_exited.dapui_config = function()
						dapui.close()
					end
				end,
			},
			-- Virtual Text
			{
				"theHamsta/nvim-dap-virtual-text",
				opts = {
					enabled = true,
					enable_commands = true,
					highlight_changed_variables = true,
					highlight_new_as_changed = false,
					show_stop_reason = true,
					commented = false,
				},
			},
			-- Mason Integration
			{
				"jay-babu/mason-nvim-dap.nvim",
				dependencies = { "williamboman/mason.nvim" },
				opts = {
					ensure_installed = { "delve", "codelldb" },
					automatic_installation = true,
					handlers = {
						function(config)
							require("mason-nvim-dap").default_setup(config)
						end,
						delve = function(config)
							table.insert(config.configurations, {
								type = "delve",
								name = "Debug Project (Root)",
								request = "launch",
								program = require("modules.dap_go").get_build_package,
								cwd = "${workspaceFolder}",
								console = "integratedTerminal",
								outputMode = "remote",
							})
							require("mason-nvim-dap").default_setup(config)
						end,
					},
				},
			},
		},
		keys = {
			{
				"<F5>",
				function()
					require("dap").continue()
				end,
				desc = "DAP Continue",
			},
			{
				"<F6>",
				function()
					require("dap").terminate()
				end,
				desc = "DAP Terminate",
			},
			{
				"<F10>",
				function()
					require("dap").step_over()
				end,
				desc = "DAP Step Over",
			},
			{
				"<F11>",
				function()
					require("dap").step_into()
				end,
				desc = "DAP Step Into",
			},
			{
				"<F12>",
				function()
					require("dap").step_out()
				end,
				desc = "DAP Step Out",
			},
			{
				"<leader>gb",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "Run to Cursor",
			},
			{
				"<leader>?",
				function()
					require("dapui").eval(nil, { enter = true, context = "repl", width = 0.5, height = 0.5 })
				end,
				desc = "DAP Eval",
			},
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "DAP UI Toggle",
			},
			{
				"<leader>dr",
				function()
					require("dapui").open()
				end,
				desc = "DAP UI Open",
			},
			{
				"<leader>dc",
				function()
					require("dapui").close()
				end,
				desc = "DAP UI Close",
			},
		},
		config = function()
			local dap = require("dap")

			vim.fn.sign_define(
				"DapBreakpoint",
				{ text = "🛑", texthl = "DiagnosticSignError", linehl = "", numhl = "" }
			)
			vim.fn.sign_define(
				"DapStopped",
				{ text = "➡️", texthl = "DiagnosticSignWarn", linehl = "Visual", numhl = "DiagnosticSignWarn" }
			)
			vim.fn.sign_define(
				"DapBreakpointRejected",
				{ text = "⚠️", texthl = "DiagnosticSignWarn", linehl = "", numhl = "" }
			)

			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
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
						return coroutine.create(function(dap_run_co)
							-- Add slight delay to ensure UI renders properly in coroutine
							vim.schedule(function()
								vim.ui.input({
									prompt = "Path to executable: ",
									default = vim.fn.getcwd() .. "/target/debug/",
									completion = "file",
								}, function(input)
									coroutine.resume(dap_run_co, input or require("dap").ABORT)
								end)
							end)
						end)
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					env = function()
						local variables = vim.fn.environ()
						-- default to debug logging
						variables["RUST_LOG"] = "debug"
						return variables
					end,
				},
			}
		end,
	},
	-- Persistent Breakpoints
	{
		"Weissle/persistent-breakpoints.nvim",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			load_breakpoints_event = { "BufReadPost", "BufNewFile" },
			always_reload = true,
		},
		config = function(_, opts)
			require("persistent-breakpoints").setup(opts)
		end,
		keys = {
			{
				"<leader>bb",
				function()
					require("persistent-breakpoints.api").toggle_breakpoint()
				end,
				desc = "Toggle Breakpoint",
				mode = "n",
				noremap = true,
			},
			{
				"<leader>bc",
				function()
					require("persistent-breakpoints.api").clear_all_breakpoints()
				end,
				desc = "Clear Breakpoints",
				mode = "n",
				noremap = true,
			},
		},
	},
}
