local t = require("spec.runner")
local hsFake = require("spec.fake_hs")
_G.hs = hsFake

local Registry = require("r35.registry")
local Deck = require("r35.deck")

-- Stub standing in for r35.icons: records what was drawn instead of doing HTTP.
-- s.fail[index] = true makes the NEXT setButtonIcon call for that index behave
-- like a failed fetch: real r35.icons.setButtonIcon leaves the hardware showing
-- whatever it had before on failure, so the stub mirrors that by invoking the
-- callback with false and deliberately NOT touching s.drawn[index].
local function stubIcons()
  local s = { drawn = {}, calls = 0, fail = {} }
  s.key = function(opts)
    opts = opts or {}
    return tostring(opts.label or "") .. "|" .. tostring(opts.font or "")
  end
  s.setButtonIcon = function(_, index, opts, callback)
    s.calls = s.calls + 1
    callback = callback or function() end
    if s.fail[index] then
      callback(false)
      return
    end
    s.drawn[index] = s.key(opts)
    callback(true)
  end
  return s
end

local function fixture(layout)
  hsFake.reset()
  local r = Registry.new()
  local icons = stubIcons()
  local d = Deck.new(r, layout, icons)
  d:attach("DEVICE")
  return d, icons, r
end

t.describe("deck", function()
  t.it("renders persistent buttons", function()
    local d, icons = fixture({ persistent = { [25] = { icon = { label = "MUTE" } } } })
    d:render()
    t.assertEquals(icons.drawn[25], "MUTE|")
  end)

  t.it("composites a page over the persistent layer", function()
    local d, icons = fixture({ persistent = {
      [25] = { icon = { label = "MUTE" } },
      [1]  = { icon = { label = "CAM"  } },
    } })
    d:setPage({ [1] = { icon = { label = "PLAY" } } })
    d:render()
    t.assertEquals(icons.drawn[1], "PLAY|", "page must win")
    t.assertEquals(icons.drawn[25], "MUTE|", "persistent must survive the page")
  end)

  t.it("suppresses a redundant render", function()
    local d, icons = fixture({ persistent = { [25] = { icon = { label = "MUTE" } } } })
    d:render()
    local first = icons.calls
    d:render()
    t.assertEquals(icons.calls, first, "identical icon key must not redraw")
  end)

  t.it("redraws when the icon key changes", function()
    local label = "A"
    local d, icons = fixture({ persistent = {
      [25] = { icon = function() return { label = label } end },
    } })
    d:render()
    label = "B"
    d:render()
    t.assertEquals(icons.drawn[25], "B|")
  end)

  t.it("invalidate forces a full redraw", function()
    local d, icons = fixture({ persistent = { [25] = { icon = { label = "MUTE" } } } })
    d:render()
    local first = icons.calls
    d:invalidate()
    d:render()
    t.assertEquals(icons.calls, first + 1)
  end)

  t.it("dispatches a press to the button's action", function()
    local fired = false
    local d = fixture({ persistent = {
      [25] = { icon = { label = "MUTE" }, action = function() fired = true end },
    } })
    d:press(25, true)
    t.assertTrue(fired)
  end)

  t.it("ignores the release half of a press", function()
    local count = 0
    local d = fixture({ persistent = {
      [25] = { icon = { label = "M" }, action = function() count = count + 1 end },
    } })
    d:press(25, true)
    d:press(25, false)
    t.assertEquals(count, 1)
  end)

  t.it("tolerates a press on an unmapped button", function()
    local d = fixture({ persistent = {} })
    d:press(7, true)
    t.assertNotNil(d)
  end)

  t.it("isolates a throwing action", function()
    local reached = false
    local d = fixture({ persistent = {
      [1] = { icon = { label = "X" }, action = function() error("boom") end },
      [2] = { icon = { label = "Y" }, action = function() reached = true end },
    } })
    d:press(1, true)
    d:press(2, true)
    t.assertTrue(reached)
  end)

  t.it("renders only the requested indices when filtered", function()
    local d, icons = fixture({ persistent = {
      [1] = { icon = { label = "A" } },
      [2] = { icon = { label = "B" } },
    } })
    d:render({ [1] = true })
    t.assertEquals(icons.drawn[1], "A|")
    t.assertNil(icons.drawn[2])
  end)
end)

