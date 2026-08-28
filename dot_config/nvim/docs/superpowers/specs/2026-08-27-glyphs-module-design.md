# Design: `r35.glyphs` as a unified glyph module

Date: 2026-08-27
Status: approved, pending implementation plan

## Summary

Fold Nerd Font _name lookup_ into the existing `r35.glyphs` module, which today
handles only glyph _widths_. The result is one package covering the whole
subject: what a glyph is called, how wide it renders, and how to fit it into a
constrained space.

The interface for name lookup is borrowed, deliberately and with credit, from
[WezTerm's `wezterm.nerdfonts`](https://wezterm.org/config/lua/wezterm/nerdfonts.html)
by Wez Furlong. The glyph data is a transform of WezTerm's own generated
`wezterm-char-props/src/nerdfonts_data.rs`.

## Motivation

Three problems, one subject.

**1. Glyphs are referenced by codepoint, not by name.** `todo-comments.lua` and
`langs/norg.lua` carry 22 hand-written `\u{}` escapes, each followed by a comment
naming the glyph:

```lua
FIX = { icon = "\u{F188}" }, -- fa-bug
```

`todo-comments.lua` explains the escapes: PUA codepoints "render as nothing
without a patched font, so literals would be unreadable in a diff or on the
web." A named lookup dissolves the problem rather than working around it — the
comment becomes the code.

**2. The width table is hand-maintained across three mirrors.** `M.ranges` in
`glyphs.lua`, `narrow_symbols` in `~/.config/kitty/conf.d/nerd_font_widths.conf`,
and a third invariant that exists only as prose (which blocks are deliberately
excluded). Nothing checks that any of them agree with the font.

**3. Nothing checks the ranges against reality.** An audit against
PragmataPro VF Liga's `hmtx` table found the ranges 9,575/9,581 correct and
**seven defects** (see below). All seven were invisible because the only
verification was a human reading a comment.

### Measured defects

Font: `~/Library/Fonts/PragmataProVF_liga_09.ttf` (what kitty's
`font_family PragmataPro VF Liga` resolves to on `spectra`). Advance widths
compared against `M` = 1024 units.

| Codepoint | Name                               | Font  | Declared | Symptom        |
| --------- | ---------------------------------- | ----- | -------- | -------------- |
| U+23F2    | timer clock (`todo-comments` TEST) | 2.00x | 1 cell   | clips          |
| U+23FB    | `iec_power`                        | 2.00x | 1 cell   | clips          |
| U+23FC    | `iec_toggle_power`                 | 2.00x | 1 cell   | clips          |
| U+23FE    | `iec_sleep_mode`                   | 2.00x | 1 cell   | clips          |
| U+2665    | `oct_heart`                        | 2.00x | 1 cell   | clips          |
| U+E009    | `pom_internal_interruption`        | 1.00x | 2 cells  | dead half-cell |
| U+E00A    | `pom_external_interruption`        | 1.00x | 2 cells  | dead half-cell |

U+23F2 is the important one. It is not in WezTerm's data — it is a plain Unicode
character chosen by hand — and `todo-comments.lua:23` documents it as
"not PUA, already one cell", which is false. A verification pass limited to the
Nerd Font set would not have caught it. This directly shapes the audit design.

Two hypotheses were tested and **refuted**, and are recorded so they are not
re-proposed:

- _U+26A1 `oct_zap` has the same bug as U+26A0._ It does not; the font draws it
  at 1.00x. Adjacency in Unicode implies nothing about advance width.
- _Excluding Powerline is a policy decision._ It is not. `pl_*` and `ple_*`
  measure 1.00x. The exclusion is a measurement that was written down as prose
  and thereafter maintained by hand.

## Non-goals

- An icon picker. (`telescope-emoji` is stale and a combined icon+emoji picker
  is worth revisiting, but not here.)
- Emoji.
- Aliases or shorthand names. WezTerm parity means WezTerm's names, exactly.
- Generating the kitty conf. The audit reads it and reports drift; it never
  writes it. `~/.config/kitty` stays owned by kitty.
- Resolving fallback-font metrics (see Open Questions).

## Architecture

```
lua/r35/glyphs/init.lua     facade — public API, back-compatible
lua/r35/glyphs/blocks.lua   THE width declaration; mirrors the kitty conf
lua/r35/glyphs/width.lua    setcellwidths, carve, intended_width
lua/r35/glyphs/icons.lua    name lookup + get/has/sign
lua/r35/glyphs/data.lua     GENERATED — 10,751 names
lua/r35/glyphs/health.lua   :checkhealth r35.glyphs
scripts/gen_glyphs.lua      nvim -l; generate and audit
tests/icons_test.lua        new
tests/glyphs_sign_test.lua  existing; path references updated
```

`lua/r35/glyphs.lua` becomes `lua/r35/glyphs/init.lua`. Lua resolves
`require("r35.glyphs")` to the same place, so all three existing call sites
(`init.lua:22`, `lua/plugins/diagnostics.lua:26`, `tests/glyphs_sign_test.lua:22`)
are untouched.

Seven comments across five files reference `r35.glyphs` or `lua/r35/glyphs.lua`
in prose. Those get a path touch-up. In a codebase this comment-dense, stale
prose is worse than a stale require — a broken require fails loudly; a comment
pointing at a file that no longer exists quietly misleads.

### Dependency direction

```
                 ┌──> width.lua ──> blocks.lua
init.lua ────────┤         ↑
                 └──> icons.lua ──> data.lua
                           │
health.lua ────────────────┴──> (all of the above)
```

`icons.lua` depends on `width.lua` for `icons.sign()` only; name lookup itself
needs nothing but `data.lua`. `blocks.lua` and `data.lua` are leaves: pure data,
no requires.

## Public API

```lua
local glyphs = require("r35.glyphs")

-- Measurement. Answers "how wide will this be once setup() has run", which is
-- the question that matters, and gives the same answer from either side of that
-- ordering. `strdisplaywidth` reports the currently installed table and is
-- therefore order-dependent — a trap this config has already been bitten by.
glyphs.cells(text)        --> integer
glyphs.width(cp)          --> integer

-- Fitting.
glyphs.fit(text, cells)   --> clamped; notifies WARN on genuine truncation
glyphs.fit_sign(text)     --> fit(text, 2)   [existing API, unchanged]

-- Applying.
glyphs.setup()            --> setcellwidths [existing API, unchanged]
glyphs.ranges             --> derived from blocks.lua [existing API]
                          --  shape unchanged: { first, last, width }[]
                          --  blocks.lua records carry a name; ranges drops it
```

```lua
local icons = require("r35.glyphs.icons")

icons.md_folder           --> "󰉋"    strict: unknown warns + placeholder
icons.get("md_folder")    --> "󰉋"|nil, never warns
icons.has("md_folder")    --> boolean
icons.sign("fa_bug")      --> lookup + fit to the sign column, one call
```

To iterate, `require("r35.glyphs.data")` is a plain table.

### Name collisions

Verified against all 10,751 names: every name carries a block prefix and an
underscore (`cod_`, `md_`, `fa_`, …), there are no duplicates, and none collides
with `get`, `has`, `sign`, `setup`, or `data`. Putting the lookup and the
functions on one table is safe.

### Unknown-name behaviour

`icons.md_foldr` warns once and returns a visible placeholder. This follows the
precedent already set in `glyphs.lua`: `setup()` notifies ERROR rather than
erroring, and `fit_sign` notifies WARN and returns a usable string. Failing
loudly beats a config that looks applied and is not; taking the config down
beats neither.

- **Warning is deduped per name.** Non-negotiable. A bad icon in a lualine
  section re-evaluates on nearly every redraw, so an undeduped `notify` is a
  denial-of-service at redraw frequency.
- **Suggestion** via `vim.fn.matchfuzzy` over the key list. Measured at 2.43 ms
  over 10,751 entries, and it runs only on the error path.
- **Placeholder** is `cod_question` (U+EB32). It sits inside the Codicons range,
  which is declared two cells, so a missing icon occupies exactly the space a
  real one would and the layout does not shift while you diagnose it.

### Loading

`icons.lua` does not require `data.lua` at load time; the `__index` metatable
pulls it in on first miss. Measured on this machine:

```
flat 10,751-entry table : 3.30 ms  (312 KB source, ~2 MB heap)
  same, via vim.loader  : 0.58 ms  (bytecode cache)
```

3.3 ms cold does not justify splitting into per-prefix modules and a routing
layer. One flat table, lazily required.

## The generator

`nvim -l scripts/gen_glyphs.lua`

1. Fetch `wezterm-char-props/src/nerdfonts_data.rs` from WezTerm `main`; resolve
   the commit SHA via the GitHub API and record it in the generated header.
2. Parse `("name", '\u{XXXX}')`.
3. Emit sorted Lua to `lua/r35/glyphs/data.lua` with a `GENERATED — do not edit`
   header carrying source URL, SHA, glyph count, and the regenerate command.

Four gates run before anything is written. On failure the generator **refuses to
write** rather than clobbering good data because upstream moved a file:

- count > 10,000
- every name matches `^[a-z0-9_]+$`
- every codepoint round-trips through `nr2char`/`str2list`
- no duplicate names

Network access happens only here, never at runtime.

### Audit mode

`nvim -l scripts/gen_glyphs.lua --audit [--font PATH]`

Measures a font's `hmtx` advance widths and reports disagreement with
`blocks.lua`. Font defaults to whatever kitty resolves on the machine it runs
on; `--font` overrides. This matters because `blocks.lua` is only correct for
one font on one machine, and the same width problems recur elsewhere with
different answers.

Two scan modes, both run by default:

- **Nerd Font set** — all 10,751 codepoints from `data.lua`.
- **Config literals** — every `\u{...}` escape and non-ASCII literal appearing
  in `lua/`, `colors/`, `init.lua`.

The second mode exists because of U+23F2: the defect lived precisely in the gap
between "glyphs the generator knows about" and "glyphs the config actually
uses." Known literal sites today: 7 in `todo-comments.lua`, 15 in
`langs/norg.lua`, plus non-ASCII literals in `blink-cmp.lua`, `neogit.lua`,
`pymple.lua`, `langs/markdown.lua`.

Audit also diffs `blocks.lua` against
`~/.config/kitty/conf.d/nerd_font_widths.conf`, **read-only**.

It shells out to `python3` with `fontTools` for font parsing. This is a
dev-time-only dependency on the `--audit` path; it degrades with a clear message
if `fontTools` is absent, and the runtime never touches it.

## Health check

`:checkhealth r35.glyphs` reports:

- whether `setup()` has run and how many ranges were installed
- ranges carved out for `fillchars`/`listchars`
- config literals whose measured width disagrees with `blocks.lua`
- drift between `blocks.lua` and the kitty conf
- `data.lua` provenance (upstream SHA, glyph count)

This is the piece that pays off on a machine other than this one: it names the
misaligned glyph and the reason, instead of requiring a statusline bisect.

## blocks.lua changes

Fixing the seven measured defects:

| Change          | Codepoints                             | Reason                               |
| --------------- | -------------------------------------- | ------------------------------------ |
| Add 2-cell      | U+23F2, U+23FB, U+23FC, U+23FE, U+2665 | font draws 2x, previously undeclared |
| Narrow Pomicons | `0xE000–0xE00A` → `0xE000–0xE008`      | U+E009, U+E00A measure 1x            |

Unchanged and explicitly verified as correct at 1 cell: U+23FD, U+2B58, U+26A1,
and all `pl_`/`ple_` Powerline codepoints.

Each entry carries its measured width and the font it was measured against, so
the next person does not have to re-derive it.

## Testing

Following the existing `tests/glyphs_sign_test.lua` shape — headless,
`nvim --headless -c 'luafile …'`, `cq` on failure, no plugins.

`tests/icons_test.lua`:

- pinned known names resolve to expected glyphs, across several blocks
- unknown name returns the placeholder, notifies exactly once; a second lookup
  is silent
- `get` returns nil for unknown and does not notify; `has` agrees with `get`
- data integrity: every value is exactly one codepoint; no name collides with
  the module's own functions; count is > 10,000 and matches the count recorded
  in the generated header. Asserting an exact literal count would fail on every
  upstream regeneration for no useful reason.
- laziness: requiring `r35.glyphs.icons` does not populate
  `package.loaded["r35.glyphs.data"]`
- `icons.sign(name)` output measures at most two cells

`tests/glyphs_sign_test.lua` keeps its existing coverage, including the order
independence case. Path references in its prose are updated.

Regression coverage for the seven defects lives in the audit, not in a test —
the assertion is about a font on disk, not about code.

## Migration

Mechanical, and separable from the module work:

- `todo-comments.lua`: 7 escapes → named lookups
- `langs/norg.lua`: 15 escapes → named lookups
- non-ASCII literals in `blink-cmp.lua`, `neogit.lua`, `pymple.lua`,
  `langs/markdown.lua`: audit first, convert what is a Nerd Font glyph

Each conversion deletes the naming comment beside it, since the name moves into
the code.

## Open questions

**Fallback-font metrics.** 1,170 of the 10,751 glyphs are absent from
PragmataPro VF Liga and fall back to Hack Nerd Font (installed). Their advance
widths have not been measured, so whether `blocks.lua` is correct for them is
unknown. Deliberately unresolved rather than guessed. The audit will surface it
as soon as it runs, since a missing glyph is distinguishable from a 1x one.

## Revision 2026-08-27b — block-scoped access, completion, picker

Supersedes the "Non-goals" entry that excluded a picker.

**Added to the public API.** Flat WezTerm parity stays the base; block-scoped
sugar is layered over it, never replacing it:

```lua
local g  = require("r35.glyphs")
local fa = g.from("fa")
fa.square_o   --> a plain string, same value as g.fa_square_o
g.fa_square_o --> unchanged
```

`from(block)` returns a flat table for that block, typed by literal-string
`---@overload` so lua_ls resolves it. **One level only.** Nested access
(`from("fa").square.outline`) was measured and rejected: 2,814 of 10,751 names
are simultaneously a glyph and a parent of other names, so the intermediate node
would have to be both a string and a table; a proxy table breaks every consumer
that assigns straight into plugin `opts`; and `from()` taking a runtime string
means lua_ls cannot infer through it without generating 12,085 node classes.
The nested form costs completion, which is what makes 10,751 names usable.
`fa_square_outline` does not exist in any case — the name is `fa_square_o`.

**Block aliases.** 16 keys, each mapping to exactly ONE WezTerm prefix. Strict
1:1 — no merges, therefore no collisions and nothing shadowed. Covers all
10,751 glyphs with no unmapped prefix:

| Alias         | WezTerm prefix | Count     |
| ------------- | -------------- | --------- |
| `fa`          | `fa_`          | 1817      |
| `fae`         | `fae_`         | 170       |
| `pl`          | `pl_`          | 9         |
| `ple`         | `ple_`         | 34        |
| `wi`          | `weather_`     | 228       |
| `sui`         | `seti_`        | 167       |
| `custom`      | `custom_`      | 41        |
| `oct`         | `oct_`         | 310       |
| `logos`       | `linux_`       | 130       |
| `iec`         | `iec_`         | 5         |
| `pom`         | `pom_`         | 11        |
| `md`          | `md_`          | 6880      |
| `cod`         | `cod_`         | 438       |
| `dev`         | `dev_`         | 508       |
| `indent`      | `indent_`      | 2         |
| `indentation` | `indentation_` | 1         |
|               | **total**      | **10751** |

WezTerm's own prefixes stay valid keys too (`from("weather")`, `from("seti")`,
`from("linux")`), so parity holds at both levels.

