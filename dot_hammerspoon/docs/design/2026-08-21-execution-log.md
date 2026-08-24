# SDD ledger — plan: /Users/bobsaska/.hammerspoon/docs/plans/2026-08-21-streamdeck-refactor.md

Spec: /Users/bobsaska/.hammerspoon/docs/design/2026-08-21-streamdeck-refactor.md
Tracking: kata#wbyy

## Harness adaptation (no git repository)

`~/.hammerspoon` is not a git repo; `git init` was explicitly declined by the user.
The SDD skill assumes git throughout (worktrees, `git rev-parse HEAD`, BASE..HEAD diffs).
Adapted as follows:

- `scripts/sdd-workspace` unusable (needs a repo root) -> workspace is this directory.
- `scripts/review-package` unusable (git diff) -> `hs-review-pkg BASE_SNAP HEAD_SNAP OUT`
  builds an equivalent package via `diff -ruN -U10` between snapshot trees.
- `scripts/task-brief` works unchanged via its explicit-OUTFILE third argument.
- Commits -> snapshots. `hs-snap DEST` copies the config source tree.
- No worktree isolation available. User has explicitly authorised working in place.

Ruling: proceed without git. Cost if wrong: no atomic revert; mitigated by a
pre-task snapshot before every dispatch plus the known-good pre-work snapshot.

## Pre-flight conflict scan

| #   | Tasks / scope  | Produces vs consumes                                                                   | Finding                                                                          |
| --- | -------------- | -------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| 1   | T1 -> T9       | `r35.ipc.start()`; T1 adds the require to init.lua, T9 rewrites init.lua               | OK — T9's rewrite retains the require                                            |
| 2   | T2 -> T9       | T2 Step 6 writes a launchd comment block into init.lua; T9 replaces init.lua wholesale | **CONFLICT** — documentation silently lost                                       |
| 3   | T3 -> T4,6,7,8 | `spec/all.lua` SUITES list appended by each                                            | OK — sequential appends, no collision                                            |
| 4   | T3 -> T4-T8    | `log.info/warn/error(tag, msg)`                                                        | OK — signature consistent at every call site                                     |
| 5   | T4 -> T5,7,8   | `announce/revoke/update/on/whenAvailable/get`                                          | OK — all six defined in T4, all uses match                                       |
| 6   | T5 -> T9       | `.start(registry)`, `.start(registry, devices.cameras)`                                | OK — arities match init.lua                                                      |
| 7   | T5 -> T9       | registry keys `camera:<name>`, `audio.in:default`                                      | OK — layout.lua watches exactly these strings                                    |
| 8   | T6 -> T7       | `icons.key(opts)`, `icons.setButtonIcon(deck,i,opts)`                                  | OK — deck stub mirrors both signatures                                           |
| 9   | T6 -> T9       | `icons.ensureCacheDir()`                                                               | OK — defined T6, called T9                                                       |
| 10  | T7 -> T9       | `Deck.new/bind/attach/detach/render/press/invalidate/setPage`                          | OK — all eight defined in T7                                                     |
| 11  | T8 -> T9       | `clock.fields()` keys vs `f[field]` lookups in clockTile                               | OK — weekday/month/day/hour/minute/meridiem all present                          |
| 12  | T8 -> T9       | `actions.sendTo(bundle,mods,key,desc)`, `actions.bindHotkey`                           | OK — arities match                                                               |
| 13  | **T9 -> T6**   | layout clockTile sends `glyph = ""` to the icon service                                | **CONFLICT** — service 500s on empty glyph                                       |
| 14  | T6 self        | `stream-deck-icons.lua` deletion listed in T6 files but performed in T9 Step 6         | OK — T6 does not delete; note only                                               |
| 15  | T9 self        | init.lua orders `deck:bind()` before device start; clock announces after streamdeck    | OK — clockTile falls back to `clock.fields()`; render no-ops while device is nil |
| 16  | T3 self        | tests specified vs code specified; cumulative counts 13/18/28/36                       | OK — arithmetic checks out                                                       |

## Rulings

Ruling 1 (row 2): T9's `init.lua` rewrite MUST retain the launchd comment block that
T2 Step 6 installs. Reason: T2's deliverable is partly documentation (D6 — the stale
`com.r35.icon-service` instructions were themselves the defect), and T9 would delete it
in the same plan that added it. Carried into the T9 dispatch.
Cost if wrong: the launchd operational notes are lost and D6's documentation half regresses.

Ruling 2 (row 13): T6 MUST make the icon service render text-only tiles. Confirmed live
against the running service, not inferred:
curl "http://127.0.0.1:5555/generate?label=11&glyph=" -> HTTP 500
{"error":"invalid literal for int() with base 16: ''"}
`int(glyph_hex, 16)` raises on an empty string. All six clock tiles would 500.
Two changes required, both in T6:
(a) an absent or empty `glyph` skips glyph rendering entirely rather than raising;
(b) with no glyph, the label centres in the full 96x96 tile instead of being pinned
5px from the bottom (`label_y = size - 5 - label_bbox[3]`), which would jam the
clock digits against the bottom edge.
Carried into the T6 dispatch.
Cost if wrong: six clock tiles render blank or bottom-jammed; caught immediately at T9 Step 5.

## Progress

Briefs extracted for all 10 tasks; each verified to begin with its own task heading.
Baseline snapshot: base-task01 (6 files) — the pre-refactor known-good state.

Task 1: dispatched (sonnet) — IPC bootstrap + D11 live diagnosis.
Dispatch carried: no-git adaptation (hs-snap replaces commit), the dead
`local log = { }` removal, and instructions not to overclaim on D11.

Task 1: report DONE_WITH_CONCERNS. IPC gate PASSED (`echo 'return 1+1' | hs` -> 2,
re-confirmed independently by controller). Files: r35/ipc.lua (new), init.lua (+1),
spec D11 section rewritten. Concern: D11's DEGRADATION mode unresolved.