-- bind() is the entire mechanism behind every dynamic button in the live
-- config (clock tiles watching "clock:minute", the camera indicator
-- watching "camera:...", the mic indicator watching "audio.in:default").
-- If it silently regressed to rendering the whole deck instead of just the
-- watching button(s), the deck would still repaint on every event -- nothing
-- would look broken until you noticed the "suppresses a redundant render"
-- cost had come back for every watched key. These tests use the real
-- Registry (not a stub) so they exercise the actual wiring, not an idea of it.
t.describe("deck bind()", function()
  t.it("a changed event on a watched key renders only the watching button", function()
    local labelA, labelB = "A0", "B0"
    local d, icons, r = fixture({ persistent = {
      [1] = { icon = function() return { label = labelA } end, watch = { "clock:minute" } },
      [2] = { icon = function() return { label = labelB } end },
    } })
    d:bind()
    d:render()
    t.assertEquals(icons.drawn[1], "A0|")
    t.assertEquals(icons.drawn[2], "B0|")

    labelA, labelB = "A1", "B1"
    r:update("clock:minute", "TICK")

    t.assertEquals(icons.drawn[1], "A1|", "watching button must redraw")
    t.assertEquals(icons.drawn[2], "B0|", "non-watching button must not redraw")
  end)

  t.it("two buttons watching the same key both render when it fires", function()
    local labelA, labelB, labelC = "A0", "B0", "C0"
    local d, icons, r = fixture({ persistent = {
      [1] = { icon = function() return { label = labelA } end, watch = { "clock:minute" } },
      [2] = { icon = function() return { label = labelB } end, watch = { "clock:minute" } },
      [3] = { icon = function() return { label = labelC } end },
    } })
    d:bind()
    d:render()

    labelA, labelB, labelC = "A1", "B1", "C1"
    r:update("clock:minute", "TICK")

    t.assertEquals(icons.drawn[1], "A1|", "first co-watcher must redraw")
    t.assertEquals(icons.drawn[2], "B1|", "second co-watcher must redraw")
    t.assertEquals(icons.drawn[3], "C0|", "unwatched button must not redraw")
  end)

  t.it("one button watching two different keys renders when either fires", function()
    local label = "L0"
    local d, icons, r = fixture({ persistent = {
      [1] = { icon = function() return { label = label } end,
              watch = { "clock:minute", "camera:isInUse" } },
    } })
    d:bind()
    d:render()
    t.assertEquals(icons.drawn[1], "L0|")

    label = "L1"
    r:update("clock:minute", "TICK")
    t.assertEquals(icons.drawn[1], "L1|", "first watched key must trigger a render")

    label = "L2"
    r:update("camera:isInUse", "CAM")
    t.assertEquals(icons.drawn[1], "L2|", "second watched key must also trigger a render")
  end)

  t.it("a button with no watch field is never rendered by bind()-driven events", function()
    local labelWatched, labelUnwatched = "W0", "U0"
    local d, icons, r = fixture({ persistent = {
      [1] = { icon = function() return { label = labelWatched } end, watch = { "clock:minute" } },
      [2] = { icon = function() return { label = labelUnwatched } end },
    } })
    d:bind()
    d:render()

    labelUnwatched = "U1"
    r:update("clock:minute", "TICK")
    t.assertEquals(icons.drawn[2], "U0|", "unwatched button must not redraw on a changed event")

    labelUnwatched = "U2"
    r:announce("clock:minute", "TICK2")
    t.assertEquals(icons.drawn[2], "U0|", "unwatched button must not redraw on an available event")
  end)

  t.it("available triggers a render too, not only changed", function()
    local label = "V0"
    local d, icons, r = fixture({ persistent = {
      [1] = { icon = function() return { label = label } end, watch = { "camera:cam1" } },
      [2] = { icon = { label = "STATIC" } },
    } })
    d:bind()
    d:render()

    label = "V1"
    r:announce("camera:cam1", "CAM")

    t.assertEquals(icons.drawn[1], "V1|", "available must trigger a render, not only changed")
    t.assertEquals(icons.drawn[2], "STATIC|")
  end)

  -- Finding 1: bind() wired only "changed" and "available", never "lost".
  -- registry:revoke(...) (called by r35/devices/camera.lua and
  -- r35/devices/audio.lua when hardware disappears) emits "lost" -- with no
  -- subscriber, the watching button's icon function never re-runs, so it
  -- stays frozen on its last drawn image (e.g. the camera tile's MISSING
  -- branch becomes unreachable after the first render).
  t.it("a lost event on a watched key re-renders that button", function()
    local label = "M0"
    local d, icons, r = fixture({ persistent = {
      [1] = { icon = function() return { label = label } end, watch = { "camera:cam1" } },
      [2] = { icon = { label = "STATIC" } },
    } })
    d:bind()
    r:announce("camera:cam1", "CAM")
    d:render()
    t.assertEquals(icons.drawn[1], "M0|")

    label = "MISSING"
    r:revoke("camera:cam1")

    t.assertEquals(icons.drawn[1], "MISSING|", "lost must trigger a render, same as changed/available")
    t.assertEquals(icons.drawn[2], "STATIC|", "non-watching button must not redraw")
  end)
end)

