-- Generated. Hues come from the kitty candy tab bar palette; L and C are
-- redistributed per semantic role in OKLCH. See the derivation notes in
-- ~/.config/kitty/tab_bar.py for where the hues originate.
--
-- Two invariants hold this together, and breaking either will make the theme
-- fall apart in ways that are tedious to debug:
--
--   1. Every background stays below OKLab L=0.38 and every foreground above
--      L=0.62. That single rule makes legibility unconditional instead of
--      something patched pair by pair.
--   2. Grounds separate from each other by HUE, not lightness. Judge that with
--      OKLab dE, never with WCAG contrast -- contrast only measures luminance
--      and will call two obviously different hues identical.
--
-- CurSearch is the one deliberate exception to (1): it sets both fg and bg, so
-- it cannot inherit an unreadable foreground.

return {
  ["bg"] = "#0F1424",
  ["bg_gutter"] = "#101820",
  ["bg_cursorline"] = "#17232F",
  ["bg_float"] = "#202E3C",
  ["bg_visual"] = "#123A5D",
  ["bg_pmenu_sel"] = "#3D2F5E",
  ["bg_search"] = "#3C2A0D",
  ["bg_cursearch"] = "#FFBD4F",
  ["fg_cursearch"] = "#211300",
  ["bg_matchparen"] = "#004331",
  ["bg_diff_add"] = "#2A4339",
  ["bg_diff_delete"] = "#4B303C",
  ["bg_diff_change"] = "#463A30",
  ["bg_diff_text"] = "#1E426A",
  ["bg_vt_error"] = "#2A2130",
  ["bg_vt_warning"] = "#28272D",
  ["bg_vt_info"] = "#1C273C",
  ["bg_vt_hint"] = "#182934",
  ["bg_statusline"] = "#202E3C",
  ["bg_quickfix"] = "#17232F",
  ["border"] = "#465463",
  ["fg"] = "#C7D2DE",
  ["fg_muted"] = "#95A0AB",
  ["comment"] = "#8899AA",
  ["line_nr"] = "#596571",
  ["line_nr_active"] = "#CCC882",
  ["fg_statusline"] = "#8899AA",
  ["keyword"] = "#B89EFF",
  ["string"] = "#9AD387",
  ["function"] = "#8CC7FF",
  ["type"] = "#51DEEC",
  ["constant"] = "#F3B44A",
  ["boolean"] = "#FF9F68",
  ["parameter"] = "#F1A5D7",
  ["field"] = "#72D8B3",
  ["error"] = "#FF7D7D",
  ["warning"] = "#F7B33C",
  ["info"] = "#7FC1FF",
  ["hint"] = "#59CDA6",

  terminal = {
    "#101820",
    "#FF7D7D",
    "#8CD075",
    "#F3B44A",
    "#71BBFF",
    "#B89EFF",
    "#49D7E6",
    "#C7D2DE",
    "#6D7C8C",
    "#FFB4B1",
    "#A2EB88",
    "#EAE05E",
    "#ACD6FF",
    "#FFB1E5",
    "#83F4CC",
    "#EDF2F8",
  },
}
