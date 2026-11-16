# Repository working conventions

Use English for user-facing text, code comments, documentation, commit messages, branches, issues, pull requests and releases. Keep recorded proper names, user-selected scenario labels, API identifiers and quoted evidence intact. Do not rewrite Git history to translate old commits.

Preserve existing work, scenarios, diagnostics and recovery files. Keep experimental CoE5SE source and binaries separate from the Sandbox mod. Do not bundle Extender/game/third-party mod files. Test only in an explicitly isolated game copy and profile, and distinguish native API tests, visible UI observations and offline checks.

Historical report consolidations must retain their version boundaries, limitations and links to original evidence. Never upgrade an incomplete or failed test to a pass.

Mute every isolated game instance launched by an agent. Use the native process arguments `--nosound --musicvol=0` (the public test launcher accepts `-Muted`). Apply them to native probes and visible game tests alike. Leave the normal game's audio settings and system volume unchanged.

When Sandbox needs a capability missing from CoE5SE, first check current upstream and existing APIs. If genuinely absent, implement/test a general-purpose API in a separate experimental Extender checkout. Keep it outside the mod and the already submitted PR unless explicitly authorized. Document its native behavior, contract, tests, compatibility, limitations and Sandbox use case for a later contribution to musical_pianist. Never bundle or distribute a modified Extender with the mod.
