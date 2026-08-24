local t = require("spec.runner")
local hsFake = require("spec.fake_hs")
_G.hs = hsFake

local Registry = require("r35.registry")
local log = require("r35.log")

local function fresh()
  hsFake.reset()
  return Registry.new()
end

t.describe("registry", function()
  -- D1 regression: the original doUntil ran the action while the device was
  -- ABSENT and stopped the moment it appeared. Both directions must work now.
  t.it("fires whenAvailable registered BEFORE the device appears", function()
    local r = fresh()
    local got = nil
    r:whenAvailable("streamdeck", function(d) got = d end)
    t.assertNil(got, "must not fire before announce")
    r:announce("streamdeck", "DECK")
    t.assertEquals(got, "DECK")
  end)

  t.it("fires whenAvailable registered AFTER the device appears", function()
    local r = fresh()
    r:announce("streamdeck", "DECK")
    local got = nil
    r:whenAvailable("streamdeck", function(d) got = d end)
    t.assertNil(got, "must be async, not synchronous")
    hsFake.flush()
    t.assertEquals(got, "DECK")
  end)

  t.it("dispatches asynchronously even when already available", function()
    local r = fresh()
    r:announce("streamdeck", "DECK")
    r:whenAvailable("streamdeck", function() end)
    t.assertEquals(hsFake.pendingCount(), 1, "must queue, never call inline")
  end)

  t.it("fires whenAvailable exactly once across reconnects", function()
    local r = fresh()
    local calls = 0
    r:whenAvailable("streamdeck", function() calls = calls + 1 end)
    r:announce("streamdeck", "DECK")
    r:revoke("streamdeck")
    r:announce("streamdeck", "DECK")
    hsFake.flush()
    t.assertEquals(calls, 1)
  end)

  -- Finding 1 regression: `update` on a key that was never announced must
  -- still drain the pending whenAvailable queue. Before the fix, only
  -- `announce` performed the nil -> non-nil drain, so a `whenAvailable`
  -- handler registered while the device was absent would be stranded forever
  -- if the device's first appearance came through `update` instead of
  -- `announce`.
  t.it("update on an unannounced key still drains pending whenAvailable handlers", function()
    local r = fresh()
    local got = nil
    r:whenAvailable("cam", function(d) got = d end)
    r:update("cam", "CAM")
    t.assertEquals(got, "CAM", "update transitioning nil->device must drain pending queue same as announce")
  end)

  t.it("fires on(available) on EVERY reconnect", function()
    local r = fresh()
    local calls = 0
    r:on("streamdeck", "available", function() calls = calls + 1 end)
    r:announce("streamdeck", "DECK")
    r:revoke("streamdeck")
    r:announce("streamdeck", "DECK")
    t.assertEquals(calls, 2, "replugged hardware returns blank; must re-render")
  end)

  t.it("fans out to multiple listeners", function()
    local r = fresh()
    local a, b = 0, 0
    r:on("cam", "changed", function() a = a + 1 end)
    r:on("cam", "changed", function() b = b + 1 end)
    r:announce("cam", "CAM")
    r:update("cam", "CAM")
    t.assertEquals(a, 1)
    t.assertEquals(b, 1)
  end)

  -- D9 regression
  t.it("isolates a throwing handler from its siblings", function()
    local r = fresh()
    local reached = false
    r:on("cam", "changed", function() error("boom") end)
    r:on("cam", "changed", function() reached = true end)
    r:announce("cam", "CAM")

    -- This throw is deliberate: silence log.error around it so the expected
    -- diagnostic doesn't print a traceback indistinguishable from a genuine
    -- production error into test output -- that trains a reader to wave real
    -- Registry errors away as "just the boom test". Restored immediately
    -- after, in this test only; production code is untouched.
    local realLogError = log.error
    log.error = function() end
    local ok = pcall(function() r:update("cam", "CAM") end)
    log.error = realLogError

    t.assertTrue(ok, "update must not raise even though a sibling handler throws")
    t.assertTrue(reached, "a throwing handler must not abort the chain")
  end)

  t.it("emits lost and clears the device", function()
    local r = fresh()
    local lost = false
    r:on("deck", "lost", function() lost = true end)
    r:announce("deck", "DECK")
    r:revoke("deck")
    t.assertTrue(lost)
    t.assertNil(r:get("deck"))
  end)

  t.it("revoking an absent device is a no-op", function()
    local r = fresh()
    local lost = false
    r:on("deck", "lost", function() lost = true end)
    r:revoke("deck")
    t.assertEquals(lost, false)
  end)

  -- The mid-dispatch guarantee isn't just "doesn't corrupt": a handler
  -- registered during `_emit` must not fire in the same dispatch that
  -- registered it -- it starts firing from the NEXT emit for this key/event.
  t.it("defers a handler registered mid-dispatch to the next emit, not the current one", function()
    local r = fresh()
    local innerCalls = 0
    r:on("cam", "changed", function()
      r:on("cam", "changed", function() innerCalls = innerCalls + 1 end)
    end)
    r:announce("cam", "CAM")

    r:update("cam", "CAM")
    t.assertEquals(innerCalls, 0, "handler registered mid-dispatch must not fire during that same emit")

    r:update("cam", "CAM")
    t.assertEquals(innerCalls, 1, "handler registered mid-dispatch must fire starting the next emit")
  end)

  t.it("get returns nil for an unknown key", function()
    t.assertNil(fresh():get("nope"))
  end)
end)
