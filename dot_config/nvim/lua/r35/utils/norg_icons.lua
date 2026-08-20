---Neorg todo icons that replace the whole `(x)`, brackets included.
---
---Neorg's stock `on_left` renderer overlays `(" "):rep(len - 1) .. icon` at the
---todo status character. That arithmetic assumes the icon is exactly one cell
---wide. Ours are two (see r35.glyphs), so the overlay runs one cell past the
---node it is replacing, and `virt_text_pos = "overlay"` silently paints over
---whatever sits there -- the closing `)` -- leaving a dangling `(`. Writing
---`(! )` in the file, with a literal space, also renders correctly, which is the
---tell: the overlay is off by exactly one cell, not the font.
---
---The fix uses `conceal` rather than a wider overlay, because overlay virt_text
---cannot change a line's width -- it paints over N cells and whatever sits under
---cell N+1 just disappears. `conceal` genuinely reclaims the width: three cells
---of `(x)` collapse to the icon's two, and a double-width replacement renders at
---full size rather than being clipped.
---
---Two consequences worth knowing:
---
---  * The replacement must be a single character (`:h :syn-cchar`; `:syntax`
---    rejects two with E475). Multi-character icons fall back to the padded
---    overlay below, which keeps the width instead of reclaiming it.
---  * A concealed character does NOT inherit the highlight underneath it the way
---    an `hl_mode = "combine"` overlay does -- it falls back to Normal. The state
---    highlight has to be passed explicitly, which `M.todo` does.
---
---On the line the cursor is on, 'concealcursor' is empty by default, so the raw
---`(x)` shows through. That is the usual editing affordance rather than a
---defect; set `concealcursor` for norg buffers if you would rather see the icon
---there too.

local M = {}

---Neorg's own conceal namespace.
---
---Reusing it puts these marks inside neorg's clear-and-rerender cycle. A private
---namespace would render identically and then never be pruned.
---@return integer?
local function conceal_ns()
  return vim.api.nvim_get_namespaces()["neorg-conceals"]
end

---The `(x)` enclosing a todo status character.
---
---Neorg hands the renderer the status character alone; the brackets belong to
---its parent. Falling back to the node keeps this harmless rather than wrong if
---the grammar ever reshapes that.
---@param node TSNode
---@return integer row, integer col_start, integer col_end
local function bracket_range(node)
  local parent = node:parent()
  local target = (parent and parent:type() == "detached_modifier_extension") and parent or node
  local row, col_start, _, col_end = target:range()
  return row, col_start, col_end
end

---Replace the whole bracket group with the icon.
---@param config table
---@param bufid integer
---@param node TSNode
function M.render(config, bufid, node)
  local ns = conceal_ns()
  if not config.icon or not ns then
    return
  end

  local row, col, col_end = bracket_range(node)

  -- One character: conceal it, reclaiming the cell the brackets no longer need.
  if vim.fn.strchars(config.icon) == 1 then
    vim.api.nvim_buf_set_extmark(bufid, ns, row, col, {
      end_row = row,
      end_col = col_end,
      conceal = config.icon,
      hl_group = config.highlight,
      hl_mode = "combine",
    })
    return
  end

  -- More than one character, which `conceal` cannot express. Overlay it padded
  -- to the bracket width instead: no cell is reclaimed, but nothing downstream
  -- shifts and nothing gets eaten either.
  local pad = (col_end - col) - vim.fn.strdisplaywidth(config.icon)
  if pad < 0 then
    -- Wider than the brackets it would replace. Leaving the literal text alone
    -- is the honest outcome; overlaying anyway is what caused this bug.
    return
  end

  vim.api.nvim_buf_set_extmark(bufid, ns, row, col, {
    virt_text = { { config.icon .. (" "):rep(pad), config.highlight } },
    virt_text_pos = "overlay",
    virt_text_hide = true,
    hl_mode = "combine",
    end_row = row,
    end_col = col,
  })
end

---Prune marks across the whole bracket group before a re-render.
---
---Neorg's default cleanup covers only the node's own range, so a mark anchored a
---column to its left survives and the next render stacks another on top.
---Defining `clear` replaces that default -- see the `if config.clear` branch in
---neorg's concealer.
---@param _ table
---@param bufid integer
---@param node TSNode
function M.clear(_, bufid, node)
  local ns = conceal_ns()
  if not ns then
    return
  end

  local row, col, col_end = bracket_range(node)
  local last = math.max(col, col_end - 1)
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(bufid, ns, { row, col }, { row, last }, {})) do
    vim.api.nvim_buf_del_extmark(bufid, ns, mark[1])
  end
end

---Expand `state = icon` pairs into neorg icon configs using the renderer above.
---
---Each state gets its own `@neorg.todo_items.*` highlight. Neorg leaves these
---nil and lets `hl_mode = "combine"` pick the colour up off the text underneath,
---which works for an overlay but not for a concealed character -- that falls
---back to Normal, so every icon would come out the same colour.
---@param icons table<string, string>
---@return table
function M.todo(icons)
  local out = {}
  for state, icon in pairs(icons) do
    out[state] = {
      icon = icon,
      highlight = "@neorg.todo_items." .. state,
      render = M.render,
      clear = M.clear,
    }
  end
  return out
end

return M
