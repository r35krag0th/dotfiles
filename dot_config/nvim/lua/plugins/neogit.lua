return {
  "NeogitOrg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim", -- required
    "sindrets/diffview.nvim", -- optional - Diff integration

    -- Only one of these is needed.
    "echasnovski/mini.pick", -- optional
  },
  opts = {
    graph_style = "unicode",
    integrations = {
      mini_pick = true,
    },
  },
  -- Kind can be one of -- https://github.com/NeogitOrg/neogit?tab=readme-ov-file#usage
  -- ===================
  --  - tab (default)
  --  - replace
  --  - split
  --  - split_above
  --  - split_above_all
  --  - split_below
  --  - split_below_all
  --  - vsplit
  --  - floating
  --  - auto (vsplit if >80 cols; split otherwise)
  --
  -- Popups can be one of -- https://github.com/NeogitOrg/neogit?tab=readme-ov-file#popups
  --  - bisect
  --  - branch_and_bisect
  --  - cherry_pick
  --  - commit
  --  - diff
  --  - fetch
  --  - ignore
  --  - log
  --  - merge
  --  - pull
  --  - push
  --  - rebase
  --  - remote_config
  --  - reset
  --  - revert
  --  - stash
  --  - tag
  --  - worktree
  keys = {
    {
      "<leader>gg",
      function()
        require("neogit").open()
      end,
      desc = "Open Neogit UI",
    },
    {
      "<leader>gc",
      function()
        require("neogit").open({ "commit" })
      end,
      desc = "Git Commit (Neogit)",
    },
    {
      "<leader>guf",
      function()
        require("neogit").open({ "fetch", kind = "split_below_all" })
      end,
      desc = "Git Fetch (Neogit)",
    },
    {
      "<leader>gup",
      function()
        require("neogit").open({ "pull", kind = "split_below_all" })
      end,
      desc = "Git Pull (Neogit)",
    },
    {
      "<leader>guP",
      function()
        require("neogit").open({ "push", kind = "split_below_all" })
      end,
      desc = "Git Push 🚀 (Neogit)",
    },
    {
      "<leader>gR",
      function()
        require("neogit").open({ "rebase", kind = "floating" })
      end,
      desc = "Git Rebase (Neogit)",
    },
    {
      "<leader>gxs",
      function()
        require("neogit").open({ "stash", kind = "split_below_all" })
      end,
      desc = "Git Stash 📥 (Neogit)",
    },
    {
      "<leader>gxi",
      function()
        require("neogit").open({ "ignore", kind = "split_below_all" })
      end,
      desc = "Git Ignore 🤫 (Neogit)",
    },
    {
      "<leader>gxr",
      function()
        require("neogit").open({ "reset", kind = "split_below_all" })
      end,
      desc = "Git Reset ⚠️(Neogit)",
    },
    {
      "<leader>gxv",
      function()
        require("neogit").open({ "revert", kind = "split_below_all" })
      end,
      desc = "Git Revert ⚠️(Neogit)",
    },
    {
      "<leader>gl",
      function()
        require("neogit").open({ "log", kind = "floating" })
      end,
      desc = "Git Log 📃 (Neogit)",
    },
    {
      "<leader>gt",
      function()
        require("neogit").open({ "tag", kind = "split_below_all" })
      end,
      desc = "Git Tag (Neogit)",
    },
  },
}
