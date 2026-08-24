# Stream Deck XL Refactor — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Break `~/.hammerspoon/init.lua` into focused modules, replace the broken device-discovery hook with a registry that has correct semantics, make the button layout declarative, add clock tiles, and fix the twelve defects catalogued in the spec.

**Architecture:** A central `Registry` owns the single global callback slot each Hammerspoon device API exposes, fans events out to many listeners, and replays current state to handlers registered after a device already appeared. Device adapters normalise `hs.streamdeck` / `hs.camera` / `hs.audiodevice` into registry events. A `Deck` composites a persistent button layer beneath an optional page layer, diffs icon keys before fetching, and dispatches presses to actions declared as plain closures.

**Tech Stack:** Lua 5.4 (Hammerspoon-embedded), Python 3 + Flask + Pillow via `uv` (icon service), launchd, `hs.ipc` for live verification. No package manager, no new runtime dependencies.

**Spec:** `~/.hammerspoon/docs/design/2026-08-21-streamdeck-refactor.md`

**Tracking:** `kata#wbyy` (project `hammerspoon`)

## Global Constraints

- **No git repository.** `~/.hammerspoon` is deliberately untracked; `git init` was explicitly declined. **Every task ends with a filesystem snapshot instead of a commit.** Never run `git init`, `git add`, or `chezmoi add` in this tree.
- **Snapshot directory:** `/private/tmp/claude-501/-Users-bobsaska--hammerspoon/a7c5ad89-5af0-4808-a08c-55c4a0fbb5ae/scratchpad/snapshots/` — referred to below as `$SNAP`. A pre-work snapshot of the known-good config already exists alongside it.
- **No new packages.** No luarocks, no npm, no pip beyond what `icon-service.py`'s inline PEP 723 block already declares (`flask`, `pillow`).
- **Must run on a locked-down work laptop:** no admin rights, no Homebrew assumed, `$HOME` differs between machines. Nothing may hardcode `/Users/bobsaska`.
- **Lua 5.4.** Hammerspoon embeds it; tests run under `/opt/homebrew/bin/lua`.
- **Stream Deck XL is 8 columns x 4 rows, buttons 1-32, icons 96x96 px.**
- **mise tasks must be file-based, never TOML.**
- **Markdown gets `npx prettier --write` before it is considered done.**
- **Logging prefix convention:** `[r35.<Area>]`, e.g. `[r35.Registry]`, `[r35.Deck]`.

**Snapshot helper** — paste into the shell once per session:

```bash
SNAP=/private/tmp/claude-501/-Users-bobsaska--hammerspoon/a7c5ad89-5af0-4808-a08c-55c4a0fbb5ae/scratchpad/snapshots
snap() { local t="$1"; shift; mkdir -p "$SNAP/$t"; cp -R "$@" "$SNAP/$t/" && echo "snapshot -> $SNAP/$t"; }
```

## File Structure

| Path                                 | Responsibility                                                                       |
| ------------------------------------ | ------------------------------------------------------------------------------------ |
| `init.lua`                           | Bootstrap only: require, wire, go. Target ~30 lines.                                 |
| `r35/log.lua`                        | Prefixed logging. Pure Lua, no `hs` dependency, so it loads under test.              |
| `r35/registry.lua`                   | Device event hub. Replay, fan-out, error isolation.                                  |
| `r35/ipc.lua`                        | `hs.ipc` load plus `cliInstall` with a writable-prefix probe.                        |
| `r35/icons.lua`                      | Icon fetch and cache. Owns `key()`, used for **both** cache path and render diffing. |
| `r35/deck.lua`                       | Composite layers, diff, render, dispatch button presses.                             |
| `r35/actions.lua`                    | Action constructors returning closures.                                              |
| `r35/clock.lua`                      | Locale-independent clock fields plus the `clock:minute` pseudo-device.               |
| `r35/devices/streamdeck.lua`         | Owns `hs.streamdeck.init`.                                                           |
| `r35/devices/camera.lua`             | Owns `hs.camera.setWatcherCallback`, seeds from `allCameras()`.                      |
| `r35/devices/audio.lua`              | Owns `hs.audiodevice.watcher`, tracks `defaultInputDevice()`.                        |
| `config/devices.lua`                 | Target device names.                                                                 |
| `config/layout.lua`                  | **The editing surface.** Declarative button data.                                    |
| `launchd/net.r35.icon-service.plist` | Canonical plist, symlinked into `~/Library/LaunchAgents/`.                           |
| `spec/runner.lua`                    | Zero-dependency test harness.                                                        |
| `spec/fake_hs.lua`                   | Minimal `hs` fake with a controllable clock.                                         |
| `spec/*_spec.lua`                    | Test suites.                                                                         |
| `.mise/tasks/test`                   | File-based mise task.                                                                |

**Deleted:** the window-management block at `init.lua:287-347`.

---

### Task 1: IPC bootstrap and D11 live diagnosis

Unlocks live verification for every later task, and settles whether D11 is a real fault before we write a fix for it.

**Files:**

- Create: `r35/ipc.lua`
- Modify: `init.lua` (add two lines near the top; no restructuring yet)

**Interfaces:**

- Consumes: nothing.
- Produces: `require("r35.ipc").start() -> boolean` — loads `hs.ipc` and ensures an `hs` CLI binary exists on a writable prefix. Returns `true` when the message port is open.

- [ ] **Step 1: Write `r35/ipc.lua`**

```lua
-- r35/ipc.lua -- opens the hs.ipc message port and ensures a CLI binary exists.
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
    -- cliInstall returns false on failure rather than raising; check it.
    if hs.ipc.cliInstall(prefix, true) then
      say("INFO", "installed cli to " .. prefix .. "/bin/hs")
      return true
    end
  end

  say("WARN", "no writable prefix for cliInstall; hs CLI unavailable")
  return true -- the message port is open regardless of the CLI binary
end

return M
```

- [ ] **Step 2: Wire it into the existing `init.lua`**

Insert immediately after the `hs.loadSpoon("EmmyLua")` line at `init.lua:2`:

```lua
require("r35.ipc").start()
```

- [ ] **Step 3: Reload and verify the message port opens**

Run:

```bash
open -g hammerspoon://reloadConfig ; sleep 2 ; echo 'return 1+1' | hs
```

Expected: `2`

If it prints `can't access Hammerspoon message port`, `hs.ipc` did not load — read the Hammerspoon console before continuing. Do not proceed past this step; every later task's verification depends on it.

- [ ] **Step 4: Diagnose D11 — does keystroke targeting actually work?**

With Microsoft Teams running but **not** frontmost (put a terminal in front), run:

```bash
echo 'local a = hs.application.applicationsForBundleID("com.microsoft.teams2")
return string.format("count=%d type=%s first=%s", #a, type(a), tostring(a[1]))' | hs
```

Expected: `count=1 type=table first=hs.application: Microsoft Teams (...)`

This confirms the shape: `applicationsForBundleID` yields a **table**, and `init.lua:251` passes that table where `keyStroke` documents an `hs.application` object.

- [ ] **Step 5: Record the D11 finding**

Append the observed output to the spec's D11 section, replacing `**Status: unconfirmed.**` with what was actually seen. If the table is passed and Teams still receives the keystroke while unfocused, D11 is a latent type error rather than a live fault — say so explicitly. Either way Task 8 passes `apps[1]`.

- [ ] **Step 6: Snapshot**

```bash
snap task01 ~/.hammerspoon/init.lua ~/.hammerspoon/r35
```

---

### Task 2: launchd plist rename and `$HOME` portability

Fixes D6 (Label disagrees with filename) and D7 (hardcoded `/Users/bobsaska`). Independent of every other task.

**Files:**

- Create: `launchd/net.r35.icon-service.plist`
- Modify: `init.lua:70-72` (stale comment)
- Replace: `~/Library/LaunchAgents/net.r35.icon-service.plist` (becomes a symlink)

**Interfaces:**

