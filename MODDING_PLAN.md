# Modding plan

- Target: owned Steam CoE5 5.43 Windows x64, app 1606340, build 26458448.
- Route: a separate Lua mod using only the public CoE5SE dev API. No extender changes, native hooks or game executable patches.
- Pinned upstream: `57abc69a2ddb272a5b9049b4a561367066d9d99e` (3.3.0). Original installed version is 3.2.2.
- Lab: ignored private copy of executable and runtime dependencies; separate profile via `COE5_SAVE`; owned data read through `COE5_DATA`. Configuration copied into lab only, with a backup retained there. No real saves are loaded.
- First vertical slice: actual Spearman vs two Goblins from a main-menu Sandbox button. Completed and observed.
- Expansion: cell editor, mixed teams, native collision checks, formations and unit operations, scenario validation, actual combat and truthful report exports.
- Blockers: configurable native terrain/width; exact native unit snapshots; base magic level changes; anatomical equipment-slot preflight; provenance; complete combat event attribution. See docs/API-GAPS.md.
- Publication: only explicit original project files; no private lab, proprietary assets, keys, copied mods or extender binaries. The user explicitly requested the public SandboxOfElysium repository.
