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
			jsonc = { "prettier" },
			yaml = { "prettier" },
			markdown = { "prettier" },
			bash = { "shfmt" },
			sql = { "sleek" },
			svg = { "prettier_svg" },
			xml = { "xmlformat" },
			qml = { "qmlformat" },
			qmljs = { "prettierd", "prettier", stop_after_first = true },
		},
		formatters = {
			prettier_svg = {
				command = "prettier",
				args = { "--stdin-filepath", "$FILENAME", "--parser", "html" },
			},
			qmlformat = {
				command = "qmlformat6",
				args = {
					"-i",
					"-n",
					"-w",
					"2",
					"--objects-spacing",
					"--functions-spacing",
					"--group-attributes-together",
					"--single-line-empty-objects",
					"--semicolon-rule",
					"always",
					"$FILENAME",
				},
				stdin = false,
			},
		},
	},
	config = function(_, opts)
		local conform = require("conform")
		conform.setup(opts)

		local function format_with_progress(async)
			-- Get the specific buffer we are formatting
			local bufnr = vim.api.nvim_get_current_buf()

			-- ==============================================
			-- QMLJS Pragma Hiding Logic
			-- ==============================================
			local is_qmljs = vim.bo[bufnr].filetype == "qmljs"
			local has_pragma = false
			local lines_to_remove = 0

			if is_qmljs then
				local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""

				-- Match ".pragma library" even if it has trailing spaces/tabs
				if first_line:match("^%.pragma library%s*$") then
					has_pragma = true
					lines_to_remove = 1 -- The pragma line itself

					-- Greedily check for subsequent empty/whitespace-only lines
					local total_lines = vim.api.nvim_buf_line_count(bufnr)
					for i = 1, total_lines - 1 do
						local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1]
						if line and line:match("^%s*$") then
							lines_to_remove = lines_to_remove + 1
						else
							-- Stop at the first line that contains actual code
							break
						end
					end

					-- Remove the entire block (pragma + trailing spaces/newlines)
					vim.api.nvim_buf_set_lines(bufnr, 0, lines_to_remove, false, {})
				end
			end
			-- =========================================================

			local has_fidget, fidget = pcall(require, "fidget")
			local task = nil

			-- Only create the fidget spinner if fidget is installed
			if has_fidget then
				task = fidget.progress.handle.create({
					title = "Formatting",
					message = "In progress...",
					lsp_client = { name = "Conform" },
				})
			end

			conform.format({
				bufnr = bufnr,
				async = async,
				lsp_fallback = true,
				timeout_ms = 1000,
			}, function(err)
				-- ==============================================
				-- Restore the Pragma Line
				-- ==============================================
				-- We do this inside the callback to guarantee it goes back
				-- exactly when Conform finishes, whether it succeeds or fails.
				if has_pragma then
					vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { ".pragma library", "" })
				end

				-- Complete the Fidget task if it exists
				if task then
					task:report({ message = err and "Failed" or "Done" })
					task:finish()
				end
			end)
		end

		-- Format on save
		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*",
			callback = function()
				-- Must be false (synchronous) so it finishes before writing to disk
				format_with_progress(false)
			end,
		})

		-- Manual format keymap
		vim.keymap.set({ "n", "v" }, "<leader>gf", function()
			format_with_progress(true)
		end, { desc = "Format buffer with Progress" })
	end,
}
