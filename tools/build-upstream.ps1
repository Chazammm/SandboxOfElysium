param([Parameter(Mandatory)][string]$Toolchain, [string]$SourceDirectory, [string[]]$ExtraCFlags=@(), [string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$src = if ($SourceDirectory) { Join-Path (Resolve-Path -LiteralPath $SourceDirectory) 'src' } else { Join-Path $root 'private/upstream/src' }
$cc = Join-Path $Toolchain 'bin/x86_64-w64-mingw32-clang.exe'
$rc = Join-Path $Toolchain 'bin/x86_64-w64-mingw32-windres.exe'
$out = if ($OutputDirectory) { [IO.Path]::GetFullPath($OutputDirectory) } else { Split-Path $src -Parent }
New-Item -ItemType Directory -Path $out -Force | Out-Null
$stub = Join-Path $out 'glu32.dll'
$loader = Join-Path $out 'coe5se_loader.dll'
$plugin = Join-Path $out 'coe5se.c5plugin.dll'
$loaderResource = Join-Path $out 'loader.rc.o'
$pluginResource = Join-Path $out 'plugin.rc.o'
Push-Location $src
try {
    & $cc -shared -O2 -Wall -Wextra -s '-Wl,--no-insert-timestamp' -o $stub frozen_stub/glu32_stub.c frozen_stub/glu32.def -lbcrypt -luser32
    if ($LASTEXITCODE) { throw 'stub build failed' }
    & $rc -O coff -o $loaderResource coe5se_loader.rc
    if ($LASTEXITCODE) { throw 'loader resource failed' }
    & $cc -shared -O2 -Wall -Wextra -s '-Wl,--no-insert-timestamp' -o $loader coe5se_loader.c -lbcrypt -luser32 $loaderResource
    if ($LASTEXITCODE) { throw 'loader build failed' }
    & $rc -O coff -o $pluginResource coe5se.c5plugin.rc
    if ($LASTEXITCODE) { throw 'plugin resource failed' }
    $lua = Get-ChildItem -LiteralPath ./lua -Filter '*.c' | Where-Object Name -NotIn @('lua.c','luac.c','linit.c','liolib.c','loadlib.c','loslib.c','ldblib.c') | ForEach-Object { 'lua/' + $_.Name }
    & $cc -shared -O2 -Wall -Wextra -s '-Wl,--no-insert-timestamp' @ExtraCFlags -o $plugin coe5se_plugin.c graphics/graphics.c fanpatch/fix_feeblemind.c fanpatch/fix_item_reset.c fanpatch/fix_token_sprites.c @lua -I. -Ilua -lbcrypt -lshell32 -luser32 $pluginResource
    if ($LASTEXITCODE) { throw 'plugin build failed' }
} finally { Pop-Location }
