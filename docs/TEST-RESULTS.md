# Verification results — 2026-11-13

**2026-11-17 editor.15:** [Six additional vanilla sieges, exact ordinary build, all-seven siege matrices, representative-map/zoom/log/name/configuration regressions and visible observations](TEST-SIEGE-EXPANSION-2026-11-17.md). Earlier reports retain their own checkpoint boundaries.

**2026-11-17 editor.14:** [Native log overlay, combat/post toggles, exact build and separate offline/native/visible evidence](TEST-LOG-LAYOUT-2026-11-17.md). The editor.13 zoom/fort report below retains its own checkpoint boundary.

**2026-11-17 editor.12:** [Actual Troll/busy-square reproduction, permanent retirement, native button/wheel zoom, in-place unique policy, safe item clearing and exact current-build tests](TEST-EDITOR-CONTROLS-2026-11-17.md). Historical results below retain their original version boundaries.


**2026-11-16 editor.11:** [Local checkpoint pairing, five new native presets, 162 offline cases, ordinary-build API regressions and actual Farm/Oasis visible observations](TEST-VANILLA-PRESETS-2026-11-16.md). Failures, unsupported contexts and QA quota reruns are recorded separately. This does not upgrade historical test coverage.

**2026-11-16 editor.10:** [Native individual naming, limits, exact persistence and separate API evidence](TEST-NATIVE-NAMES-2026-11-16.md). Current naming tests and visible observations are distinct from all historical reports below.

**2026-11-15/16 current upstream port:** [Five CoE5SE 3.4.4 source contributions and combined verification](TEST-API-CONTRIBUTIONS-2026-11-15.md). Final combined native runs pass 21 standard, 14 fixture and four placement groups (including repeats); visible evidence and final-revision limits are distinguished. Existing product Lua is unchanged. Earlier results below are not automatically later-build acceptance.

**2026-11-15 editor.8:** [Explicit cursed removal using the actual Crystal Heart diagnostic](TEST-CURSED-2026-11-15.md). Current local report: live identity/spell preservation, exact supported saved configuration, native bonus refusal and explicit injury-persistence limitation. Earlier reports below retain their historical scope.

**2026-11-15 editor.7:** [Battlefield window, native item views and modded filters](TEST-PANEL-2026-11-15.md). New visible item equip/reject/cancel/replace/remove, magic/label/input and origin-filter evidence is separated from actual native API regressions and offline tests. This is the current local development report; older sections retain their historical scope.

**2026-11-15 editor.6:** [Equipment, actual base schools and exact spell configuration](TEST-LOADOUT-2026-11-15.md). Current local source has 114 passing offline contracts; native and visible equipment/magic/persistence results and their exact build bindings are recorded separately there. Earlier sections below retain their historical scope.

**2026-11-14 editor.5:** [Final snapshot, empty editor, terrain and filter follow-up](TEST-BATTLEFIELD-2026-11-14.md). The old empty final grid was reproduced with a living survivor. The separate Extender now captures before native cleanup and supports an explicitly commander-free editor. Actual UI observations, candidate/final native runs, offline contracts and unresolved cases are separated in that report. Earlier tables remain historical.

**Current menu/mod follow-up:** [Grouped Battlefield menu and active CrabCult units](TEST-MENU-MODS-2026-11-14.md). Current normal DLL `63b293…`: 97 offline cases; all selected native regression groups pass, including two fights and exact rebuilding of the actual ten-unit user setup after fixing a deployment cycle. New CrabCult battle and visible menu/filter/mod-sprite results are separate from the historical prototype tests below. Natural conversions/transformations and complete render scenes remain unverified.

**2026-11-14 editor.4:** [Footprint/native Inspect/caster validation](TEST-INSPECTOR-2026-11-14.md). Frozen sources reproduced the actual invalid God Emperor recovery. Final build: **78 offline Lua cases and 13 distinct native groups PASS**; three complete visible six-unit battles and Back/Reset/Rematch/Save/Load succeed with the explicitly corrected copy. Genuine read-only native cards, item subcard, both teams/unique copies, 1×1/2×2/3×3/2×1 previews and Forest rejection verified visibly. Held right-drag and all camera zooms remain unverified visually. Original recovery/diagnostics and regular installation hashes unchanged. Earlier tables remain historical.

