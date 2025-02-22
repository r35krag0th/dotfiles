local wezterm = require("wezterm")
local utils = require("r35.utils")
local sessionizer = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer.wezterm")

local M = {}

-- Sessionizer (Default) Keybinds:
-- <ALT-a> => select from active workspaces
-- <ALT-s> => show sessionizer
-- <ALT-m> => jump to previous workspace

M.keys = {}
M.config = {
	command_options = {
		-- Uses a wrapper that only returns the basename of the discovered directory
		-- BUG: This doesn't work :(  It uses the name as the PWD.  Need to need about a smater way to do this.
		-- fd_path = string.format("%s/.local/bin/wrap-fd", wezterm.home_dir),
		--
		fd_path = "/opt/homebrew/bin/fd",
		max_depth = 2,
		-- {//} returns the parent directory of the discovered directory
		format = "{//}",
	},
	paths = {
		-- Search in the follow standard directories
		wezterm.home_dir .. "/workspace/personal",
		wezterm.home_dir .. "/.local/share",
		wezterm.home_dir .. "/notes",
	},
}

function M.apply_to_config(c)
	wezterm.log_info("Loading r35.configs.sessionizer")
	sessionizer.apply_to_config(c)
	sessionizer.config = M.config
	utils.append_all(c.keys, M.keys)
	return c
end

return M
