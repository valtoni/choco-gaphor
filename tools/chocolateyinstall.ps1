$ErrorActionPreference = 'Stop'

$packageName = 'gaphor'
$version     = '3.1.0'

# Official Windows installer (single 64-bit EXE)
$url64       = "https://github.com/gaphor/gaphor/releases/download/$version/gaphor-$version-installer.exe"

# Official SHA256 of the EXE
$checksum64  = '88F3A13A8038811D578F9E8E3F5041B5DD2B8F6208D7DD3E7F9286FFE61D3EDC'

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

