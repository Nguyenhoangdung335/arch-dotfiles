return {
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "windwp/nvim-ts-autotag", -- Handles HTML and React components perfectly
        },
        config = function()
            local npairs = require("nvim-autopairs")
            local Rule = require("nvim-autopairs.rule")

            npairs.setup({
                disable_filetype = { "text" },
                ignored_next_char = "[%w%(%[%{]",
                map_cr = true,
                map_c_w = true,
                check_ts = true,
                ts_config = {
                    lua = { "string", "source" },                 -- Don't pair inside Lua strings
                    javascript = { "string", "template_string" }, -- Don't pair inside JS strings
                },
                fast_wrap = {
                    map = "<M-e>", -- Press Alt+e to trigger fast wrap
                    chars = { "{", "[", "(", '"', "'", "`" },
                    pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
                    offset = 0,
                    end_key = "$",
                    keys = "qwertyuiopzxcvbnmasdfghjkl",
                    check_comma = true,
                    highlight = "PmenuSel",
                    highlight_grey = "LineNr"
                },
            })
            npairs.add_rules({
                Rule("```", "```", { "markdown", "rmd", "md" })
            })
            require("nvim-ts-autotag").setup({
                opts = {
                    enable_close = true,
                    enable_rename = true,
                    enable_close_on_slash = false,
                }
            })
        end,
    }
}
--[[ return {
    {
        "m4xshen/autoclose.nvim",
        opts = {
            keys = {
                ["("] = { escape = false, close = true, pair = "()" },
                ["["] = { escape = false, close = true, pair = "[]" },
                ["{"] = { escape = false, close = true, pair = "{}" },

                [">"] = { escape = true, close = false, pair = "<>" },
                [")"] = { escape = true, close = false, pair = "()" },
                ["]"] = { escape = true, close = false, pair = "[]" },
                ["}"] = { escape = true, close = false, pair = "{}" },

                ['"'] = { escape = true, close = true, pair = '""' },
                ["'"] = { escape = true, close = true, pair = "''" },
                ["`"] = { escape = true, close = true, pair = "``" },
            },
            options = {
                disable_when_touch = true,
                pair_spaces = true,
                disabled_filetypes = { "text" },
                touch_regex = "[%w(%[{]",
                auto_indent = true,
                disable_command_mode = false
            },
        },
        config = function(_, opts)
            require("autoclose").setup(opts)
        end,
    }
} ]]
