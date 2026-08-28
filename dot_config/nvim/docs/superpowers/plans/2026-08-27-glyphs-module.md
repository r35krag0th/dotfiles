# `r35.glyphs` Unified Glyph Module — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fold Nerd Font name lookup into `r35.glyphs`, so one package covers what a glyph is called, how wide it renders, and how to fit it into a constrained space.

**Architecture:** `lua/r35/glyphs.lua` becomes `lua/r35/glyphs/init.lua`, a thin facade over `blocks.lua` (width declaration), `width.lua` (measurement, application, fitting), `icons.lua` (name lookup), and a generated `data.lua`. A `scripts/gen_glyphs.lua` generator produces `data.lua` from WezTerm's data and audits `blocks.lua` against real font metrics. `:checkhealth r35.glyphs` surfaces disagreement.

**Tech Stack:** Lua (LuaJIT, via Neovim), `nvim -l` for scripts, `curl` for fetching, `python3` + `fontTools` for font measurement (dev-time only, `--audit` path only), plain headless-nvim test scripts.

**Spec:** `docs/superpowers/specs/2026-08-27-glyphs-module-design.md`

## Global Constraints

- **Lua flavour is LuaJIT.** No `utf8` stdlib. Use `vim.fn.nr2char`, `vim.fn.str2list`, `vim.fn.strchars`, `vim.fn.strdisplaywidth`.
- **`\u{XXXX}` string escapes are supported** and are used throughout this config. Prefer them to literal PUA characters — literals are unreadable in a diff.
- **Formatting:** `stylua.toml` — 2-space indent, 120 column width. Run `stylua` on every Lua file you touch.
- **Runtime has zero external dependencies.** `python3`/`fontTools` and `curl` may be used only by `scripts/gen_glyphs.lua`. Nothing under `lua/` may shell out or touch the network.
- **`require("r35.glyphs")` must keep working with its current members** — `ranges`, `setup`, `fit_sign` — throughout. Three call sites depend on it: `init.lua:22`, `lua/plugins/diagnostics.lua:26`, `tests/glyphs_sign_test.lua:22`.
- **`M.ranges` array shape is load-bearing.** `tests/glyphs_sign_test.lua` iterates `range[1]`/`range[2]`. Keep `{ first, last, width }[]`.
- **The `fit`/`fit_sign` truncation warning must contain the word `truncated`.** `tests/glyphs_sign_test.lua` matches on it.
- **This directory is not a git repository.** `.gitignore` exists, `.git` does not, and there is no parent repo. Every task therefore ends with a **Checkpoint** (run the full suite) instead of a commit. If you want commit points, run `git init && git add -A && git commit -m "chore: baseline"` first — that is your call, not this plan's.
- **Test invocation:** `nvim --headless -c 'luafile ~/.config/nvim/tests/<name>.lua'`. Exits non-zero on failure via `vim.cmd("cq")`.
- **Reference font for all width claims:** `~/Library/Fonts/PragmataProVF_liga_09.ttf`, which is what kitty's `font_family PragmataPro VF Liga` resolves to on this machine. Advance widths are measured against `M` = 1024 units; 2048 means two cells.

---

## File Structure

| File                          | Responsibility                                          |
| ----------------------------- | ------------------------------------------------------- |
| `lua/r35/glyphs/init.lua`     | Facade. Re-exports the public API. No logic.            |
| `lua/r35/glyphs/blocks.lua`   | The width declaration. Pure data, no requires.          |
| `lua/r35/glyphs/width.lua`    | Derive ranges, apply via `setcellwidths`, measure, fit. |
| `lua/r35/glyphs/icons.lua`    | Name lookup, `get`/`has`/`sign`, unknown-name handling. |
| `lua/r35/glyphs/data.lua`     | GENERATED. Name → glyph. Pure data, no requires.        |
| `lua/r35/glyphs/health.lua`   | `:checkhealth r35.glyphs`.                              |
| `scripts/gen_glyphs.lua`      | Generate `data.lua`; audit `blocks.lua` against a font. |
| `tests/icons_test.lua`        | New. Lookup behaviour.                                  |
| `tests/glyphs_width_test.lua` | New. Measurement and fitting helpers.                   |
| `tests/glyphs_sign_test.lua`  | Existing. Unchanged behaviour; prose touch-ups only.    |

---

## Task 1: Split `glyphs.lua` into a package, preserving the API

Behaviour-preserving refactor. Nothing observable changes. The existing test suite is the specification.

**Files:**

- Create: `lua/r35/glyphs/blocks.lua`
- Create: `lua/r35/glyphs/width.lua`
- Create: `lua/r35/glyphs/init.lua`
- Delete: `lua/r35/glyphs.lua`
- Test: `tests/glyphs_sign_test.lua` (existing, unmodified)

**Interfaces:**

- Consumes: nothing.
- Produces:
  - `require("r35.glyphs.blocks")` → `r35.glyphs.Block[]` where `Block = { name: string, first: integer, last: integer, cells: integer }`
  - `require("r35.glyphs.width")` → `{ ranges: integer[][], setup: fun(), fit_sign: fun(text: string): string }`
  - `require("r35.glyphs")` → `{ ranges, setup, fit_sign }` (unchanged public surface)

- [ ] **Step 1: Record the baseline**

```bash
nvim --headless -c 'luafile ~/.config/nvim/tests/glyphs_sign_test.lua'; echo "exit=$?"
```

Expected: all checks `ok`, `exit=0`. Write the passed/failed counts down. This exact output must reappear at Step 6.

- [ ] **Step 2: Create `lua/r35/glyphs/blocks.lua`**

Transcribe the existing `M.ranges` verbatim. Do **not** fix any widths here — Task 3 owns that, with measurements attached.

```lua
---Nerd Font glyph cell widths, declared as blocks.
---
---This is THE declaration. `width.lua` derives its `setcellwidths()` ranges from
---it, `scripts/gen_glyphs.lua --audit` checks it against real font metrics, and
---it mirrors ~/.config/kitty/conf.d/nerd_font_widths.conf.
---
---PragmataPro draws every Nerd Font glyph at 2048 units against its normal 1024
---- exactly double width - while wcwidth reports 1. Terminals therefore either
---squash the glyph into one cell or let it draw at full width and clip it.
---Declaring them two cells wide renders them at their designed size.
---
---IMPORTANT: kitty is told the same widths in
---~/.config/kitty/conf.d/nerd_font_widths.conf. These two lists MUST stay in
---sync. `:checkhealth r35.glyphs` reports when they drift.
---
---Powerline (U+E0A0-U+E0D7) is deliberately absent, but not as a policy: the
---font measures it at 1024 units, i.e. one cell. It is excluded because that is
---what it is, not because we decided so.

---@class r35.glyphs.Block
---@field name string    human label; mirrors the kitty conf comment
---@field first integer  first codepoint, inclusive
---@field last integer   last codepoint, inclusive
---@field cells integer  display cells

---@type r35.glyphs.Block[]
return {
  { name = "Pomicons", first = 0x0E000, last = 0x0E00A, cells = 2 },
  { name = "Font Awesome Extension", first = 0x0E200, last = 0x0E2A9, cells = 2 },
  { name = "Weather", first = 0x0E300, last = 0x0E3E3, cells = 2 },
  { name = "Seti-UI / Custom", first = 0x0E5FA, last = 0x0E6B7, cells = 2 },
  { name = "Devicons", first = 0x0E700, last = 0x0E8EF, cells = 2 },
  { name = "Codicons", first = 0x0EA60, last = 0x0EC1E, cells = 2 },
  { name = "Font Awesome", first = 0x0ED00, last = 0x0F2FF, cells = 2 },
  { name = "Font Logos", first = 0x0F300, last = 0x0F381, cells = 2 },
  { name = "Octicons", first = 0x0F400, last = 0x0F533, cells = 2 },
  { name = "Material Design", first = 0xF0001, last = 0xF1AF0, cells = 2 },
  { name = "Warning sign", first = 0x026A0, last = 0x026A0, cells = 2 },
}
```

