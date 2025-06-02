return {
  "r35krag0th/r35.notes",
  -- dir = "~/workspace/r35.notes",
  -- dev = { true },
  enabled = true,
  lazy = false,
  dependencies = {
    "nvim-telescope/telescope.nvim", -- for picker="telescope"
    "echasnovski/mini.pick", -- for picker="mini-pick"
  },
  opts = {
    root = os.getenv("HOME") .. "/notes",
  },
}
