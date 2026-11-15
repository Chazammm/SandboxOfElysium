# Current CoE5SE API contribution review — 2026-11-15

The five source contributions and combined branch target actual official dev **df09497f04a39ff8fb7b0979dedde7dfed120c64**, CoE5SE 3.4.4/API14. It was fetched and rechecked, rather than inferred from an older ZIP. The existing dirty 3.4.0 experiment and first Ranged preparation remain unchanged.

[Complete branch plan, capability matrix, exact test bindings and English PR drafts](https://github.com/Chazammm/coe5se/tree/review/sandbox-complete-20261115/docs/sandbox-review).

| Review contribution | Base | Scope |
|---|---|---|
| [Ranged](https://github.com/Chazammm/coe5se/tree/review/sandbox-ranged-20261115) | official dev | Narrow main-menu permission for native monsterHasRanged |
| [Content origin](https://github.com/Chazammm/coe5se/tree/review/sandbox-content-origin-20261115) | official dev | Observed item/spell/school definition writers, explicit unknown coverage |
| [Field core](https://github.com/Chazammm/coe5se/tree/review/sandbox-field-core-20261115) | official dev | Owned generations/cleanup, empty editor, independent uniques, exact spells and five neutral land terrains |
| [Presentation](https://github.com/Chazammm/coe5se/tree/review/sandbox-field-presentation-20261115) | field core | Projection, full-footprint partial preview, text focus, fitted sprites, native Inspect and timed final capture |
| [Configuration](https://github.com/Chazammm/coe5se/tree/review/sandbox-field-configuration-20261115) | presentation | Twenty item positions, existing base schools, exact ordered spells and explicit cursed removal |

Stock upstream already supplies the loaded catalogs, ordinary UI/INI/legacy fields, item-slot machinery and spell primitives. Those are reused. Its monsterMod getter also exists; it is not the missing item/spell/school provenance contract and no extra Modded Units feature was added. Ordinary item/spell writes do not replace the owned transactional/lifecycle guarantees.

## Actual test evidence

Owned Windows x64 CoE5 5.43, executable SHA256 **489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55**. Builds use unchanged upstream src/build.sh with llvm-mingw20260922. Final combined DLL SHA256 **0c7d40c491a64e6891bd6e0c7f87e6ef623a7eb2c960d89a2259636a6c8d8ebb** remains private.

- Independent native branch checks: full 1879-record Ranged catalog, 721 positives, no context mismatches; provenance 4 groups; core 7; presentation 4; configuration parser 3 plus 14 production regressions. All pass on their bound branch source.
- Final combined standard session **1205b0ab8e8f4509afc951bb663a51ca**: **21/21** groups pass, including actual CrabCult combat, exact equipment/spells, empty setups, Reset/Rematch and Plain/Forest/Mountains/Swamp/Desert.
- Final explicit fixture session **c48de6acd3b341aab3082b94fbb67172**: **14/14** groups pass, including twenty positions, same-name spell identities, modded filters and native selection of a custom-school spell followed by exact restoration. Seven normal loadout groups are repeated; this is not fourteen new distinct tests.
- Final placement session **bc4298444d884d5da605b116d7f36a14**: **4/4** groups pass, including large-unit deletion/immediate reuse, repeated rejection, Forest obstacles, unique preflight and explicit exact-spell recovery after injected cleanup refusal. Rejected placement exported diagnostics. These are 39 combined group executions, including repeats, rather than 39 distinct cases.
- All 127 existing offline Lua contracts, distributed Lua syntax, project Python/PowerShell parsing, 21 current C terrain-parser cases and 51 policy assertions pass. The English BAT passes -CheckOnly and a copied missing-helper error test. These checks do not constitute another full game launch through the translated BAT.

The scan covers 60 current function/member names, 38 getter keys, four setter keys and five observation/wrapper sites, including UI aliases, diagnostic wrappers, dynamic spell lists/team colors and guarded fallbacks. Exact locations and behavioral equivalence are in the separate CSV/matrix.

## Visible editor observations

On the earlier combined DLL **e2996d24…**, actual production UI showed the grouped menu, Forest, Clear to A0/B0, unchanged empty-team refusal, live Druid search/place, Druidism base1→2, explicit Learn/Mem, CrabCult Abyss Fragment equip and Select-again deselection. A1/B2 included Druid's Apprentice and CrabCult's actual Abyssal Shellback #2004. The own q4 scenario saved and visibly loaded. The private QA school was explicitly enabled; it is not CrabCult content.

Two real Forest battles finished Team B/round6. Post-view showed one Shellback survivor; genuine native Inspect showed the correct sprite, 62/70 HP and one kill. Rematch, Back to Sandbox, Reset and diagnostic export worked. The final diagnostic has three model/native actors and no native issues. A clipped off-screen window initially caused incorrect injected dialog clicks; moving the full window onscreen resolved Load. No product change was inferred from that automation issue.

The complete mouse workflow was not repeated after the final lazy-startup change. That final revision was rebuilt and reverified with the native production suites above. Multi-cell/independent-unique/rollback edge cases have native evidence, not a new complete mouse acceptance. Initial requested size1200×900 produced a full 962×752 window and800×600 internal coordinates at this workstation's scaling. Raw diagnostics and the own saved QA scenario remain private.

## Corrections, limitations and preservation

The port preserves current upstream observers/content-write tracking and generated hook entries. Upkeep capture uses the existing wrapper chain. Mac keeps the exact legacy test-field implementation and explicitly refuses new editor options, with new bindings/text/fitted helpers guarded. New lifecycle hooks install only on an explicit field-open request; a capability query does not install hooks or prove they work. Configuration parsing uses raw caller data and pins actor generation/session. An initial lazy-capability reporting failure was caught and corrected before publication; failed runs remain archived.

No Mac build/runtime is claimed: the required Zig0.16 compiler/runnable Mac game is unavailable. Host preprocessing and exact legacy-blob comparison are structural checks only. Full native injury/HP/affliction serialization, table compaction/exhaustion, complete render scenes, arbitrary mods/campaigns/multiplayer and all camera/drag cases remain unaccepted. Current Sandbox uses plain setup tables; reentrant legacy setup-table callbacks are outside this test coverage. Crystal Heart removal preserves live permanent injuries, but reconstruction does not serialize the complete injury state.

Preservation confirms all385 original experimental source files/status/diffs/index, first preparation changes, all88 original Sandbox profile files and the normal configuration/game/installed-Extender control hashes unchanged. Product Lua is byte-identical. Current Sandbox changes are English documentation/consolidations, launcher strings, the mod description and English working conventions. Full historical reports remain at their pinned Git commit; no history was rewritten.

Branches are unsigned review material. Personal acceptance of CONTRIBUTING.md terms/sign-off is still outstanding. Signing off confirms the right to contribute and grants the maintainer/successors a permanent, worldwide, irrevocable, royalty-free license to use/change/sublicense/distribute the contribution, with public permanent sign-off history; copyright is retained. No sign-off was invented from configured Git identity. No PR, upstream push, merge, contact, binary release or bundled Extender was performed.

The ordinary **SandboxOfElysium-Testen.bat** still uses the existing separate local experiment and isolated terrain profile. It does not automatically switch to these review branches. See [English installation and test instructions](../INSTALLATION.md).