- [ ] **Step 3: Create `lua/r35/glyphs/width.lua`**

Move `reserved`, `carve`, `setup`, `intended_width`, `intended_cells`, `fit_sign`, and `SIGN_CELLS` across **unmodified**, keeping every comment. The only new code is the `M.ranges` derivation at the top.

```lua
---Applying, measuring, and fitting glyph widths.
---
---Ranges are derived from `blocks.lua` rather than declared here, so the
---declaration has exactly one home.

local blocks = require("r35.glyphs.blocks")

local M = {}

---@type integer[][] { first, last, width }
---Back-compat shape: `tests/glyphs_sign_test.lua` indexes these positionally,
---and `r35.glyphs.ranges` has always been an array of arrays.
M.ranges = {}
for _, b in ipairs(blocks) do
  M.ranges[#M.ranges + 1] = { b.first, b.last, b.cells }
end
```

Then paste, verbatim from `lua/r35/glyphs.lua`:

1. `reserved()` — unchanged.
2. `carve(ranges, excluded)` — unchanged.
3. `M.setup()` — unchanged, but the notify prefix stays `"r35.glyphs: "`.
4. `SIGN_CELLS`, `intended_width`, `intended_cells` — unchanged, still `local`.
5. `M.fit_sign(text)` — unchanged, notify prefix stays `"r35.glyphs: "`.

End with `return M`.

- [ ] **Step 4: Create `lua/r35/glyphs/init.lua`**

```lua
---Nerd Font glyphs: names, widths, and fitting.
---
---This is a facade. Nothing is implemented here.
---
---  r35.glyphs.blocks  the width declaration
---  r35.glyphs.width   applying, measuring, fitting
---  r35.glyphs.icons   name lookup
---  r35.glyphs.data    GENERATED name -> glyph
---
---`require("r35.glyphs")` resolves to this file, so every existing call site
---keeps working unchanged.

local width = require("r35.glyphs.width")

local M = {}

M.ranges = width.ranges
M.setup = width.setup
M.fit_sign = width.fit_sign

return M
```

- [ ] **Step 5: Delete the old module**

```bash
rm ~/.config/nvim/lua/r35/glyphs.lua
```

- [ ] **Step 6: Verify the baseline is unchanged**

```bash
nvim --headless -c 'luafile ~/.config/nvim/tests/glyphs_sign_test.lua'; echo "exit=$?"
```

Expected: identical passed/failed counts to Step 1, `exit=0`. Any difference means the refactor changed behaviour — fix it before proceeding.

- [ ] **Step 7: Verify nvim still starts**

```bash
nvim --headless -c 'lua print(vim.inspect(#require("r35.glyphs").ranges))' -c 'qa!'
```

Expected: `11`.

- [ ] **Step 8: Format and checkpoint**

```bash
stylua ~/.config/nvim/lua/r35/glyphs/
nvim --headless -c 'luafile ~/.config/nvim/tests/glyphs_sign_test.lua'; echo "exit=$?"
```

Expected: `exit=0`.

---

## Task 2: Promote the width helpers to public API

`intended_width` and `intended_cells` are private today. Promote them, and generalise `fit_sign` into `fit(text, cells)`.

**Files:**

- Modify: `lua/r35/glyphs/width.lua`
- Modify: `lua/r35/glyphs/init.lua`
- Test: `tests/glyphs_width_test.lua` (create)

**Interfaces:**

- Consumes: `require("r35.glyphs.width")` from Task 1.
- Produces:
  - `width.width(cp: integer): integer` — declared cells for one codepoint
  - `width.cells(text: string): integer` — declared cells for a string
  - `width.fit(text: string, budget: integer): string` — clamp to `budget` cells
  - `width.fit_sign(text: string): string` — `fit(text, 2)`, unchanged behaviour

- [ ] **Step 1: Write the failing test**

Create `tests/glyphs_width_test.lua`:

```lua
-- Tests for the public width helpers in `r35.glyphs.width`.
--
--   nvim --headless -c 'luafile ~/.config/nvim/tests/glyphs_width_test.lua'
--
-- The contract that matters: these answer "how wide will this be once setup()
-- has run", and give the SAME answer from either side of that call. That is why
-- they consult the declared ranges rather than `strdisplaywidth`, which reports
-- the table currently installed and is therefore order-dependent.

local ok, glyphs = pcall(require, "r35.glyphs")
if not ok then
  print("FAIL require r35.glyphs: " .. tostring(glyphs))
  vim.cmd("cq")
end

local pass, fail = 0, 0
local function check(name, cond, extra)
  if cond then
    pass = pass + 1
    print("  ok   " .. name)
  else
    fail = fail + 1
    print("  FAIL " .. name .. (extra and ("  -> " .. tostring(extra)) or ""))
  end
end

local NERD = vim.fn.nr2char(0xF057) -- fa, inside a declared 2-cell range
local ASCII = "E"

-- Deliberately BEFORE setup(): the answer must not depend on this.
vim.fn.setcellwidths({})

check("width() of ASCII is 1", glyphs.width(0x45) == 1, glyphs.width(0x45))
check("width() of a declared glyph is 2", glyphs.width(0xF057) == 2, glyphs.width(0xF057))
check("cells() of ASCII is 1", glyphs.cells(ASCII) == 1, glyphs.cells(ASCII))
check("cells() of a declared glyph is 2", glyphs.cells(NERD) == 2, glyphs.cells(NERD))
check("cells() sums across a string", glyphs.cells(NERD .. ASCII) == 3, glyphs.cells(NERD .. ASCII))

local before_width = glyphs.width(0xF057)
local before_cells = glyphs.cells(NERD .. " ")

glyphs.setup()

check("width() is order-independent", glyphs.width(0xF057) == before_width, glyphs.width(0xF057))
check("cells() is order-independent", glyphs.cells(NERD .. " ") == before_cells, glyphs.cells(NERD .. " "))

check("fit() leaves a string that already fits", glyphs.fit(NERD, 2) == NERD)
check("fit() sheds padding to make room", glyphs.fit(NERD .. " ", 2) == NERD, glyphs.fit(NERD .. " ", 2))
check("fit() honours a larger budget", glyphs.fit(NERD .. " ", 3) == NERD .. " ", glyphs.fit(NERD .. " ", 3))
check("fit() honours a budget of 4", glyphs.cells(glyphs.fit(NERD .. NERD, 4)) == 4)

-- Genuine overflow: whole codepoints only, and it must say so.
local notified
local real_notify = vim.notify
vim.notify = function(msg)
  notified = msg
end
local squeezed = glyphs.fit(NERD .. NERD, 2)
vim.notify = real_notify

check("fit() truncates to the budget", glyphs.cells(squeezed) == 2, glyphs.cells(squeezed))
check("fit() truncates whole codepoints", vim.fn.strchars(squeezed) == 1, vim.fn.strchars(squeezed))
check("fit() warns on truncation", notified ~= nil and notified:match("truncated") ~= nil, notified)

check("fit_sign is fit(text, 2)", glyphs.fit_sign(NERD .. " ") == glyphs.fit(NERD .. " ", 2))

print(string.format("\n%d passed, %d failed", pass, fail))
vim.cmd(fail > 0 and "cq" or "qa!")
```

- [ ] **Step 2: Run it and watch it fail**

```bash
nvim --headless -c 'luafile ~/.config/nvim/tests/glyphs_width_test.lua'; echo "exit=$?"
```

Expected: FAIL, `exit=1`, with errors about calling a nil value (`glyphs.width`, `glyphs.cells`, `glyphs.fit` do not exist yet).

- [ ] **Step 3: Promote the helpers in `width.lua`**

Rename the two locals to module members and generalise the fitter. Keep every existing comment — they explain _why_ `strdisplaywidth` is the wrong instrument, which is the whole point of these functions.

