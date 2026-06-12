local M = {}

function M.init()
  vim.lsp.config["cue"] = {
    cmd = { "cue", "lsp" },
    filetypes = { "cue" },
    root_markers = { "cue.mod", ".git" },
  }
  vim.lsp.enable({ "cue" })
end

function M.plugins()
  return {
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      event = { "BufReadPost", "BufNewFile" },
      --- @type TSConfig
      opts = {
        ensure_installed = {
          "cue",
        },
      },
      ------@param opts TSConfig
      ---config = function(_, opts)
      ---  require("nvim-treesitter.configs").setup(opts)
      ---end,
    },
  }
end

return M
