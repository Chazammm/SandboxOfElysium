# Installation and testing

SandboxOfElysium 0.2.0-rc.1 is a review build for the Windows x64 edition of Conquest of Elysium 5, version 5.43. The package supplies the Sandbox mod and documentation. CoE5SE is installed separately and must provide the compatible owned test-field APIs described in [Compatibility](docs/COMPATIBILITY.md).

Stock CoE5SE 3.6.0 can load the Sandbox menu entry. Clicking it displays the compatibility message and preserves your data. Wait for a compatible official build before installing this package for normal play. See the [official CoE5SE repository](https://github.com/musical-pianist/coe5se) for its installation instructions and current versions.

## Once a compatible build is available

1. Install CoE5SE using its own instructions in a CoE5 test copy and profile. Verify that the game reports the expected version and the Extender is enabled.
2. Copy the archive's `SandboxOfElysium` folder into the profile's `mods` directory. `SandboxOfElysium.c5m` and `SandboxOfElysium.lua` belong directly in that folder.
3. Enable SandboxOfElysium alongside CoE5SE. Restart the game if required and select **Sandbox** from the main menu.
4. Choose a battlefield and **Open battlefield / edit (keep positions)**. The native deployment alternative intentionally picks new positions. Select a team and unit, then right-click a free cell to place it. Use **View** to inspect a type first, or right-click a unit with the browser selection cleared to edit it.
5. Put at least one actor on each side and select **Start battle**. Check **Back to Sandbox (restore setup)**, **Reset setup** and **Rematch**. Save a test copy under a new name.

The source checkout has a developer launcher, `SandboxOfElysium-Testen.bat`, for its preconfigured private lab. It requires separately prepared local game files and Extender sources. It is not part of this archive. The Windows lab used to verify the release candidate is separate from the original development profile. Use `--nosound --musicvol=0` for muted native testing.

Scenarios and diagnostics live under `coe5se_data/SandboxOfElysium` inside the selected profile. If restoration is refused, export diagnostics and keep the original save. When the editor reports unverified cleanup, restart the test game before loading the preserved recovery copy. Disable the mod and remove its folder to uninstall. Keep the data folder if you want your scenarios later.
