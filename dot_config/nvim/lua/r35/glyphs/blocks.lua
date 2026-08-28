---Nerd Font glyph cell widths, declared as blocks.
---
---This is THE declaration. `width.lua` derives its `setcellwidths()` ranges from
---it, `scripts/gen_glyphs.lua --audit` checks it against real font metrics, and
---it mirrors ~/.config/kitty/conf.d/nerd_font_widths.conf.
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
---line containing an icon will drift. `:checkhealth r35.glyphs` reports drift.
---
---Powerline (U+E0A0-U+E0D7) is deliberately absent, but not as a policy: the
---font measures it at 1024 units, i.e. one cell. It is excluded because that is
---what it is, not because anyone decided so.

---@class r35.glyphs.Block
---@field name string    human label; mirrors the kitty conf comment
---@field first integer  first codepoint, inclusive
---@field last integer   last codepoint, inclusive
---@field cells integer  display cells

---@type r35.glyphs.Block[]
return {
  -- U+E009 and U+E00A measure 1024 units (one cell); the rest of the block is
  -- 2048. Declaring the whole block two cells left a dead half-cell after each.
  { name = "Pomicons", first = 0x0E000, last = 0x0E008, cells = 2 },
  { name = "Font Awesome Extension", first = 0x0E200, last = 0x0E2A9, cells = 2 },
  { name = "Weather", first = 0x0E300, last = 0x0E3E3, cells = 2 },
  { name = "Seti-UI / Custom", first = 0x0E5FA, last = 0x0E6B7, cells = 2 },
  { name = "Devicons", first = 0x0E700, last = 0x0E8EF, cells = 2 },
  { name = "Codicons", first = 0x0EA60, last = 0x0EC1E, cells = 2 },
  { name = "Font Awesome", first = 0x0ED00, last = 0x0F2FF, cells = 2 },
  { name = "Font Logos", first = 0x0F300, last = 0x0F381, cells = 2 },
  { name = "Octicons", first = 0x0F400, last = 0x0F533, cells = 2 },
  { name = "Material Design", first = 0xF0001, last = 0xF1AF0, cells = 2 },
  -- Non-PUA glyphs PragmataPro nonetheless draws at 2048 units. They clip
  -- without this, exactly the way U+26A0 did. U+23FD and U+2B58 sit between
  -- these and measure 1024, which is why the IEC range is split rather than
  -- declared 23FB-23FE wholesale.
  { name = "Timer clock", first = 0x023F2, last = 0x023F2, cells = 2 },
  { name = "IEC power / toggle power", first = 0x023FB, last = 0x023FC, cells = 2 },
  { name = "IEC sleep mode", first = 0x023FE, last = 0x023FE, cells = 2 },
  { name = "Black heart suit", first = 0x02665, last = 0x02665, cells = 2 },
  { name = "Warning sign", first = 0x026A0, last = 0x026A0, cells = 2 },
}
