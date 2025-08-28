local wezterm = require("wezterm")
local utils = require("r35.utils")

local M = {}

local keys = {
	{ key = "l", mods = "ALT", action = wezterm.action.ShowLauncherArgs({ flags = "LAUNCH_MENU_ITEMS" }) },
	-- Splitting Bindings
	{ key = "h", mods = "LEADER", action = wezterm.action.SplitHorizontal },
	{ key = "v", mods = "LEADER", action = wezterm.action.SplitVertical },
	{ key = "h", mods = "ALT", action = wezterm.action.SplitHorizontal },
	{ key = "v", mods = "ALT", action = wezterm.action.SplitVertical },
	-- Pane motions
	{ key = "r", mods = "LEADER", action = wezterm.action.RotatePanes("CounterClockwise") },
	{ key = "R", mods = "LEADER", action = wezterm.action.RotatePanes("Clockwise") },
	{ key = "z", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },
	{ key = "f", mods = "LEADER", action = wezterm.action.ToggleFullScreen },
	-- Pane Resize
	{ key = "UpArrow", mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Up", 5 }) },
	-- { key = "UpArrow", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Up", 10 }) },
	{ key = "DownArrow", mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Down", 5 }) },
	-- { key = "DownArrow", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Down", 10 }) },
	{ key = "LeftArrow", mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Left", 5 }) },
	{ key = "LeftArrow", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Left", 10 }) },
	{ key = "RightArrow", mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Right", 5 }) },
	{ key = "RightArrow", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Right", 10 }) },
}

local font_config = wezterm.font_with_fallback({
	{ family = "PragmataPro VF Mono Liga", scale = 1.0 },
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
	command_palette_bg_color = "#7DCFFF",
	command_palette_fg_color = "#000000",
	command_palette_font_size = 16,
	command_palette_rows = 5,
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
	-- NOTE: I swapped this to run with ALT-b rather than CTRL-b
	leader = {
		key = "b",
		mods = "ALT",
	},
}

function M.apply_to_config(c)
	wezterm.log_info("Loading r35.configs.core")
	c = utils.merge(c, config)
	c.keys = utils.append_all(c.keys, keys)
	wezterm.log_info("Complete - r35.configs.core")
	return c
end

return M
