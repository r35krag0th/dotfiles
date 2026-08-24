-- spec/actions_spec.lua -- pure-helper tests only. r35/actions.lua wraps hs
-- APIs (hs.urlevent, hs.application, hs.eventtap, hs.alert) that the
-- standalone runner cannot provide, so only M._validateURL is exercised
-- here -- same boundary already drawn for icons._fnv1a64 and
-- icons._fontFingerprint. The rest of the module is verified live over
-- hs.ipc, not in this suite.
local t = require("spec.runner")

local actions = require("r35.actions")

t.describe("actions._validateURL", function()
  t.it("accepts a valid https:// URL", function()
    local ok, err = actions._validateURL("https://www.hammerspoon.org/docs/")
    t.assertTrue(ok)
    t.assertNil(err)
  end)

  t.it("accepts a non-http custom scheme (slack://)", function()
    -- The validator must not be so strict it rejects legitimate custom
    -- schemes -- Slack, Zoom, Teams and friends all use one.
    local ok, err = actions._validateURL("slack://open")
    t.assertTrue(ok)
    t.assertNil(err)
  end)

  t.it("rejects a bare host with no scheme", function()
    local ok, err = actions._validateURL("example.com")
    t.assertEquals(ok, false)
    t.assertNotNil(err)
  end)

  t.it("rejects an empty string", function()
    local ok, err = actions._validateURL("")
    t.assertEquals(ok, false)
    t.assertNotNil(err)
  end)

  t.it("rejects a nil argument", function()
    local ok, err = actions._validateURL(nil)
    t.assertEquals(ok, false)
    t.assertNotNil(err)
  end)

  t.it("rejects a non-string argument", function()
    local okNum, errNum = actions._validateURL(42)
    t.assertEquals(okNum, false)
    t.assertNotNil(errNum)

    local okTbl, errTbl = actions._validateURL({})
    t.assertEquals(okTbl, false)
    t.assertNotNil(errTbl)
  end)

  -- Fix round 1: hs.urlevent.openURL("http://") was verified LIVE to return
  -- true -- macOS opens a blank tab and reports success. There is no
  -- "opened" boolean backstop for a scheme-only URL the way there is for a
  -- bad bundle ID; this validator is the ONLY line of defence against it.
  -- Do not loosen this on the assumption the API call downstream will catch
  -- it -- it demonstrably does not.
  t.it("rejects a scheme-only URL with no authority", function()
    local ok, err = actions._validateURL("http://")
    t.assertEquals(ok, false)
    t.assertNotNil(err)
  end)
end)
