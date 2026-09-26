local M = {}

M.setup = function()
  -- require('mason').install({})
end

M.create_binding = function()
  vim.api.nvim_buf_set_keymap(0, "n", "<localleader>yss", "", {
    desc = "SchemaCompanion :D",
    callback = function()
      require("schema-companion").select_schema()
    end,
  })
  vim.api.nvim_buf_set_keymap(0, "n", "<localleader>ysfm", "", {
    desc = "From Matching",
    callback = function()
      require("schema-companion").select_from_matching_schema()
    end,
  })
  vim.api.nvim_buf_set_keymap(0, "n", "<localleader>ysrm", "", {
    desc = "From Matching",
    callback = function()
      require("schema-companion").match()
    end,
  })
end

M.init = function()
  vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { "yaml", "helm" },
    callback = function(ev)
      M.create_binding()
    end,
  })
end

M.plugins = function()
  return {
    {
      "cenk1cenk2/schema-companion.nvim",
      dependencies = {
        { "neovim/nvim-lspconfig" },
        { "nvim-lua/plenary.nvim" },
        { "redhat-developer/yaml-language-server" },
        { "nvim-telescope/telescope.nvim" },
        { "nvim-lualine/lualine.nvim" },
      },
      config = function()
        require("schema-companion").setup({})
      end,
    },
    {
      "r35krag0th/kube-schemas.nvim",
      ft = { "yaml", "helm" },
      dir = "~/workspace/kube-schemas.nvim/",
      dev = true,
      opts = {
        catalog_url = "https://schemas.r35.io/api/json/catalog.json",
      },
      keys = {
        { "<localleader>yks", "<cmd>KubeSchemas search<cr>", desc = "Search for k8s Schema" },
        { "<localleader>yka", "<cmd>KubeSchemas auto<cr>", desc = "Auto-detect Kubernetes schema" },
      },
    },
  }
end

return M
