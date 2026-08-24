local t = require("spec.runner")
local hsFake = require("spec.fake_hs")
_G.hs = hsFake

local clock = require("r35.clock")
local Registry = require("r35.registry")

-- clock is a singleton module (package.loaded caches it), so M._timer state
-- leaks across tests unless each test that exercises start()/stop() gets its
-- own fresh module instance. Re-requiring after clearing package.loaded gives
-- a clean M._timer = nil, same as a first-ever require.
local function freshClock()
  package.loaded["r35.clock"] = nil
  hsFake.reset()
  return require("r35.clock")
end

-- wday is 1=Sunday. 2026-08-21 is a Friday -> wday 6.
local function at(hour, min, opts)
  opts = opts or {}
  return {
    hour = hour, min = min,
    day = opts.day or 21, month = opts.month or 8,
    wday = opts.wday or 6, year = 2026,
  }
end

t.describe("clock.fields", function()
  t.it("formats a typical morning time", function()
    local f = clock.fields(at(11, 2))
    t.assertEquals(f.weekday, "FRI")
    t.assertEquals(f.month, "AUG")
    t.assertEquals(f.day, "21")
    t.assertEquals(f.hour, "11")
    t.assertEquals(f.minute, "02")
    t.assertEquals(f.meridiem, "AM")
  end)

  -- Midnight and noon are where naive hour % 12 arithmetic breaks.
  t.it("renders midnight as 12 AM", function()
    local f = clock.fields(at(0, 0))
    t.assertEquals(f.hour, "12")
    t.assertEquals(f.meridiem, "AM")
  end)

  t.it("renders noon as 12 PM", function()
    local f = clock.fields(at(12, 0))
    t.assertEquals(f.hour, "12")
    t.assertEquals(f.meridiem, "PM")
  end)

  t.it("converts afternoon hours to 12-hour form", function()
    local f = clock.fields(at(13, 5))
    t.assertEquals(f.hour, "01")
    t.assertEquals(f.minute, "05")
    t.assertEquals(f.meridiem, "PM")
  end)

  t.it("zero-pads the hour", function()
    t.assertEquals(clock.fields(at(9, 30)).hour, "09")
  end)

  t.it("does not pad the day of month", function()
    t.assertEquals(clock.fields(at(9, 0, { day = 8 })).day, "8")
  end)

  t.it("uses a fixed weekday table rather than locale formatting", function()
    t.assertEquals(clock.fields(at(9, 0, { wday = 1 })).weekday, "SUN")
    t.assertEquals(clock.fields(at(9, 0, { wday = 7 })).weekday, "SAT")
  end)

  t.it("uses a fixed month table", function()
    t.assertEquals(clock.fields(at(9, 0, { month = 1 })).month, "JAN")
    t.assertEquals(clock.fields(at(9, 0, { month = 12 })).month, "DEC")
  end)
end)

-- Timers created via hs.timer.doEvery survive hs.reload() (verified
-- empirically: a probe timer kept firing at the same rate across a live
-- config reload). The config's own pathwatcher calls hs.reload() on every
-- .lua edit, so an unguarded start() leaks one more 1-second timer per edit --
-- each one independently calling registry:update, unbounded over a session.
t.describe("clock.start / clock.stop", function()
  t.it("stop() on a never-started clock does not error", function()
    local c = freshClock()
    c.stop()
  end)

  t.it("stop() stops the running timer", function()
    local c = freshClock()
    local r = Registry.new()
    c.start(r)
    t.assertEquals(#hsFake._timers, 1)
    t.assertEquals(hsFake._timers[1].stopped, false)

    c.stop()
    t.assertEquals(hsFake._timers[1].stopped, true)
  end)

  t.it("stop() twice does not error", function()
    local c = freshClock()
    local r = Registry.new()
    c.start(r)
    c.stop()
    c.stop()
  end)

  t.it("start() twice leaves exactly one live timer, not two", function()
    local c = freshClock()
    local r = Registry.new()
    c.start(r)
    c.start(r)

    t.assertEquals(#hsFake._timers, 2, "fake records both timer creations")
    local live = 0
    for _, tm in ipairs(hsFake._timers) do
      if not tm.stopped then live = live + 1 end
    end
    t.assertEquals(live, 1, "only the second timer should still be running")
  end)
end)
