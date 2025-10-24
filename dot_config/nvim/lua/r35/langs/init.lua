local M = {}

M.registered_modules = {}

function M.init()
  M.registered_modules.yaml = require("r35.langs.yaml")
  M.registered_modules.markdown = require("r35.langs.markdown")
  -- load up the yaml_v2 module and create a keybinding to activate it
end

function M.setup() end

function M.yaml()
  return require("r35.langs.yaml")
end

function M.plugins()
  local output = {}
  for k, v in pairs(M.registered_modules) do
    v:init()

    table.insert(output, v:plugins())
  end

  return output
end

return M