Ruling 3: Microsoft Teams is NOT installed on this machine (spectra) — confirmed by
controller via /Applications and mdfind. The user stated this config is "largely used
at work", so Teams lives on the work laptop only. Consequences: - Task 1's D11 diagnosis is necessarily partial. The TYPE mismatch is confirmed
(applicationsForBundleID returns a table; keyStroke documents an application
object; passing the table raises no Lua error, so the mismatch is silent).
The DELIVERY consequence cannot be observed without the target app. - Task 8 Step 6 and Task 10 Step 4 both verify targeted send against Teams.
Neither is executable here.
Decision: the D11 code fix (`apps[1]`) stands on the documented API contract and does
not need Teams to justify it. Task 8 and Task 10 substitute a target application that
IS installed, proving the MECHANISM (keystroke reaches a named, unfocused app) rather
than Teams specifically. Teams-specific verification is deferred to the work laptop and
recorded as such in the spec.
Cost if wrong: the mechanism works but some Teams-specific quirk defeats it; surfaces
on first real use at work, and the fix is localised to actions.sendTo.

Also noted: the Task 1 implementer declined to live-fire a keystroke because the
frontmost app was the terminal hosting its own session. Correct judgement — an
eventtap aimed at one's own controlling terminal is a genuine footgun.

Ruling 2 AMENDED (user direction, mid-flight): default `glyph` to "0000" when absent
or empty, rather than branching on "no glyph". Verified live by controller:
curl ".../generate?glyph=0000&label=11" -> HTTP 200
and the rendered PNG shows U+0000/.notdef draws NOTHING (no hollow box) in
PragmataPro. This is already the user's own convention — init.lua:23 writes
`glyph = "0000"` for button 17. Simpler than the skip-branch and matches existing style.

Part (b) of the original ruling STANDS and is now visually confirmed: with glyph=0000
the label is still pinned 5px from the bottom (`label_y = size - 5 - label_bbox[3]`),
so the clock digits render small and bottom-jammed instead of owning the tile.
T6 must centre the label vertically when the glyph resolves to codepoint 0.
Using codepoint 0 as the single sentinel keeps one convention doing both jobs.
Cost if wrong: clock tiles look wrong but function; cosmetic, caught at T9 Step 5.

Task 1: review -> Spec OK, quality Approved. 1 Important, 2 Minor, 3 cannot-verify.
Controller resolved all three cannot-verify items directly:
(a) ~/.local/bin EXISTS and is on PATH (position 82) — so it is a valid target.
(b) Branch taken: /opt/homebrew/bin/hs exists, so binaryPresent() short-circuits at
prefix #2 and the cliInstall fallback loop never ran. Reviewer was correct.
(c) cliInstall does NOT create intermediate dirs. Tested against an empty prefix:
hs.ipc.cliInstall("/tmp/clitest", true) -> returned=false
ls -laR /tmp/clitest -> nothing created
(c) escalates the Important finding from "unverified path" to a CONFIRMED DEFECT:
on the work laptop (no Homebrew, /usr/local not writable, ~/.local/bin possibly absent)
all three prefixes fail and the module installs nothing while returning true. The one
environment the module exists for is the one where it silently no-ops.

Task 1: fix round 1/5 dispatched (resumed original implementer).
Findings sent: (1) Important — ensure <prefix>/bin exists before cliInstall, with live
before/after evidence required, hs.fs.mkdir is not recursive; (2) Minor — file comment
claims the module "ensures a CLI binary exists" while the WARN path returns true having
installed nothing; fix the comment, not the contract.
Ruling 4: folded a Minor into this round because it edits the same lines the Important
fix touches. Skill says minors defer to the ledger; splitting them here would mean a
second dispatch over the same three lines. Cost if wrong: negligible.
Minor deferred (not in loop): reviewer noted apparent brief drift re a `local log = {}`
line my dispatch told the implementer to omit. Explained — I removed it from the plan
during self-review before briefs were generated, so the brief never contained it. The
reviewer flagging an instruction it could not see is correct behaviour, not an error.

Ruling 5 (controller process defect, self-inflicted): my fix-round instruction told the
implementer to re-snapshot to the SAME path (head-task01), overwriting the pre-fix
state. The skill's scoped re-review wants FIX_BASE..HEAD — the isolated fix diff — and
I destroyed FIX_BASE. For this round the re-reviewer gets the full task diff
(base-task01 -> head-task01) with the two findings named explicitly; sufficient here
because the fix is one file and the final state shows both findings resolved.
CONVENTION CORRECTED for all later tasks: fix rounds snapshot to head-task<NN>-fix<R>,
never overwriting the reviewed head. Cost of this instance: the re-review sees the whole
task rather than just the fix, so it may re-raise settled points; cheap to adjudicate.

Task 1: fix round 1/5 — implementer reports both findings fixed with live evidence.
Controller independently verified: /opt/homebrew/bin/hs symlink intact; gate
`echo 'return 1+1' | hs` -> 2; no throwaway prefixes left behind; ensureDir walks
path components (hs.fs.mkdir is not recursive) and tolerates the mkdir-lost-race case;
header comment now says "best-effort ... only attempted" rather than "ensures".
Task 1: fix round 1/5 re-review — 2 addressed, 0 open, no new breakage.
Task 1: complete (snapshots base-task01..head-task01, review clean).
Deferred minor (for final review triage): the permission-denied path at root-owned
/usr/local is reasoned-about but never live-tested. Control flow makes it provably
non-crashing (hs.fs.mkdir returns false,err rather than raising), so this is coverage
completeness, not a suspected fault.

Task 2: dispatching (sonnet) — launchd plist rename + $HOME portability (D6, D7).
Touches live system state: ~/Library/LaunchAgents, launchctl bootout/bootstrap.
Authorised by the user's approval of the plan, which specifies these steps verbatim.
Pre-work snapshot holds the original plist for restore.

