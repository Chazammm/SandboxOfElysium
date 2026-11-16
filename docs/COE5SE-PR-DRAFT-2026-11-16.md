# CoE5SE API PR: submitted description

[PR #2](https://github.com/musical-pianist/coe5se/pull/2) is open against `dev`. The filename retains its preparation history; the description below is the submitted version.

What this changes, and why:

These are general technical capabilities for Lua mods that need an owned main-menu test battlefield, reliable native actor/configuration state, loaded-content origin and catalog queries. SandboxOfElysium is the current consumer and integration test application; the mod remains in its own repository and is not part of this change. This combines the prepared API contributions into one source-only proposal against official `dev`, retaining current upstream machinery wherever it already supplies the required behavior.

Sandbox source: https://github.com/Chazammm/SandboxOfElysium

Base: `musical-pianist/coe5se:dev` at `df09497f04a39ff8fb7b0979dedde7dfed120c64` (3.4.4/API 14), fetched again on 2026-11-16. Candidate: `Chazammm:pr/sandbox-editor-api-20261116` at `816671921e1b0499b2e69ead87dc19c112304004`.

## API areas

### monsterHasRanged

Upstream already exposes the native classifier and Windows mapping. This changes only that call's main-menu permission (`m` to `@m`), retaining monster-ID validation and unrelated game-context guards. Sandbox can populate Ranged before opening a battlefield. It is not a replacement classifier or a new Mac mapping.

### Content origin

Upstream already has loaded catalogs, `monsterMod`, mod-command processing and content-write tracking. Those are retained. `loadedContentOrigin` adds observed defining/last-writing mod information for loaded items, spells and spell schools, bound to the current record. Unobserved writes invalidate attribution to Unknown; `historyComplete` remains false. This supports Modded Items and Modded Schools without guessing origin from numeric IDs. A native school containing mod spells is distinct from a mod-defined school. This is not a complete history of all content or graphics changes.

### Test-field lifecycle and core

Upstream already has `openTestField`, add/move/draw/fight/close and native battle/unit queries. The existing entry points are extended with explicit `emptyEditor`, `allowMultipleUnique` and supported terrain options. Legacy calls and the legacy primary-commander protection remain; the empty editor has no dummy commander and battle start requires both sides.

Generation-bound ownership, whole-request unique preflight, optional independent unique records, verified removal/cleanup, full-footprint state queries and exact ordered spell operations provide the missing consistency contract. Native placement remains authoritative. A failed rollback or cleanup is an error with diagnostics, not success. The Sandbox caller preserves its setup and locks editing until explicit verified recovery/restart.

A new native regression exposed an additional callback race: `__index` could close/reopen a field during add-argument validation and the outer call would allocate into the replacement session. Open/add now recheck context before native mutation and return `context_changed`; both replacement-field regressions pass.

### Presentation and input

Upstream UI/layout/drawing, battle hooks, observers and INI storage are reused. Added owned-field APIs expose native viewport/projection, footprint queries, explicitly partial placement preflight, fitted native sprites, physical pointer state, committed SDL text/focus and genuine read-only unit/item Inspect. No native inspector edit finalizer is used to reroll spells.

Final actor/cell state is captured after aftermath (75 ticks), before upkeep clears it, through the existing upstream wrapper chain. Existing observers still run. `complete` describes actor/cell coverage; `sceneComplete=false`: effects, projectiles and animations are not retained. Survivor Inspect reads the current native record and can be unavailable for removed temporary actors.

### Items, magic and spell configuration

Upstream already has twenty-position item helpers, compatibility checks, spell metadata/lists, ordinary give/take/memorize operations and extended school/spell definitions. This reuses them rather than adding another global inventory or spell system.

`testFieldLoadoutState` and `setTestFieldConfiguration` add owned actor/session/generation-bound validation, native readback and verified rollback for equipment, existing base schools and ordered known/memorized spells. Caller tables use raw reads. Explicit cursed removal is supported; new permanent eye/heart implants remain protected. Existing schools can use base levels 1–3; template, base, item bonus, effective level and memorization allowance remain separate. Invalid memorization is refused unchanged; higher known spells are retained and randomized selections are never silently replaced. Maximum known/memorized lists remain 60/30.

## Review structure and compatibility

Seven focused commits cover ranged, core, presentation, configuration, origin, callback/integrated regressions and fixture instructions. Ranged and origin are independent; core must keep creation/generation/removal/cleanup together; presentation depends on core and configuration on both. The previous five individual branches and `review/sandbox-complete-20261115` remain unchanged as historical review alternatives. Their multi-PR descriptions are deliberately excluded here.

The total is 40 files, about 4.7k added lines, including LuaLS API documentation and native/offline probes. Lifecycle, text input, final capture and configuration make this substantial, but the dependency chain is technically practical as one PR. If smaller reviews are preferred, the concrete boundary is independent Ranged/Origin plus Core → Presentation → Configuration; no split has been submitted.

No Sandbox code, game files, private diagnostics, third-party mod files or binaries are included. Existing return conventions are retained, including ordinary no-value fight success. Capability detection is required: API 14 alone does not imply these optional additions. New editor hooks install only on an explicit owned-field open; queries do not install them. The API call supplies the opt-in instead of a new global Mod Settings switch; this is an explicit guideline exception for maintainer review. Ordinary upstream settings and behavior remain in place. Helper sections retain compact local comment blocks rather than adding a separate comment to every small helper.

Seven Windows 5.43 mappings are added in `game_addresses.h`; their address indexes are synchronized manually as CONTRIBUTING permits. `entry_hook_sites.h` retains all existing entries and adds two training-reader rows (53→55). Please regenerate these indexes/sites from the canonical mappings when integrating. The new addresses are marked unmapped on Mac.

## Verification performed for this candidate

Windows x64 CoE5 **5.43**; unchanged upstream `src/build.sh`, prescribed **llvm-mingw20260922**. Final commit rebuilt without warnings/errors. Private plugin SHA256: `86be1e51416a5000b108f654f9445e45170e74837bc0bfdbfdccb03a62babb4c`.

The tests below ran on the clean unsigned candidate `3195a061c78a5932025553f6a2fe4d4d908193a7`. All seven signed commits have exactly the same source trees as their unsigned equivalents; the final signed tree is identical, including the tests. The Windows build was repeated on signed HEAD and its three binaries matched the tested build byte-for-byte. No new in-game runs were performed during this sign-off-only finalization. The verified native results are: **61 passing group executions / 54 distinct named groups**, including seven repeated loadout groups:

| Suite | Passing groups |
|---|---:|
| Core, including two callback-context regressions | 9 |
| Presentation/final capture/upstream observer chain | 4 |
| Configuration raw-table/identity contracts | 3 |
| Loaded content origin | 4 |
| Ranged: all 1,879 named loaded monsters, 721 positives, zero context mismatches | 1 |
| Production Sandbox standard: empty/one-sided setups, cursed/configuration/filters/mod combat and five terrains | 21 |
| Explicit 20-slot/custom-school fixture and panel | 11 |
| Production placement, unique guards, Forest obstacle and explicit failed-cleanup recovery | 4 |
| Production inspector, memorization, battle/Reset/Rematch and read-only footprint regressions | 4 |

Also passed: **127 Sandbox offline assertions**, distributed/candidate Lua parsing, helper PowerShell/Python parsing, **21 C terrain-parser cases**, **51 terrain-policy assertions**, `git diff --check`, Windows-host platform guards and exact upstream legacy Mac Git-blob comparison. The latter is not a Mac compilation.

Visible workflow used the same final native source/DLL (the following final commit only corrected fixture README prose; the final rebuild is byte-identical). A private entry seeded the owned saved `q4` setup plus one Apocalyptic Rider per side, using current unmodified production modules. Manually verified: 3×3 Rider interior hit/context/Delete, immediate Spearman placement in its vacated cell, A2/B3 counters, Druid's Apprentice's cursed CrabCult Abyss Fragment, Druidism base 2, explicit QA school base 1 and known/memorized selection, two completed Forest battles, post-field, genuine Rider Inspect (180/180 HP), Rematch, Back to Sandbox and Reset. The post-view had four Team B actors because the opposing Druid changed owner; original-team reporting and captured current ownership were kept distinct. Five bounded exports reported zero native issues and preserved exact spell order. The normal menu sections were visible/readable at this machine's 800×600 internal resolution. Save/load, other equipment mutations, rejected placement and recovery were tested through the actual native production suites, not all repeated by mouse.

Historical branch tests and the older 39 combined-group executions remain supplementary evidence only. The pre-final visible `e2996d24…` build is not presented as this candidate. An initial duplicated declaration was caught by compilation and corrected; an inspector harness run missing its private replay fixture ran no groups, was retained, then reran successfully with the fixture. Neither is counted as passing evidence.

## Remaining limits and contribution procedure

- Mac: no Zig 0.16 compiler or runnable Mac game available here. No Mac build/runtime claim. Legacy Mac fields are byte-for-byte upstream; new editor capabilities return zero/empty and new options refuse `windows_only`. Content-origin portability is unverified on Mac.
- Terrains: Plain, Forest, Mountains, Swamp and Desert only. No water, siege, special planes or full campaign climate/season/enchantment equivalence.
- Serialization is deliberately incomplete: no full native HP/injury/affliction/opaque-unit-state restoration. Removing Crystal Heart preserves a live permanent injury, but reconstructing the actor does not serialize that injury. Final captures and combat attribution are partial; native combat text can remain over the post-field. Summons/owner changes are distinguished from starting teams.
- Table exhaustion/compaction, arbitrary mod combinations, campaigns/multiplayer, every camera/zoom, sustained physical drag and exhaustive Unicode/IME behavior are not accepted. This does not claim the complete original Sandbox feature set.
- The user reports prior maintainer agreement to review this work. No new issue/contact was made; please confirm that prior discussion satisfies the issue-first guideline.
- The contributor explicitly accepted the current CONTRIBUTING.md terms and confirmed the right to submit these changes on 2026-11-16. All seven commits carry `Signed-off-by: Chazammm <138124106+Chazammm@users.noreply.github.com>`; the configured identity was verified against the connected GitHub username/account ID. Sign-off changed commit metadata only.

- [x] Intended base is `dev`, not `main`.
- [x] Every commit is signed off, agreeing to CONTRIBUTING.md, with the contributor's explicit authorization.
- [x] Tested in game on Windows CoE5 5.43 x64; Mac untested.
- [x] Change lines are in `.github/DEV_NOTES.md`.
