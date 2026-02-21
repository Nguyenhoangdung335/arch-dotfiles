return {}
-- return {
--     {
--         "nvimtools/none-ls.nvim",
--         dependencies = {
--             "nvim-lua/plenary.nvim",
--         },
--         config = function()
--             local null_ls = require("null-ls")

--             null_ls.setup({
--                 sources = {
--                     -- FORMATTING
--                     null_ls.builtins.formatting.stylua,
--                     null_ls.builtins.formatting.prettier,
--                     null_ls.builtins.formatting.shfmt,

--                     -- DIAGNOSTICS
--                     -- null_ls.builtins.diagnostics.eslint_d, -- Don't know if this works or not
--                     null_ls.builtins.diagnostics.buf,
--                     null_ls.builtins.diagnostics.trivy,

--                     --[[
-- 					-- COMPLETION
-- 					null_ls.builtins.completion.spell,
-- 					null_ls.builtins.completion.luasnip,
-- 					null_ls.builtins.completion.nvim_snippets,
--                     ]]

--                     -- CODE_ACTIONS
--                     null_ls.builtins.code_actions.gitsigns,
--                 },
--             })

--             vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
--         end,
--     },
-- }
