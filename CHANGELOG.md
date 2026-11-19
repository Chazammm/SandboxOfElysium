# Changelog

## 0.2.0-rc.1 - 2026-11-19

- Prepare the non-naval Sandbox candidate with native unit View, amber placement preview and the guarded exact deployment fix for the 61-unit Guard Tower scenario.
- Keep the 21 supported land, siege and water choices with independent actors. Fleet saves explain why their ship and passenger setup cannot be opened.
- Gate editor startup on compatible retirement and restoration capabilities. Keep the mod package separate from the Extender and all private test data.

## Unreleased local development - editor.16, 2026-11-17

- Add verified Coastal Hamlet, Sea and Deep Sea (21 choices total), using actual native water cells, hazards and combat. Keep all18 previous maps and controls.
- Warn about native drowning; refuse unsupported ship/passenger transport before creation or battle. Keep saved setups and previous reports when native battle start is refused.
- Separate experimental native water query and verified sea/boat-count cleanup; no Extender binary is bundled. [Tests and manual plan](docs/TEST-WATER-COAST-2026-11-17.md).

## Unreleased local development - editor.15, 2026-11-17

- Add six verified vanilla sieges: Guard tower, Watch Tower, Castle, Citadel, Town and City. Keep Fortified Hoburg and all eleven neutral contexts (eighteen choices total).
- Reuse native structure provenance, exact restoration, team roles and strict footprint passability. Native parapets are legal where the game allows them; gates reject overlap. Keep names, equipment, magic, zoom and log controls.
- Separately read/verify native specialized tower context and restore its previous value on close. No modified Extender is bundled. [Tests and limitations](docs/TEST-SIEGE-EXPANSION-2026-11-17.md).

## Unreleased local development - editor.14, 2026-11-17

- Hide the actual native log overlay during preparation. Keep the existing usable map area and native projection, zoom, pan and placement.
- Start every battle with the native log visible. Add a labelled Hide/Show button during combat and in the post-battle field; preserve message generation, reports and native controls.
- Use actual visibility/rectangle readbacks for log input priority and dismiss stale context popups when toggling. Missing API support remains explicit.
- Retain editor.13 zoom and Fortified Hoburg. [Tests and limitations](docs/TEST-LOG-LAYOUT-2026-11-17.md).


## Unreleased local development � editor.13, 2026-11-17

- Fit the actual playable field into the usable editor area, preserving aspect ratio and native pointer mapping. Add Fit, 10�200% native zoom and full reachable pan bounds; keep wheel/menu priority and existing formation controls.
- Enable Fortified Hoburg only with the matching native structure-provenance contract. Preserve native walls/gate, actual siege movement/battle, and exact Save/Load/Reset/Rematch. Structures remain separate from army counters and editing.
- Use native strict full-footprint passability for proven map scenery in a verified siege; keep unknown objects and actor collisions blocked. Preserve structures across placement/configuration rollback and fail closed on provenance/cleanup failure.
- Add focused offline/native regressions and [exact version-specific evidence](docs/TEST-ZOOM-FORTIFICATION-2026-11-17.md). Separate Extender source, no binary bundling, PR modification, publication or release.

## Unreleased local development — editor.12, 2026-11-17

- Fix rejected/deleted regenerative actors with verified permanent native retirement in the separate experiment; preserve recovery and lock on unverified cleanup.
- Change unique policy in place without rebuilding scenery or actors.
- Add native Zoom -/+ and map-only mouse-wheel zoom, fixed UI and fresh-draw input barriers. Menus, lists, focused text fields and configuration windows keep scroll priority.
- Add a formation-size minus beside plus. Rows stop at one and squares at 2x2; Single has neither size button. Existing plus behavior is retained.
- Add right-panel new-only starting items, Single count1, and explicit both-team Clear All Held Items with per-actor rollback/spell/injury safeguards.
- Add focused offline/native tests and bounded current-life/busy-identity diagnostics. See [exact evidence and limits](docs/TEST-EDITOR-CONTROLS-2026-11-17.md). No binary distribution or submitted PR changes.


## Unreleased — editor.11 verified stock contexts, 2026-11-16