**Why nothing is merged.** The original sketch grouped `sui` as "Seti-UI +
Custom", matching the _font_ block — `blocks.lua` does declare
`U+E5FA-U+E6B7` as one range named "Seti-UI / Custom". But WezTerm names them
under two prefixes that share **17 leaf names**: `folder`, `go`, `c`, `cpp`,
`crystal`, `ruby`, `default`, `home`, `asm`, `bazel`, `elixir`, `elm`,
`firebase`, `kotlin`, `play_arrow`, `puppet`, `purescript`. Merging would
silently drop 17 glyphs. `indent_`/`indentation_` collide the same way on
`line`. Keeping the mapping 1:1 costs one extra block key each and loses
nothing — the font block and the name prefix simply are not the same
partition, and the names are what this module indexes.

**Four names need bracket syntax** in block-scoped form, being Lua keywords or
digit-leading once the prefix is stripped: `from("fa")["500px"]`,
`from("fa")["repeat"]`, `from("md")["function"]`, `from("md")["repeat"]`. Flat
parity is unaffected — `g.fa_repeat` is a valid identifier. The generator
asserts this set has exactly these four members, so a future upstream addition
that breaks dot-access is caught rather than discovered.

**Generated type annotations.** The generator emits a `---@class` meta file
alongside `data.lua`: one `---@field` per glyph whose description text is the
**rendered glyph**, so lua_ls shows the actual icon in the completion and hover
popup. One class per block alias, plus the flat class, plus the `from`
overloads. Risk to watch: a 10,751-field class may slow lua_ls; measured during
implementation, and the file is trivially droppable if it does.

**Picker.** `:R35Icons`, built on snacks (already installed). Fuzzy-search all
10,751 names with the glyph rendered beside each; yank the name, the flat name,
or the glyph. This replaces the previous non-goal — `telescope-emoji` is
unmaintained and the picker is the discovery half of the same problem.

## Credit

The lookup interface is Wez Furlong's design, from WezTerm's
`wezterm.nerdfonts`. `data.lua` is a transform of WezTerm's generated
`nerdfonts_data.rs`. Credited in the header of both `icons.lua` and `data.lua`,
and in the README.

## Notes

This directory is not a git repository (a `.gitignore` is present, `.git` is
not), so this spec is written but not committed.
