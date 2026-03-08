local M = {}

M.default_opts = {
	icons = {
		user = "🚀 ",
		llm = "✨ ",
	},
	metadata = {
		enabled = true,
		placement = "inline", -- "top", "bottom", "inline" (inline means next to the last header)
		align = "left", -- "right" or "left" (when placement is inline)
		padding = 2, -- number of spaces before metadata
		-- Allows the user to construct the chunks dynamically
		format_chunks = function(metadata, bufnr)
			local chunks = {}

			local buf_name = vim.api.nvim_buf_get_name(bufnr)
			if buf_name and buf_name ~= "" then
				local title = vim.fn.fnamemodify(buf_name, ":t")
				if title ~= "" then
					table.insert(chunks, { " 󰭹 " .. title, "Title" })
				end
			end

			-- Debug print all adapter metadata
			if metadata then
				vim.notify(vim.inspect(metadata))
			end

			if metadata.adapter and metadata.adapter.name then
				table.insert(chunks, { " 󰚩 " .. metadata.adapter.name, "CodeCompanionChatInfo" })
			end
			if metadata.adapter and metadata.adapter.model then
				table.insert(chunks, { "  " .. metadata.adapter.model, "CodeCompanionChatInfo" })
			end
			if metadata.tokens and metadata.tokens > 0 then
				table.insert(chunks, { " 󰔡 " .. tostring(metadata.tokens), "CodeCompanionChatTokens" })
			end

			if chunks then
				vim.notify(vim.inspect(chunks))
			end
			return chunks
		end,
	},
	theme = {
		enabled = true,
		header_fg = "lavender", -- using catppuccin color names
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
}

-- =========================================================================
-- METADATA RENDERING
-- =========================================================================

--- Renders metadata virtual text chunks in the CodeCompanion buffer
---@param bufnr number The buffer number
---@param metadata_opts table The metadata configuration options
local function render_metadata(bufnr, metadata_opts)
	if not metadata_opts.enabled then
		return
	end
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	if vim.bo[bufnr].filetype ~= "codecompanion" then
		return
	end

	---@diagnostic disable-next-line: undefined-field
	local metadata = _G.codecompanion_chat_metadata and _G.codecompanion_chat_metadata[bufnr]
	if not metadata then
		return
	end

	local ns_id = vim.api.nvim_create_namespace("codecompanion_ui_metadata")
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	local chunks = {}
	if type(metadata_opts.format_chunks) == "function" then
		chunks = metadata_opts.format_chunks(metadata, bufnr)
	end

	if not chunks or #chunks == 0 then
		return
	end

	-- Add configured padding
	local padding_str = string.rep(" ", metadata_opts.padding or 2)
	table.insert(chunks, 1, { padding_str, "Normal" })

	if metadata_opts.placement == "top" then
		vim.api.nvim_buf_set_extmark(bufnr, ns_id, 0, 0, {
			virt_text = chunks,
			virt_text_pos = "right_align",
			hl_mode = "combine",
			priority = 110,
		})
	elseif metadata_opts.placement == "bottom" then
		local line_count = vim.api.nvim_buf_line_count(bufnr)
		if line_count > 0 then
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_count - 1, 0, {
				virt_text = chunks,
				virt_text_pos = "right_align",
				hl_mode = "combine",
				priority = 110,
			})
		end
	elseif metadata_opts.placement == "inline" then
		-- Use tree-sitter to find the last atx_heading (Markdown header).
		-- This is used to place the metadata inline right next to the header.
		local parser = vim.treesitter.get_parser(bufnr, "markdown")
		if parser then
			local tree = parser:parse()[1]
			local root = tree:root()
			local query = vim.treesitter.query.get("markdown", "tokens")
			if query then
				local header
				for id, node in query:iter_captures(root, bufnr, 0, -1) do
					if query.captures[id] == "role" then
						header = node
					end
				end

				if header then
					local _, _, end_row, _ = header:range()
					local pos = (metadata_opts.align == "left") and "eol" or "right_align"
					vim.api.nvim_buf_set_extmark(bufnr, ns_id, end_row - 1, 0, {
						virt_text = chunks,
						virt_text_pos = pos,
						hl_mode = "combine",
						priority = 110,
					})
				end
			end
		end
	end
end

-- =========================================================================
-- REASONING BLOCK HIGHLIGHTING
-- =========================================================================

