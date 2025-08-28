return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    opts = {},
    config = function(_, opts)
      local lspconfig = require("lspconfig")

      -- Use the Mason-installed HelmLS
      vim.lsp.config("helmls", {
        cmd = {
          vim.fn.expand("~/.local/share/nvim/mason/packages/helm-ls/helm_ls_darwin_arm64"),
          "serve",
        },
      })
      -- Mappings.
      -- See `:help vim.diagnostic.*` for documentation on any of the below functions
      local opts = { noremap = true, silent = true }
      vim.api.nvim_set_keymap(
        "n",
        "\\dd",
        "<cmd>lua vim.diagnostic.open_float()<CR>",
        { noremap = true, silent = true, desc = "X: Show Diagnostic" }
      )
      vim.api.nvim_set_keymap("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", {
        noremap = true,
        silent = true,
        desc = "X: Go to Previous Diagnostic",
      })
      vim.api.nvim_set_keymap(
        "n",
        "]d",
        "<cmd>lua vim.diagnostic.goto_next()<CR>",
        { noremap = true, silent = true, desc = "X: Go to Next Diagnostic" }
      )
      vim.api.nvim_set_keymap(
        "n",
        "\\dq",
        "<cmd>lua vim.diagnostic.setloclist()<CR>",
        { noremap = true, silent = true, desc = "X: Set Diagnostic Location List" }
      )

      -- Use an on_attach function to only map the following keys
      -- after the language server attaches to the current buffer
      local on_attach = function(client, bufnr)
        -- Enable completion triggered by <c-x><c-o>
        -- vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

        -- Mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "gD",
          "<cmd>lua vim.lsp.buf.declaration()<CR>",
          vim.tbl_extend("force", opts, { desc = "X: Go to Declaration" })
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "gd",
          "<cmd>lua vim.lsp.buf.definition()<CR>",
          vim.tbl_extend("force", opts, { desc = "X: Go to Definition" })
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "K",
          "<cmd>lua vim.lsp.buf.hover()<CR>",
          vim.tbl_extend("force", opts, { desc = "X: Hover" })
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "gi",
          "<cmd>lua vim.lsp.buf.implementation()<CR>",
          vim.tbl_extend("force", opts, { desc = "X: Go to Implementation" })
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "<C-k>",
          "<cmd>lua vim.lsp.buf.signature_help()<CR>",
          vim.tbl_extend("force", opts, { desc = "X: Signature Help" })
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "<space>wa",
          "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>",
          vim.tbl_extend("force", opts, { desc = "X: Add Workspace Folder" })
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "<space>wr",
          "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>",
          vim.tbl_extend("force", opts, { desc = "X: Remove Workspace Folder" })
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "<space>wl",
          "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>",
          vim.tbl_extend("force", opts, { desc = "X: List Workspace Folders" })
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "<space>D",
          "<cmd>lua vim.lsp.buf.type_definition()<CR>",
          vim.tbl_extend("force", opts, { desc = "X: Type Definition" })
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "<space>rn",
          "<cmd>lua vim.lsp.buf.rename()<CR>",
          vim.tbl_extend("force", opts, { desc = "X: Rename" })
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "<space>ca",
          "<cmd>lua vim.lsp.buf.code_action()<CR>",
          vim.tbl_extend("force", opts, { desc = "X: Code Actions" })
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "gr",
          "<cmd>lua vim.lsp.buf.references()<CR>",
          vim.tbl_extend("force", opts, { desc = "X: References" })
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "<space>f",
          "<cmd>lua vim.lsp.buf.formatting()<CR>",
          vim.tbl_extend("force", opts, { desc = "X: Format" })
        )
      end

      -- Use a loop to conveniently call 'setup' on multiple servers and
      -- map buffer local keybindings when the language server attaches
      local servers = { "pyright", "rust_analyzer", "tsserver" }
      for _, lsp in pairs(servers) do
        require("lspconfig")[lsp].setup({
          on_attach = on_attach,
          flags = {
            -- This will be the default in neovim 0.7+
            debounce_text_changes = 150,
          },
        })
      end
      -- vim.lsp.config("pyright", {
      --   settings = {
      --     pyright = {
      --       autoImportCompletion = true,
      --       autoSearchPaths = true,
      --       disableOrganizeImports = false,
      --     },
      --     python = {
      --       analysis = {
      --         autoSearchPaths = true,
      --         diagnosticMode = "workspace", -- or "openFilesOnly"
      --         useLibraryCodeForTypes = true,
      --         typeCheckingMode = "standard", -- options are: "off", "basic", "strict", "standard"
      --       },
      --     },
      --   },
      -- })
      --
      vim.lsp.config("ruff", {
        filetypes = { "python" },
        root_dir = lspconfig.util.root_pattern(".git", "pyproject.toml"),
        settings = {
          ruff = {
            args = { "--line-length", "180" },
          },
        },
      })

      -- vim.api.nvim_create_autocmd("LspAttach", {
      --   group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
      --   callback = function(args)
      --     local client = vim.lsp.get_client_by_id(args.data.client_id)
      --     if client == nil then
      --       return
      --     end
      --     if client.name == "ruff" then
      --       -- Disable hover in favor of Pyright
      --       client.server_capabilities.hoverProvider = false
      --     end
      --   end,
      --   desc = "LSP: Disable hover capability from Ruff",
      -- })

      -- for server, config in pairs(opts.servers) do
      --   config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
      --   vim.lsp.config(server, config)
      -- end

      lspconfig.basepyright.setup({})

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
        -- "pylsp", -- Python LSP
        -- "pyright", -- Pyright-based Python LSP
        "basedpyright",
        "ruff",
        "tailwindcss", -- Tailwind CSS LSP
        "yamlls", -- YAML LSP
      })

      return opts
    end,
  },
}
