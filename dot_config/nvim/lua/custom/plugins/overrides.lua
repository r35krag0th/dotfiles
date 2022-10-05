local M = {}

M.treesitter = require('custom.plugins.settings_treesitter')
M.mason = {
  ensure_installed = {
    "css-lsp",
    "debugpy",
    "delve",
    "goimports",
    "golangci-lint",
    "gomodifytags",
    "gopls",
    "prettier",
    "pydocstyle",
    "pyright",
    "pyproject-flake8",
    "gitlint",
    "flake8",
    "gotests",
    "html-lsp",
    "lua-language-server",
    "stylua",
    "svelte-language-server",
    "typescript-language-server",
  }
}
M.nvimtree = {
  git = {
    enable = true,
  },
  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
      },
    },
  },
}

return M
