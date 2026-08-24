# Stream Deck XL / Hammerspoon Refactor — Design

**Date:** 2026-08-21
**Status:** Approved, pending implementation
**Tracking:** Kata (dotfiles ecosystem; deliberately not tracked in public repos)

## Context

`~/.hammerspoon/init.lua` has grown to 417 lines holding four unrelated concerns with no
internal boundaries. It drives an Elgato Stream Deck XL used primarily during work calls.
The Elgato software is not an option: it cannot send hotkeys to a _targeted_ application,
and closing that gap with its plugin ecosystem would mean adding Node.js packages to a
work machine — unacceptable supply-chain and install-friction cost.

Constraints that shape every decision below:

- **Must run on a locked-down work laptop.** No admin rights, no package managers assumed.
- **Different `$HOME` on each machine.** The username differs between personal and work.
- **Config will eventually be managed by chezmoi** (`~/.local/share/chezmoi`), which has
  `autoCommit`/`autoPush` enabled. Not adopted until this work is complete.
- **No git repository during this work**, by explicit decision. A scratchpad snapshot of
  the known-good config is the only safety net.

## Goals

1. Break `init.lua` into focused modules with clear interfaces.
2. Replace the broken device-discovery hook with a registry that has correct semantics.
3. Make the button layout declarative data rather than imperative calls.
4. Add clock tiles.
5. Fix the latent bugs found during design (enumerated below).

## Non-goals

- App-aware page switching. The seam is designed in; the mechanism is not built.
- Real Microsoft Teams mute state. Not observable without `hs.axuielement`; see Decisions.
- Window management. The existing block is deleted, not ported.

---

## Defects found in the current implementation

These were identified during design and are fixed as part of the work. Several would
survive a naive "just move the code into files" refactor.

### D1 — The discovery hook is logically inverted (the reported bug)

`init.lua:15-30` uses `hs.timer.doUntil`. Per
`/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/timer.lua:146`:

```lua
module.doUntil = function(predicateFn, actionFn, checkInterval)
  stopWatch = module.new(checkInterval, function()
    if not predicateFn() then actionFn(stopWatch)   -- runs WHILE predicate is false
    else stopWatch:stop() end                        -- stops WHEN predicate is true
  end):start()
```

The predicate is `deckXL ~= nil`. So while the deck is absent it calls
`setButtonIcon(nil, 17, ...)` once per second against a nil deck, and the moment the deck
appears it stops without ever running the action. Button 17 can never be set.

`hs.timer.waitUntil` (same file, line 118) has the assumed semantics. But polling is the
wrong shape regardless — see D2.

### D2 — Device APIs are single global callback slots

`hs.streamdeck.init`, `hs.camera.setWatcherCallback`, and
`hs.audiodevice.watcher.setCallback` each hold exactly **one** callback. They overwrite,
they do not append. Any second consumer silently displaces the first. This is the
structural reason a registry is required rather than merely convenient.

### D3 — Method call on a possibly-dead object

`init.lua:84` calls `deck:serialNumber()` unconditionally inside the discovery callback,
but that callback also fires with `isConnected = false` on disconnect.

### D4 — Camera and audio devices present at startup are invisible

`hs.streamdeck.init` replays already-connected decks to its callback. `hs.camera` and
`hs.audiodevice` watchers do **not** — they report only _changes_. Any device already
present when the config loads is never announced. The current code happens to paper over
this with a manual `allCameras()` scan; the audio path has no equivalent and the pattern
is not applied consistently.

### D5 — `hs.audiodevice.current()` returns the output device

Its parameter is documented as _"output — an optional boolean, true to fetch information
about the default **input** device, false for output device."_ The name and the semantics
disagree. `init.lua:416` passes no argument, defaults to `false`, and therefore logs the
default **output** device while appearing to report the microphone.

### D6 — launchd Label does not match its filename

The file is `~/Library/LaunchAgents/net.r35.icon-service.plist`; the `Label` inside is
`com.r35.icon-service`. launchd keys on the Label, confirmed by `launchctl list`. The
instructions at `init.lua:70-72` reference `com.r35.icon-service.plist`, which does not
exist on disk.

