param([string]$OutputDirectory)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$out=if($OutputDirectory){[IO.Path]::GetFullPath($OutputDirectory)}else{Join-Path $root 'dist'}
$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if($version -notmatch '^\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?$'){throw 'Invalid package version'}
New-Item -ItemType Directory -Path $out -Force | Out-Null
$zip=Join-Path $out ('SandboxOfElysium-'+$version+'.zip')
if(Test-Path -LiteralPath $zip){throw "Package already exists; kept unchanged: $zip"}
# Git's ignore rules exclude raw local captures. Already tracked historical
# evidence and reviewed docs/public-evidence remain eligible. No private tree.
$files=@(& git -C $root ls-files --cached --others --exclude-standard -- mod docs tests tools)
if($LASTEXITCODE){throw 'Git file inventory failed'}
$files+=@('README.md','INSTALLATION.md','LICENSE','MODLOG.md','MODDING_PLAN.md','CHANGELOG.md','VERSION','SandboxOfElysium-Testen.bat')
$stage=Join-Path $out ('stage-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
foreach($relative in ($files|Sort-Object -Unique)){
    $source=[IO.Path]::GetFullPath((Join-Path $root $relative))
    if(-not $source.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Package path outside project'}
    if($relative -match '(^|[/\\])(private|dist|\.git)([/\\]|$)' -or [IO.Path]::GetExtension($relative) -in @('.dll','.exe','.o','.obj','.log')){throw "Refusing private/build payload: $relative"}
    if(-not(Test-Path -LiteralPath $source -PathType Leaf)){throw "Package file missing: $relative"}
    $destination=Join-Path $stage $relative
    New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force|Out-Null
    Copy-Item -LiteralPath $source -Destination $destination
}
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip
Get-FileHash -LiteralPath $zip -Algorithm SHA256
