local M = {}

local desiredTheme = "tokyonight"
local themeRegistry = {
  nightfox = "EdenEast/nightfox.nvim",
  rosepine = "rose-pine/neovim",
  vague = "vague2k/vague.nvim",
  ayu = "Shatur/neovim-ayu",
}

---Sets the colorscheme
function M.setTheme()
  vim.cmd(string.format("colorscheme %s", desiredTheme))
end

---Returns a list of plugin specs
---@param returnAllThemes boolean Return all Themes instead of just the matching?
---@return table
function M.deps(returnAllThemes)
  local output = {}
  -- Iterate through the themeRegistry and only return the value of the key matching desiredTheme
  for key, value in pairs(themeRegistry) do
    if key == desiredTheme or (returnAllThemes ~= nil and returnAllThemes == true) then
      table.insert(output, {
        value,
        name = key,
      })
    end
  end

  return output
end

return M
