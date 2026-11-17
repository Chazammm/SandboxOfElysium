# Installation and testing — editor.15

Log controls require the separate owned-field native log-presentation API. The local launcher builds that source without bundling it with this mod. Setup hides the log; combat and the post-battle field have a labelled Hide/Show control. Missing support shows N/A. [Exact tests](docs/TEST-LOG-LAYOUT-2026-11-17.md).

Editor.15 also requires the accepted siege policies and specialized native tower-context contract from the separate Extender source. The launcher builds/reuses that source locally. [Current presets, tests and blockers](docs/TEST-SIEGE-EXPANSION-2026-11-17.md).

## Choose the correct build

The repository contains **0.1.0+editor.15**, an experimental Windows development version for **Conquest of Elysium 5.43 x64**. It includes the mod, documentation and local development tools. It is not a complete first-time player package.

The full editor needs additional APIs from a **separately built experimental CoE5SE**. The local release-next experiment is based on the separately submitted 3.4.4 source contribution, with additional environment/minimum-size/bounded-state work. That additional work is not part of PR #2. Unmodified official CoE5SE, including examined dev 3.5.0, does not implement the full editor contract. The Ranged fix alone is also insufficient. A GitHub source ZIP does not install these dependencies.

No CoE5SE files or modified DLL are bundled here. Its [separate license](https://github.com/musical-pianist/coe5se/blob/d96f2b784e97e115022a2598da2c821dd9520135/LICENSE.txt) prohibits including them with a mod. The game, keys and third-party mods are not distributed either. Older prototype test reports do not certify this editor with stock upstream.

The [submitted source-only API PR #2](https://github.com/musical-pianist/coe5se/pull/2) remains separate and unchanged. Local editor.15 additionally needs the release-next and individual-naming API experiments in `SandboxOfElysium-ExtenderLab-next`; the local BAT now defaults explicitly to this separate worktree. Use `-ExtenderSource` for an explicit alternate source. See [current feature/tests/limitations](docs/TEST-RELEASE-NEXT-2026-11-16.md). This is not a public dependency installer.

Current viewport and fortification requirements: [editor.13 report](docs/TEST-ZOOM-FORTIFICATION-2026-11-17.md). The separate experiment additionally provides `battleViewport=1` and `structureProvenance=1`; an older Extender cannot enable the fortified preset.

Earlier controls, retirement/zoom/item API requirements and exact tests: [editor.12 report](docs/TEST-EDITOR-CONTROLS-2026-11-17.md). The existing BAT builds the matching separate experiment locally.

## On the existing development computer

1. Close a running isolated Sandbox test game.
2. Double-click **SandboxOfElysium-Testen.bat** in **Sandbox of Elysium**.
3. Let the launcher check paths, synchronize local mod files and build/reuse the separate Extender. Errors leave its window open. A fresh response from the running game must confirm the private profile; otherwise it aborts.
4. Choose **Sandbox → Battlefield → Open with native deployment (reposition units)**.
5. Choose Team A or B, search a unit, click Select, then right-click free ground. Click Select again to deselect. Both teams may be empty while editing; Clear battlefield removes all actors.
6. Put at least one actor on each team and choose Start battle. Afterward try Back to Sandbox (restore setup), Reset setup and Rematch.

Prerequisites: Windows PowerShell, Python 3, prepared `private/lab/identity.json` and `private/terrain-lab`, the owned verified game, separate `../SandboxOfElysium-ExtenderLab-next` source and the existing llvm-mingw toolchain. These private components are absent from Git. **The BAT is not an installer for another computer.** `SandboxOfElysium-Testen.bat -CheckOnly` checks the existing paths without launching. Use `SandboxOfElysium-Testen.bat -Muted` for process-local `--nosound --musicvol=0`; agents always use muted launches without changing normal game/system audio. Optional `-CrabCult` uses already installed private files; CrabCult is not included.

The launcher uses only its private runtime/profile. Scenario and diagnostic files are under **private/terrain-lab/profile/coe5se_data/SandboxOfElysium**. Back up your own files before manual changes. The normal installation/profile is not updated and existing data is not deleted.

## On another computer

1. Install your own compatible Windows CoE5. Obtain official CoE5SE and its instructions from its [official repository](https://github.com/musical-pianist/coe5se). Stock CoE5SE alone does not enable this full development editor.
2. Download/clone this repository. The mod folder is **mod/SandboxOfElysium**; the entire repository is not a game mod folder.
3. Full editor.14 currently requires a separately obtained and appropriately built compatible experimental Extender plus an independently prepared isolated game/profile. This download sets up neither. Do not replace a regular installation with the experimental build.
4. Once that separate test environment is ready, copy the complete **SandboxOfElysium** mod folder into its own **mods** directory and enable CoE5SE and SandboxOfElysium in its test profile. The `.c5m` belongs directly inside the SandboxOfElysium folder. Preserve existing scenario files separately.

Mac, Linux, multiplayer and arbitrary mod combinations have not been accepted for this editor. A source review branch is not a public binary release.

## Equipment, magic and limits

- Without a selected item, right-click a placed actor → Edit. Items shows actual anatomical positions. Remove → Remove cursed item confirms cursed removal; Cancel keeps it. Remove before replacing a cursed item.
- Permanent injuries are not healed by removing an existing implant. Schema 3 with the release-next API restores bounded HP/XP/kills/injury bits; other afflictions/effects remain unsupported. Old schemas lack these fields and migrate only to a new unused filename. New eye/heart implants remain unsupported.
- Removing a bonus or lowering a school refuses unchanged if memorization would become invalid. Explicitly deselect those spells in Magic Schools & Spells, then retry. Random spells are not silently changed.
- Existing base schools can be adjusted within 1–3. Unlock learns eligible spells without memorizing. Native item/unit Inspect is read-only.
- Modded Items / Modded schools use observed loaded provenance. Unknown remains Unknown. Install and enable third-party mods separately.
- Save/Load support empty and one-sided setups. Start battle requires at least one actor per team and otherwise keeps the editor/setup unchanged.

Read [cursed-item tests](docs/TEST-CURSED-2026-11-15.md), [window/mod-filter tests](docs/TEST-PANEL-2026-11-15.md) and [launcher tests](docs/TEST-LAUNCHER-2026-11-13.md) for exact coverage.

## Troubleshooting and uninstalling

Use Export Diagnostics on the battlefield or in a recovery message. The dialog names its file. Preserve the original scenario; an unverified rollback must not be ignored. The export is bounded and distinguishes missing data from complete coverage. Logs depend on loader stage: `coe5mod.log` or `coe5se_logs/coe5mod.log` in the relevant test environment.

Disable the mod and remove its mod folder to uninstall. Keep scenario data under `coe5se_data/SandboxOfElysium` if needed. The development BAT does not install or remove the normal Extender.

For individual names: right-click an actor → Edit → Name. Maximum32 Unicode code points and 47 UTF-8 bytes; excess input shows an error and is refused. Naming needs the separate local naming experiment; PR #2 and stock3.4.4 alone do not provide it. [Native naming tests and exact limitations](docs/TEST-NATIVE-NAMES-2026-11-16.md).

## Verified battlefields in editor.14

Choose **Sandbox → Battlefield → Farm, Village, Hoburg Village, Oasis or Tent Village**, then **Open with native deployment (reposition units)** for a new layout. The six previous terrain choices and all current controls remain available. Saved exact positions still require native verification; scenery may block a cell after rebuilding. **Fortified Hoburg** is now the first verified siege: choose it via the Battlefield selection, then use native deployment for a new layout. Team A attacks; Team B defends. Clear removes the roster while retaining native map structures. Use **Fit** to see the full field and arrows/middle-drag to pan. Other forts/siege variants, sea/coasts and underground contexts remain unavailable. [Tests, exact checkpoint pairing and blockers](docs/TEST-VANILLA-PRESETS-2026-11-16.md).