-- Both defects below are in the ORIGINAL Task 7 code (the brief's design),
-- not introduced by the bind() fix round. Both are live-relevant: the icon
-- service restarts on config changes (a fetch can fail mid-flight), and the
-- camera tile's icon function calls into a device object that can die when
-- the camera disconnects (an icon function can throw).
t.describe("deck render() robustness", function()
  -- Finding 1: Deck:render marked a button's key as "current" the instant it
  -- decided to redraw, before the (genuinely async) fetch had even resolved.
  -- r35.icons.setButtonIcon deliberately leaves the hardware showing the OLD
  -- image on failure -- so a single failed fetch left the cache claiming a
  -- key that was never actually drawn, and every later identical render saw
  -- a "matching" key and silently suppressed the redraw forever.
  t.it("retries after a failed icon fetch instead of caching the stale key", function()
    local d, icons = fixture({ persistent = { [25] = { icon = { label = "MUTE" } } } })
    icons.fail[25] = true

    d:render()
    t.assertNil(icons.drawn[25], "a failed fetch must not update what the hardware shows")

    icons.fail[25] = false
    d:render()
    t.assertEquals(icons.drawn[25], "MUTE|",
      "the next render must retry rather than treating the never-drawn key as already current")
  end)

  -- Finding 2: Deck:render's call into iconSpec (and thus a button's `icon`
  -- function) was unprotected, unlike press()'s action dispatch. One
  -- throwing icon function aborted the whole pairs() loop mid-pass, so every
  -- button ordered after it in that (nondeterministic) iteration never
  -- rendered. d:render() itself would throw here under the unfixed code --
  -- this test fails outright (not merely a wrong assertion) against it,
  -- regardless of pairs() iteration order, because pairs() always visits
  -- both indices within the one render() call.
  t.it("isolates a throwing icon function so other buttons still render", function()
    local d, icons = fixture({ persistent = {
      [1] = { icon = function() error("camera boom") end },
      [2] = { icon = { label = "OK" } },
    } })
    d:render()
    t.assertEquals(icons.drawn[2], "OK|",
      "a healthy button must still render even though a sibling's icon function throws")
  end)
end)
