local extra_schemas = {
  {
    name = "Kubernetes 1.28",
    url = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.28.15-standalone-strict/all.json",
  },
  {
    name = "Kubernetes 1.29",
    url = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.13-standalone-strict/all.json",
  },
  {
    name = "Kubernetes 1.30",
    url = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.30.9-standalone-strict/all.json",
  },
}

return {
  "someone-stole-my-name/yaml-companion.nvim",
  dependencies = {
    { "neovim/nvim-lspconfig" },
    { "nvim-lua/plenary.nvim" },
    { "redhat-developer/yaml-language-server" },
    { "nvim-telescope/telescope.nvim" },
  },
  config = function()
    --- Options we are setting; mainly to support the Kubernetes schemas
    local opts = {
      builtin_matchers = {
        -- Detects Kubernetes files based on content
        kubernetes = { enabled = true },
        cloud_init = { enabled = true },
      },
      schemas = extra_schemas,
      lspconfig = {
        settings = {
          yaml = {
            schemas = extra_schemas,
          },
        },
      },
    }

    -- Load a local helper
    require("r35.kube_schemas").init()

    -- Tell YamlLS about these extra goodies
    local lc = require("yaml-companion").setup(opts)
    require("lspconfig").yamlls.setup(lc)

    -- Load the Yaml-Companion Telescope picker
    require("telescope").load_extension("yaml_schema")
  end,
}