**2026-11-14 editor.3:** [Interface/lifecycle follow-up](TEST-INTERFACE-2026-11-14.md) separates the reproduced God cleanup failure, native allocation/combat checks, visible search/sprite/report checks and offline regressions. Earlier tables below remain historical evidence.

**2026-11-14 editor.2:** [Actual-user-diagnostic placement/deletion investigation](TEST-PLACEMENT-2026-11-14.md), native unique-slot reinitialization reproduced and prevented, verified large-unit deletion/reuse and explicit integrity recovery. Nine native groups and 40 offline cases passed; visible and injected/offline-only cases are distinguished. Earlier evidence below remains historical.

**Current local editor follow-up:** [Priestess, native-map editor and diagnostics report](TEST-EDITOR-2026-11-13.md) supersedes the old rebuild/UI limitations below for the separate experimental build. It records the reproduced failure, corrected post-WAIT projection guard, visible successive Priestess placement/resize/error export, five native regression groups, 20 model and 8 editor checks. The tables below retain historical 0.1.0 evidence.

Prototype 0.1.0; CoE5 5.43 Windows x64; unchanged CoE5SE dev `57abc69a2ddb272a5b9049b4a561367066d9d99e` (3.3.0). Tests used a private runtime/profile. See [RECON](RECON.md) for fingerprints. No result below implies full acceptance of the original specification.

**Follow-up:** the tables below retain the released prototype's baseline. The local 3.4.0 terrain extension and updated Sandbox have a separate [complete terrain test report](TERRAIN-EXPERIMENT-2026-11-13.md). Plain and Forest were visually inspected and fought in the real game; invalid arguments, cleanup, injected initialization failure and Forest scenario/reset/rematch were exercised through native API tests. Current offline totals: **20 model/guard cases**, **21 actual extender terrain-parser cases**, all shipped Lua and both native probes parse. The old 16-case total below belongs to 0.1.0.

**Evidence labels:** *Manual game UI* means a visible game window was inspected and operated. *Native API* means code ran inside that real game against CoE5SE. *Offline* means pure Lua/model tests outside the game. A native API test is not automatically a manual UI test.

## Actual battles and sizing

| Case | Result | Evidence |
|---|---|---|
| Initial Spearman vs 2 Goblins | Team A won, round 4; Spearman 4 HP, Goblins -2/-1 HP | Manual game UI + [initial report](evidence/initial-battle.ini) |
| Spearman vs Goblin | Native AI fought; winner, HP, kill counters and team totals exported | Native API + manual report screen; [UI report](evidence/ui-run/battle-report.ini) |
| 100 Spearmen vs 100 Goblins, first run | A won at round 14; A lost 2, 98 survived; B lost 100, 0 survived; elapsed wall 38.563 s | Manual game UI + native API; [large report](evidence/run-01/probe-large-battle.ini) |
| Same large roster, second run | Completed successfully; independent native outcome recorded | Native API; [second report](evidence/run-02/probe-large-battle.ini) |
| Activated CrabCult: Shorebound Initiate vs Goblin | A won, final round 6; 1/1 A alive, 0/1 B alive | Native API, activated mod banner inspected; [mod report](evidence/run-02/probe-mod-battle.ini) |
| Automatic field width | Small 32; 100 vs 100: 34; 500 vs 500: 84 columns; height 20 | Native API; [measurements](evidence/run-02/native-probe.ini) |
| 500 vs 500 | Field creation/deployment/sizing tested; **no complete battle at this size** | Native API only |

The native speed controls were visible; fast speed was clicked in the 100-vs-100 fight. A full pause/resume acceptance test was not performed. Elapsed time is wall time and includes pauses/UI delays, not simulated battle seconds.

