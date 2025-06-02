local curl = require("plenary").curl

local schemas_catalog = "datreeio/CRDs-catalog"
local schema_catalog_branch = "main"
local github_base_api_url = "https://api.github.com/repos"
local github_headers = {
  Accept = "application/vnd.github+json",
  ["X-GitHub-Api-Version"] = "2022-11-28",
}

local function schema_url(selection)
  return string.format("https://raw.githubusercontent.com/%s/%s/%s", schemas_catalog, schema_catalog_branch, selection)
end

local function github_tree_url()
  return string.format("%s/%s/git/trees/%s", github_base_api_url, schemas_catalog, schema_catalog_branch)
end

local M = {}

M.list_github_tree = function()
  local response = curl.get(github_tree_url(), {
    headers = github_headers,
    query = {
      recursive = 1,
    },
  })
  local body = vim.fn.json_decode(response.body)
  local trees = {}
  for _, tree in ipairs(body.tree) do
    if tree.type == "blob" and tree.path:match("%.json$") then
      table.insert(trees, tree.path)
    end
  end
  return trees
end

M.create_binding = function()
  vim.api.nvim_buf_set_keymap(0, "n", "<localleader>ys", "", {
    desc = "Search for a YAML Schema and inject the modeline",
    callback = M.perform_selection,
  })
end

M.perform_selection = function()
  -- Only run if the buffer is YAML
  if vim.bo.filetype ~= "yaml" then
    return
  end

  -- Check the first line for the modeline
  -- local lines = vim.api.nvim_buf_get_lines(0, 0, 1, false)

  local all_crds = M.list_github_tree()
  vim.ui.select(all_crds, { prompt = "Select schema: " }, function(selection)
    if not selection then
      return
    end
    local schema_modeline = "# yaml-language-server: $schema=" .. schema_url(selection)
    vim.api.nvim_buf_set_lines(0, 0, 0, false, { schema_modeline })
    vim.notify("Added schema modeline: " .. schema_modeline)
  end)
end

M.init = function()
  vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { "yaml" },
    callback = function(ev)
      M.create_binding()
    end,
  })

  -- vim.api.nvim_set_keymap("n", "<localleader>ys", "", {
  --   callback = function() end,
  --   desc = "Search for a YAML Schema and inject the modeline",
  -- })
end

return M
