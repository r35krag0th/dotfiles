local wezterm = require("wezterm")
local config = wezterm.config_builder()
-- local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local sessionizer = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer.wezterm")
sessionizer.apply_to_config(config)

local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
bar.apply_to_config(config, {
	modules = {
		spotify = {
			enabled = true,
			format = " {artist} - {title}",
			interval = 1,
		},
		hostname = {
			enabled = false,
		},
		username = {
			enabled = false,
		},
		pane = { enabled = true, icon = wezterm.nerdfonts.md_dock_window },
	},
})

local home_dir = os.getenv("HOME")
sessionizer.config = {
	command_options = {
		fd_path = "/opt/homebrew/bin/fd",
		max_depth = 2,
		format = "{//}",
	},
	paths = {
		home_dir .. "/workspace/personal",
		home_dir .. "/.local/share",
	},
}

-- https://lospec.com/palette-list/tokyo-night
-- ---------------------------------------------------
-- | #1F2335 | #24283B | #292E42 | #3B4261 | #414868 |
-- | #545C7E | #565F89 | #737AA2 | #A9B1D6 | #C0CAF5 |
-- | #394B70 | #3D59A1 | #7AA2F7 | #7DCFFF | #B4F9F8 |
-- | #BB9AF7 | #9D7CD8 | #FF9E64 | #FFC777 | #C3E88D |
-- | #4FD6BE | #41A6B5 | #FF757F | #C53B53 | #FF007C |
-- ---------------------------------------------------
config.color_scheme = "Tokyo Night"
config.window_frame = {
	font = wezterm.font({ family = "PragmataPro Mono Liga", weight = "Bold" }),
	font_size = 16,
	active_titlebar_bg = "#181825",
	inactive_titlebar_bg = "#181825",
	active_titlebar_border_bottom = "#4fd6be",
	inactive_titlebar_border_bottom = "#c53b53",
	-- Add a window border
	border_left_width = "0.5cell",
	border_right_width = "0.5cell",
	border_bottom_height = "0.25cell",
	border_top_height = "0.25cell",
	border_left_color = "#24283B",
	border_right_color = "#24283B",
	border_bottom_color = "#24283B",
	border_top_color = "#24283B",
}
config.window_padding = {
	left = 8,
	right = 1,
	top = 8,
	bottom = 8,
}
-- config.colors = {}
config.default_prog = {
	"/opt/homebrew/bin/fish",
	"-l",
}
config.tab_bar_at_bottom = true
-- Font Options: https://wezfurlong.org/wezterm/config/fonts.html#font-related-options
config.font = wezterm.font_with_fallback({
	"PragmataPro Mono Liga",
	"Apple Color Emoji",
	"Apple Symbols",
	"Symbols Nerd Font Mono",
})
config.font_shaper = "Harfbuzz"
config.font_size = 18

-- Accepts an array of tables that define 'label' and 'args'
config.launch_menu = {}

-- config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
-- config.integrated_title_buttons = { "Maximize" }

-- tabline.setup({
-- 	options = {
-- 		icons_enabled = true,
-- 		tabs_enabled = true,
-- 		-- theme = "tokyonight",
-- 		section_separators = {
-- 			left = wezterm.nerdfonts.ple_right_half_circle_thick,
-- 			right = wezterm.nerdfonts.ple_left_half_circle_thick,
-- 		},
-- 		component_separators = {
-- 			left = wezterm.nerdfonts.ple_right_half_circle_thin,
-- 			right = wezterm.nerdfonts.ple_left_half_circle_thin,
-- 		},
-- 		tab_separators = {
-- 			left = wezterm.nerdfonts.ple_right_half_circle_thick,
-- 			right = wezterm.nerdfonts.ple_left_half_circle_thick,
-- 		},
-- 		theme_overrides = {
-- 			normal_mode = {
-- 				-- a = { fg = "#E5C07B", bg = "#282C34" },
-- 				a = { fg = "#FFC777", bg = "#282C34" },
-- 				b = { fg = "#FF9E64", bg = "#282C34" },
-- 				-- c = { fg = "#B4F9F8", bg = "#282C34" },
-- 				x = { fg = "#B4F9F8", bg = "#282C34" },
-- 				y = { fg = "#B4F9F8", bg = "#282C34" },
-- 				z = { fg = "#B4F9F8", bg = "#282C34" },
-- 			},
-- 			tab = {
-- 				active = { fg = "#D6D58E", bg = "#005C53" },
-- 				inactive = { fg = "#ABB2BF", bg = "#24283B" },
-- 				inactive_hover = { fg = "#5C6370", bg = "#FFC777" },
-- 			},
-- 		},
-- 	},
-- 	sections = {
-- 		tabline_a = {
-- 			{
-- 				"mode",
-- 				fmt = function(str)
-- 					return str:sub(1, 1)
-- 				end,
-- 			},
-- 		},
-- 		tabline_b = { "workspace" },
-- 		tabline_c = { " " },
-- 		tab_active = {
-- 			"index",
-- 			{ "parent", padding = 0 },
-- 			"/",
-- 			{ "cwd", padding = { left = 0, right = 1 } },
-- 			{ "zoomed", padding = 0 },
-- 		},
-- 		tab_inactive = {
-- 			{ "index", { "process", padding = { left = 0, right = 1 } } },
-- 		},
-- 		tabline_x = {},
-- 		tabline_y = {},
-- 		tabline_z = { "domain" },
-- 	},
-- })

return config
