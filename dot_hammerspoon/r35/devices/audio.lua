-- r35/devices/audio.lua -- owns hs.audiodevice.watcher.
local log = require("r35.log")

local M = {}

local KEY = "audio.in:default"

-- Deliberately NOT hs.audiodevice.current(): its parameter is documented as
-- "output - true to fetch information about the default INPUT device", i.e. the
-- name and the semantics disagree, and it returns a metadata table rather than a
-- device object. defaultInputDevice() has neither problem.
local function resolve(registry)
  local dev = hs.audiodevice.defaultInputDevice()
  if dev == nil then
    registry:revoke(KEY)
    return
  end
  log.info("Audio", string.format("default input = %s (inUse=%s)",
    dev:name(), tostring(dev:inUse())))
  if registry:get(KEY) == nil then
    registry:announce(KEY, dev)
  else
    registry:update(KEY, dev)
  end
end

function M.start(registry)
  -- SEEDING: as with cameras, the watcher reports only changes (D4).
  resolve(registry)

  hs.audiodevice.watcher.setCallback(function(event)
    -- Event codes are undocumented four-character strings. Rather than guess at
    -- them, log what actually arrives and re-resolve unconditionally --
    -- re-resolution is cheap and the registry's update() is idempotent.
    log.info("Audio", "watcher event: " .. tostring(event))
    resolve(registry)
  end)

  hs.audiodevice.watcher.start()
end

return M