```lua
---Width `cp` will occupy once `setup()` has run -- whether or not it has yet.
---
---`strdisplaywidth` reports the table currently installed, which makes it the
---wrong instrument here: plugin `opts` are resolved while `require("config.lazy")`
---runs, and init.lua cannot call `setup()` until after that returns. An icon
---measured in that window is still one cell wide and looks like it fits, right
---up until `setup()` widens it out from under the stored value.
---
---Consulting the declared blocks instead answers the question that actually
---matters -- how wide will this end up? -- identically from either side.
---@param cp integer
---@return integer
function M.width(cp)
  for _, range in ipairs(M.ranges) do
    if cp >= range[1] and cp <= range[2] then
      return range[3]
    end
  end
  return vim.fn.strdisplaywidth(vim.fn.nr2char(cp))
end

---Declared width of every codepoint in `text`, summed.
---@param text string
---@return integer
function M.cells(text)
  local total = 0
  for _, cp in ipairs(vim.fn.str2list(text)) do
    total = total + M.width(cp)
  end
  return total
end

---Fit `text` into a `budget` of display cells.
---
---Widths come from the declared blocks, so this tracks them on its own: widen a
---block and the glyphs inside it start getting trimmed, with no second list to
---keep in sync and no constraint on when this may be called.
---@param text string
---@param budget integer
---@return string
function M.fit(text, budget)
  if M.cells(text) <= budget then
    return text
  end

  -- The common case: padding that used to fit and no longer does.
  local trimmed = vim.trim(text)
  if M.cells(trimmed) <= budget then
    return trimmed
  end

  -- Genuinely too wide. Drop whole codepoints rather than bytes so the result
  -- stays valid UTF-8, and say so out loud: a silently clipped icon reads as a
  -- font problem and sends you hunting in entirely the wrong place.
  local fitted, used = "", 0
  for _, cp in ipairs(vim.fn.str2list(trimmed)) do
    local cost = M.width(cp)
    if used + cost > budget then
      break
    end
    fitted, used = fitted .. vim.fn.nr2char(cp), used + cost
  end

  vim.notify(
    ("r35.glyphs: %q is %d cells, truncated to %q"):format(trimmed, M.cells(trimmed), fitted),
    vim.log.levels.WARN
  )
  return fitted
end

---Neovim's sign column is two cells wide and `sign_text` may not exceed it.
local SIGN_CELLS = 2

---Fit `text` into the sign column's two-cell budget.
---@param text string
---@return string
function M.fit_sign(text)
  return M.fit(text, SIGN_CELLS)
end
```

Delete the now-redundant `intended_width` and `intended_cells` locals and the old `M.fit_sign` body.

- [ ] **Step 4: Re-export from the facade**

In `lua/r35/glyphs/init.lua`, add below the existing assignments:

```lua
M.width = width.width
M.cells = width.cells
M.fit = width.fit
```

- [ ] **Step 5: Run both suites**

```bash
nvim --headless -c 'luafile ~/.config/nvim/tests/glyphs_width_test.lua'; echo "width exit=$?"
nvim --headless -c 'luafile ~/.config/nvim/tests/glyphs_sign_test.lua'; echo "sign exit=$?"
```

Expected: both `exit=0`. The sign suite matters here — it asserts the truncation warning contains `truncated`, which the reworded message above still satisfies.

- [ ] **Step 6: Format and checkpoint**

```bash
stylua ~/.config/nvim/lua/r35/glyphs/
```

---

## Task 3: Fix the seven measured width defects

Seven codepoints where `blocks.lua` disagrees with the font. Five clip, two waste a half-cell. Each change below carries its measured advance width.

**Files:**

- Modify: `lua/r35/glyphs/blocks.lua`
- Modify: `lua/plugins/todo-comments.lua:23` (comment only)
- Test: `tests/glyphs_width_test.lua` (extend)

**Interfaces:**

- Consumes: `require("r35.glyphs").width` from Task 2.
- Produces: no new API. `blocks.lua` gains four entries and one narrowed range.

- [ ] **Step 1: Write the failing test**

Append to `tests/glyphs_width_test.lua`, immediately before the final `print`/`vim.cmd` lines:

```lua
-- Measured against ~/Library/Fonts/PragmataProVF_liga_09.ttf, advance vs M=1024.
-- Regenerate this table with: nvim -l scripts/gen_glyphs.lua --audit
local MEASURED = {
  { 0x23F2, 2, "timer clock (todo-comments TEST)" },
  { 0x23FB, 2, "iec_power" },
  { 0x23FC, 2, "iec_toggle_power" },
  { 0x23FD, 1, "iec_power_on" },
  { 0x23FE, 2, "iec_sleep_mode" },
  { 0x2B58, 1, "iec_power_off" },
  { 0x2665, 2, "oct_heart" },
  { 0x26A0, 2, "warning sign" },
  { 0x26A1, 1, "oct_zap -- adjacent to 26A0 but genuinely 1 cell" },
  { 0xE008, 2, "pom_ last correct entry" },
  { 0xE009, 1, "pom_internal_interruption" },
  { 0xE00A, 1, "pom_external_interruption" },
  { 0xE0A0, 1, "pl_branch -- Powerline is 1 cell by measurement" },
}
for _, m in ipairs(MEASURED) do
  local cp, want, label = m[1], m[2], m[3]
  check(("U+%04X declared %d cell(s) -- %s"):format(cp, want, label), glyphs.width(cp) == want, glyphs.width(cp))
end
```

- [ ] **Step 2: Run it and watch it fail**

```bash
nvim --headless -c 'luafile ~/.config/nvim/tests/glyphs_width_test.lua'; echo "exit=$?"
```

Expected: FAIL, `exit=1`, with exactly seven failing checks: U+23F2, U+23FB, U+23FC, U+23FE, U+2665 reporting `1` where `2` is wanted, and U+E009, U+E00A reporting `2` where `1` is wanted.

- [ ] **Step 3: Narrow the Pomicons block**

In `lua/r35/glyphs/blocks.lua`, replace the Pomicons entry:

```lua
  -- U+E009 and U+E00A measure 1024 units (one cell); the rest of the block is
  -- 2048. Declaring the whole block two cells left a dead half-cell after each.
  { name = "Pomicons", first = 0x0E000, last = 0x0E008, cells = 2 },
```

- [ ] **Step 4: Add the four missing entries**

Insert immediately before the `Warning sign` entry, keeping the table roughly codepoint-ordered:

```lua
  -- Non-PUA glyphs PragmataPro nonetheless draws at 2048 units. They clip
  -- without this, exactly the way U+26A0 did. U+23FD and U+2B58 sit between
  -- these and measure 1024, which is why the IEC range is split rather than
  -- declared 23FB-23FE wholesale.
  { name = "Timer clock", first = 0x023F2, last = 0x023F2, cells = 2 },
  { name = "IEC power / toggle power", first = 0x023FB, last = 0x023FC, cells = 2 },
  { name = "IEC sleep mode", first = 0x023FE, last = 0x023FE, cells = 2 },
  { name = "Black heart suit", first = 0x02665, last = 0x02665, cells = 2 },
```

- [ ] **Step 5: Run the tests**

```bash
nvim --headless -c 'luafile ~/.config/nvim/tests/glyphs_width_test.lua'; echo "width exit=$?"
nvim --headless -c 'luafile ~/.config/nvim/tests/glyphs_sign_test.lua'; echo "sign exit=$?"
```

Expected: both `exit=0`. The sign suite samples every range including the four new ones.

- [ ] **Step 6: Correct the false comment in `todo-comments.lua`**

Line 23 currently reads:

```lua
      TEST = { icon = "\u{23F2}" }, -- timer clock (not PUA, already one cell)
```

The parenthetical is wrong — the font draws U+23F2 at 2048 units. Replace with:

```lua
      TEST = { icon = "\u{23F2}" }, -- timer clock (not PUA, but still 2 cells)
```

- [ ] **Step 7: Emit the kitty conf delta**

`blocks.lua` and `~/.config/kitty/conf.d/nerd_font_widths.conf` are now out of sync. This plan does not write kitty's config. Print what needs changing and hand it to the user:

