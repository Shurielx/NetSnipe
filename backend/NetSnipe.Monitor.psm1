function Start-NetSnipeMonitor {
    $context = Get-NetSnipeContext
    if (Test-Path -LiteralPath $context.MonitorPidFile) {
        $oldPid = Get-Content -LiteralPath $context.MonitorPidFile -ErrorAction SilentlyContinue
        if ($oldPid -and (Get-Process -Id ([int]$oldPid) -ErrorAction SilentlyContinue)) { return [ordered]@{ running = $true; pid = [int]$oldPid; log = $context.MonitorLog } }
    }
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $context.ScriptPath, '-Action', 'Monitor', '-DiagnosticSeconds', '15', '-DataRoot', $context.DataRoot)
    $process = Start-Process -FilePath powershell.exe -ArgumentList $arguments -WorkingDirectory $context.Root -WindowStyle Hidden -PassThru
    $process.Id | Out-File -LiteralPath $context.MonitorPidFile -Encoding ascii -Force
    [ordered]@{ running = $true; pid = $process.Id; log = $context.MonitorLog; note = 'The background worker measures the gateway and saved targets until stopped.' }
}

function Stop-NetSnipeMonitor {
    $context = Get-NetSnipeContext
    if (-not (Test-Path -LiteralPath $context.MonitorPidFile)) { return [ordered]@{ stopped = $false; running = $false; reason = 'Monitor is not running.' } }
    $pid = [int](Get-Content -LiteralPath $context.MonitorPidFile -ErrorAction SilentlyContinue)
    $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
    if ($process) { Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath $context.MonitorPidFile -Force -ErrorAction SilentlyContinue
    [ordered]@{ stopped = $true; running = $false; pid = $pid }
}

function Get-NetSnipeMonitorStatus {
    $context = Get-NetSnipeContext
    if (-not (Test-Path -LiteralPath $context.MonitorPidFile)) { return [ordered]@{ running = $false; log = $context.MonitorLog } }
    $pid = [int](Get-Content -LiteralPath $context.MonitorPidFile -ErrorAction SilentlyContinue)
    $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
    if (-not $process) { Remove-Item -LiteralPath $context.MonitorPidFile -Force -ErrorAction SilentlyContinue; return [ordered]@{ running = $false; log = $context.MonitorLog } }
    [ordered]@{ running = $true; pid = $pid; log = $context.MonitorLog }
}

function Get-NetSnipeMonitorLatest {
    $context = Get-NetSnipeContext
    if (-not (Test-Path -LiteralPath $context.MonitorLog)) { return [ordered]@{ latest = ''; log = $context.MonitorLog } }
    $lines = @(Get-Content -LiteralPath $context.MonitorLog -ErrorAction SilentlyContinue)
    [ordered]@{ latest = if ($lines.Count) { $lines[$lines.Count - 1] } else { '' }; log = $context.MonitorLog }
}

function Invoke-NetSnipeMonitor {
    $context = Get-NetSnipeContext
    while ($true) {
        $snapshot = Get-NetSnipeStatusSnapshot
        $measurements = foreach ($target in (Get-NetSnipeMonitoringTargets)) {
            $rate = if ($target -eq $snapshot.gateway) { 10 } else { 2 }
            Test-NetSnipeTarget -Target $target -Seconds 15 -Rate $rate
        }
        [ordered]@{ timestamp = (Get-Date -Format 'o'); measurements = @($measurements) } | ConvertTo-Json -Compress -Depth 8 | Out-File -LiteralPath $context.MonitorLog -Append -Encoding utf8
        Start-Sleep -Seconds 30
    }
}

Export-ModuleMember -Function Start-NetSnipeMonitor, Stop-NetSnipeMonitor, Get-NetSnipeMonitorStatus, Get-NetSnipeMonitorLatest, Invoke-NetSnipeMonitor
