param([switch]$NativeChecks)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$target=Join-Path $root 'private/lab/profile/mods/SandboxOfElysium'
Copy-Item -Path (Join-Path $root 'mod/SandboxOfElysium/*') -Destination $target -Recurse -Force
if ($NativeChecks) {
    Copy-Item -LiteralPath (Join-Path $root 'tests/native_probe.lua') -Destination (Join-Path $target 'sandbox/native_probe.lua')
    Add-Content -LiteralPath (Join-Path $target 'SandboxOfElysium.lua') -Value "`ncoe5.addMainMenuButton('Sandbox API checks',function() require('sandbox.native_probe').run(sandbox) end)"
}
