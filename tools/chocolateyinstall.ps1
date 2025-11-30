$ErrorActionPreference = 'Stop'

$packageName = 'gaphor'
$version     = '3.2.0'

# Official Windows installer (single 64-bit EXE)
$url64       = "https://github.com/gaphor/gaphor/releases/download/$version/gaphor-$version-installer.exe"

# Official SHA256 of the EXE
$checksum64  = 'C6076A89B3FF16318A32F4BA0F1872B258E82E50F93C9447C17FB3D623B4DF91'

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

