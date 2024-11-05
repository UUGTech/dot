return {
	"williamboman/mason.nvim",
	cmd = {
		"Mason",
		"MasonInstall",
		"MasonUninstall",
		"MasonUninstallAll",
		"MasonLog",
		"MasonUpdate",
		"MasonUpdateAll",
	},
	opts = {
		ui = {
			icons = {
				package_installed = "✓",
				package_uninstalled = "✗",
				package_pending = "⟳",
			},
		},
	},
	build = ":MasonUpdate",
}
