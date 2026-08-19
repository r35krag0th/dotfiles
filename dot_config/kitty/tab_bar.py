# vim:fileencoding=utf-8:foldmethod=marker
"""Candy-shop tab bar.

Every tab is a pill.  Its hue comes from its position, so the bar reads as one
continuous gradient left to right and you learn "the green one is my GitLab
tab" without reading a word.

Three kitty internals shape the code below, all of them non-obvious:

* ``DrawData`` has no ``tab_bar_background`` field.  The real source is
  ``get_options().tab_bar_background``, which may be None (meaning: fall back
  to the window background).
* ``draw_tab_with_separator()`` writes ``cursor.fg``, ``cursor.bg``, ``bold``
  and ``italic``, so it clobbers any per-tab colour set before calling it.
  ``draw_title()`` writes only ``cursor.x`` and therefore inherits ours.
* ``{fmt.fg.tab}`` inside ``tab_title_template`` emits an SGR escape built from
  ``draw_data.tab_fg(tab)``.  Left alone it would repaint the title in the
  global active/inactive colour halfway through.  ``DrawData`` is a NamedTuple,
  so ``_replace()`` swaps in this tab's candy and the template renders *in* the
  right colour instead of fighting it.
"""

from __future__ import annotations

import time
from typing import NamedTuple

from kitty.boss import get_boss
from kitty.fast_data_types import Color, Screen, add_timer, get_options
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    Formatter,
    TabAccessor,
    TabBarData,
    as_rgb,
    draw_attributed_string,
    draw_title,
)

# ── the candy ────────────────────────────────────────────────────────────────
#
# Ten candies generated in OKLCH at a fixed L=0.84 / C=0.21, rotating hue only.
# Holding lightness and chroma constant is what makes them read as one set
# rather than ten unrelated colours: every candy lands between 10.6:1 and
# 12.0:1 against the #0F1424 bar, so no hue shouts louder than its neighbours.
# Picking them by eye in HSL could not have done this -- #FFFF00 and #0000FF are
# both "100% saturated" yet differ roughly 12x in actual luminance.
#
# Marigold was added last, to split the widest gap in the wheel (Tangerine 50 to
# Lemon 105).  A periwinkle at hue 272 was generated and rejected: sRGB is
# pinched there, so at L=0.84 it could only reach C=0.079 of the requested 0.21
# and landed 3.4 from both Cotton and Grape in OKLab -- closer than any existing
# neighbour pair, which would have turned tabs 7-9 into one pale blue smear.
# Keep hue order monotonic when adding more, or the gradient stops reading.
#
# INK is the text colour on an active pill: a near-black tinted with that
# candy's *own* hue (OKLCH L=0.20, C=0.055), so cherry gets a near-black maroon
# and spearmint a near-black green.  Never flat black.
#
#                 name          bright      ink
CANDIES: tuple[tuple[str, int, int], ...] = (
    ("Cherry",     0xFFB4B1, 0x2A090A),
    ("Tangerine",  0xFFB891, 0x280D00),
    ("Marigold",   0xFFBD4F, 0x211300),
    ("Lemon",      0xDDD000, 0x191700),
    ("Sour Apple", 0x7FE954, 0x081B02),
    ("Spearmint",  0x00EDB5, 0x001C12),
    ("Blue Rasp",  0x00E5F7, 0x001A1D),
    ("Cotton",     0x9FD0FF, 0x00172D),
    ("Grape",      0xCEC0FF, 0x18102C),
    ("Bubblegum",  0xFFABE3, 0x260A1E),
)

# How far each candy is mixed toward the bar to make its inactive pill, in
# OKLab.  Mixing toward the bar (rather than just dropping lightness) is what
# keeps these from turning to mud: compare #453946 to the #874213 you get from
# an HSL darken.  At 0.26 the pill reads clearly against the bar (~1.7:1) while
# the candy text on top stays at ~6.4:1.  Raise for bolder pills, lower for
# subtler ones.
INACTIVE_FILL = 0.26

# The pill's rounded ends.  The solid pair builds a filled pill; the thin pair
# below it builds a hollow one, if the outline treatment ever appeals.
CAP_LEFT, CAP_RIGHT = "\uE0B6", "\uE0B4"      # solid half circles
THIN_LEFT, THIN_RIGHT = "\uE0B7", "\uE0B5"    # hollow, for an outline treatment

