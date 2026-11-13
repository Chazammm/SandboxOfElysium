# Environment and capability inventory — 2026-11-13

## Pinned versions

| Component | Examined state |
|---|---|
| Game | Owned Steam app 1606340, build 26458448; CoE5 5.43, Windows x64 native |
| Executable SHA256 | `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55` |
| Originally installed CoE5SE | DLL metadata 3.2.2; SHA256 `87e70dead42341573889641447d04c700af359243696a57b32e89a4fac682e8a` |
| Examined upstream | [dev commit 57abc69a2ddb272a5b9049b4a561367066d9d99e](https://github.com/musical-pianist/coe5se/commit/57abc69a2ddb272a5b9049b4a561367066d9d99e), version metadata 3.3.0, plugin API 11 |
| Tested plugin | Locally compiled, unchanged upstream source; SHA256 `6faf1c2526dd5c50568d680271c3163e71f04115e610dcf08a0bfe4b8c41d62f` |
| Compiler | Existing llvm-mingw 20260922 UCRT x86_64 |
| Isolation | Private executable/dependencies copy; private `COE5_SAVE`; `COE5_DATA` reads owned installation's data |

No matching local project content or GitHub repository existed at intake. The existing empty project folder was used. No installed extender source/binary, regular save, regular mod, or regular profile was changed. The dev checkout's tracked files remained unchanged after the build (`git diff --exit-code`). Compiled artifacts and the entire lab remain excluded from Git.

## Evidence levels

| Area | Supported and exercised in the real game | Unconfirmed or restricted |
|---|---|---|
| Main menu and screens | `addMainMenuButton`, `ui.screenBegin`, `ui.wait`, native name box, `monsterRow` | Full UI acceptance coverage is in TEST-RESULTS |
| Input | Pointer coordinates, held `mouseButtons`, BATTLE_WAIT/DRAW wrappers; context precedence observed | `uiWheel` documented only in world previews; editor uses paging |
| Catalog | Monster names, Idle sprites, flags/categories, item names/types, spellInfo | No reliable per-record originating-mod or distinct attack-sprite accessor found |
| Mod content | Loaded database is enumerated after mods load | Mod-origin filter needs metadata; active faction-unit test recorded separately |
| Terrain | Named terrain table and batmap value readable | Cannot select terrain in test field: terrain 0 is hardcoded |
| Dimensions | Native width readable, height 20; native automatic growth observed | No supported manual Small/Medium/Large/Extra Large selector |
| Teams | Test field creates slots 0 and 24 with different teams; colors writable and restored | Test-field API does not initialize arbitrary factions' complete campaign settings |
| Creation/deployment | `openTestField` mixed groups, `moveTestFieldUnit` with native collision/footprint checks | No harmless remove/clone/snapshot helper; editor rebuilds candidate fields |
| Equipment | Inventory readable; native giveItem call accepted a test item | Unit anatomical-slot preflight not exposed; production assignment disabled |
| Magic | Native starting known/memorized spells readable; memorization APIs available | No exact base-school setter or arbitrary known-spell teaching/restoration found |
| Combat | `fightTestField` runs real AI; speed controls visible and used | Complete damage source/cast-event coverage not established |
| Results | Winner, round, original roster outcomes, unitKills | Actual return-time coordinates were nil even for a survivor; native post-fight view was empty. Retained final deployment is unavailable; aftermath observations tested separately |
| Persistence | `writeIni` / `readIni`, schema/content validation and actual native re-opening | No full content fingerprints or exact native unit-state snapshot |

## Sources inspected

- [Lua reference at the pinned commit](https://github.com/musical-pianist/coe5se/blob/57abc69a2ddb272a5b9049b4a561367066d9d99e/coe5.lua): API contract and restrictions.
- [Test-field implementation at the pinned commit](https://github.com/musical-pianist/coe5se/blob/57abc69a2ddb272a5b9049b4a561367066d9d99e/src/lua_test_battle.h): native setup/deploy/fight calls and fixed test terrain/slots.
- [Upstream example](https://github.com/musical-pianist/coe5se/tree/57abc69a2ddb272a5b9049b4a561367066d9d99e/ToolsAndExamples/MachineCult): mod file structure and loaded content.
- [Official game modding manual](https://www.illwinter.com/coe5/coe5modding.pdf) and [upstream documentation](https://musical-pianist.github.io/coe5se-docs/).
- Existing local spell/weapon workbench's isolated-launch implementation: confirmed `COE5_SAVE` and `COE5_DATA` usage, rechecked against this game's execution.

Source inspection is not described as an in-game test. Tools and examples were examined without editing the extender. No private reverse-engineering output is distributed.