--- Parses the markdown buffer using tree-sitter to find reasoning blocks and applies custom highlights
---@param bufnr number The buffer number
local function apply_reasoning_hl(bufnr)
	-- Query matches the content section under an H3 heading named "Reasoning"
	local query_str = [[
		(section
		  (atx_heading
		    (atx_h3_marker)
		    heading_content: (_) @block_name
		  )
		  (#eq? @block_name "Reasoning")
		  (_) @content
		)
	]]
	local ok, reasoning_query = pcall(vim.treesitter.query.parse, "markdown", query_str)

	if not ok or not reasoning_query then
		return
	end
	if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	if vim.bo[bufnr].filetype ~= "codecompanion" then
		return
	end

	local reasoning_ns = vim.api.nvim_create_namespace("CodeCompanion_Reasoning_HL")

	-- Schedule to ensure buffer text is ready and not mutating during event emission
	vim.schedule(function()
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end

		vim.api.nvim_buf_clear_namespace(bufnr, reasoning_ns, 0, -1)
		local parser = vim.treesitter.get_parser(bufnr, "markdown")
		if not parser then
			return
		end

		local tree = parser:parse()[1]
		local root = tree:root()

		for id, node in reasoning_query:iter_captures(root, bufnr, 0, -1) do
			if reasoning_query.captures[id] == "content" then
				local start_row, start_col, end_row, end_col = node:range()
				if start_row ~= end_row or start_col ~= end_col then
					vim.api.nvim_buf_set_extmark(bufnr, reasoning_ns, start_row, start_col, {
						end_row = end_row,
						end_col = end_col,
						hl_group = "CodeCompanionChatReasoning",
						hl_mode = "combine",
					})
				end
			end
		end
	end)
end

-- =========================================================================
-- MODULE SETUP FUNCTIONS
-- =========================================================================

--- Dynamically injects the configuration overrides into render-markdown plugin
local function setup_render_markdown(opts)
	if not opts.render_markdown.enabled then
		return
	end

	local rm_ok, rm = pcall(require, "render-markdown")
	if not rm_ok then
		return
	end

	local state_ok, rm_state = pcall(require, "render-markdown.state")
	if not (state_ok and rm_state and rm_state.config) then
		return
	end

	-- Construct the custom filetype backgrounds based on theme settings
	local backgrounds = {}
	for _ = 1, 6 do
		table.insert(backgrounds, "CodeCompanionChatHeader")
	end

	local cc_override = {
		heading = {
			sign = opts.render_markdown.heading.sign,
			icons = opts.render_markdown.heading.icons,
			backgrounds = backgrounds,
			border = opts.render_markdown.heading.border,
			border_virtual = opts.render_markdown.heading.border_virtual,
			above = opts.render_markdown.heading.above,
			left_pad = opts.render_markdown.heading.left_pad,
			right_pad = opts.render_markdown.heading.right_pad,
			width = opts.render_markdown.heading.width,
		},
		dash = {
			icon = opts.render_markdown.dash.icon,
			highlight = "CodeCompanionChatSeparator",
			width = opts.render_markdown.dash.width,
		},
	}

	-- Create a deepcopy of the full config and inject our override securely to prevent overwriting
	-- user configuration like `anti_conceal` or other global markdown states
	local current_config = vim.deepcopy(rm_state.config)
	current_config.overrides = current_config.overrides or {}
	current_config.overrides.filetype = current_config.overrides.filetype or {}
	current_config.overrides.filetype.codecompanion = cc_override

	-- Call setup with the newly updated full config
	rm.setup(current_config)
end

--- Dynamically resolves catppuccin colors and injects them as highlight groups
local function setup_theme(opts)
	if not opts.theme.enabled then
		return
	end

	-- We can manually setup the highlights so they immediately take effect,
	-- and then create an autocmd to re-apply them if colorscheme changes.
	local function apply_highlights()
		local cat_ok, cat_palettes = pcall(require, "catppuccin.palettes")
		if cat_ok then
			local flavor = require("catppuccin").flavour or "mocha"
			local colors = cat_palettes.get_palette(flavor)
			if colors then
				vim.api.nvim_set_hl(0, "CodeCompanionChatHeader", {
					fg = colors[opts.theme.header_fg] or colors.lavender,
					bg = colors[opts.theme.header_bg] or colors.surface1,
					bold = true,
				})
				vim.api.nvim_set_hl(0, "CodeCompanionChatSeparator", {
					fg = colors[opts.theme.separator_fg] or colors.surface2,
					bold = true,
				})
				vim.api.nvim_set_hl(0, "CodeCompanionChatReasoning", {
					fg = colors[opts.theme.reasoning_fg] or colors.surface1,
					italic = true,
				})
			end
		end
	end

	-- Apply now
	apply_highlights()

	-- Apply on ColorScheme changes
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("CodeCompanionThemeOverrides", { clear = true }),
		callback = apply_highlights,
	})
