<#!
.SYNOPSIS
    Builds the distributable NetSnipe artifacts.
#>
[CmdletBinding()]
param(
    [switch]$SkipWebView2Download,
    [switch]$SkipInstaller
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
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
Invoke-Step 'npm.cmd' @('--prefix', $frontend, 'run', 'build')

Write-Host '[2/4] Publishing self-contained Windows x64 application...'
Invoke-Step 'dotnet' @('publish', $project, '--configuration', 'Release', '--runtime', 'win-x64', '--self-contained', 'true', '-p:PublishSingleFile=false', '-p:PublishTrimmed=false', '-p:DebugType=None', '-o', $publish)

Write-Host '[3/4] Creating portable ZIP...'
Copy-Item -Path (Join-Path $publish '*') -Destination $portable -Recurse -Force
$portableZip = Join-Path $artifacts 'NetSnipe-Portable-win-x64.zip'
Compress-Archive -Path (Join-Path $portable '*') -DestinationPath $portableZip -CompressionLevel Optimal -Force

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
        Write-Warning 'ISCC.exe was not found. Portable ZIP was created; install Inno Setup and rerun this script for the installer EXE.'
    } else {
        & $iscc.Source (Join-Path $root 'installer\NetSnipe.iss')
        if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed with exit code ${LASTEXITCODE}." }
    }
}

Write-Host ''
Write-Host 'Release artifacts:'
Get-ChildItem -LiteralPath $artifacts -File -Recurse | Select-Object FullName, Length
