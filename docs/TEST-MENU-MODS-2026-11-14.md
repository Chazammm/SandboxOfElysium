# Grouped battlefield menu and active mod units — 2026-11-14

This English consolidation retains the historical scope and key findings. [The complete original report at the preserved source commit](https://github.com/Chazammm/SandboxOfElysium/blob/b67e8a344b942df1d65d7ce23939891bd74c9f59/docs/TEST-MENU-MODS-2026-11-14.md) remains in Git history; no history was rewritten. Its tests are not automatically tests of the current build.

## Menu organization

The existing setup screen separates Current setup (terrain/colors/counts/unique mode), Battlefield (exact/native deployment), Scenarios (Load/Save and applicable reset), Tools (diagnostics/terrain browser/native check/API limits), and a separate Main menu row. Common opening actions remain prominent; saved scenarios and recovery paths are retained.

## Verified active content

The catalog enumerates the loaded monster database after active mods load. Names, sprites and data are read from the actual records, not assigned a mod origin from numeric IDs. The installed CrabCult C5M explicitly defines Shorebound Initiate and Abyssal Shellback. Both were found, placed and used in native combat/reset. A visible current-build Shellback search/placement/native card/battle/snapshot was also completed. The native card showed its sprite and 70/70 starting HP.

A saved scenario's active-mod requirements are checked. Omitting CrabCult from the production decoder's supplied active set refuses Load and names the missing mod; this test does not claim an additional physical deactivate/restart UI run. Same-ID/same-name content changes are not fully detectable. Third-party files remain private and separately installed.

## Ranged and visual evidence

The old main-menu restriction incorrectly made Ranged empty. The separate minimal fix permits only the template-based native monsterHasRanged operation there. Native semantics include spell attacks and rank rules. With CrabCult active, 721 of 1879 catalog entries were ranged; missing classification is explicitly unknown. Other filters use loaded human/animal/undead/demonic/flying properties.

Fresh public images show the grouped menu at requested 1200×900, 721 ranged results and the actual native mod card. Those images do not repeat earlier fights. Unreliably named older image files were excluded. See [public evidence](public-evidence/README.md). Historical final normal-build regression and actual ten-unit setup battles passed; this is not proof for a later DLL without rerunning it.


## Recorded identifiers

Reference identifiers retained from the original report, including baseline, failed, intermediate and accepted runs. This list alone does not identify a successful run; use the bound evidence above or the original report.

- `63b293fb0a694cf6a528cbf66d9aa2e561c80b38337f1fb7e40b154ba64a8bdd`
- `409c10230c2853cd68a2227c2a345d5a001e30637cd720f66240cd2465c796ed`
- `272fcca5bf2aeab186eff74cf405c8888493ea1fb4b984ca92c0799c5ab1a6c3`
- `4904be0f2c659075e8449f32cd3024f5429b9a24ea2aaef1b9207685bb1ba5a1`
- `6f2f739f6e4743e6b2538ce851cd76ac`
- `54f26dddea5a440db8ffd327e9351cee`
