# SandboxOfElysium

An experimental Lua sandbox for **Conquest of Elysium 5**. Open **Sandbox** from the main menu, prepare two armies, then fight using the game's native battle AI.

**Current development version: `0.1.0+editor.8`.** See [Installation and testing](INSTALLATION.md). The editor requires additional APIs from a **separate experimental CoE5 Script Extender**. Stock upstream CoE5SE, including the examined 3.4.4 build, does not provide the complete editor contract. This repository contains no Extender DLL, game files or third-party mod files. Its source update does not replace the older 0.1.0 prototype package.

All maintained documentation, interface text and future GitHub contributions use English. Historical test results remain version-specific; they are not evidence that a later build passed the same tests.

[Current 3.4.4 source contribution stack and test results](docs/TEST-API-CONTRIBUTIONS-2026-11-15.md): five review contributions plus a combined branch, kept separate from this mod. They are not merged upstream or supplied as a binary release.

## Test on the existing development computer

1. Close any running isolated test game. Double-click **[SandboxOfElysium-Testen.bat](SandboxOfElysium-Testen.bat)** in this project folder.
2. The launcher checks the private game copy/profile, synchronizes the current local mod and builds or reuses the separate experimental Extender. Errors keep the console open. The running game must confirm the isolated profile before launch is accepted.
3. Choose **Sandbox** in the main menu. Under **Battlefield**, choose **Open with native deployment (reposition units)**. This explicitly accepts native deployment; **Open battlefield / edit (keep positions)** instead requires the saved positions.
4. Choose **Team A** or **Team B**, click the search box, type a name, then click **Select** beside a result. Right-click a free battlefield cell to place the unit. Clicking the same **Select** again deselects it, making inspection easier.
5. Place at least one unit on each team and choose **Start battle**. Afterward use **View post-battle field**, **Back to Sandbox (restore setup)**, **Reset setup** or **Rematch**. **Main menu** leaves the Sandbox.

The BAT uses only `private/terrain-lab/runtime` and **`private/terrain-lab/profile`**. Scenarios and diagnostics go to `private/terrain-lab/profile/coe5se_data/SandboxOfElysium`. It does not install into the normal game/profile. A missing fresh runtime profile confirmation stops the exact newly launched test process. A DLL on disk alone is not proof that an API works.

This launcher requires the already prepared private environment, an owned verified Windows CoE5 5.43 x64 installation, Python 3, the separate `../SandboxOfElysium-ExtenderLab-current` source and the existing llvm-mingw toolchain. Private components are deliberately absent from Git. **The BAT is not a first-time installer.** Use `SandboxOfElysium-Testen.bat -CheckOnly` for path checks or `-WindowWidth 1704 -WindowHeight 900` for more visible map area. Builds remain under `private/terrain-lab/builds`. A known older fallback cannot supply the complete editor; missing integrity APIs refuse editing. Stale extra files and running test games are reported rather than deleted. [Launcher verification](docs/TEST-LAUNCHER-2026-11-13.md).

## Battlefield controls

- The setup menu separates **Current setup**, **Battlefield**, **Scenarios**, **Tools** and navigation. Team colors cycle through seven choices; equal colors are allowed without making the teams allies.
- The right panel has **Units / Items**, live search and filters, with five results per page and page buttons. Enter or clicking elsewhere ends text input; Backspace removes a character and **Clear** clears the search.
- Right-click empty ground to place the selected unit. Holding and dragging across new cells repeats the selected formation with footprint-aware spacing. The same held cell is not retried every frame. **Single / Horizontal Row / Vertical Row / Square** choose formation; `+` changes its count or size.
- Right-click an existing actor, including an interior cell of a large footprint, for **Inspect / Edit / Move / Copy / Delete**. Existing-unit context takes priority over placing another unit. **Cancel move** cancels a pending move; Escape is not promised as its shortcut.
- The native battle map is the primary view with the required projection API. **Planning grid** is an explicitly abstract compatibility view. Footprint previews mark blocked and out-of-bounds cells, but remain **partial**: native placement makes the final decision.
- **Clear battlefield** removes every actor. Either team, or both, may be empty during editing and in saved scenarios. There is no hidden commander. A battle requires at least one actor per team and refuses an incomplete setup without changing it. Older Extenders retain their protected commander and cannot fake an empty field.
- **Multiple unique units: Off** is the default. With confirmed scoped native support, enable it to create independent native actors across either team. Turn it off only after duplicate unique types are removed. Ordinary campaigns keep their normal unique rules. The four identically named Rider types have distinct IDs #201–204.

The **Ranged** filter follows the native definition, including spell attacks and rank rules. Missing classification is reported as unknown/partial. Units from active mods appear in the loaded searchable catalog; mod origin is not guessed from numeric IDs. A dedicated Modded Units filter is not part of this editor. [Current filter/menu evidence](docs/TEST-MENU-MODS-2026-11-14.md).

## Items, schools and spells

**Items:** Select the Items tab, search by name and use **Slot / Modded Items** filters. **Inspect** opens the native item card. Select an item and right-click a placed unit; choose an anatomical position when necessary. Occupied positions require explicit replacement. Click the same Select again or **Cancel item selection** to return to normal unit context. Empty ground never places a unit while an item is selected.

**Edit:** With no selected item, right-click a unit and choose Edit. Its draggable, resizable window has **Items / Magic Schools & Spells / Name** tabs and remains clamped to the game area. Changes belong to that actor. Items show actual positions, native compatibility and readback. **Remove → Remove cursed item** explicitly confirms cursed removal; Cancel preserves it. Direct cursed replacement and new permanent eye/heart implants remain protected. An existing Crystal Heart can be removed, but **permanent injuries are not healed**. Full native HP/affliction state is not serialized, so rebuilding a scenario can differ. [Cursed-item evidence and limits](docs/TEST-CURSED-2026-11-15.md).

