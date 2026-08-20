-- Regression tests for `r35.glyphs.fit_sign`.
--
--   nvim --headless -c 'luafile ~/.config/nvim/tests/glyphs_sign_test.lua'
--
-- Exits non-zero if anything fails. Touches no files and no plugins: it drives
-- `setcellwidths` directly so both sides of widening a glyph can be exercised
-- in a single run.
--
-- The behaviour under test: `sign_text` accepts at most two display cells.
-- LazyVim ships diagnostic icons as a Nerd Font glyph plus a trailing space,
-- which measures two cells until `r35.glyphs.setup()` declares the glyph itself
-- two cells wide -- at which point the pair measures three and every
-- `nvim_buf_set_extmark` carrying it fails with "Invalid 'sign_text'".
--
-- The regression that motivated these: `fit_sign` originally measured with
-- `strdisplaywidth`, so it returned a DIFFERENT answer depending on whether
-- `setup()` had run yet. It has to run before -- nvim-lspconfig is configured
-- during `require("config.lazy")` -- where the padded icon still measured two
-- cells and sailed through untouched. Hence `order independence` below, which
-- is the test that would have caught it.

local ok, glyphs = pcall(require, "r35.glyphs")
if not ok then
  print("FAIL require r35.glyphs: " .. tostring(glyphs))
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

local ns = vim.api.nvim_create_namespace("r35_glyphs_test")
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "line" })

---Does Neovim actually accept this as sign text? The only contract that matters.
local function accepted(text)
  return (pcall(vim.api.nvim_buf_set_extmark, buf, ns, 0, 0, { sign_text = text }))
end

local function cells(text)
  return vim.fn.strdisplaywidth(text)
end

local ERROR_ICON = vim.fn.nr2char(0xF057) -- LazyVim's diagnostic Error glyph
local PADDED = ERROR_ICON .. " " -- ...as LazyVim actually ships it

-- Before any widths are declared, which is when plugin opts are resolved.
vim.fn.setcellwidths({})
check("padded icon still measures 2 cells here", cells(PADDED) == 2, cells(PADDED))
check("fit_sign trims it anyway", glyphs.fit_sign(PADDED) == ERROR_ICON, glyphs.fit_sign(PADDED))
check("plain ASCII passes through", glyphs.fit_sign("E") == "E")
check("a bare 1-cell char is left alone", glyphs.fit_sign("!") == "!")
local before = glyphs.fit_sign(PADDED)

-- Apply the real width table. This is the change that breaks diagnostics.
glyphs.setup()

check("glyph alone is 2 cells after widening", cells(ERROR_ICON) == 2, cells(ERROR_ICON))
check("padded icon is now 3 cells", cells(PADDED) == 3, cells(PADDED))
check("padded icon is rejected by extmark", not accepted(PADDED))
check("order independence: same result either side of setup()", glyphs.fit_sign(PADDED) == before, before)
check("fit_sign output is accepted", accepted(glyphs.fit_sign(PADDED)))

-- Every glyph the widened ranges cover must survive the round trip, not just
-- the one severity that happened to be in the traceback.
local sampled, worst = 0, nil
for _, range in ipairs(glyphs.ranges) do
  for _, cp in ipairs({ range[1], math.floor((range[1] + range[2]) / 2), range[2] }) do
    local fitted = glyphs.fit_sign(vim.fn.nr2char(cp) .. " ")
    sampled = sampled + 1
    if not accepted(fitted) then
      worst = ("U+%05X -> %q (%d cells)"):format(cp, fitted, cells(fitted))
      break
    end
  end
end
check(("all %d sampled range glyphs fit once padded"):format(sampled), worst == nil, worst)

-- Oversized with no padding to shed: truncate to whole codepoints, and warn --
-- a silently clipped icon reads as a font bug and misdirects the search.
local notified
local real_notify = vim.notify
vim.notify = function(msg)
  notified = msg
end
local truncated = glyphs.fit_sign(ERROR_ICON .. ERROR_ICON)
vim.notify = real_notify

check("unpaddable overflow is truncated to 2 cells", cells(truncated) == 2, cells(truncated))
check("truncated result is valid UTF-8", vim.fn.strchars(truncated) == 1, vim.fn.strchars(truncated))
check("truncated result is accepted", accepted(truncated))
check("truncation warns", notified ~= nil and notified:match("truncated") ~= nil, notified)

print(string.format("\n%d passed, %d failed", pass, fail))
vim.cmd(fail > 0 and "cq" or "qa!")