Task 2: report DONE. Controller independently verified before review:
launchctl list -> "11896 0 net.r35.icon-service" (old com.r35.* label gone);
LaunchAgents entry is a symlink to ~/.hammerspoon/launchd/;
grep -c "/Users/bobsaska" on the new plist -> 0 (D7 satisfied);
/health responds; net.r35.mcp-hub.plist untouched; Task 1's ipc.lua + init.lua
require line intact. Review dispatched (sonnet).
Task 2: review -> Spec OK, quality Approved. 0 Critical/Important, 2 Minor. No fix loop.
Task 2: minor (deferred): report quoted only the changed keys of the original plist, so
its "KeepAlive/ProcessType/ThrottleInterval unchanged" claim was not evidenced in the
report itself; the reviewer verified it externally and it holds.
Task 2: minor (deferred): the log path assumes ~/Library/Logs exists. The install step
does `mkdir -p`, but the init.lua "Start" comment run standalone on a fresh account
would not. macOS creates that directory by default, so low risk.
Task 2: complete (snapshots base-task02..head-task02, review clean).
Note: the reviewer verified the original plist's unchanged keys against a fixture it
found at ~/Downloads/2026-08-21_snapshot/... — outside the artifacts I supplied. Read-only
and the claim it verified is real, so no action; recorded for transparency.

Task 3: dispatching (sonnet) — test harness + logger. Foundational: tasks 4, 6, 7 and 8
all TDD against this harness, so correctness here is load-bearing. Chose sonnet over the
cheapest tier despite the brief containing complete code, because Step 7 (deliberately
break a test, confirm RED, then revert) is a judgement step and a harness that cannot
report failure is worse than none.

