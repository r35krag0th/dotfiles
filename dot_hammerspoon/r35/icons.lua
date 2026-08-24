-- r35/icons.lua -- icon fetch and cache against the local icon service.
local log = require("r35.log")

local M = {}

local CACHE_DIR  = os.getenv("HOME") .. "/.hammerspoon/icon-cache"
local SERVICE    = "http://127.0.0.1:5555"

-- Where the last-seen font fingerprint (see M._fontFingerprint below) is
-- persisted, alongside the cached PNGs it governs. Deliberately a dotfile so
-- a plain `*.png` sweep of CACHE_DIR (see wipeCachedIcons below) never
-- touches it.
local FONT_FINGERPRINT_PATH = CACHE_DIR .. "/.fonts"

-- Every parameter that can change the rendered image, in the exact order
-- sent on the wire. buildQuery() below only ever sends fields named here, so
-- a param icon-service.py accepts but this list doesn't know about can never
-- be requested from Lua -- a real, deferred gap (reviewed, not solved here).
-- What IS now closed structurally: a param listed here is always both sent
-- and hashed together, because M.key() below hashes buildQuery()'s own
-- output rather than recomputing anything in parallel. There is no longer a
-- second computation that could disagree about what a field means, which is
-- what made D8 possible in the first place.
--
-- `default` documents icon-service.py's own behaviour when a field is
-- omitted from the request. It is reference only -- no code below reads it.
-- The client used to keep its own copy of these defaults to compute the
-- cache key; that copy disagreed with the server twice (font support
-- shipped with no key coverage at all, then the glyph defaults themselves
-- diverged). See M.key()'s comment for why the client no longer tries.
local PARAMS = {
  { name = "glyph",       default = "0000"   },
  { name = "glyph_color", default = "ffffff" },
  { name = "bg_color",    default = "141d3a" },
  { name = "glyph_size",  default = 48       },
  { name = "label",       default = ""       },
  { name = "label_color", default = "ffffff" },
  { name = "label_size",  default = 12       },
  { name = "font",        default = "glyph"  },
  { name = "glyph_font",  default = "glyph"  },
  { name = "weight",      default = ""       },
}

-- 64-bit FNV-1a. Pure Lua, no `hs` dependency -- this is what lets M.key()
-- (below) stay callable, and testable, under standalone Lua rather than
-- only inside Hammerspoon. Lua 5.3+ integers are 64-bit and wrap on
-- overflow, which is exactly the arithmetic FNV needs. Verified against the
-- canonical test vectors ("" -> cbf29ce484222325, "a" -> af63dc4c8601ec8c,
-- "foobar" -> 85944171f73967e8) -- see spec/icons_spec.lua.
local FNV_OFFSET = 0xcbf29ce484222325
local FNV_PRIME  = 0x100000001b3

local function fnv1a64(s)
  local h = FNV_OFFSET
  for i = 1, #s do
    h = h ~ s:byte(i)
    h = h * FNV_PRIME
  end
  return string.format("%016x", h)
end
-- Exposed only so spec/icons_spec.lua can pin it against the canonical FNV-1a
-- vectors directly. The underscore marks it as an internal implementation
-- detail, not part of the module's real API -- callers want M.key(), not this.
M._fnv1a64 = fnv1a64

-- M.key() hashes the REQUEST (see its comment below) and structurally cannot
-- see server-side state: which font FILE a logical name like "display"
-- resolves to. icon-service.py resolves that once at startup (FONT_CHAINS ->
-- RESOLVED_FONTS) and the only place it's ever visible from the client side
-- is /health's "fonts" map. checkHealth() below already fetches /health for
-- its own logging; this hashes just the "fonts" object out of that same
-- body -- via a balanced-brace match, not a whole-body hash -- so an
-- unrelated field added to /health later (a new "version" key, say) can
-- never cause a false cache invalidation.
--
-- Pure and `hs`-free like fnv1a64 above, for the same reason: it must stay
-- callable, and testable, under standalone Lua. Returns nil (not an error)
-- when the body doesn't contain a recognisable "fonts" object, so a
-- malformed or unexpected /health response degrades to "don't invalidate"
-- rather than crashing the health-check callback.
function M._fontFingerprint(body)
  if type(body) ~= "string" then return nil end
  local fonts = body:match('"fonts":%s*(%b{})')
  if not fonts then return nil end
  return fnv1a64(fonts)
end

-- Percent-encode everything except RFC 3986 unreserved characters
-- (A-Z a-z 0-9 - . _ ~). Pure Lua, deliberately not `hs.http.encodeForQuery`,
-- for the same reason as fnv1a64 above: buildQuery() uses this, M.key() uses
-- buildQuery(), and M.key() must stay usable under standalone Lua.
local function urlEncode(s)
  return (tostring(s):gsub("[^%w%-%.%_%~]", function(c)
    return string.format("%%%02X", c:byte())
  end))
end

