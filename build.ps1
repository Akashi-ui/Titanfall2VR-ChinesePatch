param([string]$OutputName = "Titanfall2VR-Korean-Setup-v0.2.29.exe")
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Path $dist -Force | Out-Null
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { throw '.NET Framework C# compiler not found.' }
$zip = Join-Path $dist 'payload.zip'
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip }
[IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $root 'payload'), $zip, [IO.Compression.CompressionLevel]::Optimal, $false)
$exe = Join-Path $dist ([IO.Path]::GetFileName($OutputName))
& $compiler /nologo /target:winexe /platform:x64 /optimize+ /utf8output /codepage:65001 "/out:$exe" "/win32manifest:$root\src\app.manifest" "/resource:$zip,payload.zip" "/resource:$root\src\Assets\titanfall-2.jpg,hero.jpg" /reference:System.Windows.Forms.dll /reference:System.Drawing.dll /reference:System.IO.Compression.dll /reference:System.IO.Compression.FileSystem.dll /reference:System.Web.Extensions.dll /reference:System.Net.Http.dll "$root\src\Installer.cs" "$root\src\AssemblyInfo.cs" "$root\src\UpdateChecker.cs" "$root\src\Manager.cs"
if ($LASTEXITCODE -ne 0) { throw 'Installer build failed.' }
$hash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path $dist 'SHA256SUMS.txt'), $hash + '  ' + [IO.Path]::GetFileName($exe) + "`n", [Text.UTF8Encoding]::new($false))
Write-Output $exe
