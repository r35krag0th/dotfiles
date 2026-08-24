-- r35/deck.lua -- composites layers, diffs before drawing, dispatches presses.
local log = require("r35.log")

local Deck = {}
Deck.__index = Deck

-- iconsModule is injected rather than required so tests can substitute a stub
-- and never touch HTTP or the filesystem.
function Deck.new(registry, layout, iconsModule)
  return setmetatable({
    registry = registry,
    layout   = layout,
    icons    = iconsModule or require("r35.icons"),
    device   = nil,
    page     = nil,
    rendered = {}, -- index -> last drawn icon key
  }, Deck)
end

function Deck:attach(device)
  self.device = device
  -- Freshly attached hardware is blank, whatever we drew before.
  self:invalidate()
end

function Deck:detach()
  self.device = nil
  self:invalidate()
end

function Deck:setPage(page)
  self.page = page
  self:render()
end

function Deck:invalidate()
  self.rendered = {}
end

-- Page layer composited over the persistent layer. A page declares only the
-- indices it owns, so persistent buttons (mute) survive a page switch.
function Deck:resolve()
  local out = {}
  for index, button in pairs(self.layout.persistent or {}) do out[index] = button end
  for index, button in pairs(self.page or {})            do out[index] = button end
  return out
end

local function iconSpec(button, registry)
  if type(button.icon) == "function" then
    return button.icon(registry) or {}
  end
  return button.icon or {}
end

function Deck:render(indices)
  if self.device == nil then return end
  for index, button in pairs(self:resolve()) do
    if indices == nil or indices[index] then
      -- A button's `icon` can be a function (the camera tile calls into a
      -- device object that can die when the camera disconnects; the clock
      -- tiles read the current time). Unlike press()'s action dispatch, this
      -- call used to be unprotected: one throwing icon function aborted the
      -- whole pairs() loop mid-pass, so every button ordered after it in
      -- that (nondeterministic) iteration silently never rendered -- a bug
      -- that reproduced differently between runs. Isolate it the same way
      -- press() isolates a throwing action: log and skip just this button.
      --
      -- The protected region covers the WHOLE per-button body, not just
      -- iconSpec: self.icons.key(...) and the synchronous cache-hit path of
      -- setButtonIcon (which invokes its callback inline, before returning)
      -- run in this same call stack, and a cache hit is the NORMAL path, not
      -- the exception -- an unprotected throw there would reintroduce the
      -- exact same whole-loop-abort bug this xpcall exists to prevent.
      local ok, err = xpcall(function()
        local spec = iconSpec(button, self.registry)
        -- Diff BEFORE fetching: a suppressed tile costs one string comparison,
        -- no HTTP round trip and no USB write. This is what makes six clock
        -- tiles ticking once a minute effectively free.
        local key = self.icons.key(spec)
        if self.rendered[index] ~= key then
          -- Optimistic set is deliberate: it stops a second render from firing
          -- a duplicate concurrent fetch for the same button while this one is
          -- in flight.
          self.rendered[index] = key
          self.icons.setButtonIcon(self.device, index, spec, function(fetchOk)
            -- setButtonIcon is genuinely async and, by deliberate design,
            -- leaves the hardware showing its PREVIOUS image on failure. So
            -- the optimistic set above is a lie the moment the fetch fails --
            -- the cache claims a key that was never actually drawn, which
            -- would suppress every future identical render forever. Clear it
            -- so the next pass retries. Guard against a newer render having
            -- superseded us in the meantime: only roll back if this key is
            -- still the one we optimistically set.
            if not fetchOk and self.rendered[index] == key then
              self.rendered[index] = nil
            end
          end)
        end
      end, debug.traceback)
      if not ok then
        log.error("Deck", string.format("render for button %d failed: %s", index, err))
      end
    end
  end
end

function Deck:press(index, pressed)
  if not pressed then return end -- ignore the release half
  local button = self:resolve()[index]
  if not button then return end
  if not button.action then
    -- A defined button with no `action` (e.g. the reaction tiles) used to
    -- fail this press silently: nothing lit up, nothing logged, no way to
    -- tell "no action bound" apart from "the press event never arrived" from
    -- the console. Make it visible.
    log.info("Deck", string.format("button %d pressed but has no action bound", index))
    return
  end
  local ok, err = xpcall(button.action, debug.traceback)
  if not ok then
    log.error("Deck", string.format("action for button %d failed: %s", index, err))
  end
end

-- Wire every button's `watch` list so a registry event re-renders exactly
-- the button(s) watching that key -- never the whole deck. Both "changed"
-- (an already-known device's state changed) and "available" (the device
-- just appeared, e.g. a reconnect) drive the same per-key render, so a
-- replugged camera or a mic that just came back repaints its own indicator
-- without touching any other button's icon key.
--
-- Limitation 1: only self.layout.persistent is walked -- a page layer's
-- watched buttons are never bound. That's correct for today: the page/
-- persistent composite seam exists in resolve()/setPage(), but nothing
-- switches pages yet, so no page button declares `watch`. Whoever adds page
-- switching will need bind() to also cover self.page (or to re-run per
-- page) -- it does not happen automatically today.
--
-- Limitation 2: calling bind() twice double-registers every handler, so a
-- matching event fires two renders instead of one (wasteful -- render()'s
-- diff still suppresses the actual redraw on the second call -- not
-- incorrect). Safe today because init.lua calls bind() exactly once and
-- hs.reload() discards the whole Lua state, so nothing currently calls it
-- twice. Don't add a second call without first making bind() idempotent.
function Deck:bind()
  local watched = {}
  for index, button in pairs(self.layout.persistent or {}) do
    for _, key in ipairs(button.watch or {}) do
      watched[key] = watched[key] or {}
      watched[key][index] = true
    end
  end

  for key, indices in pairs(watched) do
    self.registry:on(key, "changed",   function() self:render(indices) end)
    self.registry:on(key, "available", function() self:render(indices) end)
    -- registry:revoke(...) emits "lost" (e.g. camera.lua and audio.lua call it
    -- when hardware disappears). Without this, a watching button's icon
    -- function never re-runs on disconnect, so it stays frozen on its last
    -- drawn image -- the MISSING branch in config/layout.lua's camera tile
    -- becomes unreachable after the first render.
    self.registry:on(key, "lost",      function() self:render(indices) end)
  end
end

return Deck
