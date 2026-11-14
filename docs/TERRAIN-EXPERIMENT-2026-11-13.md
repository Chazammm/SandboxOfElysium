# Experimental native test-field terrain — 2026-11-13

Status: implemented, Windows x64 compiled, offline tested and exercised in the real game. Plain and Forest are enabled only with the experimental capability API. This is local work for review; no PR, message, push, release or regular-game installation was performed.

## Source and isolation

The complete official `dev` source was fetched from `https://github.com/musical-pianist/coe5se.git`, not inferred from a comparison page. Pinned base: **d96f2b784e97e115022a2598da2c821dd9520135**, metadata **3.4.0**, API **11**. The private 3.3.0 source was initially fetched by its old local origin; that was caught before implementation and the new worktree was reset to the fetched official commit.

API changes are in the sibling checkout `SandboxOfElysium-ExtenderLab-current`, branch `sandbox-test-field-terrain-3.4`. The older `SandboxOfElysium-ExtenderLab` branch and its pre-existing dirty source/experiment note were preserved. A new English PR draft was added there without replacing that note.

Owned game: CoE5 **5.43**, Windows x64, Steam build **26458448**. Executable SHA256: `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`. Compiler: existing llvm-mingw **20260922**, UCRT x64. Tests used ignored `private/terrain-lab/runtime` and `private/terrain-lab/profile`; `COE5_SAVE` selects that profile and `COE5_DATA` reads the owned game data. Regular saves and the installed 3.2.2 extender were not replaced. Private binaries, key/config copies and native research exports are excluded from publication.

Final experimental plugin SHA256: `6b858c285c78a66985314b622df8b34f73b510d2de318804e0433f3dfff98bf7`. Loader SHA256: `0fc968830aca2fab9b8e1758eb61d91fb8f1fe6abde2f45390eea1708b92f6d9`. See each evidence directory's `hashes.json` for intermediate builds; the final build has **no fault-injection flag**.

## API contract

```lua
-- Feature-detect first: older extenders silently ignore unknown table keys.
local ids = coe5.testFieldTerrains and coe5.testFieldTerrains() or {}
-- Resolve names from the loaded terrain table; do not assume other mods preserve it.
local ok, units = coe5.openTestField {
    commander = coe5.findMonster('Spearman'),
    enemies = {{coe5.findMonster('Goblin'), 1}},
    terrain = forest_id
}
-- ... native placement / draw / fight ...
if ok then coe5.closeTestField() end
```

The same optional field applies to the table form of `coe5.testBattle`. The new read-only `testFieldTerrains()` returns a list of allowed numeric IDs without opening a field. In this loaded vanilla table **Plain = 0**, **Forest = 2**, last terrain index **355**. The native policy additionally checks nonempty records and exact expected names. Other named terrain is refused, rather than treating every ID as supported.

Omitted/nil terrain and the old positional form retain the legacy zeroed-square setup and return shape. Explicit Plain deliberately uses the newly initialized neutral context, so it need not have the identical object count of the legacy default. All calls also receive the independently discovered square-army restoration fix.

| Refusal | Meaning |
|---|---|
| `bad_terrain` | Wrong Lua type, noninteger/nonfinite number, negative, above loaded last index/table capacity/signed-short range, or empty terrain record |
| `unsupported_terrain` | Used record outside the verified Plain/Forest policy, or changed required name |
| `terrain_unavailable` | Explicit terrain on the unvalidated Mac path; capability list is empty there |
| `terrain_init_failed` | Temporary native plane/ground initialization did not satisfy its guard; borrowed context restored before units are created |

Refusals return false/nil according to existing API behavior and record the reason in `lua_refused`; no new Lua exception/result convention was introduced. Invalid input is checked before temporary game-state mutation. A numeric string is rejected explicitly because Lua's integer conversion would otherwise accept it.

## Native initialization and restoration

Static inspection of the owned executable and existing source helpers established that writing the terrain ID alone is insufficient. `squareDefaultGround` reads existing ground and neighbors; it is not an initializer. Zero temperature classifies the square as northern/snow. Native battle setup already creates terrain objects through its normal scatter/tree path.

For explicit terrain only, the implementation saves the full square record, separate square-army entry, world dimensions, full plane-0 record and last-plane index. It lends square (1,1) a small Elysium plane rectangle, checks native `planeAt`, uses native fixed-temperature initialization (**25**), then the native ground-rectangle helper for exactly one square. Existing native battle setup/deployment generates the battlefield. No decorative trees are manually added, and the wider world-temperature pass is avoided because it writes a surrounding halo.

Close restores those borrowed values plus the existing team, active-player, battle-delay, show-flag and optional spell-weapon guards. The army entry is now saved **before** native commander creation: the unchanged 3.4.0 baseline saved it too late and left `squareArmy` changed after close. Allocation failure restores that army entry and the new plane/map context. The post-initialization failure path restores square/plane/map context before any unit allocation.

