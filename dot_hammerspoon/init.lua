-- init.lua -- bootstrap only. Behaviour lives in r35/, data lives in config/.
hs.loadSpoon("EmmyLua")

require("r35.ipc").start()

local log      = require("r35.log")
local Registry = require("r35.registry")
local Deck     = require("r35.deck")
local icons    = require("r35.icons")
local actions  = require("r35.actions")
local clock    = require("r35.clock")

local devices = require("config.devices")
local layout  = require("config.layout")

-- Icon service runs via launchd (net.r35.icon-service)
-- Canonical plist: ~/.hammerspoon/launchd/net.r35.icon-service.plist
--   (symlinked into ~/Library/LaunchAgents/)
-- Start:  launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/net.r35.icon-service.plist
-- Stop:   launchctl bootout gui/$(id -u)/net.r35.icon-service
-- Logs:   ~/Library/Logs/net.r35.icon-service.log
icons.ensureCacheDir()

local registry = Registry.new()
local deck = Deck.new(registry, layout, icons)
deck:bind()

-- checkHealth() call itself is deliberately down here, after `deck` exists:
-- its callback closes over `deck`, and hs.http.asyncGet's callback runs
-- later regardless (so ordering relative to the "available" handler below
-- doesn't matter) -- but Lua locals aren't visible to a closure written
-- before their own `local` statement, so this must come after `local deck`.
--
-- Wiping the on-disk PNG cache (r35/icons.lua) is necessary but not
-- sufficient: Deck.rendered remembers, per button, the key it last drew, and
-- a font-resolution change leaves every one of those keys unchanged (M.key()
-- hashes the request, not the render). Without invalidate() first, render()'s
-- own diff would suppress every redraw and the deck would keep showing
-- stale images regardless of what's on disk.
icons.checkHealth(function()
  log.info("Init", "resolved fonts changed; forcing full repaint")
  deck:invalidate()
  deck:render()
end)

-- Persistent, not whenAvailable: replugged hardware comes back blank, so every
-- reconnect must re-render, not just the first one.
registry:on("streamdeck", "available", function(device)
  device:reset()
  device:setBrightness(100)
  device:buttonCallback(function(_, buttonId, pressed)
    deck:press(buttonId, pressed)
  end)
  deck:attach(device)
  deck:render()
end)

registry:on("streamdeck", "lost", function()
  log.info("Init", "stream deck disconnected")
  deck:detach()
end)

require("r35.devices.streamdeck").start(registry)
require("r35.devices.camera").start(registry, devices.cameras)
require("r35.devices.audio").start(registry)
clock.start(registry)

for _, h in ipairs(layout.hotkeys or {}) do
  actions.bindHotkey(h.mods, h.key, actions.sendTo(h.bundleID, h.to[1], h.to[2], h.desc))
end

-- Timers do not fire during sleep and the deck can return stale or blank.
local wakeWatcher = hs.caffeinate.watcher.new(function(event)
  if event == hs.caffeinate.watcher.systemDidWake then
    log.info("Init", "woke; forcing full redraw")
    deck:invalidate()
    deck:render()
  end
end):start()

-- Reload on any .lua change under ~/.hammerspoon.
local configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then hs.reload() end
  end
end):start()

-- hs.reload() destroys the entire Lua state, including every timer and
-- watcher created in it -- so there is no cross-reload leak for this teardown
-- to fix. Verified against a REAL reload driven by the pathwatcher above (not
-- `open -g hammerspoon://reloadConfig`, which this config has no listener for
-- and which therefore never reloads it at all): a probe timer ticked several
-- times in the seconds before a pathwatcher-triggered reload and zero times
-- in the same window after, and a global set just before the reload read
-- back nil just after -- proof the whole state, not just the timer, was gone.
--
-- So hs.shutdownCallback below is defensive hygiene, not a leak fix: it
-- guards explicit re-entry within a single Lua state (something calling
-- start() twice without a reload in between, which would otherwise register
-- a second timer/watcher alongside the first) and it gives Hammerspoon a
-- clean, deliberate exit path -- releasing native resources (camera and
-- audio watchers) instead of leaving that to garbage-collection timing.
hs.shutdownCallback = function()
  log.info("Init", "tearing down before reload/exit")
  clock.stop()
  hs.camera.stopWatcher()
  hs.audiodevice.watcher.stop()
  if wakeWatcher then wakeWatcher:stop() end
  if configWatcher then configWatcher:stop() end
end

hs.alert.show("Config loaded")
