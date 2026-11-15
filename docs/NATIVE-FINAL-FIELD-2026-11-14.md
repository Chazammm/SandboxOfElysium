# Native final-field capture boundary — 2026-11-14

This English consolidation retains the historical scope and key findings. [The complete original report at the preserved source commit](https://github.com/Chazammm/SandboxOfElysium/blob/b67e8a344b942df1d65d7ce23939891bd74c9f59/docs/NATIVE-FINAL-FIELD-2026-11-14.md) remains in Git history; no history was rewritten. Its tests are not automatically tests of the current build.

## Observed native boundary

User exports `diagnostics-5bd42749aa2c47d4ba1b-{1,2,3}.ini` show living native actors after real combat but empty raw cells/missing anchors. Earlier BATTLE_TURN_EFFECTS positions were partial observations, not a complete final capture. The owned Windows CoE5 5.43 executable explains the sequence: determine winner, execute another 75 aftermath ticks, call afterFightUpkeep, handle sunk ships and clear the battle grid. Keeping a field handle open does not preserve its final raster.

The separate Extender captures tracked actors and all cells **after aftermath, immediately before upkeep**. Later upstream-based contributions preserve the existing BATTLE_AFTER_FIGHT_UPKEEP wrapper chain rather than replacing it. Native cleanup still runs.

## Contract

Capture records native ID/generation, actor/terrain kind, life/type/owner, full footprint, raw anchors, derived occupied cells and current-record status. Capture completeness, issue lists and scene completeness are separate. A bounded export is not the whole capture. Missing/off-field positions are not reconstructed from the editor model.

Sandbox draws safely located living captured actors and terrain, including tracked summons without adding them retroactively to original army counts. Owner/type changes are explicit. Inspect opens the current native record after cleanup; a temporary actor may no longer be inspectable. Snapshot integrity does not mean the entire native render scene survived.

## Limits

Effects, projectiles, animations and full rendering state are absent: `sceneComplete=false`. Captured cells and actor data are a timed snapshot, not a paused native battle. Natural conversion/transformation coverage is incomplete. Windows 5.43 evidence is not Mac support. Full record reclamation and every opaque native property are not established.


## Recorded identifiers

Reference identifiers retained from the original report, including baseline, failed, intermediate and accepted runs. This list alone does not identify a successful run; use the bound evidence above or the original report.

- `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`
- `63b293fb0a694cf6a528cbf66d9aa2e561c80b38337f1fb7e40b154ba64a8bdd`
- `54f26dddea5a440db8ffd327e9351cee`
