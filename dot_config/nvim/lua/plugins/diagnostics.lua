-- Diagnostic signs must fit the two-cell sign column.
--
-- LazyVim's diagnostic icons are a Nerd Font glyph followed by a space. Once
-- `r35.glyphs` declares those glyphs two cells wide the pair measures three,
-- one more than `sign_text` accepts, and every attempt to draw a diagnostic
-- sign dies with "Invalid 'sign_text'" -- on LSP publish, on the debounced
-- redraw, and on the InsertLeave refresh.
--
-- Note that this runs BEFORE `r35.glyphs.setup()`: LazyVim's LazyFile event
-- fires during `require("config.lazy")`, so nvim-lspconfig is fully loaded and
-- configured by the time init.lua reaches line 22. `fit_sign` measures against
-- the declared ranges rather than the widths currently installed precisely so
-- that does not matter -- see its comment. Nothing here may assume the glyphs
-- have been widened yet.
--
-- Rewriting whatever `opts` already carries, instead of restating the icons,
-- means this survives LazyVim changing them or another spec setting its own.
return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    local text = vim.tbl_get(opts, "diagnostics", "signs", "text")
    if type(text) ~= "table" then
      return
    end

    local fit_sign = require("r35.glyphs").fit_sign
    for severity, icon in pairs(text) do
      text[severity] = fit_sign(icon)
    end
  end,
}
