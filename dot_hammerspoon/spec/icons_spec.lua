local t = require("spec.runner")
local hsFake = require("spec.fake_hs")
_G.hs = hsFake

local icons = require("r35.icons")

t.describe("icons.key", function()
  -- D8 regression. The original params_to_key covered glyph, colours and label
  -- but NOT font, so the first render in a new font silently returned the old
  -- font's cached PNG. Same function now serves cache path AND render diffing,
  -- so the two cannot drift apart again.
  t.it("changes when only the font changes", function()
    local a = icons.key({ label = "11", font = "display" })
    local b = icons.key({ label = "11", font = "glyph" })
    if a == b then error("font must affect the key: both were " .. a) end
  end)

  t.it("changes when only the glyph font changes", function()
    local a = icons.key({ glyph = "f131", glyph_font = "glyph" })
    local b = icons.key({ glyph = "f131", glyph_font = "display" })
    if a == b then error("glyph_font must affect the key") end
  end)

  -- Fix round 1: weight is a render-affecting param (variable-font instance,
  -- e.g. "Black" for the clock tiles) and was found missing from PARAMS --
  -- exactly the D8 shape this task exists to prevent. This test pins it in.
  t.it("changes when only the weight changes", function()
    local a = icons.key({ label = "11", font = "display", weight = "Black" })
    local b = icons.key({ label = "11", font = "display", weight = "Regular" })
    if a == b then error("weight must affect the key: both were " .. a) end
  end)

  t.it("is stable for identical input", function()
    local o = { glyph = "f131", label = "MUTE", font = "display" }
    t.assertEquals(icons.key(o), icons.key(o))
  end)

  t.it("changes when the label changes", function()
    local a = icons.key({ label = "11" })
    local b = icons.key({ label = "12" })
    if a == b then error("label must affect the key") end
  end)

  t.it("produces a filesystem-safe key", function()
    local k = icons.key({ label = "A/B C", font = "display" })
    if k:find("[/ ]") then error("key must not contain / or space: " .. k) end
  end)

  -- Fix round 2, Finding 1 (CRITICAL): the sanitizer collapsed every
  -- disallowed byte to the same "_", so distinct labels produced identical
  -- keys and the second request silently served the first request's cached
  -- PNG -- D8's exact failure mode, reproduced inside the function built to
  -- prevent D8. "produces a filesystem-safe key" above only checked the
  -- output *looked* safe; it never checked the mapping was injective, which
  -- is why this survived. These pairs must map to DISTINCT keys.
  t.it("does not collide distinct labels onto the same key", function()
    local function assertDistinct(labelA, labelB)
      local ka = icons.key({ label = labelA })
      local kb = icons.key({ label = labelB })
      if ka == kb then
        error(string.format("collision: %q and %q both key to %s", labelA, labelB, ka))
      end
    end

    assertDistinct("A/B", "A B")
    assertDistinct("A:B", "A;B")
    assertDistinct("IN USE!", "IN USE?")
    -- Multi-byte UTF-8 case: U+2019 (RIGHT SINGLE QUOTATION MARK, used in
    -- init.lua's "Bob\xE2\x80\x99s iPhone Camera") vs U+2018 (LEFT SINGLE
    -- QUOTATION MARK) -- both 3-byte sequences of non-%w bytes, so a
    -- byte-wise "collapse every disallowed byte to _" sanitizer maps both to
    -- the same three underscores.
    assertDistinct("Bob\xE2\x80\x99s", "Bob\xE2\x80\x98s")
  end)
end)