end

--- Overrides CodeCompanion internal formatters for clean custom UI rendering
local function setup_overrides(opts, cc_ui, cc_helpers, cc_config)
	-- OVERRIDE THE RENDERER (format_header)
	---@diagnostic disable-next-line: unused-local
	cc_ui.format_header = function(self, role)
		local icon = ""

		-- Determine if the role is user or LLM
		local user_role = cc_config.interactions.chat.roles.user
		if type(role) == "string" and string.match(role, vim.pesc(user_role)) then
			icon = opts.icons.user
		else
			icon = opts.icons.llm
		end

		-- We always use H2 level now, because we removed layout option
		local hashes = "##"
		-- Append a colon to give it a clean '**User:**' feel instead of a block header
		local header = string.format("%s %s%s:", hashes, icon, role)

		if cc_config.display.chat.show_header_separator then
			header = string.format("%s %s", header, cc_config.display.chat.separator)
		end

		return header
	end

	-- OVERRIDE THE HELPER (format_role)
	local orig_format_role = cc_helpers.format_role
	cc_helpers.format_role = function(role)
		-- Safety check in case CodeCompanion passes nil
		if not role then
			return role
		end

		-- Let the original function handle stripping header separators
		local formatted = orig_format_role(role)

		-- Ensure we have a string to run gsub on before stripping icons
		if type(formatted) == "string" then
			formatted = string.gsub(formatted, vim.pesc(opts.icons.user), "")
			formatted = string.gsub(formatted, vim.pesc(opts.icons.llm), "")
			formatted = string.gsub(formatted, ":$", "") -- strip the appended colon
			return vim.trim(formatted)
		end

		return formatted
	end
end

--- Sets up the autocmds for metadata virtual text rendering and reasoning block highlights
local function setup_metadata_and_reasoning(opts, cc_config)
	if not opts.metadata or not opts.metadata.enabled then
		return
	end

	-- Disable CodeCompanion's built-in token display so they don't overlap/clash with ours
	cc_config.display.chat.show_token_count = false

	local group = vim.api.nvim_create_augroup("CodeCompanionUI_Metadata", { clear = true })

	-- Metadata event triggers
	vim.api.nvim_create_autocmd("User", {
		pattern = {
			"CodeCompanionChatOpened",
			"CodeCompanionChatAdapter",
			"CodeCompanionChatModel",
			"CodeCompanionRequestFinished",
			"CodeCompanionChatDone",
		},
		group = group,
		callback = function(args)
			local data = args.data
			local bufnr = (data and data.bufnr) or args.buf
			if not bufnr then
				return
			end

			-- Schedule to ensure the metadata object has been updated and buffer is ready
			vim.schedule(function()
				render_metadata(bufnr, opts.metadata)
			end)
		end,
	})

	-- Also run whenever text changes (useful for 'bottom' placement when lines are added dynamically)
	if opts.metadata.placement == "bottom" then
		vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
			group = group,
			callback = function(args)
				if vim.bo[args.buf].filetype == "codecompanion" then
					render_metadata(args.buf, opts.metadata)
				end
			end,
		})
	end

	-- Reasoning Event Triggers
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		callback = function(args)
			apply_reasoning_hl(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = {
			"CodeCompanionChatOpened",
			"CodeCompanionRequestFinished",
			"CodeCompanionChatDone",
		},
		callback = function(args)
			local bufnr = (args.data and args.data.bufnr) or args.buf
			apply_reasoning_hl(bufnr)
		end,
	})
end

-- =========================================================================
-- MAIN SETUP
-- =========================================================================

function M.setup(opts)
	opts = vim.tbl_deep_extend("force", M.default_opts, opts or {})

	-- 1. Safely load CodeCompanion modules
	local ok, cc_ui = pcall(require, "codecompanion.interactions.chat.ui")
	local ok_helpers, cc_helpers = pcall(require, "codecompanion.interactions.chat.helpers")
	if not ok or not ok_helpers then
		vim.notify("CodeCompanion UI/Helpers module not found", vim.log.levels.WARN)
		return
	end

	local cc_config = require("codecompanion.config")

	-- 2. Execute discrete setup functions
	setup_render_markdown(opts)
	setup_theme(opts)
	setup_overrides(opts, cc_ui, cc_helpers, cc_config)
	setup_metadata_and_reasoning(opts, cc_config)
end

return M
