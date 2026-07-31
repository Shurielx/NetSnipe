<#!
.SYNOPSIS
    Builds the distributable NetSnipe artifacts.
#>
[CmdletBinding()]
param(
    [switch]$SkipWebView2Download,
    [switch]$SkipInstaller,
    [switch]$SkipPortable,
    [ValidateSet('Main', 'Beta', 'Dev')]
    [string]$Channel,
    [string]$Version = '1.1'
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$branch = (& git -C $root branch --show-current 2>$null).Trim()
if ([string]::IsNullOrWhiteSpace($Channel)) {
    $Channel = switch ($branch) {
        'main' { 'Main' }
        'beta' { 'Beta' }
        'dev' { 'Dev' }
        default { 'Dev' }
    }
}

$channelInfo = @{
    Main = @{ Code = 'V'; Label = 'Main'; AppId = '{B8B1A8B2-4D9F-4B91-8F39-2A4D6E3C1D72}' }
    Beta = @{ Code = 'B'; Label = 'Beta'; AppId = '{C9C2B9C3-5E0A-4C92-9F40-3B5E7F4D2E83}' }
    Dev  = @{ Code = 'D'; Label = 'Dev';  AppId = '{DAD3CAD4-6F1B-4DA3-A051-4C6F805E3F94}' }
}[$Channel]
$buildVersion = "$($channelInfo.Code)$Version"
$displayName = "NetSnipe $buildVersion - $($channelInfo.Label)"
$channelLabel = $channelInfo.Label
$filePrefix = "NetSnipe-$buildVersion"
$frontend = Join-Path $root 'NetSnipe.UI\Frontend'
$project = Join-Path $root 'NetSnipe.UI\NetSnipe.UI.csproj'
$artifacts = Join-Path $root 'artifacts'
$publish = Join-Path $artifacts 'publish'
$portable = Join-Path $artifacts 'portable'
$installerInput = Join-Path $artifacts 'prerequisites'
$installerOutput = Join-Path $artifacts 'installer'

function Invoke-Step {
    param([string]$FilePath, [string[]]$ArgumentList)
    & $FilePath @ArgumentList
    if ($LASTEXITCODE -ne 0) { throw "Command failed with exit code ${LASTEXITCODE}: $FilePath" }
}

if (-not (Test-Path -LiteralPath (Join-Path $frontend 'node_modules'))) {
    throw 'Frontend dependencies are missing. Run setup-dev.bat first.'
}

Remove-Item -LiteralPath $artifacts -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $artifacts, $publish, $portable, $installerInput, $installerOutput -Force | Out-Null

Write-Host '[1/4] Building frontend...'
$env:VITE_NETSNIPE_VERSION = $filePrefix.Replace('NetSnipe-', '')
Invoke-Step 'npm.cmd' @('--prefix', $frontend, 'run', 'build')

Write-Host '[2/4] Publishing self-contained Windows x64 application...'
Invoke-Step 'dotnet' @('publish', $project, '--configuration', 'Release', '--runtime', 'win-x64', '--self-contained', 'true', '-p:PublishSingleFile=false', '-p:PublishTrimmed=false', '-p:DebugType=None', '-o', $publish)

if (-not $SkipPortable) {
    Write-Host '[3/4] Creating portable ZIP...'
    Copy-Item -Path (Join-Path $publish '*') -Destination $portable -Recurse -Force
    $portableZip = Join-Path $artifacts "$filePrefix-Portable-win-x64.zip"
    Compress-Archive -Path (Join-Path $portable '*') -DestinationPath $portableZip -CompressionLevel Optimal -Force
} else {
    Write-Host '[3/4] Skipping portable ZIP.'
}

if (-not $SkipWebView2Download) {
    $webView2Installer = Join-Path $installerInput 'MicrosoftEdgeWebView2RuntimeInstallerX64.exe'
    if (-not (Test-Path -LiteralPath $webView2Installer)) {
        Write-Host '[4/4] Downloading WebView2 Runtime installer...'
        Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' -OutFile $webView2Installer
    }
} else {
    Write-Host '[4/4] Skipping WebView2 Runtime download.'
}

if (-not $SkipInstaller) {
    $iscc = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
    if ($null -eq $iscc) {
        $knownCompilerPaths = @(
            (Join-Path ${env:ProgramFiles} 'Inno Setup 6\ISCC.exe'),
            (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
            (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
            (Join-Path ${env:ProgramFiles} 'Inno Setup 7\ISCC.exe')
        ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
        if ($knownCompilerPaths.Count -gt 0) {
            $iscc = Get-Item -LiteralPath $knownCompilerPaths[0]
        }
    }
    if ($null -eq $iscc) {
        Write-Warning 'ISCC.exe was not found. Portable ZIP was created; install Inno Setup and rerun this script for the installer EXE.'
    } else {
        $compilerPath = if ($iscc.PSIsContainer) { $iscc.FullName } else { $iscc.Source }
        if ([string]::IsNullOrWhiteSpace($compilerPath)) { $compilerPath = $iscc.FullName }
        $appId = $channelInfo.AppId.Trim('{}')
        & $compilerPath (Join-Path $root 'installer\NetSnipe.iss') "/DMyAppName=$displayName" "/DMyAppChannel=$channelLabel" "/DMyAppVersion=$Version" "/DMyAppId={{$appId}}" "/DMyOutputBaseFilename=$filePrefix-Setup-win-x64"
        if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed with exit code ${LASTEXITCODE}." }
    }
}

Write-Host ''
Write-Host "Build channel: $displayName"
Write-Host 'Release artifacts:'
Get-ChildItem -LiteralPath $artifacts -File -Recurse | Select-Object FullName, Length