- Preserve the tested editor.10 source in a local checkpoint, separately from its experimental Extender source.
- Add Farm, Village, Hoburg Village, Oasis and Tent Village only after native context, obstacle, placement, persistence, battle, Reset/Rematch and cleanup acceptance. Keep the six existing terrains, UI controls and placement/recovery logic.
- Show verified template availability separately from the read-only 59-template inventory. Include bounded observed native context in diagnostics; selection before load is not presented as a full environment snapshot.
- Keep failed rural candidates, siege/gate, sea/coast and underground contexts unavailable with documented blockers. A separate general-purpose context API proposal remains local; no new PR or DLL distribution.
- Add process-local muted launching with `-Muted`, and require it for agent-run isolated instances. See docs/TEST-VANILLA-PRESETS-2026-11-16.md for actual native and visible results.

## Unreleased local development — editor.10,2026-11-16

- Add individually scoped native names in the existing Name tab, native Inspect and original combat messages through a separate experimental API. Shared unit templates and submitted PR #2 remain unchanged.
- Enforce32 Unicode code points/47 UTF-8 bytes, show counters and an explicit too-long error, retain the previous value on refusal and offer clear/explicit legacy-label promotion.
- Preserve names through Move/Copy/Save/Load/Reset/Rematch; schema4 stores exact UTF-8 as hex, keeps formats1–3 readable and migrates to a new filename. Add bounded name provenance/readback diagnostics and named report entries. Native log lines still have a63-byte whole-line bound; no full campaign naming or serialization claim.
- See [naming evidence](docs/TEST-NATIVE-NAMES-2026-11-16.md). No modified Extender binary is bundled or published.

## Unreleased local development — editor.9,2026-11-16

- Add a verified-field picker with Jungle and a read-only inventory of59 native templates/356 vanilla terrain records; unsupported water/siege/plane contexts remain explicit.
- Add tested Sandbox minimum sizes32/50/70/160x20 with native expansion; retain automatic default and exact-cell safety. Fix rollback to use the last verified setup rather than pending menu size/terrain options.
- Add schema3 model identity persistence and bounded HP/XP/kills/injury-bit restoration through a separate experimental API. Preserve old formats with absent-state notices and migration to a new filename; full native state/scenery remains incomplete.
- Add new-only starting-equipment omission with normal default, exact spell preservation, cursed-item handling and implant refusal. Copies/restores keep saved equipment.
- Add Modded Units based on the actual defining-mod getter and a separate no-definition category; verify CrabCult enabled/disabled and a deliberately modified vanilla definition.
- Point the local BAT at the separate release-next worktree; derive required DLL resource version from upstream's header. Normal game/profile and submitted PR #2 remain unchanged; no push/release/binary bundle.
- See [current tests and limitations](docs/TEST-RELEASE-NEXT-2026-11-16.md) for offline/native/visible evidence and preserved failed candidates.

## Documentation and upstream API review — 2026-11-15

- Maintain current documentation, installation instructions, launcher messages and future repository work in English. Earlier detailed reports have English consolidations and links to their preserved source-era originals in Git history.
- Prepare the separate source-only CoE5SE 3.4.4 contribution stack, capability matrix, English PR drafts and exact native test bindings. Product Lua is unchanged; no Extender binary, new release or PR is included. See docs/TEST-API-CONTRIBUTIONS-2026-11-15.md.

## Unreleased — editor.8 explicit cursed removal, 2026-11-15

- Permit explicitly confirmed removal of one held cursed item through a capability-gated, identity/position/item-bound native transaction. Keep ordinary cursed replacement protected; never change a shared item definition.
- Support removing an existing eye/heart implant without healing its permanent native injuries. Keep new implants unsupported, and verify the native organ-injury mask on success and rollback.
- Preserve the live actor, exact known/memorized spells and other actors. Refuse bonus removal if it invalidates memorization; the user chooses which spells to deselect.
- Reconstruct saved supported equipment/spells even when a fresh actor has unwanted random cursed starting items. Existing implant layout restoration cannot add another implant. Full native injury persistence remains unsupported and is documented.
- Retain Select-to-deselect. Correct two placement-test fixtures to explicitly select their intended unit. See docs/TEST-CURSED-2026-11-15.md for actual diagnostic replay, visible/native evidence and limitations. No Extender binary is bundled.

