return {
  {
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      default_merge_method = "rebase",
      use_emojis = true,
      suppress_missing_scope = {
        projects_v2 = true,
      },
      users = "assignable",
    },
    keys = {
      { "<localleader>po", "<cmd>Octo pr<CR>", desc = "Open PR for current branch" },
      { "<localleader>pl", "<cmd>Octo pr list<CR>", desc = "List PRs for this repo" },
      { "<localleader>pc", "<cmd>Octo pr checks<CR>", desc = "Show PR checks" },
      { "<localleader>pC", "<cmd>Octo pr commits<CR>", desc = "Show PR commits" },
    },
  },
}
