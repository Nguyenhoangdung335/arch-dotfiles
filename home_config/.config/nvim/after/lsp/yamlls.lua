return {
	---@type vim.lsp.Config
	settings = {
		yaml = {
			schemaStore = {
				enable = false,
				url = "https://www.schemastore.org/api/json/catalog.json",
			},
			schemas = {
				["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/v1.32.1-standalone-strict/all.json"] = "/*.k8s.yaml",
				["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose.yml",
				["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
				["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
				["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/**/*.{yml,yaml}",
				["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
				["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
				["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
				["http://json.schemastore.org/circleciconfig"] = ".circleci/**/*.{yml,yaml}",
			},
			validate = true,
			hover = true,
			completion = true,
			format = { enabled = true },
		},
	},
}