## Unreleased — editor.7 battlefield configuration window, 2026-11-15

- Follow-up: clicking Select again on the same unit/item clears its selection. No selected unit means no placement or preview; existing-unit context/Inspect stays available.
- Keep configuration on the map: Units/Items catalog tabs, live item search and slot/source filters, native item icons/card, right-click equip, anatomical choice and explicit replacement/removal.
- Add a draggable, resizable, clamped per-instance window with Items / Magic Schools & Spells / Name. Consume its pointer/text input without editing the map; keep genuine native Inspect read-only.
- Add Modded Items and Modded schools filters backed by observed accepted loaded-definition writes in the separate Extender. Include native schools with observed mod spells; retain Unknown origin and avoid numeric-ID guesses or full provenance claims.
- Adjust existing base levels 1–3, preserve higher known spells, refuse invalid memorization unchanged, and unlock eligible spells through the selected base level without memorizing. Exact reconstruction supports formerly higher known spells without randomization.
- Persist optional individual Sandbox display labels separately from native names/type identity. Existing placement, unique copies, empty editor and exact configuration recovery remain guarded.
- See docs/TEST-PANEL-2026-11-15.md for visible/native/offline evidence, failed candidates and limitations. Separate local Extender only; no binary distribution, release, PR or push.

## Unreleased — editor.6 equipment and base schools, 2026-11-15

- Add anatomical equipment positions, item name/slot search, identity-bound explicit replacement/removal and native compatibility/readback through the separate local Extender.
- Increase existing actual base schools up to level 3, with native bonuses kept separate; learn spells without replacing random originals, and select memorization under native limits. Native Inspect reflects the configuration.
- Add schema 2 positions/item IDs and base-school identities; preserve exact known/memorized order through configured Copy/Move/Save/Load/Reset/Rematch. Retain schema 1 and fail closed on unavailable APIs or ambiguous legacy items.
- Require complete twenty-position readback and quarantine unverified rollback or false success; extend bounded diagnostics with configuration stage, identity, base/template/bonus/effective levels and rollback status.
- Add private native mod/expanded-slot/duplicate-spell probes and 16 offline identity/persistence/recovery contracts. See docs/TEST-LOADOUT-2026-11-15.md for actual acceptance and unsupported cases. No Extender binary distribution, release, PR or push.

## Unreleased — editor.5 final snapshot and empty editor, 2026-11-14

- Capture actual native unit/cell state after aftermath and before cleanup in the separate Extender; draw verified living survivors and summons as a read-only snapshot with native footprints and owners. Distinguish partial coverage and current-record Inspect from a retained full native scene.
- Add a capability-gated commander-free editor. Both teams may be empty, Clear removes all actors, empty/one-sided scenarios persist, and battle start requires both teams before changing state. Legacy callers retain the primary-commander guard.
- Fix the main-menu Ranged classification through a narrowly permitted template-only native query. Unknown results are labelled; native semantics include spell attacks.
- Separate setup status, battlefield actions, scenarios and tools with native section headers; retain a separate Main menu row and safe locked-state recovery. Name missing active mods in Load refusal.
- Reproduce and fix a large-unit deployment cycle in the actual ten-unit user setup: park all still-blocked actors once outside every destination footprint, then require exact global final placement. Never repeatedly park one unrelated actor.
- Verify active CrabCult content in the current build: visible Abyssal Shellback search/placement/native Inspect/battle/snapshot and native Shorebound Initiate + Shellback combat/reset. Third-party files remain private and optional.
- Extend the separately verified land-terrain policy and preserve exact-position refusal/recovery. No automatic scenario redeployment, modified Extender distribution, PR or release.
- See docs/TEST-BATTLEFIELD-2026-11-14.md for actual UI/native/offline evidence and limits.

## Unreleased — editor.4 footprint, Inspect and caster validation, 2026-11-14

