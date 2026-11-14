# Changelog

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

- Root-level Windows BAT launcher for the current local Sandbox, guarded private profile, automatic separate extender builds/cache and runtime capability/profile confirmation; includes actual BAT/UI tests and German instructions.

- Capability-gated Plain/Forest selector, terrain scenario validation/persistence and report metadata, using a separate experimental CoE5SE 3.4.0 patch.
- Explicit native-deployment preparation when changed terrain blocks saved cells; exact saved deployment remains required for Reset/Rematch.
- Native terrain objects displayed in the planning grid; game placement remains authoritative.
- Isolated terrain lab, 20 offline model/guard cases, 21 extender parser cases and documented real-game terrain/rollback/Forest integration evidence. No campaign-equivalence claim, release or regular-install update.

## 0.1.0 — 2026-11-13

Initial experimental prototype: main-menu entry, native grass test fields, team colors, cell editor, formations, native unit placement, context operations, loaded monster catalog and Idle browser, existing-spell memorization, scenario INI validation, native fights and partial reports. Includes real-game evidence, a capability inventory and an English API handoff.

Not a completed implementation of the full sandbox specification. Terrain selection, manual size presets, guaranteed anatomical-slot equipment assignment, base magic-level upgrades, complete combat telemetry and a retained native final deployment remain unavailable or unverified through the examined API. Right-drag placement is implemented but lacks a full physical drag acceptance test.
