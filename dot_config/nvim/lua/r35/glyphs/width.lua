---Applying, measuring, and fitting glyph widths.
---
---Ranges are derived from `blocks.lua` rather than declared here, so the
---declaration has exactly one home.

local blocks = require("r35.glyphs.blocks")

local M = {}

---@type integer[][] { first, last, width }
---Back-compat shape: `tests/glyphs_sign_test.lua` indexes these positionally,
---and `r35.glyphs.ranges` has always been an array of arrays.
M.ranges = {}
for _, b in ipairs(blocks) do
  M.ranges[#M.ranges + 1] = { b.first, b.last, b.cells }
end

---Ranges installed by the last successful `setup()`; nil if it has not run.
---
---`:checkhealth` needs to distinguish "not applied yet" from "applied", and
---there is no way to read the table back out of `setcellwidths`.
---@type integer|nil
M.applied = nil

---Codepoints that must stay single width.
---
---'fillchars' and 'listchars' may only contain single-width characters, and
---setcellwidths() rejects the ENTIRE call with E835 if even one of their glyphs
---falls inside a two-cell range. LazyVim puts Nerd Font chevrons in 'fillchars'
---(foldopen, foldclose), which lands squarely inside the Font Awesome block.
---
---Reading them at runtime rather than hardcoding the exceptions means changing
---'fillchars' later cannot silently break this.
---@return table<integer, boolean>
local function reserved()
  local set = {}
  for _, name in ipairs({ "fillchars", "listchars" }) do
    for item in vim.gsplit(vim.o[name] or "", ",", { trimempty = true }) do
      local value = item:match("^[^:]+:(.*)$")
      if value and value ~= "" then
        for _, cp in ipairs(vim.fn.str2list(value)) do
          set[cp] = true
        end
      end
    end
  end
  return set
end

---Split ranges so none of `excluded` falls inside any of them.
---@param ranges integer[][]
---@param excluded table<integer, boolean>
---@return integer[][]
local function carve(ranges, excluded)
  local out = {}
  for _, r in ipairs(ranges) do
    local first, last, width = r[1], r[2], r[3]
    local holes = {}
    for cp in pairs(excluded) do
      if cp >= first and cp <= last then
        holes[#holes + 1] = cp
      end
    end
    table.sort(holes)
    local start = first
    for _, cp in ipairs(holes) do
      if cp > start then
        out[#out + 1] = { start, cp - 1, width }
      end
      start = cp + 1
    end
    if start <= last then
      out[#out + 1] = { start, last, width }
    end
  end
  return out
end

---Apply the widths, minus whatever 'fillchars'/'listchars' have claimed.
function M.setup()
  local excluded = reserved()
  local ranges = carve(M.ranges, excluded)
  local ok, err = pcall(vim.fn.setcellwidths, ranges)
  if ok then
    M.applied = #ranges
  end
  if not ok then
    -- Failing loudly beats a config that looks applied and is not: setcellwidths
    -- is all-or-nothing, so a rejected call leaves every glyph at its old width.
    vim.notify("r35.glyphs: setcellwidths failed: " .. tostring(err), vim.log.levels.ERROR)
  end
end

---Width `cp` will occupy once `setup()` has run -- whether or not it has yet.
---
---`strdisplaywidth` reports the table currently installed, which makes it the
---wrong instrument here. Plugin `opts` are resolved while `require("config.lazy")`
---runs, and init.lua cannot call `setup()` until after that returns, because
---`reserved()` has to read the 'fillchars' LazyVim sets during its own setup.
---An icon measured in that window is still one cell wide and looks like it
---fits, right up until `setup()` widens it out from under the stored value.
---
---Consulting `M.ranges` instead answers the question that actually matters --
---how wide will this end up? -- identically from either side of that ordering.
---@param cp integer
---@return integer
function M.width(cp)
  for _, range in ipairs(M.ranges) do
    if cp >= range[1] and cp <= range[2] then
      return range[3]
    end
  end
  return vim.fn.strdisplaywidth(vim.fn.nr2char(cp))
end

---Declared width of every codepoint in `text`, summed.
---@param text string
---@return integer
function M.cells(text)
  local total = 0
  for _, cp in ipairs(vim.fn.str2list(text)) do
    total = total + M.width(cp)
  end
  return total
end

---Fit `text` into a `budget` of display cells.
---
---Widths come from `M.ranges`, so this tracks the declared widths on its own:
---widen a range and the glyphs inside it start getting trimmed, with no second
---list to keep in sync and no constraint on when this may be called.
---
---(Codepoints `setup()` carves out for 'fillchars'/'listchars' are measured at
---their declared width rather than the one cell they keep. Those glyphs are
---never sign text, so the distinction has nowhere to show up.)
---@param text string
---@param budget integer
---@return string
function M.fit(text, budget)
  if M.cells(text) <= budget then
    return text
  end

  -- The common case: padding that used to fit and no longer does.
  local trimmed = vim.trim(text)
  if M.cells(trimmed) <= budget then
    return trimmed
  end

  -- Genuinely too wide. Drop whole codepoints rather than bytes so the result
  -- stays valid UTF-8, and say so out loud: a silently clipped icon reads as a
  -- font problem and sends you hunting in entirely the wrong place.
  local fitted, used = "", 0
  for _, cp in ipairs(vim.fn.str2list(trimmed)) do
    local cost = M.width(cp)
    if used + cost > budget then
      break
    end
    fitted, used = fitted .. vim.fn.nr2char(cp), used + cost
  end

  vim.notify(
    ("r35.glyphs: %q is %d cells, truncated to %q"):format(trimmed, M.cells(trimmed), fitted),
    vim.log.levels.WARN
  )
  return fitted
end

---Neovim's sign column is two cells wide and `sign_text` may not exceed it.
---
---This is the other half of the bargain `setup()` strikes. Promoting a glyph to
---two cells spends the entire sign budget on the glyph itself, so the padding
---icon sets habitually ship with -- LazyVim's diagnostic icons are a glyph plus
---a trailing space -- pushes `sign_text` to three cells, and every
---`nvim_buf_set_extmark` carrying it fails with "Invalid 'sign_text'".
local SIGN_CELLS = 2

---Fit `text` into the sign column's two-cell budget.
---@param text string
---@return string
function M.fit_sign(text)
  return M.fit(text, SIGN_CELLS)
end

return M
