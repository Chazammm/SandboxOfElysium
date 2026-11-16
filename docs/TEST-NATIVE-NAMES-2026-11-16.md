# Native individual names — editor.10,2026-11-16

Current local development, not a released dependency package. Sandbox source remains on `development/release-next-editor9-20261116` at 7891e2b plus preserved uncommitted work. Naming extends the separate `SandboxOfElysium-ExtenderLab-next` experiment based on 8166719; the submitted CoE5SE PR #2 and the older experimental checkout are unchanged. No commit, push, new PR, contact, game-file distribution or modified Extender bundle was performed for this task.

## Finding and implementation

Freshly fetched official dev remains df09497f04a39ff8fb7b0979dedde7dfed120c64 (3.4.4). Current source exposes writable commanderName and commanderTheName. Ordinary actors have no personal-name string/API. Changing monsterName would rename every instance of that shared type and is not used.

Private examination of the owned Windows 5.43 executable confirmed the ordinary native formatter, canonical commander formatter, Inspect header and original battle-log writer. The separate extension adds `testFieldUnitName` / `setTestFieldUnitName` with owned-field/session/constructor-generation guards. Ordinary actors use a **native formatter override**, not an invented native unit-record field. Real commanders use their existing personal-name record. Their native title remains "name the type", while unit-oriented combat calls use the personal name. No battle-message synthesis or BATTLE_LOG replacement is performed. Native unit/template identity, health, items, schools and spells are not edited by renaming.

Names are supported only in the owned main-menu test field. Production Sandbox uses the commander-free empty-editor API; a unit whose monster type normally leads armies is not automatically given a commander record. The separate real-commander acceptance fixture used the native test-field commander option, not a hidden Sandbox dummy. Full native scope, hook guards and ABI evidence are documented in the separate ExtNext `INDIVIDUAL-NAMES-EXPERIMENT.md` for a later contribution review.

## Player workflow and limits

1. Start the existing `SandboxOfElysium-Testen.bat`, then Sandbox → Battlefield → Open with native deployment (reposition units), or open exact saved positions.
2. Right-click a placed actor → **Edit → Name**. Click its field and type/backspace. **Clear native name** restores the native default; a commander restores its captured original personal name.
3. The limit is **32 Unicode code points and 47 UTF-8 bytes**. Both counters are shown. The 33rd ASCII character visibly produces **Name too long:33/32 characters,33/47 UTF-8 bytes.Previous name kept.** No silent truncation occurs. Multibyte characters can reach the byte limit earlier. The current field fits the complete bounded name with a smaller font for long text.
4. Move retains the name. Copy starts with that name and remains independently renameable. Save/Load, Reset and Rematch restore it after the saved native configuration. Preview hover/context and the editor use the full chosen name where space permits. The post-battle context queries the current native name only when its constructor generation matches; unavailable cleanup records are explicitly unavailable.

Empty is a clear operation; controls/invalid UTF-8/native format characters are refused. Legacy Sandbox-only labels remain separate and are never silently applied to native units. **Use previous label** explicitly promotes a valid label; a legacy 48-character label exceeding the new 32-character/47-byte contract is retained and refused for promotion with an explanation.

Schema4 records native names as hexadecimal UTF-8 plus a version/scope/count contract. This avoids the upstream INI format's rejection of outer whitespace and retains exact Unicode bytes. Formats1–3 stay readable; migration writes a new unused filename, preserving the source. An older schema3-only editor refuses4 instead of silently dropping names. Named scenarios refuse reconstruction before closing the current field if the API is missing. Reports include named individual rows and pre-battle name provenance, not a reconstructed combat log. Exported exact name fields use hex; readable report names with outer spaces are explicitly bracketed.

## Exact build and new tests

- Game 5.43 executable SHA256: `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`.
- CoE5SE 3.4.4 separate experiment, Windows llvm-mingw 20260922, original project build.sh: plugin `8a40f029d55ed4f03f756455259fd4d38bdb99fd5e39a7fb7ebf952adc68d9ef`. Fresh `naming-final-v2` build has no compiler warnings/errors and matches the earlier tested naming-v2 binary.
- Final distributed mod source-tree SHA256: `e62738c662ead2e589279ba383dfb1078c2b0d1be5b720456dbc78ffb0d24819`. Every final production/regression run below binds this hash, DLL hash, session and current dirty source manifest. The pure native API probe used the identical DLL before the final font-fit-only Lua change; it loads no Sandbox modules.
- **155 offline Lua contracts** (141 existing plus14 naming) and all 12 suites/syntax pass. Naming tests cover Unicode/codepoint/byte boundaries, schema 4 exact names/clear, old labels, missing-API preflight, transaction refusal/false success/quarantine and persistent UI error feedback. These are offline contract checks, not native Inspect/combat simulations.
- **24 pure C validator checks** pass with `-Wall -Wextra -Werror`: strict UTF-8 boundaries,47/48 bytes, controls, format characters and empty/whitespace cases.

