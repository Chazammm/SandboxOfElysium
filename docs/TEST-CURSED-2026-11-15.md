# Explicit cursed-item removal — editor.8

This English consolidation retains the historical scope and key findings. [The complete original report at the preserved source commit](https://github.com/Chazammm/SandboxOfElysium/blob/b67e8a344b942df1d65d7ce23939891bd74c9f59/docs/TEST-CURSED-2026-11-15.md) remains in Git history; no history was rewritten. Its tests are not automatically tests of the current build.

## Actual diagnostic and cause

The bounded `diagnostics-5b0a36e7cc244d528769-1.ini` has64 recent actions. Action061/sequence151 records equipment_change refused `cursed_item`, validate stage, model5/native8, Arcane Frost Dragon1830, rollback_verified=true. The six-model/native snapshot reports no integrity issues. This is verified unchanged refusal, not successful removal.

The saved target is Crystal Heart185 at zero-based position6 (UI #7 Misc), 3×3 at6,6, Frost Magic27/base2. Exact known order:91:Icicle,88:Freeze,98:Winter Ward,96:Hail Storm. Memorized:98:Winter Ward,96:Hail Storm,88:Freeze. The bounded ring cannot establish the earlier equip sequence or Remove versus Replace. Other dragons/items are not evidence of that action.

The transaction protected all cursed items. Crystal Heart is also a permanent heart implant: simply bypassing the curse guard would ignore native organ-injury effects. The scoped override binds native actor/generation, expected position and item, allows only explicit single-item removal, verifies the full supported state and organ mask, and never changes the shared item's curse definition. Cancel and ordinary cursed replacement retain their guards; new implants remain unsupported.

## Native evidence

Session `f60fa3de8376498e9ae773fe27aece72` passed both new groups plus14 existing groups (7loadout/5empty/2filter-mod). A fresh independent `eb4a1ca2371f48d3994b5ef87eeeb81f` repeated the new groups. The private fixture reproduces the diagnostic's supported target configuration with its own QA teammates; it is not the user's whole six-actor scenario or proof about unknown earlier actions.

Explicit removal succeeded with the same living native actor/generation, all other slots, base schools, ordered known/memorized spells and other Druid unchanged. Wrong expected ID, an extra simultaneous change, stale repeat and ordinary no-override requests refused with verified prior state. File reconstruction retained the supported configuration without reintroducing random cursed start items.

CrabCult Shell Priest2009 with Abyss Fragment300 has Hydro base1/bonus1/effective2. Removing its bonus while level2 spell428 is memorized refuses `spell_level` unchanged. After explicit deselection, removal succeeds at base1/bonus0/effective1, higher known spell retained, then Save/Load succeeds.

## Visible evidence

In fresh eb4a session, a private button opened the real production editor. Interior-cell context on the large dragon opened Edit showing #7 Crystal Heart[cursed], A2/B1. Remove displayed the permanent-injury warning; Cancel retained the item. Confirmed Remove cursed item emptied the position and reported exact native verification, with sprite/counts intact. An actual diagnostic export confirmed three model/native entries, no issues and empty native/saved position6. Strange Seraph Select and Abyss Fragment Select were each clicked twice to verify deselection without mutation. Captures were962×751; internal coordinates800×600. Save/Load and complete spell comparisons were native tests, not another complete mouse replay.

## Critical limitation and preserved failures

Live removal **does not heal permanent injuries**: the measured partial organ mask stayed4194304→4194304. Scenario serialization does not include full native injuries/HP/opaque attributes; the freshly rebuilt dragon had mask0. Exact supported items/base schools/spells is not full injury restoration. A live removal and later reconstruction are distinct operations.

All127 offline cases and distributed Lua syntax passed. Earlier failed/partial fixture attempts (wrong slot/random start items/implant reconstruction), private probe errors and a failed compile were retained, not relabelled. Both final sessions are authoritative. All88 original Sandbox profile files and three regular installation/profile controls remained unchanged. No DLL/EXE is in the mod. The requested bundled Extender release was withdrawn; binaries stay separate.

## Retest

Close the old test process, launch the BAT, open Sandbox with explicit native deployment, right-click an equipped actor → Edit → Items → Remove → Remove cursed item. Cancel should keep it. Explicitly deselect spells before removing a required bonus. Put an actor on each team before battle; use Save/Load/Reset/Rematch with the injury-serialization limitation above.


## Recorded identifiers

Reference identifiers retained from the original report, including baseline, failed, intermediate and accepted runs. This list alone does not identify a successful run; use the bound evidence above or the original report.

- `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`
- `d96f2b784e97e115022a2598da2c821dd9520135`
- `ba4d614289d0eff8dcac5ada2b58521290de8251c18e50dc630a6e02de6a2c5a`
- `3c2f2d2a16f735b09e596499fad297b80726229624c8e668314c88eed84328d3`
- `f60fa3de8376498e9ae773fe27aece72`
- `eb4a1ca2371f48d3994b5ef87eeeb81f`
