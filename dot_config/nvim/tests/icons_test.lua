-- Tests for `r35.glyphs.icons`.
--
--   nvim --headless -c 'luafile ~/.config/nvim/tests/icons_test.lua'
--
-- The contract: a known name resolves; an unknown name is LOUD but harmless.
-- Returning nil for a typo is the failure mode this module exists to prevent --
-- a missing icon renders as nothing and reads as a font problem, which sends
-- you hunting in entirely the wrong place.
--
-- Deduplication is not a nicety. A bad icon in a lualine section re-evaluates
-- on nearly every redraw, so an undeduped notify is a denial-of-service.

local ok, icons = pcall(require, "r35.glyphs.icons")
if not ok then
  print("FAIL require r35.glyphs.icons: " .. tostring(icons))
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

---Capture every vim.notify made while `fn` runs.
local function capturing(fn)
  local msgs = {}
  local real = vim.notify
  vim.notify = function(msg)
    msgs[#msgs + 1] = msg
  end
  local result = fn()
  vim.notify = real
  return result, msgs
end

-- Known names, flat (WezTerm parity).
check("md_folder resolves", icons.md_folder == vim.fn.nr2char(0xF024B), icons.md_folder)
check("fa_bug resolves", icons.fa_bug == vim.fn.nr2char(0xF188), icons.fa_bug)
check("cod_account resolves", icons.cod_account == vim.fn.nr2char(0xEB99), icons.cod_account)

-- get / has never warn and never substitute.
local got, quiet = capturing(function()
  return icons.get("md_foldr")
end)
check("get() returns nil for unknown", got == nil, got)
check("get() does not notify", #quiet == 0, #quiet)
check("get() returns the glyph for known", icons.get("md_folder") == icons.md_folder)
check("has() is true for known", icons.has("md_folder") == true)
check("has() is false for unknown", icons.has("md_foldr") == false)

-- Unknown via indexing: placeholder now, diagnostic at the exact call site.
--
-- A notification needs you to think of `:messages`. A diagnostic lands on the
-- line you typed the typo, where you are already looking. The placeholder stays
-- two cells wide so a typo never shifts a statusline while you fix it.
local PLACEHOLDER = vim.fn.nr2char(0xEB32) -- cod_question
local THIS = debug.getinfo(1, "S").source:match("^@(.+)$")

local miss_line = debug.getinfo(1, "l").currentline + 1
local first = icons.md_foldr
check("unknown returns the placeholder", first == PLACEHOLDER, first)

local found
for _, m in ipairs(icons.misses()) do
  if m.name == "md_foldr" then
    found = m
  end
end
check("the miss is recorded", found ~= nil)
check("miss names this file", found and found.file == THIS, found and found.file)
check("miss points at the exact line", found and found.line == miss_line, found and found.line)
check("message names the bad key", found and found.message:match("md_foldr") ~= nil, found and found.message)
check("message suggests the near miss", found and found.message:match("md_folder") ~= nil, found and found.message)

-- Same site hit repeatedly records ONCE. This is the property that matters: a
-- bad icon in a lualine section is looked up on nearly every redraw.
local before = #icons.misses()
for _ = 1, 5 do
  local _ = icons.md_foldr
end
check("five lookups at one site record one miss", #icons.misses() == before + 1, #icons.misses() - before)

local repeated = icons.md_foldr
check("repeat lookup still returns the placeholder", repeated == PLACEHOLDER, repeated)

local n = #icons.misses()
local other = icons.fa_bg
check("a DIFFERENT bad name records its own miss", #icons.misses() == n + 1, #icons.misses() - n)
check("...and returns the placeholder", other == PLACEHOLDER, other)

-- The diagnostic must actually reach the buffer once the file is loaded.
vim.cmd.edit(THIS)
vim.wait(500, function()
  local ns = vim.api.nvim_get_namespaces()["r35_glyphs_icons"]
  return ns ~= nil and #vim.diagnostic.get(vim.fn.bufnr(THIS), { namespace = ns }) > 0
end)
local ns = vim.api.nvim_get_namespaces()["r35_glyphs_icons"]
check("a diagnostic namespace exists", ns ~= nil)
local diags = ns and vim.diagnostic.get(vim.fn.bufnr(THIS), { namespace = ns }) or {}
check(("diagnostics attached to the buffer (%d)"):format(#diags), #diags > 0)
local on_line = false
for _, d in ipairs(diags) do
  if d.lnum == miss_line - 1 then
    on_line = true
  end
end
check("a diagnostic sits on the line of the first miss", on_line, miss_line)
check("diagnostics are ERROR severity", diags[1] and diags[1].severity == vim.diagnostic.severity.ERROR)

-- from(): block-scoped access. Leaves are plain strings, same values as flat.
local fa = icons.from("fa")
check("from('fa').bug equals fa_bug", fa.bug == icons.fa_bug, fa.bug)
check("from('fa').square_o equals fa_square_o", fa.square_o == icons.fa_square_o, fa.square_o)
check("from() leaf is a plain string", type(fa.bug) == "string", type(fa.bug))
check("from('wi') aliases weather_", icons.from("wi").snow == icons.weather_snow)
check("from('logos') aliases linux_", icons.from("logos").ubuntu == icons.linux_ubuntu)
check("from('sui') aliases seti_", icons.from("sui").folder == icons.seti_folder)
check("from('custom') is its own block", icons.from("custom").folder == icons.custom_folder)
check("sui and custom folder differ (not merged)", icons.seti_folder ~= icons.custom_folder)
check("from('dev') aliases dev_", icons.from("dev").git == icons.dev_git)
check("wezterm's own prefix works too", icons.from("weather").snow == icons.weather_snow)
check("bracketed leaf works", icons.from("md")["function"] == icons.md_function)
check("digit-leading leaf works", icons.from("fa")["500px"] == icons.fa_500px)

local bad_block, block_msgs = capturing(function()
  return icons.from("nope")
end)
check("from() on an unknown block warns", #block_msgs == 1, #block_msgs)
check("from() on an unknown block returns a table", type(bad_block) == "table", type(bad_block))

-- sign(): lookup and fit in one call.
require("r35.glyphs").setup()
check("sign() fits the sign column", require("r35.glyphs").cells(icons.sign("fa_bug")) <= 2, icons.sign("fa_bug"))
check("sign() of a known name is the glyph", icons.sign("fa_bug") == icons.fa_bug)

-- Data integrity.
local data = require("r35.glyphs.data")
local n, bad_width, bad_name = 0, nil, nil
for name, glyph in pairs(data) do
  n = n + 1
  if vim.fn.strchars(glyph) ~= 1 then
    bad_width = name
  end
  if name == "get" or name == "has" or name == "sign" or name == "from" then
    bad_name = name
  end
end
check(("data has %d entries (>10000)"):format(n), n > 10000, n)
check("every value is exactly one codepoint", bad_width == nil, bad_width)
check("no name collides with the module API", bad_name == nil, bad_name)

-- Laziness, checked LAST and against a fresh instance.
--
-- Checking `package.loaded` at the top of this file would be vacuous: the
-- config itself now uses icons while resolving plugin opts, so the table is
-- already loaded before any test runs. Re-requiring proves the property that
-- actually matters -- `require` alone does not pull in 10,751 entries.
--
-- Last, because re-requiring re-registers the module's autocmd in a cleared
-- augroup, which would orphan the instance the diagnostic tests above rely on.
local saved_icons = package.loaded["r35.glyphs.icons"]
local saved_data = package.loaded["r35.glyphs.data"]
package.loaded["r35.glyphs.icons"] = nil
package.loaded["r35.glyphs.data"] = nil
local fresh = require("r35.glyphs.icons")
check("require alone does not load data", package.loaded["r35.glyphs.data"] == nil)
local _ = fresh.fa_bug
check("first glyph access loads data", package.loaded["r35.glyphs.data"] ~= nil)
package.loaded["r35.glyphs.icons"] = saved_icons
package.loaded["r35.glyphs.data"] = saved_data

print(string.format("\n%d passed, %d failed", pass, fail))
vim.cmd(fail > 0 and "cq" or "qa!")
