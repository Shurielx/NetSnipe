function Show-NetSnipeMenu {
    $color = 'Cyan'
    do {
        Clear-Host
        $snapshot = Get-NetSnipeStatusSnapshot
        Write-Host '=================================================================' -ForegroundColor $color
        Write-Host ' NetSnipe - local network diagnostics' -ForegroundColor $color
        Write-Host " Adapter: $($snapshot.adapter) | Gateway: $($snapshot.gateway)" -ForegroundColor $color
        Write-Host '=================================================================' -ForegroundColor $color
        Write-Host ' [1] Status snapshot'
        Write-Host ' [2] One-time diagnostics'
        Write-Host ' [3] Custom ping'
        Write-Host ' [4] DNS resolution test'
        Write-Host ' [5] Bufferbloat test'
        Write-Host ' [6] Apply profile'
        Write-Host ' [7] Start monitor'
        Write-Host ' [8] Stop monitor'
        Write-Host ' [B] Create backup'
        Write-Host ' [R] Restore latest backup'
        Write-Host ' [Q] Quit'
        $choice = Read-Host ' Choice'
        switch ($choice.ToUpperInvariant()) {
            '1' { $snapshot | ConvertTo-Json -Depth 6 | Write-Host; Read-Host 'Press Enter' | Out-Null }
            '2' { $seconds = Read-Host 'Total seconds (default 60)'; if (-not $seconds) { $seconds = 60 }; Invoke-NetSnipeDiagnostics -Seconds ([int]$seconds) | ConvertTo-Json -Depth 10 | Write-Host; Read-Host 'Press Enter' | Out-Null }
            '3' { $target = Read-Host 'Hostname or IP'; $rate = Read-Host 'Pings per second (default 2)'; $seconds = Read-Host 'Duration seconds (default 30)'; $context = Get-NetSnipeContext; $context.PingRate = if ($rate) { [int]$rate } else { 2 }; $context.PingSeconds = if ($seconds) { [int]$seconds } else { 30 }; Invoke-NetSnipePingTest -Target $target | ConvertTo-Json -Depth 10 | Write-Host; Read-Host 'Press Enter' | Out-Null }
            '4' { Invoke-NetSnipeDnsTest | ConvertTo-Json -Depth 10 | Write-Host; Read-Host 'Press Enter' | Out-Null }
            '5' { Invoke-NetSnipeBufferbloat | ConvertTo-Json -Depth 10 | Write-Host; Read-Host 'Press Enter' | Out-Null }
            '6' { $profile = Read-Host 'Balanced, Gaming Balanced, Lowest Ping or Download / Streaming'; $preview = Get-NetSnipeProfilePreview -Name $profile; $preview | ConvertTo-Json -Depth 6 | Write-Host; $yes = Read-Host 'Apply? (Y/N)'; if ($yes -eq 'Y') { Set-NetSnipeProfile -Name $profile | ConvertTo-Json -Depth 10 | Write-Host }; Read-Host 'Press Enter' | Out-Null }
            '7' { Start-NetSnipeMonitor | ConvertTo-Json -Depth 6 | Write-Host; Read-Host 'Press Enter' | Out-Null }
            '8' { Stop-NetSnipeMonitor | ConvertTo-Json -Depth 6 | Write-Host; Read-Host 'Press Enter' | Out-Null }
            'B' { Backup-NetSnipeCurrentConfig -Reason 'Manual backup' | Out-Null; Write-Host 'Backup created.'; Read-Host 'Press Enter' | Out-Null }
            'R' { Restore-NetSnipeCurrentConfig | ConvertTo-Json -Depth 6 | Write-Host; Read-Host 'Press Enter' | Out-Null }
        }
    } while ($choice.ToUpperInvariant() -ne 'Q')
}

Export-ModuleMember -Function Show-NetSnipeMenu
