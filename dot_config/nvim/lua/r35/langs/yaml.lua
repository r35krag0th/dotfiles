local M = {}

M.setup = function()
  -- require('mason').install({})
end

-- Required: r35.langs.init calls v:init() on every registered module.
-- kube-schemas.nvim declares its own keys, so there is nothing to bind here.
M.init = function() end

M.plugins = function()
  return {
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
