# Non-naval release candidate test report

SandboxOfElysium 0.2.0-rc.1, 2026-11-19. The candidate archive is for review. A compatible official CoE5SE build is still required for public release.

## Tested pairing

| Component | Identification |
| --- | --- |
| Game | CoE5 5.43, Windows x64. Executable SHA-256 `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`. |
| Sandbox | 0.2.0-rc.1. Runtime tree fingerprint `f07e5194e0c7524d343da6eb3cb92935055819dce5eb858b3bdb3e8c4cb4e528`. |
| Local CoE5SE reference | Non-naval build of the separate editor.22-era experimental source on base `fd59863d28762cb7e4250802a5f69ce2ac58fb86`. Plugin SHA-256 `6b792752317aa1ca55565fff943b57024fa1528319c7c6e920bbb5050b500661`. The source preserves the generic actor readback used by deployment and excludes the experimental fleet and hull APIs. |
| Official comparison build | CoE5SE 3.6.0 on dev `b9cd9453912d92474c41eb51240683039292dd0a`. Plugin SHA-256 `cdf265dd9a9aebf3c2a98e4bf1b105bc90850df8675f8dd5fa16ca5aa6eead99`. |

All game runs used a separate profile and game executable copy with `--nosound --musicvol=0`. Probe data and the original save and recovery files were kept outside the archive. Probes used the game's own battle outcome calculation and could speed up waiting. They supplement the visible session.

## Checks performed

- **Offline.** 397 behavior assertions across 29 Lua suites, plus the distributed Lua and probe syntax suite. These cover persistence, capability and fleet-save refusals, placement, identity and deployment checks, browser View, names, equipment, spells, and input routing.
- **Setup, native placement, and presets.** The game opened, inspected and cleaned up all 21 stock contexts at width 50. The probe also verified refusal of changed terrain definitions, battle refusal on altered native context, and rollback after an occupied exact target. Placement probes covered both Guard Tower teams, Forest obstacles, Plain copy/move/clear and zoom, formation and large-unit footprints, and admission on all three water maps. Control and projection geometry also received offline checks. A separate 1,536-wide low-level test moved an actor to column 1,000 and checked decoding its saved anchor.
- **Guard Tower recovery.** A copy of the 61-actor recovery restored all positions and supported configuration, with the native structure kept separate. Save/Load, Back to Sandbox, Reset and Rematch succeeded over three natural battles. A deliberately conflicting exact restore was refused and the earlier setup remained verified. The final snapshots enumerated actors and cells and marked the complete rendered scene unavailable.
- **Representative battles.** Native Farm and Castle battles exercised placement refusals, movement, saving/loading, restoration and cleanup. Castle included native gate damage and breach. Sea, Deep Sea and Coastal Hamlet each completed two native independent-unit fights with reconstruction and cleanup. Sea and Deep Sea used the native sea context, and Coastal Hamlet used the `coastville` land and water layout. Native drowning damage was observed in the at-sea checks.
- **Items, condition and magic.** The integration probe covered regular and cursed item handling, both starting-item policies, formation and copied saves, and refusal to omit a permanent implant while keeping the existing field. It verified supported native naming, health, injuries, identity, items and ordered magic through battle, Reset and Rematch. Six neutral terrains restored through size changes or returned a verified refusal followed by an explicitly selected native redeployment.
- **Active mod unit.** The independently installed CrabCult's Shorebound Initiate was identified through the loaded definition, placed on Team A, saved/reloaded, used in a native battle and Reset to its exact cell. A decode check without CrabCult in the available-mod list refused the file and kept the open setup.
- **Visible 1,200 × 900 session.** The Sandbox menu opened on the reference pairing. A copied fleet save showed as unavailable and loading it displayed a clear message with the Plain setup intact. The unit browser's **View** opened the native Abbot card with Prayers. Closing it kept the roster counts. A Plain battle showed the native report, the final field and its combat messages, and Back to Sandbox restored the previous setup. In a separate official 3.6.0 session, opening the same Sandbox menu showed the compatibility notice before opening an editor field.

## Battlefield availability

- **Land** — Plain, Forest, Mountains, Swamp, Jungle, Desert, Farm, Village, Hoburg Village, Oasis and Tent Village.
- **Siege** — Fortified Hoburg, Guard Tower, Watch Tower, Castle, Citadel, Town and City. Team A attacks and Team B defends. The native gates and walls are battlefield structures.
- **Water and coast** — Sea, Deep Sea and Coastal Hamlet with independent actors. Native conditions determine suitability for each unit and position.

The startup check requires the retirement and exact-restoration contracts. The official build can open a basic Plain field through the low-level API. It lacks the complete set of contracts needed by the editor. The first upstream review branches cover minimum width and actor retirement. Those branches were tested separately and do not provide the full reference pairing.

The native unit card previews a temporary instance. Starting items are omitted and randomized preview spells can differ from those on a subsequently placed unit. Fleet setups and transport-dependent placement are unavailable. The Save/Load guarantee covers supported serialized state and a verified native reconstruction. It can refuse when a required mod, permanent loadout, saved cell or context is unavailable. Preserve the recovery copy if that happens. Mac, Linux, other game executables and multiplayer were outside this acceptance run. A complete visual pass through all 21 maps, alternate resolutions, and arbitrary mod combinations remains unverified.

## Manual review

1. In the compatible isolated build, open **Sandbox** and select Plain. Use **View** on a unit, place one army member on each side and try a blocked move. Save a test setup under a new name.
2. Start a battle and open the final field. Check Back to Sandbox and Rematch. For the 61-unit Guard Tower case use a new copy of the recovery and verify positions after returning from the fight.
3. Try independent actors on Sea, Deep Sea and Coastal Hamlet. Confirm that an existing fleet save explains the unsupported feature and leaves the current setup in place.
