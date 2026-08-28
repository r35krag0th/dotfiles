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

-- `nvim -l script.lua --audit` puts the script's own args in the global `arg`.
local MODE, FONT = "generate", nil
for i, a in ipairs(_G.arg or {}) do
  if a == "--audit" then
    MODE = "audit"
  elseif a == "--font" then
    FONT = (_G.arg or {})[i + 1]
  end
end

---Block aliases: short key -> the ONE WezTerm prefix it maps to.
---
---Strictly 1:1. `seti_`/`custom_` share 17 leaf names and `indent_`/
---`indentation_` share `line`, so merging them would silently drop glyphs.
---Each keeps its own key instead: nothing is shadowed, nothing is lost.
local ALIASES = {
  fa = "fa",
  fae = "fae",
  pl = "pl",
  ple = "ple",
  wi = "weather",
  sui = "seti",
  custom = "custom",
  oct = "oct",
  logos = "linux",
  iec = "iec",
  pom = "pom",
  md = "md",
  cod = "cod",
  dev = "dev",
  indent = "indent",
  indentation = "indentation",
}

---Leaf names that are Lua keywords or digit-leading once the prefix is
---stripped, so block-scoped access needs bracket syntax. Asserted rather than
---documented: an upstream addition that breaks dot-access should fail the
---build, not surprise someone later.
---Disagreements between the font and `blocks.lua` that are DELIBERATE.
---
---An audit that reports a known-and-accepted finding on every run is an audit
---that gets ignored. Each entry needs a reason, and removing one should be a
---considered act rather than a way to quiet the output.
---@type table<integer, string>
local ACKNOWLEDGED = {
  [0x26A1] = "oct_zap: East Asian Wide, so nvim AND kitty both reserve 2 cells. "
    .. "The font draws 1024 units, so the glyph renders slightly small -- but "
    .. "nvim and kitty agree with each other, so nothing drifts. Forcing 1 here "
    .. "without changing kitty would turn a cosmetic quirk into real drift.",
}

local EXPECTED_BRACKETED = { "fa.500px", "fa.repeat", "md.function", "md.repeat" }

local KEYWORDS = {
  ["and"] = true,
  ["break"] = true,
  ["do"] = true,
  ["else"] = true,
  ["elseif"] = true,
  ["end"] = true,
  ["false"] = true,
  ["for"] = true,
  ["function"] = true,
  ["goto"] = true,
  ["if"] = true,
  ["in"] = true,
  ["local"] = true,
  ["nil"] = true,
  ["not"] = true,
  ["or"] = true,
  ["repeat"] = true,
  ["return"] = true,
  ["then"] = true,
  ["true"] = true,
  ["until"] = true,
  ["while"] = true,
}

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

