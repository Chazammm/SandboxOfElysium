# Additional vanilla sieges, 2026-11-17

Local **0.1.0+editor.15**, after clean Sandbox `0d49f3f767de280fe47d0d5c89ebf0944fa08b6a` and separate Extender `fac593df1cc4960407dcac9f60d720a1dcbb4a2a`. Preserve the earlier [zoom/first-fort](TEST-ZOOM-FORTIFICATION-2026-11-17.md) and [log-layout](TEST-LOG-LAYOUT-2026-11-17.md) reports as historical checkpoints. No release, remote push, new PR, earlier-contribution edit or binary distribution.

## Playable presets

Separate experimental Extender checkpoint: **`77cd67b0506176490eb0fe507f54f4b26a719ec0`**, in `SandboxOfElysium-ExtenderLab-next`. It is paired with this editor.15 source checkpoint by the private manifest and handoff. The earlier `SandboxOfElysium-ExtenderLab-current` and submitted review checkout were not edited.

Six additions plus the existing Fortified Hoburg make **seven sieges**. All eleven prior neutral contexts remain selectable: **eighteen choices total**. These are particular verified native terrain/context combinations, not every world-terrain variant of a template.

| Preset / terrain | Actual native template | Fort parts | Tower context | Gates observed at minimum50 | Fresh ordinary native matrix |
| --- | --- | --- | --- | --- | --- |
| Guard tower20 | stonetower |1548/0x60c|true|1 wooden|PASS, two battles, rounds5/5|
| Watch Tower72 | woodentower |1549/0x60d|true|1 wooden|PASS, two battles, rounds5/5|
| Castle22 | greatwall |2821/0xb05|false|2 iron|PASS, two battles, rounds4/4|
| Citadel23 | citadel |2568/0xa08|false|3 iron|PASS, two battles, rounds4/4|
| Town17 | town |1574/0x626|false|2 wooden|PASS, two battles, rounds4/4|
| City9 | city |1831/0x727|false|2 wooden|PASS, two battles, rounds4/4|
| Fortified Hoburg1, retained | palisaden |1546/0x60a|false|1 wooden|PASS, two battles, rounds6/6|

All use native Elysium plane0, temperature25, siege=true and sea/underground=false. **Team A attacks; Team B defends.** Gates, walls, buildings and tower scenery are native map content outside the editable army roster and counters. Castle deliberately uses the game's actual `greatwall` battle layout. Exact names/flags, native selected filename, complete fort parts and returned context must agree; replaced/unexplained contexts still refuse.

The six templates were compared on screen: stone and wooden enclosed towers; Castle's broad stone wall; Citadel's outer wall plus inner fort; Town's palisade/buildings; City's larger wall and urban buildings. File existence alone was never acceptance.

## What changed

Sandbox adds six exact loaded terrain identities and an explicit siege set shared by capability checks, setup hints and Clear messages. Available-preset count follows the actual validated catalogue. Scenario schema4 and all controls/placement/configuration/recovery paths remain. Missing native advertisement, wrong identity or missing structure capability refuses before replacing the current field.

Existing constructor provenance works for every new gate: loader return0x874d3, terrain placement0xf065f, gate replacement0xee3d7. No constructor whitelist, monster-name exception or ID-only structure classification was added. A separately created actor of a gate's monster type remains an actor. Native structures do not satisfy an empty team's battle requirement.

The separate Extender additionally reads/verifies the specialized stone/wooden tower context. Native32-bit RVA0x5804c50 is reset on each BATTLE_SETUP and set only by selectors12/13. It affects deployment and wall-cell flags, not just artwork. `testFieldEnvironmentInfo().towerContextVersion=1` advertises additive `testFieldEnvironmentState().tower`. Existing version1 fields remain compatible. Setup compares the exact native integer0/1 with the expected selector, and close restores/verifies the previous native value. No new writable Lua API is exposed. The source contract/native evidence/limitations are in the separate Extender's `SIEGE-CONTEXT-EXPANSION-2026-11-17.md`.

Native parapets are not universally forbidden placement tiles. Each matrix checked a flagged wall/parapet cell against native strict passability and verified matching editor behavior; tested cells accepted a1x1 defender. Gate overlap remained blocked on repeated attempts. Collision/integrity rules were preserved, not relaxed. Exact saved positions are verified; refusal keeps recovery rather than silently redeploying or changing randomized spells.

## Exact build and native evidence

