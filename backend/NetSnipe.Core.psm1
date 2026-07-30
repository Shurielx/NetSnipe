Set-StrictMode -Version Latest

$script:NetSnipeContext = $null

function Initialize-NetSnipeContext {
    param(
        [Parameter(Mandatory)][string]$Root,
        [string]$DataRoot = $Root,
        [switch]$JsonOutput,
        [Parameter(Mandatory)][string]$ScriptPath
    )

    $context = [pscustomobject]@{
        Root = $Root
        ScriptPath = $ScriptPath
        JsonOutput = [bool]$JsonOutput
        DataRoot = $DataRoot
        LogDir = Join-Path $DataRoot 'logs'
        BackupDir = Join-Path $DataRoot 'backups'
        ReportDir = Join-Path $DataRoot 'reports'
        DataDir = Join-Path $DataRoot 'data'
        BackupFile = Join-Path $DataRoot 'backup_config.json'
        HistoryFile = Join-Path $DataRoot 'logs\changes.jsonl'
        MonitorPidFile = Join-Path $DataRoot 'logs\monitor.pid'
        MonitorLog = Join-Path $DataRoot 'logs\monitor.jsonl'
        TargetsFile = Join-Path $DataRoot 'data\targets.json'
        MaxBackups = 30
        AdapterName = $null
        AdapterSelectionReason = $null
        PingRate = 2
        PingSeconds = 30
    }
    foreach ($directory in @($context.LogDir, $context.BackupDir, $context.ReportDir, $context.DataDir)) {
        if (-not (Test-Path -LiteralPath $directory)) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
    }
    $script:NetSnipeContext = $context
    return $context
}

function Get-NetSnipeContext { return $script:NetSnipeContext }

function Write-NetSnipeProgress {
    param(
        [string]$Action,
        [string]$Target,
        [double]$ElapsedSeconds,
        [int]$TotalSeconds,
        [int]$Sent,
        [int]$Received,
        [int]$Lost,
        [Nullable[double]]$LastLatency
    )
    $context = Get-NetSnipeContext
    if (-not $context.JsonOutput) { return }
    $payload = [ordered]@{
        action = $Action
        target = $Target
        elapsed_seconds = [math]::Round($ElapsedSeconds, 1)
        total_seconds = $TotalSeconds
        sent = $Sent
        received = $Received
        lost = $Lost
        loss_percent = if ($Sent) { [math]::Round(($Lost / $Sent) * 100, 2) } else { 0 }
        last_latency_ms = $LastLatency
    }
    [Console]::Out.WriteLine('NETSNIPE_PROGRESS ' + ($payload | ConvertTo-Json -Compress))
    [Console]::Out.Flush()
}

function Write-NetSnipeChangeHistory {
    param([string]$Action, [string]$Result, [string]$Details = '')
    $context = Get-NetSnipeContext
    $entry = [ordered]@{ date = (Get-Date -Format 'o'); action = $Action; result = $Result; details = $Details }
    ($entry | ConvertTo-Json -Compress) | Out-File -FilePath $context.HistoryFile -Append -Encoding utf8
}

function Write-NetSnipeReport {
    param([string]$Action, [System.Collections.IDictionary]$Result)
    $context = Get-NetSnipeContext
    $json = $Result | ConvertTo-Json -Depth 12
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
    $jsonPath = Join-Path $context.ReportDir "report_${Action}_${stamp}.json"
    $htmlPath = Join-Path $context.ReportDir "report_${Action}_${stamp}.html"
    $json | Out-File -FilePath $jsonPath -Encoding utf8
    $safeHtml = [System.Net.WebUtility]::HtmlEncode($json)
    "<html><head><meta charset='utf-8'><title>NetSnipe $Action</title><style>body{font-family:Segoe UI;background:#0a1016;color:#e9f2f8;padding:24px}pre{white-space:pre-wrap;background:#111d27;padding:18px;border-radius:8px}</style></head><body><h1>NetSnipe - $Action</h1><pre>$safeHtml</pre></body></html>" | Out-File -FilePath $htmlPath -Encoding utf8
    $Result.report_json = $jsonPath
    $Result.report_html = $htmlPath
}

function Get-NetSnipeNumber {
    param($Value, [double]$Fallback = 0)
    if ($null -eq $Value) { return $Fallback }
    try { return [double]$Value } catch { return $Fallback }
}

Export-ModuleMember -Function Initialize-NetSnipeContext, Get-NetSnipeContext, Write-NetSnipeProgress, Write-NetSnipeChangeHistory, Write-NetSnipeReport, Get-NetSnipeNumber
