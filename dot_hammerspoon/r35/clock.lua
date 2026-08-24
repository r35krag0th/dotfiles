-- r35/clock.lua -- clock fields plus the clock:minute pseudo-device.
local M = {}

-- Fixed tables rather than os.date("%a")/("%b"): those are locale-dependent, and
-- a machine with a non-English locale would silently render the wrong strings.
local WDAY  = { "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT" }
local MONTH = { "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                "JUL", "AUG", "SEP", "OCT", "NOV", "DEC" }

function M.fields(t)
  t = t or os.date("*t")
  local hour12 = t.hour % 12
  if hour12 == 0 then hour12 = 12 end
  return {
    weekday  = WDAY[t.wday],
    month    = MONTH[t.month],
    day      = tostring(t.day),
    hour     = string.format("%02d", hour12),
    minute   = string.format("%02d", t.min),
    meridiem = t.hour < 12 and "AM" or "PM",
  }
end

local KEY = "clock:minute"

-- Stops the running timer, if any. Safe to call when nothing is running --
-- it is a no-op in that case, not an error.
function M.stop()
  if M._timer then
    M._timer:stop()
    M._timer = nil
  end
end

-- Poll every second but emit only when a displayed value actually changes.
-- Cheaper and more robust than aligning a timer to the minute boundary, which
-- drifts across sleep/wake.
--
-- hs.reload() destroys the entire Lua state, including any timer created via
-- hs.timer.doEvery -- there is no cross-reload accumulation for M.stop() to
-- guard against. (See init.lua's shutdownCallback comment for how this was
-- verified: a real pathwatcher-driven reload, not
-- `open -g hammerspoon://reloadConfig`, which this config never listens for.)
--
-- Stopping any previous timer before creating a new one still matters for
-- the case that actually exists: start() called twice within a single Lua
-- state (e.g. a bug in caller code, or a future re-init path) would
-- otherwise leave two 1-second timers running concurrently, each
-- independently calling registry:update -- duplicate renders for as long as
-- that one state lives. Idempotency closes that off no matter how many times
-- start() is called.
function M.start(registry)
  M.stop()

  local fields = M.fields()
  local last = table.concat({ fields.hour, fields.minute, fields.meridiem,
                              fields.day, fields.month, fields.weekday }, "|")
  registry:announce(KEY, fields)

  M._timer = hs.timer.doEvery(1, function()
    local f = M.fields()
    local stamp = table.concat({ f.hour, f.minute, f.meridiem,
                                 f.day, f.month, f.weekday }, "|")
    if stamp ~= last then
      last = stamp
      registry:update(KEY, f)
    end
  end)
end

return M
