# Editor, Priestess and diagnostics — editor.1

This English consolidation retains the historical scope and key findings. [The complete original report at the preserved source commit](https://github.com/Chazammm/SandboxOfElysium/blob/b67e8a344b942df1d65d7ce23939891bd74c9f59/docs/TEST-EDITOR-2026-11-13.md) remains in Git history; no history was rewritten. Its tests are not automatically tests of the current build.

## Cause and correction

The old Runtime:add rebuilt the entire army. Native creation rerolled the Anointed Priestess's starting spells; configuration checks correctly rejected the mismatch, and rebuilding the previous army could reroll again. This placement failure was reproduced in an actual isolated CoE5 process. Exporting diagnostics was not its cause, and the reproduction does not establish every earlier user click.

Incremental addition now retains existing native IDs, HP, inventory and spells. A rejected new placement removes only the new actor and verifies/restores existing positions. Copy/Load/Reset/Rematch use the separate exact spell-list contract: validate the bounded 60-known/30-memorized lists before writing, read back, and verify rollback. This early removal API protected the legacy primary commander; later empty-editor support is documented separately.

## Evidence and limits

Actual native and visible tests covered the Priestess reproduction, configured Copy/Move, file Save/Load, Reset/Rematch, two real battles, resizing, blocked-tree cleanup and Plain/Forest. Existing actors were not recreated during ordinary addition. Bounded diagnostics record recent actions and saved/actual spell state without publishing private logs or full paths.

Extreme field growth, sustained physical drag and every camera zoom were not fully accepted. Exact supported spell/item restoration is not a promise to serialize every opaque native instance attribute. These results belong to editor.1 and the separate 3.4.0 experiment, not stock upstream or the later contribution branches.


## Recorded identifiers

Reference identifiers retained from the original report, including baseline, failed, intermediate and accepted runs. This list alone does not identify a successful run; use the bound evidence above or the original report.

- `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`
- `d96f2b784e97e115022a2598da2c821dd9520135`
- `cf38abac73323e267d4955cb830462b604b3b4a22aa96fe0c8adc515aa77d390`
