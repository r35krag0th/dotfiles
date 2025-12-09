-- <leader>gi = open issues
-- <leader>gI = all issues
-- <leader>gp = open PRs
-- <leader>gP = all PRs
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    gh = {},
    bigfile = { enabled = true },
    dashoard = { enabled = true },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    picker = {
      enabled = true,
      -- Show hidden files by default (part 1)
      hidden = true,
      sources = {
        files = {
          -- Show hidden files by default (part 2)
          hidden = true,
        },
        gh_issue = {},
        gh_pr = {},
      },
    },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    lazygit = {},
  },
}