## Feature acceptance matrix

| Requested area | Result and scope | Evidence level |
|---|---|---|
| Main-menu Sandbox entry | Appears, opens setup, enters editor | Manual game UI |
| Map selection | Grass native field only; terrain/batmap inventory implemented read-only. Other environments cannot be selected by the test-field API | Source-confirmed restriction; grass tested in game |
| Small/Medium/Large/Extra Large | Not implemented as functional selectors; automatic native growth measured instead | API restriction + native API |
| Seven colors; same color allowed | Seven palettes implemented; RGB is applied to slots 0/24 and restored on close. Identical green colors retained different teams. Blue/red native tokens visibly confirmed | Native API + manual default appearance; not every palette manually cycled |
| Two enemy AI teams | Ownership 0/24, distinct native teams, actual fighting | Native API + manual game UI |
| Alphabetic listing/search | Sorted Idle browser inspected; entered `s`, accepted via native OK, filtered rows changed accordingly | Manual game UI |
| Loaded Mod units | CrabCult unit ID 2000 available and fought. Abyssal Shellback ID 2004 found through the visible browser, selected, placed and seen in Native view | Native API + manual game UI |
| Mod-origin category | Not implemented: no reliable origin metadata found. No ID-range guesses | API metadata gap |
| Idle/Attack sprites | Idle images visible in native monsterRow browser. Separate Attack image not available/implemented | Manual Idle test; Attack API gap |
| Categories | Actual native human/animal/undead/demonic/flying/ranged flags used | Real catalog API exercised; full filter UI combinations not manually tested |
| Five visible entries | Five rows plus previous/next implemented. Mouse-wheel scrollbar is not implemented | Manual layout inspected; wheel API gap |
| Single | Exact native coordinates checked | Native API |
| Horizontal/Vertical rows | Counts 1 and 15 verified in the game; all counts 1–15 checked by pure formation tests | Native API + offline |
| Squares | 2×2, 3×3, 4×4 all exact coordinates verified in the game | Native API |
| Right-click placement | A Mod unit selected through browser and placed on a blank planning cell; counter updated; native view confirmed it | Manual game UI |
| Held-right-button dragging | Implemented using held mouseButtons and changed-cell detection. A long physical right-drag path was **not** acceptance-tested by available desktop controls | Not fully tested; do not call it verified |
| Existing-unit context priority | Right-click on existing unit while placement active opened context, without adding a unit | Manual game UI |
| Invalid/occupied cells | Native move rejected off-field and occupied targets without moving original | Native API; mixed-invalid formation UI not fully tested |
| Ghost | Planning bounds/anchor preview visible; not a full native footprint/obstacle oracle | Manual visual inspection, documented restriction |
| Move | Native move preserved inventory; visible UI moved A1 from (8,9) to (10,9), count stayed 1 | Native API + manual game UI |
| Cancel Move | Visible Back action cancelled and original cell stayed unchanged. Final UI names this button Cancel move | Manual game UI. Escape attempts were unreliable; no Escape guarantee |
| Copy/Delete | Real candidate rebuild, distinct native copied record, item readback, removal and re-opening passed. UI context contains both entries | Native API + UI presence; full click-through combinations not all manually tested |
| Preserve items on move/copy | Regression used native “A Chest Full of Fire”; actual inventory was retained through move/copy/rebuild | Native API [run 02](evidence/run-02/native-probe.ini), not only an empty-inventory test |
| Item assignment | Read-only searchable item catalog/slot-type filter. General giveItem works, but production equip UI is disabled until anatomical-slot guarantees are established | Native giveItem probe; appropriate/inappropriate UI assignment blocked/unverified |
| Known-spell selection | Old Wizard removal/re-memorization passed: 8 known, 4 memorized. ID+name keys distinguish duplicate names | Native API [magic regression](evidence/run-03/native-probe-magic.ini) + offline identity regression |
| Base magic-school levels | No supported exact setter found; upgrade UI disabled | API gap |
| Mod spells/items | Loaded tables enumerated; actual custom-mod spell casting and custom-item slot compatibility were not separately proven | Catalog available, broader cases untested |
| Reset/Rematch | Small roster re-created at original positions, fought again and exported. UI controls exist | Native API [reset/rematch](evidence/run-04/end-state-probe.ini); full manual UI reset combinations not exhaustively tested |
| Randomized mage restoration | Actual saved Old Wizard had a different regenerated starting spell set; operation was explicitly refused | Native API [restoration result](evidence/run-03/native-probe-magic-restoration.ini) |
| Clear | Cleared 3-unit setup and returned to setup with “0 placed” | Manual game UI |
| Battle report | Actual winner, round, elapsed wall time, original roster losses/survivors and types shown; file export written | Native API + manual game UI |
| Kills | Native counter delta observed (Spearman 1, Goblin 0) | Native API / exported report |
| Damage / cast totals | Only synchronous directly observed HP loss and explicit item-spell attack observations; complete totals marked unavailable | Partial instrumentation; no claim of full combat telemetry |
| Return-time final positions | Both coordinates nil even for living 6-HP Spearman. Native field view after fight was visibly empty | Native API + manual game UI; [UI report](evidence/ui-run/battle-report.ini) |
| Aftermath callback positions | Separate BATTLE_TURN_EFFECTS observer captured one survivor's cell before cleanup, while return-time position count was zero. Stored separately; not a retained native scene or complete final-state snapshot | Native API [aftermath report](evidence/run-04/probe-small-battle.ini) |
| Save/load valid scenario | writeIni/readIni/schema/native re-opening passed. Saved simple roster was loaded and fought through UI | Native API + manual game UI |
| Missing/changed content | Missing mod/unit/item/spell, duplicate-cell/malformed counts, unsupported terrain/schema/size and missing baseline rejected | Offline validation tests; not all missing-content cases manually reproduced in a second game profile |
| Same-name content edits | Spell ID+name checked. Arbitrary definition changes under unchanged identity are not fully detectable | Known limitation |
| Multiplayer/macOS | Not tested or claimed | Outside verified scope |