Diagnostics compare the restored full square/plane records and guarded scalar fields, and hash all eight neighboring square records before/after. Native test logs reported `borrowed_restored=1 neighbours_unchanged=1` in the successful runs. Public API snapshots independently compare the exposed subset. These checks cover specified borrowed state, **not every engine global**: RNG state, unit/commander allocation counters, battle buffers and pre-existing test-field lifecycle semantics are not claimed to be transactional or campaign-equivalent. Native fatal errors/process crashes cannot be repaired by a local rollback branch.

## What actually ran

Evidence levels: **Visible game** = operated/inspected the game window; **Native API** = Lua executed inside the real CoE5 process; **Offline** = actual parser/model code outside the game, without simulating combat.

| Case | Result | Evidence |
|---|---|---|
| Unchanged 3.4.0 baseline | Omitted/positional open and grass fight worked, but close changed separate squareArmy (0→3 / 0→6) | Native API; visible grass battle; baseline: `docs/evidence/terrain-3.4/baseline/compatibility.ini` (lokaler Beleg; nicht veröffentlicht) |
| Initial ground-only Forest attempt | **Failed visual acceptance:** snowy ground 10, temperature 0, no plane, no vegetation objects. A completed fight did not prove correct terrain | Visible game + failed Forest: `docs/evidence/terrain-3.4/v1-failed-forest/results.ini` (lokaler Beleg; nicht veröffentlicht) |
| Corrected Forest | Green terrain with native trees/bushes/rocks; 142 object cells, 43 commander-blocked cells vs 597 standable cells on width 32 | Visible game + Forest result: `docs/evidence/terrain-3.4/v2-native-forest/results.ini` (lokaler Beleg; nicht veröffentlicht) |
| Forest placement/fight | Valid placement (4,0), actual blocking-object refusal; Spearman vs 2 Goblins completed, A won round 11, Spearman 6 HP; 29 observed movement transitions | Visible game + native API, same Forest evidence |
| Explicit Plain, final build | Green terrain, 4 object cells, 3 commander-blocked vs 637 standable; valid placement (3,0), object refusal; A won round 14, Spearman 1 HP, 32 observed movement transitions; close restored | Visible game + final results: `docs/evidence/terrain-3.4/final/results.ini` (lokaler Beleg; nicht veröffentlicht) |
| Legacy compatibility, final | Both forms opened and closed with matching public state; omitted-terrain fight A won round 4 | Native API, final results |
| Bad arguments, final | 14 cases refused, public state unchanged, valid field reopened after every refusal | Native API, final results |
| Alternating terrain | Ten Plain/Forest cycles opened/closed, ground 0/temp 25/plane 0, matching public snapshots; object counts 4/142 repeated | Native API, final results |
| `testBattle` table Forest | Actual fight completed (A won, round 4); borrowed public state matched on return | Native API, final results |
| Initialization failure | One-time **injected** failure after actual native initialization refused and restored; next valid field opened | Native API test build only; rollback: `docs/evidence/terrain-3.4/fault/rollback.ini` (lokaler Beleg; nicht veröffentlicht) |
| Sandbox Forest integration | Actual production catalog/model/runtime/report modules; native Forest build, INI save/load, exact Reset and a second real Rematch completed | Native API; battle: `docs/evidence/terrain-3.4/final/forest-integration-battle.ini` (lokaler Beleg; nicht veröffentlicht), rematch: `docs/evidence/terrain-3.4/final/forest-integration-rematch.ini` (lokaler Beleg; nicht veröffentlicht) |
| Explicit native-deployment integration | Follow-up after the UI exposed blocked old positions: new production runtime action adopted native cells, then saved/loaded, reset exact cells and completed two real fights | Native API; follow-up result: `docs/evidence/terrain-3.4/final/native-deployment-results.ini` (lokaler Beleg; nicht veröffentlicht), battle: `docs/evidence/terrain-3.4/final/native-deployment-battle.ini` (lokaler Beleg; nicht veröffentlicht), rematch: `docs/evidence/terrain-3.4/final/native-deployment-rematch.ini` (lokaler Beleg; nicht veröffentlicht) |
| C parser | **21 passed**, using the very parser header included by the extender and its bundled Lua; type/bounds/stack checks | Offline, `fuzz/test_field_terrain_arg_test.c` in extender checkout |
| Sandbox model/guards | **20 passed**, including Forest persistence, changed terrain and incompatible/absent capability refusal before closing a field | Offline, `tests/model_spec.lua`; all shipped Lua and both native probes parse |

