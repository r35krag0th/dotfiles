local wezterm = require("wezterm")
local utils = require("r35.utils")

local M = {}

local keys = {
	{ key = "l", mods = "ALT", action = wezterm.action.ShowLauncherArgs({ flags = "LAUNCH_MENU_ITEMS" }) },
	{ key = "h", mods = "LEADER", action = wezterm.action.SplitHorizontal },
	{ key = "v", mods = "LEADER", action = wezterm.action.SplitVertical },
	{ key = "r", mods = "LEADER", action = wezterm.action.RotatePanes("CounterClockwise") },
	{ key = "R", mods = "LEADER", action = wezterm.action.RotatePanes("Clockwise") },
	{ key = "z", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },
	{ key = "f", mods = "LEADER", action = wezterm.action.ToggleFullScreen },
	{ key = "]", mods = "CMD|SHIFT", action = wezterm.action.ToggleAlwaysOnTop },
	{ key = "UpArrow", mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Up", 5 }) },
	{ key = "DownArrow", mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Down", 5 }) },
	{ key = "LeftArrow", mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Left", 5 }) },
	{ key = "RightArrow", mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Right", 5 }) },
	{ key = "LeftArrow", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Left", 10 }) },
	{ key = "RightArrow", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Right", 10 }) },
}

local font_config = wezterm.font_with_fallback({
	{ family = "PragmataPro Mono", scale = 1.0 },
	-- { family = "0xProto Nerd Font", scale = 1.0 },
	{ family = "FiraMono Nerd Font", scale = 1.0 },
	{ family = "Apple Color Emoji", scale = 1.0 },
	{ family = "Apple Symbols", scale = 1.0 },
	{ family = "Symbols Nerd Font", scale = 1.0 },
	{ family = "Symbols Nerd Font Mono", scale = 1.0 },
})

local config = {
	color_scheme = "Tokyo Night",
	window_padding = {
		left = 8,
		right = 1,
		top = 8,
		bottom = 8,
	},
	default_prog = {
		"/opt/homebrew/bin/fish",
		"-l",
	},
	font = font_config,
	font_shaper = "Harfbuzz",
	font_size = 18,
	ssh_domains = {
		{
			name = "murozond",
			remote_address = "murozond.r35.network",
			username = "bobsaska",
		},
	},
}

function M.apply_to_config(c)
	wezterm.log_info("Loading r35.configs.core")
	c = utils.merge(c, config)
	utils.append_all(c.keys, keys)
	return c
end

return M
