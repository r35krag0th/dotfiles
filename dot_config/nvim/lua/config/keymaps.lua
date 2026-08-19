-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.api.nvim_create_autocmd("FileType", {
  pattern = "norg",
  callback = function()
    -- Create the ToC
    vim.keymap.set("n", "go", "<cmd>Neorg toc<CR>", { buffer = true })
  end,
})
