# SandboxOfElysium 0.2.0-rc.1

Configure two armies in Conquest of Elysium 5 and watch them fight using the game's native AI. This is the non-naval review candidate for Windows CoE5 5.43 x64.

**Dependency status.** The full editor requires additional owned test-field APIs. The compatibility check keeps this candidate's editor closed on stock CoE5SE 3.6.0. The separate upstream-based Windows review build now includes the remaining View and viewport APIs. Public release is pending upstream support and verification of the resulting official build. See [installation](INSTALLATION.md) and [compatibility](docs/COMPATIBILITY.md).

- Choose a land, siege or water battlefield and a native or minimum field size. Sea, Deep Sea and Coastal Hamlet support independent units. Native drowning rules apply.
- Search vanilla and active mod units, use **View** to open the native unit card, and place units with the editor's footprint checks. Both armies can be empty during setup.
- Right-click a placed unit for its items, magic and individual name. Native rules limit equipment, spells and placement.
- Save setups, view the battlefield after a fight, and return to the exact saved deployment, Reset, or Rematch. Invalid restoration preserves the setup and can produce diagnostics.

Fleet and passenger battles are postponed. Existing fleet files remain readable as unavailable entries in the load list so you can identify and retain them.

The mod is MIT licensed. Thanks to Illwinter for CoE5 and musical_pianist for CoE5SE. SandboxOfElysium was developed with Codex assistance. Game content and any third-party mods come from their respective installations.

[Release candidate tests and known limits](docs/TEST-RELEASE-CANDIDATE-2026-11-19.md) · [Changelog](CHANGELOG.md)

See the [combined-build results](docs/TEST-COMBINED-PRESENTATION-2026-11-19.md), [battlefield object audit](docs/TEST-BATTLEFIELD-OBJECTS-2026-11-19.md) and [upstream API dependencies](docs/COE5SE-API-DEPENDENCIES-2026-11-19.md).
