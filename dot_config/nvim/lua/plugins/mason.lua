return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = function(opts)
      opts.automatic_enable = {
        exclude = require("r35.lsp").not_auto_enabled(),
      }
      opts.ensure_installed = require("r35.lsp").enabled()
      return opts
    end,
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
  },
}
