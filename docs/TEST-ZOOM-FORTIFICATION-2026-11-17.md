# Zoom viewport and first fortification acceptance — 2026-11-17

Local editor.13 work; separate experimental Extender. No GitHub push, release, PR modification or binary distribution. Started from clean Sandbox `609a84801eeb140f129498f2b31442c122ae619d` and Extender `7442a9c931c449b460b6e50406b31e9cae12ac1c`. Fetched/reviewed official dev `9d74ae4fc70d019bb088dc26995594c71f6e2497` (3.5.0); existing upstream field APIs do not supply these additional contracts. Separate Extender checkpoint: `3aec80c2c51a4b56856c9411a9fea12d6dadb46d`. This report is included in the corresponding Sandbox checkpoint; the exact pair is recorded in the private task manifest and handoff. Evidence below binds the tested code/build directly.

## What was reproduced and fixed

At requested1200×900 (captured962×752; native UI800×600), the original editor.12/c64bb566 build at50% zoom pinned the field to the bottom, hiding lower rows under the toolbar; the wide map also extended behind the right-hand menus. Earlier tests validated only cells already visible. The native Y<=0 pan clamp ignored the space reserved by the UI, and a render reset could read stale float viewport geometry from a prior Inspect scene.

The owned viewport uses `{x=0,y=38,width=screenW-310,height=screenH-76}` in lower-left native UI units. It retains a two-unit inner border, preserves aspect ratio, centres fitting axes and clamps oversized axes to their complete reachable extent. **Fit** computes scale from the actual expanded field dimensions. Native zoom is10–200%, with arrows/middle-drag or the Pan API for fields still too large at10%. Pointer input waits for a fresh native DRAW after a WAIT-phase change. Previews use the same usable bounds and native cell projection; no Lua-only visual scale is substituted. Wheel priority, formation minus/plus and placement controls remain.

Fortified Hoburg's earlier orphan was a real native replacement gate on the unit layer, not an unexplained user actor to ignore. The native loader initially creates owner31 scenery; gate replacement removes one generation and creates a defending-side structural generation. Verified constructor call origins and lifecycle generations now identify those roles. No name, monster ID or defending-owner-only exception blesses a gate. An independently created instance of the same gate monster was tested and remained an actor.

A second blocker appeared after the first classification fix: a natively deployed Spearman shared a cell with map scenery. Restoration rejected every object collision. After the other actor moved away, native strict `battleCanStand(unit,x,y,0)` accepted that cell. The new exception is limited to constructor-proven scenery inside the verified unchanged siege context, using that native full-footprint rule. Unknown objects and actor collisions still refuse. Original neutral-field placement rules remain.

## Supported first siege

**Fortified Hoburg**: actual loaded terrain1, flags`0x1000000001`, fort parts1546, native stock template`palisaden`, siege=true, plane0, temperature25, sea/underground=false. Native selection, returned setup and the complete required context must agree; a custom template replacement refuses. The twelve choices retain the previous eleven canonical fields unchanged.

Team A attacks; Team B defends. Walls/gate are native map content, not a dummy commander or editable army. They affect blocking and combat normally. Clear removes all roster actors while native structures remain; a structure cannot satisfy an empty team's battle requirement. Saved scenarios retain terrain identity and actor configuration in existing schema4. Matching structure capability is checked before replacing the current field. Unknown/incomplete provenance or unverified cleanup keeps recovery locked rather than silently continuing.

Other forts, wall/gate variants, sea/coasts, underground and other unverified native contexts remain unavailable. Their particular templates/world/plane/siege contexts have not passed this acceptance matrix. This is not all59 native templates or campaign-equivalent world initialization.

## Exact final ordinary build and automated evidence

Windows CoE5 5.43 x64 / Steam26458448, executable SHA256`489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`. Final ordinary build **siege-final**, plugin SHA256`fb0c6f11872fae1c00b5c150692d7d5973f520d24710542ff15995a1ced7a18f`; existing src/build.sh/llvm-mingw20260922, no compiler warnings or candidate/fault flags. Initial native/visible acceptance used the same implementation with candidate policies enabled (`3efa541a6f736b2ae0258beff9ba0ba9594b61020b43659f21bc5e86a1c96eaf`); the final ordinary build was independently rerun below. Compiled-source and mod hashes are retained per session; subsequent documentation edits do not change the binary.

