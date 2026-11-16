# Single CoE5SE API pull request: 2026-11-16

Status: submitted as [CoE5SE PR #2](https://github.com/musical-pianist/coe5se/pull/2) against official `dev`. All seven commits are signed off after the contributor explicitly accepted the current terms and confirmed the right to contribute. The PR is open and unmerged; no modified Extender is distributed. GitHub Actions currently reports `action_required`, so no GitHub build result is claimed.

- Public Sandbox: https://github.com/Chazammm/SandboxOfElysium, version `0.1.0+editor.8`.
- CoE5SE candidate: [pr/sandbox-editor-api-20261116](https://github.com/Chazammm/coe5se/tree/pr/sandbox-editor-api-20261116), `816671921e1b0499b2e69ead87dc19c112304004` (signed submission).
- Official `dev` fetched twice today, still `df09497f04a39ff8fb7b0979dedde7dfed120c64`, CoE5SE 3.4.4/API 14. No new upstream change displaced part of the prepared work.
- Sandbox product-source SHA256: `8b8176fe9662c9e4f4a4a1d46bc4d4d7e5f649df4431b3adbb1487e12cd451fb`. Product Lua is unchanged from the public editor.8 implementation; only handoff documentation changes in this task.
- Windows x64 CoE5 5.43; executable SHA256 `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`. Final private plugin SHA256 `86be1e51416a5000b108f654f9445e45170e74837bc0bfdbfdccb03a62babb4c`.

Submission verification: signed HEAD `816671921e1b0499b2e69ead87dc19c112304004` has the same source tree as tested unsigned `3195a061c78a5932025553f6a2fe4d4d908193a7`; every corresponding commit tree is unchanged. A new Windows build on signed HEAD completed without warnings/errors, and all three binaries matched the tested build byte-for-byte. Existing native/offline evidence below applies to that unchanged source; no additional in-game tests were performed during sign-off finalization. The submitted diff was re-audited: 40 files, 4,670 insertions/16 deletions, only Extender APIs/hooks, tests and documentation. No Sandbox mod, game files, private diagnostics or compiled binaries. Remote PR base/head, all seven sign-offs, complete file list and description were verified. Sign-off identity: `Chazammm <138124106+Chazammm@users.noreply.github.com>`, matched to GitHub username/account ID.

## Scope and review

[Description as submitted](COE5SE-PR-DRAFT-2026-11-16.md) explains each upstream equivalent, extension, dependency, test and limitation. The public [LuaLS API definitions](https://github.com/Chazammm/coe5se/blob/pr/sandbox-editor-api-20261116/coe5.lua) document the new contracts. The historical [import inventory](https://github.com/Chazammm/coe5se/blob/review/sandbox-complete-20261115/docs/sandbox-review/API-INVENTORY.csv) still describes the unchanged production Lua imports; its old multi-PR submission plan is superseded here.

The combined branch was a starting point, not blindly submitted: the new branch starts at current official dev and aggregates the individual Ranged/Core/Presentation/Configuration/Origin work into focused commits. It retains upstream catalogs, `monsterMod`, native ranged classification, twenty-slot helpers, spell primitives, UI, observers and content-write tracking. Old review-only documents and WIP commit history are excluded. Ranged and origin are independent; core → presentation → configuration form the main dependency chain. Creation/generation/removal/cleanup must stay coherent. Forty files/about 4.7k added lines make review substantial, but a single PR is technically practical. All five old individual review branches and the old combined branch remain unchanged.

A fresh native callback test failed before the additional fix: original session 14 became replacement session 15, and outer Add accepted/allocated one actor into the replacement field. This is evidence of a wrong-session mutation during argument validation, not a newly reconstructed explanation of the user's earlier bounded diagnostic sequence. Open/add now pin/recheck field context; Add and Open callback regressions refuse `context_changed` and preserve the replacement field. The final tests pass. Current Sandbox plain setup tables continue to work.

## New tests on the final candidate

Unchanged upstream `src/build.sh`, prescribed llvm-mingw20260922, final clean commit rebuilt without compiler warnings/errors. All nine native runs below were repeated after the final documentation commit, with exact commit, source-tree and DLL hashes recorded privately. **61 passing group executions, 54 distinct named groups**: seven loadout groups repeat with the fixture.

| Actual native suite | Passing groups | Run session |
|---|---:|---|
| Configuration raw-table/identity contracts | 3 | `b828c14bac384537aa61e58f3a038404` |
| Core, including both callback guards | 9 | `b090749953c44a38984df7ed8b800349` |
| Observed content origin | 4 | `11344cd438334f66bea4a950681ce60a` |
| Presentation and timed final capture | 4 | `0b075afef5834e6299d852e10d8a2270` |
| Full native ranged catalog | 1 | `4468446ed9e74d8aa7bf323f4a75c677` |
| Twenty-slot/custom-school fixture and panel | 11 | `4763f1f4c5e845d88fd310d708c9478c` |
| Inspector, spells, six-unit battle/Reset/Rematch, footprint preview | 4 | `22e56b783f59454fbbbc03dde2eaea27` |
| Large/unique/obstacle/failed-cleanup recovery | 4 | `0bba039a968343f3b53e8162c1b9561a` |
| Sandbox standard, empty/cursed/loadout/filters/mods/five terrains | 21 | `817b38c6377e470d868d4dbddb5e3abf` |

Ranged covered all 1,879 named loaded monsters, 721 positives, zero main-menu/field/after-close mismatches and retained unrelated context guards. Native tests include empty and one-sided persistence/refusal, final-unit removal, immediate cell reuse, independently allocated unique instances, full multi-cell footprints, blocked placements, explicit failed-cleanup recovery, exact spell order, items/base schools and combat with Reset/Rematch. The standard terrain matrix completed two fights per supported terrain; the core probe separately exercised each supported terrain. Installed CrabCult's Abyssal Shellback and Abyss Fragment were used; the custom school and same-name spells belong to our explicit QA fixture, not CrabCult.

Also passed: 127 existing Sandbox offline assertions, distributed/candidate Lua syntax, helper PowerShell/Python syntax, 21 compiled C terrain-parser cases, 51 terrain-policy assertions, `git diff --check`, Windows-host preprocessor checks and exact upstream legacy Mac Git-blob comparison. Structural checks do not imply a Mac build.

An initial duplicated declaration was caught during compilation and corrected before acceptance. A first inspector harness run had no private `replay.ini`, stopped at script load and ran no groups. Its log was retained, then the proper existing private fixture was copied and all four groups passed; the entire suite passed again on final HEAD. Failed/unrun runs are not included in the totals.

## New visible workflow

Session `9fe47f638e774e3388a79bd5ecc6909a`, same compiled native source/DLL as final HEAD; the subsequent commit only corrected fixture README prose and its rebuild is byte-identical. A private entry seeded our existing `q4` scenario plus one Apocalyptic Rider per side, then used current production UI/modules. The entry also exported diagnostics after successful builds; it is not distributed.

Observed directly with mouse/keyboard:

- Forest editor, independent large Riders on both sides, A2/B3, visible native sprites and context menu from inside a Rider's 3×3 footprint.
- Deleted Team A's Rider: count became A1. Immediately placed a Spearman into the vacated footprint: A2 again, correct sprite. The other Rider and caster remained.
- Druid's Apprentice Edit showed the cursed CrabCult Abyss Fragment in its actual position, Druidism base 2 and our modded QA base 1; expanded spells showed explicit memorization. This pass inspected configuration; item replacement/learning/cursed-removal transactions were exercised in native suites.
- Two real Forest battles completed Team B, round 2, approximately 11 seconds each. Reports kept starting-team accounting separate from a captured owner change. Post-view showed A0/B4: the original A Druid had changed owner; this was not an extra starting unit.
- Post-field showed the large Rider and Shellback; actual native Rider Inspect displayed 180/180 HP and zero kills. Exit, Rematch, Back to Sandbox and editor Reset worked. Restored setup was A2/B3.
- The normal grouped Sandbox menu was readable with Current setup, Battlefield, Scenarios and Tools sections. Requested window1200×900 resulted in a full962×752 window and800×600 internal resolution at this workstation's scaling.

Five bounded exports recorded zero native issues, five model/native actors and complete owned actor queries. The caster kept known IDs `346,348,1029,344`, memorized IDs `348,346,1029,344` and both base-school levels through deletion, battle restoration, Rematch and Reset. Native IDs changed on reconstruction as expected; saved model identity and supported configuration were retained. Capped exports are not full world snapshots. Save/load, rejected placement, explicit recovery and other mutations were exercised in actual native production suites; this pass did not repeat every action by mouse. Native combat text can remain drawn over the field after battle; controls remained usable.

## Historical evidence and remaining limits

The earlier per-area probes and 39 combined-group executions in [the preceding report](TEST-API-CONTRIBUTIONS-2026-11-15.md) remain supplementary evidence for unchanged areas. The older visible `e2996d24…` build is not substituted for current acceptance. The new callback guard closes the previously documented reentrant-setup coverage gap.

No Mac compiler/runtime test: required Zig0.16 and a runnable Mac game are unavailable. Legacy Mac field code remains the exact upstream blob; new editor capabilities are zero/empty and new options refuse `windows_only`. New native mappings and editor operations are Windows5.43 only. Content-origin Mac portability is not accepted.

Only Plain, Forest, Mountains, Swamp and Desert are supported neutral-land fixtures. Water, siege, special planes and full campaign climate/season/enchantment behavior are outside scope. Final capture covers actors/cells after aftermath before upkeep; `sceneComplete=false` excludes complete effects/projectiles/animations. Inspect uses current native survivor records. Combat attribution remains partial.

Full HP/injury/affliction/opaque-state serialization is absent. Crystal Heart removal preserves a live permanent injury; rebuilding does not serialize that injury. Table exhaustion/compaction, arbitrary mods/campaigns/multiplayer, all zoom/camera cases, sustained drag and exhaustive Unicode/IME use remain unaccepted. This is not the complete original Sandbox feature set.

## Installation, preservation and procedure

For review, build the candidate using upstream's documented compiler/scripts and install output only in your own isolated CoE5 copy/profile. Install the Sandbox source mod separately using [INSTALLATION.md](../INSTALLATION.md). This repository supplies no modified Extender. Capability presence alone is not successful native execution.

The existing **SandboxOfElysium-Testen.bat** still synchronizes the local Sandbox source and builds/uses the separate `SandboxOfElysium-ExtenderLab-current` experiment in its own terrain profile. It does **not** select this PR branch. The final candidate above was tested in the existing separate cursed-lab profile; do not infer candidate selection from launching the BAT. Keep normal saves/settings/CoE5SE separate.

Preservation audit before the authorized documentation edits: all385 experimental source files, dirty status/diff/index, all404 old prepared files, old branch tips, all99 Sandbox tracked/unignored files and all88 original terrain-profile data files unchanged. Normal game, config and installed Extender control hashes unchanged. Our own q4 and old reports remain; changing own launcher context/latest-report bookkeeping was backed up before testing. Private raw logs/diagnostics, game files, QA/third-party assets and Extender binaries stay outside Git.

Current upstream [CONTRIBUTING.md](https://github.com/musical-pianist/coe5se/blob/df09497f04a39ff8fb7b0979dedde7dfed120c64/CONTRIBUTING.md) requires dev base, prescribed builds/native testing, dev notes and every commit signed off. Mac-only gaps, explicit lazy API opt-in instead of a new global settings switch, generated index/site updates and compact helper comments are disclosed in the draft. Prior maintainer review agreement is user-reported; no new issue was opened.

**Contributor decision completed:** the contributor personally accepted the current terms, confirmed the right to contribute and explicitly authorized sign-off/submission on 2026-11-16. The terms grant the maintainer/successors a perpetual, worldwide, non-exclusive, royalty-free, irrevocable license to use/copy/change/sublicense/distribute under any terms; the contribution/sign-off remain public and copyright is retained. Acceptance was explicit; Git identity was separately verified. All seven PR commits are signed off and PR #2 is open for review, not merged.
