local M = {}

local desiredTheme = "candy"

-- NOTE: candy is deliberately absent from themeRegistry. The registry feeds
-- deps() -> lazy.nvim plugin specs, and candy is local (lua/r35/themes/candy),
-- not a repo to clone. setTheme() runs `colorscheme <name>` for whatever it is
-- given, so a local theme works without being registered -- which is also why
-- tokyonight worked here despite never being listed.
local themeRegistry = {
  nightfox = "EdenEast/nightfox.nvim",
  rosepine = "rose-pine/neovim",
  vague = "vague2k/vague.nvim",
  ayu = "Shatur/neovim-ayu",
  koda = "oskarnurm/koda.nvim",
}

---Sets the colorscheme
function M.setTheme(themeOverride)
  themeOverride = themeOverride or desiredTheme
  -- vim.notify("Setting theme to " .. desiredTheme, vim.log.levels.TRACE)
  vim.cmd(string.format("colorscheme %s", themeOverride))
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
