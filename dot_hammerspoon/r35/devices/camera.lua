-- r35/devices/camera.lua -- owns hs.camera.setWatcherCallback.
local log = require("r35.log")

local M = {}

local function key(name) return "camera:" .. name end

local function watchProperties(registry, cam)
  cam:setPropertyWatcherCallback(function(c, property)
    -- "gone" is misleadingly named: it means the device's IN-USE status changed
    -- (another app started or stopped using the camera), not that it vanished.
    if property == "gone" then
      registry:update(key(c:name()), c)
    end
  end)
  cam:startPropertyWatcher()
end

function M.start(registry, names)
  local wanted = {}
  for _, n in ipairs(names) do wanted[n] = true end

  -- SEEDING: hs.camera's watcher reports only CHANGES. A camera already present
  -- when this config loads is never announced otherwise -- that is D4.
  for _, cam in ipairs(hs.camera.allCameras()) do
    local name = cam:name()
    log.info("Camera", "discovered " .. name)
    if wanted[name] then
      watchProperties(registry, cam)
      registry:announce(key(name), cam)
    end
  end

  hs.camera.setWatcherCallback(function(cam, state)
    local name = cam:name()
    if not wanted[name] then return end
    if state == "Added" then
      watchProperties(registry, cam)
      registry:announce(key(name), cam)
    elseif state == "Removed" then
      registry:revoke(key(name))
    end
  end)

  hs.camera.startWatcher()
end

return M
