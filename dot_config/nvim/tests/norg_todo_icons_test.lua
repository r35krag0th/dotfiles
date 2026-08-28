-- Regression tests for `r35.utils.norg_icons`.
--
--   nvim --headless -c 'luafile ~/.config/nvim/tests/norg_todo_icons_test.lua'
--
-- Exits non-zero if anything fails. Parses an in-memory scratch buffer; no file
-- is read or written, and the buffer is never shown in a window (neorg renders
-- per-window, so nothing else draws into the namespace while we count).
--
-- The behaviour under test: neorg's stock `on_left` renderer overlays
-- `(" "):rep(len - 1) .. icon` at the todo status character, which assumes a
-- one-cell icon. At two cells the overlay runs one past the node and eats the
-- closing `)`, leaving a dangling `(`. These icons must instead cover the whole
-- `(x)`, via `conceal` rather than a wider overlay -- conceal is the only
-- mechanism that actually reclaims the width, and a concealed character does not
-- inherit the highlight underneath, so the state group must be passed through.

local ok, icons = pcall(require, "r35.utils.norg_icons")
if not ok then
  print("FAIL require r35.utils.norg_icons: " .. tostring(icons))
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

-- Same namespace neorg uses; creating it is idempotent when neorg already has.
local ns = vim.api.nvim_create_namespace("neorg-conceals")

local SRC = { "* T", "", "  - ( ) undone", "  - (x) done", "  - (!) urgent" }
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, SRC)
vim.bo[buf].filetype = "norg"

local parsed, parser = pcall(vim.treesitter.get_parser, buf, "norg")
if not parsed then
  print("FAIL norg parser unavailable: " .. tostring(parser))
  vim.cmd("cq")
end

---Collect the todo status nodes, keyed by state.
local nodes = {}
local function walk(node)
  local state = node:type():match("^todo_item_(.+)$")
  if state then
    nodes[state] = node
  end
  for child in node:iter_children() do
    walk(child)
  end
end
walk(parser:parse()[1]:root())

check("found todo nodes for all three states", nodes.undone and nodes.done and nodes.urgent ~= nil)

local TWO_CELL = vim.fn.nr2char(0xF00C) -- fa-check, widened by r35.glyphs
local function marks_on(row)
  return vim.api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, -1 }, { details = true })
end

-- The core claim: one mark spanning the whole `(x)`, concealing it to the icon.
for state, row in pairs({ undone = 2, done = 3, urgent = 4 }) do
  local node = nodes[state]
  local config = {
    icon = TWO_CELL,
    highlight = "@neorg.todo_items." .. state,
    render = icons.render,
    clear = icons.clear,
  }
  icons.clear(config, buf, node)
  icons.render(config, buf, node)

  local placed = marks_on(row)
  local m = placed[1]
  local d = m and m[4] or {}
  local line = SRC[row + 1]

  check(("%s: exactly one mark"):format(state), #placed == 1, #placed)
  check(("%s: anchored at the opening paren"):format(state), m and line:sub(m[3] + 1, m[3] + 1) == "(", m and m[3])
  check(("%s: conceals with the icon"):format(state), d.conceal == TWO_CELL, vim.inspect(d.conceal))
  check(
    ("%s: spans the whole bracket group"):format(state),
    d.end_col == m[3] + 3 and line:sub(m[3] + 1, d.end_col):match("^%(.%)$") ~= nil,
    m and line:sub(m[3] + 1, d.end_col or 0)
  )
  -- Without an explicit group a concealed char falls back to Normal, so every
  -- state would render the same colour.
  check(("%s: carries its state highlight"):format(state), d.hl_group == "@neorg.todo_items." .. state, d.hl_group)
end

-- Rendering twice without a clear must not stack, because neorg's own pruning
-- only covers the node range and would miss a mark anchored to its left.
local cfg = { icon = TWO_CELL, render = icons.render, clear = icons.clear }
icons.render(cfg, buf, nodes.done)
check("second render without clear stacks (why clear() exists)", #marks_on(3) == 2, #marks_on(3))
icons.clear(cfg, buf, nodes.done)
check("clear() prunes the whole bracket group", #marks_on(3) == 0, #marks_on(3))
icons.render(cfg, buf, nodes.done)
check("clear + render leaves exactly one", #marks_on(3) == 1, #marks_on(3))

-- Multi-character icons cannot be a conceal replacement (:h :syn-cchar), so they
-- fall back to a padded overlay that at least preserves the width.
icons.clear(cfg, buf, nodes.done)
icons.render({ icon = "ab" }, buf, nodes.done)
local fb = marks_on(3)[1]
check("multi-char icon falls back to overlay", fb and fb[4].virt_text ~= nil and fb[4].conceal == nil)
check(
  "overlay fallback is padded to 3 cells",
  fb and vim.fn.strdisplaywidth(fb[4].virt_text[1][1]) == 3,
  fb and vim.fn.strdisplaywidth(fb[4].virt_text[1][1])
)

-- Too wide to fit and not concealable: leave the literal text rather than eat
-- into it. Overlaying anyway is precisely the bug this module exists to fix.
icons.clear(cfg, buf, nodes.done)
icons.render({ icon = TWO_CELL .. TWO_CELL }, buf, nodes.done)
check("oversized multi-char icon places no mark", #marks_on(3) == 0, #marks_on(3))

print(string.format("\n%d passed, %d failed", pass, fail))
vim.cmd(fail > 0 and "cq" or "qa!")
