param([switch]$CheckOnly, [switch]$NoWait, [switch]$EditingProbe, [switch]$PlacementProbe, [switch]$InterfaceProbe, [switch]$InspectorProbe, [ValidatePattern('^[a-z0-9_,]*$')][string]$InspectorCases='', [switch]$BattlefieldProbe, [switch]$TerrainCandidates, [switch]$CrabCult, [ValidatePattern('^[a-z0-9_,]*$')][string]$BattlefieldCases='', [ValidateSet('baseline','regression')][string]$ProbeMode='regression', [ValidateRange(800,3840)][int]$WindowWidth=1200, [ValidateRange(600,2160)][int]$WindowHeight=900)
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2
$root=[IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$lab=Join-Path $root 'private/terrain-lab'
$profile=Join-Path $lab 'profile'
$extender=Join-Path (Split-Path $root -Parent) 'SandboxOfElysium-ExtenderLab-current'
$payload=@('glu32.dll','coe5se_loader.dll','coe5se.c5plugin.dll','CoE5SE.c5m','CoE5SE.c5se','banner.tga')
$gameProcess=$null; $launchLock=$null; $verified=$false
function FullPath([string]$Path) { [IO.Path]::GetFullPath($Path).TrimEnd([char[]]'\/') }
function RequireFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required file missing: $Path" }
}
function Hash([string]$Path) {
    $stream=[IO.File]::OpenRead($Path);$sha=[Security.Cryptography.SHA256]::Create()
    try { ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose();$stream.Dispose() }
}
function AssertPlainPath([string]$Path) {
    $cursor=[IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Linked test path is not allowed (junction/symlink): $cursor"
            }
        }
        $cursor=Split-Path $cursor -Parent
    }
}
function AssertPlainTree([string]$Path) {
    AssertPlainPath $Path
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $stack=New-Object 'System.Collections.Generic.Stack[string]';$stack.Push($Path)
    while ($stack.Count) {
        foreach ($entry in Get-ChildItem -LiteralPath $stack.Pop() -Force) {
            if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked test file is not allowed: $($entry.FullName)" }
            if ($entry.PSIsContainer) { $stack.Push($entry.FullName) }
        }
    }
}
function ValidateIdentity([string]$File,[string]$ExpectedProfile) {
    RequireFile $File;AssertPlainPath $File
    $id=Get-Content -LiteralPath $File -Raw | ConvertFrom-Json
    if ((FullPath $id.profile) -ne (FullPath $ExpectedProfile)) {
        throw "Unsafe profile path in $File. Expected: $ExpectedProfile. Launch aborted; the normal profile will not be used."
    }
    if ((FullPath $id.data) -ne (FullPath (Join-Path $id.game 'data'))) { throw "Unexpected game data path in $File" }
    return $id
}
function Fingerprint([string]$Source,[string]$Toolchain) {
    $lines=New-Object 'System.Collections.Generic.List[string]'
    foreach ($f in Get-ChildItem -LiteralPath (Join-Path $Source 'src') -File -Recurse | Sort-Object FullName) {
        $lines.Add($f.FullName.Substring($Source.Length)+':'+(Hash $f.FullName))
    }
    foreach ($name in @('CoE5SE.c5m','CoE5SE.c5se','banner.tga')) { $lines.Add($name+':'+(Hash (Join-Path $Source $name))) }
    foreach ($file in @((Join-Path $PSScriptRoot 'build-upstream.ps1'),(Join-Path $Toolchain 'bin/x86_64-w64-mingw32-clang.exe'),(Join-Path $Toolchain 'bin/x86_64-w64-mingw32-windres.exe'))) {
        $lines.Add($file+':'+(Hash $file))
    }
    $sha=[Security.Cryptography.SHA256]::Create()
    try { ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($lines -join "`n"))))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