-- Fix round 3: key() now derives from a pure-Lua 64-bit FNV-1a hash of the
-- literal querystring (see M.key()'s comment for why). Pinning the hash
-- function against the canonical published FNV-1a test vectors means a
-- future "let's swap in a nicer hash" refactor cannot silently change every
-- cache key without this test catching it.
t.describe("icons._fnv1a64 (hash vectors)", function()
  t.it("matches the canonical FNV-1a 64-bit test vectors", function()
    t.assertEquals(icons._fnv1a64(""), "cbf29ce484222325")
    t.assertEquals(icons._fnv1a64("a"), "af63dc4c8601ec8c")
    t.assertEquals(icons._fnv1a64("foobar"), "85944171f73967e8")
  end)
end)

-- The cache key (M.key, above) is a pure function of the REQUEST and
-- structurally cannot see server-side state: which font file a logical name
-- like "display" resolves to. That's resolved once at icon-service.py
-- startup and only ever surfaces via /health's "fonts" map. M._fontFingerprint
-- hashes just that map (not the whole /health body) so that an unrelated
-- field added to /health later can never cause a false cache invalidation.
-- Kept underscore-prefixed and pure -- no `hs` access -- for the same reason
-- as M._fnv1a64: it must stay callable, and testable, under standalone Lua.
t.describe("icons._fontFingerprint", function()
  local SAMPLE_BODY = '{"fonts":{"display":"/Users/x/Library/Fonts/Aldrich-Regular.ttf",' ..
    '"glyph":"/Users/x/Library/Fonts/PragmataProVF_liga_09.ttf"},"status":"ok"}'

  t.it("hashes only the fonts object, not the whole body", function()
    local fontsOnly = '{"display":"/Users/x/Library/Fonts/Aldrich-Regular.ttf",' ..
      '"glyph":"/Users/x/Library/Fonts/PragmataProVF_liga_09.ttf"}'
    t.assertEquals(icons._fontFingerprint(SAMPLE_BODY), icons._fnv1a64(fontsOnly))
  end)

  t.it("changes when a resolved font path changes", function()
    local orbitronBody = '{"fonts":{"display":"/Users/x/Library/Fonts/Orbitron-Regular.ttf",' ..
      '"glyph":"/Users/x/Library/Fonts/PragmataProVF_liga_09.ttf"},"status":"ok"}'
    local a = icons._fontFingerprint(SAMPLE_BODY)
    local b = icons._fontFingerprint(orbitronBody)
    if a == b then error("fingerprint must change when a resolved font path changes: both were " .. a) end
  end)

  t.it("is stable for identical fonts maps", function()
    t.assertEquals(icons._fontFingerprint(SAMPLE_BODY), icons._fontFingerprint(SAMPLE_BODY))
  end)

  t.it("is unaffected by unrelated fields added elsewhere in the body", function()
    local withExtra = '{"fonts":{"display":"/Users/x/Library/Fonts/Aldrich-Regular.ttf",' ..
      '"glyph":"/Users/x/Library/Fonts/PragmataProVF_liga_09.ttf"},"status":"ok","extra":{"nested":"field"}}'
    t.assertEquals(icons._fontFingerprint(SAMPLE_BODY), icons._fontFingerprint(withExtra))
  end)

  t.it("returns nil when the body has no fonts field", function()
    t.assertNil(icons._fontFingerprint('{"status":"ok"}'))
  end)

  t.it("returns nil for a non-string body", function()
    t.assertNil(icons._fontFingerprint(nil))
  end)
end)

-- Review finding (kata#mw13, round 2): syncFontFingerprint used to write the
-- new fingerprint unconditionally after attempting a wipe, even when the
-- wipe failed or only partly succeeded. That's self-concealing -- a stale
-- PNG left behind by a failed os.remove would sit there FOREVER, because
-- the advanced fingerprint tells every future run "fonts unchanged, nothing
-- to do". M._fingerprintAction is the pure decision extracted out of that
-- function so the branching (not the wipe/write side effects themselves,
-- which need hs.fs.dir/io.open and stay live-verified) is pinned down here:
-- syncFontFingerprint must persist the new fingerprint on "first-run"
-- unconditionally, but on "wipe" only after confirming the wipe fully
-- succeeded -- never unconditionally.
t.describe("icons._fingerprintAction", function()
  t.it("is a no-op when the fingerprint is unchanged", function()
    t.assertEquals(icons._fingerprintAction("abc123", "abc123"), "noop")
  end)

  t.it("is a first-run when there is no previous fingerprint", function()
    t.assertEquals(icons._fingerprintAction(nil, "abc123"), "first-run")
  end)

  t.it("requires a wipe when the fingerprint changed from a real previous value", function()
    t.assertEquals(icons._fingerprintAction("abc123", "def456"), "wipe")
  end)
end)
