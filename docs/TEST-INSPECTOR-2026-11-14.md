# Footprint preview, native Inspect and caster validation — editor.4

This English consolidation retains the historical scope and key findings. [The complete original report at the preserved source commit](https://github.com/Chazammm/SandboxOfElysium/blob/b67e8a344b942df1d65d7ce23939891bd74c9f59/docs/TEST-INSPECTOR-2026-11-14.md) remains in Git history; no history was rewritten. Its tests are not automatically tests of the current build.

## Reproduced invalid spell setup

The actual saved six-actor scenario contains three God Emperor #141 on A and three God Emperor of the Underworld #144 on B. Distinct model IDs and native IDs must remain distinct across processes. The old edit primitive allowed six Solar spells even though native capacity was four. The recorded ten-spell selection therefore cannot be exactly reconstructed as a valid native state. The old error and failed recovery were reproduced with frozen sources and the owned Windows CoE5 5.43 executable.

## Changes

Footprint-aware previews and formation/drag spacing use actual native width/height. Clear/blocked/outside are partial geometry and occupancy information; the engine remains authoritative. Existing-unit context has priority, including interior cells of large footprints.

Inspect opens the genuine native instance card read-only. It preserves exact configuration and verifies state on return. Native editable finalization is avoided because it can rerandomize spells. A template card is never substituted for an invalid instance.

Strict spell editing checks known status, school/effective level and native capacity before mutation, then verifies readback/rollback. Repair saved spell selection (copy) lets the user explicitly choose a valid subset, retains known spells and saves a separately named verified copy. Cancel keeps the original. There is no automatic truncation or random replacement.

## Acceptance

Historical final editor.4: **78 offline cases and 13 distinct native groups PASS**. Three complete visible six-unit battles, Back/Reset/Rematch and file Save/Load succeeded with the explicitly repaired copy. Visible genuine unit/item cards, both teams and independent unique copies, 1×1/2×2/3×3/2×1 previews and Forest rejection were exercised. Frozen-baseline and failed candidate evidence remains separate.

Held physical drag and all camera zooms were not fully visually accepted. The original invalid scenario/recovery remains unchanged; a valid repaired copy is not proof that the invalid source became natively valid. Full native scene retention and full instance serialization are not claimed.


## Recorded identifiers

Reference identifiers retained from the original report, including baseline, failed, intermediate and accepted runs. This list alone does not identify a successful run; use the bound evidence above or the original report.

- `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`
- `465ed011d900b1b29edba830744d2788b29befdfcd1643400eb39b3979cc861b`
- `85d08c0e65434d599b4093232a941277`
- `e08b5a56b0e2e5eac7bcbe6d09fe2b798cd585950955fcdff1c92e1fc29ff9af`
