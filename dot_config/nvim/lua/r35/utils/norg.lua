---@diagnostic disable
-- stylua: ignore start
local neorg = require("neorg.core")
local ls = require("luasnip")
local t = ls.text_node
local utils, log = neorg.utils, neorg.log
local s = require("neorg.modules.external.templates.default_snippets")
-- stylua: ignore end
---@diagnostic enable

local M = {
  date_format = [[%Y-%m-%d]],
}

M.tf = function(v)
  if type(v) == "boolean" then
    return v and "true" or "false"
  end
  return v
end

M.print_table = function(v)
  if v == nil then
    print("nil")
    return
  end

  for key, value in pairs(v) do
    print("key[" .. key .. "] = " .. M.tf(value))
  end
end

---Gets the neorg journal configuration
---@return {template_name: string, journal_folder: string, strategy: string, use_template: boolean}? # Journal configuration
M.get_journal_config = function()
  -- NOTE: the strategy is resolved to the date format string and not the literal value set in your neorg config.
  return neorg.modules.get_module_config("core.journal")
end

---Convert date object into a string using the journal strategy format
---@param delta_date integer # Shift x number of days from `str_or_date` (-1 means yesterday, 1 means tomorrow)
---@param str_or_date string|integer # osdate object or string representing date with `YYYY-mm-dd` format
---@return string|osdate # string representing the date
M.parse_date = function(delta_date, str_or_date)
  local jc = M.get_journal_config()
  assert(jc ~= nil, "Journal configuration is nil")
  return s.parse_date(delta_date, str_or_date, jc.strategy)
end

M.journal_path_for = function(delta_date)
  local jc = M.get_journal_config()
  assert(jc ~= nil, "Journal configuration is nil")

  local output =
    string.gsub(string.format("$/%s/%s", jc.journal_folder, M.parse_date(delta_date, s.file_tree_date())), ".norg$", "")
  assert(output ~= nil, "Output is nil")
  assert(output ~= "", "Output is empty")
  return output
end

M.day_ordinal = function(dayn)
  local last_digit = dayn % 10
  if last_digit == 1 and dayn ~= 11 then
    return "st"
  elseif last_digit == 2 and dayn ~= 12 then
    return "nd"
  elseif last_digit == 3 and dayn ~= 13 then
    return "rd"
  else
    return "th"
  end
end

--- Get the current Quarter of the Year
M.current_quarter = function()
  local month = os.date("%m")
  local quarter = math.ceil(month / 3)
  return quarter
end

--- Get the previous Quarter of the Year
M.previous_quarter = function()
  local current_quarter = M.current_quarter()
  return current_quarter == 1 and 4 or current_quarter - 1
end

--- Get the next Quarter of the Year
M.next_quarter = function()
  local current_quarter = M.current_quarter()
  return current_quarter == 4 and 1 or current_quarter + 1
end

return M
