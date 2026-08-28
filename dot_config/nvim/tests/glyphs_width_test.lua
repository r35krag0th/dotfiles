-- Tests for the public width helpers in `r35.glyphs.width`.
--
--   nvim --headless -c 'luafile ~/.config/nvim/tests/glyphs_width_test.lua'
--
-- The contract that matters: these answer "how wide will this be once setup()
-- has run", and give the SAME answer from either side of that call. That is why
-- they consult the declared ranges rather than `strdisplaywidth`, which reports
-- the table currently installed and is therefore order-dependent.

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

local NERD = vim.fn.nr2char(0xF057) -- fa, inside a declared 2-cell range
local ASCII = "E"

-- Deliberately BEFORE setup(): the answer must not depend on this.
vim.fn.setcellwidths({})

check("width() of ASCII is 1", glyphs.width(0x45) == 1, glyphs.width(0x45))
check("width() of a declared glyph is 2", glyphs.width(0xF057) == 2, glyphs.width(0xF057))
check("cells() of ASCII is 1", glyphs.cells(ASCII) == 1, glyphs.cells(ASCII))
check("cells() of a declared glyph is 2", glyphs.cells(NERD) == 2, glyphs.cells(NERD))
check("cells() sums across a string", glyphs.cells(NERD .. ASCII) == 3, glyphs.cells(NERD .. ASCII))

local before_width = glyphs.width(0xF057)
local before_cells = glyphs.cells(NERD .. " ")

glyphs.setup()

check("width() is order-independent", glyphs.width(0xF057) == before_width, glyphs.width(0xF057))
check("cells() is order-independent", glyphs.cells(NERD .. " ") == before_cells, glyphs.cells(NERD .. " "))

check("fit() leaves a string that already fits", glyphs.fit(NERD, 2) == NERD)
check("fit() sheds padding to make room", glyphs.fit(NERD .. " ", 2) == NERD, glyphs.fit(NERD .. " ", 2))
check("fit() honours a larger budget", glyphs.fit(NERD .. " ", 3) == NERD .. " ", glyphs.fit(NERD .. " ", 3))
check("fit() honours a budget of 4", glyphs.cells(glyphs.fit(NERD .. NERD, 4)) == 4)

-- Genuine overflow: whole codepoints only, and it must say so.
local notified
local real_notify = vim.notify
vim.notify = function(msg)
  notified = msg
end
local squeezed = glyphs.fit(NERD .. NERD, 2)
vim.notify = real_notify

check("fit() truncates to the budget", glyphs.cells(squeezed) == 2, glyphs.cells(squeezed))
check("fit() truncates whole codepoints", vim.fn.strchars(squeezed) == 1, vim.fn.strchars(squeezed))
check("fit() warns on truncation", notified ~= nil and notified:match("truncated") ~= nil, notified)

check("fit_sign is fit(text, 2)", glyphs.fit_sign(NERD .. " ") == glyphs.fit(NERD .. " ", 2))

-- Measured against ~/Library/Fonts/PragmataProVF_liga_09.ttf, advance vs M=1024.
-- Regenerate this table with: nvim -l scripts/gen_glyphs.lua --audit
local MEASURED = {
  { 0x23F2, 2, "timer clock (todo-comments TEST)" },
  { 0x23FB, 2, "iec_power" },
  { 0x23FC, 2, "iec_toggle_power" },
  { 0x23FD, 1, "iec_power_on" },
  { 0x23FE, 2, "iec_sleep_mode" },
  { 0x2B58, 1, "iec_power_off" },
  { 0x2665, 2, "oct_heart" },
  { 0x26A0, 2, "warning sign" },
  -- The font draws U+26A1 at 1024 units, but it is East Asian Wide, so nvim AND
  -- kitty both reserve 2 cells. They agree with each other and merely disagree
  -- with the font: the glyph renders slightly small, but nothing drifts.
  -- Forcing 1 here without changing kitty would turn that into real drift.
  { 0x26A1, 2, "oct_zap -- EAW-wide; font disagrees but nvim and kitty do not" },
  { 0xE008, 2, "pom_ last correct entry" },
  { 0xE009, 1, "pom_internal_interruption" },
  { 0xE00A, 1, "pom_external_interruption" },
  { 0xE0A0, 1, "pl_branch -- Powerline is 1 cell by measurement" },
}
for _, m in ipairs(MEASURED) do
  local cp, want, label = m[1], m[2], m[3]
  check(("U+%04X declared %d cell(s) -- %s"):format(cp, want, label), glyphs.width(cp) == want, glyphs.width(cp))
end

print(string.format("\n%d passed, %d failed", pass, fail))
vim.cmd(fail > 0 and "cq" or "qa!")
