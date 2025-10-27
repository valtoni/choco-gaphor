# chocolateyuninstall.ps1
$ErrorActionPreference = 'Stop'

$packageName = $env:ChocolateyPackageName

$packageArgs = @{
  packageName    = $packageName
  softwareName   = 'Gaphor*'   # DisplayName in Programs and Features
  fileType       = 'exe'       # NSIS-based installer
  silentArgs     = '/S'        # NSIS silent uninstall
  validExitCodes = @(0)        # NSIS returns 0 on success
}

[array]$keys = Get-UninstallRegistryKey -SoftwareName $packageArgs.softwareName

if ($keys.Count -eq 1) {
  $key = $keys[0]

  # UninstallString may contain arguments; pass only the exe path to file and keep /S in silentArgs
  $exePath, $existingArgs = $key.UninstallString -split '\s+', 2
  $exePath = $exePath.Trim('"')

  if ([string]::IsNullOrWhiteSpace($exePath) -or -not (Test-Path $exePath)) {
    Write-Warning "Uninstall executable not found or invalid in registry: '$($key.UninstallString)'. Trying auto-uninstaller."
  } else {
    $packageArgs['file'] = $exePath
  }

  Uninstall-ChocolateyPackage @packageArgs

} elseif ($keys.Count -eq 0) {
  Write-Warning "$packageName appears to be already uninstalled."

} else {
  # Multiple matches – prefer the one with an uninstall EXE path that exists
  $preferred = $keys | Where-Object {
    $_.UninstallString -match '\.exe' -and (Test-Path (($_.UninstallString -split '\s+',2)[0].Trim('"')))
  } | Select-Object -First 1

  if ($null -ne $preferred) {
    $exePath = ( $preferred.UninstallString -split '\s+', 2 )[0].Trim('"')
    $packageArgs['file'] = $exePath
    Uninstall-ChocolateyPackage @packageArgs
  } else {
    Write-Warning "$($keys.Count) registry entries matched '$($packageArgs.softwareName)'."
    Write-Warning "No unique uninstall target resolved. Aborting to prevent accidental removal."
    $keys | ForEach-Object { Write-Warning "- $($_.DisplayName) :: $($_.UninstallString)" }
  }
}
