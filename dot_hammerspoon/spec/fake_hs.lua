-- spec/fake_hs.lua -- the minimum hs surface the pure modules touch, with a
-- clock the tests drive by hand. Registry dispatch is deliberately async, so
-- tests must be able to decide exactly when queued callbacks run.
local M = { _pending = {}, _timers = {} }

M.fs = {
  attributes = function(_) return nil end,
}

M.timer = {
  doAfter = function(delay, fn)
    table.insert(M._pending, { delay = delay, fn = fn })
    return { stop = function() end }
  end,
  doEvery = function(interval, fn)
    local t = { interval = interval, fn = fn, stopped = false }
    t.stop = function() t.stopped = true end
    table.insert(M._timers, t)
    return t
  end,
}

-- Run every queued doAfter callback. Callbacks that queue more work are picked
-- up by the next flush, not this one -- that keeps ordering predictable.
function M.flush()
  local queue = M._pending
  M._pending = {}
  for _, t in ipairs(queue) do t.fn() end
  return #queue
end

function M.pendingCount() return #M._pending end

-- Fire every doEvery timer once, as though `interval` had elapsed.
function M.tick()
  for _, t in ipairs(M._timers) do
    if not t.stopped then t.fn() end
  end
end

function M.reset()
  M._pending = {}
  M._timers = {}
end

return M
