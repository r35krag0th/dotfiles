-- r35/devices/streamdeck.lua -- owns hs.streamdeck.init, the module's single
-- discovery callback slot.
local log = require("r35.log")

local M = {}

-- The disconnect callback hands back a deck object that may already be dead, so
-- we record the serial at CONNECT time and look it up on disconnect rather than
-- calling deck:serialNumber() on a possibly-invalid object.
--
-- Deliberately a STRONG table: weak keys would let the entry be collected at
-- precisely the moment of unplug, which is when we need it. Entries are removed
-- explicitly on disconnect instead.
local serials = {}
local lastSerial = nil

local function serialFor(deck)
  -- Identity lookup is EXPECTED to hit: hs.streamdeck is believed to hand back
  -- the same userdata object on disconnect as on connect. That belief is
  -- user-reported and hedged ("seems to be the same thing"), not
  -- independently verified -- this module's start() has never been exercised
  -- against live hardware. Because that assumption is unconfirmed, the
  -- lastSerial fallback below exists precisely so a lookup miss still
  -- degrades to a correct answer for the one-deck case this configuration
  -- drives, rather than failing outright.
  local known = serials[deck]
  if known then return known end
  -- If identity ever fails, fall back to the most recent connect. Sound because
  -- this configuration drives exactly one deck; revisit if that changes.
  -- NOTE: do NOT "fall back" by scanning the table for `obj == deck` -- that is
  -- literally the same comparison the direct lookup already made.
  return lastSerial
end

function M.start(registry)
  hs.streamdeck.init(function(isConnected, deck)
    if isConnected then
      local serial = deck:serialNumber()
      serials[deck] = serial
      lastSerial = serial

      -- buttonLayout() returns TWO values (columns, rows). Bind both explicitly
      -- so neither is silently swallowed by a surrounding call.
      local columns, rows = deck:buttonLayout()
      log.info("StreamDeck", string.format("connected serial=%s layout=%dx%d",
        serial, columns, rows))

      registry:announce("streamdeck", deck)
      registry:announce("streamdeck:" .. serial, deck)
    else
      local serial = serialFor(deck)
      log.info("StreamDeck", string.format("disconnected serial=%s", tostring(serial)))
      registry:revoke("streamdeck")
      if serial then registry:revoke("streamdeck:" .. serial) end
      serials[deck] = nil
    end
  end)
end

return M
