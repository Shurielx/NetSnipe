function Invoke-NetSnipeDnsTest {
    $context = Get-NetSnipeContext
    $names = @('cloudflare.com', 'google.com', 'microsoft.com')
    $servers = @()
    try { $servers = @(Get-DnsClientServerAddress -InterfaceAlias $context.AdapterName -AddressFamily IPv4 -ErrorAction Stop).ServerAddresses } catch { }
    if (-not $servers) { $servers = @('1.1.1.1', '8.8.8.8') }
    $results = foreach ($server in ($servers | Select-Object -Unique)) {
        foreach ($name in $names) {
            $watch = [Diagnostics.Stopwatch]::StartNew(); $ok = $false; $address = $null; $errorText = $null
            try {
                $answer = Resolve-DnsName -Name $name -Server $server -Type A -DnsOnly -ErrorAction Stop | Where-Object Type -eq 'A' | Select-Object -First 1
                $ok = $null -ne $answer; if ($answer) { $address = $answer.IPAddress }
            } catch { $errorText = $_.Exception.Message }
            $watch.Stop()
            [ordered]@{ server = $server; name = $name; success = $ok; latency_ms = $watch.Elapsed.TotalMilliseconds.ToString('0.00'); address = $address; error = $errorText }
        }
    }
    [ordered]@{ configured_servers = @($servers); results = @($results); successful = @($results | Where-Object success).Count; note = 'This measures DNS name resolution through the configured servers. It is not an ICMP ping test.' }
}

Export-ModuleMember -Function Invoke-NetSnipeDnsTest
