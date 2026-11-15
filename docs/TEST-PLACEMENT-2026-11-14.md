# Placement, deletion and integrity — editor.2

This English consolidation retains the historical scope and key findings. [The complete original report at the preserved source commit](https://github.com/Chazammm/SandboxOfElysium/blob/b67e8a344b942df1d65d7ce23939891bd74c9f59/docs/TEST-PLACEMENT-2026-11-14.md) remains in Git history; no history was rewritten. Its tests are not automatically tests of the current build.

## What the actual exports establish

The two preserved `diagnostics-f2aa0585830642fa8be8-{1,2}.ini` exports contain overlapping bounded rings: sequences 278–341 and 283–346. Placement failures and unverified “restore failed” already exist at the beginning. The first damaging action and the user's exact gesture are absent.

Model IDs 12, 13 and 14 all reference native ID 19, HP 0, with no reported anchor. Model 15 references native ID 20, also dead. At sequences 337–340, Delete on model 13 returns `dead_unit`, unchanged. This is a refused deletion, not proof of successful removal or the cause of the earlier death. Sequence 345 attempts memorization after corruption. Do not infer the precise first deleted Rider.

## Reproduced root cause

Native NEW_UNIT applies unique-monster reuse: it can reinitialize an existing record rather than allocate another actor. Two old addTestFieldUnits requests for Rider #202 returned the same living ID 9 in the independent reproduction. After five Strange Seraphs, several apparently successful model placements shared that actor. Removing one model retired their shared native actor while other model rows survived. The differing native ID from the user's export reflects allocation order.

Sandbox accepted aliases without an identity/life check, mistook sequential moves for a globally correct deployment, removed an existing shared handle during failed-new-unit cleanup, continued after unverified rollback and fell back to saved model anchors for hit testing. Legitimate large-footprint rejections exposed this state corruption. Native #206 Seraph is 2×2; tested Riders #202/#203 are 3×3. Nine hit cells are derived from one native anchor, not nine independent raw anchors.

## Fix and recovery

The separate Extender preflights unique conflicts before mutation and exposes life/team/type/generation, native anchors, occupied hit cells and lifecycle cleanup. Sandbox requires model/native bijection and exact final deployment, checks every rollback independently, removes phantom hit-test fallback and guards edit/copy/delete/spells/fight. Stable SDL buttons suppress same-cell held retries while allowing intentional drag.

Unverified rollback locks editing, retains the original scenario and recovery data, and requests diagnostics plus explicit safe reopening. It is not reported as success. Random spells are never silently replaced. Later optional multiple-unique mode creates independent native records; its default remains Off.

## Verification

Historical acceptance: nine native groups and 40 offline cases; visible 1×1/2×2/3×3 deletion and immediate reuse, overlap/unique refusal and Forest obstacles. Diagnostics distinguish model/native identity, life/team, anchor/full footprint, raw vs derived occupancy, operation and rollback. Snapshots/exports remain bounded. Neither the ring nor later reproductions reconstruct unknown earlier user actions. Campaigns, arbitrary native transformations, every zoom and sustained drag are not fully covered.


## Recorded identifiers

Reference identifiers retained from the original report, including baseline, failed, intermediate and accepted runs. This list alone does not identify a successful run; use the bound evidence above or the original report.

- `cf38abac73323e267d4955cb830462b604b3b4a22aa96fe0c8adc515aa77d390`
- `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`
- `d96f2b784e97e115022a2598da2c821dd9520135`
- `d793b96c0772240ce5da86ecad96bcd9e19c122b686ca527167cced87f5e0d9a`
- `fb595fd545df4d0104178550739e62bbbef9a1dfb9341c7b7fe0761922e44fe7`
