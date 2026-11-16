# Release-next development and verification — 2026-11-16

## Delivery status

Local Sandbox **0.1.0+editor.9**, branch `development/release-next-editor9-20261116`; local Extender branch `experiment/sandbox-release-next-20261116` in the separate `SandboxOfElysium-ExtenderLab-next` worktree. These are uncommitted development changes, not a complete first release or a published update.

At intake, official CoE5SE dev remained `df09497f04a39ff8fb7b0979dedde7dfed120c64`; [submitted PR #2](https://github.com/musical-pianist/coe5se/pull/2) was open/unmerged at signed `816671921e1b0499b2e69ead87dc19c112304004`. That branch/PR is untouched. The public [Sandbox repository](https://github.com/Chazammm/SandboxOfElysium) remains on editor.8 source with the earlier review documentation. No new PR, push, contact, binary package or release was made.

| Requested feature | Current result |
|---|---|
| All vanilla terrains/maps | **Partial.** Actual inventory and selection UI; six verified neutral land contexts. All specialized template contexts remain unavailable. |
| Selectable sizes | **Implemented and native-tested as minimums.** Default native automatic; Small 32, Medium 50, Large 70, Extra Large 160 columns, 20 rows; native expansion retained. These names are Sandbox policy, not native enums. |
| More reliable restoration | **Partial.** Schema 3 preserves model identity gaps and supported configuration plus HP/XP/kills/injury bits. Full native state and exact scenery snapshots remain missing. |
| No starting equipment | **Implemented with explicit refusals.** New placements/formations only; copies/restores retain captured configuration. Implant initialization cannot be undone safely. |
| Modded Units | **Implemented and tested.** Defining mod only; a modified vanilla definition is not classified as mod-defined. Nil remains unknown modification provenance. |

## Actual terrain and template inventory

The owned Windows 5.43 game has **59 installed `.coem` templates**. All examined headers have a 160x20 stored canvas; this is **not** the effective battle width. Native setup selects/trims/centers a template or generates a general field from effective battlemap flags and environment. A world terrain with `batmap=0` does not constitute a unique named template.

A fresh native catalog run with CrabCult and all definition QA fixtures disabled found **356 loaded vanilla terrain records**; the CrabCult-enabled intake had 360. The [complete vanilla metadata CSV](vanilla-terrain-catalogue-2026-11-16.csv) lists exact loaded IDs/names, native battlemap flags, terrain flags and neutral-field availability. It contains metadata only, no game assets. Many records share a generated/template selection. Low-byte template selectors and context flags must not be treated as an already implemented editor API.

The 59 installed template names are:

`agarthafort`, `archmage`, `bramble`, `bridge`, `capital`, `cavefort`, `cavefortwide`, `cavetunnel`, `cavetunnel2`, `citadel`, `city`, `cloudcastle`, `cloudtower`, `cloudwall`, `coastville`, `corkscrewtowers`, `dark1`, `dark2`, `dwarfcity`, `earth`, `fairycircle`, `farm`, `flamewall`, `ford`, `greatwall`, `highwall`, `highwalln`, `hoburgh`, `houseruins`, `jerusalem`, `junglevillage`, `kingscastle`, `lionvillage`, `lowwall`, `lowwalln`, `monasteryn`, `natcavefort`, `natcavefortwide`, `oasis`, `oasisupgr`, `outpost`, `palisade`, `palisaden`, `port`, `portupgr`, `stonetower`, `tentvillage`, `towerbridge`, `town`, `townruins`, `village`, `villageupgr`, `widebridge`, `widebronzewall`, `widewall`, `widewalln`, `witchtower`, `woodentower`, `ziggurat`

The picker advertises only Plain 0, Forest 2, Mountains 12, Swamp 107, **Jungle 115**, Desert 117. Jungle's loaded name, characteristic 0x800000000000 flag and general-map/no-forbidden-context policy are checked. Native neutral ground 2, jungle scenery, large actors, movement, cleanup and two completed fights were observed through the native test matrix. The old five contexts passed again.

| Category | Native context still needed | Editor availability |
|---|---|---|
| General neutral land | Correct terrain identity/ground, Elysium plane, neutral temperature 25, native scatter/deployment | Six verified fields above |
| Water/coasts/ports | Neighbor and water environment, at-sea/amphibious behavior, shore/port selection and deployment | Unverified; not offered as playable |
| Forts/sieges/walls/gates | Effective fort/template flags, attack/defense and siege context, working walls/gates and native deployment | Unverified; template presence is not acceptance |
| Underground/cloud/other planes | Native plane/environment, underground/tunnel rules and relevant variants | Unverified; neutral Elysium cannot stand in for these |
| Climate, seasons, world effects, upgraded/random variants | Temperature/neighbors/variant selection and applicable faction/world/enchantment effects | Not reproduced or certified |

The read-only template catalogue explicitly labels every template context unavailable. Existing `addBattleMap`/scatter APIs are load-time custom-map facilities; they do not by themselves supply a verified stock siege/water/plane descriptor. A separately documented environment descriptor proposal remains necessary.

## Sizes and safe reconstruction

Native setup has automatic army/context sizing, not Small/Medium/Large enums. Observed native minimum branches include 32 for general fields,50/70 for particular contexts and 160 for another native context. The experiment uses the existing size trace point **before** ground, template/scatter and deployment, scoped to the owned field. It raises the requested minimum, never overwrites a larger native army requirement. Actual 32/50/70/160 x 20 fields completed fights; a 50 minimum expanded to 96 columns for 601 actors.1536 is a native bound, not an exhaustively tested UI size. Arbitrary height is unsupported.

The menu shows these dimensions and preserves native automatic as default; the user explicitly selected tested minimums with expansion. Size/terrain selections are pending until Open. Keep positions verifies all saved footprints; native deployment is a distinct explicit repositioning action. Large fields exceed the native viewport at the normal window width: use Planning grid for the whole field or the documented wider launcher window. No new camera/pan API is claimed.

**Fixed rollback defect:** pending size/terrain choices mutate the current scenario object. Rebuild previously copied that pending object as its rollback source, so a failed70-column request could try to restore 70 rather than the last verified 50-column setup. Rollback now uses `lastKnownGood`. Native six-terrain 50→70 tests and an offline regression verify the old minimum/configuration is restored when exact opening is refused.

Random scenery is regenerated. An early complex Jungle caster/dragon/two-Rider reconstruction was refused with blocked native targets; that exact arbitrary-layout case is not certified. The restoration stress test was isolated on Plain. A separate Jungle matrix passed 2x2 Strange Seraph / 3x3 Apocalyptic Rider placement/deletion, canonical-roster Save/Load and two-fight Reset/Rematch. Neither result proves universal exact scenery restoration. If rollback cannot verify the old model/native configuration/cells, editing locks, a recovery scenario and diagnostic context are retained, and the UI requires explicit recovery. No silent redeployment or successful-rollback claim is allowed.

## Bounded actor state and migration

The separate experimental API adds `testFieldEnvironmentInfo`, `testFieldActorState`, `setTestFieldActorState`, and the optional `minimumWidth` argument. The actor contract is **version 1**, `fullState=false`: positive HP, XP/kills 0..32767 and native injury bits 20..30(mask0x7ff00000), checked against body, footprint and native maximum HP. These bits were matched to the native affliction list. Configuration is restored first, then these scalars/flags with pinned ownership/session/generation and verified rollback. Other status bits are not overwritten. Unsupported readback now refuses before changing the saved actor; it does not throw away its configuration.

Schema 3 retains stable **model** IDs/gaps, next ID, teams, positions, colors, size minimum, unique mode, new-unit policy, per-actor pending omission, exact 20-position item identity, base schools and ordered known/memorized spells. Native handles are intentionally newly allocated, not persisted as identities. Move preserves the live actor; Copy/Load/Reset/Rematch reconstruct and verify supported state. Captured XP 150/kills 3, damaged HP and Crystal Heart removal injury 0x400000 survived the native stress workflow with a Druid's Apprentice, Arcane Frost Dragon and independent Apocalyptic Riders. Removing an implant does not heal its injury. Random spells were compared in exact order; no hidden reroll or repair was performed.

Schemas 1/2 remain readable. They never recorded all this state: load explicitly reports absent health/injury fields. Native defaults cannot be claimed as recovered historical values. Saving a legacy migration requires a **new unused filename**; the original remains untouched. Malformed/partial state fields, reused model IDs, false complete-state claims, changed native body/max HP and missing required APIs are refused. Missing active mods or changed ID/name identities remain a load refusal. Content changes retaining identical IDs/names are not fully detectable.

**Not serialized:** other afflictions/status words, poison/bleeding counters, benefits, opaque active effects, commander data, transformations and complete native memory. Post-battle capture is still the earlier timed actor/cell snapshot after aftermath before upkeep; effects/projectiles/animations are excluded. No campaign-equivalence or full-state claim is made.

## Starting equipment and mod origin

Normal starting equipment remains default. With omission enabled, native NEW_UNIT still initializes normally; protected transactions remove the resulting held non-implant items and compare exact original spell lists/organ flags. This catches normal, random-result and cursed equipment through actual native readback. It does not change shared templates. Implant/permanent-effect items are refused **before removal**; cleanup of the freshly created actor is verified. Equipment bonuses that make memorized spells invalid cause refusal rather than silently changing memorization. Copies and restored scenarios use saved configuration regardless of the new-unit switch.

Explicit QA-only definitions initialized an Amulet of Anti Magic, CrabCult Abyss Fragment (cursed), caster gear and Crystal Heart (implant). Normal/cursed omission and formations/copies/SaveLoad passed; the implant refused without changing the old actors or leaving a phantom handle/cell. Every possible random starting-item combination is not exhausted.

`monsterMod` is upstream definition provenance: `newmonster` records the defining mod, while `selectmonster` does not rewrite that origin. Native tests: CrabCult enabled yielded 28 Modded Units; Abyssal Shellback reported `CrabCult`. A separate QA mod changed vanilla Spearman strength 4→37, while `monsterMod` remained nil and it stayed out of Modded Units. CrabCult disabled yielded 0 mod-defined units, 1851 entries with no definition reported, and no Shellback. The **No mod definition** filter is deliberately not called confirmed vanilla/unmodified.

## Verification performed now

CoE5 Windows 5.43, Steam executable SHA256 `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`. Extender 3.4.4-based private plugin SHA256 **`ade33f020d294c5f6fa9ae87f817e01edf1ba0090894b8c37f740af7577f221f`**, llvm-mingw 20260922, no candidate/fault-injection build flags. Build completed without warnings/errors. Final production Lua hash **`51736686eba9f2244bd0e406f15dbe0c08f6b66dacf91b5fb8ecbe7ee094617e`**; native run manifests retain source paths/hashes and dirty-tree status rather than falsely labeling the new binary as the unchanged submitted 8166719 commit.

- **141 offline assertions** passed, distributed Lua parses, tool PowerShell/Python parse. Actual C terrain parser 21 cases and expanded terrain policy 63 assertions passed; these are not in-game tests.
- **New native API:** 9 groups: metadata, four minimum-size battles, 601-actor expansion, HP/XP/kills/spell independence, native injury transfer, invalid/raw-table/max-HP refusal and rollback.
- **Final production integration:** 4 groups: six-terrain 50→70 resize/preservation, normal/cursed equipment/formation/copy/load, implant refusal/delete/reuse/diagnostic, supported actor state with unique/large deletion/copy/SaveLoad/two battles/Reset/Rematch and deliberately wrong max-HP reconstruction refusal.
- **Older probes rerun on final production Lua:** 16 main groups (empty 5, equipment 7, cursed 2, filters/mod battle 2), 8 fixture equipment groups (includes repeats), placement 4, inspector/repair 4, six terrain groups with two completed fights per terrain. Inspectors preserve the original invalid spell recovery and write only an explicit repaired test copy. Counters, footprints, interior hit tests and spell/item preservation are checked natively.
- **Origin:** enabled/modifying-vanilla and disabled-mod runs passed. Fresh no-Crab environment inventory independently enumerated 356 terrains / 59 templates. Metadata enumeration is not gameplay acceptance for the other maps.
- **Visible ordinary Sandbox:** normal 1200x900 requested window, readable grouped menu, six-field picker, unavailable template catalogue, dimension labels and equipment toggle; Jungle minimum 50; Ranged 721; Modded Units 28; actual Shellback placement/deselection/context/native Inspect 70/70 HP and sprite; new `q9` Save/Load; two round 3 Team A victories via battle/Rematch; survivor view; Back restores 2A/1B; Reset and diagnostics export. Native filename input required physical key events because Unicode automation text injection was ignored. A native battle-message overlay remains visible after returning to the editor. Final UI cleanup hit focus/manual-input protection; only the exact owned test PID was then stopped after evidence capture.

The visible run preceded the final defensive unsupported-state capture refinement; all six final native suites above reran afterward with the final production hash. It is evidence for unchanged UI/successful workflow paths, not a visible exercise of the new refusal branch.

Failed runs are retained privately: real pending-size rollback defect, unsupported exact Jungle reconstruction, test-helper `M.formation` typo, a nonexistent Jungle getter word (corrected to the observed flag), schema 2 assumptions in the old inspector test, a wrapper combining three catalog reads in one callback and exceeding the native Lua step budget, and an inspector selection wrapper that selected no groups. Corrected runs are separately named; none of these failed results was overwritten or promoted to PASS.

Private backups preserve both existing test profiles. The final audit verifies all 385 original-experiment files, all 395 submitted-checkout files, their heads/status/diffs/index, all 13 prior cursed-lab and 87 prior terrain-lab Sandbox data files (excluding generated launch metadata), and three normal-installation controls. The QA last-battle result was archived separately and the original isolated-profile summary restored from its pre-task backup. Earlier scenarios/diagnostics remain unchanged. No normal game/profile/Extender files are updated. The new public files contain source, synthetic QA definitions and sanitized metadata only. Mac compilation/runtime, Linux, multiplayer, all zoom/drag combinations, complete scenery/native-state persistence, every start-item outcome and the unavailable context categories remain untested or blocked.

## User test path

1. Close the isolated game and double-click `SandboxOfElysium-Testen.bat` in the project root. This local branch defaults to the separate `../SandboxOfElysium-ExtenderLab-next`; an explicit `-ExtenderSource` overrides it. The old experiment remains untouched. The BAT was actually used to build the matching hash and confirm its private `terrain-lab` profile at runtime.
2. In Sandbox choose a verified Battlefield, a minimum size (default automatic), and the **New units** equipment policy. Choose native deployment only when repositioning is intended.
3. Place one actor on each team, inspect/configure, then Start battle. Try Save under a new name, Load, Back, Reset and Rematch. Try Modded Units with `-CrabCult` if privately installed. For wide fields use Planning grid or a wider window.
4. For old schemas save a migrated copy under an unused name. On editing lock, Export Diagnostics and use Reopen preserved setup; restart the isolated game if cleanup is unverified. Do not overwrite the original recovery or assume missing full state was restored.
