# Equipment, existing base schools and exact spells — editor.6

This English consolidation retains the historical scope and key findings. [The complete original report at the preserved source commit](https://github.com/Chazammm/SandboxOfElysium/blob/b67e8a344b942df1d65d7ce23939891bd74c9f59/docs/TEST-LOADOUT-2026-11-15.md) remains in Git history; no history was rewritten. Its tests are not automatically tests of the current build.

## Implementation

Upstream already supplies an anatomical item system with up to twenty positions; the old Sandbox stored only eight name-based positions. Schema 2 records position/item ID/name and school ID/name/base, retains schema 1 and rejects ambiguous legacy names. Native slot compatibility and exact readback are required. At this historical editor.6 stage cursed replacement/removal was protected; editor.8 adds explicit removal separately.

Base magic levels come from monster spell-attack rows. Writing the template would change other actors. The separate Extender keeps field/session/generation-bound existing-school overrides, consumed by both native level readers and combat attack selection. Bonuses stay separate. Supported base levels are 1–3; no arbitrary new school or higher-level editing. Exact ordered known/memorized lists are validated and restored without rerolling random originals. New implants remain protected.

## Build and actual tests

Owned Windows CoE5 5.43, executable `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`; local Extender base d96f2b7 with preserved changes. Accepted DLL `51dccf74e1b49f9b143775329f8631c460a7835e4ca9fe4ddc2303c47d632352`.

- Native normal run `00f81e03ba304c709f700a9630f10515`: 21/21 groups PASS (7 loadout, 5 empty, 4 placement, 3 inspector/caster/repair, 2 filter/mod).
- Explicit own twenty-slot/custom-school/duplicate-spell fixture run `55fedd95178a4687bd0d9ffa3f2d6cd6`: 8/8 PASS, including seven repeated normal loadout groups. There are 22 distinct groups across these runs.
- Visible run `56f46d71090f49a9a46cac6c5936d352`: own saved QA setup, A2/B1, two occupied misc positions, explicit removal Cancel preserving both, native Druidism2/MR11/3-of-3 card. The fixture's original spells differ from an earlier session; they were not silently substituted within a saved scenario.

Earlier visible vertical test equipped Amulet of Anti Magic #153, raised Druidism39 to base2 and explicitly learned/memorized Briar Cage350 while retaining its starting Befriend Animal344/Vine Arrow347. Native unit/item cards reflected the change. Subsequent normal final BAT start `f9bf2eefcb264286a8b115abc9614231` verified profile redirection after two hint-only source edits; the entire combat matrix was not rerun after those text edits.

## Regressions and limits

Malformed requests, incompatible positions, occupied-slot confirmation, exact rollback, independent unique multischool actors, Copy/Move/Save/Load/natural fight/Reset/Rematch and CrabCult item behavior were tested natively. 114 offline cases passed at this stage. Unverified rollback quarantines editing and preserves recovery.

No full native injury/HP/opaque-state serialization, arbitrary new implants/schools, all other mods, Mac or full mouse workflow on the final hint-only revision is claimed. Detailed earlier candidate failures remain in Git history and private archives, not counted as successes.


## Recorded identifiers

Reference identifiers retained from the original report, including baseline, failed, intermediate and accepted runs. This list alone does not identify a successful run; use the bound evidence above or the original report.

- `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`
- `51dccf74e1b49f9b143775329f8631c460a7835e4ca9fe4ddc2303c47d632352`
- `1617cb61ae0669126bd0af35f6e829bd25c30e2190c2c07119c10d999272e114`
- `61532bd01bcd68721864c0e83a23e7d1efec504b247c3f40b74317b9cafa901e`
- `f9bf2eefcb264286a8b115abc9614231`
- `00f81e03ba304c709f700a9630f10515`
- `55fedd95178a4687bd0d9ffa3f2d6cd6`
- `56f46d71090f49a9a46cac6c5936d352`