```bash
cat <<'EOF'
Apply to ~/.config/kitty/conf.d/nerd_font_widths.conf:

  # Pomicons  -- narrow: E009/E00A measure 1 cell
  - narrow_symbols U+E000-U+E00A 2
  + narrow_symbols U+E000-U+E008 2

  # add, before the warning-sign entry:
  + # Timer clock
  + narrow_symbols U+23F2 2
  + # IEC power / toggle power
  + narrow_symbols U+23FB-U+23FC 2
  + # IEC sleep mode
  + narrow_symbols U+23FE 2
  + # Black heart suit
  + narrow_symbols U+2665 2

Then reload kitty (ctrl+shift+F5).
EOF
```

- [ ] **Step 8: Format and checkpoint**

```bash
stylua ~/.config/nvim/lua/r35/glyphs/ ~/.config/nvim/lua/plugins/todo-comments.lua
```

---

## Task 4: Generator — produce `lua/r35/glyphs/data.lua`

**Files:**

- Create: `scripts/gen_glyphs.lua`
- Create (generated): `lua/r35/glyphs/data.lua`

**Interfaces:**

- Consumes: nothing from earlier tasks.
- Produces: `require("r35.glyphs.data")` → `table<string, string>`, roughly 10,751 entries, name → single-codepoint UTF-8 string.

- [ ] **Step 1: Write the generator**

Create `scripts/gen_glyphs.lua`:

```lua
-- Generate lua/r35/glyphs/data.lua from WezTerm's Nerd Font name table.
--
--   nvim -l scripts/gen_glyphs.lua
--
-- The interface this data serves is Wez Furlong's design (wezterm.nerdfonts),
-- and the source file is WezTerm's own generated output. Both are credited in
-- the header this script writes.
--
-- Network access happens here and nowhere else. Nothing under lua/ fetches.

local RAW = "https://raw.githubusercontent.com/wezterm/wezterm/main/wezterm-char-props/src/nerdfonts_data.rs"
local COMMITS = "https://api.github.com/repos/wezterm/wezterm/commits/main"
local OUT = "lua/r35/glyphs/data.lua"

local function die(msg)
  io.stderr:write("gen_glyphs: " .. msg .. "\n")
  os.exit(1)
end

local function fetch(url)
  local res = vim.system({ "curl", "-sSL", "--fail", url }, { text = true }):wait()
  if res.code ~= 0 then
    die(("fetch failed (%d): %s\n%s"):format(res.code, url, res.stderr or ""))
  end
  return res.stdout
end

print("fetching " .. RAW)
local src = fetch(RAW)

local sha = "unknown"
local ok, commit = pcall(vim.json.decode, fetch(COMMITS))
if ok and type(commit) == "table" and commit.sha then
  sha = commit.sha:sub(1, 12)
end

-- Long-bracket pattern so the backslash in \u{...} needs no escaping.
local PATTERN = [[%("([a-z0-9_]+)",%s*'\u{(%x+)}'%)]]

local names, seen = {}, {}
local glyphs = {}
for name, hex in src:gmatch(PATTERN) do
  if seen[name] then
    die("duplicate name in upstream data: " .. name)
  end
  seen[name] = true
  names[#names + 1] = name
  glyphs[name] = tonumber(hex, 16)
end
table.sort(names)
print(("parsed %d glyphs (wezterm @ %s)"):format(#names, sha))

-- Gates. Refuse to write rather than clobber good data because upstream moved
-- a file or changed a format: a truncated data.lua is worse than a stale one.
if #names < 10000 then
  die(("only %d glyphs parsed; expected >10000. Upstream format may have changed."):format(#names))
end
for _, name in ipairs(names) do
  if not name:match("^[a-z0-9_]+$") then
    die("name is not a valid Lua identifier: " .. name)
  end
  local cp = glyphs[name]
  local round = vim.fn.str2list(vim.fn.nr2char(cp))
  if #round ~= 1 or round[1] ~= cp then
    die(("codepoint U+%X does not round-trip (%s)"):format(cp, name))
  end
end
print("gates passed: count, identifiers, round-trip, uniqueness")

local out = {}
local function w(line)
  out[#out + 1] = line
end

w("---Nerd Font glyph names.")
w("---")
w("---GENERATED -- do not edit. Run `nvim -l scripts/gen_glyphs.lua` to refresh.")
w("---")
w("---The naming scheme and the lookup interface are Wez Furlong's design, from")
w("---WezTerm's `wezterm.nerdfonts`:")
w("---  https://wezterm.org/config/lua/wezterm/nerdfonts.html")
w("---")
w("---Source: wezterm-char-props/src/nerdfonts_data.rs @ " .. sha)
w("---  " .. RAW)
w("---")
w("---@glyph-count " .. #names)
w("---")
w("---Escapes rather than literals on purpose: these are mostly Private Use Area")
w("---codepoints and render as nothing without a patched font, so literals would")
w("---be unreadable in a diff or on the web.")
w("")
w("---@type table<string, string>")
w("return {")
for _, name in ipairs(names) do
  w(("  %s = \"\\u{%X}\","):format(name, glyphs[name]))
end
w("}")

local fh = assert(io.open(OUT, "w"))
fh:write(table.concat(out, "\n"), "\n")
fh:close()

local size = vim.fn.getfsize(OUT)
print(("wrote %s (%d entries, %.0f KB)"):format(OUT, #names, size / 1024))
```

- [ ] **Step 2: Run it**

```bash
cd ~/.config/nvim && nvim -l scripts/gen_glyphs.lua
```

Expected output shape:

```
fetching https://raw.githubusercontent.com/...
parsed 10751 glyphs (wezterm @ <12-char sha>)
gates passed: count, identifiers, round-trip, uniqueness
wrote lua/r35/glyphs/data.lua (10751 entries, ~400 KB)
```

- [ ] **Step 3: Verify the output loads and is correct**

```bash
cd ~/.config/nvim && nvim --clean --headless -l /dev/stdin <<'LUA'
package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
local t0 = vim.uv.hrtime()
local d = require("r35.glyphs.data")
local ms = (vim.uv.hrtime() - t0) / 1e6
local n = 0
for _ in pairs(d) do n = n + 1 end
print(("entries=%d  load=%.2f ms"):format(n, ms))
print(("md_folder=%q  fa_bug=%q  cod_question=%q"):format(d.md_folder, d.fa_bug, d.cod_question))
assert(n > 10000, "too few entries")
assert(ms < 25, "load too slow: " .. ms)
assert(vim.fn.strchars(d.md_folder) == 1, "md_folder is not one codepoint")
print("OK")
vim.cmd("qa!")
LUA
```

Expected: `entries=10751`, a load time in single-digit milliseconds, and `OK`. If load exceeds 25 ms, stop and reconsider the escape-vs-literal choice before continuing.

- [ ] **Step 4: Confirm `vim.loader` caches it**

```bash
cd ~/.config/nvim && nvim --headless -c 'lua local t=vim.uv.hrtime(); require("r35.glyphs.data"); print(("second-run load: %.2f ms"):format((vim.uv.hrtime()-t)/1e6))' -c 'qa!'
```

Expected: noticeably faster than Step 3 (sub-millisecond territory) on the second and later runs, because `vim.loader` byte-compiles it.

- [ ] **Step 5: Checkpoint**

```bash
stylua --check ~/.config/nvim/lua/r35/glyphs/data.lua || echo "generated file formatting differs; that is fine, it is machine-written"
```

---

## Task 5: `icons.lua` — name lookup

This task contains the one piece intended for the repo owner to write: the `unknown()` handler.

**Files:**

- Create: `lua/r35/glyphs/icons.lua`
- Test: `tests/icons_test.lua` (create)

**Interfaces:**

- Consumes: `require("r35.glyphs.data")` (Task 4), `require("r35.glyphs.width").fit` (Task 2).
- Produces:
  - `icons.<name>` → `string` (glyph, or placeholder on unknown)
  - `icons.get(name: string): string|nil`
  - `icons.has(name: string): boolean`
  - `icons.sign(name: string): string`

- [ ] **Step 1: Write the failing test**

