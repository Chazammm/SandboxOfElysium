$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$out=Join-Path $root 'dist'
New-Item -ItemType Directory -Path $out -Force | Out-Null
# An explicit allowlist: never package the lab, upstream, installed mods, or game files.
$stage=Join-Path $out ('stage-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'mod/SandboxOfElysium') -Destination $stage -Recurse
Copy-Item -LiteralPath (Join-Path $root 'README.md'),(Join-Path $root 'LICENSE') -Destination $stage
Copy-Item -LiteralPath (Join-Path $root 'MODLOG.md'),(Join-Path $root 'MODDING_PLAN.md'),(Join-Path $root 'CHANGELOG.md'),(Join-Path $root 'VERSION') -Destination $stage
Copy-Item -LiteralPath (Join-Path $root 'docs') -Destination $stage -Recurse
Copy-Item -LiteralPath (Join-Path $root 'tests'),(Join-Path $root 'tools') -Destination $stage -Recurse
$zip=Join-Path $out 'SandboxOfElysium-0.1.0.zip'
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
Get-FileHash -LiteralPath $zip -Algorithm SHA256