The 14 native rejection cases were negative, above-last, huge, fractional, numeric string, false, true, table, function, thread, infinity, NaN, maximum integer and used-but-unsupported terrain 1. No verified unused native record was exercised; the empty-record guard is code-reviewed, not a demonstrated native empty-record test. Parser tests do not establish that every in-range number is supported.

Object counts include passable decoration. Standability includes occupied cells and depends on the tested commander. Movement counts show native AI movement occurred; they do not measure or establish campaign-equivalent movement costs. The cycles' second fixed anchor can be occupied by the other Goblin, so its refusal is not a terrain-initialization failure. Repeated object counts do not prove a guaranteed stable layout for every roster/mod/build.

## Sandbox behavior

The setup menu selects Plain/Forest. Forest requires the new capability function and a matching loaded terrain definition; stock or malformed capability implementations produce a readable refusal before closing an existing field. Plain falls back to legacy calls when the extension is absent. Scenario schema 1 already had a terrain field; it now accepts only the verified pair and checks loaded names. Reports include terrain ID/name.

Changing terrain can block previously saved cells. **Prepare battlefield (keep positions)** retains exact deployment. **Prepare with native deployment (reposition units)** explicitly adopts the game's initial valid cells into a candidate scenario; it becomes the current scenario only after successful configuration. Save/load, Reset and Rematch continue to require the stored exact cells. Randomized-caster restoration restrictions remain.

The planning grid marks native object cells brown. Some decoration is passable, so object presence alone does not reject placement; native movement/footprint validation remains authoritative. No native camera transform or complete ghost collision oracle is claimed.

Visible UI scope: the real setup menu changed Plain→Forest and its exact-position preparation correctly refused a blocked old layout. The explicit native-deployment action was added in response and its production runtime path passed the native integration above. The final button-to-editor click-through was not manually completed because the test window was minimized during desktop use. This distinction does not turn the native integration into a claimed manual UI test. Missing/incompatible capability notices are covered by code review/offline guards, not a separate complete stock-extender UI run.

**Later follow-up, same date:** the [BAT starter test](TEST-LAUNCHER-2026-11-13.md) completed the formerly open visible click-through: Forest selected, native-deployment button operated, native vegetation inspected, actual fight started through the UI and report observed (A wins round 3). Switching back to Plain and opening its native view also passed. The historical scope description above refers to the earlier terrain session.

## Limits and next investigation

No normal campaign battle comparison was performed. The supported claim is **neutral Elysium test-field Plain/Forest**, with observed terrain, scatter, placement and real AI fights. Seasons, climate gradients, neighbors, enchantments, faction effects and same-name mod overrides have not been proved equivalent to a campaign. Water, forts, sieges, special planes and other terrain IDs are refused; Mac was not built or run.

For each next terrain: identify the loaded record, trace its native environmental prerequisites, guard every additional borrowed record, compare visible setup and native placement/fights against a controlled campaign reference, then test failure/cleanup and advertise only that proven subset. Water and sieges need their own environmental contracts rather than merely extending this allowlist.

## Reproduction and local review

1. Fetch the pinned official source into a separate checkout; apply the local extender changes, including the new parser header. Build using `tools/build-upstream.ps1 -SourceDirectory <checkout> -Toolchain <existing-toolchain>`.
2. Use `tools/prepare-terrain-lab.py --extender <checkout> --label <build-name>` after preparing the owned-game private lab. Add `--sandbox` to enable the actual Sandbox UI in this private profile.
3. Launch with `tools/launch-terrain-lab.ps1`. Run the Terrain experiment menu. For startup API checks write `TerrainProbe/terrain-auto.ini` in the private data folder with `[run]`, `quick=1`, `standardFight=1`, `tableFight=1`, `integration=1`.
4. Fault-only build: `-ExtraCFlags '-DCOE5SE_TEST_FIELD_FAIL_INIT_ONCE=1'`; use `[run] fault=1`. Keep it out of the final build. This is an explicit test seam, not evidence of a natural native failure.
5. The English local PR draft is `../SandboxOfElysium-ExtenderLab/PR_DRAFT_TEST_FIELD_TERRAIN.md`; current API notes also live in `../SandboxOfElysium-ExtenderLab-current/SANDBOX_TERRAIN_EXPERIMENT.md`. Existing old experiment notes remain historical evidence.

Only own code, generated INI results and hashes belong in a future proposal. Native decompilation exports, game/mod assets, keys, full logs and test binaries stay private. No proposal has been sent.

Veröffentlichungshinweis: [Bereinigte Testzusammenfassung und drei frisch geprüfte Bildschirmaufnahmen](public-evidence/README.md). Frühere Bilddateien waren ihren Dateinamen nicht zuverlässig zuordenbar und dienen nicht als Bildnachweis. Livebeobachtungen und numerische native Exporte werden getrennt davon bewertet. Rohdiagnosen bleiben lokal.
