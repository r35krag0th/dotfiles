local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local present, null_ls = pcall(require, "null-ls")

if not present then
  return
end

local with_diagnostic_code = function(builtin)
  return builtin.with {
    diagnostics_format = "#{m} [#{c}]",
  }
end

local with_root_file = function(builtin, file)
  return builtin.with {
    condition = function(utils)
      return utils.root_has_file(file)
    end,
  }
end

local b = null_ls.builtins

local sources = {
  -- webdev
  b.formatting.prettier.with {
    filetypes = {
      "html",
      "markdown",
      "css",
    },
  },

  -- lua
  b.formatting.stylua,

  -- shell
  b.formatting.shfmt,
  b.diagnostics.shellcheck.with {
    diagnostics_format = "#{m} [#{c}]",
  },

  -- cpp
  b.formatting.rustfmt,

  -- code actions
  b.code_actions.gitsigns,
  b.code_actions.gitrebase,

  -- diagnostics
  with_diagnostic_code(b.diagnostics.spellcheck),

  -- hover
  b.hover.dictionary,
}

null_ls.setup {
  debug = true,
  sources = sources,
  on_attach = function(client, bufnr)
    if client.supports_method "textDocument/formatting" then
      vim.api.nvim_clear_autocmds {
        group = augroup,
        buffer = bufnr,
      }
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format()
        end,
      })
    end
  end,
}
