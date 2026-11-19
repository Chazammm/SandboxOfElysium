# Compatibility

| Pairing | Status |
| --- | --- |
| CoE5 5.43 x64 on Windows with the local non-naval reference build | Full candidate test pairing. See the [test report](TEST-RELEASE-CANDIDATE-2026-11-19.md) for the exact inputs and coverage. |
| CoE5 5.43 x64 on Windows with the separately built upstream review stack | Current candidate pairing. See the [combined-build report](TEST-COMBINED-PRESENTATION-2026-11-19.md) for source revisions and verification. The version number alone does not identify this build. |
| Official CoE5SE 3.6.0, dev `b9cd9453912d92474c41eb51240683039292dd0a` | Includes the merged first test-field contribution. The full editor remains unavailable because the candidate depends on additional safety and feature APIs. |
| Earlier CoE5SE, Mac, Linux, other game executables, multiplayer | No full-candidate acceptance. Use the tested Windows pairing for local review. |

The first merged contribution implements the owned test-field lifecycle and basic terrain, placement and inspection, equipment and spells, loaded content origin and the main-menu ranged query. The active local candidate additionally uses these API groups.

| Group | What Sandbox uses it for |
| --- | --- |
| Permanent retirement and identity | Remove units and failed placements without leaving regenerating actors. Verify native closure before rebuilding. |
| Owned contexts and width | Track native map context and structure provenance in sieges. Apply width floors. Support independent water actors and report drowning risk. |
| Exact placement and initial deployment | Reapply saved targets with checks on the full roster and footprints. Use an authenticated one-use receipt if the first native deployment temporarily overlaps. |
| Configuration and names | Restore supported individual names, bounded health/XP/kills/injury state, starting equipment policy and ordered spells. |
| Native unit type View | Make a verified temporary preview for the real game card. Random spells in a preview are examples. Starting items are omitted. |
| Presentation | Native zoom, Fit/pan/centering, preview feedback and native combat-log visibility. |

The upstream review stack covers these groups in separate Extender commits. The viewport and unit-type View use the verified native ABI with Clang 23 on Windows. The local reference and upstream review stack have separate evidence. See the [API dependency map](COE5SE-API-DEPENDENCIES-2026-11-19.md).

Save schema 4 records exact positions and supported configuration. Older schemas can be loaded, with missing fields represented by native defaults and migration to a new copy. Required loaded content is checked. Incompatible or missing items, spells, mods or API contracts can prevent reconstruction. A fresh unit with a different permanent implant may refuse exact restore. The editor does not reroll a saved loadout or spell selection to make it fit.

Post-battle snapshots show supported native actors and cells rather than the complete rendered scene. Combat reports have limited damage and spell attribution. Arbitrary mod combinations, native effects beyond the supported saved fields, custom battlefield replacements, additional map contexts and naval battles remain outside this candidate's verified scope.
