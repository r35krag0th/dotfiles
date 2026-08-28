---`:checkhealth r35.glyphs`
---
---The question this answers: why is that icon misaligned? It is the piece that
---pays off on a machine other than the one blocks.lua was written for -- it
---names the glyph and the reason, instead of requiring a statusline bisect.
---
---Font metrics deliberately are NOT checked here. That needs python/fontTools
---and takes seconds; `nvim -l scripts/gen_glyphs.lua --audit` owns it. This
---checks the things that are cheap and true at runtime.

local M = {}

local H = vim.health

---Parse the kitty mirror into a list of {first, last, cells}.
---
---Ranges rather than an expanded codepoint map: Material Design alone spans
---~110,000 codepoints, and expanding it to compare is wasteful when every
---disagreement necessarily shows up at a range boundary.
---@return integer[][]|nil
local function kitty_ranges()
  local dir = vim.fn.expand("~/.config/kitty")
  local out = {}
  for _, path in ipairs(vim.fn.glob(dir .. "/conf.d/**/*.conf", false, true)) do
    for _, line in ipairs(vim.fn.readfile(path)) do
      local first, last, cells = line:match("^%s*narrow_symbols%s+U%+(%x+)%-U%+(%x+)%s+(%d+)")
      if not first then
        local one, c = line:match("^%s*narrow_symbols%s+U%+(%x+)%s+(%d+)")
        first, last, cells = one, one, c
      end
      if first then
        out[#out + 1] = { tonumber(first, 16), tonumber(last, 16), tonumber(cells) }
      end
    end
  end
  return #out > 0 and out or nil
end

---Declared width of `cp` in a {first, last, cells} list, defaulting to 1.
---@param cp integer
---@param ranges integer[][]
---@return integer
local function width_in(cp, ranges)
  for _, r in ipairs(ranges) do
    if cp >= r[1] and cp <= r[2] then
      return r[3]
    end
  end
  return 1
end

---Codepoints where nvim and kitty disagree.
---
---Checked at every range boundary on BOTH sides, plus one codepoint either
---side of each. A one-directional scan over our own blocks cannot see the case
---where kitty declares MORE than we do -- which is exactly what U+E009/U+E00A
---became when the Pomicons block was narrowed.
---@param ours integer[][]
---@param theirs integer[][]
---@return string[]
local function drift(ours, theirs)
  local probes, seen = {}, {}
  for _, side in ipairs({ ours, theirs }) do
    for _, r in ipairs(side) do
      for _, cp in ipairs({ r[1] - 1, r[1], r[2], r[2] + 1 }) do
        if cp >= 0 and not seen[cp] then
          seen[cp] = true
          probes[#probes + 1] = cp
        end
      end
    end
  end
  table.sort(probes)

  local out = {}
  for _, cp in ipairs(probes) do
    local mine, yours = width_in(cp, ours), width_in(cp, theirs)
    if mine ~= yours then
      out[#out + 1] = ("U+%04X: nvim=%d kitty=%d"):format(cp, mine, yours)
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
  local theirs = kitty_ranges()
  if not theirs then
    H.warn("no narrow_symbols found in ~/.config/kitty/conf.d/**/*.conf", {
      "nvim and kitty will disagree about cell widths, and every line with an icon drifts.",
    })
  else
    local ours = {}
    for _, b in ipairs(blocks) do
      ours[#ours + 1] = { b.first, b.last, b.cells }
    end
    local diffs = drift(ours, theirs)
    if #diffs == 0 then
      H.ok(("kitty conf agrees with blocks.lua (%d ranges each side)"):format(#theirs))
    else
      H.error(("%d codepoint(s) where nvim and kitty disagree:"):format(#diffs), diffs)
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

  -- Unknown names land as diagnostics in the file that used them, which is the
  -- right place -- unless you never open that file. This is the net for that.
  H.start("r35.glyphs: unknown names")
  local icons_ok, icons = pcall(require, "r35.glyphs.icons")
  if not icons_ok then
    H.error("r35.glyphs.icons failed to load", { tostring(icons) })
  else
    local misses = icons.misses()
    if #misses == 0 then
      H.ok("no unknown glyph names looked up this session")
    else
      local lines = {}
      for _, m in ipairs(misses) do
        lines[#lines + 1] = ("%s:%d  %s"):format(vim.fn.fnamemodify(m.file, ":~:."), m.line, m.name)
      end
      H.warn(("%d unknown glyph name(s) looked up:"):format(#misses), lines)
    end
  end
end

return M
