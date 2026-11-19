# Battlefield object audit

This follow-up is based on the non-naval 0.2.0-rc.1 review candidate at `0f4d0d1`. The earlier archive and its test report describe the earlier source pairing.

## Native roles on Windows CoE5 5.43

| Native creation and layer | Observed examples | Ownership and behavior |
| --- | --- | --- |
| Map loader or terrain scatter, object layer | Bush, tree, boulder, stone wall, stone parapet, wooden stairs and coastal house | Native owner 31. These are neutral scenery and stay outside both army counts. Native objects can block cells or provide cover or passability. |
| Native gate replacement, unit layer | Guard Tower Wooden Gate and Castle Iron Gate | Native defender owner 24. Gates take part in the native siege and keep their side, footprint and damage behavior. They are fixed map structures outside the editable rosters. |
| Owned army creation, unit layer | Player-placed Bronze Wall, Wooden Gate, Bush, Cabbage, Stone Stairs and Wooden Stairs, tested for both sides | Original side 0 or 24. These are roster actors even when a map creates neutral scenery or a fixed structure from the same template. Copy and removal work under the regular actor rules. Whether a type can move or attack during combat is determined by CoE5. |

Classification uses the verified native constructor route and generation. The object's appearance, template name and team color are insufficient to establish that role. No native neutral placement API was verified for arbitrary unit-browser templates. The Cabbage result above concerns the player-placed actor. The audited layouts did not establish a map-generated Cabbage case.

Clear the selected unit and hover a map feature to see its role. The final field uses the captured role, including the native side for siege structures. Its Sandbox overlay applies team color only to army actors. Roster counts and battle-start requirements use the armies, while the winner continues to come from the game. A gate on its own cannot fill a missing team. Fixed features regenerate through the native map context when a saved setup is reopened. The scenario retains player-placed actors and their exact saved positions. Reset and Rematch reconstruct the pre-battle map, so combat damage to a gate is not a saved map edit.

## Bugs fixed

- **Final snapshot classified gates as scenery.** The upstream-based port previously reduced all non-roster actors to scenery during final export. CoE5SE now exports the captured creation source and structure kind with the existing native owner. The change extends the snapshot and leaves simulation and native ownership with the game.
- **Post-battle overlay used side colors on all owned rows.** The Sandbox now uses the army layer for team tint and labels verified scenery or structures separately.
- **A recycled native handle could distort the roster report.** The report now pins the setup's generation. It uses the original actor's verified final row or return-time record and separates unverified outcomes from losses. A synthetic recycled-handle regression verifies this case. No handle reuse was required for the native test scenarios.
- **Rejected initial overlap repair could still show a complete snapshot.** The upstream-based restoration port now keeps the raw diagnostic rows and marks the field incomplete while it is quarantined. The 11-case native receipt regression passed after this correction.
- **Clear All Held Items was unavailable on the upstream-based pairing.** The API exposed ordinary equipment editing and single cursed-item removal. The port now accepts an explicit per-actor clear operation, including cursed and implanted items. It preserves known and memorized spells and existing injury state. When equipment removal invalidates a memorized spell, it verifies rollback for that actor.

## Verification

The neutral audit used the Sandbox runtime fingerprint `5cb1d3a42a41dd973883766fe2490a428b48a0b88524331ab593406a5ae1cb70` with the upstream-based Extender commit `5ed7949e222050573d12085217ce7ae04eaffbf0`, plugin SHA-256 `5cbb9765d2df39251754e66d67246c64de94c977b53a522022b3b1286dfb620f`. CoE5 5.43 Windows x64 ran in a separate muted copy and profile. The Extender also cross-compiled for Apple Silicon. Mac runtime is unverified.

- **Offline.** 401 behavior checks across 30 behavior suites, plus one Lua syntax suite. The new checks distinguish two instances of the same template, protect session-specific scenery and gate identity, and verify uncertain roster reporting.
- **Native engine.** Compared native actors and object-layer records on Plain, Forest, Guard Tower, Castle and Coastal Hamlet. Placed and removed six structure-like or plant-like templates for each side. The independent CoE5SE fixture verified that a native gate does not satisfy the defender roster requirement and that the same-template player actor remains classified separately after battle.
- **Sandbox in the real engine.** Plain (6+6) and Castle (4+4) passed same-color team identity, placement, gate refusal, Copy/Delete, Save/Load, two native fights each, report totals, Back to Sandbox and Rematch. Original unmodified inputs for the 61-unit Guard Tower setup were copied. The copy passed exact reconstruction, three native battles, position and supported state readback, invalid-target refusal, Reset and Rematch. Sea and Coastal Hamlet passed independent-unit reconstruction and cleanup.
- **Visible.** The Sandbox menu opened. In the live Castle editor at a requested 1200×900, the team counters showed 1 and 2 with both teams the same color. Searching for Spearman and deselecting it exposed the Stone Wall's “Neutral battlefield scenery” tooltip. The Spearman still showed “Team A.” Back returned to the main menu. The gate tooltip and final-field rendering were checked through Lua and native readback only. This session exposed a missing log capability flag.
- **Follow-on integration.** Extender `955f7afbadf47b50dc42270fa8fadddf9b271fd8`, Windows plugin SHA-256 `68e1e9e7013e1f3faba87472e366f9f886b987005ba559b748fedc55e6ccd043`, includes the log flag, live unique policy and bulk equipment clearing. The same copied Guard Tower recovery passed again through three native battles. The unique-policy checks passed duplicate refusal, removal and identity preservation. The equipment checks passed both-team clearing and rejected an item-only change that would invalidate a spell. The log test checked visibility, continued message generation and restoration on close.
- **Known limits of the port.** The fixed-scale placement preview passed for both sides on Guard Tower, Forest scenery, large formations, Sea, Deep Sea and Coastal Hamlet. The full zoom/pan preview probe requires APIs still present only in the older reference build. Automated geometry and native placement in the audit are separate from visual acceptance. Genuine unit-type View, fit/zoom controls and the complete rendered final scene remain outside this port's acceptance.

See [the API dependency map](COE5SE-API-DEPENDENCIES-2026-11-19.md) for review order and remaining release blockers.

## Manual check on the integrated build

1. Open Castle in the isolated profile and set both teams to the same color. With no unit selected, hover a stone wall, wooden stairs and the native gate. The scenery tooltip names the feature as neutral. The gate identifies its defender side. The counters use the two army rosters.
2. Place a Bronze Wall or Cabbage from the browser, then hover it. It should show its selected team and count toward that team. Copy it, delete the copy and try placing beside the native gate.
3. Save a copy, start a battle and use Back to Sandbox and Rematch. The selected teams, player-placed wall or plant and the native gate should return in their original roles. Repeat with a copy of the Guard Tower recovery if available.
