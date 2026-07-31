function Test-NetSnipeTarget {
    param([string]$Target, [int]$Seconds = 15, [int]$Rate = 2)
    $interval = [math]::Max(100, [math]::Round(1000 / $Rate))
    $sent = 0; $lost = 0
    $values = [System.Collections.Generic.List[double]]::new()
    $samples = [System.Collections.Generic.List[object]]::new()
    $jitter = [System.Collections.Generic.List[double]]::new()
    $previous = $null
    $ping = [System.Net.NetworkInformation.Ping]::new()
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $lastProgress = -2
    Write-NetSnipeProgress -Action 'Ping' -Target $Target -ElapsedSeconds 0 -TotalSeconds $Seconds -Sent 0 -Received 0 -Lost 0 -LastLatency $null
    while ($watch.Elapsed.TotalSeconds -lt $Seconds) {
        $started = [Diagnostics.Stopwatch]::StartNew(); $sent++; $lastLatency = $null
        try {
            $reply = $ping.Send($Target, 2000)
            if ($reply.Status -eq 'Success') {
                $latency = [double]$reply.RoundtripTime; $lastLatency = $latency; $values.Add($latency)
                $samples.Add([ordered]@{ elapsed_seconds = [math]::Round($watch.Elapsed.TotalSeconds, 2); latency_ms = $latency })
                if ($null -ne $previous) { $jitter.Add([math]::Abs($latency - $previous)) }
                $previous = $latency
            } else { $lost++; $previous = $null }
        } catch { $lost++; $previous = $null }
        $sleep = $interval - $started.ElapsedMilliseconds
        if ($sleep -gt 0) { Start-Sleep -Milliseconds $sleep }
        if ($watch.Elapsed.TotalSeconds -ge ($lastProgress + 2) -or $watch.Elapsed.TotalSeconds -ge $Seconds) {
            Write-NetSnipeProgress -Action 'Ping' -Target $Target -ElapsedSeconds $watch.Elapsed.TotalSeconds -TotalSeconds $Seconds -Sent $sent -Received $values.Count -Lost $lost -LastLatency $lastLatency
            $lastProgress = [math]::Floor($watch.Elapsed.TotalSeconds / 2) * 2
        }
    }
    $watch.Stop(); $sorted = @($values | Sort-Object)
    [ordered]@{
        target = $Target; seconds = $Seconds; actual_seconds = [math]::Round($watch.Elapsed.TotalSeconds, 1); rate = $Rate; sent = $sent; received = $values.Count
        loss_percent = if ($sent) { [math]::Round(($lost / $sent) * 100, 2) } else { 100 }
        min_ms = if ($sorted.Count) { [math]::Round($sorted[0], 2) } else { $null }
        average_ms = if ($values.Count) { [math]::Round(($values | Measure-Object -Average).Average, 2) } else { $null }
        max_ms = if ($sorted.Count) { [math]::Round($sorted[$sorted.Count - 1], 2) } else { $null }
        median_ms = if ($sorted.Count) { [math]::Round($sorted[[math]::Floor($sorted.Count / 2)], 2) } else { $null }
        p95_ms = if ($sorted.Count) { [math]::Round($sorted[[math]::Min($sorted.Count - 1, [math]::Floor($sorted.Count * .95))], 2) } else { $null }
        jitter_ms = if ($jitter.Count) { [math]::Round(($jitter | Measure-Object -Average).Average, 2) } else { $null }
        samples = @($samples)
    }
}

function Get-NetSnipeMonitoringTargets {
    $snapshot = Get-NetSnipeStatusSnapshot
    $targets = @()
    if ($snapshot.gateway) { $targets += [string]$snapshot.gateway }
    $targets += @(Get-NetSnipeSavedTargets | ForEach-Object { [string]$_.address })
    @($targets | Select-Object -Unique)
}

function Get-NetSnipeMeasurements {
    param([int]$Seconds = 15)
    $snapshot = Get-NetSnipeStatusSnapshot
    $measurements = foreach ($target in (Get-NetSnipeMonitoringTargets)) {
        $rate = if ($target -eq $snapshot.gateway) { 10 } else { 2 }
        Test-NetSnipeTarget -Target $target -Seconds $Seconds -Rate $rate
    }
    [ordered]@{ snapshot = $snapshot; measurements = @($measurements) }
}

