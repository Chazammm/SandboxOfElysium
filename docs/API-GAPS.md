# SandboxOfElysium: API findings for musical_pianist

## 2026-11-17 local editor.12 experiment

Current upstream dev9d74ae4 (3.5.0) was checked. Separate source adds permanent owned retirement/current-life diagnostics, `setTestFieldMultipleUnique`, `testFieldZoom`/`setTestFieldZoom`, WAIT-only `testFieldPointerWheel`, and the explicit per-actor `clearHeldItems` configuration mode. These are outside the submitted PR. [Contracts, reproduction, tests and platform limits](TEST-EDITOR-CONTROLS-2026-11-17.md). No DLL is bundled.


**2026-11-16 editor.11:** [Five additional verified native stock contexts and exact blockers](TEST-VANILLA-PRESETS-2026-11-16.md). Separate `testFieldEnvironmentState`/metadata extensions observe actual context without claiming complete environment serialization. Siege structures need creation provenance; sea/coast needs ship/neighbor contracts; underground needs reversible plane/neighborhood context. These gaps remain closed to selection. Current upstream dev `be8a2bf7b4fa094d828e2ad56eb0376e51adf3e1` now includes PR #2; it still lacks these newer local APIs.

**Release-next local development (2026-11-16):** environment/minimum-width and bounded HP/XP/kills/injury-bit APIs are separate from submitted PR #2. Six neutral fields now include Jungle; water/siege/plane contexts, exact scenery and complete native unit/effect serialization remain gaps. [Current scope and API proposal](TEST-RELEASE-NEXT-2026-11-16.md). Earlier entries below retain their historical boundaries.

