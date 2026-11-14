# Extender API work: terrain experiment, 2026-11-13

The user authorized preparation of changes to CoE5SE for a potential future pull request. No pull request or message has been sent.

## Upstream changed

The Sandbox prototype tested CoE5SE dev `57abc69a2ddb272a5b9049b4a561367066d9d99e` (3.3.0). GitHub's `57abc69...dev` comparison on 2026-11-13 reported dev one commit ahead, including 3.4.0 custom item-slot work. This does not by itself establish a usable anatomical-slot Lua API; investigate its actual semantics before changing the item editor. `src/lua_test_battle.h` at dev has unchanged blob `a3df3f0cdbbdd680f6406b301c9f5297ab4353d5`.

## Separate local experiment

An independent local Git clone and branch `sandbox-test-field-terrain` exist at `../SandboxOfElysium-ExtenderLab`, based on the previously available 3.3.0 commit. The existing upstream checkout and the installed extender were not modified. Its `SANDBOX_TERRAIN_EXPERIMENT.md` records the hypothesis, code, validation status and required next steps.

The experimental optional `terrain` field is compiled but has not been tested in the game. It only writes a terrain ID into the test square; it does not establish correct terrain-derived ground, water, fort or siege behavior. It must not be enabled in the sandbox as a finished feature. The compile used llvm-mingw and produced a temporary DLL outside this repository. Neither the existing test lab nor the installed game was changed.

## Next

Obtain the full current dev checkout (direct Git network access failed in this environment), rebase and repeat build. Then use the isolated lab to prove valid and invalid arguments, grass regression, native setup/cleanup and campaign-equivalent behavior for safe land terrain before considering a PR. Assess water/forts separately and compare 3.4.0 item-slot changes against the existing API-gap report. Capture reproducible evidence with exact versions and do not distribute game binaries.

## Follow-up completed on 2026-11-13

The preceding sections describe the preserved **earlier** experiment. The full official dev source was subsequently fetched and verified at **d96f2b784e97e115022a2598da2c821dd9520135**, version **3.4.0/API 11**, in the new sibling worktree `SandboxOfElysium-ExtenderLab-current`, branch `sandbox-test-field-terrain-3.4`. The dirty original checkout was retained.

Strict optional terrain parsing, a read-only capability query, native neutral plane/temperature/ground initialization, failure rollback and a separate pre-existing square-army restoration fix are now implemented and Windows-compiled. Plain and Forest were visually inspected and fought in the real isolated game. Forest's initial snowy/empty failure and the corrected native vegetation are both recorded. Twenty-one actual C-parser tests, twenty Sandbox model/guard tests, native invalid-input/alternation/fault checks, and real Sandbox Forest save/load/reset/rematch passed.

Sandbox now offers capability-gated Plain/Forest and an explicit native-deployment preparation action when new vegetation blocks old positions. No campaign-environment equivalence, other terrain, siege or Mac support is claimed. Regular profiles and the installed extender remain unchanged. No PR, message or push was sent.

The authoritative detailed follow-up is [TERRAIN-EXPERIMENT-2026-11-13.md](TERRAIN-EXPERIMENT-2026-11-13.md), with generated evidence under `docs/evidence/terrain-3.4/`. The English local draft is in the original sibling lab as `PR_DRAFT_TEST_FIELD_TERRAIN.md`; the current worktree has a new experiment note. The original note was not overwritten.
