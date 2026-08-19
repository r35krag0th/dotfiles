-- Candy: a neovim colorscheme derived from the kitty tab bar palette.
--
-- Generated from the same OKLCH derivation that produces the tab bar's ten
-- candies, with L and C redistributed per semantic role. Do not hand-edit the
-- hexes in palette.lua -- regenerate, or the equal-weight property that makes
-- the set cohere quietly breaks.

local M = {}

local C = require("r35.themes.candy.palette")

---Apply the colorscheme.
function M.load()
  if vim.g.colors_name then
    vim.cmd("hi clear")
  end
  vim.o.termguicolors = true
  vim.o.background = "dark"
  vim.g.colors_name = "candy"

  local set = vim.api.nvim_set_hl
  for group, spec in pairs(M.groups()) do
    set(0, group, spec)
  end
  for i, colour in ipairs(C.terminal) do
    vim.g["terminal_color_" .. (i - 1)] = colour
  end
end

---All highlight groups, as a single table so they can be inspected or patched
---before being applied.
---@return table<string, table>
function M.groups()
  local g = {
  -- Editor
  ["Normal"] = { fg = C["fg"], bg = C["bg"] },
  ["NormalNC"] = { fg = C["fg"], bg = C["bg"] },
  ["NormalFloat"] = { fg = C["fg"], bg = C["bg_float"] },
  ["FloatBorder"] = { fg = C["border"], bg = C["bg_float"] },
  ["FloatTitle"] = { fg = C["line_nr_active"], bg = C["bg_float"], bold = true },
  ["ColorColumn"] = { bg = C["bg_cursorline"] },
  ["Conceal"] = { fg = C["fg_muted"] },
  ["Cursor"] = { fg = C["bg"], bg = C["fg"] },
  ["lCursor"] = { fg = C["bg"], bg = C["fg"] },
  ["CursorIM"] = { fg = C["bg"], bg = C["fg"] },
  ["CursorColumn"] = { bg = C["bg_cursorline"] },
  ["CursorLine"] = { bg = C["bg_cursorline"] },
  ["CursorLineNr"] = { fg = C["line_nr_active"], bold = true },
  ["LineNr"] = { fg = C["line_nr"] },
  ["LineNrAbove"] = { fg = C["line_nr"] },
  ["LineNrBelow"] = { fg = C["line_nr"] },
  ["SignColumn"] = { fg = C["line_nr"], bg = C["bg_gutter"] },
  ["FoldColumn"] = { fg = C["line_nr"], bg = C["bg_gutter"] },
  ["Folded"] = { fg = C["comment"], bg = C["bg_cursorline"] },
  ["Directory"] = { fg = C["function"] },
  ["EndOfBuffer"] = { fg = C["bg"] },
  ["VertSplit"] = { fg = C["border"] },
  ["WinSeparator"] = { fg = C["border"] },
  ["NonText"] = { fg = C["line_nr"] },
  ["Whitespace"] = { fg = C["line_nr"] },
  ["SpecialKey"] = { fg = C["line_nr"] },
  ["Title"] = { fg = C["function"], bold = true },
  ["Question"] = { fg = C["info"] },
  ["MoreMsg"] = { fg = C["info"] },
  ["ModeMsg"] = { fg = C["fg"], bold = true },
  ["MsgArea"] = { fg = C["fg"] },
  ["ErrorMsg"] = { fg = C["error"] },
  ["WarningMsg"] = { fg = C["warning"] },
  ["MatchParen"] = { fg = C["line_nr_active"], bg = C["bg_matchparen"], bold = true },
  ["QuickFixLine"] = { bg = C["bg_quickfix"], bold = true },
  ["Visual"] = { bg = C["bg_visual"] },
  ["VisualNOS"] = { bg = C["bg_visual"] },
  -- Search. CurSearch forces BOTH colours so it can never inherit an
  -- unreadable foreground -- see palette.lua.
  ["Search"] = { fg = C["fg"], bg = C["bg_search"] },
  ["IncSearch"] = { fg = C["fg_cursearch"], bg = C["bg_cursearch"], bold = true },
  ["CurSearch"] = { fg = C["fg_cursearch"], bg = C["bg_cursearch"], bold = true },
  ["Substitute"] = { fg = C["fg_cursearch"], bg = C["bg_cursearch"] },
  -- Popups
  ["Pmenu"] = { fg = C["fg"], bg = C["bg_float"] },
  ["PmenuSel"] = { bg = C["bg_pmenu_sel"], bold = true },
  ["PmenuKind"] = { fg = C["type"], bg = C["bg_float"] },
  ["PmenuKindSel"] = { fg = C["type"], bg = C["bg_pmenu_sel"] },
  ["PmenuExtra"] = { fg = C["comment"], bg = C["bg_float"] },
  ["PmenuExtraSel"] = { fg = C["comment"], bg = C["bg_pmenu_sel"] },
  ["PmenuSbar"] = { bg = C["bg_float"] },
  ["PmenuThumb"] = { bg = C["border"] },
  ["WildMenu"] = { bg = C["bg_pmenu_sel"] },
  -- Statusline and tabs
  ["StatusLine"] = { fg = C["fg_statusline"], bg = C["bg_statusline"] },
  ["StatusLineNC"] = { fg = C["line_nr"], bg = C["bg_statusline"] },
  ["TabLine"] = { fg = C["comment"], bg = C["bg_gutter"] },
  ["TabLineFill"] = { bg = C["bg_gutter"] },
  ["TabLineSel"] = { fg = C["bg"], bg = C["function"], bold = true },
  ["WinBar"] = { fg = C["comment"], bold = true },
  ["WinBarNC"] = { fg = C["line_nr"] },
  -- Diff
  ["DiffAdd"] = { bg = C["bg_diff_add"] },
  ["DiffChange"] = { bg = C["bg_diff_change"] },
  ["DiffDelete"] = { bg = C["bg_diff_delete"] },
  ["DiffText"] = { bg = C["bg_diff_text"], bold = true },
  ["Added"] = { fg = C["string"] },
  ["Changed"] = { fg = C["constant"] },
  ["Removed"] = { fg = C["error"] },
  -- Spell
  ["SpellBad"] = { undercurl = true, sp = C["error"] },
  ["SpellCap"] = { undercurl = true, sp = C["warning"] },
  ["SpellLocal"] = { undercurl = true, sp = C["info"] },
  ["SpellRare"] = { undercurl = true, sp = C["hint"] },
  -- Legacy syntax
  ["Comment"] = { fg = C["comment"], italic = true },
  ["Constant"] = { fg = C["constant"] },
  ["String"] = { fg = C["string"] },
  ["Character"] = { fg = C["string"] },
  ["Number"] = { fg = C["constant"] },
  ["Float"] = { fg = C["constant"] },
  ["Boolean"] = { fg = C["boolean"] },
  ["Identifier"] = { fg = C["fg"] },
  ["Function"] = { fg = C["function"] },
  ["Statement"] = { fg = C["keyword"] },
  ["Conditional"] = { fg = C["keyword"] },
  ["Repeat"] = { fg = C["keyword"] },
  ["Label"] = { fg = C["keyword"] },
  ["Operator"] = { fg = C["fg_muted"] },
  ["Keyword"] = { fg = C["keyword"] },
  ["Exception"] = { fg = C["keyword"] },
  ["PreProc"] = { fg = C["boolean"] },
  ["Include"] = { fg = C["keyword"] },
  ["Define"] = { fg = C["keyword"] },
  ["Macro"] = { fg = C["boolean"] },
  ["PreCondit"] = { fg = C["boolean"] },
  ["Type"] = { fg = C["type"] },
  ["StorageClass"] = { fg = C["keyword"] },
  ["Structure"] = { fg = C["type"] },
  ["Typedef"] = { fg = C["type"] },
  ["Special"] = { fg = C["boolean"] },
  ["SpecialChar"] = { fg = C["boolean"] },
  ["Tag"] = { fg = C["type"] },
  ["Delimiter"] = { fg = C["fg_muted"] },
  ["SpecialComment"] = { fg = C["comment"], bold = true },
  ["Debug"] = { fg = C["error"] },
  ["Underlined"] = { fg = C["info"], underline = true },
  ["Ignore"] = { fg = C["line_nr"] },
  ["Error"] = { fg = C["error"] },
  ["Todo"] = { fg = C["bg"], bg = C["hint"], bold = true },
  -- Diagnostics
  ["DiagnosticError"] = { fg = C["error"] },
  ["DiagnosticWarn"] = { fg = C["warning"] },
  ["DiagnosticInfo"] = { fg = C["info"] },
  ["DiagnosticHint"] = { fg = C["hint"] },
  ["DiagnosticOk"] = { fg = C["string"] },
  ["DiagnosticVirtualTextError"] = { fg = C["error"], bg = C["bg_vt_error"] },
  ["DiagnosticVirtualTextWarn"] = { fg = C["warning"], bg = C["bg_vt_warning"] },
  ["DiagnosticVirtualTextInfo"] = { fg = C["info"], bg = C["bg_vt_info"] },
  ["DiagnosticVirtualTextHint"] = { fg = C["hint"], bg = C["bg_vt_hint"] },
  ["DiagnosticUnderlineError"] = { undercurl = true, sp = C["error"] },
  ["DiagnosticUnderlineWarn"] = { undercurl = true, sp = C["warning"] },
  ["DiagnosticUnderlineInfo"] = { undercurl = true, sp = C["info"] },
  ["DiagnosticUnderlineHint"] = { undercurl = true, sp = C["hint"] },
  ["DiagnosticFloatingError"] = { fg = C["error"], bg = C["bg_float"] },
  ["DiagnosticFloatingWarn"] = { fg = C["warning"], bg = C["bg_float"] },
  ["DiagnosticFloatingInfo"] = { fg = C["info"], bg = C["bg_float"] },
  ["DiagnosticFloatingHint"] = { fg = C["hint"], bg = C["bg_float"] },
  ["DiagnosticSignError"] = { fg = C["error"], bg = C["bg_gutter"] },
  ["DiagnosticSignWarn"] = { fg = C["warning"], bg = C["bg_gutter"] },
  ["DiagnosticSignInfo"] = { fg = C["info"], bg = C["bg_gutter"] },
  ["DiagnosticSignHint"] = { fg = C["hint"], bg = C["bg_gutter"] },
  ["DiagnosticDeprecated"] = { strikethrough = true, sp = C["comment"] },
  ["DiagnosticUnnecessary"] = { fg = C["line_nr"] },
  -- LSP
  ["LspReferenceText"] = { bg = C["bg_visual"] },
  ["LspReferenceRead"] = { bg = C["bg_visual"] },
  ["LspReferenceWrite"] = { bg = C["bg_visual"], underline = true },
  ["LspSignatureActiveParameter"] = { fg = C["parameter"], bold = true },
  ["LspInlayHint"] = { fg = C["line_nr"], bg = C["bg_cursorline"], italic = true },
  ["LspCodeLens"] = { fg = C["comment"], italic = true },
  ["LspInfoBorder"] = { fg = C["border"], bg = C["bg_float"] },

  -- Treesitter
  ["@variable"] = { fg = C["fg"] },
  ["@variable.builtin"] = { fg = C["boolean"] },
  ["@variable.parameter"] = { fg = C["parameter"] },
  ["@variable.member"] = { fg = C["field"] },
  ["@constant"] = { fg = C["constant"] },
  ["@constant.builtin"] = { fg = C["boolean"] },
  ["@constant.macro"] = { fg = C["boolean"] },
  ["@module"] = { fg = C["type"] },
  ["@module.builtin"] = { fg = C["type"] },
  ["@label"] = { fg = C["keyword"] },
  ["@string"] = { fg = C["string"] },
  ["@string.documentation"] = { fg = C["string"] },
  ["@string.regexp"] = { fg = C["boolean"] },
  ["@string.escape"] = { fg = C["boolean"], bold = true },
  ["@string.special"] = { fg = C["boolean"] },
  ["@string.special.url"] = { fg = C["info"], underline = true },
  ["@character"] = { fg = C["string"] },
  ["@character.special"] = { fg = C["boolean"] },
  ["@number"] = { fg = C["constant"] },
  ["@number.float"] = { fg = C["constant"] },
  ["@boolean"] = { fg = C["boolean"] },
  ["@type"] = { fg = C["type"] },
  ["@type.builtin"] = { fg = C["type"], italic = true },
  ["@type.definition"] = { fg = C["type"] },
  ["@attribute"] = { fg = C["boolean"] },
  ["@property"] = { fg = C["field"] },
  ["@function"] = { fg = C["function"] },
  ["@function.builtin"] = { fg = C["function"], italic = true },
  ["@function.call"] = { fg = C["function"] },
  ["@function.macro"] = { fg = C["boolean"] },
  ["@function.method"] = { fg = C["function"] },
  ["@function.method.call"] = { fg = C["function"] },
  ["@constructor"] = { fg = C["type"] },
  ["@operator"] = { fg = C["fg_muted"] },
  ["@keyword"] = { fg = C["keyword"] },
  ["@keyword.function"] = { fg = C["keyword"] },
  ["@keyword.operator"] = { fg = C["keyword"] },
  ["@keyword.import"] = { fg = C["keyword"] },
  ["@keyword.type"] = { fg = C["keyword"] },
  ["@keyword.modifier"] = { fg = C["keyword"] },
  ["@keyword.repeat"] = { fg = C["keyword"] },
  ["@keyword.return"] = { fg = C["keyword"], bold = true },
  ["@keyword.debug"] = { fg = C["error"] },
  ["@keyword.exception"] = { fg = C["keyword"] },
  ["@keyword.conditional"] = { fg = C["keyword"] },
  ["@keyword.directive"] = { fg = C["boolean"] },
  ["@punctuation.delimiter"] = { fg = C["fg_muted"] },
  ["@punctuation.bracket"] = { fg = C["fg_muted"] },
  ["@punctuation.special"] = { fg = C["boolean"] },
  ["@comment"] = { fg = C["comment"], italic = true },
  ["@comment.error"] = { fg = C["bg"], bg = C["error"], bold = true },
  ["@comment.warning"] = { fg = C["bg"], bg = C["warning"], bold = true },
  ["@comment.todo"] = { fg = C["bg"], bg = C["hint"], bold = true },
  ["@comment.note"] = { fg = C["bg"], bg = C["info"], bold = true },
  ["@markup.strong"] = { bold = true },
  ["@markup.italic"] = { italic = true },
  ["@markup.strikethrough"] = { strikethrough = true },
  ["@markup.underline"] = { underline = true },
  ["@markup.heading"] = { fg = C["function"], bold = true },
  ["@markup.quote"] = { fg = C["comment"], italic = true },
  ["@markup.math"] = { fg = C["boolean"] },
  ["@markup.link"] = { fg = C["info"] },
  ["@markup.link.label"] = { fg = C["field"] },
  ["@markup.link.url"] = { fg = C["info"], underline = true },
  ["@markup.raw"] = { fg = C["string"] },
  ["@markup.list"] = { fg = C["keyword"] },
  ["@markup.list.checked"] = { fg = C["string"] },
  ["@markup.list.unchecked"] = { fg = C["comment"] },
  ["@diff.plus"] = { fg = C["string"] },
  ["@diff.minus"] = { fg = C["error"] },
  ["@diff.delta"] = { fg = C["constant"] },
  ["@tag"] = { fg = C["keyword"] },
  ["@tag.builtin"] = { fg = C["keyword"] },
  ["@tag.attribute"] = { fg = C["parameter"] },
  ["@tag.delimiter"] = { fg = C["fg_muted"] },
  }

  -- LSP semantic tokens layer on top of Treesitter and win, so each one is
  -- linked explicitly. Skipping this is why themes look correct in one language
  -- and subtly wrong in the next.
  for from, to in pairs({
    ["@lsp.type.class"] = "@type",
    ["@lsp.type.comment"] = "@comment",
    ["@lsp.type.decorator"] = "@attribute",
    ["@lsp.type.enum"] = "@type",
    ["@lsp.type.enumMember"] = "@constant",
    ["@lsp.type.event"] = "@type",
    ["@lsp.type.function"] = "@function",
    ["@lsp.type.interface"] = "@type",
    ["@lsp.type.keyword"] = "@keyword",
    ["@lsp.type.macro"] = "@function.macro",
    ["@lsp.type.method"] = "@function.method",
    ["@lsp.type.modifier"] = "@keyword.modifier",
    ["@lsp.type.namespace"] = "@module",
    ["@lsp.type.number"] = "@number",
    ["@lsp.type.operator"] = "@operator",
    ["@lsp.type.parameter"] = "@variable.parameter",
    ["@lsp.type.property"] = "@property",
    ["@lsp.type.regexp"] = "@string.regexp",
    ["@lsp.type.string"] = "@string",
    ["@lsp.type.struct"] = "@type",
    ["@lsp.type.type"] = "@type",
    ["@lsp.type.typeParameter"] = "@type.definition",
    ["@lsp.type.variable"] = "@variable",
    ["@lsp.mod.readonly"] = "@constant",
    ["@lsp.mod.defaultLibrary"] = "@function.builtin",
    ["@lsp.typemod.function.defaultLibrary"] = "@function.builtin",
    ["@lsp.typemod.variable.defaultLibrary"] = "@variable.builtin",
    ["@lsp.typemod.variable.readonly"] = "@constant",
    ["@lsp.typemod.property.readonly"] = "@constant",
  }) do
    g[from] = { link = to }
  end

  return g
end

return M
