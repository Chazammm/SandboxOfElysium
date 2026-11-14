# SandboxOfElysium development journal

## 2026-11-14 — editor.5 final snapshot, empty editor and Ranged

Preserved dirty sources and the full existing private data folder under private/battlefield-before-931288ebeb7b426b9b288b1cdd116463. Inspected the actual diagnostics-5bd42749aa2c47d4ba1b-{1,2,3} and five matching reports: surviving native records with cleared battlefield cells, and the legacy final-Team-A restriction. The bounded exports do not establish an unrecorded earlier action.

Native lifecycle analysis identifies the guarded afterFightUpkeep call after 75 aftermath ticks and later temporary-unit removal/grid clear. Capture unit/cell state there without suppressing cleanup; draw only verified living footprints as a labelled read-only snapshot, with current-record native Inspect. Add a native commander-free emptyEditor mode while retaining legacy protection and refusing missing-team battle starts before mutation. Static proof permits only the template-only monsterHasRanged leaf in main-menu context; native Ranged includes spell attacks.

Actual visible tests remove the last A, Clear to zero/zero, save/load zero and B-only, place either side, refuse an empty-team fight, complete two Spearman battles with snapshot/Inspect/Back/Reset/Rematch. Candidate e9c934 native tests classify all 1851 monsters identically at menu/in-field, with 714 ranged results; all five neutral land maps pass two-battle placement/persistence/cleanup matrices. The final normal63b293 DLL repeats the full matrix. Source54f26ddd also fixes a reproduced deployment cycle: the first blocked large actor was repeatedly parked while other actors remained in a cycle; parking each waiting actor once outside all desired footprints solves the actual user10 fixture. Both natural user fights end round7/winner24 and exact rebuild succeeds. Root Lua contracts now total97. Two final visible six-God battles end round16/winner0 with two3x3survivors, native final Inspect, Back and Reset. Native live-summon captures, later removal and read-only guards pass; natural transformation/conversion remains unobserved. Full bindings/failures/limits are in docs/TEST-BATTLEFIELD-2026-11-14.md.

Incorporated musical_pianist's menu feedback using native Current setup/Battlefield/Scenarios/Tools sections and a separate Main menu row. Visible normal-resolution before/after-battle menus fit all actions; locked-state actions remain read-only except recovery/export. Current CrabCult copy: native Shorebound Initiate+Shellback fight/reset pass; visible Abyssal Shellback search, custom sprite,70HP native card, placement and natural round3 battle pass. Missing CrabCult load leaves the setup unchanged and is diagnosed by name; the UI now shows the reason directly. With CrabCult all1879 entries/filtercounts are visible, Ranged721. Historical CrabCult evidence stays separate. See docs/TEST-MENU-MODS-2026-11-14.md. No original diagnostics/recovery/scenarios or normal installation files changed; no PR, external contact, release or Extender distribution.

## 2026-11-14 — editor.4 actual God Emperor diagnostics, preview and Inspect

Preserved current dirty sources/profile and 9df3eae7c90343999f1d diagnostics under private/inspect-before-85d08c0e65434d599b4093232a941277. Frozen465ed native replay reproduced all four custom-Edit additions, Solar6 versus total allowance4, full six-unit fight round17/winner24, then bulk memorize_limit and lock. The native primitive did not validate capacity; native unit-card exit would randomly normalize, which the Sandbox Edit bypassed. New guarded edits and explicit copied repair avoid silent trimming. Added read-only native card and native-rule footprint/preflight with formation spacing. Separate extender sources/binaries remain separate; no PR or external contact. Current test status and evidence: docs/TEST-INSPECTOR-2026-11-14.md.

Final e08b5a56 plugin: 78 offline Lua cases, 19 caster/20 preview/21 Inspect C assertions and 13 distinct native groups pass. Native two full six-unit fights plus visible three full fights finish round16/winner0 after explicit correction; exact Back/Reset/Rematch/Load readback succeeds. Seven visible native Inspect sessions include both teams, independent God copies, interior cells and an equipped God with actual native item subcard; all records unchanged. Visible 2×1 Bog/Crocodile, 2×2 Seraph, 3×3 God/Rider, footprint-spaced row/square placement, Forest and edge refusal, large Delete/Reuse, live search and default BAT tested. Earlier incomplete background/budget attempts retained and distinguished. Diagnostics export optimized without raising native step budget. Original files and normal installation hashes unchanged; normal test profile ends with three mods and no running test game. Long physical RMB drag and all zooms remain outside visible acceptance.