Create `tests/icons_test.lua`:

```lua
-- Tests for `r35.glyphs.icons`.
--
--   nvim --headless -c 'luafile ~/.config/nvim/tests/icons_test.lua'
--
-- The contract: a known name resolves; an unknown name is LOUD but harmless.
-- Returning nil for a typo is the failure mode this module exists to prevent --
-- a missing icon renders as nothing and reads as a font problem, which sends
-- you hunting in entirely the wrong place.
--
-- Deduplication is not a nicety. A bad icon in a lualine section re-evaluates
-- on nearly every redraw, so an undeduped notify is a denial-of-service.

local ok, icons = pcall(require, "r35.glyphs.icons")
if not ok then
  print("FAIL require r35.glyphs.icons: " .. tostring(icons))
  vim.cmd("cq")
end

local pass, fail = 0, 0
local function check(name, cond, extra)
  if cond then
    pass = pass + 1
    print("  ok   " .. name)
  else
    fail = fail + 1
    print("  FAIL " .. name .. (extra and ("  -> " .. tostring(extra)) or ""))
  end
end

---Capture every vim.notify made while `fn` runs.
local function capturing(fn)
  local msgs = {}
  local real = vim.notify
  vim.notify = function(msg)
    msgs[#msgs + 1] = msg
  end
  local result = fn()
  vim.notify = real
  return result, msgs
end

-- Laziness: requiring the module must not pull in the 10,751-entry table.
check("data is not loaded on require", package.loaded["r35.glyphs.data"] == nil)

-- Known names.
check("md_folder resolves", icons.md_folder == vim.fn.nr2char(0xF024B), icons.md_folder)
check("fa_bug resolves", icons.fa_bug == vim.fn.nr2char(0xF188), icons.fa_bug)
check("cod_account resolves", icons.cod_account == vim.fn.nr2char(0xEB99), icons.cod_account)
check("data is loaded after first access", package.loaded["r35.glyphs.data"] ~= nil)

-- get / has never warn and never substitute.
local got, quiet = capturing(function()
  return icons.get("md_foldr")
end)
check("get() returns nil for unknown", got == nil, got)
check("get() does not notify", #quiet == 0, #quiet)
check("get() returns the glyph for known", icons.get("md_folder") == icons.md_folder)
check("has() is true for known", icons.has("md_folder") == true)
check("has() is false for unknown", icons.has("md_foldr") == false)

-- Unknown via indexing: placeholder plus exactly one warning.
local PLACEHOLDER = vim.fn.nr2char(0xEB32) -- cod_question
local first, msgs = capturing(function()
  return icons.md_foldr
end)
check("unknown returns the placeholder", first == PLACEHOLDER, first)
check("unknown notifies once", #msgs == 1, #msgs)
check("warning names the bad key", msgs[1] and msgs[1]:match("md_foldr") ~= nil, msgs[1])
check("warning suggests the near miss", msgs[1] and msgs[1]:match("md_folder") ~= nil, msgs[1])

local second, again = capturing(function()
  return icons.md_foldr
end)
check("repeat lookup still returns the placeholder", second == PLACEHOLDER, second)
check("repeat lookup is silent", #again == 0, #again)

local other, other_msgs = capturing(function()
  return icons.fa_bg
end)
check("a DIFFERENT bad name still warns", #other_msgs == 1, #other_msgs)
check("...and returns the placeholder", other == PLACEHOLDER, other)

-- sign(): lookup and fit in one call.
require("r35.glyphs").setup()
check("sign() fits the sign column", require("r35.glyphs").cells(icons.sign("fa_bug")) <= 2, icons.sign("fa_bug"))
check("sign() of a known name is the glyph", icons.sign("fa_bug") == icons.fa_bug)

-- Data integrity.
local data = require("r35.glyphs.data")
local n, bad_width, bad_name = 0, nil, nil
for name, glyph in pairs(data) do
  n = n + 1
  if vim.fn.strchars(glyph) ~= 1 then
    bad_width = name
  end
  if name == "get" or name == "has" or name == "sign" then
    bad_name = name
  end
end
check(("data has %d entries (>10000)"):format(n), n > 10000, n)
check("every value is exactly one codepoint", bad_width == nil, bad_width)
check("no name collides with the module API", bad_name == nil, bad_name)

print(string.format("\n%d passed, %d failed", pass, fail))
vim.cmd(fail > 0 and "cq" or "qa!")
```

- [ ] **Step 2: Run it and watch it fail**

```bash
nvim --headless -c 'luafile ~/.config/nvim/tests/icons_test.lua'; echo "exit=$?"
```

Expected: FAIL, `exit=1`, at the `require` guard — `r35.glyphs.icons` does not exist yet.

- [ ] **Step 3: Write the scaffold, leaving `unknown()` for the repo owner**

Create `lua/r35/glyphs/icons.lua`:

```lua
---Nerd Font glyphs by name.
---
---The interface is Wez Furlong's, borrowed from WezTerm's `wezterm.nerdfonts`:
---  https://wezterm.org/config/lua/wezterm/nerdfonts.html
---Index the module with a glyph's symbolic name and get the string back.
---
---  local icons = require("r35.glyphs.icons")
---  icons.fa_bug        --> the glyph
---  icons.get("fa_bug") --> the glyph, or nil, silently
---  icons.has("fa_bug") --> boolean
---  icons.sign("fa_bug")--> the glyph, fitted to the sign column
---
---Unknown names are LOUD rather than nil. A nil icon renders as nothing and
---reads as a font problem, which is the wrong place to go looking. See
---`unknown()` below.
---
---`data` is required lazily. Requiring this module costs nothing until a glyph
---is actually asked for; the table itself is ~10,751 entries and measures
---around 3 ms cold, well under 1 ms once `vim.loader` has cached its bytecode.

local M = {}

---Codicon `cod_question`. Inside a declared two-cell block, so a missing icon
---occupies exactly the space a real one would and the layout does not shift
---while you work out what went wrong.
local PLACEHOLDER = "\u{EB32}"

---@type table<string, string>|nil
local data

---@return table<string, string>
local function load()
  data = data or require("r35.glyphs.data")
  return data
end

---Names already warned about, so a lookup in a redraw loop warns once.
---@type table<string, true>
local warned = {}

---Handle a name that is not in the table.
---
---TODO(bobsaska): implement. The contract the tests assert:
---
---  * Returns PLACEHOLDER, always. Never nil, never an error.
---  * Notifies at WARN level, and does so AT MOST ONCE per distinct name --
---    use `warned`. This matters: a bad icon in a lualine section is looked up
---    on nearly every redraw.
---  * The message contains the bad name, and a suggestion when there is a near
---    miss. `vim.fn.matchfuzzy(vim.tbl_keys(load()), name)[1]` gives you one;
---    it measures ~2.4 ms over the full table, which is fine on this path.
---  * Prefix the message with "r35.glyphs.icons: " to match the rest of the
---    module family.
---@param name string
---@return string
local function unknown(name)
  return PLACEHOLDER
end

setmetatable(M, {
  __index = function(_, name)
    return load()[name] or unknown(name)
  end,
})

---Look up `name` without warning or substituting.
---@param name string
---@return string|nil
function M.get(name)
  return load()[name]
end

---@param name string
---@return boolean
function M.has(name)
  return load()[name] ~= nil
end

---Look up `name` and fit it to the two-cell sign column.
---
---`sign_text` accepts at most two display cells and rejects the whole extmark
---otherwise, so this is the form you want anywhere a glyph becomes a sign.
---@param name string
---@return string
function M.sign(name)
  return require("r35.glyphs.width").fit(M[name], 2)
end

return M
```

- [ ] **Step 4: Run the tests — expect a partial pass**

```bash
nvim --headless -c 'luafile ~/.config/nvim/tests/icons_test.lua'; echo "exit=$?"
```

Expected: every check passes EXCEPT the four covering warning behaviour — `unknown notifies once`, `warning names the bad key`, `warning suggests the near miss`, and `a DIFFERENT bad name still warns`. The placeholder checks already pass, because the stub returns it.

