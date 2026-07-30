function Invoke-NetSnipeBufferbloat {
    param([int]$DownloadMb = 10, [int]$MaximumSeconds = 90)
    $gateway = Get-NetSnipeGateway
    if (-not $gateway) { throw 'No IPv4 gateway available for bufferbloat test.' }
    $baseline = Test-NetSnipeTarget -Target $gateway -Seconds 15 -Rate 10
    $client = [System.Net.Http.HttpClient]::new(); $client.Timeout = [TimeSpan]::FromSeconds($MaximumSeconds + 10)
    $bytes = [math]::Max(5000000, [math]::Min(50000000, $DownloadMb * 1000000))
    $url = "https://speed.cloudflare.com/__down?bytes=$bytes"
    $task = $client.GetByteArrayAsync($url)
    $loaded = [System.Collections.Generic.List[double]]::new(); $watch = [Diagnostics.Stopwatch]::StartNew(); $ping = [System.Net.NetworkInformation.Ping]::new()
    while (-not $task.IsCompleted -and $watch.Elapsed.TotalSeconds -lt $MaximumSeconds) {
        try { $reply = $ping.Send($gateway, 2000); if ($reply.Status -eq 'Success') { $loaded.Add([double]$reply.RoundtripTime) } } catch { }
        Start-Sleep -Milliseconds 100
    }
    try { $task.GetAwaiter().GetResult() | Out-Null } catch { }
    $client.Dispose(); $watch.Stop()
    $sorted = @($loaded | Sort-Object)
    $loadedMedian = if ($sorted.Count) { [math]::Round($sorted[[math]::Floor($sorted.Count / 2)], 2) } else { $null }
    $added = if ($null -ne $loadedMedian -and $null -ne $baseline.median_ms) { [math]::Round($loadedMedian - $baseline.median_ms, 2) } else { $null }
    [ordered]@{
        gateway = $gateway
        baseline = $baseline
        download_mb = $DownloadMb
        maximum_seconds = $MaximumSeconds
        loaded_ping_median_ms = $loadedMedian
        loaded_samples = $loaded.Count
        added_latency_ms = $added
        assessment = if ($null -eq $added) { 'Not enough samples' } elseif ($added -le 20) { 'Low added latency' } elseif ($added -le 50) { 'Moderate added latency' } else { 'High added latency' }
        note = "The download used a temporary ${DownloadMb} MB Cloudflare endpoint and requires Internet access. No network settings were changed."
    }
}

Export-ModuleMember -Function Invoke-NetSnipeBufferbloat
