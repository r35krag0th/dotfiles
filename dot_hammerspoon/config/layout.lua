-- config/layout.lua -- THE editing surface. Button data, not code.
--
-- Stream Deck XL grid:
--    1  2  3  4  5  6  7  8
--    9 10 11 12 13 14 15 16
--   17 18 19 20 21 22 23 24
--   25 26 27 28 29 30 31 32
local a = require("r35.actions")
local clock = require("r35.clock")

local TEAMS = "com.microsoft.teams2"

-- Per-field label colours, matching the user's previous setup: the date group
-- reads blue (weekday lighter than month/day), the time group white, and the
-- meridiem green so AM/PM is distinguishable at a glance from the digits.
local CLOCK_COLORS = {
	weekday = "4FADF5",
	month = "2050E8",
	day = "2050E8",
	hour = "FFFFFF",
	minute = "FFFFFF",
	meridiem = "A4FC4E",
}

-- Shared styling for the six clock tiles.
local function clockTile(field)
	return {
		icon = function(registry)
			local f = registry:get("clock:minute") or clock.fields()
			return {
				label = f[field],
				-- Two sizes, deliberately. WIDTH is the binding constraint here, not
				-- height: Aldrich's digits are wider than they are tall, so the tile's
				-- vertical space cannot be filled without overflowing horizontally.
				-- Measured against a 96px tile (usable ~90px):
				--   3-char ("FRI"): 44 -> 73px   52 -> 86px   56 -> 92px  OVERFLOWS
				--   2-char ("48"):  64 -> 83px   68 -> 88px   72 -> 94px  OVERFLOWS
				-- Hence 44 for the 3-character tiles and 64 for the 2-character ones.
				-- Do not collapse these into one value -- a single size either wastes
				-- the number tiles or clips the weekday and month.
				label_size = (field == "weekday" or field == "month") and 44 or 64,
				label_color = CLOCK_COLORS[field] or "F4F4F4",
				bg_color = "000000",
				font = "display",
				weight = "Black", -- Orbitron is variable (400-900); the approved design is Black
				glyph = "0000", -- no glyph; .notdef renders as nothing
			}
		end,
		watch = { "clock:minute" },
	}
end

