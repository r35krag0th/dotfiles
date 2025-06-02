return {
  "echasnovski/mini.nvim",
  version = "*",
  init = function()
    local gen_loader = require("mini.snippets").gen_loader
    require("mini.snippets").setup({
      snippets = {
        gen_loader.from_file("~/.config/nvim/snippets/global.json"),
        gen_loader.from_lang(),
      },
      mappings = {
        -- Expand snippet at cursor position. Created globally in Insert mode.
        expand = "<C-\\>",

        -- Interact with default `expand.insert` session.
        -- Created for the duration of active session(s)
        jump_next = "<C-l>",
        jump_prev = "<C-h>",
        stop = "<C-c>",
      },
    })
  end,
}
