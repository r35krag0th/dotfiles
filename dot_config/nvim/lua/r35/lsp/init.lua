local M = {}

local enabled_lsps = {}

function M.setup()
  vim.lsp.enable({
    "bashls", -- BASH Shell LSP
    "cssls", -- Cascading Stylesheets LSP; `brew install vscode-langservers-extracted`
    "cue", -- Cue LSP
    "dagger", -- Dagger LSP
    "docker_compose_language_service", -- Docker Compose LSP
    "dockerls", -- Docker LSP
    "elixirls", -- Elixir LSP
    "fish_lsp", -- Fish Shell LSP; `brew install fish-lsp`
    "gh_actions_ls", -- GitHub Actions LSP
    "golangci_lint_ls", -- Golang CI Linter LSP
    "gopls", -- Go Please (LSP)
    "helmls", -- Helm Chart LSP; `brew install helm-ls`
    "html", -- HTML; `brew install vscode-langservers-extracted`
    "jsonls", -- JSON LSP
    "jsonnet_ls", -- JSONNET LSP; Available in Mason
    "kulala_ls", -- Kualua LSP (HTTP Testing); `npm install -g @mistweaverco/kulala-ls`
    "lua_ls", -- Lua LSP
    "marksman", -- Marksman LSP (Markdown)
    "postgres_lsp", -- Postgres LSP; Available in Mason (postgrestools)
    "pylsp", -- Python LSP
    "pyright", -- Pyright-based Python LSP
    "ts_ls", -- Typescript + Javascript (see note below)
    "tailwindcss", -- Tailwind CSS LSP
    "terraformls", -- Terraform LSP from Hashicorp.  There's also a "terraform-lsp" that is maintained by another person...
    "yamlls", -- YAML LSP
  })

  vim.lsp.config("helmls", {
    cmd = {
      vim.fn.expand("~/.local/share/nvim/mason/packages/helm-ls/helm_ls_darwin_arm64"),
      "serve",
    },
  })
end

return M
