param([string]$OutputDirectory)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$out=if($OutputDirectory){[IO.Path]::GetFullPath($OutputDirectory)}else{Join-Path $root 'dist'}
$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if($version -notmatch '^\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?$'){throw 'Invalid package version'}
$zip=Join-Path $out ('SandboxOfElysium-'+$version+'.zip')
if(Test-Path -LiteralPath $zip){throw "Package already exists and was kept: $zip"}
$runtime=Join-Path $root 'mod/SandboxOfElysium'
$modules=Join-Path $runtime 'sandbox'
$docs=@('README.md','INSTALLATION.md','LICENSE','VERSION','docs/COMPATIBILITY.md')
$files=[ordered]@{}
foreach($path in $docs){$files[$path]=Join-Path $root $path}
$files['CHANGELOG.md']=Join-Path $root 'docs/RELEASE-CHANGELOG.md'
foreach($name in @('SandboxOfElysium.c5m','SandboxOfElysium.lua','banner.tga')){$files[('SandboxOfElysium/'+$name)]=Join-Path $runtime $name}
foreach($file in Get-ChildItem -LiteralPath $modules -File -Force | Sort-Object Name){
    if($file.Name -notmatch '^[a-z_]+\.lua$' -or $file.Name -match '^(fleet|transport)'){throw "Unexpected runtime module: $($file.Name)"}
    $files[('SandboxOfElysium/sandbox/'+$file.Name)]=$file.FullName
}
foreach($path in $files.Values){
    $source=Get-Item -LiteralPath $path
    if($source -isnot [IO.FileInfo]){throw "Not a regular input file: $path"}
    while($source){
        if($source.Attributes -band [IO.FileAttributes]::ReparsePoint){throw "Linked package input refused: $($source.FullName)"}
        $source=if($source -is [IO.FileInfo]){$source.Directory}else{$source.Parent}
    }
}
New-Item -ItemType Directory -Path $out -Force|Out-Null
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipStream=[IO.File]::Open($zip,[IO.FileMode]::CreateNew)
try{
    $archive=[IO.Compression.ZipArchive]::new($zipStream,[IO.Compression.ZipArchiveMode]::Create,$true)
    try{
        foreach($path in $files.Keys){
            $entry=$archive.CreateEntry($path,[IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime=[DateTimeOffset]::new(2026,11,19,0,0,0,[TimeSpan]::Zero)
            $dest=$entry.Open();$inputFile=[IO.File]::OpenRead($files[$path])
            try{$inputFile.CopyTo($dest)}finally{$inputFile.Dispose();$dest.Dispose()}
        }
    }finally{$archive.Dispose()}
}finally{$zipStream.Dispose()}
Get-FileHash -LiteralPath $zip -Algorithm SHA256
