# SandboxOfElysium development journal

## 2026-11-13 — scope and baseline

- Request: independent public Lua sandbox project, build on current CoE5SE dev, test actual combat early. No extender changes, no invented APIs/values, no automatic contact with the author.
- Existing project folder was empty. Repository lookup through GitHub connector and authenticated CLI found no SandboxOfElysium repository. Available account: Chazammm.
- Owned Steam app 1606340, build 26458448, native Windows x64 CoE5 5.43. Scanner found no anti-cheat. Local paths are intentionally excluded from public notes.
- Installed extender DLL metadata: 3.2.2, SHA256 `87e70dead42341573889641447d04c700af359243696a57b32e89a4fac682e8a`.
- Examined dev: `57abc69a2ddb272a5b9049b4a561367066d9d99e`, metadata 3.3.0/API 11. Built unchanged with existing llvm-mingw 20260922. Local plugin hash: `6faf1c2526dd5c50568d680271c3163e71f04115e610dcf08a0bfe4b8c41d62f`. Tracked upstream diff stayed empty.
- Relevant API reference, test-field source, bindings and examples inspected. An existing local workbench provided a starting point for profile isolation, revalidated here.
- Knowledge-base cache had no matching CoE5 note; live index and current primary sources consulted. Findings are prepared locally in the English API handoff. No external knowledge-base PR or message was sent.

## Isolated oracle and first vertical slice

- Ignored `private/lab/runtime` contains a private executable/dependency copy. `COE5_SAVE` points only at `private/lab/profile`; `COE5_DATA` reads the owned installation's data. A copied configuration is backed up in the lab; no real saves were loaded.
- A sandbox-account process was not targetable by desktop automation. It was stopped by exact PID; later launches ran in the visible user desktop with the same private environment.
- Fixed initial mod metadata/icon requirements (native banner must be 256×64).
- Actual first main-menu battle: one Spearman vs two Goblins. Winner A, final round 4, surviving Spearman 4 HP. Report retained in docs/evidence/initial-battle.ini.

## Implementation and native regressions

- Implemented separate model/catalog/runtime/report/UI modules. All engine operations use public coe5 methods. No DLL/plugin hooks or upstream edits.
- Native grass field uses slots 0/24 with opposing teams. Colors are temporarily applied and restored separately from team membership.
- Native movement validates anchors, footprints and blockers. Candidate fields implement additions/deletion and deterministic re-placement; restoration errors are visible. No dummy combatants are used.
- Formations: native Single, horizontal/vertical counts 1 and 15, squares 2/3/4 all passed. Pure Lua covers every row count 1–15.
- Copy/move/configured-item preservation, deletion, INI roundtrip, same-color hostility, small battle/reset/rematch and 100-vs-100 battle passed inside the real game.
- Width observations: 32 small, 34 at 100 vs 100, 84 for 500 vs 500 created/deployed. Only the 100-vs-100 case was actually fought. First large battle: 98/100 Spearmen survived; 0/100 Goblins survived.
- Private copy of installed CrabCult activated: Shorebound Initiate (#2000) fought and won against a Goblin. Visible browser also selected/placed an Abyssal Shellback (#2004), confirmed in native view. No faction files are published; complete faction campaign effects are not initialized.
- Catalog search, Idle pictures, sorting, context priority, move, explicit cancel, Clear, scenario load, combat start and report were operated through the actual visible game UI.
- Right-drag logic exists but a long physical right-drag is not fully acceptance-tested. Native wheel scrolling and attack-artwork selection are not claimed.

## Corrections and confirmed constraints

- Move originally allowed a held click to fall through to placement. Corrected branch and release guard; visible move subsequently kept count 1. Explicit cancellation button works; unreliable automated Escape behavior is not promised.
- Name-only spell keys collided. Preserved failed native result; changed to ID+name. Native removal/re-memorization then passed on an Old Wizard (8 known, 4 memorized).
- Saving/recreating that Old Wizard produced a different starting spell set. Exact restoration was refused rather than silently randomized. This can block additions/copy/delete/reset when rebuilding randomized casters.
- Item event helpers work, but anatomical slot preflight/replacement guarantees remain unclear. Production item assignment stays disabled.
- Native test field fixes terrain 0, offers no manual width presets. World terrain helpers are not assumed to rebuild the test field. Terrain selection, base magic upgrades and reliable mod provenance remain gaps.
- Actual post-fight UI disproved native final-scene retention: living Spearman 6 HP / 1 kill, both battle coordinates nil, empty native terrain on draw. Return-time coordinate count was zero. BATTLE_TURN_EFFECTS aftermath observation separately captured one survivor position before cleanup; no native final-scene reconstruction is claimed.
- Native kills and original roster outcomes are exported. Direct synchronous HP-loss attribution is explicitly partial; full damage and all-cast telemetry are unavailable/unproven.

## Delivery and remaining work

- 16 offline model tests pass; all distributed Lua files parse. Native evidence retains both failures and corrected regressions; see docs/TEST-RESULTS.md.
- README includes installation, uninstall, compatibility, data/report paths, limitations and AI/tool credits. docs/API-GAPS.md is the English handoff for musical_pianist.
- Package/repository use explicit original-file allowlists. Private game/runtime/config/key copies, upstream sources/binaries and copied mods are excluded.
- This is prototype 0.1.0, not full acceptance. Next work depends on clarified/extended test-field configuration, safe state snapshots, slot compatibility and event/projection APIs, followed by full physical drag/UI and randomized-caster acceptance.
