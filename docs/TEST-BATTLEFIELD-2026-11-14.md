# Final snapshot, empty editor and land terrains — editor.5

This English consolidation retains the historical scope and key findings. [The complete original report at the preserved source commit](https://github.com/Chazammm/SandboxOfElysium/blob/b67e8a344b942df1d65d7ce23939891bd74c9f59/docs/TEST-BATTLEFIELD-2026-11-14.md) remains in Git history; no history was rewritten. Its tests are not automatically tests of the current build.

## Historical accepted build

The final ordinary build without terrain candidate flags used DLL `63b293fb0a694cf6a528cbf66d9aa2e561c80b38337f1fb7e40b154ba64a8bdd`, session `54f26dddea5a440db8ffd327e9351cee`, Sandbox source `409c10230c2853cd68a2227c2a345d5a001e30637cd720f66240cd2465c796ed`. Earlier candidate DLLs/runs are distinct; their incomplete large battles are not accepted as passes.

The empty final grid with living survivors was reproduced. Capture now occurs after aftermath and before native upkeep/cleanup. The read-only view separates snapshot state from current native Inspect and original editor data. It does not retain effects/projectiles/animations or claim a complete native scene.

## Empty editor and deployment

The new explicit emptyEditor mode creates no commander/dummy. Both teams can be empty, the last actor on either team can be deleted and Clear removes all actors. Empty/one-sided setups save/load. Starting combat requires an actor on each team and refuses before changing the setup. Legacy primary-commander callers keep their guard. Exact spells/equipment and scoped independent uniques remain protected.

The actual ten-unit scenario exposed a placement cycle: repeatedly parking one unrelated actor could not resolve all overlapping destinations. The fix parks all still-blocked actors once outside every target footprint, then requires global exact final deployment. Native deployment is an explicit separate action, never an automatic fallback for a saved scenario/Reset/Rematch.

## Terrain and acceptance scope

Plain, Forest, Mountains, Swamp and Desert passed neutral Elysium test-field initialization, native placement/collision, persistence, natural fights and repeated cleanup. The production positive list is checked against loaded IDs/names. Terrain regeneration can place obstacles on saved cells; exact reopening may correctly refuse. Water, siege, special planes and complete campaign climate/season/enchantment equivalence remain unsupported.

Visible tests include empty counters/refusal/repopulation, terrain and large final views; native tests separately cover repeatable persistence, combat and exact rebuilding. The later menu/mod report adds 97 offline cases, CrabCult and both battles on the actual ten-unit setup. Natural transformations/conversions and complete render-scene coverage remain incomplete. Original diagnostic/scenario/recovery files and normal installation controls were preserved.


## Recorded identifiers

Reference identifiers retained from the original report, including baseline, failed, intermediate and accepted runs. This list alone does not identify a successful run; use the bound evidence above or the original report.

- `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`
- `e08b5a56b0e2e5eac7bcbe6d09fe2b798cd585950955fcdff1c92e1fc29ff9af`
- `df24879e59ceec17b41d9a26f35278fc202fc6761e7186ab6c1d52c5e8dba4ed`
- `fed1bff370bec08b2de2f4a69f5eb36a9804ff2f49a3f15af1aa4fce41fa51fe`
- `238dd83139fe4a4baec3134ff74156ee`
- `e9c93442207d0eac0607182e81043881d07c9b50e9148e766f051b8692306455`
- `3aa7f0da0dd44801918f158386d3633b`
- `20db500868da6f337c6deba34b10d7d1d3b7838659e26d3f54e4913edc435ee6`
- `63b293fb0a694cf6a528cbf66d9aa2e561c80b38337f1fb7e40b154ba64a8bdd`
- `54f26dddea5a440db8ffd327e9351cee`
- `409c10230c2853cd68a2227c2a345d5a001e30637cd720f66240cd2465c796ed`
- `931288ebeb7b426b9b288b1cdd116463`
- `5bd42749aa2c47d4ba1bcafdd15a239a`
