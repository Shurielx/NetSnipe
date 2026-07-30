function Resolve-NetSnipeAdapter {
    $context = Get-NetSnipeContext
    $candidates = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object {
        $_.Status -eq 'Up' -and $_.HardwareInterface -and ($_.InterfaceDescription -match 'Wi-?Fi|Wireless|802\.11|FastConnect|Qualcomm')
    })
    $withGateway = @($candidates | Where-Object {
        try { (Get-NetIPConfiguration -InterfaceIndex $_.ifIndex -ErrorAction Stop).IPv4DefaultGateway } catch { $false }
    })
    $pool = if ($withGateway.Count) { $withGateway } else { $candidates }
    if (-not $pool.Count) {
        $fallback = Get-NetAdapter -Name 'Wi-Fi' -ErrorAction SilentlyContinue
        if ($fallback) { $context.AdapterSelectionReason = 'Fallback: adapter named Wi-Fi'; $context.AdapterName = $fallback.Name; return $fallback.Name }
        $context.AdapterSelectionReason = 'No active physical Wi-Fi adapter detected'
        $context.AdapterName = 'Wi-Fi'
        return $context.AdapterName
    }
    $selected = $pool | Sort-Object @{ Expression = { if ($_.InterfaceDescription -match 'Qualcomm|FastConnect') { 0 } else { 1 } } }, @{ Expression = { $_.ifIndex } } | Select-Object -First 1
    $context.AdapterSelectionReason = if ($withGateway.Count) { 'Active physical Wi-Fi adapter with IPv4 default gateway' } else { 'Active physical Wi-Fi adapter without detected gateway' }
    $context.AdapterName = $selected.Name
    return $context.AdapterName
}

function Initialize-NetSnipeAdapter { Resolve-NetSnipeAdapter | Out-Null }

function Get-NetSnipeStatusSnapshot {
    $context = Get-NetSnipeContext
    $adapter = Get-NetAdapter -Name $context.AdapterName -ErrorAction SilentlyContinue
    $ip = Get-NetIPConfiguration -InterfaceAlias $context.AdapterName -ErrorAction SilentlyContinue
    $gateway = if ($ip -and $ip.IPv4DefaultGateway) { [string]$ip.IPv4DefaultGateway.NextHop } else { $null }
    $wifi = @(netsh wlan show interfaces 2>$null)
    $signal = $null; $band = $null; $channel = $null
    foreach ($line in $wifi) {
        if ($line -match 'Signal\s*:\s*(\d+)%') { $signal = [int]$Matches[1] }
        if ($line -match 'Band\s*:\s*(.+)$') { $band = $Matches[1].Trim() }
        if ($line -match 'Channel\s*:\s*(.+)$') { $channel = $Matches[1].Trim() }
    }
    [ordered]@{
        adapter = $context.AdapterName
        description = if ($adapter) { $adapter.InterfaceDescription } else { $null }
        status = if ($adapter) { [string]$adapter.Status } else { 'Not found' }
        link_speed = if ($adapter) { [string]$adapter.LinkSpeed } else { $null }
        gateway = $gateway
        signal = $signal
        band = $band
        channel = $channel
        selection_reason = $context.AdapterSelectionReason
        backup_count = @(Get-NetSnipeBackupFiles).Count
    }
}

function Get-NetSnipeGateway {
    return (Get-NetSnipeStatusSnapshot).gateway
}

function Get-NetSnipeBandwidthRecommendation {
    $snapshot = Get-NetSnipeStatusSnapshot
    [ordered]@{ signal = $snapshot.signal; recommendation = 'Auto'; reason = 'Keep Auto unless repeated measurements prove a narrower channel is more stable.' }
}

Export-ModuleMember -Function Resolve-NetSnipeAdapter, Initialize-NetSnipeAdapter, Get-NetSnipeStatusSnapshot, Get-NetSnipeGateway, Get-NetSnipeBandwidthRecommendation