### D7 — The plist is not portable across machines

`Program` and `WorkingDirectory` hardcode `/Users/bobsaska`. launchd expands neither `~`
nor `$HOME` in those keys. (`icon-service.py`'s shebang is fine: `env -S` _does_ expand
`${HOME}`, braces mandatory — verified.)

### D8 — Icon cache key omits the font

`stream-deck-icons.lua:12` builds the cache key from glyph, colors, and label. Adding font
support without extending this key causes the first render in a new font to return the
cached PNG from the old one. Silent, and it presents as "the font parameter is broken."

### D9 — No error isolation in callbacks

A single throwing callback aborts the whole chain with no diagnostic, producing partial
deck updates that look like a rendering bug.

### D10 — `buttonLayout()` returns two values

At `init.lua:90` it is the final argument to `string.format`, so it expands to
`(columns, rows)`; the row count lands in an unused fourth argument and is discarded.

### D11 - Hotkey targeting passes a table where an application object is required

`hs.application.applicationsForBundleID` returns _a table of zero or more hs.application
objects_. `hs.eventtap.keyStroke`'s fourth parameter takes _an hs.application object_.
`init.lua:251` passes `appTeams` — the table — rather than `appTeams[1]`.

This is the targeting argument, i.e. the single capability the Elgato software could not
provide and the reason this project exists. The likely degradation is silent: keystrokes
fall through to the frontmost application, which looks correct whenever Teams already has
focus and fails precisely when it does not.

**Status: partially confirmed live over `hs.ipc` on 2026-08-21.** Microsoft Teams is not
installed on this machine, so `applicationsForBundleID("com.microsoft.teams2")` could only
be observed returning an empty table (`count=0 type=table first=nil`) — consistent with,
but not itself proof of, the type-mismatch claim. To confirm the shape `applicationsForBundleID`
returns for a match, the same call was made against `org.hammerspoon.Hammerspoon` (running,
not frontmost — `kitty`/the terminal held focus at the time):

```
count=1 type=table first=hs.application: Hammerspoon (0xa7e24a5b8) frontmost=net.kovidgoyal.kitty
```

This confirms the documented shape: the call always returns a table/array of `hs.application`
objects, never a bare object, so `init.lua:215`'s `appTeams` is a table and `init.lua:251`
does pass that table — not `appTeams[1]` — as `hs.eventtap.keyStroke`'s fourth argument.

Separately, `pcall(function() hs.eventtap.keyStroke({}, "escape", 0, appsTable) end)` (using
the `org.hammerspoon.Hammerspoon` table above in place of `appTeams`) returned `true, nil` —
no Lua error at the API boundary when a table is passed where the docs specify a single
`hs.application` object. So the type mismatch does not crash; whatever it does, it does
silently.

What remains **unconfirmed**: whether the keystroke, once it clears that silent type
mismatch, still reaches the (unfocused) target app correctly, falls through to the
frontmost app, or is dropped entirely. Verifying that requires a live delivery test against
an observable, unfocused target — but the frontmost application during this diagnosis was
the terminal running the active Hammerspoon-refactor agent session itself, so a live-fire
keystroke test risked injecting input into, or interrupting, that session. That test was
deliberately not run. Teams' absence from this machine means the specific scenario in this
defect (table passed for a real, running-but-unfocused Teams) was not exercised end to end
either. Either way, Task 8 passes `apps[1]`, which is correct regardless of how the
type-mismatch case currently degrades.

### D12 - Application lookup is cached at config load and never refreshed

`init.lua:215` resolves the Teams application once, at load time, and every hotkey closure
closes over that value. If Teams is not running when Hammerspoon starts, the table is empty
forever; if Teams restarts, the reference is stale. Resolution must happen at send time.

---

## Architecture

