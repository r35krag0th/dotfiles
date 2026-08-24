-- r35/actions.lua -- action constructors. Plain closures: an Action class
-- hierarchy would buy nothing over this.
local log = require("r35.log")

local M = {}

local ALERT_STYLE = {
  fillColor   = { hex = "#464EB8" },
  strokeColor = { hex = "#7B83EB" },
  textColor   = { hex = "#F4F4F4" },
  textFont    = "PragmataPro VF",
  strokeWidth = 5,
  radius      = 24,
}

-- Send a keystroke to a specific application, whatever currently has focus.
-- This is the capability the Elgato software cannot provide and the reason this
-- config exists.
function M.sendTo(bundleID, mods, key, desc)
  return function()
    -- Resolved at SEND time, never cached at load time (D12): the app may not
    -- have been running when Hammerspoon started, and it may have restarted since.
    local apps = hs.application.applicationsForBundleID(bundleID)
    if #apps == 0 then
      log.warn("Actions", string.format("%s is not running; dropping %s", bundleID, key))
      -- Without this, a press against a not-running app is silent: the
      -- button visibly does nothing and the user has no reason to suspect
      -- the target app simply isn't running. Same alert path as the success
      -- case below, so this needs no new UI.
      if desc then
        hs.alert.closeAll()
        hs.alert.show(desc .. " — " .. bundleID .. " not running", ALERT_STYLE)
      end
      return
    end

    -- apps is a TABLE of hs.application objects; keyStroke wants a single
    -- object. Passing the table (D11) silently falls through to the frontmost
    -- application, which looks correct only while the target already has focus.
    local app = apps[1]

    if desc then
      hs.alert.closeAll()
      hs.alert.show(desc, ALERT_STYLE)
    end
    hs.eventtap.keyStroke(mods, key, nil, app)
  end
end

-- Validates that a URL is at minimum shaped like one before it is handed to
-- hs.urlevent. hs.urlevent.openURL/openURLWithBundle both return a boolean
-- and fail SILENTLY (D11's exact shape: an API whose failure is a return
-- value nobody checks) -- catching a malformed URL here, with a specific
-- reason, is strictly better than finding out from a bare `false` after the
-- call. Pure and hs-free so it is testable under the standalone runner; see
-- spec/actions_spec.lua. Same precedent as icons._fnv1a64 and
-- icons._fontFingerprint: underscore-prefixed, exposed solely for the suite.
--
-- Hammerspoon's docs are explicit that the URL "must contain a scheme and
-- '://'" -- this checks exactly that, and nothing stricter. It does NOT
-- validate the scheme against a fixed allowlist: "slack://", "zoommtg://"
-- and other non-http custom schemes are legitimate and must keep working.
function M._validateURL(url)
  if url == nil then
    return false, "url is nil"
  end
  if type(url) ~= "string" then
    return false, "url is not a string (got " .. type(url) .. ")"
  end
  if url == "" then
    return false, "url is empty"
  end
  -- Scheme must be a leading letter followed by letters/digits/+/-/. --
  -- the standard URI scheme grammar (RFC 3986 3.1) -- immediately before
  -- "://". This rejects both a bare host ("example.com", no "://" at all)
  -- and a "://" with nothing schemelike before it.
  if not url:match("^%a[%w+.-]*://") then
    return false, "url has no scheme (must contain a scheme and '://'): " .. url
  end
  -- Fix round 1: a scheme with nothing after "://" ("http://") passed this
  -- far and was verified LIVE to make hs.urlevent.openURL return true --
  -- macOS opens a blank tab and calls it a success. There is no downstream
  -- boolean check that catches this (unlike a bad bundle ID, which the real
  -- API call does report); this validator is the only place it can be
  -- caught. Require at least one character after "://" that is not a
  -- delimiter (/, ?, #) -- an empty or immediately-terminated authority.
  -- Deliberately NOT a hostname/port/TLD check: this catches structurally
  -- impossible URLs, not malformed-but-real ones.
  if not url:match("^%a[%w+.-]*://[^/?#]") then
    return false, "url has a scheme but no authority after '://': " .. url
  end
  return true, nil
end

-- Open a URL, optionally with a specific application. This is the
-- capability the Elgato software cannot provide via a bare link: a
-- Stream Deck button that opens a link with one press.
--
-- bundleID is a plain positional argument, matching sendTo's own shape,
-- not a table: browser *profile* routing (e.g. Chrome's
-- --profile-directory) was raised and explicitly ruled out of scope, and
-- hs.urlevent has no way to express it anyway (openURLWithBundle targets
-- an application, not a profile within one). Add a parameter if and when
-- that need is real -- no speculative shape here.
function M.openURL(url, desc, bundleID)
  return function()
    local ok, err = M._validateURL(url)
    if not ok then
      log.warn("Actions", "not opening URL: " .. err)
      if desc then
        hs.alert.closeAll()
        hs.alert.show(desc .. " — invalid URL", ALERT_STYLE)
      end
      return
    end

    local opened
    if bundleID then
      opened = hs.urlevent.openURLWithBundle(url, bundleID)
    else
      opened = hs.urlevent.openURL(url)
    end

    -- Both hs.urlevent functions return a boolean and fail SILENTLY (D11's
    -- shape again): a bad bundle ID or a handler that refuses the URL looks
    -- identical to success unless this is checked and logged explicitly.
    if not opened then
      if bundleID then
        log.warn("Actions", string.format("failed to open %s with %s", url, bundleID))
      else
        log.warn("Actions", "failed to open " .. url)
      end
      if desc then
        hs.alert.closeAll()
        hs.alert.show(desc .. " — failed to open", ALERT_STYLE)
      end
      return
    end

    if desc then
      hs.alert.closeAll()
      hs.alert.show(desc, ALERT_STYLE)
    end
  end
end

function M.bindHotkey(fromMods, fromKey, action)
  return hs.hotkey.bind(fromMods, fromKey, action)
end

return M
