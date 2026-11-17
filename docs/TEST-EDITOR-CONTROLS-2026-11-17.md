# Editor.12: rejected Troll lifecycle and battlefield controls

**Later user correction, 2026-11-17:** mouse-wheel zoom was withdrawn. Formation sizes now have adjacent minus/plus buttons; minus stops at one for rows and 2x2 for squares, and Single hides both. Native zoom buttons remain. The follow-up mod tree is `a86434e20becbf6390895f542eb41be4ee3c71737695dd25482c4fcb795e2c1a`. All188 current offline cases plus syntax pass (four obsolete wheel cases removed). Visible muted session `8a3799c2fd0246b7ae715887424d8d8c` confirmed Horizontal1→2→1→1 and no wheel zoom at100%, with both army counters unchanged. No new battle was launched; the separate Extender was unchanged. Results below describe the preceding `eaded4aa50d18d75229d12e13408432ce1efb8a3` checkpoint and retain their original wheel-test/version boundaries.

Local development only. Sandbox and experimental Extender source remain separate; no modified DLL, private diagnostic, game file or third-party mod is distributed. The submitted API PR is unchanged. Every game in this investigation used `--nosound --musicvol=0` and a new private runtime/profile, leaving the user's two previous lab profiles intact.

## Diagnostic chronology and uncertainty

All three original `diagnostics-7263c221355a46848eaf-{1,2,3}.ini` files were read before edits. They identify editor.11, mod tree SHA256 `d08d71dbe14932cbe7747a8c8c3c59d9f1c95920db1efcd0918dc19555ff4700`, experimental DLL `596a7b7459752bb33d480320933fec4faf38a37391edf2db6a624e2e8cdf008b`, game 5.43.

| Export | Recorded evidence |
| --- | --- |
| 1, elapsed 295391 ms | Cached failed Ageless Troll #962/native4449, candidate model10/team B, anchor29,9. Removal said OK and rollback verified. Before/after failure contained nine model/native actors; current generation46 contained fifteen and no Troll. The bounded 64-action window does not include the earlier failed action itself. An older cleanup row describes4449 already dead, HP -163. |
| 2, elapsed 312938 ms | Battle528/529, Reset530, Troll selection540. Rejected 3x3 attempts544/549 at15,10 and14,11; native4552/4553, last candidate model16. Current generation47 still fifteen actors, no model Troll. Creation-time HP131/"active" is not a current life-status measurement. |
| 3, elapsed 328657 ms | Battle560/561, Rematch562, battle563/564, reopen565 `temporary_square_busy`, integrity lock566. Fifteen model actors preserved in a recovery file. Post-battle actors without anchors are phase-specific evidence, not proof of a complete retained battlefield. |

These exports alone do not establish which exact rendered Troll the user saw, nor all earlier actions. No missing history was invented.

## Confirmed cause and recovery

A private frozen-source replay used the actual fifteen-actor schema4 recovery copy, Hoburg Village, and the two recorded rejected anchors. The original removal and lifecycle cleanup wrote HP zero and cleared a grid anchor but left the native unit at world square1,1. Native `BATTLE_TURN_EFFECTS` regenerated rejected Trolls104/105 from HP0 to positive HP. After a new field generation cleared the previous ownership ledger, old Troll104 survived a later battle at HP131. The reopen preflight identified **unit104, monster962, owner24, HP131, not owned by current lifecycle session2**, then returned `temporary_square_busy`.

This links both symptoms in a controlled reproduction. Different battle outcomes did not always reproduce the final busy error; the bounded user exports do not prove that their original native IDs followed precisely that replay.

The separate experiment now uses the native non-death removal routine for generation-proven owned allocations: HP -9999, world coordinates -1/-1, commander/world unlinking and both grid layers cleared and verified. This includes failed allocations and already-dead actors during close. Combat death/kill events are not fabricated. Native slots are tombstones, not compacted table entries; they are detached and cannot occupy cells or enter subsequent fights. Sandbox independently verifies retirement before accepting a delete or failed-add rollback. An older HP-zero implementation now locks editing rather than reporting success.

If retirement, restoration or identity cannot be proved, editing stops, the scenario/recovery and diagnostics are retained, and the user is told to restart the isolated process and load the preserved setup. An unknown actor on a busy square is never silently deleted. Recovery does not reroll or trim spells. A process already poisoned by the old implementation needs that restart; updating Lua inside it cannot identify all lost generations safely.

The final capture excludes only physically verified pre-battle retired editor allocations and reports their count. Lifecycle diagnostics retain them. A reactivated retired record is included with an issue, not hidden. Natural battle deaths remain participants. Final captures still have explicit partial coverage.

