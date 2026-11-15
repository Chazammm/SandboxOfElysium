param([switch]$PassThru,[ValidateRange(800,3840)][int]$WindowWidth=1200,[ValidateRange(600,2160)][int]$WindowHeight=900)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$lab=Join-Path $root 'private/terrain-lab'
$identity=Get-Content -LiteralPath (Join-Path $lab 'identity.json') -Raw | ConvertFrom-Json
$expectedProfile=[IO.Path]::GetFullPath((Join-Path $lab 'profile'))
if ([IO.Path]::GetFullPath($identity.profile) -ne $expectedProfile) { throw 'Unsafe profile path: launch aborted. Expected private/terrain-lab/profile.' }
if ([IO.Path]::GetFullPath($identity.data) -ne [IO.Path]::GetFullPath((Join-Path $identity.game 'data'))) { throw 'Unsafe data path: launch aborted.' }
foreach ($target in @($lab,$expectedProfile)) {
    $cursor=Get-Item -LiteralPath $target
    while ($cursor) {
        if ($cursor.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked test path is not allowed: $($cursor.FullName)" }
        $cursor=$cursor.Parent
    }
}
$info=[System.Diagnostics.ProcessStartInfo]::new()
$info.FileName=Join-Path $lab 'runtime/CoE5.exe';$info.WorkingDirectory=Join-Path $lab 'runtime';$info.UseShellExecute=$false
$info.WindowStyle=[System.Diagnostics.ProcessWindowStyle]::Normal
$info.Arguments='-w --winres={0}*{1} --nofade --nogamepad' -f $WindowWidth,$WindowHeight
$info.EnvironmentVariables['COE5_SAVE']=$expectedProfile;$info.EnvironmentVariables['COE5_DATA']=$identity.data
if ($info.EnvironmentVariables['COE5_SAVE'] -ne $expectedProfile) { throw 'Could not safely set COE5_SAVE.' }
$process=[System.Diagnostics.Process]::Start($info)
$process.Id | Set-Content -LiteralPath (Join-Path $lab 'pid.txt')
if ($PassThru) { $process } else { "Terrain lab PID $($process.Id), build $($identity.label)" }
