---Browse Nerd Font glyphs and insert the NAME.
---
---snacks ships `Snacks.picker.icons()` already, and it is good, but it differs
---in the way that matters here: it uses upstream nerd-fonts naming
---(`nf-fa-bug`), fetches `glyphnames.json` over the network, and its confirm
---action is `put` -- it inserts the raw glyph character.
---
---Inserting the glyph is the trap this whole module exists to avoid.
---`lua/plugins/todo-comments.lua` says it outright: PUA codepoints "render as
---nothing without a patched font, so literals would be unreadable in a diff or
---on the web", and one went missing that way already.
---
---So this picker inserts `fa_bug`, not ``. Offline, from the generated table,
---in the naming this config actually uses.
---
---  <CR>   insert the flat name        fa_bug
---  <C-b>  insert the block form       from("fa").bug
---  <C-y>  yank the glyph itself       (when you really do want the character)

local M = {}

---Alias for each WezTerm prefix. Kept beside the picker rather than exported
---from icons.lua because only display needs it.
local ALIAS_OF = {
  fa = "fa",
  fae = "fae",
  pl = "pl",
  ple = "ple",
  weather = "wi",
  seti = "sui",
  custom = "custom",
  oct = "oct",
  linux = "logos",
  iec = "iec",
  pom = "pom",
  md = "md",
  cod = "cod",
  dev = "dev",
  indent = "indent",
  indentation = "indentation",
}

---Leaves needing bracket syntax, so the block form we offer is valid Lua.
local function block_form(alias, leaf)
  if leaf:match("^%d") or leaf:match("^[a-z]+$") == nil then
    return ("from(%q)[%q]"):format(alias, leaf)
  end
  -- Lua keywords cannot follow a dot.
  local KEYWORDS = {
    ["and"] = true,
    ["break"] = true,
    ["do"] = true,
    ["else"] = true,
    ["elseif"] = true,
    ["end"] = true,
    ["false"] = true,
    ["for"] = true,
    ["function"] = true,
    ["goto"] = true,
    ["if"] = true,
    ["in"] = true,
    ["local"] = true,
    ["nil"] = true,
    ["not"] = true,
    ["or"] = true,
    ["repeat"] = true,
    ["return"] = true,
    ["then"] = true,
    ["true"] = true,
    ["until"] = true,
    ["while"] = true,
  }
  if KEYWORDS[leaf] then
    return ("from(%q)[%q]"):format(alias, leaf)
  end
  return ("from(%q).%s"):format(alias, leaf)
end

---One picker item per glyph. Exported so it can be tested without a UI.
---@return table[]
function M.items()
  local data = require("r35.glyphs.data")
  local names = vim.tbl_keys(data)
  table.sort(names)

  local out = {}
  for _, name in ipairs(names) do
    local prefix, leaf = name:match("^([a-z0-9]+)_(.+)$")
    local alias = ALIAS_OF[prefix] or prefix
    local form = block_form(alias, leaf)
    out[#out + 1] = {
      -- `text` is what the fuzzy matcher sees. Both forms are included so
      -- searching "fa bug" and "fa_bug" both land.
      text = name .. " " .. form,
      name = name,
      leaf = leaf,
      block = alias,
      form = form,
      glyph = data[name],
    }
  end
  return out
end

---@param text string
local function insert(text)
  vim.api.nvim_put({ text }, "c", true, true)
end

---Open the picker.
---@param opts? table passed through to Snacks.picker.pick
function M.open(opts)
  local ok, Snacks = pcall(require, "snacks")
  if not ok or not Snacks.picker then
    vim.notify("r35.glyphs.picker: snacks.nvim with the picker module is required", vim.log.levels.ERROR)
    return
  end

  return Snacks.picker.pick(vim.tbl_deep_extend("force", {
    title = "Nerd Font Glyphs",
    items = M.items(),
    layout = { preset = "vscode" },
    format = function(item)
      return {
        { item.glyph .. "  ", "Special" },
        { ("%-34s"):format(item.name), "Identifier" },
        { item.form, "Comment" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        insert(item.name)
      end
    end,
    actions = {
      insert_block_form = function(picker, item)
        picker:close()
        if item then
          insert(item.form)
        end
      end,
      yank_glyph = function(picker, item)
        picker:close()
        if item then
          vim.fn.setreg(vim.v.register or '"', item.glyph)
          vim.notify(("yanked %s (%s)"):format(item.glyph, item.name))
        end
      end,
    },
    win = {
      input = {
        keys = {
          ["<c-b>"] = { "insert_block_form", mode = { "i", "n" } },
          ["<c-y>"] = { "yank_glyph", mode = { "i", "n" } },
        },
      },
    },
  }, opts or {}))
end

return M