return {
	persistent = {
		-- Camera in-use indicator.
		[1] = {
			icon = function(registry)
				local cam = registry:get("camera:r35-iPhone17.Pro.Max Camera")
				-- Absent almost always means the iPhone hit its 3-day idle auto-lock and
				-- needs a passcode -- an action, not an error, so the label says what to
				-- DO. Other causes (phone elsewhere, Wi-Fi off, Continuity Camera
				-- disabled) look identical from here; macOS exposes no way to tell them
				-- apart. Amber rather than red: red is reserved for IN USE, which is the
				-- genuinely urgent state.
				if cam == nil then
					return {
						glyph = "F1A15",
						glyph_color = "1A1A1A",
						bg_color = "EBBD5F",
						label = "UNLOCK",
						label_color = "1A1A1A",
						label_size = 18,
					}
				end
				if cam:isInUse() then
					return {
						glyph = "F0100",
						glyph_color = "F4F4F4",
						bg_color = "C23E26",
						label = "IN USE!",
						label_color = "FFFFFF",
						label_size = 18,
					}
				end
				return {
					glyph = "F05DF",
					glyph_color = "6A994E",
					bg_color = "000000",
					label = "√ SAFE",
					label_color = "FFFFFF",
					label_size = 18,
				}
			end,
			watch = { "camera:r35-iPhone17.Pro.Max Camera" },
			-- The indicator is also the control. Note the two are not the same thing:
			-- the icon reflects the HARDWARE camera (in use by any app), while this
			-- toggles TEAMS' video. They agree whenever Teams is what is using the
			-- camera, which is the normal case, but something else grabbing it would
			-- show red while Teams video stays off.
			action = a.sendTo(TEAMS, { "cmd", "shift" }, "o", "MS Teams: Toggle Video"),
		},

		-- Microphone activity indicator. NOT a mute indicator: Teams mutes in-app
		-- and never touches CoreAudio, and the Scarlett reports muted(),
		-- inputMuted() and outputMuted() as nil. inUse() is the only honest signal.
		[9] = {
			icon = function(registry)
				local dev = registry:get("audio.in:default")
				local live = dev ~= nil and dev:inUse()
				return {
					glyph = live and "F036C" or "F036D",
					glyph_color = live and "C23E26" or "6A994E",
					bg_color = "000000",
					label = live and "MIC LIVE" or "MIC IDLE",
					label_color = "FFFFFF",
					label_size = 16,
				}
			end,
			watch = { "audio.in:default" },
		},

		-- Hammerspoon's own API docs, opened in the default browser. Neutral
		-- placement away from both the Teams call-control cluster (row 4) and
		-- the clock (row 3) -- this button has nothing to do with either.
		-- F03CC (mdi "open-in-new") over a Chrome logo or a plain document
		-- glyph: it reads as "leaves this app for a link", which is what the
		-- action actually does, rather than implying a specific browser.
		[12] = {
			icon = {
				glyph = "F03CC",
				glyph_color = "4EADE1",
				bg_color = "000000",
				label = "DOCS",
				label_color = "FFFFFF",
				label_size = 18,
			},
			action = a.openURL("https://www.hammerspoon.org/docs/", "Hammerspoon Docs"),
		},

		-- Toast / pre-call actions. Microsoft Teams has NO keyboard shortcuts for
		-- reactions, so the five decorative reaction buttons that lived here were
		-- replaced with shortcuts that actually exist.
		[3] = {
			icon = {
				glyph = "F03F7",
				glyph_color = "6A994E",
				bg_color = "000000",
				label = "JOIN",
				label_color = "FFFFFF",
				label_size = 18,
			},
			action = a.sendTo(TEAMS, { "cmd", "shift" }, "j", "MS Teams: Join Meeting"),
		},
		-- ACCEPT and DECLINE sit adjacent deliberately: when a call is ringing you
		-- are not reading labels carefully.
		--
		-- CAVEAT: Teams binds cmd+shift+a to BOTH "accept video call" and "toggle
		-- live captions", resolving it by context. The user keeps captions on
		-- permanently, so pressing this mid-meeting would turn OFF something they
		-- always want on. Press again to restore.
		[4] = {
			icon = {
				glyph = "F03F2",
				glyph_color = "6A994E",
				bg_color = "000000",
				label = "ACCEPT",
				label_color = "FFFFFF",
				label_size = 16,
			},
			action = a.sendTo(TEAMS, { "cmd", "shift" }, "a", "MS Teams: Accept Call"),
		},
		[6] = {
			icon = {
				glyph = "F0B58",
				glyph_color = "4EADE1",
				bg_color = "000000",
				label = "ADMIT",
				label_color = "FFFFFF",
				label_size = 18,
			},
			action = a.sendTo(TEAMS, { "cmd", "shift" }, "y", "MS Teams: Admit from Lobby"),
		},
		[5] = {
			icon = {
				glyph = "F03F5",
				glyph_color = "C23E26",
				bg_color = "000000",
				label = "DECLINE",
				label_color = "FFFFFF",
				label_size = 15,
			},
			action = a.sendTo(TEAMS, { "cmd", "shift" }, "d", "MS Teams: Decline Call"),
		},

		-- Clock: date group 17-19, time group 22-24.
		[17] = clockTile("weekday"),
		[18] = clockTile("month"),
		[19] = clockTile("day"),
		[22] = clockTile("hour"),
		[23] = clockTile("minute"),
		[24] = clockTile("meridiem"),

		-- Call controls.
		[25] = {
			icon = {
				glyph = "f131",
				glyph_color = "464EB8",
				bg_color = "000000",
				label = "MUTE",
				label_color = "FFFFFF",
				label_size = 18,
			},
			action = a.sendTo(TEAMS, { "cmd", "shift" }, "m", "MS Teams: Toggle Mute"),
		},
		[26] = {
			icon = {
				glyph = "F037A",
				glyph_color = "4EADE1",
				bg_color = "000000",
				label = "SHARE",
				label_color = "FFFFFF",
				label_size = 18,
			},
			action = a.sendTo(TEAMS, { "cmd", "shift" }, "e", "MS Teams: Share Tray"),
		},
		[27] = {
			icon = {
				glyph = "0000",
				bg_color = "000000",
				label = "BLUR",
				label_color = "D1B48F",
				label_size = 34,
			},
			action = a.sendTo(TEAMS, { "cmd", "shift" }, "p", "MS Teams: Background Blur"),
		},
		[29] = {
			icon = {
				glyph = "F0A4F",
				glyph_color = "EBBD5F",
				bg_color = "000000",
				label = "RAISE",
				label_color = "FFFFFF",
				label_size = 18,
			},
			action = a.sendTo(TEAMS, { "cmd", "shift" }, "k", "MS Teams: Raise/Lower Hand"),
		},
		[32] = {
			icon = {
				glyph = "F0A48",
				glyph_color = "FFFFFF",
				bg_color = "FF0000",
				label = "LEAVE",
				label_color = "FFFFFF",
				label_size = 18,
			},
			action = a.sendTo(TEAMS, { "cmd", "shift" }, "h", "MS Teams: Leave Call"),
		},
	},

	-- Keyboard chords bound to the same actions the buttons use.
	hotkeys = {
		-- {
		-- 	mods = { "rightctrl" },
		-- 	key = "m",
		-- 	bundleID = TEAMS,
		-- 	to = { { "cmd", "shift" }, "m" },
		-- 	desc = "MS Teams: Toggle Mute",
		-- },
		-- {
		-- 	mods = { "rightctrl" },
		-- 	key = "h",
		-- 	bundleID = TEAMS,
		-- 	to = { { "cmd", "shift" }, "k" },
		-- 	desc = "MS Teams: Raise/Lower Hand",
		-- },
		-- {
		-- 	mods = { "rightctrl" },
		-- 	key = "end",
		-- 	bundleID = TEAMS,
		-- 	to = { { "cmd", "shift" }, "h" },
		-- 	desc = "MS Teams: Leave Call",
		-- },
	},
}
