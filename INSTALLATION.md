# Install Sandbox of Elysium 0.2.0-beta.2

You need the **Windows x64 build of Conquest of Elysium 5 version 5.43** and **official CoE5SE 3.8.2**. Install CoE5SE separately. [Conquest of Elysium 5 on Steam](https://store.steampowered.com/app/1606340/Conquest_of_Elysium_5/) · [Official CoE5SE 3.8.2 release and ZIP](https://github.com/musical-pianist/coe5se/releases/tag/CoE5SE-v3.8.2)

1. Exit CoE5. Download `CoE5SE-3.8.2.zip` from the official release and follow its Windows instructions in `how-to-install.html`. Copy its `CoE5SE` folder to `%APPDATA%\coe5\mods` and copy the official `glu32.dll` from that folder next to `CoE5.exe`. Confirm CoE5SE is enabled on the game's **Mods** screen.
2. Open CoE5's mod directory through **Mods → Open Mods Directory**. The standard Windows profile uses `%APPDATA%\coe5\mods`. Extract the folder named `SandboxOfElysium` from this ZIP there. The game should find `mods\SandboxOfElysium\SandboxOfElysium.c5m` and the adjacent Lua entry file.
3. Enable **SandboxOfElysium** alongside **CoE5SE** in **Mods**. Restart CoE5 if prompted. Choose **Sandbox** from the main menu.
4. Select a battlefield and choose **Open battlefield / edit (keep positions)**. If the new map cannot keep those positions, choose **Open with native deployment (reposition units)** to let the game place them. Select Team A or B, use **Select** on a unit row, then right-click a free tile. Click **Select** again to clear the placement selection and right-click an existing unit to edit or inspect it.
   To erase units, switch **Ctrl Right-click Delete** on in the footer. Hold Ctrl and right-click a unit, or hold the right button and sweep across several. Scenery stays in place.
5. Put at least one unit on each team and choose **Start battle**. Neutral scenery stays outside the team counts. On the report screen, **Back to Sandbox** restores the setup and **Rematch** restores it before fighting again.

## Update or remove

Close the game. Move any earlier `SandboxOfElysium` mod folder out of `mods` as a backup, then install the new folder. Keep a single enabled copy and preserve `coe5se_data\SandboxOfElysium` in your game profile. This separate folder contains scenarios, diagnostics and recovery copies. Uninstall by disabling the mod and moving its mod folder out of `mods`.

## Troubleshooting

If **Sandbox** is missing, confirm that both mods are enabled, the archive has the folder layout above and CoE5 reports the tested version. If an exact reconstruction is refused, retain the saved setup, export diagnostics and follow the editor's recovery message.

Choose **Export Diagnostics** from the Sandbox menu or battlefield toolbar. The exported INI records the versions, loaded content, recent actions and recovery details that the running build can verify. Find it in `coe5se_data\SandboxOfElysium` under the selected profile. Include your game and CoE5SE versions with the report, especially if the export marks them unknown. Review scenario names and mod names before sharing the file.

[Compatibility and limits](docs/COMPATIBILITY.md)
