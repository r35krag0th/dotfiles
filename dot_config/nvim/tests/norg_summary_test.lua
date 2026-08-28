-- Regression tests for the workspace-summary helpers in `r35.utils.norg`.
--
--   nvim --headless -c 'luafile ~/.config/nvim/tests/norg_summary_test.lua'
--
-- Exits non-zero if anything fails. Operates on the real workspace index but
-- only ever in memory -- the buffer is never written.
--
-- The behaviour under test: `core.summary` only ever *inserts* at the cursor,
-- so running `:Neorg generate-workspace-summary` twice duplicates the index.
-- `regenerate_summary` clears the target first, which must make it idempotent.

vim.o.swapfile = false -- workspace files may be open in another nvim

local ok, m = pcall(require, "r35.utils.norg")
if not ok then
  print("FAIL require r35.utils.norg: " .. tostring(m))
  vim.cmd("cq")
end

local pass, fail = 0, 0
local function check(name, cond, extra)
  if cond then
    pass = pass + 1
    print("  ok   " .. name)
  else
    fail = fail + 1
    print("  FAIL " .. name .. (extra and ("  -> " .. tostring(extra)) or ""))
  end
end

--------------------------------------------------------------------- pure ---
print("== extract_category_block ==")
local generated = {
  "** 1password",
  "  - {:$/wisdom/a:}[A] - alpha",
  "** Agents",
  "  - {:$/wisdom/b:}[B] - beta",
  "  - {:$/wisdom/c:}[C] - gamma",
  "*** Nested",
  "   - {:$/wisdom/d:}[D] - delta",
  "** Zfs",
  "  - {:$/wisdom/e:}[E] - epsilon",
}
local blk = m.extract_category_block(generated, "** Agents", 2)
check("finds the block", blk ~= nil)
check("keeps its heading", blk and blk[1] == "** Agents", blk and blk[1])
check("stops at the next same-level heading", blk and #blk == 5, blk and #blk)
check("keeps the nested subcategory heading", blk and blk[4] == "*** Nested", blk and blk[4])
check("keeps the subcategory body", blk and blk[5] == "   - {:$/wisdom/d:}[D] - delta", blk and blk[5])
check("first block works", (m.extract_category_block(generated, "** 1password", 2) or {})[1] == "** 1password")
check("last block runs to the end", #(m.extract_category_block(generated, "** Zfs", 2) or {}) == 2)
check("unknown heading -> nil", m.extract_category_block(generated, "** Nope", 2) == nil)
check(
  "tolerates surrounding whitespace",
  (m.extract_category_block(generated, "  ** Agents  ", 2) or {})[1] == "** Agents"
)

print("== summary_target policy ==")
local function entry(level)
  return { level = level }
end
local chain3 = { entry(3), entry(2), entry(1) }
check("on a heading -> that heading", m.summary_target(chain3, true).level == 3)
check("loose in body -> outermost", m.summary_target(chain3, false).level == 1)
check("single-heading chain, on line", m.summary_target({ entry(1) }, true).level == 1)
check("single-heading chain, off line", m.summary_target({ entry(1) }, false).level == 1)

------------------------------------------------------------- real buffer ---
local dirman = require("neorg.core").modules.get_module("core.dirman")
local workspace = dirman.get_current_workspace()
local ws_root = tostring(workspace[2])
local index = ws_root .. "/index.norg"

vim.cmd.edit(index)
vim.bo.filetype = "norg"
vim.treesitter.get_parser(0, "norg"):parse()

local function buftext()
  return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end

local function duplicate_headings()
  local seen, dupes = {}, {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line:match("^%*%* ") then
      if seen[line] then
        table.insert(dupes, line)
      end
      seen[line] = true
    end
  end
  return dupes
end

local head_row
for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 40, false)) do
  if line:match("^%* ") then
    head_row = i
    break
  end
end

print("== enclosing_headings ==")
check("found the level-1 heading in " .. index, head_row ~= nil, head_row)

vim.api.nvim_win_set_cursor(0, { head_row, 0 })
local chain, on_line = m.enclosing_headings(0)
check("chain non-empty on the heading line", #chain > 0, #chain)
check("on_heading_line true there", on_line == true)
check("outermost is level 1", chain[#chain].level == 1, chain[#chain].level)

vim.api.nvim_win_set_cursor(0, { head_row + 2, 0 })
local chain2, on_line2 = m.enclosing_headings(0)
check("chain non-empty inside the body", #chain2 > 0, #chain2)
check("on_heading_line false when loose in body", on_line2 == false)
check("outermost still level 1 from the body", chain2[#chain2].level == 1, chain2[#chain2].level)

print("== regenerate_summary: whole index ==")
vim.api.nvim_win_set_cursor(0, { head_row, 0 })
m.regenerate_summary()
local once = buftext()

-- Deliberately NOT compared against the committed file: the workspace grows,
-- so that assertion would fail every time a note is added.
local links, dangling = 0, {}
for path in once:gmatch("{:%$/([^:]+):}") do
  links = links + 1
  if vim.fn.filereadable(ws_root .. "/" .. path .. ".norg") == 0 then
    table.insert(dangling, path)
  end
end
check("generated a plausible number of links", links > 100, links)
check("every link resolves to a real file", #dangling == 0, vim.inspect(vim.list_slice(dangling, 1, 5)))
check("no duplicated category heading", #duplicate_headings() == 0, vim.inspect(duplicate_headings()))
check("cursor parked back on the heading", vim.api.nvim_win_get_cursor(0)[1] == head_row)

vim.api.nvim_win_set_cursor(0, { head_row, 0 })
m.regenerate_summary()
check(
  "IDEMPOTENT: second run is byte-identical",
  buftext() == once,
  ("run1=%d chars, run2=%d chars"):format(#once, #buftext())
)
check("still no duplicated heading after two runs", #duplicate_headings() == 0)

print("== regenerate_summary: single category, in place ==")
local cat_row, cat_text
for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
  if line:match("^%*%* ") then
    cat_row, cat_text = i, line
    break
  end
end
check("found a category heading", cat_row ~= nil, cat_text)

local before = buftext()
vim.api.nvim_win_set_cursor(0, { cat_row, 0 })
m.regenerate_summary()
check(
  "category regen leaves the buffer unchanged",
  buftext() == before,
  ("before=%d chars, after=%d chars"):format(#before, #buftext())
)
check("heading survives in place", vim.api.nvim_buf_get_lines(0, cat_row - 1, cat_row, true)[1] == cat_text)
check("no duplicated heading after category regen", #duplicate_headings() == 0)

-- Regression: a second category regen runs against a tree left stale by the
-- first. Before `enclosing_headings` re-parsed, the sub-heading range spanned
-- to EOF and this collapsed the document to a few hundred characters.
vim.api.nvim_win_set_cursor(0, { cat_row, 0 })
m.regenerate_summary()
check(
  "back-to-back category regen is stable",
  buftext() == before,
  ("expected=%d chars, got=%d chars"):format(#before, #buftext())
)
check("document was not truncated", #buftext() > 100000, #buftext())

vim.bo.modified = false -- never write the index
print(string.format("\n%d passed, %d failed", pass, fail))
vim.cmd(fail > 0 and "cq" or "qa!")
