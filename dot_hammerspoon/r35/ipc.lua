-- r35/ipc.lua -- opens the hs.ipc message port. Best-effort installs the `hs`
-- CLI binary on a writable prefix; the CLI install is not guaranteed to
-- succeed (e.g. no writable prefix exists yet), only attempted.
local function say(level, msg) print(string.format("[r35.IPC][%s] %s", level, msg)) end

local M = {}

-- cliInstall defaults to /usr/local, which is root-owned on stock macOS.
-- Probe user-writable prefixes first so this works without admin rights.
local PREFIXES = {
  os.getenv("HOME") .. "/.local",
  "/opt/homebrew",
  "/usr/local",
}

local function binaryPresent()
  for _, p in ipairs(PREFIXES) do
    if hs.fs.attributes(p .. "/bin/hs") then return p end
  end
  return nil
end

-- hs.fs.mkdir is not recursive, and cliInstall does not create its target
-- directory either -- it silently no-ops (returns false, writes nothing) if
-- <prefix>/bin doesn't exist. Walk the path one component at a time so a
-- fresh prefix (e.g. $HOME/.local on a machine that has never had it) is
-- actually usable. Existing components are left untouched.
local function ensureDir(path)
  local built = ""
  for component in path:gmatch("[^/]+") do
    built = built .. "/" .. component
    if not hs.fs.attributes(built) then
      local ok, err = hs.fs.mkdir(built)
      if not ok and not hs.fs.attributes(built) then
        return false, err
      end
    end
  end
  return true
end

function M.start()
  local ok, err = pcall(require, "hs.ipc")
  if not ok then
    say("ERROR", "could not load hs.ipc: " .. tostring(err))
    return false
  end

  local existing = binaryPresent()
  if existing then
    say("INFO", "cli already present at " .. existing .. "/bin/hs")
    return true
  end

  for _, prefix in ipairs(PREFIXES) do
    local dirOk, dirErr = ensureDir(prefix .. "/bin")
    if not dirOk then
      say("WARN", "cannot create " .. prefix .. "/bin: " .. tostring(dirErr))
    else
      -- cliInstall returns false on failure rather than raising; check it.
      if hs.ipc.cliInstall(prefix, true) then
        say("INFO", "installed cli to " .. prefix .. "/bin/hs")
        return true
      end
    end
  end

  say("WARN", "no writable prefix for cliInstall; hs CLI unavailable")
  return true -- the message port is open regardless of the CLI binary
end

return M
