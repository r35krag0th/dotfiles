-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Setup the various LSP things
require("r35.lsp").setup()

-- Set the current theme
require("r35.themes").setTheme()
