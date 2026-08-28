---Nerd Font glyphs by name.
---
---The interface is Wez Furlong's, borrowed from WezTerm's `wezterm.nerdfonts`:
---  https://wezterm.org/config/lua/wezterm/nerdfonts.html
---Index the module with a glyph's symbolic name and get the string back.
---
---  local icons = require("r35.glyphs.icons")
---  icons.fa_bug          --> the glyph
---  icons.get("fa_bug")   --> the glyph, or nil, silently
---  icons.has("fa_bug")   --> boolean
---  icons.sign("fa_bug")  --> the glyph, fitted to the sign column
---  icons.from("fa").bug  --> the same glyph, block-scoped
---
---Unknown names are LOUD rather than nil. A nil icon renders as nothing and
---reads as a font problem, which is the wrong place to go looking. See
---`unknown()` below.
---
---`data` is required lazily. Requiring this module costs nothing until a glyph
---is actually asked for; the table is 10,751 entries and measures around 3.3 ms
---cold, 1.4 ms once `vim.loader` has cached its bytecode.
---
---Completion comes from the generated `types.lua`, which declares every name
---with the rendered glyph as its description -- so the popup shows the actual
---icon. With 10,751 names that is what makes them usable.

---@class r35.glyphs.icons : r35.glyphs.names
local M = {}

---Codicon `cod_question`. Inside a declared two-cell block, so a missing icon
---occupies exactly the space a real one would and the layout does not shift
---while you work out what went wrong.
local PLACEHOLDER = "\u{EB32}"

---Short block key -> the ONE WezTerm prefix it maps to.
---
---Strictly 1:1. `seti_`/`custom_` share 17 leaf names (`folder`, `go`, `c`,
---`cpp`, `ruby`, ...) and `indent_`/`indentation_` share `line`, so merging
---them into one key would silently drop glyphs. Each keeps its own key:
---nothing is shadowed, nothing is unreachable.
local ALIASES = {
  fa = "fa",
  fae = "fae",
  pl = "pl",
  ple = "ple",
  wi = "weather",
  sui = "seti",
  custom = "custom",
  oct = "oct",
  logos = "linux",
  iec = "iec",
  pom = "pom",
  md = "md",
  cod = "cod",
  dev = "dev",
  indent = "indent",
  indentation = "indentation",
}

---Every accepted block key -> prefix. WezTerm's own prefix names resolve too,
---so `from("weather")` and `from("wi")` are the same block.
local PREFIX = {}
for alias, prefix in pairs(ALIASES) do
  PREFIX[alias] = prefix
  PREFIX[prefix] = prefix
end

---@type table<string, string>|nil
local data

---@return table<string, string>
local function load()
  data = data or require("r35.glyphs.data")
  return data
end

---Diagnostics for unknown names, keyed by the file they were written in.
---
---A missing icon renders as nothing and reads as a font problem, which sends
---you hunting in the wrong place. A notification is better than nothing but
---still needs you to think of `:messages`. A diagnostic lands the error on the
---exact line you typed the typo, where you are already looking.
local NS = vim.api.nvim_create_namespace("r35_glyphs_icons")

---This file's own path, so `caller()` can skip its own frames.
local SELF = (debug.getinfo(1, "S").source or ""):match("^@(.+)$")

---The first stack frame outside this module: whoever actually wrote the name.
---
---Walking rather than indexing a fixed level. The depth differs by entry point
---- `icons.foo` reaches here through `__index` then `unknown`, while
---`icons.sign("foo")` adds another frame - and a hardcoded level silently
---blames icons.lua itself, which is exactly the wrong file to point at.
---@return string? file, integer line
local function caller()
  for lvl = 2, 12 do
    local info = debug.getinfo(lvl, "Sl")
    if not info then
      return nil, 0
    end
    local file = info.source and info.source:match("^@(.+)$")
    if file and file ~= SELF and info.currentline and info.currentline > 0 then
      return file, info.currentline
    end
  end
  return nil, 0
end

---file -> key -> vim.Diagnostic. Keyed per call SITE, not per name: the same
---typo in two files is two problems, and each wants its own squiggle.
---@type table<string, table<string, vim.Diagnostic>>
local misses = {}

---Files carrying diagnostics that have not been attached to a buffer yet,
---because the file was not loaded when the miss happened -- which is the normal
---case, since plugin `opts` resolve long before you open the file to fix them.
---@type table<string, true>
local unattached = {}

---@param file string
local function attach(file)
  local buf = vim.fn.bufnr(file)
  if buf == -1 or not vim.api.nvim_buf_is_loaded(buf) then
    unattached[file] = true
    return
  end
  unattached[file] = nil
  local list = {}
  for _, d in pairs(misses[file] or {}) do
    list[#list + 1] = d
  end
  vim.diagnostic.set(NS, buf, list)
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("r35_glyphs_icons", { clear = true }),
  callback = function(ev)
    local file = vim.api.nvim_buf_get_name(ev.buf)
    if misses[file] and unattached[file] then
      attach(file)
    end
  end,
})

