$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$moduleNames = @(
    'NetSnipe.Core.psm1', 'NetSnipe.Targets.psm1', 'NetSnipe.Backup.psm1', 'NetSnipe.Adapter.psm1',
    'NetSnipe.Ping.psm1', 'NetSnipe.Dns.psm1', 'NetSnipe.Bufferbloat.psm1', 'NetSnipe.Profiles.psm1',
    'NetSnipe.Monitor.psm1', 'NetSnipe.Menu.psm1'
)
foreach ($moduleName in $moduleNames) { Import-Module (Join-Path (Join-Path $root 'backend') $moduleName) -Force }
$testDataRoot = Join-Path ([IO.Path]::GetTempPath()) "NetSnipeSmoke_$PID"
Initialize-NetSnipeContext -Root $root -DataRoot $testDataRoot -JsonOutput:$true -ScriptPath (Join-Path $root 'NetSnipe.ps1') | Out-Null
Initialize-NetSnipeAdapter
$status = Get-NetSnipeStatusSnapshot
$preview = Get-NetSnipeProfilePreview -Name 'Gaming Balanced'
$targets = Get-NetSnipeTargetsAction
$measurement = Test-NetSnipeTarget -Target $status.gateway -Seconds 5 -Rate 1
if (-not $status.adapter) { throw 'Adapter snapshot did not return an adapter.' }
if (-not $preview.changes.Count) { throw 'Profile preview did not return changes.' }
if ($null -eq $targets.targets) { throw 'Target action did not return a target collection.' }
if ($measurement.sent -lt 1) { throw 'Ping smoke test did not send a packet.' }
[ordered]@{ status = 'OK'; adapter = $status.adapter; gateway = $status.gateway; profile_preview = 'OK'; ping_sent = $measurement.sent; targets = @($targets.targets).Count } | ConvertTo-Json -Compress
