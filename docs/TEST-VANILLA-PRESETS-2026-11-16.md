# Editor.11 — native vanilla presets and local checkpoints, 2026-11-16

This increment adds five verified native stock contexts. It preserves the current editor controls, placement/deletion/rollback implementation, names, item/spell configuration and battlefield-size policy. It does **not** complete all vanilla battle contexts. No release, push, new PR, modification of the submitted PR branch or Extender binary distribution occurred.

## Source checkpoints and upstream review

| Purpose | Sandbox | Separate experimental Extender |
|---|---|---|
| Tested editor.10 baseline preserved before map changes | `4d1ebd57167f3a0929d46520546cd8f92d7f9e9f` | `63a89850aa6238998fab95c6446eb32d558c0407` |
| Editor.11 map increment | This report's local commit, **Add five verified native battlefield presets and muted agent launches** | `f9e0db30509d54baa226861926e5c1cf491b9945` |

Branches remain `development/release-next-editor9-20261116` and `experiment/sandbox-release-next-20261116`. The private checkpoint manifest records both exact final hashes after commit. Neither checkpoint was pushed. The baseline source-only commit includes the previously uncommitted editor.9/editor.10 source/tests/docs; it excludes private diagnostics, scenarios, game/mod assets and DLLs. [Baseline checkpoint details](DEVELOPMENT-CHECKPOINT-2026-11-16.md).

Official upstream dev was freshly fetched and verified at `be8a2bf7b4fa094d828e2ad56eb0376e51adf3e1`, which squash-merged PR #2. Its existing field lifecycle, Ranged, origin, presentation and configuration work is not proposed again. Naming, bounded actor state, minimum sizes and the new context API remain separate local experiments. The tested experiment was not rebased during this task; a later contribution must port only its new delta onto then-current dev. The submitted review checkout and the earlier experimental checkout were preserved.

Native test platform: owned Windows CoE5 5.43 x64, Steam build26458448; game SHA256 `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`. Ordinary, non-candidate/non-fault DLL used for the integrated matrices and visible tests: `596a7b7459752bb33d480320933fec4faf38a37391edf2db6a624e2e8cdf008b`. Tested mod-tree SHA256: `d08d71dbe14932cbe7747a8c8c3c59d9f1c95920db1efcd0918dc19555ff4700`. All product Lua is unchanged after those tests. Later edits are documentation, the LuaLS API reference and process-local launch options. Compiler: existing llvm-mingw20260922; native builds use existing project build tools. Test DLLs remain private.

## Playable native presets

All five new presets use the real native terrain/ground/template/scatter/deployment path, in the existing owned Elysium plane-0 field with temperature25. These are neutral battle contexts without campaign garrisons, siege or sea/underground state.

| New choice | Loaded terrain ID | Observed native stock template | Effective native battle flags | Current acceptance |
|---|---:|---|---:|---|
| Farm | 5 | farm | 49 | Integrated API matrix and visible battle/Rematch/Reset |
| Village | 18 | village | 40 | Integrated API matrix |
| Hoburg Village | 70 | hoburgh | 46 | Integrated API matrix |
| Oasis | 98 | oasis | 52 | Integrated API matrix and visible editor/native Inspect |
| Tent Village | 109 | tentvillage | 45 | Integrated API matrix |

The original **Plain0, Forest2, Mountains12, Swamp107, Jungle115 and Desert117** remain selectable, with their policy and native regression coverage retained. There are eleven verified choices, not 59 playable maps. Repeated world-terrain variants are not automatically separate presets.

The read-only catalogue still inventories59 stock template names, including installed headers. A stored160×20 canvas is not an actual field-size promise. It now distinguishes a verified context through listed terrain IDs from a file whose required context remains unverified. Existing size choices remain Native automatic or tested minimums32/50/70/160, with native expansion; no fixed maximum army size is promised.

## Separate native API and safety

The separate Extender proposes `testFieldEnvironmentState()` version1 and additive `testFieldEnvironmentInfo()` metadata (`environmentStateVersion`, `templateContextVersion`, template `verifiedTerrainIds`, terrain `verifiedTemplateField`). Current context includes plane/ground/temperature/effective fort flags, sea/siege/underground flags and effective dimensions. Diagnostic exports include a bounded summary without absolute paths.

The observation hook records the bounded native template basename **before loading**; this is not a loader-success receipt or full environment snapshot. `setupReturned` means real BATTLE_SETUP returned. Native actor/grid integrity and current context are verified separately. Native before/after snapshots confirm the query is read-only.

