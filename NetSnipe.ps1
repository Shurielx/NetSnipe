<#
.SYNOPSIS
    NetSnipe backend entrypoint.
.DESCRIPTION
    Loads domain modules and exposes one JSON action contract to the CLI and GUI.
    The script is intentionally thin; network and profile logic lives in backend/*.psm1.
#>
#Requires -RunAsAdministrator

param(
    [ValidateSet('Menu','Status','Diagnostics','PingTest','GamingPreview','BandwidthRecommendation','RestoreLatest','RestoreWifiScanning','ApplyProfile','OptimizeProfile','ProfilePreview','DnsTest','Bufferbloat','StartMonitor','StopMonitor','MonitorStatus','MonitorLatest','Monitor','ListTargets','AddTarget','RemoveTarget')]
    [string]$Action = 'Menu',
    [switch]$JsonOutput,
    [string]$DataRoot = '',
    [ValidateRange(15,900)] [int]$DiagnosticSeconds = 60,
    [ValidateRange(5,900)] [int]$PingSeconds = 30,
    [ValidateRange(1,10)] [int]$PingRate = 2,
    [string]$PingTarget = '',
    [ValidateRange(5,50)] [int]$BufferbloatDownloadMb = 10,
    [ValidateRange(10,90)] [int]$BufferbloatSeconds = 90,
    [ValidateSet('Balanced','Lowest Ping','Gaming Balanced','Download / Streaming','Custom')]
    [string]$Profile = 'Balanced',
    [ValidateSet('Auto','20','40','80','160')]
    [string]$ChannelWidth = 'Auto',
    [string]$TargetName = '',
    [string]$TargetAddress = '',
    [string]$TargetId = '',
    [string]$CustomSettingsJson = ''
)

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) { $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$moduleRoot = Join-Path $scriptRoot 'backend'
$moduleNames = @(
    'NetSnipe.Core.psm1', 'NetSnipe.Targets.psm1', 'NetSnipe.Backup.psm1', 'NetSnipe.Adapter.psm1',
    'NetSnipe.Ping.psm1', 'NetSnipe.Dns.psm1', 'NetSnipe.Bufferbloat.psm1', 'NetSnipe.Profiles.psm1',
    'NetSnipe.Monitor.psm1', 'NetSnipe.Menu.psm1'
)
foreach ($moduleName in $moduleNames) {
    $modulePath = Join-Path $moduleRoot $moduleName
    if (-not (Test-Path -LiteralPath $modulePath)) { throw "Backend module not found: $modulePath" }
    Import-Module -Name $modulePath -Force
}

$resolvedDataRoot = $DataRoot
if ([string]::IsNullOrWhiteSpace($resolvedDataRoot)) {
    $localAppData = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
    $resolvedDataRoot = Join-Path $localAppData 'NetSnipe'
}
$context = Initialize-NetSnipeContext -Root $scriptRoot -DataRoot $resolvedDataRoot -JsonOutput:$JsonOutput -ScriptPath $PSCommandPath
$context.PingRate = $PingRate
$context.PingSeconds = $PingSeconds
Initialize-NetSnipeAdapter

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($Action -eq 'Menu') { Write-Host '[FAIL] NetSnipe must run as Administrator. Use run.bat.' }
    else { Write-Output (@{ success = $false; action = $Action; error = 'Administrator privileges are required.' } | ConvertTo-Json -Compress) }
    exit 1
}

if (-not (Get-NetSnipeBackupFiles)) { Backup-NetSnipeCurrentConfig -Reason 'Automatic first-run baseline' | Out-Null }

function Invoke-NetSnipeJsonAction {
    param([string]$RequestedAction)
    $result = [ordered]@{ action = $RequestedAction; success = $true; timestamp = (Get-Date -Format 'o'); data = $null; error = $null }
    try {
        switch ($RequestedAction) {
            'Status' { $result.data = Get-NetSnipeStatusSnapshot }
            'Diagnostics' { $result.data = Invoke-NetSnipeDiagnostics -Seconds $DiagnosticSeconds }
            'PingTest' { $result.data = Invoke-NetSnipePingTest -Target $PingTarget }
            'DnsTest' { $result.data = Invoke-NetSnipeDnsTest }
            'Bufferbloat' { $result.data = Invoke-NetSnipeBufferbloat -DownloadMb $BufferbloatDownloadMb -MaximumSeconds $BufferbloatSeconds }
            'BandwidthRecommendation' { $result.data = Get-NetSnipeBandwidthRecommendation }
            'GamingPreview' { $result.data = Get-NetSnipeProfilePreview -Name 'Gaming Balanced' }
            'ProfilePreview' { $result.data = Get-NetSnipeProfilePreview -Name $Profile }
            'ApplyProfile' { $result.data = Set-NetSnipeProfile -Name $Profile -Width $ChannelWidth }
            'RestoreWifiScanning' { $result.data = Enable-NetSnipeWifiScanning }
            'OptimizeProfile' { $result.data = Invoke-NetSnipeOptimizeProfile -Name $Profile -Seconds $DiagnosticSeconds }
            'RestoreLatest' { $result.data = Restore-NetSnipeCurrentConfig }
            'StartMonitor' { $result.data = Start-NetSnipeMonitor }
            'StopMonitor' { $result.data = Stop-NetSnipeMonitor }
            'MonitorStatus' { $result.data = Get-NetSnipeMonitorStatus }
            'MonitorLatest' { $result.data = Get-NetSnipeMonitorLatest }
            'ListTargets' { $result.data = Get-NetSnipeTargetsAction }
            'AddTarget' { $result.data = Add-NetSnipeTarget -Name $TargetName -Address $TargetAddress }
            'RemoveTarget' { $result.data = Remove-NetSnipeTarget -Id $TargetId }
            default { throw "Unsupported action: $RequestedAction" }
        }
    } catch {
        $result.success = $false
        $result.error = $_.Exception.Message
    }
    if ($RequestedAction -ne 'Status' -or $result.success) { Write-NetSnipeReport -Action $RequestedAction -Result $result }
    $result | ConvertTo-Json -Depth 14 -Compress
}

if ($Action -eq 'Monitor') {
    Invoke-NetSnipeMonitor
    exit 0
}

if ($Action -eq 'Menu') {
    Show-NetSnipeMenu
} else {
    Invoke-NetSnipeJsonAction -RequestedAction $Action
}