```
init.lua                 ~30 lines: require, wire, go
r35/
  log.lua                prefixed logging
  registry.lua           device event hub  <- the core of this work
  ipc.lua                hs.ipc + cliInstall with writable-prefix probe
  icons.lua              (was stream-deck-icons.lua) fetch + cache
  deck.lua               Deck: composite, diff, render, dispatch
  actions.lua            action constructors returning closures
  clock.lua              clock:minute pseudo-device
  devices/
    streamdeck.lua       owns hs.streamdeck.init
    camera.lua           owns hs.camera.setWatcherCallback + seeding
    audio.lua            owns hs.audiodevice.watcher + seeding
config/
  devices.lua            target device names
  layout.lua             THE editing surface
launchd/
  net.r35.icon-service.plist
spec/                    zero-dependency tests
docs/design/             this document
```

### Registry

Three functions:

```lua
Registry:whenAvailable(key, fn)   -- one-shot; setup work
Registry:on(key, event, fn)       -- persistent; event in {available, lost, changed}
Registry:get(key)                 -- synchronous peek, may return nil
```

Keys are namespaced strings: `streamdeck`, `streamdeck:<serial>`,
`camera:<name>`, `audio.in:default`, `clock:minute`. A bare class key matches the first
device of that class to appear.

**Replay is the fix for D1.** Registration order and device presence become independent:

```lua
function Registry:whenAvailable(key, fn)
  local dev = self.devices[key]
  if dev then
    hs.timer.doAfter(0, function() self:_safeCall(key, fn, dev) end)
  else
    table.insert(self.pending[key], fn)
  end
end
```

**Dispatch is always asynchronous, even when the device is already present.** Firing
synchronously when ready and asynchronously when not would give callers two different
execution orders depending on plug state at reload — the "don't release Zalgo" hazard. It
also prevents a handler that registers further handlers from mutating `pending` mid-iteration.

**One-shot versus persistent is a semantic distinction, not sugar.** `whenAvailable` fires
once ever, which suits setup. `on(key, "available")` fires on every reconnect, which the
deck requires because replugged hardware returns blank. Choosing wrong yields a dark deck
after a replug.

**Every dispatch is wrapped in `pcall`**, logging key and traceback (fixes D9).

**Disconnect must not touch the device object.** Adapters record identity at connect time
in a table keyed by the userdata and look it up on disconnect (fixes D3).

### Deck

Composites `persistent` beneath an optional `page` table, diffs the resulting icon spec
key per index against last-rendered state, and pushes only what changed. Diffing occurs
**before** the icon fetch, so a suppressed tile costs one string comparison — no HTTP, no
USB write. Owns a single `buttonCallback` that resolves the pressed index against the
composited layout and invokes its action, replacing the print-only stub at `init.lua:99`.

Re-render on reconnect uses `on("streamdeck", "available")`, not `whenAvailable`.

`hs.caffeinate.watcher` on `systemDidWake` invalidates the render cache and forces a full
redraw. Timers do not fire during sleep and the deck can return stale or blank.

### Layout as data

```lua
-- config/layout.lua
local a = require("r35.actions")

return {
  persistent = {
    [25] = { icon   = { glyph = "f131", label = "MUTE", glyph_color = "464EB8" },
             action = a.sendTo("com.microsoft.teams2", {"cmd","shift"}, "m") },

    [1]  = { icon = function(cam) ... end,
             watch = { "camera:Bob's iPhone Camera" } },

    [17] = { icon = function() ... end, watch = { "clock:minute" }, font = "display" },
  },
}
```

`icon` is a table or a function. `watch` lists registry keys whose `changed` events
re-render that button. That single field serves the camera indicator, the mic indicator,
and the clock tiles without additional machinery.

### Actions

Plain constructor functions returning closures; no class hierarchy. `a.sendTo(bundleID,
mods, key)` generalizes the existing `msTeamsHotKey`, and one declaration can bind to both
a deck button and a keyboard chord.

### Clock tiles

| Button | Content                    | Example |
| ------ | -------------------------- | ------- |
| 17     | weekday, 3 letters         | `FRI`   |
| 18     | month, 3 letters           | `AUG`   |
| 19     | day of month               | `21`    |
| 22     | hour, 12-hour, zero-padded | `04`    |
| 23     | minute, zero-padded        | `02`    |
| 24     | meridiem                   | `AM`    |

