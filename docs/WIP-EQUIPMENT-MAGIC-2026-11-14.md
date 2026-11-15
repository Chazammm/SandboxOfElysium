# Equipment and magic investigation — historical work notes

This English consolidation retains the historical scope and key findings. [The complete original report at the preserved source commit](https://github.com/Chazammm/SandboxOfElysium/blob/b67e8a344b942df1d65d7ce23939891bd74c9f59/docs/WIP-EQUIPMENT-MAGIC-2026-11-14.md) remains in Git history; no history was rewritten. Its tests are not automatically tests of the current build.

This investigation was completed locally as editor.6 on2026-11-15. See [the bound loadout report](TEST-LOADOUT-2026-11-15.md) for acceptance; early open questions are historical, not a current feature list.

Source findings: upstream3.4.0 already has twenty anatomical positions, per-unit slot types and native implant checks. Eight name-only slots cannot represent that contract. Native base-school levels come from monster attack rows, while bonuses are separate. A safe per-instance implementation must serve base/effective readers and actual combat attack selection, scoped to field/session/generation/monster. New eye/heart effects change permanent injury flags and cannot be treated as ordinary reversible equipment.

The implemented direction became identity-based schema2 equipment/schools and an atomic native transaction with exact lists/readback/rollback. The first vertical evidence was not full acceptance: Druid's Apprentice received Amulet of Anti Magic153 at position7, Druidism39/base2, learned/memorized Briar Cage350, while original spells remained. Native unit/item cards showed the effects. Subsequent broader acceptance and unsupported cases belong to the completed loadout and later panel/cursed reports. Original sources, scenarios and dirty Extender work were preserved.
