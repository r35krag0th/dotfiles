-- [ r35krag0th/dotfiles ]
local wezterm = require("wezterm")
local config = wezterm.config_builder()
--
local r35_core = require("r35.configs.core")
local r35_bar = require("r35.configs.bar")
local r35_sessionizer = require("r35.configs.sessionizer")
local r35_utils = require("r35.utils")

r35_core.apply_to_config(config)
r35_bar.apply_to_config(config)
r35_sessionizer.apply_to_config(config)

return config
