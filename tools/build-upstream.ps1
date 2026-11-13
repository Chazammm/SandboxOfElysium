param([Parameter(Mandatory)][string]$Toolchain)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$src = Join-Path $root 'private/upstream/src'
$cc = Join-Path $Toolchain 'bin/x86_64-w64-mingw32-clang.exe'
$rc = Join-Path $Toolchain 'bin/x86_64-w64-mingw32-windres.exe'
Push-Location $src
try {
    & $cc -shared -O2 -Wall -Wextra -s '-Wl,--no-insert-timestamp' -o ../glu32.dll frozen_stub/glu32_stub.c frozen_stub/glu32.def -lbcrypt -luser32
    if ($LASTEXITCODE) { throw 'stub build failed' }
    & $rc -O coff -o ../loader.rc.o coe5se_loader.rc
    if ($LASTEXITCODE) { throw 'loader resource failed' }
    & $cc -shared -O2 -Wall -Wextra -s '-Wl,--no-insert-timestamp' -o ../coe5se_loader.dll coe5se_loader.c -lbcrypt -luser32 ../loader.rc.o
    if ($LASTEXITCODE) { throw 'loader build failed' }
    & $rc -O coff -o ../plugin.rc.o coe5se.c5plugin.rc
    if ($LASTEXITCODE) { throw 'plugin resource failed' }
    $lua = Get-ChildItem -LiteralPath ./lua -Filter '*.c' | Where-Object Name -NotIn @('lua.c','luac.c','linit.c','liolib.c','loadlib.c','loslib.c','ldblib.c') | ForEach-Object { 'lua/' + $_.Name }
    & $cc -shared -O2 -Wall -Wextra -s '-Wl,--no-insert-timestamp' -o ../coe5se.c5plugin.dll coe5se_plugin.c graphics/graphics.c fanpatch/fix_feeblemind.c fanpatch/fix_item_reset.c fanpatch/fix_token_sprites.c @lua -I. -Ilua -lbcrypt -lshell32 -luser32 ../plugin.rc.o
    if ($LASTEXITCODE) { throw 'plugin build failed' }
} finally { Pop-Location }