- Consumes: nothing.
- Produces: a running LaunchAgent under label `net.r35.icon-service` serving `http://127.0.0.1:5555`.

- [ ] **Step 1: Confirm the current state before changing it**

```bash
launchctl list | grep -i icon-service
```

Expected: a line containing `com.r35.icon-service` — the old label, which must be booted out by that name, not by the filename.

- [ ] **Step 2: Write the portable plist**

Create `~/.hammerspoon/launchd/net.r35.icon-service.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>net.r35.icon-service</string>
	<!-- launchd expands neither ~ nor $HOME in Program/StandardOutPath, so route
	     through a shell and let IT expand $HOME. Keeps this file byte-identical
	     on every machine: no chezmoi template, no per-host rendering. -->
	<key>ProgramArguments</key>
	<array>
		<string>/bin/sh</string>
		<string>-c</string>
		<string>exec "$HOME/.hammerspoon/icon-service.py" &gt;&gt; "$HOME/Library/Logs/net.r35.icon-service.log" 2&gt;&amp;1</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<dict>
		<key>SuccessfulExit</key>
		<false/>
	</dict>
	<key>ProcessType</key>
	<string>Background</string>
	<key>ThrottleInterval</key>
	<integer>10</integer>
</dict>
</plist>
```

Note: `WorkingDirectory` is dropped. `icon-service.py` resolves the font directory via `os.path.expanduser("~")` and never reads a relative path, so the working directory is irrelevant.

- [ ] **Step 3: Validate the plist parses before installing it**

```bash
plutil -lint ~/.hammerspoon/launchd/net.r35.icon-service.plist
```

Expected: `OK`

- [ ] **Step 4: Boot out the old label and install the new one**

```bash
launchctl bootout gui/$(id -u)/com.r35.icon-service 2>/dev/null
rm -f ~/Library/LaunchAgents/net.r35.icon-service.plist
ln -s ~/.hammerspoon/launchd/net.r35.icon-service.plist ~/Library/LaunchAgents/net.r35.icon-service.plist
mkdir -p ~/Library/Logs
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/net.r35.icon-service.plist
```

- [ ] **Step 5: Verify the new label is running and the old one is gone**

```bash
launchctl list | grep -i icon-service
curl -fsS http://127.0.0.1:5555/health && echo " <- health OK"
```

Expected: exactly one line, containing `net.r35.icon-service`. No `com.r35.icon-service`. Health endpoint responds.

If the service does not come up, read `~/Library/Logs/net.r35.icon-service.log`.

- [ ] **Step 6: Fix the stale comment**

Replace `init.lua:70-72` with:

```lua
-- Icon service runs via launchd (net.r35.icon-service)
-- Canonical plist: ~/.hammerspoon/launchd/net.r35.icon-service.plist
--   (symlinked into ~/Library/LaunchAgents/)
-- Start:  launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/net.r35.icon-service.plist
-- Stop:   launchctl bootout gui/$(id -u)/net.r35.icon-service
-- Logs:   ~/Library/Logs/net.r35.icon-service.log
```

- [ ] **Step 7: Snapshot**

```bash
snap task02 ~/.hammerspoon/launchd ~/.hammerspoon/init.lua
```

---

### Task 3: Test harness and logger

Everything after this is TDD, so the harness comes first. The logger ships here because the registry needs it in Task 4 and it is four lines.

**Files:**

- Create: `r35/log.lua`, `spec/runner.lua`, `spec/fake_hs.lua`, `spec/sanity_spec.lua`, `.mise/tasks/test`

**Interfaces:**

- Consumes: nothing.
- Produces:
  - `log.info(tag, msg)`, `log.warn(tag, msg)`, `log.error(tag, msg)` — all `(string, string) -> nil`
  - `runner.describe(name, fn)`, `runner.it(name, fn)`
  - `runner.assertEquals(actual, expected, [msg])`, `runner.assertTrue(v, [msg])`, `runner.assertNil(v, [msg])`, `runner.assertNotNil(v, [msg])`
  - `fake_hs.flush()` — runs every queued `doAfter` callback
  - `fake_hs.reset()` — clears the queue between tests

- [ ] **Step 1: Write `r35/log.lua`**

Pure Lua on purpose — no `hs` dependency, so modules that require it load under the test runner.

```lua
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
```

- [ ] **Step 2: Write `spec/fake_hs.lua`**

```lua
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
```

- [ ] **Step 3: Write `spec/runner.lua`**

```lua
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
  io.write(string.format("%d passed, %d failed\n", M.passed, M.failed))
  return M.failed == 0 and 0 or 1
end

return M
```

- [ ] **Step 4: Write the suite entry point `spec/all.lua`**

```lua
-- spec/all.lua -- runs every *_spec.lua. Add new suites to the list below.
package.path = "./?.lua;" .. package.path

local runner = require("spec.runner")

local SUITES = {
  "spec.sanity_spec",
}

for _, s in ipairs(SUITES) do require(s) end

os.exit(runner.report())
```

- [ ] **Step 5: Write `spec/sanity_spec.lua` — proves the harness itself works**

```lua
local t = require("spec.runner")
local hsFake = require("spec.fake_hs")

t.describe("harness", function()
  t.it("runs assertions", function()
    t.assertEquals(1 + 1, 2)
    t.assertTrue(true)
    t.assertNil(nil)
    t.assertNotNil("x")
  end)

  t.it("defers doAfter until flush", function()
    hsFake.reset()
    local ran = false
    hsFake.timer.doAfter(0, function() ran = true end)
    t.assertEquals(ran, false, "must not run before flush")
    t.assertEquals(hsFake.flush(), 1)
    t.assertEquals(ran, true, "must run after flush")
  end)
end)
```

- [ ] **Step 6: Run the suite and verify it passes**

```bash
cd ~/.hammerspoon && lua spec/all.lua
```

Expected: `..` then `2 passed, 0 failed`, exit code 0.

- [ ] **Step 7: Prove the harness can actually fail**

Temporarily change `t.assertEquals(1 + 1, 2)` to `t.assertEquals(1 + 1, 3)` and re-run.
Expected: `1 passed, 1 failed`, exit code 1, and a `FAIL:` block naming `expected 3, got 2`.

**Then revert the change.** A harness that cannot fail is worse than no harness — this step exists to prove it reports red, not just green.

- [ ] **Step 8: Write the file-based mise task `.mise/tasks/test`**

```bash
#!/usr/bin/env bash
#MISE description="Run the zero-dependency Lua spec suite"
set -euo pipefail
cd "$(dirname "$0")/../.."
exec lua spec/all.lua
```

Make it executable: `chmod +x .mise/tasks/test`

- [ ] **Step 9: Verify the mise task**

```bash
cd ~/.hammerspoon && mise run test
```

Expected: same output as Step 6, exit code 0.

- [ ] **Step 10: Snapshot**

```bash
snap task03 ~/.hammerspoon/spec ~/.hammerspoon/r35 ~/.hammerspoon/.mise
```

---

### Task 4: The Registry

The core of this work. Fixes D1 (inverted `doUntil`), D2 (single callback slots), and D9 (no error isolation).

**Files:**

- Create: `r35/registry.lua`, `spec/registry_spec.lua`
- Modify: `spec/all.lua` (add the suite)

**Interfaces:**

- Consumes: `r35.log`, global `hs.timer.doAfter`.
- Produces:
  - `Registry.new() -> registry`
  - `registry:whenAvailable(key, fn)` — one-shot; `fn(device)`
  - `registry:on(key, event, fn)` — persistent; `event` in `"available" | "lost" | "changed"`
  - `registry:get(key) -> device|nil`
  - `registry:announce(key, device)` — device appeared
  - `registry:revoke(key)` — device disappeared
  - `registry:update(key, device)` — device state changed; emits `"changed"`

- [ ] **Step 1: Write the failing tests**

Create `spec/registry_spec.lua`:

```lua
local t = require("spec.runner")
local hsFake = require("spec.fake_hs")
_G.hs = hsFake

local Registry = require("r35.registry")

local function fresh()
  hsFake.reset()
  return Registry.new()
end

t.describe("registry", function()
  -- D1 regression: the original doUntil ran the action while the device was
  -- ABSENT and stopped the moment it appeared. Both directions must work now.
  t.it("fires whenAvailable registered BEFORE the device appears", function()
    local r = fresh()
    local got = nil
    r:whenAvailable("streamdeck", function(d) got = d end)
    t.assertNil(got, "must not fire before announce")
    r:announce("streamdeck", "DECK")
    t.assertEquals(got, "DECK")
  end)

  t.it("fires whenAvailable registered AFTER the device appears", function()
    local r = fresh()
    r:announce("streamdeck", "DECK")
    local got = nil
    r:whenAvailable("streamdeck", function(d) got = d end)
    t.assertNil(got, "must be async, not synchronous")
    hsFake.flush()
    t.assertEquals(got, "DECK")
  end)

  t.it("dispatches asynchronously even when already available", function()
    local r = fresh()
    r:announce("streamdeck", "DECK")
    r:whenAvailable("streamdeck", function() end)
    t.assertEquals(hsFake.pendingCount(), 1, "must queue, never call inline")
  end)

  t.it("fires whenAvailable exactly once across reconnects", function()
    local r = fresh()
    local calls = 0
    r:whenAvailable("streamdeck", function() calls = calls + 1 end)
    r:announce("streamdeck", "DECK")
    r:revoke("streamdeck")
    r:announce("streamdeck", "DECK")
    hsFake.flush()
    t.assertEquals(calls, 1)
  end)

  t.it("fires on(available) on EVERY reconnect", function()
    local r = fresh()
    local calls = 0
    r:on("streamdeck", "available", function() calls = calls + 1 end)
    r:announce("streamdeck", "DECK")
    r:revoke("streamdeck")
    r:announce("streamdeck", "DECK")
    t.assertEquals(calls, 2, "replugged hardware returns blank; must re-render")
  end)

  t.it("fans out to multiple listeners", function()
    local r = fresh()
    local a, b = 0, 0
    r:on("cam", "changed", function() a = a + 1 end)
    r:on("cam", "changed", function() b = b + 1 end)
    r:announce("cam", "CAM")
    r:update("cam", "CAM")
    t.assertEquals(a, 1)
    t.assertEquals(b, 1)
  end)

  -- D9 regression
  t.it("isolates a throwing handler from its siblings", function()
    local r = fresh()
    local reached = false
    r:on("cam", "changed", function() error("boom") end)
    r:on("cam", "changed", function() reached = true end)
    r:announce("cam", "CAM")
    r:update("cam", "CAM")
    t.assertTrue(reached, "a throwing handler must not abort the chain")
  end)

  t.it("emits lost and clears the device", function()
    local r = fresh()
    local lost = false
    r:on("deck", "lost", function() lost = true end)
    r:announce("deck", "DECK")
    r:revoke("deck")
    t.assertTrue(lost)
    t.assertNil(r:get("deck"))
  end)

  t.it("revoking an absent device is a no-op", function()
    local r = fresh()
    local lost = false
    r:on("deck", "lost", function() lost = true end)
    r:revoke("deck")
    t.assertEquals(lost, false)
  end)

  t.it("tolerates a handler registering another handler mid-dispatch", function()
    local r = fresh()
    r:on("cam", "changed", function() r:on("cam", "changed", function() end) end)
    r:announce("cam", "CAM")
    r:update("cam", "CAM")
    t.assertNotNil(r:get("cam"))
  end)

  t.it("get returns nil for an unknown key", function()
    t.assertNil(fresh():get("nope"))
  end)
end)
```

- [ ] **Step 2: Register the suite**

In `spec/all.lua`, change `SUITES` to:

```lua
local SUITES = {
  "spec.sanity_spec",
  "spec.registry_spec",
}
```

- [ ] **Step 3: Run the tests and verify they fail**

```bash
cd ~/.hammerspoon && mise run test
```

Expected: FAIL — `module 'r35.registry' not found`.

- [ ] **Step 4: Write `r35/registry.lua`**

```lua
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

  -- Iterate a copy: a handler is allowed to register further handlers.
  local snapshot = {}
  for i, fn in ipairs(list) do snapshot[i] = fn end
  for _, fn in ipairs(snapshot) do
    self:_safeCall(key, fn, device)
  end
end

function Registry:announce(key, device)
  self.devices[key] = device

  local queue = self.pending[key]
  if queue then
    self.pending[key] = nil
    for _, fn in ipairs(queue) do
      self:_safeCall(key, fn, device)
    end
  end

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
  self:_emit(key, "changed", device)
end

return Registry
```

- [ ] **Step 5: Run the tests and verify they pass**

```bash
cd ~/.hammerspoon && mise run test
```

Expected: `13 passed, 0 failed`, exit code 0.

- [ ] **Step 6: Snapshot**

```bash
snap task04 ~/.hammerspoon/r35 ~/.hammerspoon/spec
```

---

### Task 5: Device adapters

Fixes D3 (method on a dead object), D4 (devices present at startup never announced), D5 (`current()` returns output), D10 (`buttonLayout()` two-value expansion).

**Files:**

- Create: `r35/devices/streamdeck.lua`, `r35/devices/camera.lua`, `r35/devices/audio.lua`, `config/devices.lua`

**Interfaces:**

- Consumes: `Registry` from Task 4.
- Produces: `require("r35.devices.streamdeck").start(registry)`, `.camera.start(registry, names)`, `.audio.start(registry)` — each returns `nil` and wires one global callback slot.
- Registry keys published: `streamdeck`, `streamdeck:<serial>`, `camera:<name>`, `audio.in:default`.

- [ ] **Step 1: Write `config/devices.lua`**

```lua
-- config/devices.lua -- names of the physical devices this config cares about.
return {
  -- NOTE: this uses a Unicode right single quote, not an ASCII apostrophe.
  cameras = { "Bob’s iPhone Camera" },
}
```

- [ ] **Step 2: Write `r35/devices/streamdeck.lua`**

```lua
-- r35/devices/streamdeck.lua -- owns hs.streamdeck.init, the module's single
-- discovery callback slot.
local log = require("r35.log")

local M = {}

-- The disconnect callback hands back a deck object that may already be dead, so
-- we record the serial at CONNECT time and look it up on disconnect rather than
-- calling deck:serialNumber() on a possibly-invalid object.
--
-- Deliberately a STRONG table: weak keys would let the entry be collected at
-- precisely the moment of unplug, which is when we need it. Entries are removed
-- explicitly on disconnect instead.
local serials = {}
local lastSerial = nil

local function serialFor(deck)
  -- Identity lookup is expected to hit: hs.streamdeck returns the same userdata
  -- on disconnect (confirmed against hardware 2026-08-21).
  local known = serials[deck]
  if known then return known end
  -- If identity ever fails, fall back to the most recent connect. Sound because
  -- this configuration drives exactly one deck; revisit if that changes.
  -- NOTE: do NOT "fall back" by scanning the table for `obj == deck` -- that is
  -- literally the same comparison the direct lookup already made.
  return lastSerial
end

function M.start(registry)
  hs.streamdeck.init(function(isConnected, deck)
    if isConnected then
      local serial = deck:serialNumber()
      serials[deck] = serial
      lastSerial = serial

      -- buttonLayout() returns TWO values (columns, rows). Bind both explicitly
      -- so neither is silently swallowed by a surrounding call.
      local columns, rows = deck:buttonLayout()
      log.info("StreamDeck", string.format("connected serial=%s layout=%dx%d",
        serial, columns, rows))

      registry:announce("streamdeck", deck)
      registry:announce("streamdeck:" .. serial, deck)
    else
      local serial = serialFor(deck)
      log.info("StreamDeck", string.format("disconnected serial=%s", tostring(serial)))
      registry:revoke("streamdeck")
      if serial then registry:revoke("streamdeck:" .. serial) end
      serials[deck] = nil
    end
  end)
end

return M
```