-- The literal bytes sent to icon-service.py. M.key() below hashes this same
-- string -- that coupling is the entire point of this fix round; see its
-- comment.
local function buildQuery(opts)
  opts = opts or {}
  local parts = {}
  for _, p in ipairs(PARAMS) do
    local v = opts[p.name]
    if v ~= nil then
      table.insert(parts, p.name .. "=" .. urlEncode(tostring(v)))
    end
  end
  return table.concat(parts, "&")
end

-- One string, two uses: buildQuery() produces the exact bytes sent to the
-- icon service, and the cache key is derived from those same bytes by
-- hashing them. The key therefore CANNOT disagree with the request -- which
-- is what made D8 possible in the first place: a hand-maintained key that
-- mirrored a hand-maintained default table, and the two drifted twice (font
-- shipped with no key coverage at all; then the glyph defaults themselves
-- disagreed). Do not reintroduce a second parallel computation over PARAMS
-- to "simplify" this back to a plain field concatenation.
--
-- Semantic shift from the old key(): this key now matches the REQUEST, not
-- the RENDER. Omitting a parameter and passing its default explicitly
-- produce different querystrings -- and therefore different cache entries --
-- for what is visually an identical image. That is wasteful (an extra cache
-- miss the first time) but never wrong (never a mismatched image), which is
-- strictly safer than what it replaces. Do not "fix" this by normalising
-- opts against PARAMS' defaults before hashing -- that reintroduces the
-- exact drift risk this design exists to remove.
function M.key(opts)
  local query  = buildQuery(opts)
  local label  = tostring((opts or {}).label or "")
  local prefix = label:gsub("[^%w]", ""):sub(1, 12)
  if prefix == "" then prefix = "icon" end
  return prefix .. "_" .. fnv1a64(query)
end

function M.getIcon(opts, callback)
  opts = opts or {}
  callback = callback or function() end

  local path = CACHE_DIR .. "/" .. M.key(opts) .. ".png"
  if hs.fs.attributes(path) then
    callback(true, path)
    return
  end

  hs.http.asyncGet(SERVICE .. "/generate?" .. buildQuery(opts), {}, function(status, body)
    if status < 200 or status >= 300 then
      log.error("Icons", string.format("HTTP %s for %s", tostring(status), M.key(opts)))
      callback(false, nil)
      return
    end
    -- Write to a temp file and os.rename into place rather than writing
    -- `path` directly: os.rename is atomic on the same filesystem, so a
    -- process death mid-write can never leave a truncated file sitting at
    -- `path`. Without this, a truncated file poisons that cache entry
    -- permanently: hs.fs.attributes hits it, imageFromPath returns nil, the
    -- error is logged and the entry cleared, then the very next render hits
    -- the same corrupt file and repeats the cycle forever.
    local tmpPath = path .. ".tmp"
    local f = io.open(tmpPath, "wb")
    if not f then
      log.error("Icons", "could not write cache file " .. tmpPath)
      callback(false, nil)
      return
    end
    f:write(body)
    f:close()
    local renamed, renameErr = os.rename(tmpPath, path)
    if not renamed then
      log.error("Icons", string.format("could not rename %s into place: %s",
        tmpPath, tostring(renameErr)))
      os.remove(tmpPath)
      callback(false, nil)
      return
    end
    callback(true, path)
  end)
end

function M.setButtonIcon(deck, index, opts, callback)
  callback = callback or function() end
  M.getIcon(opts, function(ok, path)
    if not ok then
      -- Leave the button showing whatever it had. A blank button reads as a
      -- hardware fault; a stale one reads as "nothing happened", which is true.
      callback(false)
      return
    end
    local img = hs.image.imageFromPath(path)
    if not img then
      log.error("Icons", "could not load image " .. path)
      callback(false)
      return
    end
    deck:setButtonImage(index, img)
    callback(true)
  end)
end

function M.ensureCacheDir()
  hs.fs.mkdir(CACHE_DIR)
end

-- A zero-byte fingerprint file is treated the same as a missing one --
-- "unknown, re-evaluate" -- rather than as a match for nothing that would
-- silently skip the first real wipe. Logged (not just swallowed) because an
-- empty file getting there at all is itself a sign of previous corruption
-- (e.g. a write that got the open but not the write+close).
local function readFontFingerprint()
  local f = io.open(FONT_FINGERPRINT_PATH, "r")
  if not f then return nil end
  local content = f:read("*a") or ""
  f:close()
  if content == "" then
    log.warn("Icons", "font fingerprint file is empty; treating as unknown")
    return nil
  end
  return content
end

local function writeFontFingerprint(fp)
  local f = io.open(FONT_FINGERPRINT_PATH, "w")
  if not f then
    log.error("Icons", "could not write font fingerprint file " .. FONT_FINGERPRINT_PATH)
    return
  end
  f:write(fp)
  f:close()
end

