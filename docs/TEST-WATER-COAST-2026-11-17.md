# Native water and coastal battlefields, 2026-11-17

Local **0.1.0+editor.16**, after clean Sandbox `84b67d4e3d86595822496b3746d492f7a72fef25`
and separate Extender `77cd67b0506176490eb0fe507f54f4b26a719ec0`.
The earlier [eighteen-map siege report](TEST-SIEGE-EXPANSION-2026-11-17.md)
retains its version boundary. No release, push, new PR, merged-contribution edit
or modified Extender distribution was performed.

## Accepted scope

**Three additions, twenty-one choices total.** All eighteen previous maps,
including the seven sieges, remain available with the matching native APIs.

| Preset | Actual native context | Native water/land behavior | Accepted transport scope |
| --- | --- | --- | --- |
| Coastal Hamlet78 | Stock `coastville`, fort parts43, plane0, temperature25, sea=false, siege=false | Mixed land and water cells, shoreline, native buildings/piers and blocking objects | Independent actors; ships/passengers unavailable |
| Sea27 | Native default generated field, no `.coem` filename; sea=true, ground11, plane0, temperature25, fort parts0 | Native open-water cells and drowning/movement rules | Independent actors; ships/passengers unavailable |
| Deep Sea68 | Native default generated deep-water field; sea=true, ground12, plane0, temperature25, fort parts0 | Distinct native deep-water appearance and actual water rules | Independent actors; ships/passengers unavailable |

There is no invented `sea.coem`. The exact loaded identity, flags, native
selection, returned context and lifecycle are checked. Map-file existence or a
blue texture was not acceptance. Sea/DeepSea have an observed empty template
basename because the native default-map path is used. The legacy metadata name
`verifiedNeutralField` means a verified default map, including these two water
fields; it does not assert land terrain.

## Native findings and implementation

Strict native placement mode0 checks geometry/occupancy, **not survival in water**.
Native0xecfb0 tests water ground11..13 with actual live object-cover rules.
Native0xeb7a0 tests the anchor and far footprint corner plus effective movement
flags0xc1 (flying/swimming/floating). It is not an every-interior-cell scan or a
complete survival guarantee. Native turn effects apply drowning damage and
native advancement avoids dangerous water. This also happens on coast cells
when the overall battle has sea=false. Sandbox does not replace those rules.

The separate proposed API is `testFieldWaterState(unit,x,y)`, advertised by
`testFieldEnvironmentInfo().waterContextVersion=1`. It reads an authenticated,
living owned editor actor and bounded proposed anchor, returns native water and
drowning observations, and rechecks session/generation/body/lifecycle health.
It changes no unit, position, RNG, damage or combat message. The `ship` result
is a conservative unsupported-transport indicator, not an actor provenance class.

Setup and placement/movement messages explain water hazards. A land actor may
be placed where native placement permits it; a warning does not make it immune
to drowning. Existing geometry previews remain explicitly partial. Ships/boats
and transport-dependent actors refuse before creation, using actual movement
bit40 or native abilities1cf/1d2/1d3 rather than names/monster-ID exceptions.
Battle start also checks **effective summed instance abilities**, including
native additions, and the actual water/boat context before simulation.

Native water initialization resets the sea flag and two side boat counts. The
Extender now snapshots, restores and verifies their exact32-bit values, exposes
the current counts in EnvironmentState, and includes adjacent-square equality
in successful close. Unverified cleanup remains failed/pending. Existing
constructor provenance, unique handling, retirement, footprint checks and
rollback quarantine were not weakened.

Sandbox also fixes a pre-existing refusal path: a native `fightTestField` false
result no longer creates a completed report. The editor restores its prior
snapshot/report, verifies the retained setup, hides the preparation log and
shows the refusal. Unsupported capability/transport rebuilds refuse before
closing the current field. Exact restoration failures retain recovery data;
there is no silent native redeployment or replacement of randomized spells.

## Final source and build

Separate Extender checkpoint: **`fd59863d28762cb7e4250802a5f69ce2ac58fb86`**, branch
`experiment/sandbox-release-next-20261116`, in `SandboxOfElysium-ExtenderLab-next`.
Sandbox remains on `development/release-next-editor9-20261116`; its editor.16
commit and the exact pair are recorded in the local checkpoint manifest/handoff.

Ordinary plugin SHA256:
`70268ed3cbcaa5c0257adbc3e76aac8c8507eba5a1e459f79128ad81465a77ad`.
Final mod-tree SHA256:
`99702acfe73ebf428bf098fe3d103133a4af9636c32271f44210ab460273bc54`.
Private `COE5SE_TEST_FIELD_TERRAIN_CANDIDATES=1` discovery builds are separate
and are not the accepted ordinary launcher build.