**Stop here and hand `unknown()` to the repo owner.** The stub is deliberately incomplete; the four failing checks are its specification.

- [ ] **Step 5: Implement `unknown()`** _(repo owner)_

Replace the stub body. Roughly eight lines. The four failing checks from Step 4 are the acceptance criteria.

- [ ] **Step 6: Run the full suite**

```bash
for t in icons glyphs_width glyphs_sign; do
  nvim --headless -c "luafile ~/.config/nvim/tests/${t}_test.lua" >/dev/null 2>&1 && echo "ok   $t" || echo "FAIL $t"
done
```

Expected: three `ok` lines.

- [ ] **Step 7: Credit WezTerm in the README**

The spec requires credit in three places: the `data.lua` header (Task 4), the
`icons.lua` header (Step 3 above), and the README. `README.md` is currently the
stock four-line LazyVim starter text. Append:

```markdown
## Credits

Nerd Font glyph names in `r35.glyphs.icons` follow the interface and naming
scheme of [`wezterm.nerdfonts`](https://wezterm.org/config/lua/wezterm/nerdfonts.html)
by [Wez Furlong](https://github.com/wez). `lua/r35/glyphs/data.lua` is generated
from WezTerm's own `wezterm-char-props/src/nerdfonts_data.rs`.
```

- [ ] **Step 8: Format and checkpoint**

```bash
stylua ~/.config/nvim/lua/r35/glyphs/icons.lua
npx --yes prettier --write ~/.config/nvim/README.md
```

---

## Task 6: Audit mode

**Files:**

- Modify: `scripts/gen_glyphs.lua`

**Interfaces:**

- Consumes: `require("r35.glyphs.blocks")`, `require("r35.glyphs.data")`.
- Produces: `nvim -l scripts/gen_glyphs.lua --audit [--font PATH]`, exit 0 clean / 1 on any disagreement. Also `M.audit` is not exported — this is a script, not a module.

- [ ] **Step 1: Add argument parsing at the top of `scripts/gen_glyphs.lua`**

Insert directly after the `OUT` constant:

```lua
-- `nvim -l script.lua --audit` puts the script's own args in the global `arg`.
local args = {}
for _, a in ipairs(arg or {}) do
  args[#args + 1] = a
end

local MODE, FONT = "generate", nil
for i, a in ipairs(args) do
  if a == "--audit" then
    MODE = "audit"
  elseif a == "--font" then
    FONT = args[i + 1]
  end
end
```

Then wrap the existing generate logic so it only runs in generate mode: move everything from `print("fetching " .. RAW)` to the final `print(("wrote %s ..."))` into `local function generate() ... end`, and add a dispatch at the very bottom of the file (written in Step 5).

- [ ] **Step 2: Add font resolution**

```lua
---The font kitty actually uses on this machine, unless overridden.
---
---`blocks.lua` is only correct for one font. Reading kitty's own `font_family`
---means running this on another machine audits THAT machine's font, which is
---the only way the answer is worth anything there.
---@return string path
local function resolve_font()
  if FONT then
    return FONT
  end
  local family = "monospace"
  local conf = vim.fn.expand("~/.config/kitty/kitty.conf")
  for _, line in ipairs(vim.fn.filereadable(conf) == 1 and vim.fn.readfile(conf) or {}) do
    local f = line:match("^%s*font_family%s+(.-)%s*$")
    if f then
      family = f
    end
  end
  local res = vim.system({ "fc-match", "-f", "%{file}", family }, { text = true }):wait()
  if res.code ~= 0 or res.stdout == "" then
    die("could not resolve a font file for " .. family .. "; pass --font PATH")
  end
  print(("font: %s -> %s"):format(family, res.stdout))
  return res.stdout
end
```

- [ ] **Step 3: Add font measurement via fontTools**

```lua
---Advance width per codepoint, in cells, from the font's own hmtx table.
---
---Shells out to python3/fontTools. This is a dev-time dependency on the audit
---path only -- nothing under lua/ touches it.
---@param path string
---@param codepoints integer[]
---@return table<integer, number>|nil widths, string? err
local function measure(path, codepoints)
  local py = [[
import json, sys
from fontTools.ttLib import TTFont
path = sys.argv[1]
cps = json.loads(sys.stdin.read())
f = TTFont(path, lazy=True)
cmap = f.getBestCmap(); hmtx = f["hmtx"]
base = hmtx[cmap[ord("M")]][0]
out = {}
for cp in cps:
    g = cmap.get(cp)
    if g is not None:
        out[str(cp)] = hmtx[g][0] / base
print(json.dumps(out))
]]
  local res = vim
    .system({ "python3", "-c", py, path }, { text = true, stdin = vim.json.encode(codepoints) })
    :wait()
  if res.code ~= 0 then
    return nil, (res.stderr or ""):gsub("%s+$", "")
  end
  return vim.json.decode(res.stdout)
end
```

- [ ] **Step 4: Add the config-literal scanner**

```lua
---Every codepoint literal appearing in the config.
---
---This mode exists because of U+23F2: a plain Unicode character chosen by hand,
---documented as one cell, actually two, and invisible to any check limited to
---the Nerd Font set. The defect lives in the gap between "glyphs the generator
---knows about" and "glyphs the config actually uses".
---@return table<integer, string[]> codepoint -> files it appears in
local function config_literals()
  local found = {}
  local function note(cp, file)
    if cp < 0x80 then
      return
    end
    found[cp] = found[cp] or {}
    for _, f in ipairs(found[cp]) do
      if f == file then
        return
      end
    end
    table.insert(found[cp], file)
  end

  local files = vim.fn.globpath("lua", "**/*.lua", false, true)
  table.insert(files, "init.lua")
  for _, file in ipairs(files) do
    for _, line in ipairs(vim.fn.readfile(file)) do
      if not line:match("^%s*%-%-") then
        for hex in line:gmatch([[\u{(%x+)}]]) do
          note(tonumber(hex, 16), file)
        end
        for _, cp in ipairs(vim.fn.str2list(line)) do
          note(cp, file)
        end
      end
    end
  end
  return found
end
```

- [ ] **Step 5: Add the audit itself and the dispatch**

```lua
---@param cp integer
---@param blocks r35.glyphs.Block[]
---@return integer
local function declared(cp, blocks)
  for _, b in ipairs(blocks) do
    if cp >= b.first and cp <= b.last then
      return b.cells
    end
  end
  return 1
end

local function audit()
  package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
  local blocks = require("r35.glyphs.blocks")
  local data = require("r35.glyphs.data")
  local font = resolve_font()

  local targets, source = {}, {}
  for _, glyph in pairs(data) do
    local cp = vim.fn.str2list(glyph)[1]
    targets[#targets + 1] = cp
    source[cp] = "nerd font set"
  end
  for cp, files in pairs(config_literals()) do
    if not source[cp] then
      targets[#targets + 1] = cp
    end
    source[cp] = table.concat(files, ", ")
  end

  local widths, err = measure(font, targets)
  if not widths then
    print("gen_glyphs: font measurement unavailable -- " .. tostring(err))
    print("  install fontTools to enable this check:  uv tool install fonttools")
    os.exit(0)
  end

  local problems, missing = {}, 0
  for _, cp in ipairs(targets) do
    local w = widths[tostring(cp)]
    if not w then
      missing = missing + 1
    else
      local actual = (w >= 1.99) and 2 or 1
      local want = declared(cp, blocks)
      if actual ~= want then
        problems[#problems + 1] = { cp = cp, actual = actual, want = want, where = source[cp] }
      end
    end
  end

  table.sort(problems, function(a, b)
    return a.cp < b.cp
  end)
  print(("\nchecked %d codepoints; %d absent from the font (fallback)"):format(#targets, missing))
  if #problems == 0 then
    print("blocks.lua agrees with the font.")
    os.exit(0)
  end
  print(("\n%d DISAGREEMENT(S):\n"):format(#problems))
  for _, p in ipairs(problems) do
    local symptom = p.actual > p.want and "clips" or "dead half-cell"
    print(("  U+%05X  font=%d  blocks.lua=%d  %-16s %s"):format(p.cp, p.actual, p.want, symptom, p.where))
  end
  os.exit(1)
end

if MODE == "audit" then
  audit()
else
  generate()
end
```