- [ ] **Step 3: Write `r35/devices/camera.lua`**

```lua
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
```

- [ ] **Step 4: Write `r35/devices/audio.lua`**

```lua
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
```

- [ ] **Step 5: Verify adapters load without error**

```bash
open -g hammerspoon://reloadConfig ; sleep 2
echo 'return type(require("r35.devices.streamdeck").start)' | hs
echo 'return type(require("r35.devices.camera").start)' | hs
echo 'return type(require("r35.devices.audio").start)' | hs
```

Expected: `function` three times.

- [ ] **Step 6: Capture the undocumented audio watcher event codes**

This resolves the last open assumption in the spec. With the config reloaded, change the system's default input device in System Settings (or unplug/replug the Scarlett) and read the console:

```bash
echo 'hs.console.getConsole()' | hs | grep -i "Audio.*watcher event" | tail -10
```

Record the observed four-character codes in the spec's "Assumptions requiring live verification" section, then move that item into "Verified facts".

- [ ] **Step 7: Snapshot**

```bash
snap task05 ~/.hammerspoon/r35 ~/.hammerspoon/config
```

---

### Task 6: Icons module and icon-service font support

Fixes D8 (cache key omits font). Adds the named font registry the clock tiles need.

**Files:**

- Create: `r35/icons.lua` (supersedes `stream-deck-icons.lua`), `spec/icons_spec.lua`
- Modify: `icon-service.py`, `spec/all.lua`
- Delete: `stream-deck-icons.lua` (only after Task 9's cutover verifies)

**Interfaces:**

- Consumes: nothing from earlier tasks.
- Produces:
  - `icons.key(opts) -> string` — stable cache/diff key covering **every** parameter that affects output
  - `icons.getIcon(opts, callback)` — `callback(ok, path)`
  - `icons.setButtonIcon(deck, index, opts, callback)` — `callback(ok)`
  - `opts` fields: `glyph`, `glyph_color`, `bg_color`, `glyph_size`, `label`, `label_color`, `label_size`, `font`, `glyph_font`

- [ ] **Step 1: Write the failing tests**

Create `spec/icons_spec.lua`:

```lua
local t = require("spec.runner")
local hsFake = require("spec.fake_hs")
_G.hs = hsFake

local icons = require("r35.icons")

t.describe("icons.key", function()
  -- D8 regression. The original params_to_key covered glyph, colours and label
  -- but NOT font, so the first render in a new font silently returned the old
  -- font's cached PNG. Same function now serves cache path AND render diffing,
  -- so the two cannot drift apart again.
  t.it("changes when only the font changes", function()
    local a = icons.key({ label = "11", font = "display" })
    local b = icons.key({ label = "11", font = "glyph" })
    if a == b then error("font must affect the key: both were " .. a) end
  end)

  t.it("changes when only the glyph font changes", function()
    local a = icons.key({ glyph = "f131", glyph_font = "glyph" })
    local b = icons.key({ glyph = "f131", glyph_font = "display" })
    if a == b then error("glyph_font must affect the key") end
  end)

  t.it("is stable for identical input", function()
    local o = { glyph = "f131", label = "MUTE", font = "display" }
    t.assertEquals(icons.key(o), icons.key(o))
  end)

  t.it("changes when the label changes", function()
    local a = icons.key({ label = "11" })
    local b = icons.key({ label = "12" })
    if a == b then error("label must affect the key") end
  end)

  t.it("produces a filesystem-safe key", function()
    local k = icons.key({ label = "A/B C", font = "display" })
    if k:find("[/ ]") then error("key must not contain / or space: " .. k) end
  end)
end)
```

- [ ] **Step 2: Register the suite**

Add `"spec.icons_spec"` to `SUITES` in `spec/all.lua`.

- [ ] **Step 3: Run and verify failure**

```bash
cd ~/.hammerspoon && mise run test
```

Expected: FAIL — `module 'r35.icons' not found`.

- [ ] **Step 4: Write `r35/icons.lua`**

```lua
-- r35/icons.lua -- icon fetch and cache against the local icon service.
local log = require("r35.log")

local M = {}

local CACHE_DIR  = os.getenv("HOME") .. "/.hammerspoon/icon-cache"
local SERVICE    = "http://127.0.0.1:5555"

-- Every parameter that can change the rendered image, in the exact order
-- sent on the wire. buildQuery() below only ever sends fields named here, so
-- a param icon-service.py accepts but this list doesn't know about can never
-- be requested from Lua -- a real, deferred gap (reviewed, not solved here).
-- What IS now closed structurally: a param listed here is always both sent
-- and hashed together, because M.key() below hashes buildQuery()'s own
-- output rather than recomputing anything in parallel. There is no longer a
-- second computation that could disagree about what a field means, which is
-- what made D8 possible in the first place.
--
-- `default` documents icon-service.py's own behaviour when a field is
-- omitted from the request. It is reference only -- no code below reads it.
-- The client used to keep its own copy of these defaults to compute the
-- cache key; that copy disagreed with the server twice (font support
-- shipped with no key coverage at all, then the glyph defaults themselves
-- diverged). See M.key()'s comment for why the client no longer tries.
local PARAMS = {
  { name = "glyph",       default = "0000"   },
  { name = "glyph_color", default = "ffffff" },
  { name = "bg_color",    default = "141d3a" },
  { name = "glyph_size",  default = 48       },
  { name = "label",       default = ""       },
  { name = "label_color", default = "ffffff" },
  { name = "label_size",  default = 12       },
  { name = "font",        default = "glyph"  },
  { name = "glyph_font",  default = "glyph"  },
  { name = "weight",      default = ""       },
}

-- 64-bit FNV-1a. Pure Lua, no `hs` dependency -- this is what lets M.key()
-- (below) stay callable, and testable, under standalone Lua rather than
-- only inside Hammerspoon. Lua 5.3+ integers are 64-bit and wrap on
-- overflow, which is exactly the arithmetic FNV needs. Verified against the
-- canonical test vectors ("" -> cbf29ce484222325, "a" -> af63dc4c8601ec8c,
-- "foobar" -> 85944171f73967e8) -- see spec/icons_spec.lua.
local FNV_OFFSET = 0xcbf29ce484222325
local FNV_PRIME  = 0x100000001b3

local function fnv1a64(s)
  local h = FNV_OFFSET
  for i = 1, #s do
    h = h ~ s:byte(i)
    h = h * FNV_PRIME
  end
  return string.format("%016x", h)
end
-- Exposed only so spec/icons_spec.lua can pin it against the canonical FNV-1a
-- vectors directly. The underscore marks it as an internal implementation
-- detail, not part of the module's real API -- callers want M.key(), not this.
M._fnv1a64 = fnv1a64

-- Percent-encode everything except RFC 3986 unreserved characters
-- (A-Z a-z 0-9 - . _ ~). Pure Lua, deliberately not `hs.http.encodeForQuery`,
-- for the same reason as fnv1a64 above: buildQuery() uses this, M.key() uses
-- buildQuery(), and M.key() must stay usable under standalone Lua.
local function urlEncode(s)
  return (tostring(s):gsub("[^%w%-%.%_%~]", function(c)
    return string.format("%%%02X", c:byte())
  end))
end

-- The literal bytes sent to icon-service.py. M.key() below hashes this same
-- string -- that coupling is the entire point of this fix round; see its
-- comment.
local function buildQuery(opts)
  opts = opts or {}
  local parts = {}
  for _, p in ipairs(PARAMS) do
    local v = opts[p.name]
    if v ~= nil then
      table.insert(parts, p.name .. "=" .. urlEncode(tostring(v)))
    end
  end
  return table.concat(parts, "&")
end

-- One string, two uses: buildQuery() produces the exact bytes sent to the
-- icon service, and the cache key is derived from those same bytes by
-- hashing them. The key therefore CANNOT disagree with the request -- which
-- is what made D8 possible in the first place: a hand-maintained key that
-- mirrored a hand-maintained default table, and the two drifted twice (font
-- shipped with no key coverage at all; then the glyph defaults themselves
-- disagreed). Do not reintroduce a second parallel computation over PARAMS
-- to "simplify" this back to a plain field concatenation.
--
-- Semantic shift from the old key(): this key now matches the REQUEST, not
-- the RENDER. Omitting a parameter and passing its default explicitly
-- produce different querystrings -- and therefore different cache entries --
-- for what is visually an identical image. That is wasteful (an extra cache
-- miss the first time) but never wrong (never a mismatched image), which is
-- strictly safer than what it replaces. Do not "fix" this by normalising
-- opts against PARAMS' defaults before hashing -- that reintroduces the
-- exact drift risk this design exists to remove.
function M.key(opts)
  local query  = buildQuery(opts)
  local label  = tostring((opts or {}).label or "")
  local prefix = label:gsub("[^%w]", ""):sub(1, 12)
  if prefix == "" then prefix = "icon" end
  return prefix .. "_" .. fnv1a64(query)
end

function M.getIcon(opts, callback)
  opts = opts or {}
  callback = callback or function() end

  local path = CACHE_DIR .. "/" .. M.key(opts) .. ".png"
  if hs.fs.attributes(path) then
    callback(true, path)
    return
  end

  hs.http.asyncGet(SERVICE .. "/generate?" .. buildQuery(opts), {}, function(status, body)
    if status < 200 or status >= 300 then
      log.error("Icons", string.format("HTTP %s for %s", tostring(status), M.key(opts)))
      callback(false, nil)
      return
    end
    local f = io.open(path, "wb")
    if not f then
      log.error("Icons", "could not write cache file " .. path)
      callback(false, nil)
      return
    end
    f:write(body)
    f:close()
    callback(true, path)
  end)
end

function M.setButtonIcon(deck, index, opts, callback)
  callback = callback or function() end
  M.getIcon(opts, function(ok, path)
    if not ok then
      -- Leave the button showing whatever it had. A blank button reads as a
      -- hardware fault; a stale one reads as "nothing happened", which is true.
      callback(false)
      return
    end
    local img = hs.image.imageFromPath(path)
    if not img then
      log.error("Icons", "could not load image " .. path)
      callback(false)
      return
    end
    deck:setButtonImage(index, img)
    callback(true)
  end)
end

function M.ensureCacheDir()
  hs.fs.mkdir(CACHE_DIR)
end

return M
```

- [ ] **Step 5: Run tests and verify they pass**

```bash
cd ~/.hammerspoon && mise run test
```

Expected: `18 passed, 0 failed`.

- [ ] **Step 6: Add the font registry to `icon-service.py`**

Replace the `find_font()` function and the `GLYPH_FONT` global (currently `icon-service.py:20-43`) with:

```python
# Logical font names -> ordered glob fallback chains. Resolution happens once at
# startup; a missing font degrades down its chain rather than returning a 500.
FONT_CHAINS = {
    "glyph": [
        # Narrow pattern FIRST and deliberately: "PragmataProVF*liga*.ttf" also matches
        # PragmataProVF_Italic_liga_09.ttf, which sorts BEFORE the upright face because
        # uppercase "I" (0x49) precedes lowercase "l" (0x6C). Do not "simplify" this away
        # -- doing so silently renders every glyph in italic.
        "{home}/Library/Fonts/PragmataProVF_liga_*.ttf",
        "{home}/Library/Fonts/PragmataProVF*liga*.ttf",
        "{home}/Library/Fonts/PragmataProVF*.ttf",
        "{home}/Library/Fonts/*Nerd*Font*.ttf",
        "/Library/Fonts/*Nerd*Font*.ttf",
    ],
    "display": [
        "{home}/Library/Fonts/Orbitron*.ttf",
        "/Library/Fonts/Orbitron*.ttf",
        "{home}/Library/Fonts/PragmataProVF*.ttf",
    ],
}

RESOLVED_FONTS = {}


def resolve_fonts():
    home = os.path.expanduser("~")
    for name, patterns in FONT_CHAINS.items():
        for pattern in patterns:
            matches = sorted(glob.glob(pattern.format(home=home)))
            if matches:
                RESOLVED_FONTS[name] = matches[0]
                print(f"[icon-service] font {name!r} -> {matches[0]}")
                break
        else:
            print(f"[icon-service] WARNING: no font resolved for {name!r}", file=sys.stderr)


resolve_fonts()
if "glyph" not in RESOLVED_FONTS:
    print("ERROR: no glyph font found.", file=sys.stderr)
    sys.exit(1)


def load_font(name, size, weight=None):
    """Load a logical font by name, falling back to the glyph chain."""
    path = RESOLVED_FONTS.get(name) or RESOLVED_FONTS["glyph"]
    font = ImageFont.truetype(path, size)
    if weight:
        try:
            font.set_variation_by_name(weight)
        except Exception:
            pass  # static font, or no such named instance
    return font
```

- [ ] **Step 7: Accept `font` / `glyph_font`, and render text-only tiles**

In `generate_icon()`, read the new parameters alongside the existing ones:

```python
    font_name = request.args.get("font", "glyph")
    glyph_font_name = request.args.get("glyph_font", "glyph")
    weight = request.args.get("weight")  # e.g. "Black" for variable fonts
```

Use `load_font(glyph_font_name, glyph_size)` where the glyph is drawn and
`load_font(font_name, label_size, weight)` where the label is drawn.

**Text-only tiles.** The six clock tiles carry no glyph. Two changes are required, and
both were verified against the running service before this plan was written:

`curl ".../generate?label=11&glyph="` returns **HTTP 500** —
`{"error": "invalid literal for int() with base 16: ''"}` — because
`int(glyph_hex, 16)` raises on an empty string. Default an absent or empty glyph to
`"0000"`, which is already this config's convention for "no glyph" (see the original
`init.lua:23`). U+0000 resolves to `.notdef`, which renders as nothing — verified, no
hollow box:

```python
    glyph_hex = request.args.get("glyph") or "0000"
```

Then treat codepoint 0 as the single sentinel for "no glyph", which controls **both**
skipping the glyph draw and centring the label:

```python
    glyph_unicode = int(glyph_hex, 16)
    has_glyph = glyph_unicode != 0
```

Guard the glyph drawing block with `if has_glyph:`, and centre the label vertically when
there is no glyph. The existing label placement pins text 5px from the bottom
(`label_y = size - 5 - label_bbox[3]`), which is correct for a caption beneath an icon and
wrong for a clock digit that should own the whole tile:

```python
        if has_glyph:
            label_y = size - 5 - label_bbox[3]      # caption under a glyph
        else:
            label_y = (size - label_h) / 2 - label_bbox[1]   # own the tile
```

- [ ] **Step 8: Report resolved fonts from `/health`**

Replace the body of the `health()` handler (`icon-service.py:121`) with:

```python
    return {"status": "ok", "fonts": RESOLVED_FONTS}
```

- [ ] **Step 9: Restart the service and verify font resolution**

```bash
launchctl kickstart -k gui/$(id -u)/net.r35.icon-service
sleep 2
curl -fsS http://127.0.0.1:5555/health
```

Expected JSON containing both `"glyph"` and `"display"`, with `"display"` pointing at `Orbitron[wght].ttf`.

- [ ] **Step 10: Verify the font parameter actually changes the output**

```bash
curl -fsS "http://127.0.0.1:5555/generate?label=11&font=display&label_size=48" -o /tmp/a.png
curl -fsS "http://127.0.0.1:5555/generate?label=11&font=glyph&label_size=48"   -o /tmp/b.png
cmp -s /tmp/a.png /tmp/b.png && echo "IDENTICAL - font param is not wired" || echo "DIFFERENT - correct"
```

Expected: `DIFFERENT - correct`

- [ ] **Step 11: Snapshot**

```bash
snap task06 ~/.hammerspoon/r35 ~/.hammerspoon/spec ~/.hammerspoon/icon-service.py
```

---