Current handoff: [CoE5SE PR #2](https://github.com/musical-pianist/coe5se/pull/2) is open against `dev`, with all seven commits signed off after explicit acceptance. See [tests and remaining gaps (2026-11-16)](TEST-SINGLE-PR-2026-11-16.md) and the [submitted description](COE5SE-PR-DRAFT-2026-11-16.md). No modified Extender is bundled. GitHub Actions reports `action_required`; no CI build pass is claimed.

**Previous contribution split, 2026-11-15/16:** the complete editor.8 API inventory has now been compared with freshly fetched official dev `df09497f04a39ff8fb7b0979dedde7dfed120c64` (3.4.4/API14). Five separate source review contributions and a combined test branch cover the current Sandbox contract. See [the preceding report](TEST-API-CONTRIBUTIONS-2026-11-15.md) and its linked capability matrix, exact source/build/native evidence and English PR drafts. Those historical preparation branches remain separate from the mod and unmerged upstream; they were unsigned review material. The signed submission status is recorded above. The older pinned findings below retain their historical scope.

**2026-11-15 editor.8, local only:** explicit `removeCursed={position,item}` with `cursedRemoval=1` permits one identity-bound removal, including an already held eye/heart implant, without changing other configuration, shared item flags or live permanent-injury bits. Ordinary cursed replacement and new implants remain protected. Bonus removal cannot silently invalidate memorization. Fresh-actor reconstruction handles unwanted random cursed starting items, then applies exact supported saved spells/items; complete afflictions/HP are still not serialized. The actual Crystal Heart diagnostic and CrabCult bonus test pass in separate native sessions, with visible Cancel/confirm evidence. See [current evidence and material limits](TEST-CURSED-2026-11-15.md) and the separate Extender's `SANDBOX_CURSED_REMOVAL_EXPERIMENT.md`. The minimal upstream 3.4.4 Ranged contribution is a different checkout and includes none of these experimental APIs.

**2026-11-15 editor.7, local only:** the separate Extender adds fitted native item icons, the metadata-only native item card and observed loaded item/spell/school provenance. Modded filters use actual parser/path/spell writes plus current-record binding; unobserved changes remain unknown. Asset-only changes, a full writer history and unit provenance remain gaps. Downward school changes recompute native aggregate levels; invalid memorization refuses unchanged, higher known spells survive, and an explicit reconstruction-only contract restores supported formerly higher known IDs. Native ordinary test actors have no verified individual name field: labels are explicitly Sandbox-only. Genuine unit Inspect remains read-only because its editable finalizer may randomize spells. See [current evidence and limits](TEST-PANEL-2026-11-15.md) and separate `SANDBOX_PANEL_EXPERIMENT.md`. Historical gaps below describe their pinned builds.

**2026-11-15 editor.6, local only:** anatomical equipment assignment now uses upstream 3.4.0's twenty-position item backend plus a separate owned-field transaction. `testFieldLoadoutState` and `setTestFieldConfiguration` atomically configure item IDs/positions, existing base-school levels and exact ordered known/memorized spell IDs, with readback and verified rollback. Per-actor generation-bound school state feeds native base/effective-level and combat attack readers without changing templates or substituting item bonuses. Increases stop at 3; new schools and new permanent eye/heart implants are unsupported. Active CrabCult equipment and a private expanded-slot/mod-school/duplicate-spell fixture are tested separately. See [current evidence and limits](TEST-LOADOUT-2026-11-15.md) and `SANDBOX_LOADOUT_EXPERIMENT.md` in the separate Extender checkout. These APIs are not upstream; full opaque instance snapshots, transformation preservation and content provenance remain gaps. Historical stock-API limitations below are not the current local feature list.

Prepared 2026-11-13. This is a handoff report only; nobody was contacted.

**2026-11-14 editor.5:** the separate local experiment now captures a timed unit/cell snapshot after 75 aftermath ticks and immediately before `afterFightUpkeep`. Native grid cleanup still runs. `testFieldFinalState()` distinguishes complete unit/cell coverage from `sceneComplete=false`; current-record read-only Inspect is separate from frozen snapshot data. A new explicit `emptyEditor` mode creates ordinary actors without a commander or dummy and rejects battle start before mutation if either team is empty. The existing legacy commander guard remains. The `monsterHasRanged` template-only native leaf is now allowed in main-menu context via the existing narrow dispatcher signature marker; unavailable results on older builds remain unknown. Native semantics include spell attacks and the rank exclusion. [Current evidence and limitations](TEST-BATTLEFIELD-2026-11-14.md); the historical end-state findings in section 9 below describe the old API.

**2026-11-14 safety follow-up:** native NEW_UNIT may reinitialize an existing unique actor. Incremental add therefore needs an entire-request unique preflight before native mutation. The local patch adds that guard, reason returns, test-field actor/grid/footprint queries and stable SDL pointer buttons. Sandbox verifies bijection and rollback, quarantines unverified state and explicitly reopens a preserved scenario. This is not a general engine snapshot or campaign cloning API. See [the placement/deletion report](TEST-PLACEMENT-2026-11-14.md) and the separate extender's updated LuaLS reference/PR draft. No submission occurred.

**Earlier local editor experiment (editor.2):** guarded `setTestFieldSpells`, `removeTestFieldUnit`, read-only `battleView` / screen-cell conversions and `ui.drawMonsterIcon`; incremental add avoids rebuilding existing actors. See [TEST-EDITOR-2026-11-13.md](TEST-EDITOR-2026-11-13.md). Base-level and equipment limitations from that stage are superseded by editor.6 above. Full instance snapshots remain unsupported. No PR or binary release occurred.

**Later local experiment:** the original 3.3.0 baseline below is retained for traceability. The separately patched 3.4.0 dev base `d96f2b784e97e115022a2598da2c821dd9520135` now supports a verified neutral Plain/Forest subset and read-only feature detection. See [the terrain experiment](TERRAIN-EXPERIMENT-2026-11-13.md) for code, actual game tests and limits. It is not an upstream release or campaign-equivalence claim.

**Baseline:** CoE5 5.43 Windows x64, Steam build 26458448. CoE5SE **dev 57abc69a2ddb272a5b9049b4a561367066d9d99e**, locally built without changing tracked upstream files, metadata 3.3.0 / API 11. The user's previously installed 3.2.2 was not used for these tests and was not replaced.

The API reviewed is the [pinned Lua reference](https://github.com/musical-pianist/coe5se/blob/57abc69a2ddb272a5b9049b4a561367066d9d99e/coe5.lua), checked against the [test-field implementation](https://github.com/musical-pianist/coe5se/blob/57abc69a2ddb272a5b9049b4a561367066d9d99e/src/lua_test_battle.h), relevant Lua bindings and actual game runs. Generated evidence and explicit test scope are in [TEST-RESULTS.md](TEST-RESULTS.md). “Not found” below means no supported accessor was found in this examined public API; it is not a claim that the engine cannot do it.

## 1. Native test-field terrain and fort configuration

- **Sandbox need:** select vanilla battle environments with their actual water, siege, wall and terrain behavior.
- **Observed:** `openTestField` / `testBattle` accept a commander, optional spell/stand-in weapon and mixed friend/enemy groups. Their implementation constructs square (1,1), sets terrain 0, clears the square record and performs native setup/deployment. Grass battles actually worked.
- **Reviewed alternatives:** terrainName, terrain/batmap, terrainLastIndex; `addBattleMap`, `setBattleScatter`; `squareTerrain` writes; `alterTerrain`; BATTLE_SETUP / BATTLE_DEPLOY observers. Named terrain/batmap data can be enumerated. Custom map registration is load-time work. Ordinary squareTerrain writes are restricted to world building. A world-mutating terrain helper does not provide a documented way to rebuild/reconfigure an already open test field. Observe-only setup/deploy sites cannot be used as replacement calls.
- **Baseline conclusion:** the unpatched test-field interface has a demonstrated configuration omission. The later local extension supplies optional `terrain` and `testFieldTerrains()`, with native neutral context for Plain/Forest only. Sandbox now selects these when that capability exists, and falls back to the legacy grass field otherwise. Water/fort/siege environments remain unverified.
- **Helpful API:** optional test-field terrain/fort/variant parameters, native regeneration behavior, documented at-sea/siege semantics and a list of supported built-in variants. State whether square terrain is sufficient or whether additional world/fort data is required.

## 2. Width, height and automatic growth

- **Observed:** `battleWidth` is read-only; Y coordinates are 0–19. Actual fields measured 32 columns for a small roster, 34 for 100 vs 100, and 84 for an auto-deployed 500 vs 500 roster. The 1000-unit case tested creation and sizing, not a completed fight. Native growth therefore exists and is usable without a manual width setting.
- **Missing:** no documented width override, resize/redeploy operation or Small/Medium/Large/Extra Large mapping. A newly added roster is realized by rebuilding the whole field in this mod, allowing native size recalculation.
- **Conclusion:** manual size selection is unavailable through the examined interface; the underlying engine supports different widths. The full sizing formula and maximum were not reverse engineered.
- **Helpful API:** explicit minimum width or size preset, actual dimensions returned on open, resize policy, and behavior for occupied cells outside the new bounds. Height configurability should be stated separately.

## 3. Battlefield projection, hit testing, footprints and sprites

- **Observed:** BATTLE_DRAW and BATTLE_WAIT permit overlays/input; `moveTestFieldUnit` checks native footprints and blockers; unitBattleX/Y read native anchors. `monsterSprite` and `ui.monsterRow` show an Idle picture. `mapView` describes world-map projection, not the battle camera.
- **Existing queries, clarified:** `battleObjectAt`, `battleUnitAt`, `battleCanStand` and `battlePathfind` already exist in the examined public API. The later terrain work uses native object/standability queries. They are not additions made by this patch. A previous blanket claim that occupancy queries were missing was too broad.
- **Missing/unclear:** no supported battle camera/cell-to-screen transform, screen-space unit hit test, explicit complete footprint dimensions, arbitrary drawMonster/drawSprite operation, or separate attack-picture accessor was found.
- **Consequence:** this prototype has a clearly labelled cell editor plus a separate native view. It cannot promise pixel-perfect mouse placement on a panned/zoomed native battlefield or complete ghost validity. Its ghost checks bounds/anchors; native placement is authoritative and may still reject a green cell for a large footprint or obstacle.
- **Tests:** exact anchor movement, occupied/off-field refusal and formation coordinates passed in the game. Idle browser was visually inspected. Attack artwork and full native-view interaction have not been implemented.
- **Helpful API:** `battleView`, screen/cell conversions, footprint/hit-test helpers and read-only monster artwork descriptors. These names are suggestions, not existing API.

## 4. Loaded content and provenance

- **Observed:** monsterName/monsterLastIndex, monster flags, itemName/itemSlotType and spellInfo expose loaded records. Active mod names/folders are readable. A CrabCult faction unit is tested separately in the native suite. The catalog includes all nonempty named monster records, including non-recruitables; it does not infer provenance from ID ranges.
- **Missing:** originating-mod identity per monster/item/spell, whether a vanilla definition was overridden, stable content identity and content hashes. Item/spell name collisions cannot reliably identify an object by string alone.
- **Conclusion:** loaded mod content is accessible; a trustworthy “Modded Units” filter is not presently implemented. This is a metadata gap, not proof that mod units cannot be used.
- **Helpful API:** a content descriptor with ID, name, defining mod, overrides, stable key and content/version fingerprint. Include unused/placeholder record status so a named but invalid record need not be guessed at.

## 5. Equipment: assignment exists; anatomical-slot preflight unclear

- **Reviewed:** unitItem (eight positions), itemSlotType, item data/abilities, giveItem, takeItem and unitRemoveItem.
- **Observed:** native giveItem accepted “A Chest Full of Fire” on a Spearman; inventory changed from zero to one item. A separate regression gives the item, moves the unit, copies it, and rebuilds after deletion. These are actual native calls, not production UI item assignment.
- **Missing/unclear:** no documented accessor for the unit's actual allowed equipment positions, an atomic `canEquip` with a reason, or explicit placement/replacement semantics. A successful string-based event helper alone does not establish safe compatibility for every creature/item pair.
- **Conclusion:** **not** “items cannot be given.” General item giving works. The production Item tab deliberately remains read-only because its requested guarantee—only actual compatible slots, no displaced ordinary gear—has not been established. Appropriate/inappropriate slot UI cases remain blocked/unverified.
- **Helpful API:** enumerate anatomical slots with type/current item; atomic equip/unequip; preflight results such as no matching slot, occupied, restricted creature and unique-item constraints. Document whether giveItem already guarantees these conditions and how callers can inspect rejection.

## 6. Magic levels, exact known-spell sets and restoration

- **Reviewed:** unitKnownSpell/unitMemorizedSpell, unitAbility, unitSpellWeaponLevel, unitPathBonus, memorizeAllowance, memorizeSpell/unmemorizeSpell, learnStartSpells and learnRandomSpell. The testBattle single-spell parameter is limited to its commander and changes that test commander's spell setup.
- **Works:** existing native spell lists can be read and memorization changes requested with readback. Old Wizard removal/re-memorization passed (8 known, 4 memorized). Duplicate names required storing spell ID + name; the initial name-only implementation failed and was corrected. A saved Old Wizard was then regenerated with a different starting known-spell set: exact restoration was explicitly refused in the actual game.
- **Missing:** no supported exact base-school-level setter, deterministic teach/remove-known-spell operation, or full spell-set replacement was found. Random learning is unsuitable for a deterministic scenario loader. Item/path bonuses are not a substitute for changing the underlying school level.
- **Consequence:** the editor offers existing known spells only. Scenario/Copy/Reset/Rematch rebuilds compare regenerated starting known spells against the saved list and refuse a mismatch. They do not silently substitute a new mage or manufacture unknown spells.
- **Helpful API:** inspect and edit native base paths/levels with native validation, deterministic known-spell edits, legal memorization/recalculation semantics and explicit support for mod paths/spells. Preserve ordinary non-magic abilities.

## 7. Harmless test-field deletion and native snapshots

- **Observed:** closeTestField removes the field's units. addTestFieldUnits and moveTestFieldUnit exist. killUnit/damage helpers perform genuine game effects and are unsuitable as silent editor deletion. There is no documented removeTestFieldUnit or deep unit clone/snapshot operation in the reviewed reference.
- **Implementation:** editor additions/deletions use a candidate roster and native re-creation, then exact placement and configuration readback. A failed candidate attempts restoration of the previous roster. Native random initialization can also prevent that restoration; this is surfaced as an error. This is not an atomic engine transaction.
- **Tests:** simple-unit copy/delete, native placement, configured inventory preservation, small-fight reset/rematch and scenario reopening are covered. General randomized mage restoration is not guaranteed.
- **Helpful API:** editor-safe remove/clone and an opaque versioned unit/scenario snapshot; guarantee restoration of HP, items, base magic, known/memorized spells, instance abilities, team and deployment. A field transaction would avoid destroy/recreate rollback failure.
- **Proposed interface sketch — not implemented:**

```lua
-- Proposal only. None of these methods are claimed to exist.
local snapshot = coe5.captureTestField()
local ok, reason = coe5.restoreTestField(snapshot)
local clone, reason = coe5.cloneTestFieldUnit(unit, team, x, y)
```

## 8. Combat telemetry: partial attribution must remain partial

- **Observed:** battleWinner, battleRound, ticksMs, unitHp, unitOwner, unitKills and surviving unit coordinates are available. DOATTACK and DAMAGE_UNIT can be observed. The sandbox exports native kill-counter deltas and synchronous HP loss inside an observed attack, separately from unassigned loss.
- **Missing/unclear:** delayed projectile/area damage source identity, periodic damage/healing attribution, nested reflected/chained effects, summons, transformation lineage and a complete successful-spell-cast event. BATTLE_SPELL_PICK may examine candidates repeatedly; treating every selection as a cast would overcount. DOATTACK's explicit spell parameter covers an item's spell, not every ordinary caster spell.
- **Conclusion:** complete per-unit damage and all-spells-cast totals are not established. The prototype labels direct observed HP loss as partial, not total damage. It exports explicit item-spell attack observations without claiming a full cast log. These are event-coverage/causality uncertainties, not proof the engine lacks the information.
- **Helpful API:** stable battle/unit/attack IDs; damage event with source/target, applied HP delta, mitigation and causal attack; successful cast event with caster/spell/targets; death/removal/retreat/transform/summon events. Specify replay and post-battle behavior.

## 9. End state and result lifetime

- **Observed:** fightTestField returns while the test-field handle remains open, but this does **not** retain the unit grid. In a manually observed Spearman/Goblin fight, the living Spearman still had 6 HP and one native kill, yet both unitBattleX/Y values were nil. Drawing the still-open test field showed empty terrain. Dead units also had nil cells. The requested native final deployment therefore cannot be claimed. A separate read-only BATTLE_TURN_EFFECTS observer **did capture** one survivor's aftermath cell (13,9) before cleanup in a subsequent real fight. The dead opponent had none. This is useful partial data, stored separately, but is not a complete final-state snapshot or a retained native scene.
- **Scope:** reports count original roster units by their original team; transformed ownership is shown separately. Summons are excluded from start-roster loss totals. Elapsed ticks are wall time, including pauses, not a claimed simulation-time duration. Last round is native battleRound, not an invented number of seconds.
- **Missing/unclear:** complete final-state snapshot including summoned units, removed/retreated records, battle effects and all unit identity transitions, plus a way to retain/redraw the final native unit grid. Whether an earlier lifecycle event captures all exact final positions remains a separate investigation; engine impossibility is not established.
- **Helpful API:** a stable battle result object and final roster/state snapshot, reasoned unit outcomes, final cells and native statistics-screen access independent of campaign reports.

## 10. Input scrolling and portable scenario identity

- **Observed:** held mouse buttons and pointer positions support repeated placement. Existing-unit context selection has priority. `uiWheel` is documented for preview worlds; no generally available BATTLE_WAIT wheel delta was found. The prototype has five-entry paging rather than claiming a functioning scrollbar.
- **Scenario behavior:** versioned INI schema, available IDs/names, item/spell names and all saved active mod names are checked. Native field construction validates actual positions. Missing or ambiguous content is refused. All saved active mods are conservatively required even when their content was not used.
- **Missing:** wheel deltas/general scroll-panel support in battle overlays; reliable per-content fingerprints and deterministic unit rehydration. Same-name/same-ID definition edits cannot all be detected with the current serialized manifest.
- **Helpful API:** uniform pointer/scroll events, scrollable overlay widgets, content manifests and the snapshot support described above.

## What is deliberately not substituted

The separate 2026-11-14 experiment adds provenance/generation-based test-field cleanup,
explicit scoped multiple-unique creation, SDL2 inline text focus, and measured monster-icon
fitting. These require the matching experimental build and are not public upstream guarantees.
See [interface/lifecycle tests](TEST-INTERFACE-2026-11-14.md). Original guards remain when
capabilities are absent; no generic unit-struct clone or campaign unique-rule change is used.

The original 0.1.0 Sandbox uses public Lua APIs. The later separately built extender patch temporarily initializes and restores native test-field context; it is documented independently and is required for Forest. No new combat rules, fake selectable sizes, inferred mod origins, estimated complete damage/cast totals, fabricated slots or dummy combatants are substituted. The planning grid and partial telemetry retain their stated limits. Remaining gaps require separate validation before the full requested sandbox can be delivered.


## Individual names — separate editor.10 experiment,2026-11-16

Rechecked official dev df09497: commanderName and commanderTheName exist; an ordinary actor has no personal-name string/API. The separate ExtNext experiment adds owned-generation testFieldUnitName/setTestFieldUnitName, a native formatter bridge for ordinary names and actual commander-record updates. It is outside submitted PR #2. See [native evidence, contract, limits and tests](TEST-NATIVE-NAMES-2026-11-16.md). Names are scoped to the owned main-menu field, not campaign saves or unit promotion. A63-byte native combat-message row cannot promise complete arbitrary long entries.