---Every unknown-name diagnostic recorded this session.
---
---Exported for `:checkhealth r35.glyphs`, which is the safety net for misses in
---files you never open -- a diagnostic nobody looks at is not a report.
---@return { file: string, line: integer, name: string, message: string }[]
function M.misses()
  local out = {}
  for file, per_site in pairs(misses) do
    for _, d in pairs(per_site) do
      out[#out + 1] = { file = file, line = d.lnum + 1, name = d.user_data, message = d.message }
    end
  end
  table.sort(out, function(a, b)
    return a.file .. a.line < b.file .. b.line
  end)
  return out
end

---Handle a name that is not in the table.
---
---Always returns PLACEHOLDER: never nil, never an error. A nil would render as
---nothing, and an error would take down whichever plugin asked.
---@param name string
---@return string
local function unknown(name)
  local file, line = caller()

  if not file or line <= 0 then
    -- No source to point at (a C boundary, or a loaded string chunk). Fall back
    -- to notifying, deduped by name, rather than losing the report entirely.
    if not misses["\0nofile"] then
      misses["\0nofile"] = {}
    end
    if not misses["\0nofile"][name] then
      misses["\0nofile"][name] = { lnum = 0, message = name, user_data = name }
      vim.notify(("r35.glyphs.icons: unknown glyph %q"):format(name), vim.log.levels.WARN)
    end
    return PLACEHOLDER
  end

  local key = line .. ":" .. name
  misses[file] = misses[file] or {}
  if misses[file][key] then
    return PLACEHOLDER
  end

  local suggestion = vim.fn.matchfuzzy(vim.tbl_keys(load()), name)[1]
  local message = ("r35.glyphs.icons: unknown glyph %q"):format(name)
  if suggestion then
    message = message .. ("\ndid you mean %q?"):format(suggestion)
  end

  misses[file][key] = {
    lnum = line - 1,
    col = 0,
    end_lnum = line - 1,
    severity = vim.diagnostic.severity.ERROR,
    source = "r35.glyphs",
    message = message,
    user_data = name,
  }

  -- Scheduled: `__index` fires while plugin `opts` are being resolved, and
  -- `vim.diagnostic.set` is not safe from every context that can reach here.
  vim.schedule(function()
    attach(file)
  end)

  return PLACEHOLDER
end

setmetatable(M, {
  __index = function(_, name)
    return load()[name] or unknown(name)
  end,
})

---Look up `name` without warning or substituting.
---@param name string
---@return string|nil
function M.get(name)
  return load()[name]
end

---@param name string
---@return boolean
function M.has(name)
  return load()[name] ~= nil
end

---Look up `name` and fit it to the two-cell sign column.
---
---`sign_text` accepts at most two display cells and rejects the whole extmark
---otherwise, so this is the form you want anywhere a glyph becomes a sign.
---@param name string
---@return string
function M.sign(name)
  return require("r35.glyphs.width").fit(M[name], 2)
end

---@type table<string, table<string, string>>
local blocks = {}

---Block keys already warned about. Separate from the per-site diagnostics
---above: an unknown BLOCK is a programming error with no useful call site to
---annotate (you get an empty table, not a wrong glyph), and there are only 16
---valid keys, so naming them all in one notification is the whole fix.
---@type table<string, true>
local warned_blocks = {}

---Glyphs of one block, keyed by name with the prefix stripped.
---
---One level deep on purpose. Nesting further (`from("fa").square.outline`) is
---not possible coherently: 2,814 of 10,751 names are simultaneously a glyph and
---the parent of other names, so `fa_square` would have to be both a string and
---a table -- and a proxy table breaks every consumer that assigns the result
---straight into a plugin's `opts`. Flat leaves stay plain strings.
---
---Four leaves need bracket syntax, being Lua keywords or digit-leading once the
---prefix is stripped: `from("fa")["500px"]`, `from("fa")["repeat"]`,
---`from("md")["function"]`, `from("md")["repeat"]`.
---@type r35.glyphs.From
M.from = function(block)
  local prefix = PREFIX[block]
  if not prefix then
    local key = tostring(block)
    if not warned_blocks[key] then
      warned_blocks[key] = true
      local keys = vim.tbl_keys(ALIASES)
      table.sort(keys)
      vim.notify(
        ("r35.glyphs.icons: unknown block %q (have: %s)"):format(tostring(block), table.concat(keys, ", ")),
        vim.log.levels.WARN
      )
    end
    return {}
  end

  if blocks[prefix] then
    return blocks[prefix]
  end
  local out = {}
  for name, glyph in pairs(load()) do
    local p, leaf = name:match("^([a-z0-9]+)_(.+)$")
    if p == prefix then
      out[leaf] = glyph
    end
  end
  blocks[prefix] = out
  return out
end

return M