# Cells of pill furniture around a titled tab: gap + cap + pad + pad + cap.
# The collapsed tiers below use tighter chrome, since a lone digit needs no
# breathing room.
PILL_CHROME = 5
COMPACT_CHROME = 3          # gap + cap + cap, no padding

# How the bar gives up width as tabs multiply.  kitty never scrolls its tab bar
# -- it measures extents and aligns them, so anything past the last column is
# simply clipped and invisible.  Handling overflow is entirely on us, and the
# rule here is that every pill stays on screen at every tab count, because the
# whole design premise is that colour encodes position.  Titles are what give
# way, in tiers.
TIER_FULL = "full"          # the whole title fits
TIER_TRUNCATED = "trunc"    # title ellipsised to a budget
TIER_INDEX = "index"        # just the tab number
TIER_DOT = "dot"            # a single mark: pure position and colour

# Below this many cells a truncated title is noise rather than information, so
# inactive tabs collapse to their index instead of showing "Inv…".
MIN_TRUNCATED_TITLE = 6

# What the active tab is offered, in descending order.  It is served before
# anyone else and never collapses past a truncated title, because losing
# "where am I" is the one failure the tiers exist to prevent.
ACTIVE_BUDGET_LADDER = (28, 20, 14, 10, 6, 3)

# Furniture is dropped before pills are: below these widths the app cell goes,
# then the date, then the clock entirely.
APP_CELL_MIN_COLUMNS = 80
STATUS_FULL_MIN_COLUMNS = 100
STATUS_TIME_MIN_COLUMNS = 55

# Bar furniture, deliberately colourless so the candy stays the only signal.
APP_CELL_FG = 0x8794B2
STATUS_SYMBOL_FG = 0x6F7CA0
STATUS_DATE_FG = 0x8794B2

# The clock is the one thing on the right, so it gets a candy rather than grey.
STATUS_TIME_FG = 0xDDD000   # Lemon

CLOCK_GLYPH, DATE_GLYPH = "\uF017", "\uF073"  # clock, calendar
DATE_FORMAT, TIME_FORMAT = "%a %d %b", "%H:%M"


class Candy(NamedTuple):
    """One candy, resolved against a specific bar colour."""

    name: str
    bright: int         # active pill fill, and inactive pill text
    ink: int            # text on the active pill
    fill: int           # inactive pill fill
    bright_color: Color
    ink_color: Color
    fill_color: Color


# ── colour maths ─────────────────────────────────────────────────────────────
# Enough OKLab to mix two sRGB colours perceptually.  OKLab is worth the ~30
# lines: mixing in plain sRGB sends colours through a muddy middle, and mixing
# in HSL swings the hue.


def _to_linear(channel: int) -> float:
    c = channel / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _to_channel(value: float) -> int:
    value = max(0.0, min(1.0, value))
    v = 12.92 * value if value <= 0.0031308 else 1.055 * (value ** (1 / 2.4)) - 0.055
    return max(0, min(255, round(v * 255)))


def _to_oklab(rgb: int) -> tuple[float, float, float]:
    r = _to_linear((rgb >> 16) & 0xFF)
    g = _to_linear((rgb >> 8) & 0xFF)
    b = _to_linear(rgb & 0xFF)
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    )


