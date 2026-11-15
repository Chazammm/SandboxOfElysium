# Battlefield configuration window and modded content — editor.7

This English consolidation retains the historical scope and key findings. [The complete original report at the preserved source commit](https://github.com/Chazammm/SandboxOfElysium/blob/b67e8a344b942df1d65d7ce23939891bd74c9f59/docs/TEST-PANEL-2026-11-15.md) remains in Git history; no history was rewritten. Its tests are not automatically tests of the current build.

## Interface and native fixes

Units/Items share the right catalog with live search, slot/source filters and fitted native icons. Right-click equip uses actual anatomy and explicit occupied-slot confirmation. The per-instance draggable/resizable/clamped window offers Items / Magic Schools & Spells / Name. Native Inspect remains genuinely native and read-only. Name is a separate Sandbox label (48 Unicode characters, no controls), not a native template/instance rename.

Existing-school base levels may rise or fall within 1–3. Unlock learns eligible spells up to base/effective constraints without memorizing. Mem is explicit. Lowering refuses unchanged if selected spells would become invalid, retains higher known spells and preserves random originals. Investigation fixed the aggregate native effective-level reader and added explicit restoreKnown for reconstructing previously learned higher spells on a lowered actor. Failed rollback quarantines the editor.

Observed C5M definition writers drive Modded Items / Modded schools; native schools with observed mod spells are included. Unknown remains separate; IDs never imply origin. Metadata provenance is not a complete history or proof about image/description-only changes.

## Bound evidence

Accepted local DLL `b0b75e0b69c7c6d16a7c6f4d1c92b7c4452189d347f2a4728120e00d6ea681ec`, final mod source `043bf667c5015597591fcf1dc98d59c7d6921415f6133e2c5414345e0f4ea955`, CoE5 Windows5.43, experimental3.4.0 base d96f2b7.

- `423d0cdf8c5f4c1bae1a81564b949126`: six panel plus eight loadout/fixture groups PASS. The custom path70's actual native spell-selection return was observed in a natural fight, followed by exact reset. This is not a full spell-effect/damage trace.
- `51871744ff7f436cb6cd33dded8cfd04`: all21 standard native groups PASS without the private content fixture.
- Visible `ca5978b2fd9c4115a609879e2d2283f4`: item search/equip/refusal/diagnostic, replacement Cancel/Confirm, native item card/removal, window movement/resize, school accordions/levels/Unlock/Mem, modded duplicate-ID spells, explicit unsafe-downgrade refusal and per-instance Unicode label. Saved own p7a.
- Visible larger `9cb6d51f5fba4c11932d7b87a789aea6`: loaded own save, twenty slots/Abyss Fragment, native item card, curse guard and moved window.
- Normal BAT `dbcc4aa5ef574611a7ccc50e8e411eeb`: three standard mods only, ordinary Sandbox/field/catalog/navigation/Quit, no automatic fights or fixture.

Requested windows were1200×900 and1704×900; captures were962×752 and1365×752 at the then-current scaling. These are not claims about an unmeasured internal resolution. 127 offline contracts passed: model20/editor10/integrity13/interface18/preview15/caster9/battlefield13/loadout16/panel13.

## Later Select toggle and limits

Clicking the same Select again clears a unit or item selection and its active modes. No selected unit means no preview/placement; existing-unit context remains. The initial toggle follow-up had46 focused offline checks but was not then visibly exercised in the already-running old session. editor.8 later visibly verified both toggles; see the cursed report.

Early aggregate-level/restoreKnown failures and an incomplete private Boolean-export run were retained and corrected before acceptance. Not every filter/page/glyph, sustained drag/zoom, Copy/Move/Reset/Rematch mouse workflow, opaque native property, arbitrary mod, new implant/school, campaign/multiplayer or complete final scene was accepted. Preservation checked83 existing profile files (only generated launcher context changed) and all three regular-install controls.


## Recorded identifiers

Reference identifiers retained from the original report, including baseline, failed, intermediate and accepted runs. This list alone does not identify a successful run; use the bound evidence above or the original report.

- `11c572a4d441a1e283d14bedb0d1d5540c7ccb45`
- `d96f2b784e97e115022a2598da2c821dd9520135`
- `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`
- `b0b75e0b69c7c6d16a7c6f4d1c92b7c4452189d347f2a4728120e00d6ea681ec`
- `043bf667c5015597591fcf1dc98d59c7d6921415f6133e2c5414345e0f4ea955`
- `29cccc380d00435da078ddcc71fbdc4d`
- `4f0bb1e8992cd5763706a5767542d009ee0bb1e876ea774728090b04ff0a9da9`
- `ca5978b2fd9c4115a609879e2d2283f4`
- `423d0cdf8c5f4c1bae1a81564b949126`
- `51871744ff7f436cb6cd33dded8cfd04`
- `9cb6d51f5fba4c11932d7b87a789aea6`
- `dbcc4aa5ef574611a7ccc50e8e411eeb`
