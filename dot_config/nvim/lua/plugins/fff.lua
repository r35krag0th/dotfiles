--[[
FFF stands for freakin fast fuzzy file finder (pick 3) and it is an opinionated fuzzy file picker for neovim. Just for files, but we'll try to solve file picking completely.

It comes with a dedicated rust backend runtime that keep tracks of the file index, your file access and modifications, git status, and provides a comprehensive typo-resistant fuzzy search experience.

GitHub: <https://github.com/dmtrKovalenko/fff.nvim>
--]]
return {
  "dmtrKovalenko/fff.nvim",
  -- BUG: for some reason this poops itself going into cmdline
  enabled = false,
  build = function()
    -- this will download prebuild binary or try to use existing rustup toolchain to build from source
    -- (if you are using lazy you can use gb for rebuilding a plugin if needed)
    require("fff.download").download_or_build_binary()
  end,
  -- if you are using nixos
  -- build = "nix run .#release",
  opts = { -- (optional)
    debug = {
      enabled = true, -- we expect your collaboration at least during the beta
      show_scores = true, -- to help us optimize the scoring system, feel free to share your scores!
    },
  },
  -- No need to lazy-load with lazy.nvim.
  -- This plugin initializes itself lazily.
  lazy = false,
  keys = {
    {
      "ff", -- try it if you didn't it is a banger keybinding for a picker
      function()
        require("fff").find_files()
      end,
      desc = "FFFind files",
    },
  },
}
