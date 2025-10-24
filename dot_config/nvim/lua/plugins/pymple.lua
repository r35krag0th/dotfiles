--[[
# Pymple

Pymple adds missing common Python IDE features for Neovim when dealing with imports:

- 🦀 automatic import updates on module/package rename
- 🦀 code-action-like import resolution

## tl;dr

🪄 Automatic import updates on file/dir move/rename with support for:

- neo-tree (https://github.com/nvim-neo-tree/neo-tree.nvim)
- nvim-tree (https://github.com/nvim-tree/nvim-tree.lua)
- oil.nvim (https://github.com/stevearc/oil.nvim)
- yazi.nvim (https://github.com/mikavilpas/yazi.nvim)
- mini.nvim (https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-files.md)

GitHub: <https://github.com/alexpasmantier/pymple.nvim>
--]]
return {
  {
    "alexpasmantier/pymple.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      -- optional (nicer ui)
      "stevearc/dressing.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    build = ":PympleBuild",
    config = function()
      require("pymple").setup()
    end,
  },
}