- [ ] **Step 6: Run the audit and confirm it is clean**

```bash
cd ~/.config/nvim && nvim -l scripts/gen_glyphs.lua --audit; echo "exit=$?"
```

Expected: `blocks.lua agrees with the font.` and `exit=0`. Task 3 fixed all seven known defects, so a non-empty report here means either Task 3 was applied incorrectly or the audit has a bug — investigate before continuing.

- [ ] **Step 7: Prove the audit actually catches things**

Temporarily break `blocks.lua` — change the `Black heart suit` entry's `cells` from `2` to `1` — then:

```bash
cd ~/.config/nvim && nvim -l scripts/gen_glyphs.lua --audit; echo "exit=$?"
```

Expected: one disagreement reporting `U+02665  font=2  blocks.lua=1  clips`, and `exit=1`. **Revert the change** and re-run to confirm clean.

- [ ] **Step 8: Confirm graceful degradation**

```bash
cd ~/.config/nvim && PATH=/usr/bin:/bin nvim -l scripts/gen_glyphs.lua --audit --font /nonexistent.ttf; echo "exit=$?"
```

Expected: a message naming the missing measurement and the `uv tool install fonttools` hint, with `exit=0` — an unavailable optional tool must not read as a failure.

- [ ] **Step 9: Format and checkpoint**

```bash
stylua ~/.config/nvim/scripts/gen_glyphs.lua
```

---

## Task 7: `:checkhealth r35.glyphs`

**Files:**

- Create: `lua/r35/glyphs/health.lua`
- Modify: `lua/r35/glyphs/width.lua` (record that `setup()` ran)

**Interfaces:**

- Consumes: `require("r35.glyphs.blocks")`, `require("r35.glyphs.width")`, `require("r35.glyphs.data")`.
- Produces: `require("r35.glyphs.health").check()`, invoked by `:checkhealth r35.glyphs`. Also `width.applied: integer|nil` — count of ranges installed by the last successful `setup()`, `nil` if it has not run.

- [ ] **Step 1: Record that `setup()` ran**

In `lua/r35/glyphs/width.lua`, add near the top:

```lua
---Ranges installed by the last successful `setup()`; nil if it has not run.
---
---`:checkhealth` needs to distinguish "not applied yet" from "applied", and
---there is no way to read the table back out of `setcellwidths`.
---@type integer|nil
M.applied = nil
```

and inside `M.setup()`, on the success path of the `pcall`:

```lua
  if ok then
    M.applied = #ranges
  end
```

- [ ] **Step 2: Write `health.lua`**

```lua
---`:checkhealth r35.glyphs`
---
---The question this answers: why is that icon misaligned? It is the piece that
---pays off on a machine other than the one blocks.lua was written for -- it
---names the glyph and the reason, instead of requiring a statusline bisect.

local M = {}

local H = vim.health

---Parse the kitty mirror into codepoint -> cells.
---@return table<integer, integer>|nil
local function kitty_widths()
  local path = vim.fn.expand("~/.config/kitty/conf.d/nerd_font_widths.conf")
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  local out = {}
  for _, line in ipairs(vim.fn.readfile(path)) do
    local first, last, cells = line:match("^%s*narrow_symbols%s+U%+(%x+)%-U%+(%x+)%s+(%d+)")
    if not first then
      local one, c = line:match("^%s*narrow_symbols%s+U%+(%x+)%s+(%d+)")
      first, last, cells = one, one, c
    end
    if first then
      for cp = tonumber(first, 16), tonumber(last, 16) do
        out[cp] = tonumber(cells)
      end
    end
  end
  return out
end

function M.check()
  local blocks = require("r35.glyphs.blocks")
  local width = require("r35.glyphs.width")

  H.start("r35.glyphs: widths")
  if width.applied then
    H.ok(("setcellwidths applied -- %d ranges from %d declared blocks"):format(width.applied, #blocks))
  else
    H.warn("setup() has not run", { "Call require('r35.glyphs').setup() from init.lua." })
  end

  local carved = {}
  for _, name in ipairs({ "fillchars", "listchars" }) do
    for item in vim.gsplit(vim.o[name] or "", ",", { trimempty = true }) do
      local value = item:match("^[^:]+:(.*)$")
      if value and value ~= "" then
        for _, cp in ipairs(vim.fn.str2list(value)) do
          for _, b in ipairs(blocks) do
            if cp >= b.first and cp <= b.last then
              carved[#carved + 1] = ("U+%04X (%s, from '%s')"):format(cp, b.name, name)
            end
          end
        end
      end
    end
  end
  if #carved == 0 then
    H.ok("no declared glyph is claimed by 'fillchars'/'listchars'")
  else
    H.info(("%d codepoint(s) carved out to keep setcellwidths legal:"):format(#carved))
    for _, c in ipairs(carved) do
      H.info("  " .. c)
    end
  end

  H.start("r35.glyphs: kitty mirror")
  local kitty = kitty_widths()
  if not kitty then
    H.warn("~/.config/kitty/conf.d/nerd_font_widths.conf not readable", { "nvim and kitty may disagree about cell widths." })
  else
    local drift = {}
    for _, b in ipairs(blocks) do
      for cp = b.first, b.last do
        if (kitty[cp] or 1) ~= b.cells then
          drift[#drift + 1] = ("U+%04X (%s): nvim=%d kitty=%d"):format(cp, b.name, b.cells, kitty[cp] or 1)
          break
        end
      end
    end
    if #drift == 0 then
      H.ok("kitty conf agrees with blocks.lua")
    else
      H.error(("%d block(s) disagree with the kitty conf:"):format(#drift), drift)
    end
  end

  H.start("r35.glyphs: data")
  local loaded, data = pcall(require, "r35.glyphs.data")
  if not loaded then
    H.error("r35.glyphs.data is missing", { "Run: nvim -l scripts/gen_glyphs.lua" })
  else
    local n = 0
    for _ in pairs(data) do
      n = n + 1
    end
    H.ok(("%d glyph names available"):format(n))
    H.info("Audit blocks.lua against the real font: nvim -l scripts/gen_glyphs.lua --audit")
  end
end

return M
```

- [ ] **Step 3: Run it**

```bash
nvim --headless -c 'checkhealth r35.glyphs' -c 'w! /tmp/health.txt' -c 'qa!' && cat /tmp/health.txt
```

Expected: three sections. `widths` reports `setcellwidths applied`. `kitty mirror` reports drift **unless** the Task 3 Step 7 kitty edits were applied — if they were not, this correctly reports the four blocks that differ, which is the health check doing its job.

- [ ] **Step 4: Confirm the failure path reads well**

Temporarily rename the kitty conf, re-run Step 3, confirm the WARN is clear, then rename it back.

```bash
mv ~/.config/kitty/conf.d/nerd_font_widths.conf{,.bak}
nvim --headless -c 'checkhealth r35.glyphs' -c 'w! /tmp/health2.txt' -c 'qa!'; grep -A2 'kitty mirror' /tmp/health2.txt
mv ~/.config/kitty/conf.d/nerd_font_widths.conf{.bak,}
```

- [ ] **Step 5: Format and checkpoint**

```bash
stylua ~/.config/nvim/lua/r35/glyphs/
for t in icons glyphs_width glyphs_sign; do
  nvim --headless -c "luafile ~/.config/nvim/tests/${t}_test.lua" >/dev/null 2>&1 && echo "ok   $t" || echo "FAIL $t"
done
```

---

## Task 8: Migrate hand-written escapes to named lookups

22 codepoint escapes across two files become names. **Three of them do not mean what their comments say** — the Nerd Fonts v2→v3 renumbering moved glyphs out from under these codepoints.

**Files:**

- Modify: `lua/plugins/todo-comments.lua`
- Modify: `lua/r35/langs/norg.lua:141-161`