## Corrections retained as evidence

1. Initial mod metadata needed the native 256×64 icon; fixed before gameplay tests.
2. A held right click in Move could fall through to placement. The moving branch now blocks placement and suppresses continued placement until release. The corrected visible move preserved the team count.
3. Name-only spell lookup failed on duplicate native names ([run-02 FAIL](evidence/run-02/native-probe.ini)). Changed to ID+name; the native magic regression passed. The earlier failure remains in the repository.
4. An assumption that an open handle retains the final native scene was disproved by actual UI inspection. Documentation/UI now state the restriction. The independent aftermath probe captures any available earlier cells with explicit provenance.
5. Escape did not reliably cancel the editor move in automated input tests. The visible cancellation button worked. The final UI uses that explicit path.

## Reproduction

The pure Lua tests are [`tests/model_spec.lua`](../tests/model_spec.lua): **16 passing tests**. [`tests/syntax_spec.lua`](../tests/syntax_spec.lua) parses every shipped Lua module. `tools/lua-runner.c` can be compiled with the examined upstream Lua sources. Its embedding callbacks serve only this offline harness; it does not simulate CoE5 APIs or reproduce extender security limits.

For native tests, clone the pinned upstream into ignored `private/upstream`, build it unchanged with `tools/build-upstream.ps1`, prepare an isolated lab with `tools/prepare-lab.py --game <owned-install>`, and use `tools/sync-lab.ps1 -NativeChecks` followed by `tools/launch-lab.ps1`. The native suite is `tests/native_probe.lua`; its extra menu button exists only in the private test copy. The CrabCult test requires the user's locally installed CrabCult mod copied into that private profile and enabled there. No CrabCult files are distributed.

No game assets, full game logs, keys or third-party mod files are included as evidence. INI files are generated test outputs.
