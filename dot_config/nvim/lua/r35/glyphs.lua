---Nerd Font glyph cell widths.
---
---PragmataPro draws every Nerd Font glyph at 2048 units against its normal 1024
---- exactly double width - while wcwidth reports 1. Terminals therefore either
---squash the glyph into one cell (kitty does this for Private Use Area
---codepoints, which is why most icons look compressed) or let it draw at full
---width and clip it (what happens to U+26A0, which is not in the PUA).
---
---Declaring them two cells wide renders them at their designed size: no
---clipping, no compression.
---
---IMPORTANT: kitty is told the same widths in
---~/.config/kitty/conf.d/nerd_font_widths.conf. These two lists MUST stay in
---sync, or neovim and the terminal will disagree about where text sits and every
---line containing an icon will drift. Change one, change the other.
---
---Powerline (U+E0A0-U+E0D7) is deliberately absent: PragmataPro already draws it
---at single width and the kitty tab bar's pill caps depend on that.

local M = {}

---@type integer[][] { first, last, width } - must mirror nerd_font_widths.conf
M.ranges = {
  { 0x0E000, 0x0E00A, 2 }, -- Pomicons
  { 0x0E200, 0x0E2A9, 2 }, -- Font Awesome Extension
  { 0x0E300, 0x0E3E3, 2 }, -- Weather
  { 0x0E5FA, 0x0E6B7, 2 }, -- Seti-UI / Custom
  { 0x0E700, 0x0E8EF, 2 }, -- Devicons
  { 0x0EA60, 0x0EC1E, 2 }, -- Codicons
  { 0x0ED00, 0x0F2FF, 2 }, -- Font Awesome
  { 0x0F300, 0x0F381, 2 }, -- Font Logos
  { 0x0F400, 0x0F533, 2 }, -- Octicons
  { 0xF0001, 0xF1AF0, 2 }, -- Material Design
  { 0x026A0, 0x026A0, 2 }, -- the one non-PUA offender
}

---Codepoints that must stay single width.
---
---'fillchars' and 'listchars' may only contain single-width characters, and
---setcellwidths() rejects the ENTIRE call with E835 if even one of their glyphs
---falls inside a two-cell range. LazyVim puts Nerd Font chevrons in 'fillchars'
---(foldopen, foldclose), which lands squarely inside the Font Awesome block.
---
---Reading them at runtime rather than hardcoding the exceptions means changing
---'fillchars' later cannot silently break this.
---@return table<integer, boolean>
local function reserved()
  local set = {}
  for _, name in ipairs({ "fillchars", "listchars" }) do
    for item in vim.gsplit(vim.o[name] or "", ",", { trimempty = true }) do
      local value = item:match("^[^:]+:(.*)$")
      if value and value ~= "" then
        for _, cp in ipairs(vim.fn.str2list(value)) do
          set[cp] = true
        end
      end
    end
  end
  return set
end

---Split ranges so none of `excluded` falls inside any of them.
---@param ranges integer[][]
---@param excluded table<integer, boolean>
---@return integer[][]
local function carve(ranges, excluded)
  local out = {}
  for _, r in ipairs(ranges) do
    local first, last, width = r[1], r[2], r[3]
    local holes = {}
    for cp in pairs(excluded) do
      if cp >= first and cp <= last then
        holes[#holes + 1] = cp
      end
    end
    table.sort(holes)
    local start = first
    for _, cp in ipairs(holes) do
      if cp > start then
        out[#out + 1] = { start, cp - 1, width }
      end
      start = cp + 1
    end
    if start <= last then
      out[#out + 1] = { start, last, width }
    end
  end
  return out
end

---Apply the widths, minus whatever 'fillchars'/'listchars' have claimed.
function M.setup()
  local excluded = reserved()
  local ranges = carve(M.ranges, excluded)
  local ok, err = pcall(vim.fn.setcellwidths, ranges)
  if not ok then
    -- Failing loudly beats a config that looks applied and is not: setcellwidths
    -- is all-or-nothing, so a rejected call leaves every glyph at its old width.
    vim.notify("r35.glyphs: setcellwidths failed: " .. tostring(err), vim.log.levels.ERROR)
  end
end

return M
