return {
	{
		"olimorris/codecompanion.nvim",
		cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
		version = "^18.0.0",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"MeanderingProgrammer/render-markdown.nvim",

			-- Extensions dependencies
			"ravitemer/mcphub.nvim",
		},
		opts = {
			extensions = {
				custom_ui = {
					enabled = true,
					callback = "modules.codecompanion_ui",
					opts = {
						icons = {
							user = "",
							llm = "",
						},
						metadata = {
							enabled = true,
							placement = "inline", -- "top", "bottom", "inline"
							align = "left",
							padding = 2,
						},
						theme = {
							enabled = true,
							header_fg = "lavender",
							header_bg = "surface1",
							separator_fg = "surface2",
							reasoning_fg = "surface1",
						},
						render_markdown = {
							enabled = true,
							heading = {
								sign = false,
								icons = { "", "", "", "", "", "" },
								border = true,
								border_virtual = true,
								above = "─",
								left_pad = 0,
								right_pad = 0,
								width = "full",
							},
							dash = {
								icon = "─",
								width = "full",
							},
						},
					},
				},
				mcphub = {
					callback = "mcphub.extensions.codecompanion",
					opts = {
						make_vars = true,
						make_slash_commands = true,
						show_result_in_chat = true,
					},
				},
			},
			interactions = {
				chat = {
					adapter = "copilot",
					keymaps = {
						options = {
							modes = { n = "?" },
							callback = "keymaps.options",
							description = "Options",
							hide = true,
						},
						completion = {
							modes = { i = "<C-_>" },
							index = 1,
							callback = "keymaps.completion",
							description = "[Chat] Completion menu",
						},
						send = {
							modes = {
								n = { "<CR>", "<C-s>" },
								i = "<C-s>",
							},
							index = 2,
							callback = "keymaps.send",
							description = "[Request] Send response",
						},
						regenerate = {
							modes = { n = "gr" },
							index = 3,
							callback = "keymaps.regenerate",
							description = "[Request] Regenerate",
						},
						close = {
							modes = {
								n = "<C-c>",
								i = "<C-c>",
							},
							index = 4,
							callback = "keymaps.close",
							description = "[Chat] Close",
						},
						stop = {
							modes = { n = "q" },
							index = 5,
							callback = "keymaps.stop",
							description = "[Request] Stop",
						},
						clear = {
							modes = { n = "gx" },
							index = 6,
							callback = "keymaps.clear",
							description = "[Chat] Clear",
						},
						codeblock = {
							modes = { n = "gc" },
							index = 7,
							callback = "keymaps.codeblock",
							description = "[Chat] Insert codeblock",
						},
						yank_code = {
							modes = { n = "gy" },
							index = 8,
							callback = "keymaps.yank_code",
							description = "[Chat] Yank code",
						},
						buffer_sync_all = {
							modes = { n = "gba" },
							index = 9,
							callback = "keymaps.buffer_sync_all",
							description = "[Chat] Toggle buffer syncing",
						},
						buffer_sync_diff = {
							modes = { n = "gbd" },
							index = 10,
							callback = "keymaps.buffer_sync_diff",
							description = "[Chat] Toggle buffer syncing (diff)",
						},
					},
				},
				background = {
					chat = {
						callback = {
							["on_ready"] = {
								actions = { "interactions.background.builtin.chat_make_title" },
								enabled = true,
							},
						},
						opts = { enabled = true },
					},
				},
				inline = {
					adapter = "copilot",
					keymaps = {
						always_accept = {
							callback = "keymaps.always_accept",
							description = "Always accept changes in this buffer",
							index = 1,
							modes = { n = "gdy" },
							opts = { nowait = true },
						},
						accept_change = {
							callback = "keymaps.accept_change",
							description = "Accept change",
							index = 2,
							modes = { n = "gda" },
							opts = { nowait = true, noremap = true },
						},
						reject_change = {
							callback = "keymaps.reject_change",
							description = "Reject change",
							index = 3,
							modes = { n = "gdr" },
							opts = { nowait = true, noremap = true },
						},
						stop = {
							callback = "keymaps.stop",
							description = "Stop request",
							index = 4,
							modes = { n = "q" },
						},
					},
				},
				agent = { adapter = "copilot" },
			},
			display = {
				action_palette = {
					width = 150,
					height = 10,
					prompt = "Prompt ", -- Prompt used for interactive LLM calls
					provider = "default", -- Can be "default", "telescope", "fzf_lua", "mini_pick" or "snacks". If not specified, the plugin will autodetect installed providers.
					opts = {
						show_preset_actions = true, -- Show the preset actions in the action palette?
						show_preset_prompts = true, -- Show the preset prompts in the action palette?
						show_preset_rules = true, -- Show the preset rules in the action palette?
						title = "CodeCompanion actions", -- The title of the action palette
					},
				},
				chat = {
					opts = {
						completion_provider = "cmp", -- blink|cmp|coc|default
						---Decorate the user message before it's sent to the LLM
						prompt_decorator = function(message, _, _)
							return string.format([[<prompt>%s</prompt>]], message)
						end,
					},
					window = {
						buflisted = false, -- List the chat buffer in the buffer list?
						layout = "vertical", -- float|vertical|horizontal|tab|buffer
						width = 0.4,
						full_height = true,
						position = "left", -- left|right|top|bottom (nil will default depending on vim.opt.splitright|vim.opt.splitbelow)
						border = "rounded", -- none|single|double|shadow|rounded
						relative = "editor",
						opts = {
							breakindent = true,
							linebreak = true,
							wrap = true,
						},
					},
					intro_message = "Welcome to CodeCompanion ✨! Press ? for options",
					separator = "---", -- The separator between the different messages in the chat buffer
					show_header_separator = false, -- We use render-markdown borders to render a divider ABOVE the header
					show_settings = false, -- Show LLM settings at the top of the chat buffer?
					show_token_count = true, -- Show the token count for each response?
					show_tools_processing = true, -- Show the loading message when tools are being executed?
					start_in_insert_mode = false, -- Open the chat buffer in insert mode?
					icons = {
						buffer_sync_all = "󰪴 ",
						buffer_sync_diff = " ",
						chat_context = "📎️",
						chat_fold = " ",
						tool_pending = "  ",
						tool_in_progress = "  ",
						tool_failure = "  ",
						tool_success = "  ",
					},
					fold_reasoning = true,
					show_reasoning = true,
					fold_context = true,
					show_context = true, -- Show context (from slash commands and variables) in the chat buffer?
					token_count = function(tokens) -- The function to display the token count
						return " (" .. tokens .. " tokens)"
					end,
				},
				inline = {
					layout = "vertical", -- vertical|horizontal|buffer
				},
			},
		},
		keys = {
			{
				"<leader>cc",
				"<cmd>CodeCompanionChat Toggle<cr>",
				mode = { "n", "v" },
				desc = "AI Chat (CodeCompanion)",
			},
			{ "<leader>ca", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "Add to AI Chat (CodeCompanion)" },
			{ "<leader>c.", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "AI Actions (CodeCompanion)" },
			{ "<leader>c/", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "AI Inline Edit" },
		},
	},
}
