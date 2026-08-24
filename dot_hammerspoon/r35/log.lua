-- r35/log.lua -- prefixed logging. Deliberately free of any hs dependency so
-- that modules requiring it are loadable under the standalone test runner.
local M = {}

local function emit(level, tag, msg)
  print(string.format("[r35.%s][%s] %s", tag, level, msg))
end

function M.info(tag, msg) emit("INFO", tag, msg) end
function M.warn(tag, msg) emit("WARN", tag, msg) end
function M.error(tag, msg) emit("ERROR", tag, msg) end

return M
