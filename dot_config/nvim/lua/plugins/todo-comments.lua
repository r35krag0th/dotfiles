-- todo-comments ships its keyword icons as "<glyph> " - glyph plus a padding
-- space. That was two display cells while Nerd Font glyphs measured one. They
-- now measure two (see lua/r35/glyphs.lua), which makes the sign three cells and
-- Vim rejects it with E239: Invalid sign text, since sign text may be at most
-- two cells.
--
-- Dropping the padding restores a valid two-cell sign and, incidentally, aligns
-- the sign column properly instead of leaving the glyph hanging off-centre.
--
-- Icons are \u{} escapes on purpose: these are Private Use Area codepoints and
-- render as nothing without a patched font, so literals would be unreadable in a
-- diff or on the web.
return {
  "folke/todo-comments.nvim",
  opts = {
    keywords = {
      FIX = { icon = "\u{F188}" }, -- fa-bug
      TODO = { icon = "\u{F00C}" }, -- fa-check
      HACK = { icon = "\u{F490}" }, -- oct-flame
      WARN = { icon = "\u{F071}" }, -- fa-exclamation-triangle
      PERF = { icon = "\u{F43A}" }, -- oct-rocket
      NOTE = { icon = "\u{EA74}" }, -- cod-note
      TEST = { icon = "\u{23F2}" }, -- timer clock (not PUA, already one cell)
    },
  },
}
