local wezterm = require("wezterm")
local utils = require("r35.utils")
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")

local M = {}

M.config = {
	modules = {
		spotify = {
			enabled = false,
			format = " {artist} - {title}",
		},
		hostname = {
			enabled = false,
		},
		username = {
			enabled = false,
		},
		pane = { enabled = true, icon = wezterm.nerdfonts.md_dock_window },
	},
}

M.keys = {}

function M.apply_to_config(c)
	wezterm.log_info("Loading r35.configs.bar")
	bar.apply_to_config(c, M.config)
	utils.append_all(c.keys, M.keys)
	return c
end

return M