### Task 7: The Deck

**Files:**

- Create: `r35/deck.lua`, `spec/deck_spec.lua`
- Modify: `spec/all.lua`

**Interfaces:**

- Consumes: `Registry` (Task 4), `icons.key` / `icons.setButtonIcon` (Task 6).
- Produces:
  - `Deck.new(registry, layout, iconsModule) -> deck` — `iconsModule` is injected so tests can substitute a stub
  - `deck:attach(device)` / `deck:detach()`
  - `deck:resolve() -> { [index] = button }` — page composited over persistent
  - `deck:render([indices])` — `indices` is an optional `{ [index] = true }` filter
  - `deck:invalidate()` — clears the render cache, forcing a full redraw
  - `deck:press(index, pressed)` — dispatches to the button's action

- [ ] **Step 1: Write the failing tests**

Create `spec/deck_spec.lua`:

```lua
local t = require("spec.runner")
local hsFake = require("spec.fake_hs")
_G.hs = hsFake

local Registry = require("r35.registry")
local Deck = require("r35.deck")

-- Stub standing in for r35.icons: records what was drawn instead of doing HTTP.
local function stubIcons()
  local s = { drawn = {}, calls = 0 }
  s.key = function(opts)
    opts = opts or {}
    return tostring(opts.label or "") .. "|" .. tostring(opts.font or "")
  end
  s.setButtonIcon = function(_, index, opts)
    s.calls = s.calls + 1
    s.drawn[index] = s.key(opts)
  end
  return s
end

local function fixture(layout)
  hsFake.reset()
  local r = Registry.new()
  local icons = stubIcons()
  local d = Deck.new(r, layout, icons)
  d:attach("DEVICE")
  return d, icons, r
end

t.describe("deck", function()
  t.it("renders persistent buttons", function()
    local d, icons = fixture({ persistent = { [25] = { icon = { label = "MUTE" } } } })
    d:render()
    t.assertEquals(icons.drawn[25], "MUTE|")
  end)

  t.it("composites a page over the persistent layer", function()
    local d, icons = fixture({ persistent = {
      [25] = { icon = { label = "MUTE" } },
      [1]  = { icon = { label = "CAM"  } },
    } })
    d:setPage({ [1] = { icon = { label = "PLAY" } } })
    d:render()
    t.assertEquals(icons.drawn[1], "PLAY|", "page must win")
    t.assertEquals(icons.drawn[25], "MUTE|", "persistent must survive the page")
  end)

  t.it("suppresses a redundant render", function()
    local d, icons = fixture({ persistent = { [25] = { icon = { label = "MUTE" } } } })
    d:render()
    local first = icons.calls
    d:render()
    t.assertEquals(icons.calls, first, "identical icon key must not redraw")
  end)

  t.it("redraws when the icon key changes", function()
    local label = "A"
    local d, icons = fixture({ persistent = {
      [25] = { icon = function() return { label = label } end },
    } })
    d:render()
    label = "B"
    d:render()
    t.assertEquals(icons.drawn[25], "B|")
  end)

  t.it("invalidate forces a full redraw", function()
    local d, icons = fixture({ persistent = { [25] = { icon = { label = "MUTE" } } } })
    d:render()
    local first = icons.calls
    d:invalidate()
    d:render()
    t.assertEquals(icons.calls, first + 1)
  end)

  t.it("dispatches a press to the button's action", function()
    local fired = false
    local d = fixture({ persistent = {
      [25] = { icon = { label = "MUTE" }, action = function() fired = true end },
    } })
    d:press(25, true)
    t.assertTrue(fired)
  end)

  t.it("ignores the release half of a press", function()
    local count = 0
    local d = fixture({ persistent = {
      [25] = { icon = { label = "M" }, action = function() count = count + 1 end },
    } })
    d:press(25, true)
    d:press(25, false)
    t.assertEquals(count, 1)
  end)

  t.it("tolerates a press on an unmapped button", function()
    local d = fixture({ persistent = {} })
    d:press(7, true)
    t.assertNotNil(d)
  end)

  t.it("isolates a throwing action", function()
    local reached = false
    local d = fixture({ persistent = {
      [1] = { icon = { label = "X" }, action = function() error("boom") end },
      [2] = { icon = { label = "Y" }, action = function() reached = true end },
    } })
    d:press(1, true)
    d:press(2, true)
    t.assertTrue(reached)
  end)

  t.it("renders only the requested indices when filtered", function()
    local d, icons = fixture({ persistent = {
      [1] = { icon = { label = "A" } },
      [2] = { icon = { label = "B" } },
    } })
    d:render({ [1] = true })
    t.assertEquals(icons.drawn[1], "A|")
    t.assertNil(icons.drawn[2])
  end)
end)
```

- [ ] **Step 2: Register the suite and verify failure**

Add `"spec.deck_spec"` to `SUITES`, then:

```bash
cd ~/.hammerspoon && mise run test
```

Expected: FAIL — `module 'r35.deck' not found`.

- [ ] **Step 3: Write `r35/deck.lua`**

```lua
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
      local spec = iconSpec(button, self.registry)
      -- Diff BEFORE fetching: a suppressed tile costs one string comparison,
      -- no HTTP round trip and no USB write. This is what makes six clock
      -- tiles ticking once a minute effectively free.
      local key = self.icons.key(spec)
      if self.rendered[index] ~= key then
        self.rendered[index] = key
        self.icons.setButtonIcon(self.device, index, spec)
      end
    end
  end
end

function Deck:press(index, pressed)
  if not pressed then return end -- ignore the release half
  local button = self:resolve()[index]
  if not button or not button.action then return end
  local ok, err = xpcall(button.action, debug.traceback)
  if not ok then
    log.error("Deck", string.format("action for button %d failed: %s", index, err))
  end
end

-- Wire every button's `watch` list so a registry change re-renders just that
-- button, and re-render the whole deck whenever the hardware reappears.
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
  end
end

return Deck
```

- [ ] **Step 4: Run tests and verify they pass**

```bash
cd ~/.hammerspoon && mise run test
```

Expected: `28 passed, 0 failed`.

- [ ] **Step 5: Snapshot**

```bash
snap task07 ~/.hammerspoon/r35 ~/.hammerspoon/spec
```

---

### Task 8: Actions and clock

Fixes D11 (table passed where an application object is required) and D12 (application cached at load).

**Files:**

- Create: `r35/actions.lua`, `r35/clock.lua`, `spec/clock_spec.lua`
- Modify: `spec/all.lua`

**Interfaces:**

- Consumes: `Registry` (Task 4).
- Produces:
  - `actions.sendTo(bundleID, mods, key, [desc]) -> function()`
  - `actions.bindHotkey(fromMods, fromKey, action)`
  - `clock.fields([timeTable]) -> { weekday, month, day, hour, minute, meridiem }` — all strings
  - `clock.start(registry)` — publishes and maintains the `clock:minute` pseudo-device

- [ ] **Step 1: Write the failing clock tests**

Create `spec/clock_spec.lua`:

```lua
local t = require("spec.runner")
local hsFake = require("spec.fake_hs")
_G.hs = hsFake

local clock = require("r35.clock")

-- wday is 1=Sunday. 2026-08-21 is a Friday -> wday 6.
local function at(hour, min, opts)
  opts = opts or {}
  return {
    hour = hour, min = min,
    day = opts.day or 21, month = opts.month or 8,
    wday = opts.wday or 6, year = 2026,
  }
end

t.describe("clock.fields", function()
  t.it("formats a typical morning time", function()
    local f = clock.fields(at(11, 2))
    t.assertEquals(f.weekday, "FRI")
    t.assertEquals(f.month, "AUG")
    t.assertEquals(f.day, "21")
    t.assertEquals(f.hour, "11")
    t.assertEquals(f.minute, "02")
    t.assertEquals(f.meridiem, "AM")
  end)

  -- Midnight and noon are where naive hour % 12 arithmetic breaks.
  t.it("renders midnight as 12 AM", function()
    local f = clock.fields(at(0, 0))
    t.assertEquals(f.hour, "12")
    t.assertEquals(f.meridiem, "AM")
  end)

  t.it("renders noon as 12 PM", function()
    local f = clock.fields(at(12, 0))
    t.assertEquals(f.hour, "12")
    t.assertEquals(f.meridiem, "PM")
  end)

  t.it("converts afternoon hours to 12-hour form", function()
    local f = clock.fields(at(13, 5))
    t.assertEquals(f.hour, "01")
    t.assertEquals(f.minute, "05")
    t.assertEquals(f.meridiem, "PM")
  end)

  t.it("zero-pads the hour", function()
    t.assertEquals(clock.fields(at(9, 30)).hour, "09")
  end)

  t.it("does not pad the day of month", function()
    t.assertEquals(clock.fields(at(9, 0, { day = 8 })).day, "8")
  end)

  t.it("uses a fixed weekday table rather than locale formatting", function()
    t.assertEquals(clock.fields(at(9, 0, { wday = 1 })).weekday, "SUN")
    t.assertEquals(clock.fields(at(9, 0, { wday = 7 })).weekday, "SAT")
  end)

  t.it("uses a fixed month table", function()
    t.assertEquals(clock.fields(at(9, 0, { month = 1 })).month, "JAN")
    t.assertEquals(clock.fields(at(9, 0, { month = 12 })).month, "DEC")
  end)
end)
```

- [ ] **Step 2: Register the suite and verify failure**

Add `"spec.clock_spec"` to `SUITES`, then run `mise run test`.
Expected: FAIL — `module 'r35.clock' not found`.

- [ ] **Step 3: Write `r35/clock.lua`**

```lua
-- r35/clock.lua -- clock fields plus the clock:minute pseudo-device.
local M = {}

-- Fixed tables rather than os.date("%a")/("%b"): those are locale-dependent, and
-- a machine with a non-English locale would silently render the wrong strings.
local WDAY  = { "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT" }
local MONTH = { "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                "JUL", "AUG", "SEP", "OCT", "NOV", "DEC" }

function M.fields(t)
  t = t or os.date("*t")
  local hour12 = t.hour % 12
  if hour12 == 0 then hour12 = 12 end
  return {
    weekday  = WDAY[t.wday],
    month    = MONTH[t.month],
    day      = tostring(t.day),
    hour     = string.format("%02d", hour12),
    minute   = string.format("%02d", t.min),
    meridiem = t.hour < 12 and "AM" or "PM",
  }
end

local KEY = "clock:minute"

-- Poll every second but emit only when a displayed value actually changes.
-- Cheaper and more robust than aligning a timer to the minute boundary, which
-- drifts across sleep/wake.
function M.start(registry)
  local fields = M.fields()
  local last = table.concat({ fields.hour, fields.minute, fields.meridiem,
                              fields.day, fields.month, fields.weekday }, "|")
  registry:announce(KEY, fields)

  M._timer = hs.timer.doEvery(1, function()
    local f = M.fields()
    local stamp = table.concat({ f.hour, f.minute, f.meridiem,
                                 f.day, f.month, f.weekday }, "|")
    if stamp ~= last then
      last = stamp
      registry:update(KEY, f)
    end
  end)
end

return M
```

- [ ] **Step 4: Run tests and verify they pass**

```bash
cd ~/.hammerspoon && mise run test
```

Expected: `36 passed, 0 failed`.

- [ ] **Step 5: Write `r35/actions.lua`**

```lua
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

function M.bindHotkey(fromMods, fromKey, action)
  return hs.hotkey.bind(fromMods, fromKey, action)
end

return M
```

- [ ] **Step 6: Verify the D11 fix against a genuinely unfocused Teams**

Reload, put a terminal in front so Teams is **not** frontmost, then:

```bash
echo 'local a = require("r35.actions").sendTo("com.microsoft.teams2", {"cmd","shift"}, "m", "Toggle Mute")
a()
return "sent"' | hs
```

Watch Teams: its mute state must change while it is unfocused. If it does not, the target application is wrong — stop and investigate before continuing, because this is the project's core capability.

- [ ] **Step 7: Snapshot**

```bash
snap task08 ~/.hammerspoon/r35 ~/.hammerspoon/spec
```

---

### Task 9: Layout config and `init.lua` cutover

The switch. Everything before this was additive; this replaces the running config.

**Files:**

- Create: `config/layout.lua`
- Rewrite: `init.lua`
- Delete: `stream-deck-icons.lua` (superseded by `r35/icons.lua`)

**Interfaces:**

- Consumes: every module from Tasks 3-8.
- Produces: a running configuration.

- [ ] **Step 1: Take a pre-cutover snapshot**

There is no git here, so this is the only way back.

```bash
snap task09-pre ~/.hammerspoon/init.lua ~/.hammerspoon/stream-deck-icons.lua
```

- [ ] **Step 2: Write `config/layout.lua`**

```lua
-- config/layout.lua -- THE editing surface. Button data, not code.
--
-- Stream Deck XL grid:
--    1  2  3  4  5  6  7  8
--    9 10 11 12 13 14 15 16
--   17 18 19 20 21 22 23 24
--   25 26 27 28 29 30 31 32
local a     = require("r35.actions")
local clock = require("r35.clock")

local TEAMS = "com.microsoft.teams2"

-- Shared styling for the six clock tiles.
local function clockTile(field)
  return {
    icon = function(registry)
      local f = registry:get("clock:minute") or clock.fields()
      return {
        label       = f[field],
        label_size  = (field == "weekday" or field == "month") and 30 or 44,
        label_color = "F4F4F4",
        bg_color    = "000000",
        font        = "display",
        weight      = "Black", -- Orbitron is variable (400-900); the approved design is Black
        glyph       = "0000", -- no glyph; .notdef renders as nothing
      }
    end,
    watch = { "clock:minute" },
  }
end

return {
  persistent = {
    -- Camera in-use indicator.
    [1] = {
      icon = function(registry)
        local cam = registry:get("camera:Bob’s iPhone Camera")
        if cam == nil then
          return { glyph = "F1A15", glyph_color = "0075C3", bg_color = "013A6F",
                   label = "MISSING", label_color = "FFFFFF", label_size = 18 }
        end
        if cam:isInUse() then
          return { glyph = "F0100", glyph_color = "F4F4F4", bg_color = "C23E26",
                   label = "IN USE!", label_color = "FFFFFF", label_size = 18 }
        end
        return { glyph = "F05DF", glyph_color = "6A994E", bg_color = "000000",
                 label = "√ SAFE", label_color = "FFFFFF", label_size = 18 }
      end,
      watch = { "camera:Bob’s iPhone Camera" },
    },

    -- Microphone activity indicator. NOT a mute indicator: Teams mutes in-app
    -- and never touches CoreAudio, and the Scarlett reports muted(),
    -- inputMuted() and outputMuted() as nil. inUse() is the only honest signal.
    [9] = {
      icon = function(registry)
        local dev = registry:get("audio.in:default")
        local live = dev ~= nil and dev:inUse()
        return {
          glyph       = live and "F036C" or "F036D",
          glyph_color = live and "C23E26" or "6A994E",
          bg_color    = "000000",
          label       = live and "MIC LIVE" or "MIC IDLE",
          label_color = "FFFFFF",
          label_size  = 16,
        }
      end,
      watch = { "audio.in:default" },
    },

    -- Reactions.
    [3]  = { icon = { glyph = "F004",  glyph_color = "C23E26", bg_color = "000000",
                      label = "HEART", label_color = "FFFFFF", label_size = 18 } },
    [4]  = { icon = { glyph = "F194B", glyph_color = "D1B48F", bg_color = "000000",
                      label = "CLAP",  label_color = "FFFFFF", label_size = 18 } },
    [5]  = { icon = { glyph = "F12A",  glyph_color = "C23E26", bg_color = "000000",
                      label = "WOW",   label_color = "FFFFFF", label_size = 18 } },
    [11] = { icon = { glyph = "F0513", glyph_color = "D1B48F", bg_color = "000000",
                      label = "LIKE",  label_color = "FFFFFF", label_size = 18 } },
    [12] = { icon = { glyph = "F4A2",  glyph_color = "D1B48F", bg_color = "000000",
                      label = "SMILE", label_color = "FFFFFF", label_size = 18 } },

    -- Clock: date group 17-19, time group 22-24.
    [17] = clockTile("weekday"),
    [18] = clockTile("month"),
    [19] = clockTile("day"),
    [22] = clockTile("hour"),
    [23] = clockTile("minute"),
    [24] = clockTile("meridiem"),

    -- Call controls.
    [25] = {
      icon   = { glyph = "f131", glyph_color = "464EB8", bg_color = "000000",
                 label = "MUTE", label_color = "FFFFFF", label_size = 18 },
      action = a.sendTo(TEAMS, { "cmd", "shift" }, "m", "MS Teams: Toggle Mute"),
    },
    [29] = {
      icon   = { glyph = "F0A4F", glyph_color = "EBBD5F", bg_color = "000000",
                 label = "RAISE", label_color = "FFFFFF", label_size = 18 },
      action = a.sendTo(TEAMS, { "cmd", "shift" }, "k", "MS Teams: Raise/Lower Hand"),
    },
    [32] = {
      icon   = { glyph = "F0A48", glyph_color = "FFFFFF", bg_color = "FF0000",
                 label = "LEAVE", label_color = "FFFFFF", label_size = 18 },
      action = a.sendTo(TEAMS, { "cmd", "shift" }, "h", "MS Teams: Leave Call"),
    },
  },

  -- Keyboard chords bound to the same actions the buttons use.
  hotkeys = {
    { mods = { "rightctrl" }, key = "m",   bundleID = TEAMS, to = { { "cmd", "shift" }, "m" }, desc = "MS Teams: Toggle Mute" },
    { mods = { "rightctrl" }, key = "h",   bundleID = TEAMS, to = { { "cmd", "shift" }, "k" }, desc = "MS Teams: Raise/Lower Hand" },
    { mods = { "rightctrl" }, key = "end", bundleID = TEAMS, to = { { "cmd", "shift" }, "h" }, desc = "MS Teams: Leave Call" },
  },
}
```