Owned game: Windows CoE5 **5.43 x64**, executable SHA256
`489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`.
All agent launches used **`--nosound --musicvol=0`** in a fresh isolated copy/profile.
Normal install/profile, original user test profiles, existing scenarios and
diagnostics, legacy experiment and merged review checkout were preserved.

Official dev was rechecked at `9d74ae4fc70d019bb088dc26995594c71f6e2497` (3.5.0).
PR#2 was already squash-merged as `be8a2bf7b4fa094d828e2ad56eb0376e51adf3e1`.
The tested experiment retains its3.4.4-based line; a later contribution must
port only its additional delta. The separate source contract is
`WATER-CONTEXT-EXPERIMENT-2026-11-17.md` in that Extender repository.

## Fresh native API and integrated tests

- Each new preset passes the full matrix at minimum32,50,160: actual context,
  both teams, Move/Copy and native names, rejected overlap/objects and diagnostics,
  full multi-cell deletion/immediate reuse, Save/Load, two naturally completed
  battles, final units/cells, exact Reset/Rematch, Clear/empty setup, add after
  Clear and verified close. Original model identity/configuration is preserved;
  rebuilds legitimately allocate new native generations.
- Coastal matrix uses Spearman, Goblin, Druid's Apprentice, a Deep One on the
  same native wet anchor, and a3x3 Apocalyptic Rider. Native hazard queries and
  actual one-HP deltas are recorded without inventing a general damage-source API.
- Sea/DeepSea matrix uses six Deep One Warriors, a Kappa Shaman and four Tritons,
  plus Copy, a2x2 **Kraken** and an intentionally endangered Spearman. It checks
  names Sea Guard/Tide Sage, a deliberately raised base school, Amulet of Anti
  Magic, exact ordered known/memorized spells, supported HP/XP/kills state,
  native movement, one-HP native turn-effect losses and exact restoration.
- Empty and one-sided setups Save/Load; an empty side refuses battle unchanged.
  Raw ship open/add requests refuse without allocation or actor/grid changes.
  An intentionally changed native sea flag is also refused through the real UI
  without a final report, after which the test restores that flag and fights.
- Environment/size probe passes17 groups: current metadata/unsupported guards,
  the five original neutral templates at automatic/160, and all three new maps
  at automatic/70 with native completed fights. Thus all four named minimums
 32/50/70/160 and automatic sizing have fresh water-context evidence.
- The **standalone Extender probe**, requiring no Sandbox modules, passes bounds,
  read-only state, swimmer/land contrast, raw transport refusal, effective
  temporary sailing-ability refusal before fighting, removal/readback, close,
  and restoration of an original nonzero sea flag through a Plain field.
- Regressions pass Fortified Hoburg, Castle and Watch Tower; Plain/Forest and
  Farm/Village; native naming/legacy labels; retirement/unique/item/bonus/zoom;
  viewport and native log workflows at requested1200x900 and1704x900. The actual
  private fifteen-unit Hoburg Village recovery replay passes six rejected Troll
  attempts and five completed fights with exact restoration and no phantom Troll.

Native WAIT fast-forward only skips native display delays. No winner, HP,
movement, damage or battle-over flag is fabricated to complete these battles.

Offline: **263 cases across17 Lua behavior suites, plus syntax**, pass. C terrain
policy harness passes **272 assertions in each ordinary/candidate mode**.
Launcher path/profile `-CheckOnly` and both repository whitespace checks pass.
Offline/C checks do not simulate the game.

## Visible observations

Requested1200x900, captured962x752/native UI800x600; ordinary final plugin and
mod source above. All21 choices and native-catalogue/Back navigation were visible.
The normal Sandbox menu's coastal warning was readable.

Through the **ordinary Sandbox entry**, Coastal Hamlet showed the real shoreline,
water and native buildings/piers. Fit51% showed the whole automatic-width32 map.
Right-clicking a water cell placed a Spearman and displayed the native drowning
warning. Context/Delete removed it; immediate placement on the same cell worked.
A naturally completed round3 fight reported Team A1 survivor, Team B0. The native
post-battle log explicitly showed one-point drowning messages and the Spearman's
death. Hiding that log worked; Back to Sandbox restored the original2/1 setup,
including the wet actor, at51% zoom.

