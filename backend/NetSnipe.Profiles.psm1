function Set-NetSnipeBandwidth {
    param([string]$Width = 'Auto')
    $context = Get-NetSnipeContext; $changed = @(); $unsupported = @()
    $properties = @(Get-NetAdapterAdvancedProperty -Name $context.AdapterName -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'channel bandwidth|Channel Width' })
    foreach ($property in $properties) {
        $match = @(Get-NetAdapterAdvancedProperty -Name $context.AdapterName -DisplayName $property.DisplayName -ErrorAction SilentlyContinue | Where-Object {
            if ($Width -eq 'Auto') { $_.DisplayValue -match 'Auto|Dynamic|20/40|20/40/80' -or $_.RegistryValue -eq 0 }
            else { $_.DisplayValue -match "\b$Width\b" -or $_.DisplayValue -match "${Width}MHz" }
        } | Select-Object -First 1)
        if ($match) {
            try { Set-NetAdapterAdvancedProperty -Name $context.AdapterName -DisplayName $property.DisplayName -RegistryValue $match.RegistryValue -ErrorAction Stop; $changed += [ordered]@{ property = $property.DisplayName; value = $match.DisplayValue } } catch { $unsupported += $property.DisplayName }
        } else { $unsupported += $property.DisplayName }
    }
    [ordered]@{ requested = $Width; changed = @($changed); unsupported = @($unsupported) }
}

function Get-NetSnipeProfilePreview {
    param([string]$Name)
    $changes = switch ($Name) {
        'Balanced' { @('Enable Wi-Fi background scanning', 'Restore standard TCP behavior', 'Enable IPv4 Large Send Offload', 'Set channel width to Auto') }
        'Gaming Balanced' { @('Keep Wi-Fi background scanning enabled', 'Set TcpAckFrequency=1', 'Set TCPNoDelay=1', 'Disable IPv4 Large Send Offload', 'Set multimedia throttling to latency-focused value', 'Keep channel width on Auto') }
        'Lowest Ping' { @('Disable Wi-Fi background scanning', 'Set TcpAckFrequency=1', 'Set TCPNoDelay=1', 'Disable IPv4 Large Send Offload', 'Set multimedia throttling to latency-focused value', 'Keep channel width on Auto') }
        'Download / Streaming' { @('Enable Wi-Fi background scanning', 'Restore standard TCP behavior', 'Enable IPv4 Large Send Offload', 'Set channel width to Auto') }
        'Custom' { @('Keep current latency and Wi-Fi settings', 'Apply only the selected channel width') }
        default { throw "Unknown profile: $Name" }
    }
    [ordered]@{ profile = $Name; changes = @($changes); note = 'IPv4 remains enabled. LSO is a separate adapter offload feature. A versioned backup is created before applying changes.' }
}

