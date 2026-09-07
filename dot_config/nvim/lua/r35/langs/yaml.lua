local M = {}

M.setup = function() end

M.init = function() end

M.plugins = function()
  return {
    {
      "r35krag0th/kube-schemas.nvim",
      ft = { "yaml", "helm" },
      dir = "~/workspace/kube-schemas.nvim/",
      dev = true,
      dependencies = {
        { "redhat-developer/yaml-language-server" },
      },
      opts = {
        catalog_url = "https://schemas.r35.dev/api/json/catalog.json",
      },
      keys = {
        { "<localleader>yks", "<cmd>KubeSchemas search<cr>", desc = "Search for k8s Schema" },
        { "<localleader>yka", "<cmd>KubeSchemas auto<cr>", desc = "Auto-detect Kubernetes schema" },
      },
    },
  }
end

return M
