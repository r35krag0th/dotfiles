-- r35/registry.lua -- one hub owning the single global callback slot each
-- Hammerspoon device API exposes, fanning out to many listeners and replaying
-- current state to handlers registered after a device already appeared.
--
-- Why this exists rather than a timer: hs.streamdeck.init,
-- hs.camera.setWatcherCallback and hs.audiodevice.watcher.setCallback each hold
-- exactly ONE callback -- they overwrite, they do not append. And the previous
-- hs.timer.doUntil approach had inverted semantics (it ran while the device was
-- ABSENT and stopped once it appeared), so button 17 could never render.
local log = require("r35.log")

local Registry = {}
Registry.__index = Registry

function Registry.new()
  return setmetatable({
    devices  = {}, -- key -> device
    pending  = {}, -- key -> { fn, ... }  one-shot queue
    handlers = {}, -- key -> event -> { fn, ... }
  }, Registry)
end

function Registry:_safeCall(key, fn, device)
  local ok, err = xpcall(fn, debug.traceback, device)
  if not ok then
    log.error("Registry", string.format("handler for %q failed: %s", key, err))
  end
  return ok
end

function Registry:get(key)
  return self.devices[key]
end

-- One-shot. Fires once, ever -- suited to setup work.
function Registry:whenAvailable(key, fn)
  local device = self.devices[key]
  if device ~= nil then
    -- Deliberately async even though we could call inline. Firing
    -- synchronously when ready and asynchronously when not would give callers
    -- two different execution orders depending on whether the device happened
    -- to be plugged in at reload -- the classic "don't release Zalgo" hazard.
    hs.timer.doAfter(0, function() self:_safeCall(key, fn, device) end)
  else
    self.pending[key] = self.pending[key] or {}
    table.insert(self.pending[key], fn)
  end
end

-- Persistent. Fires on every matching event -- suited to re-render on reconnect.
function Registry:on(key, event, fn)
  self.handlers[key] = self.handlers[key] or {}
  self.handlers[key][event] = self.handlers[key][event] or {}
  table.insert(self.handlers[key][event], fn)
end

function Registry:_emit(key, event, device)
  local byEvent = self.handlers[key]
  if not byEvent then return end
  local list = byEvent[event]
  if not list then return end

  -- Iterate a copy: a handler is allowed to register further handlers without
  -- corrupting this dispatch. A handler registered here fires starting from
  -- the NEXT emit for this key/event, not this one -- the snapshot was
  -- already taken, so it cannot observe the insertion.
  local snapshot = {}
  for i, fn in ipairs(list) do snapshot[i] = fn end
  for _, fn in ipairs(snapshot) do
    self:_safeCall(key, fn, device)
  end
end

-- Drains the one-shot whenAvailable queue for `key`. Must be called from
-- every path that can transition devices[key] from nil to non-nil --
-- currently `announce` and `update` -- so a whenAvailable handler registered
-- while the device was absent fires no matter which of those paths first
-- makes it present. Calling this when there is nothing pending is a no-op,
-- so it is safe to call unconditionally.
function Registry:_drainPending(key, device)
  local queue = self.pending[key]
  if not queue then return end
  self.pending[key] = nil
  for _, fn in ipairs(queue) do
    self:_safeCall(key, fn, device)
  end
end

function Registry:announce(key, device)
  self.devices[key] = device
  self:_drainPending(key, device)
  self:_emit(key, "available", device)
end

function Registry:revoke(key)
  local device = self.devices[key]
  if device == nil then return end
  self.devices[key] = nil
  self:_emit(key, "lost", device)
end

function Registry:update(key, device)
  self.devices[key] = device
  self:_drainPending(key, device)
  self:_emit(key, "changed", device)
end

return Registry