New stock presets require exact loaded name/terrain flags/battle flags and a readable installed header. After native setup, require the expected observed basename, no custom addBattleMap replacement and the expected effective context. A mismatch cleans up before deployment and returns `field_context_mismatch` (or `cleanup_unverified` if cleanup cannot be verified). The normal Sandbox recovery and quarantine protections remain in force. A private owned-map override fixture actually exercised refusal and restored the previous named/caster setup exactly. No map asset is included in either repository.

For musical_pianist: the general contract, native evidence locations, compatibility and future structure/neighborhood proposals are documented in the separate checkout's `VANILLA-CONTEXTS-EXPERIMENT.md` at revision `f9e0db30509d54baa226861926e5c1cf491b9945`, and in its updated `coe5.lua`. This is a local proposal, not a submitted change to PR #2.

## Fresh offline and native API tests

The initial editor.10 audit passed the existing12 offline suites/155 cases, syntax, diff and launcher path checks; that initial audit launched no battle. After the map changes, all13 offline suites/162 cases passed, including seven focused new map contracts. Lua syntax includes all three opt-in native map probes. C policy tests pass154 assertions with `-Wall -Wextra -Werror` in ordinary and explicit candidate modes. These offline checks do not simulate native combat.

On the ordinary DLL above:

- **Five integrated map matrices PASS** (`supported-empty-5/18/70/98/109`). Each selects/initializes the actual stock context, verifies native blocking objects and rejected placement without model change, Move/Copy and native names, caster Amulet of Anti Magic plus exact ordered known/memorized spells and supported condition, disk Save/Load, actual native movement, two naturally completed battles and exact Reset/Rematch. Each also places/deletes a3×3 Apocalyptic Rider, checks every footprint cell and immediate reuse, removes all actors, Save/Loads an empty setup, refuses an empty battle unchanged, places a Team B actor after clearing, and verifies cleanup of the borrowed center/neighbors/plane.
- **Eleven environment/size groups PASS** (`supported-environment-and-sizes`): guarded metadata/unsupported IDs/59-template inventory plus five new presets at native automatic and minimum160 widths. These include ten additional naturally completed native battles and read-only context equality checks.
- **One custom-template refusal/recovery group PASS** (`custom-template-refusal`): real addBattleMap registration with a private copy of the user's owned farm file, field-context mismatch, previous exact native names/items/spells restored, healthy lifecycle. The copy remains private and is not normally registered.
- **45 existing native regression groups PASS**: naming3; standard configuration/empty/filter/mod checks16; explicit loadout fixture8; placement/unique4; Inspector4; original terrains6; release-next4. Test drivers call the production Lua and actual native APIs; these are not visible mouse tests. Release-next includes completed battle, Reset/Rematch, bounded injury/HP state and exact item/spell restoration.

Existing runtime, integrity, placement, input, loadout, naming and persistence implementations were retained. The new model change is the five terrain names; UI changes are picker/catalogue wording and verified status. No silent spell randomization or saved-position redeployment was added.

### Failed investigations and test-harness limits

All failed evidence was retained privately. An early Farm test failed because the QA writer tried serializing Lua booleans to INI and the test assumed a nonexistent unit-kind field; the test helper was corrected and fresh native matrices passed. This was not presented as a game success.

Initial terrain and release regression runs hit the QA mod's real10MiB write quota after accumulating test reports. They are failed runs. Only newly generated task QA files were reversibly archived, with SHA256 manifests; original profile files and user scenarios/diagnostics were not deleted. Fresh **muted-regression-terrain** and **muted-release-rerun** passed all6 and4 respective native groups. One subsequent release invocation had a wrong relative probe path and failed before launch; a fresh absolute-path invocation is the passing run.

## Newly observed visible game behavior

A private QA main-menu entry seeded standard Spearmen/Goblins and a Druid's Apprentice, then opened the actual product setup/editor controls. It did not replace the UI. The ordinary DLL and product mod-tree hash above were used. The captured window was962×752 at the current desktop scaling; the launcher requested1200×900. Full-resolution/multiple-DPI acceptance is not claimed.

Observed directly:

1. All eleven preset labels, catalogue actions and Back were readable on one picker screen. The grouped setup menu and navigation remained available. Farm selected/opened with explicit native deployment; team counters were A3/B2.
2. Farm's native crop/ground/scenery and a genuine read-only Spearman Inspect card were visible. A visible battle and a visible Rematch each completed: Team A, final round3, A3 survived/B0. The native combat log displayed **Field Sage casts Poison Vine** and **Farm Guard attacks with Spear**. The report retained those individual names.
3. The post-battle view displayed A3/B0 and three surviving sprites. Back to Sandbox restored A3/B2; Reset retained the setup and displayed the restoration notice.
4. Oasis selected/opened with the same controls and A3/B2; native sand, water, palms and structures were visible behind the genuine Inspect card. No separate visible Oasis battle was launched. Village/Hoburg Village/Tent Village were tested through real native probes, not manually inspected in this visible session.
5. Back closed the field, Main menu returned, and Quit was selected. The isolated process exited. No normal game/profile was used.