function Invoke-NetSnipePingTest {
    param([string]$Target)
    if ([string]::IsNullOrWhiteSpace($Target)) { throw 'Enter a hostname or IP address to ping.' }
    $requested = $Target.Trim(); $resolved = $requested
    if ($requested -eq '__GATEWAY__') {
        $resolved = Get-NetSnipeGateway
        if ([string]::IsNullOrWhiteSpace($resolved)) { throw 'The active adapter has no IPv4 gateway to ping.' }
    }
    $measurement = Test-NetSnipeTarget -Target $resolved -Seconds (Get-NetSnipeContext).PingSeconds -Rate (Get-NetSnipeContext).PingRate
    [ordered]@{ requested_target = $requested; target = $resolved; measurement = $measurement; note = 'Standard ICMP echo requests only. This does not connect to a game session or modify network settings. Some hosts block or rate-limit ICMP.' }
}

function Invoke-NetSnipeDiagnostics {
    param([int]$Seconds = 60)
    $snapshot = Get-NetSnipeStatusSnapshot
    $targets = @(); if ($snapshot.gateway) { $targets += [string]$snapshot.gateway }; $targets += @('1.1.1.1', '8.8.8.8')
    $unique = @($targets | Select-Object -Unique)
    $perTarget = [math]::Max(5, [math]::Floor($Seconds / $unique.Count))
    $measurements = foreach ($target in $unique) { Test-NetSnipeTarget -Target $target -Seconds $perTarget -Rate $(if ($target -eq $snapshot.gateway) { 10 } else { 2 }) }
    [ordered]@{ snapshot = $snapshot; requested_seconds = $Seconds; per_target_seconds = $perTarget; estimated_total_seconds = $perTarget * $unique.Count; measurements = @($measurements); note = 'The diagnostic budget is shared between the gateway and public reference targets. External ICMP may be rate-limited; one run is not enough to prove a configuration fault.' }
}

function Compare-NetSnipeMeasurements {
    param($Before, $After)
    $rows = foreach ($beforeRow in @($Before.measurements)) {
        $afterRow = @($After.measurements) | Where-Object target -eq $beforeRow.target | Select-Object -First 1
        if (-not $afterRow) { continue }
        [ordered]@{ target = $beforeRow.target; median_delta_ms = if ($null -ne $beforeRow.median_ms -and $null -ne $afterRow.median_ms) { [math]::Round($afterRow.median_ms - $beforeRow.median_ms, 2) } else { $null }; p95_delta_ms = if ($null -ne $beforeRow.p95_ms -and $null -ne $afterRow.p95_ms) { [math]::Round($afterRow.p95_ms - $beforeRow.p95_ms, 2) } else { $null }; jitter_delta_ms = if ($null -ne $beforeRow.jitter_ms -and $null -ne $afterRow.jitter_ms) { [math]::Round($afterRow.jitter_ms - $beforeRow.jitter_ms, 2) } else { $null }; loss_delta_percent = [math]::Round($afterRow.loss_percent - $beforeRow.loss_percent, 2) }
    }
    $bad = @($rows | Where-Object { $_.loss_delta_percent -gt 1 -or $_.median_delta_ms -gt 10 -or $_.p95_delta_ms -gt 20 -or $_.jitter_delta_ms -gt 10 })
    [ordered]@{ rows = @($rows); degraded = $bad.Count -gt 0; degraded_targets = @($bad | ForEach-Object target); recommendation = if ($bad.Count) { 'Results degraded. Review the report and use RestoreLatest.' } else { 'No material degradation detected.' } }
}

Export-ModuleMember -Function Test-NetSnipeTarget, Get-NetSnipeMonitoringTargets, Get-NetSnipeMeasurements, Invoke-NetSnipePingTest, Invoke-NetSnipeDiagnostics, Compare-NetSnipeMeasurements