Owned Windows CoE5 5.43 x64 / Steam26458448, executable SHA256 `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`. Final ordinary `siege-expanded` plugin SHA256 **`1cc51388dac0a10753acf856fcc9f0f94aa636bd2add9b2531d92abac10f4a65`**, existing build script/llvm-mingw20260922, no warnings/candidate flags. Tested mod-tree SHA256 **`18b3814ee03a1b3f13d976248df28b6be34b8ed8bc348fc3c2e7dedda9459fa1`**. Later changes are tests/documentation, not product code. Private manifests bind source/probe/session/build and the final separate local commit pair.

Fresh ordinary runs `ordinary-tower20` and `final-siege-72/22/23/17/9/1` all passed. Each matrix covers:

- Actual native context, complete current actor/grid observations and constructor-proven structural occupancy. Same-monster actor creation cannot acquire structural provenance.
- Attacker and defender placement; empty and one-sided Save/Load; battle refusal with an empty side; no hidden commander/count.
- A native-legal parapet cell, repeated rejected gate overlap, diagnostic export,2x2 **Elephant** and3x3 **Ageless Troll**, permanent deletion and immediate cell reuse. Existing actors remain consistent.
- Individual names **Gate Breaker** / **Siege Sage**, a Druid's Apprentice with deliberately raised base school and Amulet of Anti Magic, exact randomized known/memorized spell lists, full scenario Save/Load and restoration.
- Two naturally resolved native battles, observed native movement and gate damage/breach, complete bounded final capture, Reset/rematch rebuilding and exact pre-battle setup equality.
- Clear leaves zero actors on both teams and retains native structures; complete permanent cleanup and verified tower-context restoration.

Native WAIT fast-forward removes display delays only; it does not inject damage, winners or battle-over state. Gate counts in the table are observed structural generations in these fixtures, not an inferred type list. The probe's older `walls` diagnostic counter counts all flagged grid cells, not a complete wall-object inventory.

All six additions also passed minimum32 matrices (`size-20/72/22/23-32`, `size-retake-17/9-32`). Castle additionally passed70 and160; Guard tower passed160 (`size-retake-22-70`, `size-retake-22-160`, `size-retake-20-160`). Not every terrain/army/size combination was tested. Native automatic size32 was separately opened through the ordinary City menu and Fit worked.

| Current regression | Fresh result |
| --- | --- |
| Plain/Forest | `retake-land-0/2` PASS: actual original land matrices, two battles each, state/persistence/cleanup. |
| Farm/Village | `final-map-5/18` PASS: native stock-template matrices, two battles each and restoration. |
| Environment/catalogue | `final-environment-metadata`11 groups PASS: current verified contexts, still-unsupported guard cases, all five original neutral templates at automatic/160 sizes with native fights/cleanup. |
| Viewport normal/wide | `final-viewport`, `final-viewport-wide` PASS: actual Fit/pan/projection, four corners at10/25/50/75/100/150/200%,3x3 hit/preflight/context checks, unchanged actors/cells. Pointer coordinates are injected in this API matrix, not physical drag evidence. |
| Log normal/wide | `final-logs`, `final-logs-wide` PASS: production hooks, default visibility, continued hidden messages, post toggles, two siege battles each, Reset/rematch and cleanup. |
| Controls/configuration | `final-controls`4 groups PASS: retirement/reuse/rejection, both-team unique policy, cursed/implanted held items and separately installed CrabCult bonus-spell refusal without trimming. |
| Individual naming | `final-names`3 groups PASS: names/Unicode/limits/Move/Copy/SaveLoad/ResetRematch, deletion without leaks/caster changes and legacy labels. |

Offline **243 cases across16 Lua behavior suites**, plus syntax, PASS. The13 new siege contracts cover all seven exact identities, capability/native-advertisement refusal before close, schema4 names/items/ordered spells/state, all11 neutral identities, hints/Clear and unchanged controls. C terrain-policy harness: **235 assertions in each ordinary/candidate mode**. Launcher `-CheckOnly` and both repository whitespace checks pass. Offline/C checks do not simulate game behavior.

## Visible observations

Final ordinary build and editor.15, requested1200x900, captured962x752/native UI800x600; private session `e5d367da64064fd4801a18178d52d1a5`, retained as `visible-sieges-normal`. All launches used **`--nosound --musicvol=0`**.