function Set-NetSnipeProfile {
    param([string]$Name, [string]$Width = 'Auto', [string]$CustomSettingsJson = '')
    $context = Get-NetSnipeContext
    $backup = Backup-NetSnipeCurrentConfig -Reason "Before applying profile: $Name"
    $changes = [ordered]@{ profile = $Name; backup = $context.BackupFile; actions = @(); bandwidth = $null }
    try {
        switch ($Name) {
            'Balanced' { if (Invoke-NetSnipeNetsh -Arguments @('wlan', 'set', 'autoconfig', 'enabled=yes', "interface=$($context.AdapterName)") -Description 'Enable Wi-Fi background scanning') { $changes.actions += 'Background scanning enabled' } }
            'Lowest Ping' { if (Invoke-NetSnipeNetsh -Arguments @('wlan', 'set', 'autoconfig', 'enabled=no', "interface=$($context.AdapterName)") -Description 'Disable Wi-Fi background scanning') { $changes.actions += 'Background scanning disabled' } }
            'Gaming Balanced' { if (Invoke-NetSnipeNetsh -Arguments @('wlan', 'set', 'autoconfig', 'enabled=yes', "interface=$($context.AdapterName)") -Description 'Keep Wi-Fi background scanning enabled') { $changes.actions += 'Background scanning kept enabled' } }
            'Download / Streaming' { if (Invoke-NetSnipeNetsh -Arguments @('wlan', 'set', 'autoconfig', 'enabled=yes', "interface=$($context.AdapterName)") -Description 'Enable Wi-Fi background scanning') { $changes.actions += 'Background scanning enabled' } }
            'Custom' {
                if ([string]::IsNullOrWhiteSpace($CustomSettingsJson)) { throw 'Custom profile settings were not provided.' }
                $settings = $CustomSettingsJson | ConvertFrom-Json
                $wifiScanning = [bool]$settings.wifiScanning
                $scanState = if ($wifiScanning) { 'yes' } else { 'no' }
                if (Invoke-NetSnipeNetsh -Arguments @('wlan', 'set', 'autoconfig', "enabled=$scanState", "interface=$($context.AdapterName)") -Description "Set Wi-Fi background scanning: $scanState") { $changes.actions += "Wi-Fi background scanning: $wifiScanning" }
            }
            default { throw "Unknown profile: $Name" }
        }
        $path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        $adapter = Get-NetAdapter -Name $context.AdapterName -ErrorAction Stop
        $interfacePath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.InterfaceGuid)"
        if (-not (Test-Path $interfacePath)) { New-Item -Path $interfacePath -Force | Out-Null }
        if ($Name -in @('Lowest Ping', 'Gaming Balanced')) {
            Set-ItemProperty -Path $path -Name NetworkThrottlingIndex -Value 0xffffffff -Type DWord -ErrorAction Stop
            Set-ItemProperty -Path $interfacePath -Name TcpAckFrequency -Value 1 -Type DWord -ErrorAction Stop
            Set-ItemProperty -Path $interfacePath -Name TCPNoDelay -Value 1 -Type DWord -ErrorAction Stop
            try { Disable-NetAdapterLso -Name $context.AdapterName -IPv4 -ErrorAction Stop } catch { }
            $changes.actions += 'TCP latency settings applied'; $changes.actions += 'IPv4 Large Send Offload disabled'
        } elseif ($Name -eq 'Custom') {
            $settings = $CustomSettingsJson | ConvertFrom-Json
            if ([bool]$settings.tcpAckFrequency) { Set-ItemProperty -Path $interfacePath -Name TcpAckFrequency -Value 1 -Type DWord -ErrorAction Stop } else { Remove-ItemProperty -Path $interfacePath -Name TcpAckFrequency -ErrorAction SilentlyContinue }
            if ([bool]$settings.tcpNoDelay) { Set-ItemProperty -Path $interfacePath -Name TCPNoDelay -Value 1 -Type DWord -ErrorAction Stop } else { Remove-ItemProperty -Path $interfacePath -Name TCPNoDelay -ErrorAction SilentlyContinue }
            if ([bool]$settings.multimediaThrottling) { Set-ItemProperty -Path $path -Name NetworkThrottlingIndex -Value 0xffffffff -Type DWord -ErrorAction Stop } else { Set-ItemProperty -Path $path -Name NetworkThrottlingIndex -Value 10 -Type DWord -ErrorAction Stop }
            if ([bool]$settings.lsoIPv4) { try { Enable-NetAdapterLso -Name $context.AdapterName -IPv4 -ErrorAction Stop } catch { } } else { try { Disable-NetAdapterLso -Name $context.AdapterName -IPv4 -ErrorAction Stop } catch { } }
            $changes.actions += "TcpAckFrequency: $([bool]$settings.tcpAckFrequency)"; $changes.actions += "TCPNoDelay: $([bool]$settings.tcpNoDelay)"; $changes.actions += "IPv4 LSO: $([bool]$settings.lsoIPv4)"; $changes.actions += "Multimedia throttling: $([bool]$settings.multimediaThrottling)"
        } else {
            Set-ItemProperty -Path $path -Name NetworkThrottlingIndex -Value 10 -Type DWord -ErrorAction Stop
            Remove-ItemProperty -Path $interfacePath -Name TcpAckFrequency -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $interfacePath -Name TCPNoDelay -ErrorAction SilentlyContinue
            try { Enable-NetAdapterLso -Name $context.AdapterName -IPv4 -ErrorAction Stop } catch { }
            $changes.actions += 'Standard TCP behavior restored'; $changes.actions += 'IPv4 Large Send Offload enabled'
        }
        $changes.bandwidth = Set-NetSnipeBandwidth -Width $(if ($Name -eq 'Custom') { $Width } else { 'Auto' })
        Write-NetSnipeChangeHistory -Action "Apply profile: $Name" -Result 'OK' -Details ($changes | ConvertTo-Json -Compress -Depth 8)
        return $changes
    } catch {
        Write-NetSnipeChangeHistory -Action "Apply profile: $Name" -Result 'Failed' -Details $_.Exception.Message
        throw
    }
}

function Enable-NetSnipeWifiScanning {
    $context = Get-NetSnipeContext
    $backup = Backup-NetSnipeCurrentConfig -Reason 'Before restoring Wi-Fi background scanning'
    if (-not (Invoke-NetSnipeNetsh -Arguments @('wlan', 'set', 'autoconfig', 'enabled=yes', "interface=$($context.AdapterName)") -Description 'Restore Wi-Fi background scanning')) { throw 'Windows could not enable Wi-Fi background scanning.' }
    $result = [ordered]@{ action = 'Restore Wi-Fi scanning'; adapter = $context.AdapterName; backup = $context.BackupFile; enabled = $true }
    Write-NetSnipeChangeHistory -Action 'Restore Wi-Fi background scanning' -Result 'OK' -Details ($result | ConvertTo-Json -Compress)
    return $result
}

function Invoke-NetSnipeOptimizeProfile {
    param([string]$Name, [int]$Seconds = 15)
    $before = Get-NetSnipeMeasurements -Seconds $Seconds
    $applied = Set-NetSnipeProfile -Name $Name
    $after = Get-NetSnipeMeasurements -Seconds $Seconds
    $repeat = Get-NetSnipeMeasurements -Seconds $Seconds
    [ordered]@{ profile = $Name; before = $before; after = $after; repeat = $repeat; applied = $applied; comparison = Compare-NetSnipeMeasurements -Before $before -After $after; repeat_comparison = Compare-NetSnipeMeasurements -Before $before -After $repeat; rollback_available = $true; rollback_action = 'RestoreLatest' }
}

Export-ModuleMember -Function Set-NetSnipeBandwidth, Get-NetSnipeProfilePreview, Set-NetSnipeProfile, Invoke-NetSnipeOptimizeProfile, Enable-NetSnipeWifiScanning
