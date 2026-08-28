-- `:R35Icons` -- browse Nerd Font glyphs and insert the NAME.
--
-- snacks already provides `Snacks.picker.icons()`. This is not that: snacks
-- inserts the raw glyph character, which is the silent-corruption trap this
-- config avoids everywhere else (see the comment at the top of
-- lua/plugins/todo-comments.lua). This one inserts `fa_bug`, uses the WezTerm
-- naming that `r35.glyphs.icons` is keyed by, and needs no network.
--
-- No keymap is bound on purpose: `<leader>s*` is dense in LazyVim and guessing
-- a free one here would be a collision waiting to happen. Bind it yourself.
return {
  "folke/snacks.nvim",
  init = function()
    vim.api.nvim_create_user_command("R35Icons", function()
      require("r35.glyphs.picker").open()
    end, { desc = "Browse Nerd Font glyphs (inserts the name)" })
  end,
}
