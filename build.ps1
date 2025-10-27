Param(
  [switch]$Pack
)

$ErrorActionPreference = 'Stop'

# Paths
$root               = Split-Path -Parent $MyInvocation.MyCommand.Definition
$nuspecPath         = Join-Path $root 'gaphor.nuspec'
$templateDir        = Join-Path $root 'template'
$toolsDir           = Join-Path $root 'tools'
$outputDir          = Join-Path $root 'output'
$installTemplatePs1 = Join-Path $templateDir 'chocolateyinstall.ps1'
$installPs1         = Join-Path $toolsDir 'chocolateyinstall.ps1'
$verificationPath   = Join-Path $toolsDir 'VERIFICATION.txt'

if (-not (Test-Path $nuspecPath))         { throw "File not found: $nuspecPath" }
if (-not (Test-Path $installTemplatePs1)) { throw "File not found: $installTemplatePs1" }
if (-not (Test-Path $toolsDir))           { New-Item -ItemType Directory -Path $toolsDir  | Out-Null }
if (-not (Test-Path $outputDir))          { New-Item -ItemType Directory -Path $outputDir | Out-Null }

# Read <version> from nuspec
[xml]$nuspec = Get-Content $nuspecPath -Raw
$version = $nuspec.package.metadata.version
if ([string]::IsNullOrWhiteSpace($version)) { throw "Could not read <version> from $nuspecPath" }

# Compose download URL and local file
$installerName = "gaphor-$version-installer.exe"
$url64         = "https://github.com/gaphor/gaphor/releases/download/$version/$installerName"
$installerPath = Join-Path $toolsDir $installerName

Write-Host "Version ..........: $version"
Write-Host "Download URL .....: $url64"
Write-Host "Installer (tools) : $installerPath"

# Download installer
try {
  Write-Host "Downloading installer..."
  Invoke-WebRequest -Uri $url64 -OutFile $installerPath -UseBasicParsing
} catch {
  throw "Download failed from $url64. $_"
}

# Compute SHA256
Write-Host "Computing SHA256..."
$hash = (Get-FileHash -Path $installerPath -Algorithm SHA256).Hash
Write-Host "SHA256 (x64) .....: $hash"

# Update chocolateyinstall.ps1 from template
$installTemplateContent = Get-Content $installTemplatePs1 -Raw
$installTemplateContent = [regex]::Replace($installTemplateContent, '(\$version\s*=\s*)''[^'']*''', "`$1'$version'")

if ($installTemplateContent -match '__REPLACE_WITH_SHA256__') {
  $installTemplateContent = $installTemplateContent -replace '__REPLACE_WITH_SHA256__', $hash
} elseif ($installTemplateContent -match '(\$checksum64\s*=\s*)''[^'']*''') {
  $installTemplateContent = [regex]::Replace($installTemplateContent, '(\$checksum64\s*=\s*)''[^'']*''', "`$1'$hash'")
} else {
  throw "Could not locate placeholder or `$checksum64 assignment in template: $installTemplatePs1"
}

Set-Content -Path $installPs1 -Value $installTemplateContent -Encoding UTF8
Write-Host "Updated checksum64 in $installPs1"

# ===== Write/Update VERIFICATION.txt (required for community packages) =====
$verificationContent = @"
VERIFICATION
This package downloads the official Gaphor Windows installer from the publisher's GitHub Releases.

Publisher: Gaphor
Product:   Gaphor
Version:   $version

Download URL (x64):
  $url64

Checksum (SHA256) for the downloaded file:
  $hash

Verification steps:
1. Download the installer from the URL above.
2. Compute its SHA256 hash.
3. Ensure the computed hash exactly matches the value listed here.
"@
Set-Content -Path $verificationPath -Value $verificationContent -Encoding UTF8
Write-Host "Wrote VERIFICATION.txt with SHA256."

# ===== OUTPUT ARTIFACTS (without scripts) =====
# 1) Copy installer to output directory
$outInstallerPath = Join-Path $outputDir $installerName
Copy-Item -Force $installerPath $outInstallerPath

# 2) Create SHA256 file (beside the installer copy)
$shaFile = "$outInstallerPath.sha256"
"$hash *$installerName" | Set-Content -Path $shaFile -Encoding ASCII

# 3) Copy VERIFICATION.txt to output as well (for auditing)
Copy-Item -Force $verificationPath (Join-Path $outputDir 'VERIFICATION.txt')

# 4) Create artifact manifest
$manifest = [ordered]@{
  name        = 'gaphor'
  version     = $version
  url64       = $url64
  sha256      = $hash
  generatedAt = (Get-Date).ToString('s')
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $outputDir 'artifact-manifest.json') -Encoding UTF8

# Optionally build .nupkg
$nupkgOut = $null
if ($Pack) {
  if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Warning "Chocolatey CLI not found. Skipping pack."
  } else {
    Write-Host "Packing .nupkg..."
    Push-Location $root
    $packOutput = choco pack
    Write-Host $packOutput
    $expected = "gaphor.$version.nupkg"
    $cand = Join-Path $root $expected
    if (Test-Path $cand) {
      $nupkgOut = $cand
    } else {
      $nupkgOut = Get-ChildItem -Path $root -Filter *.nupkg | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { $_.FullName }
    }
    Pop-Location
    if ($nupkgOut) {
      Copy-Item -Force $nupkgOut (Join-Path $outputDir ([IO.Path]::GetFileName($nupkgOut)))
      Write-Host "Copied nupkg to output: $([IO.Path]::GetFileName($nupkgOut))"
    } else {
      Write-Warning "Could not locate produced .nupkg"
    }
  }
}

Write-Host "Artifacts saved in: $outputDir"
Write-Host "Done."
