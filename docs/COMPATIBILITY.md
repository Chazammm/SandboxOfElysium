# Compatibility and known limitations

## Tested configuration

- **Game:** Conquest of Elysium 5 **5.43 x64 on Windows**.
- **Dependency:** official **CoE5SE 3.8.2**, installed separately. Use the release ZIP and its Windows instructions. [Download](https://github.com/musical-pianist/coe5se/releases/tag/CoE5SE-v3.8.2)
- **Play:** Standalone single-player battles from the main menu. Other game versions, macOS, Linux, Proton and multiplayer are outside the verified beta configuration.

## Neutral scenery and battlefields

Neutral placement offers 142 stock wall, parapet and stair variants on supported land and siege maps. Cycle the Neutral filter to find Walls, Parapets or Stairs. Search by name or an exact ID such as `#1397`. Ordinary troops, plants, mod-defined scenery, multi-cell structures and authored gates are outside this placement catalog. Map-generated gates retain their native siege ownership and can be inspected when their identity is verified.

Sea, Deep Sea and Coastal Hamlet support independent actors and native drowning rules. Neutral authoring, ships and passengers are unavailable on these maps. Existing naval setups and older saves with unsupported Neutral actors are preserved when the editor refuses to reconstruct them.

## Units and saved state

Enabled mods can add searchable units, items and spell schools. A saved setup can require the same enabled mods and loaded content. Missing or changed definitions may prevent exact reconstruction. Reopening Sandbox refreshes the catalog after a native mod change. While the game remains open, an in-memory setup is kept for its original enabled mod list. Code or plugin mods that CoE5SE asks you to restart for still follow its restart prompt.

**View** opens a temporary native unit card. It omits starting items, and randomized preview spells may differ from the placed unit's spells. Equipment slots, school limits and spell rules still apply. Editing changes existing base schools.

Save/Load, Reset and Rematch recreate the pre-battle setup, including exact positions, supported injuries, equipment, spells and native names where available. Stock implant recovery covers **Spirit Eye, Eye of the Night, Eye of the Old One and Crystal Heart** when the saved item slots and actor state are present and their stock definitions can be verified. Direct implant installation from the equipment UI is unavailable. Modified or unknown implants, and older saves missing necessary state, may still be refused safely.

Post-battle views capture supported actors and cells. Reports have partial damage and spell attribution. Scene effects, poison/bleeding counters and other opaque native state fall outside exact reconstruction.

[Installation and recovery instructions](../INSTALLATION.md)
