# Interface and field lifecycle — editor.3

This English consolidation retains the historical scope and key findings. [The complete original report at the preserved source commit](https://github.com/Chazammm/SandboxOfElysium/blob/b67e8a344b942df1d65d7ce23939891bd74c9f59/docs/TEST-INTERFACE-2026-11-14.md) remains in Git history; no history was rewritten. Its tests are not automatically tests of the current build.

## Evidence and cause

Preserved `diagnostics-b3534339bc164caaa2af-{1,2,3}.ini` and recovery describe seven starting actors: A Spearman #13 and Riders #201–204; B Goblin #953 and God #207. At round 8 the winner is 0 while God remains alive with HP 212 (native 11 in that user process). The old field query omits him. Close restores borrowed world context, but does not prove actor cleanup; the next Open refuses `unique_exists` for God 207/native 11. The old build reproduced the surviving off-square actor. Fresh native IDs must not be equated with the user's IDs.

## Implementation

The separate lifecycle tracker records constructor provenance, ownership and generations rather than only scanning current square membership. Cleanup includes owned actors that survived outside the temporary square. Optional independent unique copies are scoped to the owning field/session and default Off. Normal campaign rules remain intact. Sandbox blocks further mutation after unverified cleanup and preserves scenario/recovery.

Live UTF-8 unit search uses committed SDL text events, supports codepoint Backspace and explicit focus ownership, and does not use nested popups. Native sprites fit measured bounds. Results offer explicit return, Rematch and Main menu paths, with non-overwriting report archives.

## Verification and limits

Native/UI evidence covers the original lifecycle reproduction, repeated cleanup/reopen, independent unique actors, search, fitted sprites, reporting and return paths. Original diagnostics and normal installation/profile controls were preserved. A later visible workflow completed its remaining checks; earlier interrupted runs are not relabelled as passes. The detailed source-era evidence is linked below.

This does not establish full native instance serialization, all camera modes, arbitrary temporary conversions/transformations, sustained drag or Mac support. A field handle remaining open is not proof that native rendering cells remain available after combat.


## Recorded identifiers

Reference identifiers retained from the original report, including baseline, failed, intermediate and accepted runs. This list alone does not identify a successful run; use the bound evidence above or the original report.

- `fb595fd545df4d0104178550739e62bbbef9a1dfb9341c7b7fe0761922e44fe7`
- `465ed011d900b1b29edba830744d2788b29befdfcd1643400eb39b3979cc861b`