## 2026-11-14 — editor.3 lifecycle and interface

Three actual b3534339 diagnostics and the matching frozen log/recovery were preserved and inspected. A full old-build replay confirmed God #207 survived on world (-3,-1); square-only cleanup missed him and the next field failed unique_exists. Separate extender work adds a provenance/generation ledger, scoped independent unique allocation, SDL text focus and measured icon rectangles. Sandbox adds iterative report actions/archives, direct search, an explicit saved unique option and cleanup readback with fail-closed recovery. Existing uncommitted work is preserved. Detailed evidence and limits: docs/TEST-INTERFACE-2026-11-14.md. No PR, external contact or experimental DLL distribution.

## 2026-11-14 — user-diagnostic placement/deletion integrity

- Preserved dirty source and exact user exports privately. Bounded ranges278–341/283–346 omit the first corrupting operation; model12/13/14 already alias native19 HP0 before the logged Delete refusal. Later Memorize still ran on the ghost.
- Old-build native reproduction: repeated Rider202 creation reinitializes the same living slot; old runtime commits multiple models, and Delete retires their shared actor. Native ability57/unique branch and retained anchor verified privately; Seraph2062×2 and Rider202/2033×3 confirmed.
- Separate extender preflights unique requests before mutation, exposes guarded state/footprint queries and stable SDL buttons, and guards Move lifecycle. No unsafe slot compaction or death handlers.
- Sandbox validates mapping/configuration and final positions, locks unverified state, saves unique recovery files, removes phantom hit-test fallback and protects the first integrity error. Explicit recovery retains saved spells/items.
- Visible BAT tests: 1×1/2×2 delete and interior-cell reuse across teams, configured Seraph copy, exactly two rejected clicks/two errors, duplicate unique refusal, 3×3 Rider delete/export/recreation, Forest tree rejection then success. Exports prove no aliases/issues and preserved Priestess spells/item/HP.
- Final native4 placement+5 existing editor groups PASS, including injected cleanup refusal/lock/recovery and two real Priestess fights/reset/rematch. Offline20 model+10 editor/input/privacy+10 integrity cases PASS. Detailed evidence/limits: docs/TEST-PLACEMENT-2026-11-14.md.
- Original user exports unchanged. No PR/message/publication; extender remains separate. Long physical RMB drag, extreme width expansion and complete instance/RNG snapshots remain unverified.

## 2026-11-13 — local editor and diagnostics follow-up

- Preserved previous dirty Sandbox/terrain work and a private source baseline before editing. Separate extender branch remains independent; no release ZIP update, PR, push or maintainer contact.
- Reproduced the reported Priestess failure in the real process: add rebuilt every unit, native creation changed random known spells, and the attempted restoration randomized them again and failed. Export was not involved.
- Native inspection confirmed existing incremental deployment skips deployed living units. Add now creates/configures only new units. Separate validated spell-list restore and non-primary unit removal support deterministic supported configuration and failed-new-placement cleanup.
- Added actual native camera conversion and Idle drawing APIs. Found/fixed a post-WAIT frame-depth guard error through visible testing, then verified native and visible direct placement.
- Replaced separate Add workflow with five-row bottom-right search/Select, top team choice and native map default; context/Move and formations retained. Clear keeps the native primary commander.
- Added bounded diagnostics with actual saved/native spell lists, before/after/recovery, build/source fingerprints and unique filenames. Local paths and credential-like values are filtered; unavailable clock/mod-version data labelled.
- Visible tests: search `ano`, two successive Priestesses across teams with original ID/HP/spells preserved, context priority, Move, resize then placement, actual tree refusal and checked export. Native tests: twelve additions, configured copy/move/delete, eight guards, save/load/recovery, two Priestess fights/reset/rematch, Plain/Forest conversion and post-next WAIT. Offline: 20 model and 8 editor checks.
- Full physical right-drag, unrestricted pan/zoom, emergency large-roster growth and complete native-instance snapshots remain unverified. Detailed evidence and limits: docs/TEST-EDITOR-2026-11-13.md. New API contract/proposal stays in the separate extender checkout.