Castle opened with native stone walls and two gate actors, A7/B4 counters and no setup log. Fit32% showed the complete field. A real battle visibly showed native gates, advancing armies and spells/damage, then naturally completed with Team A7 survivors, Team B0, round4. The post field showed native combat messages containing **Siege Sage**; Hide removed the log. Back to Sandbox restored A7/B4 and32%, with gates and setup log hidden. Clear visibly produced A0/B0 while walls/gates stayed; starting then displayed the missing-team message and kept the empty field. Reset restored A7/B4.

Guard tower showed the distinct enclosed stone platform. After selecting Team B, a right-click inside the platform placed a Spearman and changed B4 toB5 at the displayed cell. A normal battle and a clicked Rematch both naturally completed round6 with A7 survivors/B0. The report retained individual names; Back restored A7/B5, the platform defender and32% zoom. Watch Tower, Citadel, Town and City were separately opened, rendered at32% and closed through Back; their layouts were visibly distinct. Those four did not receive separately watched battles; their native matrices above did complete battles.

The ordinary **Sandbox -> Battlefield** picker showed all18 entries at normal resolution without losing navigation. City was selected there, its attack/defense hint appeared, and Open with native deployment opened the default A1/B1 automatic field. Fit51% displayed its complete32-column field. All owned fields were closed via Back. Quit was requested and exact-PID process cleanup followed; no game remains running. This task did not repeat physical mouse tests at another resolution; actual viewport/log regressions did run at1704x900/native UI1136x600. Exhaustive physical dragging/Inspect at every zoom remains unclaimed.

## Preserved failures and remaining limits

Early discovery tried to read a nonexistent `state.objects` table; actual scenery is observed through grid/native lifecycle. Those harness failures remain archived, followed by fresh passing discovery. An overly strict test demanded an unplaceable empty wall cell, but the native parapets were legal; acceptance was corrected to compare actual strict native passability, without changing product collision rules. A smallest Town fixture later targeted a real building at a hardcoded coordinate; the editor correctly refused it. The fixture now chooses an actually empty cell on the requested side, and fresh Town/City/larger-size retakes passed. A neutral probe module was initially loaded without invoking `run`; that driver failure ran no terrain test. Corrected wrapper retakes passed. No failed/stopped run was relabelled a pass. Generated QA artifacts were preserved outside its active data directory between runs to keep exports bounded.

Still unavailable:

- Other surface wall/fort variants such as lowwall/lowwalln, highwall/highwalln, witchtower, widebronzewall and Temple City: selector candidates exist, but their own placement/combat/persistence/cleanup matrices have not passed. This is missing acceptance, not a claim that they are impossible.
- Duplicate world variants such as Guard tower21, Baron's Castle30 and Motte and Bailey199: not independently admitted/tested; some reuse an accepted template and do not add a new layout.
- Water/ports/coasts, cave/underground, cloud/infernal/other planes, special/magic walls and campaign enchantment variants: require additional verified neighbor/plane/sea/effective-fort context. The current owned initializer is surface Elysium0/temperature25 and deliberately refuses mismatches; file existence cannot supply those contexts.
- Mac/Linux, arbitrary mod combinations, full campaign equivalence, full native log telemetry and complete opaque unit/scenery serialization remain unavailable or unverified. Final view is a timed units/cells snapshot after aftermath, not the full retained animated scene. Recovery can still refuse exact positions after changed/random scenery; preserve the scenario/export and restart the isolated game if native cleanup is unverified.

Current [upstream dev](https://github.com/musical-pianist/coe5se/commit/9d74ae4fc70d019bb088dc26995594c71f6e2497) was rechecked. [PR #2](https://github.com/musical-pianist/coe5se/pull/2) is already squash-merged at `be8a2bf7b4fa094d828e2ad56eb0376e51adf3e1`; no new contribution was submitted. New native evidence has117 records, SHA256 `eb38ffd3ae8428b2556d0e9ff9c29f362a5311346d8cac07dfa3e9ea1a24b845`; target closed/reset. All original scenarios/diagnostics/protected sources are preserved and checked against fresh before-task hashes.

## Try next

Use **SandboxOfElysium-Testen.bat -Muted**, choose **Sandbox -> Battlefield -> Castle** (or another new siege), then **Open with native deployment** for a new setup and **Fit**. Team A attacks, Team B defends. Try custom ranged/flying/large armies, placement on legal battlements, rejected gate overlap, Save/Load, Back, Clear, Reset and Rematch. Keep-position loading will verify saved cells and refuse collisions rather than redeploying. Try Citadel and the two towers first for the clearest differences.
