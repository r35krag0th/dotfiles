-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.__neorg_hop_extras_debug = true

local opt = vim.opt

opt.wrap = true

-- If I'm using NeoVide, I want to use a different default font
if vim.g.neovide then
  vim.o.guifont = "PragmataPro Mono Liga:h16"
  vim.g.neovide_input_macos_option_key_is_meta = "only_left"
  vim.g.neovide_cursor_animation_length = 0
end
