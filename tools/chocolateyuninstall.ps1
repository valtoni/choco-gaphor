# chocolateyuninstall.ps1
$ErrorActionPreference = 'Stop'

$packageName = $env:ChocolateyPackageName

# Defaults for NSIS
$packageArgs = @{
  packageName    = $packageName
  softwareName   = 'Gaphor*'
  fileType       = 'exe'       # fallback default; will switch to 'msi' if needed
  silentArgs     = '/S'
  validExitCodes = @(0)
}

[array]$keys = Get-UninstallRegistryKey -SoftwareName $packageArgs.softwareName

if ($keys.Count -eq 0) {
  Write-Warning "$packageName appears to be already uninstalled."
  return
}

# If multiple matches, prefer one with an EXE path or MSI product code
if ($keys.Count -gt 1) {
  $keys = $keys | Sort-Object {
    # Prefer MSI (WindowsInstaller=1) or EXE with .exe path in UninstallString
    $score = 0
    if ($_.WindowsInstaller -eq 1) { $score += 2 }
    if ($_.UninstallString -match '\.exe') { $score += 1 }
    -$score
  }
}

$key = $keys[0]
$uninstallString = $key.UninstallString

# MSI path: WindowsInstaller=1 or UninstallString referencing msiexec with a product code GUID
$looksLikeMsi = ($key.WindowsInstaller -eq 1) -or ($uninstallString -match '(?i)msiexec\.exe')

if ($looksLikeMsi) {
  # Use product code GUID (PSChildName) as first arg to msiexec /x
  $packageArgs.fileType       = 'msi'
  $packageArgs.silentArgs     = "$($key.PSChildName) /qn /norestart"
  $packageArgs.validExitCodes = @(0, 3010, 1605, 1614, 1641)  # typical MSI codes
  $packageArgs.file           = ''  # ignored for MSI
  Uninstall-ChocolateyPackage @packageArgs
  return
}

# EXE path: extract robustly from UninstallString
# Matches: "C:\Path\app.exe" [args]  OR  C:\Path\app.exe [args]
$rx = '^(?:"(?<exe>[^"]+\.exe)"|(?<exe>\S+\.exe))(?:\s+(?<args>.*))?$'
$m = [regex]::Match($uninstallString, $rx)
if (-not $m.Success) {
  throw "Could not parse UninstallString: $uninstallString"
}

$exePath      = $m.Groups['exe'].Value.Trim()
$existingArgs = $m.Groups['args'].Value.Trim()

# Prefer our own silentArgs for NSIS
if ($existingArgs -match '(?i)(/S|/silent|/verysilent|/qn|/quiet)') {
  # Run vendor args only (Chocolatey passes them via -SilentArgs). Keep defaults minimal.
  $packageArgs.silentArgs = $existingArgs
}

# Always set file so Chocolatey has a target to run
$packageArgs.file = $exePath

Uninstall-ChocolateyPackage @packageArgs
