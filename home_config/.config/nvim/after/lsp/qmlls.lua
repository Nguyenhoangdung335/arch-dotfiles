return {
	cmd = {
		"qmlls6",
		"--no-cmake-calls",
		"-I",
		"/usr/lib/qt6/qml",
		"-I",
		"/run/user/1000/quickshell/vfs/5be5eb4850299160e8c13ad899c0b79c",
		"-b",
		"/run/user/1000/quickshell/vfs/5be5eb4850299160e8c13ad899c0b79c",
	},
	root_markers = { ".qmlls.ini", "qmldir", ".git" },
	on_attach = function(client)
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
	end,
	filetypes = { "qml", "qmljs" },
}
