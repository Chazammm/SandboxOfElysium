# Local Windows test launcher — 2026-11-13

This English consolidation retains the historical scope and key findings. [The complete original report at the preserved source commit](https://github.com/Chazammm/SandboxOfElysium/blob/b67e8a344b942df1d65d7ce23939891bd74c9f59/docs/TEST-LAUNCHER-2026-11-13.md) remains in Git history; no history was rewritten. Its tests are not automatically tests of the current build.

## Isolation and behavior

SandboxOfElysium-Testen.bat invokes tools/test-development.ps1 from the project folder, validates required paths/files and keeps errors visible. It uses only the prepared private runtime/profile, verifies the owned CoE5 5.43 executable hash, checks source/build fingerprints, synchronizes current local Sandbox files and builds/reuses the separate experimental Extender with the existing toolchain. A known older fallback does not provide the full editor.

The game must write a fresh nonce response in the selected private profile and the correct mod load must appear in its own log. Missing confirmation stops only the exact newly started test process. A DLL's presence alone does not prove terrain works. Reparse paths, unexpected identities, stale extra mod files and already-running test copies are refused or reported without deleting files. Normal saves/configuration/installed Extender remain outside this workflow.

## Historical tests

The BAT was actually launched, required paths/syntax checked, the isolated game and Sandbox entry observed, and Plain/Forest selection/native battles tested separately. A controlled missing-required-file case displayed a readable error and stayed open. -CheckOnly verified paths without a build/sync/game launch. Normal installation/profile hashes were checked unchanged.

## Limits and use

This is a launcher for the already prepared development computer, not a general installer. Its private game copy, profile, identity, toolchain and owned installation are absent from Git. Older launcher evidence is version-specific. Current instructions are in [INSTALLATION.md](../INSTALLATION.md); current console text is English. No Extender/game/third-party binaries are bundled.


## Recorded identifiers

Reference identifiers retained from the original report, including baseline, failed, intermediate and accepted runs. This list alone does not identify a successful run; use the bound evidence above or the original report.

- `d96f2b784e97e115022a2598da2c821dd9520135`
- `6b858c285c78a66985314b622df8b34f73b510d2de318804e0433f3dfff98bf7`
- `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`
