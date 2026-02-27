return {
	"stevearc/conform.nvim",
	name = "conform",
	event = "VeryLazy",
	cmd = { "ConformInfo" },
	keys = { { "<leader>gf", mode = { "n", "v" }, desc = "Format buffer" } },
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			go = { "gofmt" },
			rust = { "rustfmt" },
			javascript = { "eslint_d", "prettier" },
			typescript = { "prettier" },
			javascriptreact = { "prettier" },
			typescriptreact = { "prettier" },
			css = { "prettier" },
			html = { "prettier" },
			json = { "prettier" },
			yaml = { "prettier" },
			markdown = { "prettier" },
			bash = { "shfmt" },
			sql = { "sleek" },
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
			timeout_ms = 1000,
			lsp_fallback = true,
		},
	},
	config = function(_, opts)
		local conform = require("conform")
		conform.setup(opts)
		local has_fidget, fidget = pcall(require, "fidget")
		local function format_with_progress(async)
			-- If fidget is not installed, just format normally
			if not has_fidget then
				has_fidget, fidget = pcall(require, "fidget")
				if not has_fidget then
					conform.format({ async = async, opts.format_on_save })
					return
				end
			end

			-- Create the spinner
			local task = fidget.progress.handle.create({
				title = "Formatting",
				message = "In progress...",
				lsp_client = { name = "Conform" },
			})

			conform.format({
				async = async,
				lsp_fallback = true,
				timeout_ms = 1000,
			}, function(err)
				task:report({ message = err and "Failed" or "Done" })
				task:finish()
			end)
		end

		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*",
			callback = function()
				format_with_progress(false)
			end,
		})
		vim.keymap.set({ "n", "v" }, "<leader>gf", function()
			format_with_progress(true)
		end, { desc = "Format buffer with Progress" })
	end,
}
