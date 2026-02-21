return {
	"stevearc/conform.nvim",
	name = "conform",
	event = { "BufWritePre" }, -- Run on save
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>gf",
			mode = { "n", "v" },
			desc = "Format buffer",
		},
	},
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			go = { "gofmt" },
			rust = { "rustfmt" },
			javascript = { "prettier" },
			typescript = { "prettier" },
			javascriptreact = { "prettier" },
			typescriptreact = { "prettier" },
			css = { "prettier" },
			html = { "prettier" },
			json = { "prettier" },
			yaml = { "prettier" },
			markdown = { "prettier", "cbfmt" },
			bash = { "shfmt" },
			-- sql = { "sqruff" },
			sql = { "postgres-language-server" },
			svg = { "prettier_svg" },
			xml = { "xmlformat" },
			qml = { "qmlformat" },
		},
		formatters = {
			prettier_svg = {
				command = "prettier",
				args = { "--stdin-filepath", "$FILENAME", "--parser", "html" },
			},
			qmlformat = {
				command = "qmlformat",
				args = { "-" }, -- read from stdin
				stdin = true,
			},
		},
		-- This will format on save
		format_on_save = {
			timeout_ms = 500,
			lsp_fallback = true,
		},
	},
	config = function(_, opts)
		local conform = require("conform")
		conform.setup(opts)

		-- OPTIONAL: Customize the notification behavior
		-- Since you have Fidget handling vim.notify, you don't need complex logic here.
		-- Conform calls vim.notify on errors by default.

		-- RE-ADDING YOUR CUSTOM WRAPPER
		-- This is still the best way to get a Visual Spinner for Conform
		vim.keymap.set({ "n", "v" }, "<leader>gf", function()
			local has_fidget, fidget = pcall(require, "fidget")

			-- If fidget is not installed, just format normally
			if not has_fidget then
				conform.format({ async = true, lsp_fallback = true })
				return
			end

			-- Create the spinner
			local task = fidget.progress.handle.create({
				title = "Formatting",
				message = "In progress...",
				lsp_client = { name = "Conform" },
			})

			conform.format({
				async = true,
				lsp_fallback = true,
			}, function(err)
				-- 3. Update the text and finish the task
				if err then
					-- On error, report the failure message
					task:report({ message = "Failed" })
				else
					-- On success, update the message to "Done"
					task:report({ message = "Done" })
				end

				task:finish()
			end)
		end, { desc = "Format buffer with Progress" })
	end,
	--[[ config = function()
		local conform = require("conform")
		local fidget_ok, fidget = pcall(require, "fidget")

		conform.setup({
			formatters_by_ft = {
				lua = { "stylua" },
				go = { "gofmt" },
				rust = { "rustfmt", lsp_format = "fallback" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				bash = { "shfmt" },
				-- sql = { "sqruff" },
				sql = { "postgres-language-server" },
				svg = { "prettier_svg" },
				xml = { "xmlformat" },
				qml = { "qmlformat" },
			},
			formatters = {
				prettier_svg = {
					command = "prettier",
					args = { "--stdin-filepath", "$FILENAME", "--parser", "html" },
				},
				qmlformat = {
					command = "qmlformat",
					args = { "-" }, -- read from stdin
					stdin = true,
				},
			},
			-- This will format on save
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
		})

		-- Helper wrapper to show progress with fidget
		local function format_with_fidget(opts)
			if fidget_ok then
				local task = fidget.progress.handle.create({
					title = "Formatting",
					message = "Running formatter...",
					language = vim.bo.filetype,
				})

				conform.format(vim.tbl_extend("force", opts or {}, {
					async = true,
					lsp_fallback = true,
					callback = function()
						task:finish({ message = "Done" })
					end,
				}))
			else
				-- fallback if fidget not installed
				conform.format(opts)
			end
		end

		-- Keymap for manual format
		vim.keymap.set({ "n", "v" }, "<leader>gf", function()
			format_with_fidget()
		end, { desc = "Format buffer" })

		-- -- Override auto format on save to also show progress
		-- vim.api.nvim_create_autocmd("BufWritePre", {
		-- 	callback = function(args)
		-- 		format_with_fidget({ bufnr = args.buf })
		-- 	end,
		-- })
	end, ]]
}
