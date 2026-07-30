function Get-NetSnipeSavedTargets {
    $context = Get-NetSnipeContext
    if (-not (Test-Path -LiteralPath $context.TargetsFile)) { return @() }
    try {
        $items = @(Get-Content -LiteralPath $context.TargetsFile -Raw -Encoding utf8 | ConvertFrom-Json)
        return @($items | ForEach-Object { [ordered]@{ id = [string]$_.id; name = [string]$_.name; address = [string]$_.address } })
    } catch { return @() }
}

function Save-NetSnipeTargets {
    param([array]$Targets)
    $context = Get-NetSnipeContext
    @($Targets) | ConvertTo-Json -Depth 4 | Out-File -LiteralPath $context.TargetsFile -Encoding utf8 -Force
}

function Get-NetSnipeTargetsAction {
    [ordered]@{ targets = @(Get-NetSnipeSavedTargets); file = (Get-NetSnipeContext).TargetsFile }
}

function Add-NetSnipeTarget {
    param([string]$Name, [string]$Address)
    if ([string]::IsNullOrWhiteSpace($Name)) { throw 'Target name is required.' }
    if ([string]::IsNullOrWhiteSpace($Address)) { throw 'Target hostname or IP address is required.' }
    if ($Address.Length -gt 253 -or $Name.Length -gt 80) { throw 'Target name or address is too long.' }
    $targets = @(Get-NetSnipeSavedTargets | Where-Object { $_.address -ne $Address.Trim() })
    $targets += [ordered]@{ id = [guid]::NewGuid().ToString('N'); name = $Name.Trim(); address = $Address.Trim() }
    Save-NetSnipeTargets -Targets $targets
    [ordered]@{ targets = @($targets); saved = $true }
}

function Remove-NetSnipeTarget {
    param([string]$Id)
    $targets = @(Get-NetSnipeSavedTargets | Where-Object { $_.id -ne $Id })
    Save-NetSnipeTargets -Targets $targets
    [ordered]@{ targets = @($targets); removed = $true }
}

Export-ModuleMember -Function Get-NetSnipeSavedTargets, Save-NetSnipeTargets, Get-NetSnipeTargetsAction, Add-NetSnipeTarget, Remove-NetSnipeTarget