Task 3: report DONE_WITH_CONCERNS — implementer flagged that `lua` here is 5.5.0 while
the task constraints say 5.4. Investigated and confirmed:
/opt/homebrew/bin/lua -v -> Lua 5.5.0
echo 'return _VERSION' | hs -> Lua 5.4 (Hammerspoon's actual embedded runtime)
available binaries -> lua-5.1, lua-5.5 only; no 5.4
brew info lua@5.4 -> installable, keg-only 5.4.8, not installed
Controller also verified the modules load under the REAL runtime via IPC:
"Lua 5.4 | r35.log=OK r35.ipc=OK"
Harness independently re-verified green by controller: "2 passed, 0 failed", exit 0.

Ruling 6: do NOT install lua@5.4, despite it being one brew command away and keg-only.
The "no new packages" constraint is the spine of this project — the user built this
whole thing to avoid installing software — and spending that principle on test tooling
is the wrong trade. Tests run on 5.5; the code uses only long-stable stdlib; and the
controller runs a `require` load-smoke under real 5.4 via IPC after each task, which
catches genuine incompatibility at load time.
Cost if wrong: a 5.4-vs-5.5 behavioural difference passes tests and fails in
Hammerspoon. Mitigated by the per-task IPC load-smoke and, ultimately, by Task 9's
live cutover, which exercises everything under the real runtime.
NOTE: this is a decision made on the user's behalf about their machine. Surfaced to
them explicitly; installing lua@5.4 remains one command away if they prefer fidelity.

Task 3: fix round 1/5 dispatched (resumed implementer). Finding: runner's summary line
must name the interpreter via _VERSION, because "36 passed" that does not say which
Lua produced it is precisely how skew hides. Re-confirmation of the red path required,
since the fix edits the function that reports it. Snapshot to head-task03-fix1 (new
path — Ruling 5 convention now in force).
Task 3: fix round 1/5 — implementer reports done. Controller verified independently:
`lua spec/all.lua` -> "2 passed, 0 failed (Lua 5.5)", exit 0; `mise run test` same;
load-smoke under real runtime -> "Lua 5.4 r35.log=true".
Ruling 5's convention worked: head-task03 and head-task03-fix1 both retained, so a
properly scoped fix diff exists this time (10 changed lines).
Task 3: full task review dispatched (sonnet). Note this task had NOT been reviewed before
the fix round — the DONE_WITH_CONCERNS path sent me to address correctness first, per
the skill. The review therefore covers the whole task including the fix.
Reviewer directed hardest at the one question that matters: can the runner report green
when it should report red? Everything downstream TDDs against it.
Task 3: review -> Spec OK, quality Approved. 0 Critical/Important, 3 Minor.
Reviewer confirmed the harness genuinely fails: fail() -> error(msg,3) -> xpcall in
M.it -> M.failed++ -> report() returns 1 -> os.exit(1). Cross-validated the red/green
transcripts against real line numbers in the diff (not fabricated output).
Cannot-verify item RESOLVED by controller: .mise/tasks/test is -rwxr-xr-x.
Minor 3 ("stopped" one-shot doAfter still fires on flush) RESOLVED, not deferred: - registry discards doAfter's return value entirely (task-4-brief.md:206), never cancels - deck uses doAfter zero times - clock uses doEvery, which fake_hs DOES honor .stopped for
So the asymmetry is real but inert for every consumer in this plan.
Minor 1 (describe() does not stack _suite) and Minor 2 (error level 3 assumes assertions
are called directly from an it() body) deferred for final-review triage. Both are
defects in MY plan's code, not implementer deviations. Neither bites unless a later
spec nests describe() or wraps assertions in a helper — flag if that appears.
Task 3: complete (snapshots base-task03..head-task03-fix1, review clean).

Task 4: dispatching (sonnet) — the Registry. This is the centrepiece: the module the user
explicitly asked for help getting right, and the fix for D1/D2/D9. TDD is mandatory and
RED evidence is required before implementation.

Task 4: report DONE (13 passed, RED observed first). Controller verified independently:

- suite green, 13 passed 0 failed, exit 0
- registry loads AND instantiates under the real runtime:
  "Lua 5.4 registry.new()=table methods=function/function/function"
- MUTATION TEST on a throwaway copy (real config untouched), to prove the tests
  are not vacuous:
  mutate whenAvailable to dispatch synchronously -> 11 passed, 2 FAILED
  strip the xpcall error isolation -> 12 passed, 1 FAILED
  So the async-dispatch guarantee (D1/Zalgo) and the isolation guarantee (D9) are
  both genuinely covered, not merely asserted.
  Controller observation NOT passed to the reviewer (to avoid biasing it): the D9
  isolation test emits a full 13-line stack traceback into the middle of otherwise clean
  test output. It is expected output from a test that deliberately throws, but it makes
  the suite noisy and would camouflage a real traceback later. If the review does not
  raise it, I will add it as a controller finding.
  Task 4: review -> Spec OK, quality Approved WITH 2 Important + 2 Minor.
  Important 1: update() sets devices[key] but never drains pending[key]. Any
  whenAvailable registered before an update-on-unknown-key is stranded permanently,
  while get(key) returns non-nil and NEW whenAvailable calls fire immediately. This is
  a defect in MY plan's registry design, not an implementer deviation. The invariant I
  failed to hold: every nil -> non-nil transition of devices[key] must drain pending;
  two functions cause that transition and only announce honours it.
  Not live today (audio adapter guards with get()==nil; clock announces before updating)
  so it is a latent trap for future code.
  Important 2: the mid-dispatch test asserts only get()~=nil, never that the newly
  registered handler fires or when; and update-before-announce had zero coverage, which
  is exactly why Important 1 survived.
  Minor 3 (folded): _emit's comment states mutation is safe but not the OUTCOME
  (next-emit firing) that Important 2 will now assert. Same lines.
  Minor 4 (folded): D9 test's deliberate error prints a production-shaped traceback into
  test output. Controller had independently spotted this and withheld it from the
  reviewer to avoid biasing; the reviewer found it unprompted. Fix in the test (swap
  log.error for a no-op around the assertion), NOT by adding a silencing API to
  production log.lua.
  Ruling 7: folded both Minors into the round. Skill says minors defer, but #3 edits the
  exact comment #2's test makes assertable, and #4 edits the same spec file. Splitting
  would mean a second dispatch over the same two files. Cost if wrong: negligible.

Task 4: fix round 1/5 dispatched (resumed implementer). RED required first for the
update-before-announce regression test, so there is evidence it catches the bug.
Suite total will exceed 13; implementer told to report the ACTUAL count, not force one.
Task 4: fix round 1/5 — implementer reports 14 passed, RED first. Controller verified:

- real suite: "14 passed, 0 failed (Lua 5.5)", exit 0, and output now CLEAN (14
  unbroken dots, the D9 traceback is gone)
- MUTATION on a throwaway copy: reverted update() to skip _drainPending ->
  "13 passed, 1 failed". The regression test genuinely catches the bug it was
  written for; it is not a test that passes regardless.
  Task 4: fix round 1/5 re-review -> 4 addressed, 0 open, no new breakage. Re-reviewer
  specifically confirmed _drainPending preserved the original re-entrancy ordering at
  BOTH call sites, event semantics unchanged, drain still inside _safeCall, and that the
  log.error restore cannot leak (restore sits outside any block that can throw).
  Task 4: complete (snapshots base-task04..head-task04-fix1, review clean).
  Closes D1 (inverted doUntil), D2 (single global callback slots), D9 (no error
  isolation), plus the update()-strands-pending defect found during review.

Task 5: dispatching (sonnet) — device adapters (streamdeck / camera / audio).
Closes D3 (method on dead object), D4 (devices present at startup never announced),
D5 (audiodevice.current returns OUTPUT), D10 (buttonLayout two-value expansion).
SAFETY NOTE carried into the dispatch: brief Step 6 wants the undocumented
hs.audiodevice.watcher event codes observed by changing the default input device.
That is scriptable via hs.audiodevice.setDefaultInputDevice, but it is ~13:20 on a
workday and switching the user's microphone mid-call would be disruptive. Implementer
instructed to check inUse() first and skip + report rather than switch if the mic is
live.

Task 5: report DONE. Controller verified independently:

- default input RESTORED: "MacBook Pro Microphone | inUse=false" (matches pre-test state)
- adapters on real runtime: "Lua 5.4 | streamdeck=start:fn camera=start:fn audio=start:fn"
- camera name byte-exact: 426f 62 e2 80 99 73 -> "Bob" + U+2019 + "s". Not an ASCII
  apostrophe, which would have silently matched no camera at all.
- suite unchanged at 14 passed, 0 failed
- streamdeck start() was NOT invoked live, per the safety constraint; the user's
  current init.lua still owns hs.streamdeck.init and their deck is undisturbed.

Task 5 / Step 6 RESOLVED — the last open assumption in the spec is now closed:
observed watcher code on a default-input change is `dIn ` (trailing space; bytes
100 73 110 32) = CoreAudio kAudioHardwarePropertyDefaultInputDevice. Same code on both
transitions. Mic confirmed idle before switching; original device restored.

Ruling 8 (controller error, corrected by implementer): my dispatch told the implementer to
use `hs.audiodevice.setDefaultInputDevice(dev)`. That function does not exist — the real
API is the method form `dev:setDefaultInputDevice()`. The implementer caught it and used
the correct call rather than working around a broken instruction. Recording because it is
the second time I have handed a subagent an API detail I had not verified (the first was
the `local log = {}` line). Cost: none, caught immediately.
Task 5: review -> Spec OK, quality Approved. 0 Critical/Important, 2 Minor.
Cannot-verify RESOLVED by controller: the "confirmed against hardware 2026-08-21"
comment in streamdeck.lua traces to the USER's own statement earlier today ("that
userdata object seems to be the same thing"), recorded in the spec's Verified Facts.
It predates this task and is truthful. But the user HEDGED ("seems"), which is exactly
why the lastSerial fallback exists.
Task 5: minor (deferred): that comment reads as if this task confirmed identity stability
against hardware. It did not, and could not — start() was correctly never called live.
Accurate provenance would be "user-confirmed, hedged". Comments that overstate their
verification status are the class of defect I have been strict about all session, so
final review should triage this rather than let it stand.
Task 5: minor (deferred): no atomicity guard between camera.lua's seed loop and
startWatcher(); a camera connecting in that window is missed by both paths. Vanishingly
unlikely, and not a regression versus the brief.
Task 5: complete (snapshots base-task05..head-task05, review clean).
Closes D3, D4, D5, D10.

Task 6: dispatching (sonnet) — r35/icons.lua + icon-service font registry.
Closes D8 (cache key omits font). Carries Ruling 2 as amended by the user: glyph
defaults to "0000", and codepoint 0 is the single sentinel controlling BOTH the skipped
glyph draw and the vertically centred label.

Task 6: report DONE_WITH_CONCERNS. Both concerns were correct and both are REAL.
Concern 2 is a LIVE user-visible regression I introduced in the plan. Verified:
unsorted glob[0] (original find_font): PragmataProVF_liga_09.ttf
sorted glob[0] (my plan's addition): PragmataProVF_Italic_liga_09.ttf
live /health: "glyph":".../PragmataProVF_Italic_liga_09.ttf"
Every icon rendered from now on would be ITALIC. Root cause is mine: I added sorted()
for determinism without noticing "Italic" sorts first (uppercase I 0x49 < lowercase
l 0x6C). The actual defect is that PragmataProVF*liga*.ttf matches BOTH faces;
sorted() only made the wrong one win reliably instead of by luck.
Determinism is not correctness — I made the wrong file deterministically win.
Concern 1: `weight` affects the rendered image, exists in icon-service.py, and is
absent from icons.lua PARAMS. That is precisely D8's shape recurring inside the task
whose entire purpose is to kill D8. Not live (nothing sends weight yet) but Task 9's
clock tiles need it: Orbitron is variable and the design the USER APPROVED renders at
the Black instance; at default Regular the digits come out visibly thinner than the
mockup they signed off on.

Task 6: fix round 1/5 dispatched (resumed implementer). Narrow pattern
"PragmataProVF_liga_*.ttf" first (verified to match only the upright face), keeping
sorted(); add weight to PARAMS with a cmp proof and a key test.
Pyright's `Import "flask" could not be resolved` explicitly ruled NOT a finding — it is
the linter not understanding PEP 723 inline deps; uv installs flask at launch and the
service is demonstrably running.

Ruling 9: patched the PLAN itself, not just the running code, so the source of truth stops
carrying the bug: narrow glyph pattern + explanatory comment, `weight` added to PARAMS,
and Task 9's clockTile now requests weight="Black". Regenerated task-9-brief.
Cost if wrong: none — plan and code now agree, and the brief the Task 9 implementer
reads matches what the user was shown.
Task 6: fix round 1/5 — implementer reports done. Controller verified independently:

- /health: "glyph":".../PragmataProVF_liga_09.ttf" — UPRIGHT face restored
- suite: 20 passed, 0 failed
- END-TO-END VISUAL: rendered the real clock row through the LIVE service
  (glyph=0000, font=display, weight=Black) and inspected the PNG. Renders correctly:
  nothing drawn for the glyph, Orbitron Black, labels centred in the tile rather than
  pinned 5px from the bottom, "04" zero-padded per the user's choice. Matches the
  mockup the user approved. Both halves of Ruling 2 are now demonstrably satisfied.
  Task 6: review -> Spec OK, quality NOT APPROVED. 1 Critical, 1 Important, 2 Minor.
  CRITICAL: key()'s sanitiser v:gsub("[^%w%-]", "_") maps every disallowed byte to the
  SAME "_", so distinct inputs collide onto one cache filename. Controller verified
  against the real module:
  A/B vs A B -> COLLIDE
  A:B vs A;B -> COLLIDE
  IN USE! vs IN USE? -> COLLIDE
  Second request silently receives the first's PNG: D8's exact failure mode reproduced
  INSIDE the function written to prevent D8. One edit from live — "IN USE!" is a real
  label in the camera button.
  The brief's own "filesystem-safe" test could not catch it: it asserts the output
  contains no "/" or space, never that the function is injective. A test that checks
  the output LOOKS right rather than that the function IS correct.
  IMPORTANT: PARAMS' glyph default "f07b" disagrees with the server's new "0000" default,
  and buildQuery omits nil fields. Verified: key({}) = "f07b_..." while the server
  renders blank. Masked only because every live call site passes glyph explicitly.
  Minor (deferred): nothing structurally prevents icon-service.py's accepted params from
  drifting from PARAMS again; `weight` was caught by manual grep, not a test.
  Minor DISMISSED: reviewer flagged the docs/plans edit as scope creep. That edit was
  MINE (Ruling 9), not the implementer's. Implementer told to ignore it.
  Task 6: fix round 2/5 dispatched — injective encoding (_%02X per byte) + an injectivity
  test written RED first + glyph default aligned to the server.
  Ruling 10: patched the plan again so the source of truth carries the injective sanitiser
  and the corrected glyph default, with a comment naming the failure mode so nobody
  simplifies it back. Cost if wrong: none; plan and code agree.
  Task 6: fix round 2/5 verified — 21 passed, collisions closed, glyph default aligned.
  Task 6: fix round 3/5 dispatched — USER-REQUESTED design improvement, not a defect.
  Derive the cache key from the literal querystring instead of from a parallel walk of
  PARAMS. Rationale (user's own idea, and it is the better invariant): key() and
  buildQuery() were two functions over one list, agreeing only because they were written
  to agree — which is precisely how the glyph-default mismatch and the missing `weight`
  became possible. Hashing the querystring makes the key a function of the literal bytes
  that determine the render. One string, two uses.
  Kills by construction: collisions, the deferred param-drift Minor, and the whole
  client/server default-mismatch class.
  Chose pure-Lua 64-bit FNV-1a over hs.hash.MD5: MD5 works (verified live) but would make
  key() depend on the hs global, and key()'s purity is what allows standalone testing and
  the mutation testing I have been relying on.
  Controller VERIFIED the implementation before handing it over — against the canonical
  published FNV-1a vectors, not merely self-consistency:
  "" -> cbf29ce484222325
  "a" -> af63dc4c8601ec8c
  "foobar" -> 85944171f73967e8
  and confirmed byte-identical output under standalone 5.5 AND Hammerspoon's 5.4.
  (Doing this because I have now twice handed subagents API details I had not verified.)
  Readable prefix retained: MUTE_47850075d80e0923.png — opaque filenames are a real
  debugging loss and the prefix costs nothing.
  Ruling 11: serialised rather than dispatching Task 7 alongside this fix round, despite
  telling the user I would run them concurrently. The skill forbids parallel implementers,
  and both would touch spec/all.lua and report suite counts. Costs ~5 minutes; avoids a
  race on the shared suite registration.
  Task 6: fix round 3/5 — implementer reports 22 passed. Controller verified independently:
- key() is genuinely pure: ran it with _G.hs = nil -> "MUTE_47850075d80e0923"
- canonical FNV vectors verified THROUGH the module's own _fnv1a64, not a reimplementation
- suite 22 passed, 0 failed
- CONSEQUENTIAL CHANGE the implementer made and flagged: replaced hs.http.encodeForQuery
  with a pure-Lua urlEncode. Correct reasoning (key() calls buildQuery, so buildQuery had
  to become pure too) but it changes the literal bytes sent to the service. Controller
  diffed the two encoders across every real label; only difference is "!":
  hs.http.encodeForQuery -> IN%20USE! (leaves ! literal; ! is an RFC 3986 sub-delim)
  pure urlEncode -> IN%20USE%21 (stricter, unreserved-set only)
  Then verified it does not matter in practice: both forms rendered by the LIVE service
  produce byte-IDENTICAL PNGs. Encoding change is safe.
- Implementer's own concern (could not cross-check 5.4 vs 5.5 FNV without a lua5.4
  binary) is already answered: controller verified via the hs IPC channel, which IS 5.4.
  Recorded because the implementer had no way to know that.
  Task 6: fix rounds 2+3 re-review -> all findings addressed, no functional breakage.
  Re-reviewer confirmed the mismatch CLASS is now structurally impossible: M.key() no
  longer reads PARAMS' `default` at all, so a client/server default disagreement cannot
  express itself in the key. Round-2 injectivity test retained unmodified and passing
  against the new hash path. Old _%02X sanitiser fully removed (no dead code).
  One accurate doc nit, MINE not the implementer's: my plan patch placed M.key() BEFORE
  buildQuery(), a Lua forward-reference bug if transcribed literally, and omitted
  urlEncode entirely. Fixed by replacing the plan's whole icons.lua listing with the
  actual shipped module, so the document cannot drift from the code again.
  Task 6: complete (snapshots base-task06..head-task06-fix3, review clean).
  Closes D8. Cache key is now a hash of the literal querystring -- one string, two uses.

Task 7: report DONE — 32 passed, RED before GREEN, Deck.new loads on real runtime.
Implementer correctly reported 32 rather than the brief's stated 28. My arithmetic was
stale: the plan's cumulative counts were computed before Tasks 4 and 6 fix rounds added
tests. Plan counts from here on are indicative, not authoritative.
Task 7: fix round 1/5 dispatched. Finding: bind() has ZERO test coverage
(grep -c bind spec/deck_spec.lua = 0), yet it is the mechanism behind EVERY dynamic
button — six clock tiles, the camera indicator, the mic indicator. Its failure mode is
silent: the deck simply freezes at its first render, and nothing in the suite notices.
This is a gap in MY plan — I specified ten deck tests covering compositing, diffing and
dispatch, and none for the function connecting the registry to the renderer.
Asked for 5 behaviours, using the REAL Registry rather than a stub (it is pure and well
covered, so this tests actual wiring rather than an idea of it), with at least one
written RED against a deliberately broken bind() to prove the test discriminates.
Folded Minor: document two forward-looking limitations without changing behaviour —
bind() walks only layout.persistent (page-layer watches would not bind; pages are
deliberately unbuilt), and calling bind() twice double-registers (safe today because
init.lua calls it once and hs.reload resets Lua state).
Task 7: fix round 1/5 — implementer reports 37 passed, RED first (3/5 new tests failed
against a deliberately whole-deck-rendering bind()). It also found and fixed, unprompted,
a pre-existing comment that falsely claimed `available` re-renders the whole deck.
Controller verified independently: - suite 37 passed, 0 failed - bind() now referenced 8 times in deck_spec.lua (was 0) - MUTATION on a throwaway copy: changed bind()'s "changed" handler from
self:render(indices) to self:render() -> 34 passed, 3 FAILED. The new tests
genuinely discriminate scoped renders from whole-deck renders.
Task 7: review -> Spec OK, quality NOT APPROVED. 2 Important, 1 Minor.
IMPORTANT 1 (real production bug, defect in MY plan's deck.lua):
render() sets self.rendered[index] = key BEFORE calling the async setButtonIcon, and
passes no callback. setButtonIcon deliberately leaves the button showing its previous
image on failure. So one failed fetch leaves the cache claiming the button shows the
NEW key while the hardware shows the OLD image -- and every later identical render
matches the key and suppresses the redraw. The button stays stale FOREVER, until a
reload or invalidate(). A momentary icon-service blip permanently desyncs a tile,
silently. Untested.
FIX: pass a callback; on failure, if rendered[index] is still this key (nothing newer
superseded it), clear it so the next pass redraws. Keeping the optimistic set is
correct — it prevents duplicate concurrent fetches for the same button.
IMPORTANT 2 (also my plan's code):
Deck:render's call to iconSpec() is unprotected, while press() wraps actions in
xpcall. A throwing icon function aborts the whole render pass mid-pairs() loop, so
buttons later in iteration order never draw. pairs() order is nondeterministic in
Lua, so WHICH buttons go dark varies run to run. Live relevance: the camera tile's
icon function calls cam:isInUse() on a device object that can die.
FIX: xpcall around iconSpec; on error log and skip that one button, continue the loop.
MINOR DISMISSED: reviewer flagged undisclosed edits to docs/plans as Task 7 scope creep.
Those were MINE — I replaced the plan's stale icons.lua listing (Ruling 12) while
Task 7 was running. Not the implementer's doing. Reviewer was right to flag an
unexplained diff; the explanation is simply that the controller edits the plan too.
Ruling 12: replaced the plan's embedded icons.lua listing with the actually-shipped module
after the Task 6 re-review found my patch had M.key() before buildQuery() (a Lua
forward-reference bug if transcribed literally) and omitted urlEncode entirely.
Cost if wrong: none; the doc now cannot drift from the code.
Ruling 13: HOLDING Task 7's fix round until Task 8 lands, rather than running two
implementers concurrently. The skill forbids it; both could touch spec/all.lua and both
report suite counts. Findings recorded above so nothing is lost to a context reset.

Task 8: report DONE_WITH_CONCERNS — 45 passed, RED before GREEN. Controller verified:

- clock edge cases independently: 00:00 -> 12:00 AM, 12:00 -> 12:00 PM,
  13:05 -> 01:05 PM, 23:59 -> 11:59 PM. Midnight/noon (where naive hour%12 breaks)
  both correct. Hours zero-padded per the user's choice.
- D12 CONFIRMED by inspection: applicationsForBundleID is inside the returned closure
  (actions.lua:23, after `return function()` at :20), so it resolves at SEND time.
- both modules load on the real runtime: "Lua 5.4 actions=function clock=function"
  Implementer's concern accepted: D11's end-to-end delivery to an unfocused app remains
  unproven. It tried Finder and TextEdit and could not attribute the null result to a real
  limitation vs. those particular native targets. That is the honest answer and matches
  what I asked for — the live delivery test was explicitly a bonus, not a requirement,
  because Teams is not installed here. D11's type-level fix is verified; delivery
  verification is deferred to the work laptop, per Ruling 3.
  Task 7: fix round 2/5 — implementer reports 47 passed, RED first for BOTH findings.
  Controller verified: suite 47/0; render() now xpcalls iconSpec (logs + skips just that
  button) and passes a callback to setButtonIcon that clears rendered[index] on failure,
  guarded against a newer render having superseded it. Comments explain WHY, not what.

Task 8: review -> Spec OK, quality Approved. 1 Important, 2 Minor.
IMPORTANT: clock.start() stores M._timer with no stop() and no double-start guard.
Reviewer called it a latent landmine for Task 9. Controller ESCALATED it to confirmed
by empirical test:
probe hs.timer.doEvery(0.5) writing to a file
ticks in 2s BEFORE reload: 4
open -g hammerspoon://reloadConfig
ticks in 2s AFTER reload: 4 <-- SAME RATE; the timer survived
Hammerspoon timers SURVIVE hs.reload(). The config's own pathwatcher reloads on every
.lua edit, so an unguarded clock.start() spawns another 1-second timer per edit —
N edits, N timers, N duplicate renders per minute, unbounded.
NOTE: the user's ORIGINAL init.lua has this same defect already (pathwatcher, camera
watcher and a doEvery(5) with no teardown). Pre-existing, invisible only because those
callbacks did almost nothing.
(First probe attempt produced a false "no leak" result because shell escaping mangled
the Lua string and the timer never started. Caught it, rewrote the probe as a file and
re-ran. Recording because I nearly reported a wrong conclusion from a broken test.)

Ruling 14: patched Task 9's init.lua in the PLAN to add hs.shutdownCallback teardown
(clock.stop, camera.stopWatcher, audiodevice.watcher.stop, wake + path watchers), with
the empirical finding recorded in a comment. hs.shutdownCallback's own docs name this
exact purpose: "destroying system resources that will not be released by normal Lua
garbage collection processes." Regenerated task-9-brief. Task 8's fix round adds the
clock.stop() that teardown depends on.
Cost if wrong: teardown runs on every reload; if a stop() call errored it would surface
immediately and loudly at the Task 9 cutover.
Task 8: fix round 1/5 dispatched — M.stop(), idempotent M.start(), tests for both, plus a
folded Minor (alert the user when sendTo's target app is not running, instead of only
logging). Explicitly NOT actioned: hs.alert.closeAll() bluntness — deliberate brief
choice, deferred to final review.
Task 8: fix round 1/5 — implementer reports 51 passed, RED first (4 failures:
"attempt to call a nil value (field 'stop')"). Controller verified BEHAVIOURALLY rather
than by test count:
3x clock.start() -> 1 live timer (want 1)
clock.stop() -> 0 live timers (want 0)
clock.stop() again -> safe (pcall true)
The reload leak is genuinely closed, not merely covered by a test.
Task 8: fix round 1/5 re-review -> 2 addressed, 0 open, no new breakage. Re-reviewer
confirmed idempotency is implemented by stop-and-replace (not refuse-to-start), which
matters: a refusing implementation would leave a stale timer bound to an OLD registry
after a reload. M.stop() clears the reference rather than merely stopping it.
The not-running alert respects nil desc and reuses the existing style.
Task 8: complete (snapshots base-task08..head-task08-fix1, review clean).
Closes D11 (type-level; live delivery deferred to the work laptop per Ruling 3) and
D12 (resolve at send time, inside the closure).
Task 8: minor (deferred): hs.alert.closeAll() closes ALL Hammerspoon alerts, not just
this module's. Deliberate brief choice to avoid stacked confirmation flashes; the config
has no other alert sources today. Final review to triage.
Task 8: minor (deferred): sendTo picks apps[1] arbitrarily when a bundle ID has multiple
running instances. Out of scope; no live impact for Teams.
Task 7: fix round 2/5 re-review -> 2 addressed, 0 open, no new breakage. Re-reviewer
confirmed the fix is LIVE-effective not test-only: checked the real icons.lua
setButtonIcon actually invokes callback(false)/callback(true) as the wiring expects,
rather than trusting the stub. Also confirmed the throwing-icon test is genuinely
order-independent despite pairs() nondeterminism.
Task 7: complete (snapshots base-task07..head-task07-fix2, review clean).

RULING 1 WAS NEVER APPLIED — caught immediately before dispatching Task 9.
At pre-flight I found that T2 writes launchd documentation into init.lua (half of D6's
fix, since the ORIGINAL stale instructions were the defect) and that T9's wholesale
rewrite would delete it. I recorded the ruling and then never patched the plan.
Verified: grep for launchctl in task-9-brief -> 0 occurrences, while the live init.lua
has the block at lines 71-76. Now applied and the brief regenerated (>0 occurrences).
This is exactly the failure the pre-flight scan existed to prevent, and it was the
LEDGER, not my memory, that caught it. Recording plainly: recording a ruling is not
applying it.

Task 9 (CUTOVER): report DONE_WITH_CONCERNS. Controller verified independently:

- no Lua errors in the console since cutover
- hs.shutdownCallback installed (type=function) and confirmed firing on reload
- stream-deck-icons.lua deleted; suite unchanged at 51 passed
- 32 cache files under the new LABEL_hash scheme. The filenames are the strongest
  evidence the system is live: minute tiles 31..38 exist, i.e. the clock has rendered
  a fresh tile every minute since cutover. Plus FRI/AUG/21/PM and
  MUTE/LEAVE/RAISE/SMILE/LIKE/WOW/MICIDLE.
- deck serial CL35I1A01407 matched at connect.

REAL FINDING, user-facing: config/devices.lua watches "Bob's iPhone Camera" (U+2019)
but no such camera exists. Actually connected:
FaceTime HD Camera
r35-iPhone17.Pro.Max Camera
r35-iPhone17.Pro.Max Desk View Camera
The user renamed or replaced their iPhone. Button 1 will read MISSING permanently.
Degrades gracefully (no error) but the camera indicator is non-functional.
PRE-EXISTING drift inherited from the original init.lua, not introduced here — but it
was invisible before because the old code also silently matched nothing.
This is the user's decision (three candidate cameras), so surfacing rather than ruling.
Task 9: review -> Spec OK, quality Approved. 0 Critical/Important, 3 Minor.
Reviewer confirmed at byte level: launchd comment block SURVIVED (Ruling 1 applied just
in time), shutdownCallback covers all five started systems, window management deleted
not ported, U+2019 identical (e2 80 99) in both devices.lua and layout.lua, and the
wiring order is correct (bind before adapters; on("available") not whenAvailable).
Task 9: minor (deferred): reaction buttons 3/4/5/11/12 have NO action — pressing them is
a no-op. Not a regression (the original buttonCallback only printed) but it is dead
functionality on a third of the lit buttons, in a config built specifically to send
targeted hotkeys. Surfaced to the user; needs their Teams reaction shortcuts.
Task 9: minor (deferred): shutdownCallback does not tear down r35.ipc, the streamdeck
discovery callback, or re-bound hotkeys. Likely harmless — those are single global
slots that overwrite rather than accumulate — but unverified.
Task 9: minor (process): Step 5's literal "look at the physical device" gate was not met;
the implementer substituted indirect evidence and disclosed it plainly. Controller's
independent evidence (serial match, minute tiles 31..38 progressing) corroborates.
The user has been asked to confirm the LEDs directly.
Task 9: complete (snapshots base-task09..head-task09, review clean). CUTOVER SUCCESSFUL.

Task 10: dispatching (sonnet) — acceptance verification. Much of it needs human hands
(physical unplug/replug, Teams). Explicitly forbidding `pmset sleepnow`: it would sleep
the user's machine mid-workday. The wake-redraw criterion gets deferred to the user.
Task 10: complete — 14 PASS / 0 FAIL / 3 CANNOT VERIFY of 17 acceptance criteria.
The three unverifiable ones all need the user or the work laptop: - physical unplug/replug of the deck - button 25 -> Teams with Teams unfocused (Teams not installed here) - sleep/wake redraw (refused: would sleep the user's machine mid-workday)
Agent left kata#wbyy untouched as instructed; controller closes it.
Suite 51 passed. Spec updated with a "Task 10 verification results" section.

ALL 10 TASKS COMPLETE. Dispatching final whole-branch review (opus).

*** CORRECTION — RULING 14's PREMISE WAS FALSE ***
I claimed, citing an empirical probe, that Hammerspoon timers survive hs.reload(), and
told the user their existing config had been leaking watchers on every edit all day.
The final whole-branch reviewer disputed it. I re-tested and the reviewer is right:
grep for hs.urlevent in the config -> NO bindings anywhere
set a global, run `open -g hammerspoon://reloadConfig`, read it back
-> "SET_BEFORE_RELOAD" (survived)
=> that URL does not reload this config AT ALL. My probe measured a non-event.
Correct behaviour, measured via a REAL pathwatcher-triggered reload (touch init.lua):
ticks in 2s BEFORE: 4
pre-reload global read after: nil (proves the reload happened)
ticks in 2s AFTER: 0 (timer destroyed)
hs.reload() DESTROYS the Lua state and its timers. There was never a cross-reload leak,
and the user's original config was not leaking.
What survives unchanged: clock.stop(), idempotent clock.start(), and hs.shutdownCallback
are all still correct hygiene for an explicit double-start within one state and for a
clean exit. Only the JUSTIFICATION was wrong. Fix wave corrects the comments in
init.lua and clock.lua; the plan's copy is corrected above.
Root cause of my error: 4-ticks-before / 4-ticks-after looked like a clean positive
result. Zero-on-both-sides would have made a non-event obvious; a steady rate on both
sides looked exactly like "it survived". I did not check that the reload occurred.
This is the same class of defect I spent the session hunting in others: a test that
reports success because it never exercised the thing it claimed to.

FINAL whole-branch review: verdict SOUND. 2 Important + several Minor.
Important A: Deck:bind wires only "changed" and "available", never "lost". camera.lua
and audio.lua both call revoke() -> emits "lost" -> nobody renders. Unplugging the
watched camera freezes button 1 on its last image; layout.lua's MISSING branch is
unreachable after first render. Real bug, one-line fix, needs a test.
Important B: the false reload comments above (init.lua + clock.lua), plus
streamdeck.lua's "confirmed against hardware" which was user-asserted and hedged.
Deferred-finding triage: 1,3,4,5,6,7 fine to leave; 2 (streamdeck comment) must fix.
Fix wave dispatched (7 findings, one dispatch per the skill).
FIX WAVE: complete. 52 passed (was 51). All 7 findings fixed, none skipped.
Controller verified independently: - Finding 1: deck.lua:163 now wires registry:on(key, "lost", ...) alongside
"changed" and "available", with an explanatory comment - Findings 2/3: grep for the false claims across init.lua and r35/ -> CLEAN.
Replacements are accurate: "hs.reload() destroys the entire Lua state, including
every timer and watcher created in it -- so there is no cross-reload leak for this
teardown to fix. Verified against a REAL reload driven by the pathwatcher" - Finding 4: icons.lua:126-134 writes to path..".tmp" then os.rename, with a comment
explaining atomicity - config loads cleanly; /health 200 with both fonts resolved
Implementer flagged one cosmetic change: the render error string moved from
"icon spec for button %d failed" to "render for button %d failed" because the xpcall
region widened. Correct and more accurate; nothing greps it.
