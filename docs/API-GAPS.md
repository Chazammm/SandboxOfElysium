# SandboxOfElysium: API findings for musical_pianist

Prepared 2026-11-13. This is a handoff report only; nobody was contacted.

**Baseline:** CoE5 5.43 Windows x64, Steam build 26458448. CoE5SE **dev 57abc69a2ddb272a5b9049b4a561367066d9d99e**, locally built without changing tracked upstream files, metadata 3.3.0 / API 11. The user's previously installed 3.2.2 was not used for these tests and was not replaced.

The API reviewed is the [pinned Lua reference](https://github.com/musical-pianist/coe5se/blob/57abc69a2ddb272a5b9049b4a561367066d9d99e/coe5.lua), checked against the [test-field implementation](https://github.com/musical-pianist/coe5se/blob/57abc69a2ddb272a5b9049b4a561367066d9d99e/src/lua_test_battle.h), relevant Lua bindings and actual game runs. Generated evidence and explicit test scope are in [TEST-RESULTS.md](TEST-RESULTS.md). “Not found” below means no supported accessor was found in this examined public API; it is not a claim that the engine cannot do it.

## 1. Native test-field terrain and fort configuration

- **Sandbox need:** select vanilla battle environments with their actual water, siege, wall and terrain behavior.
- **Observed:** `openTestField` / `testBattle` accept a commander, optional spell/stand-in weapon and mixed friend/enemy groups. Their implementation constructs square (1,1), sets terrain 0, clears the square record and performs native setup/deployment. Grass battles actually worked.
- **Reviewed alternatives:** terrainName, terrain/batmap, terrainLastIndex; `addBattleMap`, `setBattleScatter`; `squareTerrain` writes; `alterTerrain`; BATTLE_SETUP / BATTLE_DEPLOY observers. Named terrain/batmap data can be enumerated. Custom map registration is load-time work. Ordinary squareTerrain writes are restricted to world building. A world-mutating terrain helper does not provide a documented way to rebuild/reconfigure an already open test field. Observe-only setup/deploy sites cannot be used as replacement calls.
- **Conclusion:** the test-field interface has a demonstrated configuration omission. Alternative sequences involving world helpers have not been validated; an engine limitation is not established. The sandbox exposes only the supported grass field and a read-only terrain inventory.
- **Helpful API:** optional test-field terrain/fort/variant parameters, native regeneration behavior, documented at-sea/siege semantics and a list of supported built-in variants. State whether square terrain is sufficient or whether additional world/fort data is required.

## 2. Width, height and automatic growth

- **Observed:** `battleWidth` is read-only; Y coordinates are 0–19. Actual fields measured 32 columns for a small roster, 34 for 100 vs 100, and 84 for an auto-deployed 500 vs 500 roster. The 1000-unit case tested creation and sizing, not a completed fight. Native growth therefore exists and is usable without a manual width setting.
- **Missing:** no documented width override, resize/redeploy operation or Small/Medium/Large/Extra Large mapping. A newly added roster is realized by rebuilding the whole field in this mod, allowing native size recalculation.
- **Conclusion:** manual size selection is unavailable through the examined interface; the underlying engine supports different widths. The full sizing formula and maximum were not reverse engineered.
- **Helpful API:** explicit minimum width or size preset, actual dimensions returned on open, resize policy, and behavior for occupied cells outside the new bounds. Height configurability should be stated separately.

## 3. Battlefield projection, hit testing, footprints and sprites

- **Observed:** BATTLE_DRAW and BATTLE_WAIT permit overlays/input; `moveTestFieldUnit` checks native footprints and blockers; unitBattleX/Y read native anchors. `monsterSprite` and `ui.monsterRow` show an Idle picture. `mapView` describes world-map projection, not the battle camera.
- **Missing/unclear:** no supported battle camera/cell-to-screen transform, native unit hit test, native footprint dimensions/occupancy query, arbitrary drawMonster/drawSprite operation, or separate attack-picture accessor was found.
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

No extender changes, memory writes, native hooks or new engine rules are used. There are no fake selectable terrains/sizes, inferred mod origins, estimated damage/cast totals, fabricated slots, or dummy combatant units. The planning grid and partial telemetry are explicitly described as such. The remaining gaps need an API clarification/extension or a separate validated investigation before the full requested sandbox can be delivered.