From the user's muting instruction onward, every launch used native `--nosound --musicvol=0`: both regression reruns and the visible session. The public BAT now accepts `-Muted`, and AGENTS.md records this requirement for future agent launches. Normal game settings and system volume are not changed. The actual public BAT was then run with `-Muted -NoWait`: a clean build produced the **same tested DLL hash**, the running game freshly confirmed the isolated terrain-lab profile and all eleven supported IDs, and the exact newly launched process was stopped. This was a launcher/API-presence check, without another battle. Prior tests before that instruction are retained as prior evidence, not described as muted.

## Contexts still unavailable

| Context | Concrete current blocker/evidence |
|---|---|
| Fairy Circle, Lion Tribe Village, Spider Tribe Village | Native templates selected, but exact native reconstruction failed with blocked targets. Placement/parking/scatter/layout cause is not isolated; all three policies remain disabled. Exact-position recovery must not silently redeploy. |
| Fortifications, sieges, walls/gates | Fortified Hoburg actually selects **palisaden**. After correcting the research expectation, a native defender-owned **Wooden Gate** was classified as an actor and rejected as `orphaned_native_unit`. The usual wall/gate booleans did not identify it. Need creation-source/structure provenance and verified native occupancy/targeting/destruction/cleanup; do not bypass integrity by name/ID. No completed siege battle is accepted. Other fort templates are inventory only. |
| Water, coast, port, bridge/ford contexts | Native sea state derives from water or a flood flag; deployment has real ship/aboard branches and space guards. Current field lacks a tested ship/cargo/aquatic contract and reversible shoreline/neighborhood context. A template/ground switch is insufficient. No sea/coast battle was tested. |
| Underground, tunnels, other planes | Native planes3/4 and neighboring tunnel terrain alter setup. Current API borrows one center plus plane-0 rectangle; neighbors are hashed, not context-swapped. Need a reversible neighborhood/plane transaction and native verification before exposing cave/underground choices. No such battle was tested. |
| Upgraded villages/cities, campaign enchantments/climate/seasons, other stock variants | Effective fort parts and native selectors depend on more than the installed file. Individual required context/restore/combat behavior is unverified;59 headers do not establish59 supported presets. |

Mac/Linux, multiplayer, arbitrary active-mod combinations, all map seeds/camera/DPI combinations and extreme widths/armies remain untested. Actor persistence is still a bounded HP/XP/kills/injury-bit/items/spells/name subset; poison/bleeding/effects/opaque state are incomplete. Post-battle snapshots remain after aftermath/before upkeep, with existing partial-scene limits. These maps do not change those contracts.

## Preservation checks

SHA256 checks confirmed the regular game executable, normal profile configuration and regular CoE5SE DLL unchanged. All395 tracked/original submitted-checkout files and385 earlier experiment files, both heads and their prior dirty/clean statuses remained unchanged. All19 original Sandbox data files in the native lab and89 in the launcher lab are byte-identical after archiving fresh outputs and restoring only generated compatibility/context files. Ten core editor modules, including runtime, integrity, names, equipment and size policy, are byte-identical to the initial checkpoint. No files or scenarios were deleted.

## Next user test with the existing BAT

1. Start `SandboxOfElysium-Testen.bat` from the complete existing development folder; use `-Muted` for silent testing. It synchronizes current local Sandbox source and builds/reuses the separate experiment. Confirm its fresh isolated-profile response.
2. **Sandbox → Battlefield**: choose Farm/Village/Hoburg Village/Oasis/Tent Village, then **Open with native deployment** for a new scene. Saved exact positions may be blocked by regenerated objects and must not be silently moved.
3. Place on both teams, try a large unit beside/over scenery, delete/reuse its cells, rename/copy a caster and verify equipment/spells. Save/Load, clear to empty and add Team B again.
4. With both teams populated, Start battle, then inspect the result and try Back to Sandbox, Reset and Rematch. Export Diagnostics immediately on any refusal/recovery problem and keep the original scenario.

All full diagnostics, source/profile backups, failed runs, native evidence, raw logs, owned fixture assets and build binaries remain under the ignored private task directory. The source repositories contain only source/tests/documentation and the existing mod assets.