| Current real-game run | Result and scope |
| --- | --- |
| `naming-acceptance-names-deletion` |3 groups PASS: two same-type Spearmen independently named; Move/Copy to other team;32-character rejection, Unicode/outer-space disk Save/Load, clear, two battles, Reset/Rematch; named actor deletion and immediate cell reuse without inherited name or caster changes; old labels require explicit promotion. |
| `api-naming-final` |2 native API groups PASS: ordinary Sir Klaus/Lady Mara and an actual commander Captain Henrik, strict native47-byte/input validation, clear/close record restoration and real battles. |
| `naming-acceptance-standard` |16 groups PASS: cursed removal, native configuration/spells, empty editor, unique ownership, Ranged/menu/filter and active CrabCult unit/item regressions. |
| `naming-acceptance-fixture` |8 groups PASS:20 slots, private mod school/duplicate spell names, native compatibility, exact spell/item state and two battles/rebuilds. Fixture is private and not distributed as an active mod. |
| `naming-acceptance-placement` |4 groups PASS: large-unit footprints/delete/reuse, Forest obstacle rejection, unique alias protection and explicitly injected Lua cleanup-refusal recovery. Normal native DLL has no injected fault build. |
| `naming-acceptance-inspector` |4 groups PASS: read-only Inspect guards/footprints, memorization and explicit recovery of the historically invalid caster copy, six-unit battle/reset/rematch. |
| `naming-acceptance-terrain-storage-retry` |6 groups PASS: Plain/Forest/Mountains/Swamp/Desert/Jungle native matrix, battles/rebuilds/cleanup. |
| `naming-acceptance-release` |4 groups PASS: tested sizes, guarded starting-equipment omission, bounded actor-state restoration, items/spells, battle/reset/rematch and refusal recovery. |

The original native `bt` traces contain **Sir Klaus attacks with Spear**, Lady Mara's own attacks/damage entries and **Captain Henrik attacks with Spear**. These are original game-formatted output, not Sandbox-generated combat entries. Ordinary template name remains Spearman. Name formatter/combat counters supplement that evidence but do not alone prove log/UI coverage.

The naming workflow compares the existing caster's known/memorized spell order, schools, items, captured baseline and bounded actor state; two complete fights are followed by exact supported setup rebuilding. Copied names initially match, then diverge independently. A named retired actor cannot be renamed, its cells are reusable and the replacement is unnamed. This does not claim every original native unit field is serialized.

## Direct visible observations

New visible sessions used the explicitly isolated cursed-lab runtime/profile at the normal962x752 captured window size. QA buttons only seed fictional setups; the actual distributed Sandbox editor/runtime and genuine native Inspect are used.

- Name tab showed Sir Klaus, counters9/32 and 9/47; physical `x` appended one character and updated both counts. Native Inspect title was **Sir Klaus**, with unchanged Spearman body description/stats.
- Actual native commander Inspect displayed **Captain Henrik the Spearman**, with no duplicated personal name. Closing its real native card started a battle that finished at round 3; its native combat name was independently verified in the native API trace.
- A full 32-L name visibly refused a physical33rd `x`. Red wrapped error was readable; field/header retained 32 characters. Clear restored0/32,0/47 and genuine native Inspect **Spearman**.
- Final product source displayed a full 32-W name in both the fitted Name field and native Inspect. **Kläus Ægir Ω** displayed in the Name field and native Inspect, with 12 code points/15 bytes. Unicode was inserted through the native API fixture. `sky.type_text` did not generate SDL text events; international physical keyboard/IME input is **not fully verified**. No workaround synthesizes successful input.
- Native Inspect was closed with Exit, fields closed with Back and the game quit cleanly. The native combat panel and post-battle name context were not separately visually inspected; native trace/API and production battle/report tests cover their stated narrower contracts.

## Failures retained and remaining limits

Earlier candidates remain private evidence: the initial API harness incorrectly asserted a truthy return from legacy fightTestField (success returns no values); the initial commander-record-only hook left unit-oriented combat messages as Spearman, which led to the verified formatter bridge. A production probe initially held a stale Lua actor reference after Copy; the harness now resolves the current model. Another probe wrote raw outer-spaced Unicode into a QA results value and timed out after INI refusal; it now records an exact hex value. These failed/partial runs were not relabeled as passes.

One final terrain wrapper failed while saving its large result because accumulated QA exports reached the existing 10 MiB **private QA mod** data quota. Native matrix rows had run, but the run remains FAIL.169 newly created QA-only files (2,416,908 bytes) were preserved by moving them into a manifest-verified private archive; no pre-existing files or Sandbox user scenarios were moved/deleted. The fresh six-group terrain retry passed. This is storage-limit handling, not proof that the failed export succeeded.

Native combat rows hold **63 bytes for the entire message**. A valid name cannot guarantee an untruncated arbitrary message, especially with long spell names or multiple actors. Inspect/formatter titles and Sandbox display are not a promise about every campaign/report screen. Glyph coverage, all international keyboard/IME input, dynamic commander promotion/demotion, transformations/conversions and every monster context remain incompletely tested. macOS/Linux are untested; the new API is Windows 5.43-only. Native save/campaign persistence, complete combat telemetry and full unit/environment state serialization are outside this contract. Supported test terrains remain the six verified neutral lands; no new water/siege/plane support is implied.

## Preservation and local retest

All 385 protected files in the older experiment and 395 submitted-PR files, their Git heads/status/diffs and staged diffs are unchanged. Normal game executable, normal profile config and regular CoE5SE DLL hashes are unchanged. All 18 pre-existing Sandbox data files other than generated launcher context remain byte-identical; earlier uncommitted Sandbox/release-next work is preserved. All new raw native research/test exports and DLLs remain ignored under private paths. Both repository diffs pass `git diff --check`.

`SandboxOfElysium-Testen.bat -CheckOnly` passed current paths/profile checks without building or launching. Its existing default points to ExtNext and rebuilds/synchronizes changed local source on an ordinary launch. This task's actual naming/native/visible sessions used the isolated cursed-lab helper, **not a claim of another full BAT-launched naming session**. To retest: launch the BAT, place two Spearmen, right-click each → Edit → Name, enter different names, Inspect, try a 33rd character, Move/Copy/Save/Load, then battle and Reset/Rematch. A named scenario requires this separate experimental naming API; stock3.4.4 or submitted PR #2 alone is insufficient.
