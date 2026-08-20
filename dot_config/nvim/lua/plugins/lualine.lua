-- Point lualine at the candy theme.
--
-- lualine takes a theme table rather than reading highlight groups, so it is the
-- one piece of UI that cannot follow the colorscheme on its own. LazyVim's
-- default of "auto" derives something serviceable from StatusLine, but it cannot
-- know that each vim mode should get its own candy.
--
-- Guarded so switching back to nightfox or tokyonight does not leave a candy
-- statusline stranded under a different theme.
--
-- The guard asks r35.themes which colorscheme it WILL select, not
-- `vim.g.colors_name`, which is still unset here: plugin `opts` resolve while
-- `require("config.lazy")` runs, and init.lua only calls setTheme() after that
-- returns. Checking the live value looks correct and silently never matches.
return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.options = opts.options or {}
    if require("r35.themes").name() == "candy" then
      opts.options.theme = require("r35.themes.candy.lualine")
    end
    return opts
  end,
}
