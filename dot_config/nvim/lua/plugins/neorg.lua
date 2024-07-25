return {
  "nvim-neorg/neorg",
  dependencies = {
    "luarocks.nvim",
    "folke/zen-mode.nvim",
    "max397574/neorg-contexts",
    {
      "pysan3/neorg-templates",
      dependencies = {
        "L3MON4D3/LuaSnip",
      },
    },
    {
      dir = "~/workspace/personal/neorg-pathfinder-character",
    },
  },
  lazy = false,
  version = "*",
  config = true,
  opts = {
    load = {
      ["core.defaults"] = {},
      -- ["core.tempus"] = {},
      ["core.completion"] = {
        config = {
          engine = "nvim-cmp",
        },
      },
      ["core.integrations.nvim-cmp"] = {},
      ["core.concealer"] = {},
      ["core.dirman"] = {
        config = {
          workspaces = {
            notes = "~/Documents/Neorg-Notes",
          },
          default_workspace = "notes",
        },
      },
      ["core.qol.toc"] = {},
      ["core.qol.todo_items"] = {},
      ["core.summary"] = {
        config = {
          strategy = "default",
        },
      },
      ["core.promo"] = {},
      ["core.export"] = { config = { extensions = "all" } },
      ["core.export.markdown"] = {},
      ["core.presenter"] = {
        config = {
          zen_mode = "zen-mode",
        },
      },
      ["core.ui"] = {},
      ["core.ui.calendar"] = {},
      ["core.tangle"] = {},
      ["external.context"] = {},
      ["external.templates"] = {},
      ["external.pathfinder-character"] = {},
    },
  },
}
