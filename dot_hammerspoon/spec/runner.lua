-- spec/runner.lua -- zero-dependency test harness. No luarocks, no busted:
-- this machine's config must stay installable on a locked-down work laptop.
local M = { passed = 0, failed = 0, failures = {}, _suite = nil }

function M.describe(name, fn)
  M._suite = name
  fn()
  M._suite = nil
end

function M.it(name, fn)
  local label = (M._suite and (M._suite .. " > ") or "") .. name
  local ok, err = xpcall(fn, debug.traceback)
  if ok then
    M.passed = M.passed + 1
    io.write(".")
  else
    M.failed = M.failed + 1
    io.write("F")
    table.insert(M.failures, { label = label, err = err })
  end
  io.flush()
end

local function fail(msg)
  error(msg, 3)
end

function M.assertEquals(actual, expected, msg)
  if actual ~= expected then
    fail(string.format("%sexpected %s, got %s",
      msg and (msg .. ": ") or "", tostring(expected), tostring(actual)))
  end
end

function M.assertTrue(v, msg)
  if v ~= true then
    fail(string.format("%sexpected true, got %s", msg and (msg .. ": ") or "", tostring(v)))
  end
end

function M.assertNil(v, msg)
  if v ~= nil then
    fail(string.format("%sexpected nil, got %s", msg and (msg .. ": ") or "", tostring(v)))
  end
end

function M.assertNotNil(v, msg)
  if v == nil then
    fail(string.format("%sexpected non-nil", msg and (msg .. ": ") or ""))
  end
end

function M.report()
  io.write("\n\n")
  for _, f in ipairs(M.failures) do
    io.write(string.format("FAIL: %s\n%s\n\n", f.label, f.err))
  end
  -- Name the interpreter that produced this result. This suite runs under
  -- standalone Lua (currently 5.5) while Hammerspoon embeds its own Lua 5.4 --
  -- a green summary is only evidence the config works if it also names the
  -- runtime it ran under, so this is load-bearing, not cosmetic. Read from
  -- _VERSION rather than hardcoding so it stays truthful if the interpreter
  -- ever changes.
  io.write(string.format("%d passed, %d failed (%s)\n", M.passed, M.failed, _VERSION))
  return M.failed == 0 and 0 or 1
end

return M