## Controls and separate API contract

- **Multiple unique:** `setTestFieldMultipleUnique(boolean)` changes both scoped constructor-policy flags in place after full ownership validation. No map setup/deployment or view mutation occurs. Off refuses duplicate living unique types, including opposite teams or outside-field physical duplicates. Missing support never falls back to a rebuild.
- **Zoom:** Zoom - / percentage / Zoom + use native cell-size and camera globals, 50–200% of viewport-height/20, in 10-point steps. The same native renderer/projection powers previews, mapping and large-unit hit testing. Setter calls occur after native WAIT; input waits for a fresh native DRAW. Saved zoom is reapplied once per new editor generation. Fights and final views use their existing native behavior.
- **Wheel:** scroll over the editable map to zoom around the pointer. Lists/right panels, text focus, configuration windows, context menus, notices and held placement gestures retain priority. Their wheel steps are discarded rather than replayed later. `testFieldPointerWheel()` is an owned WAIT-only, non-consuming, wrapping cumulative native frame counter. Existing preview-only `uiWheel` is not repurposed.
- **Starting items On/Off:** same scenario flag as setup; affects fresh placements only. Existing actors, copies and restored configurations retain their recorded items.
- **Single:** no plus/count control and exactly one unit per placement. Row and 2/3/4-square controls remain.
- **Clear All Held Items:** confirmation states both teams, actor/item totals, cursed/implant counts, injury and spell protection. Each actor is one `clearHeldItems=true` configuration transaction with all twenty requested positions empty and identical ordered known/memorized spells/base schools. Permanent injuries remain. Invalid bonus removal refuses unchanged. Earlier completed actors remain cleared if a later actor fails; the message gives exact partial progress and whether the failed actor was verified unchanged. Unverified rollback locks editing. It does not claim batch-wide atomicity.

The native zoom experiment checks the supported executable and exact instruction/callsite bytes. An early ordinary C detour failed because the native helper preserves EDX across calls and the renderer retains screen width there. The final observer uses Clang's register-preserving convention and accepts only verified battle-map screen callsites. Earlier viewport/camera failures remain archived as failures. This is Windows5.43-specific experimental support, not a general campaign/Mac zoom hook.

Current upstream dev was fetched and inspected at `9d74ae4fc70d019bb088dc26995594c71f6e2497` (CoE5SE3.5.0). It does not supply these new contracts. The tested local experiment stays on its existing separate line; no submitted contribution was rewritten.

## Verification boundaries

Offline: **192 cases across thirteen Lua behavior suites**, plus the syntax suite, PASS. This includes 28 control/batch/wheel/closed-setup contracts and two retirement refusal regressions. Two C terrain-policy modes pass154 assertions each. These checks do not simulate the native engine.

Actual native-process controls tests on the final build use production Lua: the user's exact15-actor copy, six rejected Troll attempts, five naturally completed fights with Reset/Rematch, exact model/configuration roundtrips, 3x3 deletion/all-nine-cell clearance/immediate reuse, repeated edge rejection, independent Arch Devils on both teams and in-place policy refusal/acceptance, cursed/implant clearing, and a CrabCult Shell Priest/Abyss Fragment memorization refusal followed by explicit deselection/retry. Native zoom checks cover0.5/0.75/1/1.5/2, visible-cell screen/cell roundtrips, large interior hits, unchanged field state, deletion, battle/Reset/Rematch and cleanup. Exact final build/result bindings are recorded below after acceptance.

Visible observations were made at a962x752 window (native UI800x600): v10 wheel map100→90→100; three wheel steps over the right panel kept90 and were not replayed; minus button90; 3x3 Heart Keeper context opened the actual named Arcane Frost Dragon Inspect with its equipment/spells. Native Inspect scroll/exit retained90. A Spearman was placed, deleted and immediately replaced in the same cell; counters/sprites followed A2→3→2→3. Unique and starting-items toggles kept actors/scenery/camera. Clear confirmed3actors/4items/2cursed/1implant, cleared2actors/3items, and stopped unchanged at Shell Priest `spell_level`; exported diagnostics. Cancel was also observed on the earlier v5 candidate with the same production controls.

The copied user's Hoburg setup visibly opened A4/B11 with the large/unique actors. A Troll footprint overlapping native scenery was rejected without count changes; diagnostics were exported. Its visible battle completed at round6, TeamA won (A4 start/3 survive, B11/0); post-battle view correctly said PARTIAL and included summons. Back to Sandbox restored A4/B11 and90% without a busy-square error. These v10 observations are not silently relabeled as final-v11 observations: the final change narrows the zoom observer to idle editing, and receives its own native/visible follow-up.