`r35/clock.lua` polls once per second and emits `changed` on `clock:minute` only when the
minute rolls over. All six tiles watch that one key; the deck's diff suppresses the date
tiles' 1,439 daily no-ops. No special-casing.

Steady-state cache: 60 + 12 + 2 + 7 + 12 + 31 = 124 PNGs per style. After one full day,
every render is a cache hit.

---

## Icon service changes

Named font registry with ordered fallback chains, resolved once at startup:

```python
FONTS = {
  "glyph":   ["PragmataProVF*liga*.ttf", "*Nerd*Font*.ttf"],
  "display": ["Orbitron*.ttf", "PragmataProVF*.ttf"],
}
```

- Glyph font and text font become separate parameters; clock tiles are text-only.
- `/health` reports resolved font paths per logical name, so a missing font surfaces as a
  startup warning rather than a subtly wrong deck.
- A missing font degrades down its chain; it never returns a 500.
- Orbitron is a variable font (weight axis 400-900, named instances Regular through
  Black). PIL exposes `set_variation_by_name`; tiles render at `Black`.
- **Cache key in `r35/icons.lua` must include every parameter that affects output**,
  fonts included (fixes D8). This coupling gets a comment.

Orbitron `[wght]` variable TTF installed to `~/Library/Fonts/` from Google Fonts (SIL OFL).

## launchd changes

Rewritten plist, byte-identical on every machine — no chezmoi templating needed:

```xml
<key>Label</key><string>net.r35.icon-service</string>
<key>ProgramArguments</key>
<array>
  <string>/bin/sh</string>
  <string>-c</string>
  <string>exec "$HOME/.hammerspoon/icon-service.py" >> "$HOME/Library/Logs/net.r35.icon-service.log" 2>&1</string>
</array>
```

The shell expands `$HOME` at launch, solving D7 for `Program` and `StandardOutPath`
alike. Canonical copy lives at `~/.hammerspoon/launchd/`, symlinked into
`~/Library/LaunchAgents/` — matching the existing `net.r35.mcp-hub.plist` pattern.

Migration: `bootout` label `com.r35.icon-service`, install, `bootstrap` under the new
label. Brief service gap; the icon cache covers already-rendered buttons.

## Testing

`spec/fake_hs.lua` provides the minimum `hs` surface with a controllable clock, so
`doAfter(0, ...)` is deterministic via an explicit `flush()`. `spec/runner.lua` is a
~60-line describe/it/assert harness returning a real exit code. Zero dependencies; runs
under `/opt/homebrew/bin/lua`. No luarocks, consistent with the work-machine constraint.

Covered: registry replay, one-shot versus persistent, error isolation, disconnect,
layout compositing, diff suppression, clock formatting.

Not covered by unit tests, verified live over `hs.ipc` with the physical deck: real
hardware behavior, icon service round-trip, actual rendering.

Runner: file-based mise task at `.mise/tasks/test`. Never TOML.

## Key decisions

| Decision            | Choice                                         | Rationale                                                          |
| ------------------- | ---------------------------------------------- | ------------------------------------------------------------------ |
| Discovery mechanism | Registry with async replay                     | Fixes D1 by construction; no timer to invert                       |
| Dispatch timing     | Always async, even when ready                  | Uniform ordering regardless of plug state                          |
| Page switching      | Seam only, not built                           | Cheap now, expensive to retrofit; unused today                     |
| Persistent layer    | Composite, not flat swap                       | Mute must survive page changes; avoids 32 USB writes per switch    |
| Actions             | Closures                                       | A class hierarchy buys nothing over Lua closures                   |
| Teams mute state    | Stateless toggle, no indicator                 | In-app mute never reaches CoreAudio; an indicator would desync     |
| Audio device        | `defaultInputDevice()`, key `audio.in:default` | Avoids D5; follows the default device with no hardcoded name       |
| Mic indicator       | `:inUse()`                                     | Honest signal, symmetric with the camera indicator                 |
| Plist portability   | `/bin/sh -c` expansion                         | Byte-identical across machines; no template rendering              |
| Test framework      | Hand-rolled, zero-dep                          | busted buys assertion sugar, not coverage; work-machine constraint |

## Acceptance criteria

