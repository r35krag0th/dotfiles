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
M.width = width.width
M.cells = width.cells
M.fit = width.fit

return M
