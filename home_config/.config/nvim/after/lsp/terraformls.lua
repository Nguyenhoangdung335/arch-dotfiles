return {
	cmd = { "terraform-ls", "serve" },
	filetypes = {
		"terraform",
		"terraform-vars",
		"terraform-stack",
		"terraform-deploy",
		"terraform-search",
		"hcl",
	},
	root_markers = { ".terraform", ".git" },
}
