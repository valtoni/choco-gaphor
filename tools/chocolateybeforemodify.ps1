# chocolateybeforemodify.ps1
# Runs before upgrade or uninstall. Stop running app to avoid file locks.

$ErrorActionPreference = 'Stop'

$procName = 'gaphor'   # executable is gaphor.exe

# Get any running Gaphor processes (all sessions)
$procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
if (-not $procs) {
  Write-Verbose "No running '$procName.exe' processes detected."
  return
}

Write-Host "Detected running '$procName.exe' process(es): $($procs.Id -join ', '). Attempting graceful shutdown..."

# Try graceful close first
foreach ($p in $procs) {
  try {
    if ($p.MainWindowHandle -and ($p.CloseMainWindow() -eq $true)) {
      # wait up to 15s for exit
      if (-not $p.WaitForExit(15000)) {
        Write-Warning "Process $($p.Id) did not exit in time after CloseMainWindow()."
      }
    }
  } catch {
    Write-Verbose "CloseMainWindow() failed for PID $($p.Id): $_"
  }
}

# Refresh list; force kill any survivors
$stillRunning = Get-Process -Name $procName -ErrorAction SilentlyContinue
if ($stillRunning) {
  Write-Warning "Forcing termination of remaining '$procName.exe' process(es): $($stillRunning.Id -join ', ')"
  foreach ($p in $stillRunning) {
    try {
      Stop-Process -Id $p.Id -Force -ErrorAction Stop
    } catch {
      Write-Warning "Failed to Stop-Process PID $($p.Id): $_"
    }
  }
} else {
  Write-Host "All '$procName.exe' processes exited gracefully."
}
