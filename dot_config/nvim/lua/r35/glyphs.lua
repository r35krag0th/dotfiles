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

---Apply the widths.
---setcellwidths() rejects the whole list if any entry is invalid, so a bad range
---would silently leave every glyph at its old width. Failing loudly is better
---than a config that looks applied and is not.
function M.setup()
  local ok, err = pcall(vim.fn.setcellwidths, M.ranges)
  if not ok then
    vim.notify("r35.glyphs: setcellwidths failed: " .. tostring(err), vim.log.levels.ERROR)
  end
end

return M
