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
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Benoetigte Datei fehlt: $Path" }
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
                throw "Verknuepfter Testpfad nicht erlaubt (Junction/Symlink): $cursor"
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
            if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Verknuepfte Testdatei nicht erlaubt: $($entry.FullName)" }
            if ($entry.PSIsContainer) { $stack.Push($entry.FullName) }
        }
    }
}
function ValidateIdentity([string]$File,[string]$ExpectedProfile) {
    RequireFile $File;AssertPlainPath $File
    $id=Get-Content -LiteralPath $File -Raw | ConvertFrom-Json
    if ((FullPath $id.profile) -ne (FullPath $ExpectedProfile)) {
        throw "Unsicherer Profilpfad in $File. Erwartet: $ExpectedProfile. Start abgebrochen; normales Profil wird nicht verwendet."
    }
    if ((FullPath $id.data) -ne (FullPath (Join-Path $id.game 'data'))) { throw "Unpassender Spieldatenpfad in $File" }
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
    if ($TerrainCandidates -and -not $BattlefieldProbe) { throw 'TerrainCandidates ist ausschliesslich fuer den privaten BattlefieldProbe erlaubt.' }
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
    if ($cached) { Write-Host 'Extender: passender lokaler Build wird wiederverwendet.' }
    else {
        New-Item -ItemType Directory -Path $output -Force | Out-Null
        $buildLog=Join-Path $output ('build-'+[guid]::NewGuid().ToString('N')+'.log')
        Write-Host 'Baue den lokalen experimentellen Extender (ohne Fehler-Injektion) ...'
        try { & (Join-Path $PSScriptRoot 'build-upstream.ps1') -SourceDirectory $extender -Toolchain $toolchain -OutputDirectory $output -ExtraCFlags $extraFlags *> $buildLog }
        catch { throw "Extender-Build fehlgeschlagen. Protokoll: $buildLog. $($_.Exception.Message)" }
        if ((Fingerprint $extender $toolchain) -ne $sourceStamp) { throw 'Extender-Quellcode wurde waehrend des Builds veraendert. Bitte erneut starten.' }
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
    Write-Host 'SandboxOfElysium - isolierte lokale Entwicklung'
    foreach ($file in @('tools/build-upstream.ps1','tools/prepare-terrain-lab.py','tools/launch-terrain-lab.ps1','tests/launcher_probe.lua','mod/SandboxOfElysium/SandboxOfElysium.lua','mod/SandboxOfElysium/SandboxOfElysium.c5m','mod/SandboxOfElysium/banner.tga')) { RequireFile (Join-Path $root $file) }
    AssertPlainTree $lab;AssertPlainTree (Join-Path $root 'mod/SandboxOfElysium')
    $identity=ValidateIdentity (Join-Path $lab 'identity.json') $profile
    $baseIdentity=ValidateIdentity (Join-Path $root 'private/lab/identity.json') (Join-Path $root 'private/lab/profile')
    if ((FullPath $identity.game) -ne (FullPath $baseIdentity.game)) { throw 'Die beiden Lab-Konfigurationen nennen unterschiedliche Spiele. Bitte pruefen.' }
    RequireFile (Join-Path $profile 'coe5config')
    if (-not (Test-Path -LiteralPath $identity.data -PathType Container)) { throw "Spieldaten fehlen: $($identity.data)" }
    $exe=Join-Path $lab 'runtime/CoE5.exe'
    RequireFile $exe;RequireFile (Join-Path $identity.game 'CoE5.exe')
    $gameHash=Hash $exe
    if ($gameHash -ne '489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55') {
        throw 'Spielversion: unbekannt. Dieser Starter ist fuer den isoliert geprueften CoE5-5.43-Build eingerichtet; Profilumleitung fuer diese EXE nicht bestaetigt.'
    }
    if ((Hash (Join-Path $identity.game 'CoE5.exe')) -ne $gameHash) { throw 'Installiertes Spiel und isolierte Kopie haben unterschiedliche Builds. Keine automatische Aktualisierung durchgefuehrt.' }
    foreach ($process in @(Get-Process -Name CoE5 -ErrorAction SilentlyContinue)) {
        if (-not $process.Path) { throw "Spielprozess $($process.Id) ist nicht pruefbar. Bitte Spiel zuerst schliessen." }
        if ((FullPath $process.Path) -eq (FullPath $exe)) { throw 'Diese isolierte Testkopie laeuft bereits. Bitte zuerst im Spiel Quit waehlen.' }
    }
    Write-Host 'Spielversion: CoE5 5.43 / Steam-Build 26458448 (EXE-Hash abgeglichen)'
    Write-Host "Testprofil: $profile"
    Write-Host 'Terrain-API: unbekannt bis zur Rueckmeldung des laufenden Spiels.'
    if ($CheckOnly) {
        Write-Host "Pfadpruefung OK. Extender-Quellordner vorhanden: $(Test-Path -LiteralPath (Join-Path $extender 'src/coe5se_plugin.c'))"
        Write-Host 'Nur geprueft: kein Build, keine Synchronisierung, kein Spielstart.'
        exit 0
    }
    $launchLock=[IO.File]::Open((Join-Path $lab 'launcher.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $python=Join-Path $env:LOCALAPPDATA 'Programs/Python/Python313/python.exe'
    if (-not (Test-Path -LiteralPath $python)) {
        $command=Get-Command python.exe -ErrorAction SilentlyContinue
        if (-not $command -or $command.Source -match 'WindowsApps') { throw 'Python 3 fehlt. Fuer die vorhandene isolierte Vorbereitung wird Python benoetigt.' }
        $python=$command.Source
    }
    try { $build=ExperimentalBuild }
    catch {
        Write-Host "Hinweis: $($_.Exception.Message)" -ForegroundColor Yellow
        $build=Join-Path $root 'private/upstream'
        foreach ($name in $payload) { RequireFile (Join-Path $build $name) }
        if ((Hash (Join-Path $build 'coe5se.c5plugin.dll')) -ne '6faf1c2526dd5c50568d680271c3163e71f04115e610dcf08a0bfe4b8c41d62f') { throw 'Kein bekannter, gepruefter Ersatz-Extender vorhanden. Start abgebrochen.' }
        Write-Host 'Ersatz: zuvor gepruefter CoE5SE 3.3.0. Forest ist damit nicht verfuegbar.' -ForegroundColor Yellow
    }
    $nonce=[guid]::NewGuid().ToString('N')
    $prepareArgs=@('--extender',$build,'--label',('launcher-'+$nonce),'--launcher-nonce',$nonce)
    if ($EditingProbe) { $prepareArgs+=@('--editing-probe','--probe-mode',$ProbeMode) }
    if ($PlacementProbe) { $prepareArgs+=@('--placement-probe','--probe-mode',$ProbeMode) }
    if ($InterfaceProbe) { $prepareArgs+=@('--interface-probe','--probe-mode',$ProbeMode) }
    if ($InspectorProbe) { $prepareArgs+=@('--inspector-probe','--probe-mode',$ProbeMode) }
    if ($InspectorCases) { if(-not $InspectorProbe){throw 'InspectorCases benoetigt InspectorProbe.'}; $prepareArgs+=@('--inspector-cases',$InspectorCases) }
    if ($BattlefieldProbe) { $prepareArgs+=@('--battlefield-probe','--probe-mode',$ProbeMode) }
    if ($BattlefieldCases) { if(-not $BattlefieldProbe){throw 'BattlefieldCases benoetigt BattlefieldProbe.'}; $prepareArgs+=@('--battlefield-cases',$BattlefieldCases) }
    if ($TerrainCandidates) { $prepareArgs+='--terrain-candidates' }
    if ($CrabCult) { $prepareArgs+='--crabcult' }
    & $python (Join-Path $PSScriptRoot 'prepare-terrain-lab.py') @prepareArgs
    if ($LASTEXITCODE -ne 0) { throw 'Vorbereitung der isolierten Testkopie fehlgeschlagen. Es wurde kein Spiel gestartet.' }
    $null=ValidateIdentity (Join-Path $lab 'identity.json') $profile
    $plugin=Join-Path $profile 'mods/CoE5SE/coe5se.c5plugin.dll'
    if ((Hash $plugin) -ne (Hash (Join-Path $build 'coe5se.c5plugin.dll'))) { throw 'Extender-Kopie stimmt nicht mit dem ausgewaehlten Build ueberein.' }
    $sandboxHashLines=New-Object 'System.Collections.Generic.List[string]'
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $root 'mod/SandboxOfElysium') -File -Recurse | Sort-Object FullName) {
        $relative=$file.FullName.Substring((Join-Path $root 'mod/SandboxOfElysium').Length+1)
        $sandboxHashLines.Add($relative+':'+(Hash $file.FullName))
        if ((Hash $file.FullName) -ne (Hash (Join-Path (Join-Path $profile 'mods/SandboxOfElysium') $relative))) { throw "Sandbox-Kopie nicht aktuell: $relative" }
    }
    $version=[Diagnostics.FileVersionInfo]::GetVersionInfo($plugin).ProductVersion
    if (-not $version) { $version='unbekannt' }
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
            throw 'launcher-context.ini ist bereits mit anderen Nutzerdaten belegt. Datei erhalten; bitte einen anderen Namen verwenden.'
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
    Write-Host "Extender-Version: $version (lokaler Build; SHA256 $(Hash $plugin))"
    Write-Host 'Im Spiel: Sandbox -> Battlefield (verifizierte Auswahl) -> Open with native deployment -> Start battle.'
    $gameProcess=& (Join-Path $PSScriptRoot 'launch-terrain-lab.ps1') -PassThru -WindowWidth $WindowWidth -WindowHeight $WindowHeight
    $statusFile=Join-Path $profile ('coe5se_data/SandboxLauncherCheck/response-'+$nonce+'.ini')
    $log=Join-Path $lab 'runtime/coe5se_logs/coe5mod.log'
    $deadline=[DateTime]::UtcNow.AddSeconds(45)
    $status=$null
    while ([DateTime]::UtcNow -lt $deadline) {
        if ($gameProcess.HasExited) { throw 'Das Spiel wurde beendet, bevor das isolierte Profil bestaetigt wurde. Bitte das Lab-Protokoll pruefen.' }
        if ((Test-Path -LiteralPath $statusFile) -and (Test-Path -LiteralPath $log)) {
            $candidate=ReadStatus $statusFile
            if ($candidate['nonce'] -eq $nonce -and $candidate['sandbox'] -eq '1' -and (Select-String -LiteralPath $log -SimpleMatch 'event=lua_script_loaded mod=SandboxOfElysium ' -Quiet)) { $status=$candidate;break }
        }
        Start-Sleep -Milliseconds 250
    }
    if (-not $status) { throw 'Keine frische Laufzeitbestaetigung im isolierten Profil nach 45 Sekunden. Profil/Mod-Laden nicht sicher bestaetigt; Testprozess wird beendet.' }
    $verified=$true
    Write-Host 'Profilumleitung: vom laufenden Spiel durch neue Startkennung im Testprofil bestaetigt.' -ForegroundColor Green
    if ($status['terrain_query'] -eq 'ok' -and $status['plain'] -eq '1' -and $status['forest'] -eq '1') {
        $terrainNames=$status['terrain_names'];if(-not $terrainNames){$terrainNames='Plain, Forest'}
        Write-Host ('Terrain-API meldet: '+$terrainNames+'. Dies ist kein neuer Kampffunktionstest.') -ForegroundColor Green
        if ($TerrainCandidates) { Write-Host 'Privater Kandidatenbuild: neue Terrain-Meldungen muessen erst durch die Testmatrix bestaetigt werden.' -ForegroundColor Yellow }
    } elseif ($status['terrain_query'] -eq 'absent') { Write-Host 'Terrain-API: nicht verfuegbar. Bitte Plain verwenden.' -ForegroundColor Yellow }
    else { Write-Host 'Terrain-API: unbekannt oder unvollstaendig. Forest ist nicht bestaetigt; bitte Plain verwenden.' -ForegroundColor Yellow }
    if ($status['editor'] -eq '1') { Write-Host 'Editor-API: Funktionen fuer sichere Bearbeitung und native Kartenkoordinaten vorhanden.' }
    else { Write-Host 'Editor-API fehlt: sichere Bearbeitung/Zustandswiederherstellung ist eingeschraenkt.' -ForegroundColor Yellow }
    if ($status['integrity'] -eq '1') { Write-Host 'Integritaets-API: Unique-Schutz, native Zustandspruefung und SDL-Maustasten verfuegbar.' }
    else { Write-Host 'Integritaets-API fehlt oder ist unbekannt. Der aktuelle Editor kann die Vorbereitung ablehnen.' -ForegroundColor Yellow }
    Write-Host ('Experimentelle Funktionen (Laufzeitmeldung): Lebenszyklus={0}, Mehrfach-Unique={1}, Inline-Eingabe={2}, eingepasste Icons={3}. Dies ersetzt keinen Funktionstest.' -f $status['lifecycle'],$status['multiple_unique'],$status['inline_input'],$status['fitted_icons'])
    Write-Host ('Editor-Erweiterungen (Funktionen vorhanden, kein Abnahmetest): leere Teams={0}, finale Snapshot-API={1}.' -f $status['empty_editor'],$status['final_snapshot_api'])
    @{pid=$gameProcess.Id;nonce=$nonce;profile=$profile;gameHash=$gameHash;pluginHash=(Hash $plugin);extenderVersion=$version;status=$status} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $lab 'last-launch.json') -Encoding UTF8
    $launchLock.Dispose();$launchLock=$null
    if (-not $NoWait) {
        Write-Host 'Dieses Fenster bleibt bis zum Beenden des Spiels geoeffnet.'
        $gameProcess.WaitForExit()
        if ($gameProcess.ExitCode -ne 0) { throw "Spiel mit Fehlercode $($gameProcess.ExitCode) beendet. Protokoll: $log" }
    }
    exit 0
} catch {
    if ($gameProcess -and -not $verified -and -not $gameProcess.HasExited) { $gameProcess.Kill();$gameProcess.WaitForExit() }
    Write-Host "FEHLER: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally { if ($launchLock) { $launchLock.Dispose() } }
