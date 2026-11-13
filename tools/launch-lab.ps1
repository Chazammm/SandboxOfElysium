$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$lab = Join-Path $root 'private/lab'
$identity = Get-Content -LiteralPath (Join-Path $lab 'identity.json') -Raw | ConvertFrom-Json
$info = [System.Diagnostics.ProcessStartInfo]::new()
$info.FileName = Join-Path $lab 'runtime/CoE5.exe'
$info.WorkingDirectory = Join-Path $lab 'runtime'
$info.UseShellExecute = $false
$info.Arguments = '-w --winres=1200*900 --nofade --nogamepad'
$info.Environment['COE5_SAVE'] = $identity.profile
$info.Environment['COE5_DATA'] = $identity.data
$process = [System.Diagnostics.Process]::Start($info)
$process.Id | Set-Content -LiteralPath (Join-Path $lab 'pid.txt')
Write-Output "Sandbox lab PID $($process.Id)"
