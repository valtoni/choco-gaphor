$ErrorActionPreference = 'Stop'

$packageName = 'gaphor'
$version     = 'x.y.z'

# Official Windows installer (single 64-bit EXE)
$url64       = "https://github.com/gaphor/gaphor/releases/download/$version/gaphor-$version-installer.exe"

# Official SHA256 of the EXE
$checksum64  = '__REPLACE_WITH_SHA256__'

$packageArgs = @{
  packageName    = $packageName
  fileType       = 'exe'
  url64bit       = $url64
  softwareName   = 'Gaphor*'
  checksum64     = $checksum64
  checksumType64 = 'sha256'
  silentArgs     = '/S'               # NSIS silent
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
