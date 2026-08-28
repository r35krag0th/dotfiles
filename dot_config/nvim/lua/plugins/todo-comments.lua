-- todo-comments ships its keyword icons as "<glyph> " - glyph plus a padding
-- space. That was two display cells while Nerd Font glyphs measured one. They
-- now measure two (see lua/r35/glyphs/blocks.lua), which makes the sign three
-- Vim rejects it with E239: Invalid sign text, since sign text may be at most
-- two cells.
--
-- Dropping the padding restores a valid two-cell sign and, incidentally, aligns
-- the sign column properly instead of leaving the glyph hanging off-centre.
--
-- Icons are looked up by name rather than written as codepoints. The old form
-- carried a `-- fa-bug` comment beside each escape because PUA codepoints are
-- unreadable in a diff; the name makes that comment unnecessary.
--
-- Two of the old codepoints had drifted in the Nerd Fonts v2 -> v3 renumbering:
--
--   U+F43A was labelled oct-rocket but is `oct_clock` in v3. Kept as-is and
--     renamed -- a stopwatch says "performance" better than a rocket does, so
--     the drift landed on a better icon than the one originally asked for.
--   U+EA74 was labelled cod-note but is `cod_info` in v3. Changed to
--     `cod_note`, which is what the comment always meant.
--
local icons = require("r35.glyphs.icons")

return {
  "folke/todo-comments.nvim",
  opts = {
    keywords = {
      FIX = { icon = icons.fa_bug },
      TODO = { icon = icons.fa_check },
      HACK = { icon = icons.oct_flame },
      WARN = { icon = icons.fa_exclamation_triangle },
      PERF = { icon = icons.oct_clock },
      NOTE = { icon = icons.cod_note },
      -- No Nerd Font name: a plain Unicode timer clock, so it stays a literal.
      -- Declared two cells in r35.glyphs.blocks despite not being PUA.
      TEST = { icon = "\u{23F2}" },
    },
  },
}