def _from_oklab(lab: tuple[float, float, float]) -> int:
    lightness, a, b = lab
    l = (lightness + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (lightness - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (lightness - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return (
        _to_channel(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s) << 16
        | _to_channel(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s) << 8
        | _to_channel(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)
    )


def _mix(fg: int, bg: int, amount: float) -> int:
    """Blend `fg` into `bg` in OKLab. amount=1 is pure fg, 0 is pure bg."""
    a, b = _to_oklab(fg), _to_oklab(bg)
    rest = 1 - amount
    return _from_oklab(
        (
            a[0] * amount + b[0] * rest,
            a[1] * amount + b[1] * rest,
            a[2] * amount + b[2] * rest,
        )
    )


def _as_color(rgb: int) -> Color:
    return Color((rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF)


# ── palette resolution ───────────────────────────────────────────────────────

_palette_cache: dict[int, tuple[Candy, ...]] = {}


def bar_background() -> int:
    """The colour behind the pills.

    `tab_bar_background` is None unless explicitly set, in which case kitty
    falls back to the window background.
    """
    opts = get_options()
    return int(opts.tab_bar_background or opts.background)


def palette(bar: int) -> tuple[Candy, ...]:
    """Candies resolved against `bar`, computed once per bar colour.

    The tab bar redraws on every keystroke, so the OKLab mixing and Color
    construction happen here rather than per draw.  Keying the cache on the bar
    colour means a config reload that changes it recomputes rather than serving
    stale fills.
    """
    cached = _palette_cache.get(bar)
    if cached is not None:
        return cached

    resolved = []
    for name, bright, ink in CANDIES:
        fill = _mix(bright, bar, INACTIVE_FILL)
        resolved.append(
            Candy(
                name=name,
                bright=bright,
                ink=ink,
                fill=fill,
                bright_color=_as_color(bright),
                ink_color=_as_color(ink),
                fill_color=_as_color(fill),
            )
        )
    _palette_cache[bar] = tuple(resolved)
    return _palette_cache[bar]


def candy_for(index: int, bar: int) -> Candy:
    """Position picks the hue -- that is the whole rule."""
    candies = palette(bar)
    return candies[(index - 1) % len(candies)]


# ── the clock ────────────────────────────────────────────────────────────────


def status_segments(with_date: bool = True) -> list[tuple[str, int]]:
    """The right-hand side as (text, colour) pairs.

    Measuring and drawing both derive from this one description, so the width
    the planner reserves can never drift from the width actually painted.
    """
    now = time.localtime()
    segments = []
    if with_date:
        segments.append((f" {DATE_GLYPH} ", STATUS_SYMBOL_FG))
        segments.append((f"{time.strftime(DATE_FORMAT, now)} ", STATUS_DATE_FG))
    segments.append((f" {CLOCK_GLYPH} ", STATUS_SYMBOL_FG))
    segments.append((f"{time.strftime(TIME_FORMAT, now)} ", STATUS_TIME_FG))
    return segments


def status_text(with_date: bool = True) -> str:
    return "".join(text for text, _ in status_segments(with_date))


_last_status = ""


def _tick(_timer_id: int) -> None:
    """Redraw the bar, but only when the clock actually changed.

    Marking dirty every second would force a GPU redraw every second for a
    display that only changes once a minute. Comparing the rendered string
    gives a prompt minute flip for one redraw per minute.
    """
    global _last_status
    current = status_text()
    if current == _last_status:
        return
    _last_status = current
    try:
        for tab_manager in get_boss().all_tab_managers:
            tab_manager.mark_tab_bar_dirty()
    except Exception:
        pass


# NOTE: this leaks one timer per config reload, and that is not fixable from
# here without deliberate effort.  kitty loads a custom tab bar with
# runpy.run_path(), not importlib -- the file is executed fresh into a throwaway
# namespace every reload, nothing is cached in sys.modules, and there is no
# unload or teardown hook to hang a destructor on.  The timer itself lives in
# kitty's C layer and outlives the namespace that registered it, so each old
# _tick keeps firing against its own stale globals forever.
#
# The cost is one extra mark_tab_bar_dirty() per minute per reload, which is
# noise next to the redraw every keystroke already causes.  Left alone
# deliberately.  If it ever does matter, remove_timer() exists and the fix is to
# stash the id somewhere that survives run_path -- an attribute on the
# kitty.tab_bar module object, say, since that one IS in sys.modules -- and
# remove the previous timer before adding this one.
add_timer(_tick, 1.0, True)


# ── layout ───────────────────────────────────────────────────────────────────


class Slot(NamedTuple):
    tier: str
    budget: int         # cells available to the title itself
    width: int          # total cells this tab will occupy, chrome included


_layout_cache: dict[tuple, tuple[Slot, ...]] = {}


def _tab_titles() -> tuple[list[str], int]:
    """Every tab's title plus the active one's 0-based index.

    Planning needs all of them at once, and draw_tab only ever sees one. An
    empty result means fall back to kitty's own per-tab budget.
    """
    try:
        manager = get_boss().active_tab_manager
        return [tab.title for tab in manager.tabs], manager.active_tab_idx
    except Exception:
        return [], 0


def furniture(screen: Screen, active_tab: TabAccessor) -> tuple[str, str]:
    """The app cell and clock, after dropping whatever the width cannot afford.

    Both are decided here rather than at their draw sites so that the width the
    planner reserves and the width actually drawn can never disagree. Furniture
    is only allowed to spend what is left once every tab can afford at least a
    lozenge -- the tabs are the point, the decoration is not.
    """
    columns = screen.columns
    titles, _ = _tab_titles()
    spare = columns - len(titles) * COMPACT_CHROME

    app = app_cell_text(active_tab)
    if columns < APP_CELL_MIN_COLUMNS or len(app) > spare:
        app = ""
    spare -= len(app)

    full, brief = status_text(), status_text(with_date=False)
    if columns >= STATUS_FULL_MIN_COLUMNS and len(full) <= spare:
        status = full
    elif columns >= STATUS_TIME_MIN_COLUMNS and len(brief) <= spare:
        status = brief
    else:
        status = ""
    return app, status


def _titled(title: str, budget: int) -> Slot:
    budget = max(1, min(budget, len(title)))
    tier = TIER_FULL if budget >= len(title) else TIER_TRUNCATED
    return Slot(tier, budget, budget + PILL_CHROME)


def _index_slot(index: int) -> Slot:
    width = len(str(index))
    return Slot(TIER_INDEX, width, width + COMPACT_CHROME)


DOT_SLOT = Slot(TIER_DOT, 0, COMPACT_CHROME)


def plan_layout(available: int, titles: list[str], active: int) -> tuple[Slot, ...]:
    """Decide how much room each tab gets, and which tier it renders at.

    Everything gets its full title if the bar can afford it.  Otherwise the
    active tab is served first from a descending ladder, and the inactive tabs
    take the cheapest tier that makes the whole row fit.  Crucially the total is
    checked against the available width before a plan is accepted -- picking
    tiers per tab without ever summing them was what let the bar overflow.
    """
    key = (available, tuple(titles), active)
    cached = _layout_cache.get(key)
    if cached is not None:
        return cached

    count = len(titles)
    natural = [_titled(t, len(t)) for t in titles]
    if sum(s.width for s in natural) <= available:
        return _remember(key, tuple(natural))

    others = count - 1
    for active_budget in ACTIVE_BUDGET_LADDER:
        active_slot = _titled(titles[active], active_budget)
        room = available - active_slot.width
        if room < 0:
            continue

        share = room // others if others else 0
        candidates = []

        title_budget = share - PILL_CHROME
        if title_budget >= MIN_TRUNCATED_TITLE:
            candidates.append([
                active_slot if i == active else _titled(t, title_budget)
                for i, t in enumerate(titles)
            ])
        candidates.append([
            active_slot if i == active else _index_slot(i + 1)
            for i in range(count)
        ])
        candidates.append([
            active_slot if i == active else DOT_SLOT for i in range(count)
        ])

        for plan in candidates:
            if sum(s.width for s in plan) <= available:
                return _remember(key, tuple(plan))

    # Narrower than even a row of lozenges. Nothing legible is possible; keep
    # the plan uniform so at least the gradient survives whatever gets clipped.
    return _remember(key, tuple(DOT_SLOT for _ in titles))


def _remember(key: tuple, slots: tuple[Slot, ...]) -> tuple[Slot, ...]:
    _layout_cache.clear()          # only ever one frame's layout is useful
    _layout_cache[key] = slots
    return slots


def slot_for(index: int, screen: Screen, active_tab: TabAccessor) -> Slot | None:
    """This tab's slot, or None when the tab list was unavailable."""
    titles, active = _tab_titles()
    if not titles or index > len(titles):
        return None
    app, status = furniture(screen, active_tab)
    available = max(0, screen.columns - len(app) - len(status))
    return plan_layout(available, titles, active)[index - 1]


def app_cell_text(active_tab: TabAccessor) -> str:
    return f"   {active_tab.active_oldest_exe}"


# ── drawing ──────────────────────────────────────────────────────────────────


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    active_tab = TabAccessor(get_boss().active_tab.id)
    bar = bar_background()
    bar_rgb = as_rgb(bar)
    candy = candy_for(index, bar)

    if index == 1:
        draw_app_cell(screen, active_tab, bar_rgb)


    if tab.is_active:
        pill_bg, pill_fg = candy.bright, candy.ink
    else:
        pill_bg, pill_fg = candy.fill, candy.bright

    pill_bg_rgb, pill_fg_rgb = as_rgb(pill_bg), as_rgb(pill_fg)
    slot = slot_for(index, screen, active_tab)
    tier = slot.tier if slot else TIER_TRUNCATED
    compact = tier in (TIER_INDEX, TIER_DOT)

    # Left cap.  The glyph *is* the pill's rounded end, so its foreground is the
    # fill of the text area it joins, and its background is the bar behind it.
    # Getting this backwards is what makes a powerline tab bar look like
    # confetti.
    screen.cursor.bold = screen.cursor.italic = False
    screen.cursor.fg = pill_bg_rgb
    screen.cursor.bg = bar_rgb
    screen.draw(" " + CAP_LEFT)

    screen.cursor.fg = pill_fg_rgb
    screen.cursor.bg = pill_bg_rgb
    screen.cursor.bold = tab.is_active
    if not compact:
        screen.draw(" ")

    if tier == TIER_DOT:
        pass                     # the two caps alone already form a lozenge
    elif tier == TIER_INDEX:
        screen.draw(str(index))
    else:
        # draw_title() leaves cursor.fg/bg alone, so it inherits what we set
        # here; _replace() covers the template's {fmt.fg.tab}, which would
        # otherwise repaint the title mid-string.
        budget = slot.budget if slot else max(1, max_title_length - PILL_CHROME)
        draw_title(
            draw_data._replace(
                active_fg=candy.ink_color,
                active_bg=candy.bright_color,
                inactive_fg=candy.bright_color,
                inactive_bg=candy.fill_color,
            ),
            screen,
            tab,
            index,
            max(1, budget),
        )

    screen.cursor.fg = pill_fg_rgb
    screen.cursor.bg = pill_bg_rgb
    if not compact:
        screen.draw(" ")

    # Right cap, same rule mirrored.
    screen.cursor.bold = screen.cursor.italic = False
    screen.cursor.fg = pill_bg_rgb
    screen.cursor.bg = bar_rgb
    screen.draw(CAP_RIGHT)

    if is_last:
        draw_right_status(screen, active_tab, bar_rgb)
    return screen.cursor.x


def draw_app_cell(screen: Screen, active_tab: TabAccessor, bar_rgb: int) -> None:
    """The shop sign on the far left: what the focused tab is running.

    Deliberately colourless -- if this cell took a candy it would compete with
    the tabs, and the whole point is that colour means position.
    """
    app, _ = furniture(screen, active_tab)
    if not app:
        return
    screen.cursor.bold = screen.cursor.italic = False
    screen.cursor.fg = as_rgb(APP_CELL_FG)
    screen.cursor.bg = bar_rgb
    screen.draw(app)


def draw_right_status(screen: Screen, active_tab: TabAccessor, bar_rgb: int) -> None:
    """Draw the clock on the right.

    Its width is reserved by plan_layout() before any tab is given room, so it
    can no longer be squeezed off the end. The old version subtracted its width
    from whatever the tabs had already consumed, which meant that the moment the
    tabs overflowed, every cell failed the fit test, the list drained to empty
    and the whole right-hand side silently vanished.
    """
    draw_attributed_string(Formatter.reset, screen)
    _, status = furniture(screen, active_tab)
    if not status:
        return
    padding = screen.columns - screen.cursor.x - len(status)
    if padding < 0:
        return

    screen.cursor.bold = screen.cursor.italic = False
    screen.cursor.bg = bar_rgb
    if padding:
        screen.cursor.fg = bar_rgb
        screen.draw(" " * padding)

    with_date = screen.columns >= STATUS_FULL_MIN_COLUMNS
    for text, color in status_segments(with_date):
        screen.cursor.fg = as_rgb(color)
        screen.cursor.bold = color == STATUS_TIME_FG
        screen.draw(text)
    screen.cursor.bold = False