- Reproduced the actual six-unit God Emperor failure: the old Edit primitive allowed six Solar spells against native capacity four. Guard individual edits and preserve invalid recovery data; user-selected corrections are verified and saved as separate copies.
- Add native footprint-aware previews and formation/drag spacing, with partial geometry/occupancy status and native placement authoritative.
- Add genuine native instance Inspect in read-only mode, with exact spell preservation, input ownership and fail-closed state verification.
- Extend school/ID/allowance diagnostics and separate API documentation. See docs/TEST-INSPECTOR-2026-11-14.md for actual test status and limits.

## Unreleased — editor.3 interface and field lifecycle, 2026-11-14

- Reproduced surviving God outside the temporary square; separate extender now tracks creation provenance and generations for cleanup and reports exact reopening failures.
- Live inline UTF-8 unit search, measured sprite fitting, explicit report return/rematch/main-menu actions and nonoverwriting report archives.
- Optional sandbox-scoped independent copies of unique creatures, capability-gated and saved with the scenario. Default guards and placement/integrity checks remain active.
- See docs/TEST-INTERFACE-2026-11-14.md for actual native/UI results and remaining limits. No modified extender distributed with the mod.

## Unreleased — editor.2 placement/deletion fix, 2026-11-14

- Reproduced the user's alias pattern: native unique-unit creation reinitialized one Rider; multiple models referenced it and cleanup could retire the shared actor. Separate extender rejects conflicting requests before native mutation.
- Verify model/native bijection, life/type/team, full footprints, saved configuration and global final deployment. Verify rollback independently of return booleans; lock editing and preserve recovery on unverified state.
- Remove phantom hit-test fallback; guard edit/copy/delete/memorize/fight. Stable SDL buttons preserve intentional drag without same-cell frame spam. Richer bounded diagnostics retain the first integrity failure.
- Visible 1×1/2×2/3×3 delete/reuse, unique refusal, overlap and Forest tests; nine native groups and 40 offline cases passed. See docs/TEST-PLACEMENT-2026-11-14.md. No modified extender distribution.

## Unreleased — local editor follow-up, 2026-11-13

- Incremental placement preserves existing native units instead of re-randomizing their spells. Separate experimental test-field APIs restore exact known/memorized lists and remove extra units safely.
- Native battle map is the default with the local projection API. Compact five-row search/Select menu, top team choice, context priority and existing formations retained; no separate Add unit coordinate workflow.
- Bounded Export Diagnostics with unique files, build/source fingerprints, saved/actual spells and before/after/recovery details. Reserved diagnostic filenames and privacy filtering.
- Actual Priestess reproduction and successful native/visible regressions; configured copy/move, save/load, reset/rematch, resize, blocked-tree cleanup and Plain/Forest checks. See docs/TEST-EDITOR-2026-11-13.md for evidence and untested drag/camera limits. No release or experimental binary distribution.

## Unreleased — local terrain experiment, 2026-11-13

- Root-level Windows BAT launcher for the current local Sandbox, guarded private profile, automatic separate extender builds/cache and runtime capability/profile confirmation; includes actual BAT/UI tests and instructions (now maintained in English).

- Capability-gated Plain/Forest selector, terrain scenario validation/persistence and report metadata, using a separate experimental CoE5SE 3.4.0 patch.
- Explicit native-deployment preparation when changed terrain blocks saved cells; exact saved deployment remains required for Reset/Rematch.
- Native terrain objects displayed in the planning grid; game placement remains authoritative.
- Isolated terrain lab, 20 offline model/guard cases, 21 extender parser cases and documented real-game terrain/rollback/Forest integration evidence. No campaign-equivalence claim, release or regular-install update.

## 0.1.0 — 2026-11-13

Initial experimental prototype: main-menu entry, native grass test fields, team colors, cell editor, formations, native unit placement, context operations, loaded monster catalog and Idle browser, existing-spell memorization, scenario INI validation, native fights and partial reports. Includes real-game evidence, a capability inventory and an English API handoff.

Not a completed implementation of the full sandbox specification. Terrain selection, manual size presets, guaranteed anatomical-slot equipment assignment, base magic-level upgrades, complete combat telemetry and a retained native final deployment remain unavailable or unverified through the examined API. Right-drag placement is implemented but lacks a full physical drag acceptance test.
