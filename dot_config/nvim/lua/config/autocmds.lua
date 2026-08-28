-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "iwes" then
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = args.buf,
        callback = function()
          vim.lsp.buf.format({ async = false, bufnr = args.buf })
        end,
      })
    end
  end,
})

-- Rebuild this config's own `doc/tags` whenever one of its help files is saved.
--
-- `:help r35-glyphs` resolves through doc/tags, which `:helptags` generates and
-- which is deliberately not versioned (see .chezmoiignore). lazy.nvim rebuilds
-- tags for every plugin it manages, but this config directory is not a managed
-- plugin, so nothing rebuilds them here -- a doc edit would silently leave the
-- tags stale and any new section unreachable until someone noticed E149.
--
-- The chezmoi `run_after_` script covers the other direction: a fresh apply
-- lands doc/*.txt with no tags file at all. Neither covers both cases.
local helpdir = vim.fs.joinpath(vim.fn.stdpath("config"), "doc")
vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("r35_helptags", { clear = true }),
  pattern = vim.fs.joinpath(helpdir, "*.txt"),
  desc = "Rebuild helptags for the config's own doc/ directory",
  callback = function()
    local ok, err = pcall(vim.cmd.helptags, helpdir)
    if not ok then
      vim.notify("r35: helptags failed -- " .. tostring(err), vim.log.levels.WARN)
    end
  end,
})