**Interfaces:**

- Consumes: `require("r35.glyphs.icons")` from Task 5.
- Produces: no new API.

### Decision required before starting

| Site          | Current escape | v3 glyph at that codepoint | Comment claims        | Name for the intended glyph |
| ------------- | -------------- | -------------------------- | --------------------- | --------------------------- |
| `todo` PERF   | `\u{F43A}`     | `oct_clock`                | oct-rocket            | `oct_rocket` = U+F427       |
| `todo` NOTE   | `\u{EA74}`     | `cod_info`                 | cod-note              | `cod_note` = U+EB26         |
| `norg` undone | `\u{F0C8}`     | `fa_square` (filled)       | fa-square-o (outline) | `fa_square_o` = U+F096      |

**Default: preserve intent, not pixels.** Use `oct_rocket`, `cod_note`, `fa_square_o`. The comments record what was wanted, the codepoints drifted underneath them, and a _filled_ square for an _undone_ checkbox is actively misleading. Confirm with the repo owner before applying — this changes what renders.

Four codepoints have multiple valid names. Pick the one matching the existing comment, so the diff reads as a rename rather than a change:

| Codepoint | Aliases                                                            | Use                       |
| --------- | ------------------------------------------------------------------ | ------------------------- |
| U+F071    | `fa_exclamation_triangle`, `fa_triangle_exclamation`, `fa_warning` | `fa_exclamation_triangle` |
| U+F252    | `fa_hourglass_2`, `fa_hourglass_half`                              | `fa_hourglass_half`       |
| U+F021    | `fa_arrows_rotate`, `fa_refresh`                                   | `fa_refresh`              |
| U+F249    | `fa_note_sticky`, `fa_sticky_note`                                 | `fa_sticky_note`          |

- [ ] **Step 1: Verify every name resolves before editing anything**

```bash
cd ~/.config/nvim && nvim --headless -l /dev/stdin <<'LUA'
package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
local icons = require("r35.glyphs.icons")
local names = {
  "fa_bug", "fa_check", "oct_flame", "fa_exclamation_triangle", "oct_rocket", "cod_note",
  "fa_square_o", "fa_hourglass_half", "fa_pause", "fa_ban", "fa_question", "fa_refresh",
  "fa_book", "fa_sticky_note", "fa_eye_slash",
}
local bad = {}
for _, n in ipairs(names) do
  if not icons.has(n) then bad[#bad + 1] = n end
end
print(#bad == 0 and "all names resolve" or ("MISSING: " .. table.concat(bad, ", ")))
vim.cmd(#bad == 0 and "qa!" or "cq")
LUA
```

Expected: `all names resolve`.

- [ ] **Step 2: Rewrite `lua/plugins/todo-comments.lua`**

Replace the `\u{}` block comment (lines 10-12) and the keyword table. The escapes-are-unreadable justification no longer applies — that is the point of the change.

```lua
-- Icons are looked up by name rather than written as codepoints. The old form
-- carried a `-- fa-bug` comment beside each escape because PUA codepoints are
-- unreadable in a diff; the name makes the comment unnecessary.
--
-- Two of the old codepoints had drifted: U+F43A is `oct_clock` in Nerd Fonts v3
-- (not the rocket its comment claimed) and U+EA74 is `cod_info` (not the note).
-- These now name the glyphs that were always intended.
local icons = require("r35.glyphs.icons")

return {
  "folke/todo-comments.nvim",
  opts = {
    keywords = {
      FIX = { icon = icons.fa_bug },
      TODO = { icon = icons.fa_check },
      HACK = { icon = icons.oct_flame },
      WARN = { icon = icons.fa_exclamation_triangle },
      PERF = { icon = icons.oct_rocket },
      NOTE = { icon = icons.cod_note },
      TEST = { icon = "\u{23F2}" }, -- timer clock; no Nerd Font name, stays a literal
    },
  },
}
```

Keep the leading comment block about sign widths (lines 1-8) exactly as it is.

- [ ] **Step 3: Rewrite the icon table in `lua/r35/langs/norg.lua`**

At the top of the file, beside the existing `norg_icons` require:

```lua
local icons = require("r35.glyphs.icons")
```

Replace the `\u{}` justification comment at line 128 and the icon values at lines 141-161:

```lua
                    undone = icons.fa_square_o,
                    pending = icons.fa_hourglass_half,
                    done = icons.fa_check,
                    on_hold = icons.fa_pause,
                    cancelled = icons.fa_ban,
                    urgent = icons.fa_exclamation_triangle,
                    uncertain = icons.fa_question,
                    recurring = icons.fa_refresh,
```

and, for the entries that carry a trailing space:

```lua
                    single = { icon = icons.fa_book },
                    multi_prefix = { icon = icons.fa_book .. " " },
                    multi_suffix = { icon = icons.fa_book .. " " },
```

```lua
                    single = { icon = icons.fa_sticky_note },
                    multi_prefix = { icon = icons.fa_sticky_note .. " " },
                    multi_suffix = { icon = icons.fa_sticky_note .. " " },
```

```lua
                    spoiler = { icon = icons.fa_eye_slash },
```

Replace the comment at line 128 with:

```lua
                -- Icons are named rather than written as codepoints; see
                -- r35.glyphs.icons. `undone` was U+F0C8, which is a FILLED
                -- square in Nerd Fonts v3 -- `fa_square_o` is the outline the
                -- old `-- fa-square-o` comment always meant.
```

- [ ] **Step 4: Confirm no escapes remain in the migrated files**

```bash
cd ~/.config/nvim && grep -n '\\u{' lua/plugins/todo-comments.lua lua/r35/langs/norg.lua
```

Expected: exactly one line — `todo-comments.lua`'s `TEST` entry, which has no Nerd Font name and correctly stays a literal.

- [ ] **Step 5: Confirm nvim starts clean and no icon warned**

```bash
cd ~/.config/nvim && nvim --headless -c 'messages' -c 'w! /tmp/msgs.txt' -c 'qa!'; grep -i 'unknown glyph' /tmp/msgs.txt && echo "UNKNOWN GLYPH WARNINGS -- fix the names" || echo "no unknown-glyph warnings"
```

Expected: `no unknown-glyph warnings`. Any hit means a typo — the module is doing exactly the job it was built for.

- [ ] **Step 6: Visual confirmation** _(repo owner)_

Open a file containing `TODO:`, `PERF:`, and `NOTE:` comments and confirm the gutter shows a check, a rocket, and a note — not a check, a clock, and an info badge. Then open a `.norg` file with an undone todo and confirm the checkbox is an **outline** square.

- [ ] **Step 7: Full suite and audit**

```bash
cd ~/.config/nvim
for t in icons glyphs_width glyphs_sign norg_todo_icons norg_summary; do
  nvim --headless -c "luafile ~/.config/nvim/tests/${t}_test.lua" >/dev/null 2>&1 && echo "ok   $t" || echo "FAIL $t"
done
nvim -l scripts/gen_glyphs.lua --audit; echo "audit exit=$?"
```

Expected: five `ok` lines and `audit exit=0`.

- [ ] **Step 8: Format and checkpoint**

```bash
stylua ~/.config/nvim/lua/ ~/.config/nvim/scripts/
```

---

## Follow-ups, deliberately out of scope

- **Fallback-font metrics.** 1,170 of the 10,751 glyphs are absent from PragmataPro VF and fall back to Hack Nerd Font, whose advance widths have not been measured. The audit reports them as `absent from the font (fallback)` rather than guessing. Worth a follow-up once someone hits a misaligned one.
- **The other five files with non-ASCII literals** — `blink-cmp.lua`, `neogit.lua`, `pymple.lua`, `langs/markdown.lua`, `themes/candy/lualine.lua` — were not audited for drift. `--audit` covers their codepoints for _width_, but not for whether the glyph still means what the author intended.
- **An icon picker.** `telescope-emoji` is unmaintained and misses everything past Unicode 14; a combined icon+emoji picker over `r35.glyphs.data` would replace it.
