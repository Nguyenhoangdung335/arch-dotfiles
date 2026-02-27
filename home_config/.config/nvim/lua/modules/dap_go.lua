local M = {}

function M.get_build_package()
	return coroutine.create(function(dap_run_co)
		local cwd = vim.fn.getcwd()

		-- 1. If currently inside a main.go file, offer to debug just this folder first
		if vim.fn.expand("%:t") == "main.go" then
			coroutine.resume(dap_run_co, vim.fn.expand("%:p:h"))
			return
		end

		-- 2. Dynamically find all main.go files in the project
		local find_cmd
		if vim.fn.executable("rg") == 1 then
			find_cmd = { "rg", "--files", "--glob", "main.go" }
		elseif vim.fn.executable("fd") == 1 then
			find_cmd = { "fd", "^main\\.go$" }
		elseif vim.fn.executable("git") == 1 and vim.fn.isdirectory(".git") == 1 then
			find_cmd = { "git", "ls-files", "*/main.go", "main.go" }
		elseif vim.fn.executable("find") == 1 then
			find_cmd = {
				"find",
				".",
				"-name",
				"main.go",
				"-not",
				"-path",
				"*/node_modules/*",
				"-not",
				"-path",
				"*/.git/*",
				"-not",
				"-path",
				"*/vendor/*",
			}
		end

		local choices = {}

		if find_cmd then
			local obj = vim.system(find_cmd, { text = true }):wait()
			vim.notify(obj.stdout)
			if obj.code == 0 and obj.stdout then
				for line in obj.stdout:gmatch("[^\r\n]+") do
					vim.notify("line 1:" .. line)
					line = line:gsub("^%./", "")
					vim.notify("line 2:" .. line)
					local dir = vim.fn.fnamemodify(cwd .. "/" .. line, ":h")
					vim.notify("dir:" .. dir)
					table.insert(choices, dir)
				end
			end
		else
			local files = vim.fn.globpath(cwd, "**/main.go", false, true)
			for _, file in ipairs(files) do
				table.insert(choices, vim.fn.fnamemodify(file, ":h"))
			end
		end

		for _, dir in ipairs(choices) do
			vim.notify(dir, vim.log.levels.INFO)
		end

		local seen = {}
		local unique_choices = {}
		for _, dir in ipairs(choices) do
			if not seen[dir] then
				seen[dir] = true
				table.insert(unique_choices, dir)
			end
		end
		choices = unique_choices

		-- Ensure vim.ui calls are scheduled so they execute properly in Neovim's event loop
		vim.schedule(function()
			if #choices == 0 then
				vim.ui.input({
					prompt = "No main.go found. Path to main package: ",
					default = cwd,
					completion = "file",
				}, function(input)
					coroutine.resume(dap_run_co, input or require("dap").ABORT)
				end)
			elseif #choices == 1 then
				coroutine.resume(dap_run_co, choices[1])
			else
				vim.ui.select(choices, {
					prompt = "Select Go entry point to debug",
					format_item = function(item)
						local rel_path = vim.fn.fnamemodify(item, ":~:.")
						return rel_path == "." and "(Project Root)" or rel_path
					end,
				}, function(choice)
					coroutine.resume(dap_run_co, choice or require("dap").ABORT)
				end)
			end
		end)
	end)
end

return M