Remaining limits: complete sustained physical right-button drag and every combination at every zoom have not received exhaustive visible acceptance. Offline gesture scheduling and native projection/footprint tests cover their shared paths. No Mac/Linux game testing, full native-state/scenery serialization, complete damage/cast history or retained complete animated final scene is claimed. The eleven verified presets and existing size policy are unchanged.

## Exact accepted source/build and rerun record

Separate Extender checkpoint: `7442a9c931c449b460b6e50406b31e9cae12ac1c`, branch `experiment/sandbox-release-next-20261116`. The original tested Sandbox checkpoint is `eaded4aa50d18d75229d12e13408432ce1efb8a3` on `development/release-next-editor9-20261116`; its mod tree SHA256 is `67025a196aa011fda0428d0caf07130dafbc265795a1c1ba93ccadaa540e3af3`. The formation-size follow-up is recorded separately above.

Accepted DLL SHA256 `c64bb566284868cd32ba1c532688831f420198755a097528a47230ef6ab72973`, build `controls-final`, llvm-mingw20260922 through the existing build script, zero compiler warnings, no candidate/fault flags. The previous v11 build is byte-identical; a Mac-only capability guard changes no Windows output. No DLL is committed.

All rows below use that DLL and the final mod tree above. These are **38 distinct scripted native groups**, excluding driver wrappers/repeated zoom runs, plus the separately described visible observations.

| Current run | Session | Result/scope |
| --- | --- | --- |
| Core |9b6b6ff8037f4b0bad0d7eaf366cd1d3|4 PASS: actual user replay, retirement, unique, zoom including two fights/Reset/Rematch |
| Items |ff5ec15a12b04c65917736c95962a221|2 PASS: both-team curses/implant clear and explicit bonus refusal/retry |
| Existing native suites |7144f3b397d84f2d9617708027f9fc66|16 PASS: empty/one-sided field, deletion, caster/equipment/configuration/persistence/battles, filters and installed CrabCult |
| Placement |ab7e0c39b73f4ab88bace53d43d1c3d4|4 PASS: large Rider/Seraph/cell reuse, repeated rejection, Forest obstacles, unique guards, injected cleanup lock |
| Inspect/caster |13c778976bcc4f2a94433e96dfae5805|4 PASS: exact configured six-actor scenario, explicit invalid-spell repair, instance independence, footprints and battles/Reset/Rematch |
| Individual names |55125703e5ce45d394b787e890ee3380|3 PASS: two different Spearman names, Unicode/limits, Copy/Move/Save/Load/Reset/Rematch, native battle and deletion/no name leak, legacy labels |
| Release-next |994f887b6785475cb954148bd9cf6cfd|4 PASS: six neutral terrains/sizes, new-only equipment/copies, implant refusal, bounded state preservation and battle/Reset/Rematch |
| Restart recovery |1059dd339336448e944d12451c110f8c|1 PASS: new process loads the actual injected-failure recovery, exact priest known/memorized spells and verified field/cleanup |
| Final foreground follow-up |4bedb6c442204d35bcc8930caa381037|Zoom native PASS,1599 visible-cell roundtrips and two fights/Reset/Rematch. Actual rendered first fight observed. Manual equipped field repeated100→90 map wheel, panel three-step wheel stayed90, next map step100. Quit/cleanup verified. |

Two earlier placement regressions initially failed because they still expected HP0 and in-process recovery after unverified cleanup. Their expectations were changed to permanent detachment and mandatory restart; the fresh-process recovery check above supplies the missing end-to-end proof. An initial Inspect runner lacked its copied private `replay` input; after copying the original six-actor fixture without changing it, all four groups passed. Those failed runs remain private evidence and are not relabeled as passes. Earlier zoom candidates, partial scenes and the v10 visible workflow retain their version boundaries.

The original two profiles'799/993 backed-up files, protected submitted checkout395 source files, legacy dirty checkout385 source files, and normal game/config/DLL hashes remain unchanged. All task game processes were closed. No push, release, PR change or message to another person occurred.

### Run the current development version

Close the old isolated game, then run `SandboxOfElysium-Testen.bat -Muted` in the project root. The existing launcher builds/reuses the separate current experimental source and synchronizes current Sandbox Lua into its isolated profile. Open Sandbox → Battlefield → Open with native deployment (or keep verified saved positions). Test wheel over map versus panels, last-unit deletion and immediate replacement, blocked Troll footprints, unique policy without scenery changes, and both-team item clearing. Put one actor on each side before Start battle. Keep the original scenario when sharing fresh diagnostic exports; restart/load recovery after an integrity lock.
