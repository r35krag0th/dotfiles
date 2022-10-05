local overrides = require "custom.plugins.overrides"

return {
  -- fancy dashboardy thing when opening vim
  ["goolord/alpha-nvim"] = {
    requires = { "kyazdani42/nvim-web-devicons" },
    config = function()
      require("alpha").setup(require("alpha.themes.dashboard").config)
    end,
  },

  -- LSP configuration
  ["neovim/nvim-lspconfig"] = {
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.plugins.lspconfig"
    end,
  },

  -- The core of the smarts for all things code
  ["nvim-treesitter/nvim-treesitter"] = {
    override_options = overrides.treesitter,
  },

  -- ?!
  ["williamboman/mason.nvim"] = {
    override_options = overrides.mason,
  },

  -- File browser inside vim toggled with <C-N>
  ["kyazdani42/nvim-tree.lua"] = {
    override_options = overrides.nvimtree,
  },

  -- code formatting, linting etc
  ["jose-elias-alvarez/null-ls.nvim"] = {
    after = "nvim-lspconfig",
    config = function()
      require "custom.plugins.null-ls"
    end,
  },
}