- [ ] **Step 3: Rewrite `init.lua`**

```lua
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

-- hs.reload() destroys the Lua state and the timers it owns -- verified: a
-- doEvery(0.5) probe ticked 4 times in 2s before a pathwatcher-triggered reload
-- and 0 times after, with a pre-reload global reading nil afterwards.
-- So this teardown is NOT fixing a cross-reload leak. It is defensive hygiene for
-- the cases the runtime does not cover: an explicit second start() within one Lua
-- state, and a clean exit. Cheap, and it keeps ownership explicit.
--
-- (An earlier version of this comment claimed the opposite, citing a probe that
-- used `open -g hammerspoon://reloadConfig`. This config binds no hs.urlevent
-- handler, so that URL reloads nothing -- the probe measured a non-event.)
hs.shutdownCallback = function()
  log.info("Init", "tearing down before reload/exit")
  clock.stop()
  hs.camera.stopWatcher()
  hs.audiodevice.watcher.stop()
  if wakeWatcher then wakeWatcher:stop() end
  if configWatcher then configWatcher:stop() end
end

hs.alert.show("Config loaded")
```

- [ ] **Step 4: Reload and check the console for errors**

```bash
open -g hammerspoon://reloadConfig ; sleep 3
echo 'return hs.console.getConsole()' | hs | tail -40
```

Expected: no Lua tracebacks. Look for `[r35.StreamDeck][INFO] connected`, `[r35.Camera][INFO] discovered`, `[r35.Audio][INFO] default input`.

- [ ] **Step 5: Confirm the deck is actually lit**

Look at the physical device. Expected: reactions on 3/4/5/11/12, camera indicator on 1, mic indicator on 9, clock on 17/18/19 and 22/23/24, call controls on 25/29/32.

- [ ] **Step 6: Delete the superseded module**

Only once Step 5 passes:

```bash
rm ~/.hammerspoon/stream-deck-icons.lua
open -g hammerspoon://reloadConfig ; sleep 2
echo 'return "still alive"' | hs
```

Expected: `still alive`, deck still lit.

- [ ] **Step 7: Snapshot**

```bash
snap task09 ~/.hammerspoon/init.lua ~/.hammerspoon/config ~/.hammerspoon/r35
```

---

### Task 10: Acceptance verification

Walk the spec's acceptance criteria against the running system. Nothing is "done" until this passes.

**Files:** none created; updates `docs/design/2026-08-21-streamdeck-refactor.md` and closes `kata#wbyy`.

- [ ] **Step 1: Run the full test suite**

```bash
cd ~/.hammerspoon && mise run test
```

Expected: all green, exit code 0.

- [ ] **Step 2: Verify D1 — button 17 renders**

Look at the deck. Button 17 shows the weekday. This is the defect that started the project; under the old code it could never render.

- [ ] **Step 3: Verify replug behaviour**

Physically unplug the Stream Deck, wait five seconds, plug it back in.
Expected: console logs disconnect then connect, and **every** button redraws. A blank or partial deck means `whenAvailable` was used where `on(..., "available")` was required.

- [ ] **Step 4: Verify targeted send with Teams unfocused**

With a terminal frontmost, press button 25. Teams' mute state must change.

- [ ] **Step 5: Verify clock ticks and diff suppression**

Watch across a minute boundary. The minute tile changes; the weekday, month, and day tiles must not flicker or redraw.

```bash
echo 'return hs.console.getConsole()' | hs | grep -c "Icons.*HTTP"
```

Expected: no growth in HTTP errors while idling.

- [ ] **Step 6: Verify wake redraw**

Sleep the machine (`pmset sleepnow`), wake it, and confirm the deck is fully redrawn and the clock shows the correct current time rather than the pre-sleep time.

- [ ] **Step 7: Verify the launchd label**

```bash
launchctl list | grep -i icon-service
curl -fsS http://127.0.0.1:5555/health
```

Expected: only `net.r35.icon-service`; health reports both resolved fonts.

- [ ] **Step 8: Verify `$HOME` portability of the plist**

```bash
grep -c "/Users/bobsaska" ~/.hammerspoon/launchd/net.r35.icon-service.plist
```

Expected: `0`

- [ ] **Step 9: Tick off the spec's acceptance criteria**

Open the spec's "Acceptance criteria" section and check each box that now passes. Anything that fails goes back to its originating task — do not mark the work complete with unchecked boxes.

- [ ] **Step 10: Record outcomes and close the ticket**

Move the audio watcher event codes from "Assumptions requiring live verification" into "Verified facts", and record the D11 finding from Task 1 Step 5.

```bash
npx prettier --write ~/.hammerspoon/docs/design/2026-08-21-streamdeck-refactor.md
npx prettier --write ~/.hammerspoon/docs/plans/2026-08-21-streamdeck-refactor.md
kata close wbyy --done --message "<what shipped, which defects were confirmed live, anything deferred>"
```

Kata never auto-closes and no merge event will ever close it. If any acceptance criterion is still failing, do **not** close — use `kata label add wbyy needs-review` plus a comment describing what remains.

- [ ] **Step 11: Final snapshot**

```bash
snap task10-final ~/.hammerspoon/init.lua ~/.hammerspoon/r35 ~/.hammerspoon/config ~/.hammerspoon/spec ~/.hammerspoon/launchd ~/.hammerspoon/docs
```

---

## Deferred to a later plan

- **App-aware page switching.** `Deck:setPage()` and the composite layer exist and are tested; the `hs.application.watcher` that would drive them is not built.
- **Real Teams mute state** via `hs.axuielement`. Fragile; explicitly out of scope.
- **`chezmoi add`.** Only once this plan is complete and the config has run for a while on both machines. Add `icon-cache/` to `.gitignore` first.
