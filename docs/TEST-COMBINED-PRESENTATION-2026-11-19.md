# Combined Windows presentation and release-candidate checks

The current non-naval candidate ran against an upstream-based CoE5SE 3.6.0 build. The official `dev` base was checked at `b9cd9453912d92474c41eb51240683039292dd0a`. There were no open upstream pull requests at the check. The stock release still lacks the additional APIs. This report covers the new Windows pairing. The [3.4.4-era reference evidence](TEST-RELEASE-CANDIDATE-2026-11-19.md) remains separate.

| Component | Tested identification |
| --- | --- |
| Game | CoE5 5.43, Windows x64, separate game copy and profile, muted with `--nosound --musicvol=0`. |
| Sandbox | Runtime tree SHA-256 `b0ab1a1c2d098e218700d4f5f45646426c09d97a065c339df90bdbe3b04d16b6`. |
| CoE5SE | `review/owned-field-presentation-20261119` at `a372833f6c23b1d273e86291d0ede2a252a082fb`. Windows plugin SHA-256 `667e8f8db7cb5d9b28d3d79e2016527710bc084f0ba4b27f185823b6c2b6ed3f`. Built with Clang 23. |

## Native View and presentation

- **Native type card.** The existing native stats screen receives a verified fresh off-field instance of the selected loaded type. The constructor's allocator redirection and unique lookup scope end before the modal opens. Cleanup retires that instance then verifies the unit high-water mark, slot, native battlefield data, existing actors, unique availability, RNG and projection. A failed verification quarantines the field.
- **Viewport.** Wheel readback uses the game's frame-latched counter. The Sandbox handles priority for menus, configuration, and the map. Mutate the owned viewport after native WAIT and allow a fresh DRAW before using a changed projection for input. The rectangle uses native UI coordinates with a two-unit inner margin. Zoom is uniform from 10% to 200%. Fit uses the actual field width. Pan exposes the edges when the minimum zoom cannot fit the whole field.
- **Combat center.** One-shot, on the first verified native combat draw at the game's scale. This changes the camera only. Subsequent native panning remains available. The API reports queued, applied or unobserved state separately.
- **Sprites.** The Sandbox reuses upstream's fitted `drawMonsterSprite` and `drawItemSprite` functions. Older reference builds can still use their original function names.

## Verification

- **Offline.** 31 Lua suites passed with 401 behavior checks plus syntax. The browser routing test uses the older icon name at one test width and verifies that the official sprite function takes priority at the other.
- **Automated in the game.** All 16 runs of the final combined native matrix passed. The standalone Extender viewport fixture and Sandbox viewport probe checked actual native Fit and panning. The viewport probe requested 1200×900 and 1600×900, with native UI sizes 800×600 and 1066×600. It checked 28 corner round trips and every cell of a 3×3 actor at seven zoom levels in each run. The context-menu checks used that native projection with scripted pointer positions.
- **Placement and combat.** The full placement-preview suite covered both Guard Tower sides, Forest scenery, Plain Move/Copy/Clear, formations, large units and three independent-actor water maps. Native camera probes centered the first combat frame on Plain at width 160, Castle at 71, Sea at 90 and Plain expanded from 32 to 122. Each showed zero midpoint error in native UI coordinates. All 21 supported terrain contexts passed their load and cleanup checks.
- **Persistence and identity.** A copy of the 61-unit Guard Tower recovery completed three 112-round native battles with Save/Load, Back to Sandbox, Reset and Rematch. All 61 positions and the supported names, equipment, conditions and magic matched. The player-placed Bronze Wall retained its army role. A rejected target kept recovery and restored the previous verified state. Same-color Plain and Castle teams retained their native identities. Scenery, fixed structures and roster actors retained distinct roles. The configuration, live unique, item-clearing and modded Shorebound Initiate probes passed.
- **Additional native regressions.** The six-case panel suite passed fitted item art, capacity and spell editing, known-spell preservation, modded item and school filters, and native use of configured mod-school spells. The log fixture verified that new native messages continue while hidden and that close restores the previous overlay visibility.
- **Native modal with visible close.** The first upstream-based port displayed Spearman, Pyromancer, God, three views of an already deployed Arch Devil, and CrabCult's Abyssal Shellback. I observed the spell sections and scrolled the long Arch Devil card to its native Exit button. The probe checked the existing name, held item, edited spell, roster, allocator and unique state, then successfully deleted and placed the unique type again. The final DLL repeated Spearman View with an active fitted, zoomed and panned viewport. Its readback was identical after Exit. The same run passed Save/Load and two native battles with Reset and Rematch.
- **Visible final editor.** On the requested 1200×900 Castle session, I saw fitted browser sprites, same-color army counts of 1 and 2, and the Iron Gate's defender-structure tooltip. Clicking Fit showed the whole 70-column field inside the editor at 23%, above the bottom controls and beside the browser. The window controller became busy after Fit. The map-wheel and panel-priority checks were covered by native counter and offline routing tests. A physical wheel pass across both editor regions remained unverified in this session.

## Limits and release gate

Starting items are omitted from temporary type View. Randomized preview spells can differ from a subsequently placed actor. View and native viewport controls were verified on the Windows 5.43 x64 build with Clang 23. The integration cross-compiled for Apple Silicon. Mac runtime, Linux, other game builds, network play, arbitrary mod combinations and a visual pass across all 21 maps remain unverified. Final snapshots cover supported actors and cells. Full native scene serialization is unavailable. Ships and passengers remain postponed.

The local Windows pairing satisfies the tested non-naval release workflows. Public release still depends on the required changes landing in an official CoE5SE build and repeating the combined tests against that build. See the [API dependencies and review order](COE5SE-API-DEPENDENCIES-2026-11-19.md).

For a quick visual review, open Castle at minimum width 70. Use Fit, wheel over the map, pan to its lower and right edges, and use View on Spearman. Close the card and check the camera and both team counts. Scroll over a unit or item panel to check that it takes priority. Then start a battle and use Back to Sandbox, Reset and Rematch.