-- Removes every cached *.png -- and ONLY *.png -- leaving the fingerprint
-- file (and anything else that might live in CACHE_DIR) untouched. Iterates
-- with hs.fs.dir/os.remove rather than shelling out to `rm`, matching the
-- rest of this module's no-shell-out convention (see M.getIcon's atomic
-- rename comment for the same instinct applied to writes).
--
-- MUST stay `for entry in hs.fs.dir(CACHE_DIR) do` -- hs.fs.dir (LuaFileSystem)
-- returns TWO values, an iterator function plus the directory object it
-- closes over, and Lua's generic `for` captures both automatically. Binding
-- the call to a local first (`local dir = hs.fs.dir(...)`) silently drops
-- that second value, so the loop then calls the iterator with no state and
-- LFS errors: "bad argument #1 to 'for iterator' (directory metatable
-- expected, got nil)". Caught live during kata#mw13 verification, not by
-- the standalone suite -- fake_hs.lua has no hs.fs.dir, so nothing there
-- could have exercised this path.
--
-- Returns true only if EVERY *.png was actually removed. os.remove returns
-- (nil, err) rather than raising, so a single failed entry would otherwise
-- pass silently through an unchecked loop -- the caller (syncFontFingerprint)
-- depends on this return value to decide whether it's safe to advance the
-- fingerprint past this wipe.
local function wipeCachedIcons()
  local ok, result = pcall(function()
    local allRemoved = true
    for entry in hs.fs.dir(CACHE_DIR) do
      if entry:sub(-4) == ".png" then
        local removed, removeErr = os.remove(CACHE_DIR .. "/" .. entry)
        if not removed then
          log.warn("Icons", string.format("could not remove cached icon %s: %s",
            entry, tostring(removeErr)))
          allRemoved = false
        end
      end
    end
    return allRemoved
  end)
  if not ok then
    log.error("Icons", "could not wipe icon cache: " .. tostring(result))
    return false
  end
  return result
end

-- Pure decision extracted out of syncFontFingerprint (below) so the
-- branching itself -- not the wipe/write side effects, which need
-- hs.fs.dir/io.open and stay live-verified -- is pinned down under the
-- standalone suite. Given the previously persisted fingerprint and the
-- newly computed one:
--   "noop"      -- fingerprints match, nothing to do.
--   "first-run" -- no fingerprint on disk yet; nothing stale to wipe, just
--                  record the baseline.
--   "wipe"      -- a real previous fingerprint disagrees with the new one;
--                  the cache is stale and must be cleared.
function M._fingerprintAction(prev, fp)
  if prev == fp then return "noop" end
  if prev == nil then return "first-run" end
  return "wipe"
end

-- The disk cache alone is not the whole story: Deck.rendered (in r35/deck.lua)
-- remembers, per button index, the key it last drew -- and M.key() is
-- unchanged by a font-resolution change, so render()'s diff would keep
-- suppressing every redraw even after the PNGs are gone. onFontsChanged is
-- the caller's hook to also blow away that in-memory state and repaint; see
-- init.lua, which passes `function() deck:invalidate(); deck:render() end`.
--
-- The fingerprint is written ONLY on "first-run" (nothing to wipe) or after
-- a "wipe" that fully succeeded -- never unconditionally. An advanced
-- fingerprint over a PARTIAL wipe is self-concealing: it leaves stale PNGs
-- on disk while asserting to every future run that fonts are unchanged and
-- there's nothing to retry -- silently reintroducing the exact bug this
-- fingerprint exists to prevent, permanently, with no further log line ever
-- pointing at it. Leaving the OLD fingerprint in place on a failed/partial
-- wipe is strictly worse for staleness in the short term (the stale PNGs
-- stay a bit longer) but it stays visible and gets retried on the next
-- health check, which is the trade this design deliberately takes.
local function syncFontFingerprint(body, onFontsChanged)
  local fp = M._fontFingerprint(body)
  if not fp then return end

  local prev = readFontFingerprint()
  local action = M._fingerprintAction(prev, fp)

  if action == "noop" then
    return
  end

  if action == "first-run" then
    writeFontFingerprint(fp)
    return
  end

  -- action == "wipe"
  log.info("Icons", "resolved fonts changed; wiping icon cache")
  local wiped = wipeCachedIcons()
  if onFontsChanged then onFontsChanged() end
  if not wiped then
    log.warn("Icons", "icon cache wipe was incomplete; leaving fingerprint unchanged so the next health check retries")
    return
  end
  writeFontFingerprint(fp)
end

-- Startup diagnostic, restoring what the original monolithic config's
-- check_icon_service() did: probe the icon service once at load time so a
-- dead service surfaces as one clear log line immediately, instead of only
-- ever showing up as repeated per-fetch "[r35.Icons][ERROR] HTTP ..." lines
-- once buttons start trying to render. Deliberately async (hs.http.asyncGet,
-- not the blocking hs.http.get) so a slow or dead service cannot delay config
-- load.
--
-- onFontsChanged, when given, fires when /health's resolved font map
-- differs from the last-seen fingerprint -- see syncFontFingerprint above.
function M.checkHealth(onFontsChanged)
  hs.http.asyncGet(SERVICE .. "/health", {}, function(status, body)
    if status and status >= 200 and status < 300 then
      log.info("Icons", "icon service healthy at " .. SERVICE)
      syncFontFingerprint(body, onFontsChanged)
    else
      log.warn("Icons", string.format("icon service health check failed: HTTP %s", tostring(status)))
    end
  end)
end

return M
