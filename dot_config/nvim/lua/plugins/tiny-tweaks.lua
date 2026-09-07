return {
  {
    -- Toggle splitting/joining blocks of code like:
    -- arrays, hashes, statements, dictionaries, etc
    --
    -- https://github.com/wansmer/treesj
    "wansmer/treesj",
    opts = { use_default_keymaps = false },
    keys = {
      {
        "<leader>m",
        function()
          require("treesj").toggle()
        end,
        mode = "n",
        desc = "Toggle Split/Join",
      },
    },
  },
  {
    -- Smart and highly customizable insertion of various kinds of log statements~
    --
    -- https://chrisgrieser/nvim-chainsaw
    "chrisgrieser/nvim-chainsaw",
    keys = {
      {
        "<localleader>lv",
        function()
          require("chainsaw").variableLog()
        end,
        desc = "Log name & variable",
      },
      {
        "<localleader>lo",
        function()
          require("chainsaw").objectLog()
        end,
        desc = "Log name & variable (dump obj)",
      },
      {
        "<localleader>lt",
        function()
          require("chainsaw").typeLog()
        end,
        desc = "Log name & type",
      },
      {
        "<localleader>le",
        function()
          require("chainsaw").emojiLog()
        end,
        desc = "Quick Emoji-prefixed log",
      },
      {
        "<localleader>lX",
        function()
          require("chainsaw").removeLogs()
        end,
        desc = "Remove chainsaw-created statements",
      },
    },
  },
}
