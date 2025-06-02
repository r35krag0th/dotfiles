-- For `plugins/markview.lua` users.
return {
  -- Setup Markview
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    keys = {
      { "<localleader><Up>", ":Checkbox change 0 1<CR>", desc = "Ascend 1 Level in To-do States" },
      { "<localleader><Down>", ":Checkbox change 0 -1<CR>", desc = "Descend 1 Level in To-do States" },
      { "<localleader><Left>", ":Checkbox change -1 0<CR>", desc = "Previous Checkbox State" },
      { "<localleader><Right>", ":Checkbox change 1 0<CR>", desc = "Next Checkbox State" },
      { "<localleader><CR>", ":Checkbox toggle<CR>", desc = "Toggle To-do State" },
      -- Vim-like
      { "<localleader>tk", ":Checkbox change 0 1<CR>", desc = "Ascend 1 Level in To-do States" },
      { "<localleader>tj", ":Checkbox change 0 -1<CR>", desc = "Descend 1 Level in To-do States" },
      { "<localleader>th", ":Checkbox change -1 0<CR>", desc = "Previous Checkbox State" },
      { "<localleader>tl", ":Checkbox change 1 0<CR>", desc = "Next Checkbox State" },
      { "<localleader>tt", ":Checkbox toggle<CR>", desc = "Toggle To-do State" },
      { "<localleader>ti", ":Checkbox interactive<CR>", desc = "Interactively change To-do State" },
    },
    opts = function()
      require("markview.extras.checkboxes").setup()
      return {
        markdown = {
          headings = require("markview.presets").headings.glow,
        },
        -- preview = {
        --   filetypes = {
        --     "md",
        --     "rmd",
        --     "quarto",
        --     "vimwiki",
        --   },
        -- },
      }
    end,
  },
}