- [x] Button 17 renders on deck connect — the D1 regression test
- [x] A handler registered _after_ the deck connects still fires
- [x] A handler registered _before_ the deck connects still fires
- [ ] Unplug then replug fully re-renders the deck
- [x] A throwing callback does not prevent other callbacks from running
- [x] Disconnect never calls a method on the deck object
- [x] A camera present at load is announced (D4)
- [ ] Pressing button 25 sends `cmd+shift+m` to Teams regardless of focus
- [x] Clock tiles 17/18/19/22/23/24 render and update on the minute
- [x] Clock tiles render in Orbitron; a missing font degrades without a 500
- [x] Date tiles do not re-render on minute ticks (diff suppression observable)
- [x] Changing only the font produces a different image (D8 regression test)
- [ ] Wake from sleep triggers a full redraw
- [x] `launchctl list` shows `net.r35.icon-service` and no `com.r35.icon-service`
- [x] `/health` reports resolved font paths
- [x] `echo 'return 1+1' | hs` returns 2
- [x] All spec tests pass with a zero exit code

14 of 17 confirmed 2026-08-21 during Task 10 acceptance verification. See
"Task 10 verification results" below for the evidence behind every check and
the reason each of the remaining three is unchecked rather than failed.

## Verified facts

Confirmed 2026-08-21 by the user against the physical hardware.

1. **`hs.streamdeck` returns the same userdata object on disconnect.** The disconnect
   key-lookup design is sound. Because the confirmation was hedged ("seems to be") and the
   failure mode is silent, the adapter keeps a fallback — but **not** a scan of the identity
   table, which would repeat the exact comparison the direct lookup already made. It falls
   back to the most recently connected serial, which is sound because this configuration
   drives exactly one deck. The identity table also uses strong keys: weak keys would let
   the entry be collected at precisely the moment of unplug.

2. **The Scarlett 2i2 reports `muted()`, `inputMuted()`, and `outputMuted()` as `nil`.**
   All three, not just the global one. There is no OS-level mute path on this interface at
   all, so a mute _indicator_ was never merely undesirable — it was never possible.
   `:inUse()` is the only honest audio signal available, which is exactly what the mic
   activity indicator uses.

3. **`hs.audiodevice.watcher` fires the single four-character code `dIn ` (with a
   trailing space, byte sequence `100 73 110 32`) on a default-input-device change.**
   Observed 2026-08-21 by scripting default-input switches with the device method
   `device:setDefaultInputDevice()` (there is no top-level
   `hs.audiodevice.setDefaultInputDevice`) between `MacBook Pro Microphone` and
   `AG06/AG03` and back, with the mic confirmed idle (`inUse=false`) before touching
   anything. The code matches CoreAudio's `kAudioHardwarePropertyDefaultInputDevice`
   selector. Only that one code was observed across both the switch-away and
   switch-back transitions; `r35/devices/audio.lua` does not branch on the event value
   and re-resolves unconditionally on any event, so this is confirmatory rather than
   load-bearing for correctness — but it closes the last open assumption in this spec.

## Assumptions requiring live verification

None.

## Open items

None. Hour padding resolved 2026-08-21: hours render zero-padded (`04`) for visual
symmetry with the minute tile, overriding the initial unpadded preference after reviewing
a rendered comparison of the worst case (single-digit hour beside a two-digit minute).

## Task 10 verification results (2026-08-21)

Full test suite: `mise run test` → `51 passed, 0 failed (Lua 5.5)`, exit code `0`.

14 of 17 acceptance criteria confirmed against the live, running system. The strongest
available check was used for each: unit tests where they exist, live `hs.ipc` introspection
against the running config, isolated exercises of the real (unmodified) production modules
under a fresh standalone Lua interpreter for the two device adapters with no unit-test
coverage, and direct `curl` calls against the icon service.

Notable evidence:

- **D1 (button 17):** `registry:on("streamdeck", "available", ...)` is used at
  `init.lua:30`, not `whenAvailable` — confirmed by reading the code. Two live config
  reloads (14:34:37 and 14:36:08) each produced a `[r35.StreamDeck][INFO] connected`
  log line immediately followed by a render pass with zero `[ERROR]` lines. The weekday
  tile's cache file (`FRI_...png`) reflects the actual current weekday. No physical camera
  is available to this agent to visually confirm the LCD bezel itself — the check is
  software-verified end-to-end (icon spec computed → diffed → fetched → `setButtonImage`
  called with no error), not a human eyeball on the hardware.
- **D3 (disconnect never calls a method on the deck object)** and **D4 (camera present at
  load is announced)** have no unit-test coverage (they wrap `hs.streamdeck`/`hs.camera`
  directly, per the spec's own Testing section) and, on this machine, no camera name
  actually present matches `config/devices.lua`'s watch list — so neither could be observed
  firing correctly against the _live_ registry. Both were instead confirmed by loading the
  real, unmodified `r35/devices/streamdeck.lua` and `r35/devices/camera.lua` into a fresh
  standalone Lua process with a minimal fake `hs.streamdeck`/`hs.camera` surface: the
  camera-adapter test showed `registry:announce()` firing for a camera present at
  `M.start()` time, before any watcher callback ran; the streamdeck-adapter test connected
  a fake deck, then made every method on that same object throw before "disconnecting" it —
  the real disconnect handler never called them (revocation happens via the `serials`
  identity table, not a method call) and both `streamdeck` and `streamdeck:<serial>` keys
  were correctly revoked.
- **D8 (font-only key change):** confirmed twice — once via `spec/icons_spec.lua`
  ("changes when only the font changes"), and again live end-to-end against the running
  `icon-service.py`: identical `glyph`/`label` with `font=glyph` vs `font=display` produced
  two PNGs with different MD5 hashes.
- **Missing-font degradation:** `curl` against `/generate` with a nonexistent font name
  returned HTTP `200`, not `500`.
- **Diff suppression:** `icon-cache/` files for the date tiles (`FRI_...`, `AUG_...`,
  `21_...`, `PM_...`) carry a single mtime (14:31) unchanged across a 17-minute observation
  window, while the minute tile produced a new cache file every single minute in that same
  window (`31_...` through `48_...`), tracking the wall clock exactly.
- **Button 25 / Teams graceful degradation:** Teams is not installed on this machine, so
  `hs.application.applicationsForBundleID("com.microsoft.teams2")` returns an empty table.
  Invoking the exact production closure bound to button 25 live confirmed the D12 "not
  running" branch: a warning was logged, an alert shown, and — critically —
  `hs.eventtap.keyStroke` was never reached (the function returns early on an empty table),
  so this check carried no risk of an errant keystroke landing anywhere.

### Deferred to the user — not verifiable by this agent

Three criteria require a physical action this agent was explicitly barred from taking, or
an application not present on this machine. All three are backed by code review and/or
live checks of their non-hardware-dependent paths; none is known to fail.

| Criterion                                                           | Why it's deferred                                                                                                                                                                                                                                                                                         |
| ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Unplug then replug fully re-renders the deck                        | Physically unplugging the Stream Deck was out of scope for this agent. Backed by `registry_spec`'s "fires on(available) on EVERY reconnect" and `deck_spec`'s "available triggers a render too" tests, and by `init.lua` using `on(..., "available")` rather than `whenAvailable` (code-reviewed).        |
| Pressing button 25 sends `cmd+shift+m` to Teams regardless of focus | Microsoft Teams is not installed on this machine. `a.sendTo` was confirmed to resolve `apps[1]` at send time (D11/D12, `r35/actions.lua:40`) and to degrade gracefully when Teams isn't running (see above). The actual targeted-delivery-while-unfocused behavior needs Teams on the user's work laptop. |
| Wake from sleep triggers a full redraw                              | `pmset sleepnow` was explicitly off-limits mid-workday. `init.lua`'s `hs.caffeinate.watcher` calls `deck:invalidate()` then `deck:render()` on `systemDidWake` (code-reviewed, lines 55-61) — matches the design exactly, but a real sleep/wake cycle was not exercised.                                  |

None of the checks performed surfaced a failure. The three deferred items are the only
gap between "14 confirmed" and "17 confirmed."