| Fresh final test | Evidence | Result and actual coverage |
|---|---|---|
| Viewport normal | `final-viewport` | PASS: full Fit, all four reachable corners at10/25/50/75/100/150/200%, native projection roundtrips,3×3 interior hit/context/preflight checks, unchanged actor/grid state, invalid argument and DRAW mutation refusal, verified cleanup. |
| Viewport wide | `final-viewport-wide` | PASS: same native matrix at requested1704×900/native UI1136×600. |
| Fortified Hoburg | `final-fort50`, `final-fort-32`, `final-fort-70`, `final-fort-160` | PASS:32/50/70/160 minimum widths; exact native context, structure provenance, empty/one-sided Save/Load and missing-side refusals, same-monster provenance counterexample, blocked gate placement/export,3×3 Ageless Troll deletion/reuse, customized base school/item with exact random known/memorized lists, two completed battles per size with native gate breach/damage and movement, complete bounded final capture, exact Save/Load/Reset/Rematch, Clear retaining structures, permanent cleanup. |
| Controls/configuration | `final-controls` |4 PASS:3×3 retirement/delete/reuse/rejected placement, both-team unique independence and in-place policy, cursed/implanted held-item clearing, separately installed CrabCult bonus-spell refusal without trimming spells. No third-party files distributed. |
| Naming | `final-names` |3 PASS: individual names/Unicode/limits/Move/Copy/SaveLoad/ResetRematch/battles, deletion/name isolation and exact caster preservation, legacy Sandbox-only labels. |
| Previous stock templates | `final-map-5/18/70/98/109` |5 PASS: Farm, Village, Hoburg Village, Oasis, Tent Village; their native placement, obstacle/movement, two battles, SaveLoad/ResetRematch and cleanup matrices. |

The original six neutral land contexts also passed fresh final ordinary matrices separately (`final-land-0/2/12/107/117/115`): two battles each, placement/configuration/persistence/cleanup checks. An initial combined land evidence export hit the isolated QA storage quota after Plain/Forest; its stopped run remains archived. The QA-only files were preserved outside its test data directory and the six cases were rerun individually with bounded outputs. No game/mod fix was inferred from that harness failure.

Offline **213 cases across14 Lua behavior suites**, plus syntax, PASS. Both C terrain-policy modes pass154 assertions each. git diff --check and existing launcher `-CheckOnly` pass. Offline tests include changed/missing structure quarantine on configuration success and rejection, strict unproven-structure rejection, versioned capability gating before field replacement, and structure-free army counters. These do not simulate native combat.

## What was actually observed on screen

- Original clipping at1200×900/50%; corrected Plain70-column Fit at23%, all map edges and bottom-row actor visible. Map wheel23→43; panel wheel kept zoom unchanged. Right-click placement changed A2→3; native Spearman Inspect opened at the corresponding cell.
- Fortified Hoburg's real palisade/gate and defender sprites at1200×900; Fit32% kept all map edges clear of the menus. A7/B4 excluded the gate. Right-click placement made A8/B4. A visible native battle showed gate opening, movement, spells, damage and a completed round6 Team A victory. Report counted8/4 roster actors. Back to Sandbox restored8/4 actors and the32% view.
- At1704×900 (captured1365×752/native UI1136×600), Plain70 Fit39% showed the complete field. An interior3×3 Ageless Troll click opened the proper Sandbox context; Delete removed its sprite and changed A2→1. Immediate placement reused its former footprint and changed A1→2. The replacement's context and Move control worked, moving its sprite to the chosen cell without changing counters. Menus and Back remained reachable.
- All agent launches used `--nosound --musicvol=0`. Owned test processes were closed; the normal game/profile and the user's original scenario/diagnostic profiles were not used for launches.

These visible observations apply to the candidate implementation noted above; the final ordinary build's comprehensive native tests are separate. Native API matrices cover more zoom levels than were individually observed with physical mouse input. Sustained physical right-button dragging/middle-drag and every zoom/context combination were not fully observed. Existing native log margins/visibility are unchanged in this checkpoint and are the user's next requested layout task. The final-view API remains a timed units/cells observation after aftermath and before upkeep, not a retained complete animated scene. Full opaque actor effects/poison/enchantments are not serialized. Mac/Linux and arbitrary mod combinations remain untested.

## Preserved failures and safety

Private evidence preserves initial provenance-install refusal (NEW_UNIT was already observer-wrapped), exact restoration refusal on passable scenery, a test fixture that selected a smaller Troll instead of3×3 Ageless Troll, and the deliberately refused DRAW write. None is relabelled a pass. Two early visible QA journals sampled float jitter too frequently; they were archived, bounded and rounded without changing production controls. Some automated right-clicks opened native Inspect directly; later explicit context/delete/move checks succeeded. Physical drag remains unclaimed.

Backups of the current user profiles/source and protected worktrees were taken before edits. Diagnostics remain private and bounded; current editable actor/structure observations are separate from final captures and lifecycle history. Unknown actors still fail integrity. A failed rollback is not success; keep the preserved scenario/recovery export, restart the isolated game when cleanup is unverified, then reload. No random spell changes, Git resets, private exports, game files or DLLs are included in source commits.

## Try the change

Double-click **SandboxOfElysium-Testen.bat**, choose **Sandbox**, change **Battlefield** to **Fortified Hoburg**, then choose **Open with native deployment (reposition units)** for a new scenario. Use **Fit**, select/place units for both teams and choose **Start battle**. Test Back to Sandbox, Reset and Rematch; Clear should leave only native map structures. Existing exact-position scenarios are verified rather than silently redeployed. Other unsupported maps remain unavailable.

The normal configuration/game/regular Extender hashes, both existing private terrain/cursed profiles, and all395 submitted-source/385 legacy-source files plus their Git heads/status matched the before-task inventory. All task-owned game processes were closed. Native combat-log framing remains unchanged in this checkpoint; the separately requested setup/battle-log layout follow-up is the next task.