The corrected private **Sea** fixture showed7/4 swimming armies. Fit32%, map-wheel
zoom to42%, list-scroll priority without changing zoom, context alignment and
native read-only Inspect were observed. Inspect displayed **Tide Sage**,16/16HP,
and Hydromancy level2. The round5 battle naturally ended with all7 original Team A
actors surviving and Team B0. Native movement and spell effects were visible;
the native log retained **Sea Guard** attacks and **Tide Sage** casting Summon Water.
Combat Hide was observed; log restoration was observed in the final field.

That final snapshot contained11 friendly actors:7 original survivors plus4
**Lesser Water** summons. These were separate from the report's original-roster
counts. Selecting a summon offered its correct snapshot context, but native
Inspect explicitly refused `removed_after_capture`: native cleanup had already
removed the live summoned instance. The diagnostic was exported. This is a
documented final-state limitation, not an editable leftover actor.

Back to Sandbox restored7/4 with no summons. Clear produced0/0; Start refused
with the explicit missing-team message; a Team B Deep One could immediately be
placed, and Reset restored7/4. Deep Sea's distinct native ground12 appearance
and7/4 setup were visually compared. No separate visible Deep Sea fight or
second-resolution water battle is claimed; those are native automated results.

The initial private visual journal stopped because it read an uninitialized
runtime while the ordinary mod was being tested. Only the private journal was
fixed/restarted; ordinary coastal observations and the corrected fixture are
recorded separately. A controls run also correctly failed for a missing copied
private recovery fixture; the retake with that preserved fixture passes. Neither
failed harness archive is relabeled as a pass.
The private journal retained setup changes only; combat and final-view claims
above come from visible observations, native reports/logs and the separate API
matrices, not from treating that journal as a complete frame capture.

## Unavailable contexts and remaining limits

- **Ships, boats, passengers, embarkation, capacity, sinking and transport-dependent
  transformations/summons:** no complete passenger/boat-composite geometry,
  ownership, movement, serialization or retirement contract has been accepted.
  Native boat components and linked passengers are not equivalent to one raw
  ship actor; raw Ship/Galleon creation had no ordinary unit-layer anchor.
- **Ports/upgraded ports:** native selector28 chooses port/portupgr using native
  square ability0x48f. Compound fort/gate/coastal and transport context needs its
  own deployment/combat/cleanup/upgrade matrix. It is not supplied by loading the
  file or by these non-siege water policies.
- **Lake10/11, Shallow Sea69, Coastal Ghost Hamlet146, bridges/fords and other
  water variants:** retained inventory/research or limited discovery is not
  their own complete acceptance matrix. They remain unavailable, including
  visually similar aliases. Arbitrary neighbor-dependent coast orientation,
  landing battles, flooded/enchanted terrain and other planes are not recreated.
- No Mac implementation/build/testing or Linux acceptance. Water-only units'
  world travel/land restrictions are distinct from the native battle drowning
  predicate. Full opaque conditions/effects and scenery are not serialized.
  Native final view is the bounded post-aftermath/before-upkeep capture; removed
  temporary summons can render from it while live native Inspect is unavailable.
  Nonzero live boat-count cleanup and forced native write/rollback failure were
  not exercised; unsupported transport remains closed and recovery guards remain.

## Short manual test plan

1. Double-click **SandboxOfElysium-Testen.bat** in the project root. Choose
   **Sandbox → Battlefield**. Use **Open with native deployment** when intentionally
   changing map layout; **keep positions** must refuse incompatible exact cells.
2. Try **Coastal Hamlet**, **Sea**, **Deep Sea**. Start with Deep One/Deep One Warrior
   against Tritons; add a Kappa Shaman and Kraken. Move/Copy/name actors, change an
   item/spell selection, Save/Load, delete/reuse an occupied footprint, then fight.
   Check log Hide/Show, native names, final view, Back, Reset and Rematch. On the
   coast, contrast a Spearman on land/water and read the warning/native log.
3. Clear to0/0, save/load empty and one-sided setups, verify missing-team refusal,
   and add either team again. A Ship/transport request should clearly refuse.
4. Recheck **Fortified Hoburg**, then the recently added **Guard tower, Watch Tower,
   Castle, Citadel, Town, City** as time permits: Team A attacks/B defends; gates,
   walls/buildings remain native map structures outside army counts. Try gate
   overlap, legal native parapets, Clear, Save/Load and Reset/Rematch. Exact
   restoration refusal must keep recovery data instead of silently moving units.

Export diagnostics for a mismatch and keep the original scenario/recovery file.
No modified Extender is included with the mod.
