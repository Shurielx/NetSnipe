function Get-NetSnipeBackupFiles {
    $context = Get-NetSnipeContext
    if (-not (Test-Path -LiteralPath $context.BackupDir)) { return @() }
    @(Get-ChildItem -LiteralPath $context.BackupDir -Filter 'backup_*.json' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
}

function Remove-NetSnipeOldBackups {
    $context = Get-NetSnipeContext
    $files = @(Get-NetSnipeBackupFiles)
    if ($files.Count -gt $context.MaxBackups) { $files | Select-Object -Skip $context.MaxBackups | Remove-Item -Force -ErrorAction SilentlyContinue }
}

function Backup-NetSnipeCurrentConfig {
    param([string]$Reason = 'Manual backup')
    $context = Get-NetSnipeContext
    $backup = [ordered]@{
        backup_date = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        reason = $Reason
        adapter_name = $context.AdapterName
        adapter_properties = @()
        registry = @{}
        autoconfig_enabled = $null
        lso_ipv4_enabled = $null
    }
    try {
        $properties = @(Get-NetAdapterAdvancedProperty -Name $context.AdapterName -ErrorAction Stop)
        foreach ($property in $properties) {
            $backup.adapter_properties += [ordered]@{ RegistryKeyword = $property.RegistryKeyword; DisplayName = $property.DisplayName; DisplayValue = $property.DisplayValue; RegistryValue = $property.RegistryValue }
        }
    } catch { }

    $globalPaths = @{
        NetworkThrottlingIndex = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
    }
    foreach ($key in $globalPaths.Keys) {
        try { $value = Get-ItemProperty -Path $globalPaths[$key] -Name $key -ErrorAction Stop; $backup.registry[$key] = $value.$key } catch { $backup.registry[$key] = $null }
    }
    try {
        $adapter = Get-NetAdapter -Name $context.AdapterName -ErrorAction Stop
        $interfacePath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.InterfaceGuid)"
        $backup.registry.InterfaceGuid = [string]$adapter.InterfaceGuid
        foreach ($key in @('TcpAckFrequency', 'TCPNoDelay')) {
            try { $value = Get-ItemProperty -Path $interfacePath -Name $key -ErrorAction Stop; $backup.registry["${key}_Interface"] = $value.$key } catch { $backup.registry["${key}_Interface"] = $null }
        }
    } catch { }
    try {
        $wlan = netsh wlan show interfaces
        $autoLine = $wlan | Select-String 'Auto configuration'
        $backup.autoconfig_enabled = $autoLine -match 'Yes'
    } catch { }
    try {
        $lso = @(Get-NetAdapterLso -Name $context.AdapterName -ErrorAction Stop | Where-Object { $_.IPv4Enabled -ne $null } | Select-Object -First 1)
        if ($lso.Count) { $backup.lso_ipv4_enabled = [bool]$lso[0].IPv4Enabled }
    } catch { }

    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
    $path = Join-Path $context.BackupDir "backup_${stamp}.json"
    $backup | ConvertTo-Json -Depth 8 | Out-File -LiteralPath $path -Encoding utf8 -Force
    Copy-Item -LiteralPath $path -Destination $context.BackupFile -Force
    Remove-NetSnipeOldBackups
    return $backup
}

function Invoke-NetSnipeNetsh {
    param([string[]]$Arguments, [string]$Description)
    & netsh @Arguments 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-NetSnipeChangeHistory -Action $Description -Result 'Failed' -Details "ExitCode=$LASTEXITCODE"
        return $false
    }
    Write-NetSnipeChangeHistory -Action $Description -Result 'OK'
    return $true
}

function Restore-NetSnipeCurrentConfig {
    param([string]$SelectedBackupFile)
    $context = Get-NetSnipeContext
    if ([string]::IsNullOrWhiteSpace($SelectedBackupFile)) { $SelectedBackupFile = (Get-NetSnipeBackupFiles | Select-Object -First 1).FullName }
    if (-not $SelectedBackupFile -or -not (Test-Path -LiteralPath $SelectedBackupFile)) { throw 'No backup available.' }
    $backup = Get-Content -LiteralPath $SelectedBackupFile -Raw -Encoding utf8 | ConvertFrom-Json

    foreach ($property in @($backup.adapter_properties)) {
        try { Set-NetAdapterAdvancedProperty -Name $context.AdapterName -RegistryKeyword $property.RegistryKeyword -RegistryValue $property.RegistryValue -ErrorAction Stop | Out-Null } catch { }
    }
    if ($null -ne $backup.registry.NetworkThrottlingIndex) {
        $path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
        Set-ItemProperty -Path $path -Name NetworkThrottlingIndex -Value $backup.registry.NetworkThrottlingIndex -Type DWord -ErrorAction SilentlyContinue
    }
    $guid = $backup.registry.InterfaceGuid
    if ($guid) {
        $interfacePath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid"
        foreach ($key in @('TcpAckFrequency', 'TCPNoDelay')) {
            $backupKey = "${key}_Interface"
            if ($backup.registry.PSObject.Properties.Name -contains $backupKey) {
                if ($null -eq $backup.registry.$backupKey) { Remove-ItemProperty -Path $interfacePath -Name $key -ErrorAction SilentlyContinue }
                else { Set-ItemProperty -Path $interfacePath -Name $key -Value $backup.registry.$backupKey -Type DWord -ErrorAction SilentlyContinue }
            }
        }
    }
    if ($null -ne $backup.autoconfig_enabled) {
        $state = if ($backup.autoconfig_enabled) { 'yes' } else { 'no' }
        Invoke-NetSnipeNetsh -Arguments @('wlan', 'set', 'autoconfig', "enabled=$state", "interface=$($context.AdapterName)") -Description "Restore Wi-Fi autoconfig ($state)" | Out-Null
    }
    if ($null -ne $backup.lso_ipv4_enabled) {
        try {
            if ($backup.lso_ipv4_enabled) { Enable-NetAdapterLso -Name $context.AdapterName -IPv4 -ErrorAction Stop }
            else { Disable-NetAdapterLso -Name $context.AdapterName -IPv4 -ErrorAction Stop }
        } catch { }
    }
    [ordered]@{ restored = $true; file = $SelectedBackupFile }
}

Export-ModuleMember -Function Get-NetSnipeBackupFiles, Remove-NetSnipeOldBackups, Backup-NetSnipeCurrentConfig, Invoke-NetSnipeNetsh, Restore-NetSnipeCurrentConfig