function ExperimentalBuild {
    RequireFile (Join-Path $extender 'src/lua_test_battle.h')
    RequireFile (Join-Path $extender 'src/test_field_terrain_arg.h')
    AssertPlainTree (Join-Path $extender 'src')
    $toolchain=Join-Path (Split-Path $root -Parent) 'SCRIPTEXT/spell-weapon-workbench/local-extender/toolchain/llvm-mingw-20260922-ucrt-x86_64'
    RequireFile (Join-Path $toolchain 'bin/x86_64-w64-mingw32-clang.exe')
    RequireFile (Join-Path $toolchain 'bin/x86_64-w64-mingw32-windres.exe')
    if ($TerrainCandidates -and -not $BattlefieldProbe) { throw 'TerrainCandidates is allowed only with the private BattlefieldProbe.' }
    $sourceStamp=Fingerprint $extender $toolchain
    $stamp=$sourceStamp;$candidateSuffix='';$extraFlags=@()
    if ($TerrainCandidates) { $stamp+='-terrain-candidates';$candidateSuffix='-terrain-candidates';$extraFlags=@('-DCOE5SE_TEST_FIELD_TERRAIN_CANDIDATES=1') }
    $output=Join-Path $lab ('builds/launcher-'+$sourceStamp.Substring(0,16)+$candidateSuffix)
    AssertPlainTree $output
    $manifest=Join-Path $output 'launcher-build.json'
    $cached=$false
    if (Test-Path -LiteralPath $manifest) {
        try {
            $saved=Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
            $cached=$saved.inputs -eq $stamp
            foreach ($name in $payload) {
                if (-not (Test-Path -LiteralPath (Join-Path $output $name)) -or (Hash (Join-Path $output $name)) -ne $saved.hashes.PSObject.Properties[$name].Value) { $cached=$false }
            }
        } catch { $cached=$false }
    }
    if ($cached) { Write-Host 'Extender: reusing the matching local build.' }
    else {
        New-Item -ItemType Directory -Path $output -Force | Out-Null
        $buildLog=Join-Path $output ('build-'+[guid]::NewGuid().ToString('N')+'.log')
        Write-Host 'Building the local experimental Extender (without fault injection) ...'
        try { & (Join-Path $PSScriptRoot 'build-upstream.ps1') -SourceDirectory $extender -Toolchain $toolchain -OutputDirectory $output -ExtraCFlags $extraFlags *> $buildLog }
        catch { throw "Extender build failed. Log: $buildLog. $($_.Exception.Message)" }
        if ((Fingerprint $extender $toolchain) -ne $sourceStamp) { throw 'Extender source changed during the build. Run the launcher again.' }
        foreach ($name in @('CoE5SE.c5m','CoE5SE.c5se','banner.tga')) { Copy-Item -LiteralPath (Join-Path $extender $name) -Destination (Join-Path $output $name) }
        $hashes=[ordered]@{};foreach ($name in $payload) { $hashes[$name]=Hash (Join-Path $output $name) }
        @{inputs=$stamp;hashes=$hashes;source=$extender;faultInjection=$false} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifest -Encoding UTF8
    }
    return $output
}
function ReadStatus([string]$File) {
    $values=@{}
    foreach ($line in Get-Content -LiteralPath $File) { if ($line -match '^([^=\[\]]+)=(.*)$') { $values[$matches[1].Trim()]=$matches[2].Trim() } }
    return $values
}
try {
    Write-Host 'SandboxOfElysium - isolated local development'
    foreach ($file in @('tools/build-upstream.ps1','tools/prepare-terrain-lab.py','tools/launch-terrain-lab.ps1','tests/launcher_probe.lua','mod/SandboxOfElysium/SandboxOfElysium.lua','mod/SandboxOfElysium/SandboxOfElysium.c5m','mod/SandboxOfElysium/banner.tga')) { RequireFile (Join-Path $root $file) }
    AssertPlainTree $lab;AssertPlainTree (Join-Path $root 'mod/SandboxOfElysium')
    $identity=ValidateIdentity (Join-Path $lab 'identity.json') $profile
    $baseIdentity=ValidateIdentity (Join-Path $root 'private/lab/identity.json') (Join-Path $root 'private/lab/profile')
    if ((FullPath $identity.game) -ne (FullPath $baseIdentity.game)) { throw 'The two test configurations refer to different games. Check their paths.' }
    RequireFile (Join-Path $profile 'coe5config')
    if (-not (Test-Path -LiteralPath $identity.data -PathType Container)) { throw "Game data missing: $($identity.data)" }
    $exe=Join-Path $lab 'runtime/CoE5.exe'
    RequireFile $exe;RequireFile (Join-Path $identity.game 'CoE5.exe')
    $gameHash=Hash $exe
    if ($gameHash -ne '489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55') {
        throw 'Game version: unknown. This launcher requires the isolated, verified CoE5 5.43 build; profile redirection is unverified for this executable.'
    }
    if ((Hash (Join-Path $identity.game 'CoE5.exe')) -ne $gameHash) { throw 'Installed game and isolated copy have different builds. No automatic update was performed.' }
    foreach ($process in @(Get-Process -Name CoE5 -ErrorAction SilentlyContinue)) {
        if (-not $process.Path) { throw "Cannot verify game process $($process.Id). Close the game first." }
        if ((FullPath $process.Path) -eq (FullPath $exe)) { throw 'This isolated test copy is already running. Choose Quit in that game first.' }
    }
    Write-Host 'Game version: CoE5 5.43 / Steam build 26458448 (executable hash verified)'
    Write-Host "Test profile: $profile"
    Write-Host 'Terrain API: unknown until the running game responds.'
    if ($CheckOnly) {
        Write-Host "Path checks passed. Extender source folder present: $(Test-Path -LiteralPath (Join-Path $extender 'src/coe5se_plugin.c'))"
        Write-Host 'Checks only: no build, synchronization or game launch.'
        exit 0
    }
    $launchLock=[IO.File]::Open((Join-Path $lab 'launcher.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $python=Join-Path $env:LOCALAPPDATA 'Programs/Python/Python313/python.exe'
    if (-not (Test-Path -LiteralPath $python)) {
        $command=Get-Command python.exe -ErrorAction SilentlyContinue
        if (-not $command -or $command.Source -match 'WindowsApps') { throw 'Python 3 is missing. The existing isolated preparation requires Python.' }
        $python=$command.Source
    }
    try { $build=ExperimentalBuild }
    catch {
        Write-Host "Notice: $($_.Exception.Message)" -ForegroundColor Yellow
        $build=Join-Path $root 'private/upstream'
        foreach ($name in $payload) { RequireFile (Join-Path $build $name) }
        if ((Hash (Join-Path $build 'coe5se.c5plugin.dll')) -ne '6faf1c2526dd5c50568d680271c3163e71f04115e610dcf08a0bfe4b8c41d62f') { throw 'No known verified fallback Extender is available. Launch aborted.' }
        Write-Host 'Fallback: previously verified CoE5SE 3.3.0. Forest is unavailable with this build.' -ForegroundColor Yellow
    }
    $nonce=[guid]::NewGuid().ToString('N')
    $prepareArgs=@('--extender',$build,'--label',('launcher-'+$nonce),'--launcher-nonce',$nonce)
    if ($EditingProbe) { $prepareArgs+=@('--editing-probe','--probe-mode',$ProbeMode) }
    if ($PlacementProbe) { $prepareArgs+=@('--placement-probe','--probe-mode',$ProbeMode) }
    if ($InterfaceProbe) { $prepareArgs+=@('--interface-probe','--probe-mode',$ProbeMode) }
    if ($InspectorProbe) { $prepareArgs+=@('--inspector-probe','--probe-mode',$ProbeMode) }
    if ($InspectorCases) { if(-not $InspectorProbe){throw 'InspectorCases requires InspectorProbe.'}; $prepareArgs+=@('--inspector-cases',$InspectorCases) }
    if ($BattlefieldProbe) { $prepareArgs+=@('--battlefield-probe','--probe-mode',$ProbeMode) }
    if ($BattlefieldCases) { if(-not $BattlefieldProbe){throw 'BattlefieldCases requires BattlefieldProbe.'}; $prepareArgs+=@('--battlefield-cases',$BattlefieldCases) }
    if ($env:SOE_TEST_PROBE_AUTO -eq '1') {
        if (-not $BattlefieldProbe -or -not $BattlefieldCases) { throw 'Private probe automation requires an explicit BattlefieldProbe case selection.' }
        $prepareArgs+='--probe-auto'
    }
    if ($TerrainCandidates) { $prepareArgs+='--terrain-candidates' }
    if ($CrabCult) { $prepareArgs+='--crabcult' }
    & $python (Join-Path $PSScriptRoot 'prepare-terrain-lab.py') @prepareArgs
    if ($LASTEXITCODE -ne 0) { throw 'Isolated test preparation failed. No game was launched.' }
    $null=ValidateIdentity (Join-Path $lab 'identity.json') $profile
    $plugin=Join-Path $profile 'mods/CoE5SE/coe5se.c5plugin.dll'
    if ((Hash $plugin) -ne (Hash (Join-Path $build 'coe5se.c5plugin.dll'))) { throw 'Extender copy does not match the selected build.' }
    $sandboxHashLines=New-Object 'System.Collections.Generic.List[string]'
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $root 'mod/SandboxOfElysium') -File -Recurse | Sort-Object FullName) {
        $relative=$file.FullName.Substring((Join-Path $root 'mod/SandboxOfElysium').Length+1)
        $sandboxHashLines.Add($relative+':'+(Hash $file.FullName))
        if ((Hash $file.FullName) -ne (Hash (Join-Path (Join-Path $profile 'mods/SandboxOfElysium') $relative))) { throw "Sandbox copy is outdated: $relative" }
    }
    $version=[Diagnostics.FileVersionInfo]::GetVersionInfo($plugin).ProductVersion
    if (-not $version) { $version='unknown' }
    $sourceSha=[Security.Cryptography.SHA256]::Create()
    try { $sandboxHash=([BitConverter]::ToString($sourceSha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sandboxHashLines -join "`n"))))).Replace('-','').ToLowerInvariant() } finally { $sourceSha.Dispose() }
    $sandboxData=Join-Path $profile 'coe5se_data/SandboxOfElysium'
    New-Item -ItemType Directory -Path $sandboxData -Force | Out-Null
    $contextLines=@('[environment]',('session='+$nonce),('launcher_utc='+[DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')),
        'game_version=5.43',('extender_version='+$version),('extender_build='+(Hash $plugin)),
        ('sandbox_source_hash='+$sandboxHash),('data_folder='+$sandboxData.Replace('\','/')))
    $contextFile=Join-Path $sandboxData 'launcher-context.ini'
    if (Test-Path -LiteralPath $contextFile) {
        $oldContext=[IO.File]::ReadAllText($contextFile)
        if ($oldContext -match '(?m)^\[scenario\]' -or $oldContext -notmatch '(?m)^extender_build=') {
            throw 'launcher-context.ini already contains other user data. File preserved; use a different name.'
        }
    }
    [IO.File]::WriteAllText($contextFile,(($contextLines -join "`n")+"`n"),[Text.UTF8Encoding]::new($false))
    if ($EditingProbe) {
        $probeData=Join-Path $profile 'coe5se_data/ZZSandboxEditingProbe'
        $probeContext=(($contextLines -join "`n")+"`n").Replace($sandboxData.Replace('\','/'),$probeData.Replace('\','/'))
        [IO.File]::WriteAllText((Join-Path $probeData 'launcher-context.ini'),$probeContext,[Text.UTF8Encoding]::new($false))
    }
    if ($PlacementProbe) {
        $probeData=Join-Path $profile 'coe5se_data/ZZSandboxPlacementProbe'
        $probeContext=(($contextLines -join "`n")+"`n").Replace($sandboxData.Replace('\','/'),$probeData.Replace('\','/'))
        [IO.File]::WriteAllText((Join-Path $probeData 'launcher-context.ini'),$probeContext,[Text.UTF8Encoding]::new($false))
    }
    if ($InterfaceProbe) {
        $probeData=Join-Path $profile 'coe5se_data/ZZSandboxInterfaceProbe'
        $probeContext=(($contextLines -join "`n")+"`n").Replace($sandboxData.Replace('\','/'),$probeData.Replace('\','/'))
        [IO.File]::WriteAllText((Join-Path $probeData 'launcher-context.ini'),$probeContext,[Text.UTF8Encoding]::new($false))
    }
    if ($InspectorProbe) {
        $probeData=Join-Path $profile 'coe5se_data/ZZSandboxInspectorProbe'
        $probeContext=(($contextLines -join "`n")+"`n").Replace($sandboxData.Replace('\','/'),$probeData.Replace('\','/'))
        [IO.File]::WriteAllText((Join-Path $probeData 'launcher-context.ini'),$probeContext,[Text.UTF8Encoding]::new($false))
    }
    if ($BattlefieldProbe) {
        foreach ($probeName in @('ZZSandboxBattlefieldProbe','ZZSandboxFinalProbe')) {
            $probeData=Join-Path $profile ('coe5se_data/'+$probeName)
            $probeContext=(($contextLines -join "`n")+"`n").Replace($sandboxData.Replace('\','/'),$probeData.Replace('\','/'))
            [IO.File]::WriteAllText((Join-Path $probeData 'launcher-context.ini'),$probeContext,[Text.UTF8Encoding]::new($false))
        }
    }
    Write-Host "Extender version: $version (local build; SHA256 $(Hash $plugin))"
    Write-Host 'In game: Sandbox -> Battlefield (verified selection) -> Open with native deployment -> Start battle.'
    $gameProcess=& (Join-Path $PSScriptRoot 'launch-terrain-lab.ps1') -PassThru -WindowWidth $WindowWidth -WindowHeight $WindowHeight
    $statusFile=Join-Path $profile ('coe5se_data/SandboxLauncherCheck/response-'+$nonce+'.ini')
    $log=Join-Path $lab 'runtime/coe5se_logs/coe5mod.log'
    $deadline=[DateTime]::UtcNow.AddSeconds(45)
    $status=$null
    while ([DateTime]::UtcNow -lt $deadline) {
        if ($gameProcess.HasExited) { throw 'The game exited before confirming the isolated profile. Check the test log.' }
        if ((Test-Path -LiteralPath $statusFile) -and (Test-Path -LiteralPath $log)) {
            $candidate=ReadStatus $statusFile
            if ($candidate['nonce'] -eq $nonce -and $candidate['sandbox'] -eq '1' -and (Select-String -LiteralPath $log -SimpleMatch 'event=lua_script_loaded mod=SandboxOfElysium ' -Quiet)) { $status=$candidate;break }
        }
        Start-Sleep -Milliseconds 250
    }
    if (-not $status) { throw 'No fresh runtime confirmation in the isolated profile after 45 seconds. Profile/mod loading is unverified; stopping the test process.' }
    $verified=$true
    Write-Host 'Profile redirection: confirmed by the running game with a fresh launch identifier in the test profile.' -ForegroundColor Green
    if ($status['terrain_query'] -eq 'ok' -and $status['plain'] -eq '1' -and $status['forest'] -eq '1') {
        $terrainNames=$status['terrain_names'];if(-not $terrainNames){$terrainNames='Plain, Forest'}
        Write-Host ('Terrain API reports: '+$terrainNames+'. This is not a new combat acceptance test.') -ForegroundColor Green
        if ($TerrainCandidates) { Write-Host 'Private candidate build: new terrain claims still require the test matrix.' -ForegroundColor Yellow }
    } elseif ($status['terrain_query'] -eq 'absent') { Write-Host 'Terrain API: unavailable. Use Plain.' -ForegroundColor Yellow }
    else { Write-Host 'Terrain API: unknown or incomplete. Forest is unverified; use Plain.' -ForegroundColor Yellow }
    if ($status['editor'] -eq '1') { Write-Host 'Editor API: safe editing and native map-coordinate functions are present.' }
    else { Write-Host 'Editor API missing: safe editing/state restoration is limited.' -ForegroundColor Yellow }
    if ($status['integrity'] -eq '1') { Write-Host 'Integrity API: unique guards, native state checks and SDL mouse buttons are available.' }
    else { Write-Host 'Integrity API missing or unknown. The editor may refuse preparation.' -ForegroundColor Yellow }
    Write-Host ('Experimental features (runtime report): lifecycle={0}, multiple unique={1}, inline input={2}, fitted icons={3}. This does not replace functional tests.' -f $status['lifecycle'],$status['multiple_unique'],$status['inline_input'],$status['fitted_icons'])
    Write-Host ('Editor extensions (functions present, not an acceptance test): empty teams={0}, final snapshot API={1}.' -f $status['empty_editor'],$status['final_snapshot_api'])
    Write-Host ('Equipment/base schools: API available={0}. Requires the separate local Extender; not a new functional test.' -f $status['configuration'])
    @{pid=$gameProcess.Id;nonce=$nonce;profile=$profile;gameHash=$gameHash;pluginHash=(Hash $plugin);extenderVersion=$version;status=$status} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $lab 'last-launch.json') -Encoding UTF8
    $launchLock.Dispose();$launchLock=$null
    if (-not $NoWait) {
        Write-Host 'This window remains open until the game exits.'
        $gameProcess.WaitForExit()
        if ($gameProcess.ExitCode -ne 0) { throw "Game exited with code $($gameProcess.ExitCode). Log: $log" }
    }
    exit 0
} catch {
    if ($gameProcess -and -not $verified -and -not $gameProcess.HasExited) { $gameProcess.Kill();$gameProcess.WaitForExit() }
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally { if ($launchLock) { $launchLock.Dispose() } }
