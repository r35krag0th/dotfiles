-- Generated. Candy theme for lualine.
--
-- lualine wants a theme table rather than highlight groups, so unlike every
-- other plugin it cannot pick colours up from the colorscheme. This mirrors the
-- palette instead; regenerate rather than hand-editing.
--
-- Section `a` inverts -- dark ink on a bright candy, bold -- which is the same
-- pairing the active kitty tab pill and CurSearch use. Setting both colours
-- means the mode indicator can never inherit an unreadable foreground, and each
-- mode gets its own candy, so mode is legible from colour alone.
--
-- Modes run 7.4:1 to 11.4:1 against their ground and are mutually distinct
-- (closest pair 8.6 in OKLab dE).

local C = require("r35.themes.candy.palette")

return {
  normal = {
    a = { fg = C["bg"], bg = C["function"], gui = "bold" },
    b = { fg = C["fg"], bg = C["bg_float"] },
    c = { fg = C["comment"], bg = C["bg_gutter"] },
  },
  insert = { a = { fg = C["bg"], bg = C["string"], gui = "bold" } },
  visual = { a = { fg = C["bg"], bg = C["keyword"], gui = "bold" } },
  replace = { a = { fg = C["bg"], bg = C["error"], gui = "bold" } },
  command = { a = { fg = C["bg"], bg = C["constant"], gui = "bold" } },
  terminal = { a = { fg = C["bg"], bg = C["type"], gui = "bold" } },
  inactive = {
    a = { fg = C["comment"], bg = C["bg_float"], gui = "bold" },
    b = { fg = C["line_nr"], bg = C["bg_gutter"] },
    c = { fg = C["line_nr"], bg = C["bg_gutter"] },
  },
}