local function generate()
  print("fetching " .. RAW)
  local src = fetch(RAW)

  local sha = "unknown"
  local ok, commit = pcall(vim.json.decode, fetch(COMMITS))
  if ok and type(commit) == "table" and commit.sha then
    sha = commit.sha:sub(1, 12)
  end

  -- Long-bracket pattern so the backslash in \u{...} needs no escaping.
  local PATTERN = [[%("([a-z0-9_]+)",%s*'\u{(%x+)}'%)]]

  local names, seen, glyphs = {}, {}, {}
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

  -- Every glyph must land in exactly one alias block, and no alias may be empty.
  local prefix_to_alias, counts = {}, {}
  for alias, prefix in pairs(ALIASES) do
    if prefix_to_alias[prefix] then
      die(("two aliases map to %s_: %s and %s"):format(prefix, prefix_to_alias[prefix], alias))
    end
    prefix_to_alias[prefix] = alias
    counts[alias] = 0
  end
  local bracketed = {}
  for _, name in ipairs(names) do
    local prefix, leaf = name:match("^([a-z0-9]+)_(.+)$")
    local alias = prefix and prefix_to_alias[prefix]
    if not alias then
      die(("glyph %q has prefix %q which no alias maps to"):format(name, tostring(prefix)))
    end
    counts[alias] = counts[alias] + 1
    if KEYWORDS[leaf] or leaf:match("^%d") then
      bracketed[#bracketed + 1] = alias .. "." .. leaf
    end
  end
  for alias, n in pairs(counts) do
    if n == 0 then
      die("alias " .. alias .. " matched no glyphs")
    end
  end
  table.sort(bracketed)
  if table.concat(bracketed, ",") ~= table.concat(EXPECTED_BRACKETED, ",") then
    die(
      "the set of names needing bracket syntax changed:\n  expected: "
        .. table.concat(EXPECTED_BRACKETED, ", ")
        .. "\n  got:      "
        .. table.concat(bracketed, ", ")
    )
  end
  print("gates passed: count, identifiers, round-trip, uniqueness, alias coverage, bracket set")

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
    w(('  %s = "\\u{%X}",'):format(name, glyphs[name]))
  end
  w("}")

  local fh = assert(io.open(OUT, "w"))
  fh:write(table.concat(out, "\n"), "\n")
  fh:close()

  -- ---------------------------------------------------------------- types.lua
  -- Written from the same parse as data.lua, deliberately: regenerating one
  -- without the other would leave completion advertising glyphs that no longer
  -- exist. `---@meta` marks it definition-only, so it is never loaded at
  -- runtime and costs nothing but lua_ls index time.
  local t = {}
  local function tw(line)
    t[#t + 1] = line
  end
  local function glyph_of(name)
    return vim.fn.nr2char(glyphs[name])
  end

  tw("---@meta")
  tw("")
  tw("---Type annotations for the Nerd Font glyph tables.")
  tw("---")
  tw("---GENERATED -- do not edit. Written by scripts/gen_glyphs.lua alongside")
  tw("---data.lua, from the same parse.")
  tw("---")
  tw("---Each field's description is the RENDERED glyph, so lua_ls shows the actual")
  tw("---icon in the completion and hover popup. That is the whole point of this")
  tw("---file: with 10,751 names, completion is what makes them usable.")
  tw("---")
  tw("---Source: wezterm-char-props/src/nerdfonts_data.rs @ " .. sha)
  tw("")
  tw("---Flat WezTerm-parity names: `icons.fa_bug`.")
  tw("---@class r35.glyphs.names")
  for _, name in ipairs(names) do
    tw(("---@field %s string %s"):format(name, glyph_of(name)))
  end
  tw("")

  -- One class per WezTerm prefix, keyed by the leaf name.
  local leaves = {}
  for _, name in ipairs(names) do
    local prefix, leaf = name:match("^([a-z0-9]+)_(.+)$")
    leaves[prefix] = leaves[prefix] or {}
    table.insert(leaves[prefix], { leaf = leaf, name = name })
  end
  local prefixes = {}
  for prefix in pairs(leaves) do
    prefixes[#prefixes + 1] = prefix
  end
  table.sort(prefixes)
  for _, prefix in ipairs(prefixes) do
    local aliases_for = {}
    for alias, p in pairs(ALIASES) do
      if p == prefix then
        aliases_for[#aliases_for + 1] = alias
      end
    end
    table.sort(aliases_for)
    tw(
      ("---Block %s_ -- reached via from(%q)%s."):format(
        prefix,
        aliases_for[1] or prefix,
        prefix ~= aliases_for[1] and (" or from(%q)"):format(prefix) or ""
      )
    )
    tw(("---@class r35.glyphs.block.%s"):format(prefix))
    for _, e in ipairs(leaves[prefix]) do
      tw(("---@field %s string %s"):format(e.leaf, glyph_of(e.name)))
    end
    tw("")
  end

  -- Overloads so `from("fa")` resolves to a typed table rather than
  -- table<string, string>. Literal-string overloads are how lua_ls narrows a
  -- runtime string argument; without them block access gets no completion.
  tw("---Block-scoped glyph access.")
  tw("---@class r35.glyphs.From")
  local keys = {}
  for alias, prefix in pairs(ALIASES) do
    keys[#keys + 1] = { key = alias, prefix = prefix }
    if alias ~= prefix then
      keys[#keys + 1] = { key = prefix, prefix = prefix }
    end
  end
  table.sort(keys, function(a, b)
    return a.key < b.key
  end)
  for _, k in ipairs(keys) do
    tw(("---@overload fun(block: %q): r35.glyphs.block.%s"):format(k.key, k.prefix))
  end

  local TYPES = "lua/r35/glyphs/types.lua"
  local tfh = assert(io.open(TYPES, "w"))
  tfh:write(table.concat(t, "\n"), "\n")
  tfh:close()
  print(("wrote %s (%d lines, %.0f KB)"):format(TYPES, #t, vim.fn.getfsize(TYPES) / 1024))

  local sizes = {}
  for alias, n in pairs(counts) do
    sizes[#sizes + 1] = ("%s=%d"):format(alias, n)
  end
  table.sort(sizes)
  print("blocks: " .. table.concat(sizes, " "))
  print(("wrote %s (%d entries, %.0f KB)"):format(OUT, #names, vim.fn.getfsize(OUT) / 1024))
end

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
  -- kitty.conf usually just `include`s conf.d/*.conf, so the real font_family
  -- is rarely in kitty.conf itself. Read both, last declaration wins, which is
  -- kitty's own precedence.
  local family = nil
  -- Expand the home dir FIRST, then glob: expand() on a path that already
  -- contains a wildcard returns only the first match. kitty itself uses
  -- `globinclude conf.d/**/*.conf`, so recurse the same way it does.
  local dir = vim.fn.expand("~/.config/kitty")
  local files = { dir .. "/kitty.conf" }
  vim.list_extend(files, vim.fn.glob(dir .. "/conf.d/**/*.conf", false, true))
  for _, conf in ipairs(files) do
    if vim.fn.filereadable(conf) == 1 then
      for _, line in ipairs(vim.fn.readfile(conf)) do
        local f = line:match("^%s*font_family%s+(.-)%s*$")
        if f and f ~= "" then
          family = f
        end
      end
    end
  end
  if not family then
    die("no font_family found in ~/.config/kitty/{kitty.conf,conf.d/*.conf}; pass --font PATH")
  end
  local res = vim.system({ "fc-match", "-f", "%{file}", family }, { text = true }):wait()
  if res.code ~= 0 or res.stdout == "" then
    die("could not resolve a font file for " .. family .. "; pass --font PATH")
  end
  print(("font: %s -> %s"):format(family, res.stdout))
  return res.stdout
end

---Advance width per codepoint, in cells, from the font's own hmtx table.
---
---Shells out to python3/fontTools. This is a dev-time dependency on the audit
---path only -- nothing under lua/ touches it.
---@param path string
---@param codepoints integer[]
---@return table<string, number>|nil widths, string? err
local function measure(path, codepoints)
  -- [==[ rather than [[ : the python below contains `]]` in
  -- hmtx[cmap[ord("M")]][0], which would close a plain long bracket early.
  local py = [==[
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
]==]
  local res = vim.system({ "python3", "-c", py, path }, { text = true, stdin = vim.json.encode(codepoints) }):wait()
  if res.code ~= 0 then
    return nil, (res.stderr or ""):gsub("%s+$", "")
  end
  local ok, decoded = pcall(vim.json.decode, res.stdout)
  if not ok then
    return nil, "could not decode font measurements"
  end
  return decoded
end

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
    -- Skip our own generated tables: their codepoints are the Nerd Font set,
    -- already covered, and rescanning them here is 10,751 wasted comparisons.
    if not file:match("glyphs/data%.lua$") and not file:match("glyphs/types%.lua$") then
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
  end
  return found
end

---@param cp integer
---@param blocks r35.glyphs.Block[]
---@return integer
local function declared(cp, blocks)
  for _, b in ipairs(blocks) do
    if cp >= b.first and cp <= b.last then
      return b.cells
    end
  end
  return vim.fn.strdisplaywidth(vim.fn.nr2char(cp))
end

local function audit()
  package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
  local blocks = require("r35.glyphs.blocks")
  local data = require("r35.glyphs.data")
  local font = resolve_font()

  local targets, source = {}, {}
  for _, glyph in pairs(data) do
    local cp = vim.fn.str2list(glyph)[1]
    if not source[cp] then
      targets[#targets + 1] = cp
      source[cp] = "nerd font set"
    end
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

  local acked = {}
  problems = vim.tbl_filter(function(p)
    if ACKNOWLEDGED[p.cp] then
      acked[#acked + 1] = p
      return false
    end
    return true
  end, problems)

  local function by_cp(a, b)
    return a.cp < b.cp
  end
  table.sort(problems, by_cp)
  table.sort(acked, by_cp)

  print(("\nchecked %d codepoints; %d absent from the font (fallback)"):format(#targets, missing))

  if #acked > 0 then
    print(("\n%d acknowledged disagreement(s):"):format(#acked))
    for _, p in ipairs(acked) do
      print(("  U+%05X  font=%d  blocks.lua=%d"):format(p.cp, p.actual, p.want))
      print("    " .. ACKNOWLEDGED[p.cp]:gsub("%s+", " "))
    end
  end

  if #problems == 0 then
    print("\nblocks.lua agrees with the font.")
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
