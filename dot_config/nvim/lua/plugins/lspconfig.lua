return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    opts = {},
    config = function(_, opts)
      local lspconfig = require("lspconfig")

      -- Enable some LSPs
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
        "tailwindcss", -- Tailwind CSS LSP
        "yamlls", -- YAML LSP
      })

      -- Use the Mason-installed HelmLS
      vim.lsp.config("helmls", {
        cmd = {
          vim.fn.expand("~/.local/share/nvim/mason/packages/helm-ls/helm_ls_darwin_arm64"),
          "serve",
        },
      })

      -- https://github.com/python-lsp/python-lsp-server/blob/develop/CONFIGURATION.md
      vim.lsp.config("pylsp", {
        settings = {
          pylsp = {
            plugins = {
              autopep8 = { enabled = true },
              flake8 = { enabled = false },
              jedi_completion = { enabled = true },
              jedi_definition = { enabled = true },
              jedi_hover = { enabled = true },
              jedi_references = { enabled = true },
              jedi_signature_help = { enabled = true },
              jedi_symbols = { enabled = true },
              mccabe = { enabled = true },
              pycodestyle = { enabled = true },
              pydocstyle = { enabled = false }, -- replaced by Ruff
              pylint = { enabled = false }, -- covered by Ruff
              ruff = {
                enabled = true,
                linelength = 180,
                fomatEnabled = true,
              },
              rope_autoimport = {
                enabled = true,
                code_actions = { enabled = true },
                completions = { enabled = true },
              },
              yapf = { enabled = true },
              pyls_isort = {
                enabled = true,
              },
            },
          },
        },
      })

      for server, config in pairs(opts.servers) do
        config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
        vim.lsp.config(server, config)
      end

      return opts
    end,
  },
}