**Magic Schools & Spells:** Expand an existing school and adjust its base level within 1–3. Template level, item bonus, effective level and native memorization capacity are separate. **Learn** or **Unlock all spells up to base … (known only)** adds eligible known spells without memorizing them. **Mem** explicitly selects known battle spells under native limits. Lowering a level or removing a bonus is refused unchanged if it would invalidate memorization; deselect those spells yourself first. Higher known spells are retained. Random starting spells are never silently rerolled. New base schools and arbitrary higher levels are not offered. Equal spell names remain distinguishable by ID.

**Modded Items / Modded schools** use observed loaded definition writers, including native schools containing observed mod spells. Unknown coverage stays **Unknown origin**, with content retained under All. This is not a full modification history or proof about every image/description-only change. Current tests include CrabCult's **Abyss Fragment** and an explicit private QA school with two same-name spells; the normal BAT does not enable or redistribute these fixtures. [Configuration and mod-filter tests](docs/TEST-PANEL-2026-11-15.md).

**Name** sets an optional individual Sandbox display label, up to 48 Unicode characters without controls. An empty label restores the type display. It does not rename the monster template or the native unit card/battle messages. Native individual naming for commander-free actors is unverified; font coverage depends on CoE5.

Native unit/item Inspect is read-only. It uses the actual instance card, not a replacement summary; long cards may require scrolling to **Exit**. Editing through the native card's finalizer is avoided because it can randomize spells.

## Scenarios, recovery and reports

Save/Load preserve teams, colors, positions, unique mode, and exact ordered known/memorized spells. Schema 2 adds up to twenty item positions with ID/name and existing base schools with ID/name/level; schema 1 remains readable, with ambiguous legacy names refused. Copy/Move/Reset/Rematch verify supported native configuration. Missing active mods, changed identities, unavailable required APIs and invalid data refuse safely. Content changes retaining the same ID and name are not fully detectable.

An unverified rollback locks editing and preserves recovery data; do not continue on an inconsistent field. Use **Export Diagnostics** and the offered recovery path. Each bounded export gets a fresh `diagnostics-<session>-<number>.ini` name and includes up to 64 recent actions, build/source identifiers, model/native IDs, life/team, anchors/footprints, occupied cells and configuration/rollback details. Missing information is explicit. Raw logs, credentials and absolute local paths are excluded. Keep the original scenario when supplying diagnostics.

**Older God Emperor recovery:** A previous edit primitive allowed six Solar spells despite native capacity four. That recorded ten-spell selection cannot be restored exactly as valid. **Repair saved spell selection (copy)** lets the user choose at most four per school, retaining known spells, and verifies/saves a separate `repaired-...ini`. Cancel keeps the source. There is no automatic truncation or random replacement.

Battle reports are retained as `battle-<session>-<number>.ini`; `last-battle.ini` additionally holds the latest. They record winner, rounds, elapsed wall time including pauses, starting counts, casualties, survivors and native kills. Damage attribution is partial and a complete spell log is unavailable. Summons are not added retroactively to starting armies; owner changes are separate from original teams.

The post-battle view uses a native capture after aftermath and before upkeep clears the battlefield. It records tracked actors and cells and draws safely located living actors/terrain with captured type, owner and footprint. **It is not a retained complete native scene:** effects, projectiles and animations are absent; incomplete coverage says PARTIAL. Inspect opens the current native record after cleanup and may be unavailable for removed temporary actors. Missing positions are never guessed. [Final-state contract](docs/NATIVE-FINAL-FIELD-2026-11-14.md).

## Terrain and development status

The separate local experiment originally used CoE5SE dev `d96f2b784e97e115022a2598da2c821dd9520135` (3.4.0/API 11). A source-only contribution stack is being prepared against current dev `df09497f04a39ff8fb7b0979dedde7dfed120c64` (3.4.4); it is not an upstream release. The tested positive list is **Plain, Forest, Mountains, Swamp and Desert**, checked against loaded IDs/names. Water, siege, special planes and full campaign climate/season/enchantment equivalence are unsupported. Native terrain objects may block old saved positions after regeneration. Native deployment is explicit; exact-position operations never silently redeploy. Temporary parking resolves placement cycles only if all final footprints verify. [Terrain evidence](docs/TERRAIN-EXPERIMENT-2026-11-13.md).

Historical prototype 0.1.0 tests used stock dev `57abc69a2ddb272a5b9049b4a561367066d9d99e` (3.3.0); the pre-existing normal installation had 3.2.2. Neither is evidence of full editor.8 compatibility. The normal installation remains unchanged.

Manual map-size presets, full combat telemetry, campaign initialization/blessings, multiplayer, Linux and Mac editor support remain unavailable or unverified. All zoom levels and sustained physical drag have not received complete visible acceptance. See the reports for the distinction between offline checks, actual native tests and visible UI observations.

- [Test results](docs/TEST-RESULTS.md)
- [API gaps and review handoff](docs/API-GAPS.md)
- [Public evidence](docs/public-evidence/README.md)
- [Environment inventory](docs/RECON.md)
- [Changelog](CHANGELOG.md) and [development journal](MODLOG.md)

This project distributes its own mod code, banner, tools and selected test evidence only. Third-party content remains separately installed. Uninstall by disabling SandboxOfElysium and removing its mod folder; keep scenario data separately. Credits and redistribution terms follow [LICENSE](LICENSE) and the separate CoE5SE license.