## 2026-11-13 — scope and baseline

- Request: independent public Lua sandbox project, build on current CoE5SE dev, test actual combat early. No extender changes, no invented APIs/values, no automatic contact with the author.
- Existing project folder was empty. Repository lookup through GitHub connector and authenticated CLI found no SandboxOfElysium repository. Available account: Chazammm.
- Owned Steam app 1606340, build 26458448, native Windows x64 CoE5 5.43. Scanner found no anti-cheat. Local paths are intentionally excluded from public notes.
- Installed extender DLL metadata: 3.2.2, SHA256 `87e70dead42341573889641447d04c700af359243696a57b32e89a4fac682e8a`.
- Examined dev: `57abc69a2ddb272a5b9049b4a561367066d9d99e`, metadata 3.3.0/API 11. Built unchanged with existing llvm-mingw 20260922. Local plugin hash: `6faf1c2526dd5c50568d680271c3163e71f04115e610dcf08a0bfe4b8c41d62f`. Tracked upstream diff stayed empty.
- Relevant API reference, test-field source, bindings and examples inspected. An existing local workbench provided a starting point for profile isolation, revalidated here.
- Knowledge-base cache had no matching CoE5 note; live index and current primary sources consulted. Findings are prepared locally in the English API handoff. No external knowledge-base PR or message was sent.

## Isolated oracle and first vertical slice

- Ignored `private/lab/runtime` contains a private executable/dependency copy. `COE5_SAVE` points only at `private/lab/profile`; `COE5_DATA` reads the owned installation's data. A copied configuration is backed up in the lab; no real saves were loaded.
- A sandbox-account process was not targetable by desktop automation. It was stopped by exact PID; later launches ran in the visible user desktop with the same private environment.
- Fixed initial mod metadata/icon requirements (native banner must be 256×64).
- Actual first main-menu battle: one Spearman vs two Goblins. Winner A, final round 4, surviving Spearman 4 HP. Report retained in docs/evidence/initial-battle.ini.

## Implementation and native regressions

