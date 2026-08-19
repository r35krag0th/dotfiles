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

--- Collect the chain of headings the cursor sits inside, innermost first.
---@param buf integer # buffer handle
---@return table[] # list of { node = TSNode, level = integer }, innermost -> outermost
---@return boolean # true when the cursor is parked on a heading's own line
M.enclosing_headings = function(buf)
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local node = vim.treesitter.get_node({ bufnr = buf, pos = { row, 0 } })
  local chain, on_heading_line = {}, false

  while node do
    local level = tonumber(tostring(node:type()):match("^heading(%d)$"))
    if level then
      local start_row = node:range()
      if start_row == row then
        on_heading_line = true
      end
      table.insert(chain, { node = node, level = level })
    end
    node = node:parent()
  end

  return chain, on_heading_line
end

--- Pick which heading `regenerate_summary` should rebuild.
---
--- The chain runs innermost -> outermost, so `chain[1]` is the heading the
--- cursor is nearest and `chain[#chain]` is the top-level one containing it.
--- `on_heading_line` is true only when the cursor is on a heading's own line.
---
--- Returning the outermost heading rebuilds the whole index; returning a
--- deeper one rebuilds just that category's block in place.
---
---@param chain table[] # { node = TSNode, level = integer }, innermost first
---@param on_heading_line boolean
---@return table|nil # one entry from `chain`, or nil to abort
M.summary_target = function(chain, on_heading_line)
  -- Parked on a heading: rebuild exactly that one, however deep it is.
  -- Loose in the body: the intent is "refresh this index", so go to the top.
  if on_heading_line then
    return chain[1]
  end
  return chain[#chain]
end

--- Regenerate the workspace summary under a heading, replacing what is there.
---
--- `core.summary` only ever *inserts* at the cursor, which is why running the
--- command twice duplicates the index. This clears the target first, so it is
--- idempotent.
---
--- Calls the strategy directly rather than `:Neorg generate-workspace-summary`
--- because the command's category filter lowercases its arguments and splits
--- them on spaces, while matching against raw metadata values -- so a category
--- like `2026 Journals` can never be selected through it.
M.regenerate_summary = function()
  if vim.bo.filetype ~= "norg" then
    vim.notify("Not a norg buffer", vim.log.levels.WARN)
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local chain, on_heading_line = M.enclosing_headings(buf)

  if vim.tbl_isempty(chain) then
    vim.notify("No heading under the cursor to regenerate", vim.log.levels.WARN)
    return
  end

  local target = M.summary_target(chain, on_heading_line)
  if not target then
    return
  end

  local neorg = require("neorg.core")
  local dirman = neorg.modules.get_module("core.dirman")
  if not dirman then
    vim.notify("core.dirman is not loaded", vim.log.levels.ERROR)
    return
  end

  local strategy = neorg.modules.get_module_config("core.summary").strategy
  local workspace = dirman.get_current_workspace()
  local files = dirman.get_norg_files(workspace[1]) or {}

  -- The heading's own line is row `head_row`; its body runs to `last` (exclusive).
  local head_row, _, end_row, end_col = target.node:range()
  local last = end_col == 0 and end_row or end_row + 1

  local outermost = target.level == chain[#chain].level
  -- Whole index: reissue every category one level deeper, keeping the heading.
  -- One category: reissue that block at its own level, heading line included.
  local generated = strategy(files, workspace[2], outermost and target.level + 1 or target.level, {})

  if not generated or vim.tbl_isempty(generated) then
    vim.notify("Summary came back empty -- leaving the buffer alone", vim.log.levels.WARN)
    return
  end

  local from, lines = head_row + 1, generated
  if not outermost then
    lines = M.extract_category_block(
      generated,
      vim.api.nvim_buf_get_lines(buf, head_row, head_row + 1, true)[1],
      target.level
    )
    if not lines then
      vim.notify("No generated block matches that heading -- has it been renamed?", vim.log.levels.WARN)
      return
    end
    from = head_row
  end

  vim.api.nvim_buf_set_lines(buf, from, last, true, lines)
  vim.api.nvim_win_set_cursor(0, { head_row + 1, 0 })
end

--- Pull one category's block out of a generated summary.
---
--- Matches generated output against the existing heading line, so the
--- title-casing `core.summary` applies cancels out on both sides.
---@param generated string[]
---@param heading_line string # the heading as it currently reads in the buffer
---@param level integer
---@return string[]|nil
M.extract_category_block = function(generated, heading_line, level)
  local wanted = vim.trim(heading_line)
  local boundary = "^" .. string.rep("%*", level) .. " "
  local block

  for _, line in ipairs(generated) do
    if block then
      if line:match(boundary) then
        break
      end
      table.insert(block, line)
    elseif vim.trim(line) == wanted then
      block = { line }
    end
  end

  return block
end

return M