- Implemented separate model/catalog/runtime/report/UI modules. All engine operations use public coe5 methods. No DLL/plugin hooks or upstream edits.
- Native grass field uses slots 0/24 with opposing teams. Colors are temporarily applied and restored separately from team membership.
- Native movement validates anchors, footprints and blockers. Candidate fields implement additions/deletion and deterministic re-placement; restoration errors are visible. No dummy combatants are used.
- Formations: native Single, horizontal/vertical counts 1 and 15, squares 2/3/4 all passed. Pure Lua covers every row count 1–15.
- Copy/move/configured-item preservation, deletion, INI roundtrip, same-color hostility, small battle/reset/rematch and 100-vs-100 battle passed inside the real game.
- Width observations: 32 small, 34 at 100 vs 100, 84 for 500 vs 500 created/deployed. Only the 100-vs-100 case was actually fought. First large battle: 98/100 Spearmen survived; 0/100 Goblins survived.
- Private copy of installed CrabCult activated: Shorebound Initiate (#2000) fought and won against a Goblin. Visible browser also selected/placed an Abyssal Shellback (#2004), confirmed in native view. No faction files are published; complete faction campaign effects are not initialized.
- Catalog search, Idle pictures, sorting, context priority, move, explicit cancel, Clear, scenario load, combat start and report were operated through the actual visible game UI.
- Right-drag logic exists but a long physical right-drag is not fully acceptance-tested. Native wheel scrolling and attack-artwork selection are not claimed.

## Corrections and confirmed constraints

- Move originally allowed a held click to fall through to placement. Corrected branch and release guard; visible move subsequently kept count 1. Explicit cancellation button works; unreliable automated Escape behavior is not promised.
- Name-only spell keys collided. Preserved failed native result; changed to ID+name. Native removal/re-memorization then passed on an Old Wizard (8 known, 4 memorized).
- Saving/recreating that Old Wizard produced a different starting spell set. Exact restoration was refused rather than silently randomized. This can block additions/copy/delete/reset when rebuilding randomized casters.
- Item event helpers work, but anatomical slot preflight/replacement guarantees remain unclear. Production item assignment stays disabled.
- Native test field fixes terrain 0, offers no manual width presets. World terrain helpers are not assumed to rebuild the test field. Terrain selection, base magic upgrades and reliable mod provenance remain gaps.
- Actual post-fight UI disproved native final-scene retention: living Spearman 6 HP / 1 kill, both battle coordinates nil, empty native terrain on draw. Return-time coordinate count was zero. BATTLE_TURN_EFFECTS aftermath observation separately captured one survivor position before cleanup; no native final-scene reconstruction is claimed.
- Native kills and original roster outcomes are exported. Direct synchronous HP-loss attribution is explicitly partial; full damage and all-cast telemetry are unavailable/unproven.

## Delivery and remaining work

- 16 offline model tests pass; all distributed Lua files parse. Native evidence retains both failures and corrected regressions; see docs/TEST-RESULTS.md.
- README includes installation, uninstall, compatibility, data/report paths, limitations and AI/tool credits. docs/API-GAPS.md is the English handoff for musical_pianist.
- Package/repository use explicit original-file allowlists. Private game/runtime/config/key copies, upstream sources/binaries and copied mods are excluded.
- This is prototype 0.1.0, not full acceptance. Next work depends on clarified/extended test-field configuration, safe state snapshots, slot compatibility and event/projection APIs, followed by full physical drag/UI and randomized-caster acceptance.

## 2026-11-13 — authorized separate terrain API experiment

- Preserved old dirty lab and existing experiment notes. Fetched full official dev at d96f2b784e97e115022a2598da2c821dd9520135 (3.4.0/API 11) into sibling current worktree/branch.
- Added strict shared terrain parser and read-only capability query. Only loaded vanilla Plain 0 / Forest 2 accepted; other terrain refused. Omission/positional calls keep legacy setup.
- Native investigation showed ground-only initialization was wrong: first Forest appeared snowy and empty. Corrected with temporary Elysium plane, native fixed temperature 25 and one-square native ground helper; normal battle setup creates vegetation.
- Baseline close left squareArmy modified because its backup followed commander creation. Fixed save ordering and guarded rollback, with full borrowed-record readback and neighbor checks.
- Real isolated tests: visible Plain/Forest, native obstacles/placement/AI fights, 14 invalid inputs with reuse, ten alternations, legacy default fight and table testBattle. Explicit one-time fault build tested rollback after initialization; final build has no injected failure.
- Sandbox capability selector, terrain persistence/reporting and native objects added after corrected Forest acceptance. Manual UI exposed blocked old grass positions; added explicit native-deployment preparation, and reran actual Forest save/load/exact Reset/Rematch with production modules successfully.
- 20 offline model/guard tests and 21 actual C-parser cases pass. Broader campaign climate, water/siege/other planes, empty-record runtime test and Mac remain unverified. See docs/TERRAIN-EXPERIMENT-2026-11-13.md and generated evidence.
- English local PR draft prepared in the original lab; nothing sent, pushed or installed into the regular game.

## 2026-11-13 — double-click development test launcher

- Added root `SandboxOfElysium-Testen.bat` backed by a Windows-PowerShell-compatible preflight/build/sync/launch script. Default console waits for the game and pauses on launcher/game errors.
- Reused the terrain lab, with strict identity/known-game/reparse-point/process checks. New private startup mod echoes a fresh nonce through actual coe5 INI storage and reports loaded Plain/Forest capability; no automatic battles or extra probe menu are enabled.
- Build helper accepts a separate output directory; source/resource/compiler hashes determine rebuild/cache use. No edits to the extender checkout were required by this launcher work. Existing source changes and test assets were preserved; no files deleted.
- Actual BAT runs tested clean build, cache reuse, launch from a different working directory, three fresh profile handshakes, missing helper, unsafe identity, real error pause and duplicate launch rejection. Windows PowerShell lacked Get-FileHash here; launcher uses .NET SHA256 instead.
- Visible Sandbox opened; Plain/Forest switched; native deployment and both native views confirmed. Forest Spearman vs Goblin fought through the actual Start battle button, A won round 3. This completed the earlier outstanding manual native-deployment button test.
- Regular config, installed extender and installed game EXE hashes unchanged. No normal save loaded, no release/PR, no experimental DLL added to public package inputs. Full scope and untested failure branches: docs/TEST-LAUNCHER-2026-11-13.md.
