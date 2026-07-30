@echo off
setlocal enabledelayedexpansion

title NetSnipe - Network Diagnostics, Testing ^& Optimization Suite

set "MODE=%~1"
if "%MODE%"=="" set "MODE=auto"

:: ─── Self-Elevate to Administrator ──────────────────────────────────────────
:: Check if already running as Admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO]  Not running as Administrator. Attempting self-elevation...
    echo [INFO]  If prompted, click "Yes" to allow Administrator access.
    echo.

    :: Re-launch this batch file with elevated privileges
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs"

    :: Exit this non-elevated instance
    exit /b
)

:: ─── We are now running as Administrator ────────────────────────────────────
cd /d "%~dp0"

echo [OK]     Running with Administrator privileges.
echo [INFO]   Launch mode: %MODE%
echo.

if /I "%MODE%"=="cli" goto :cli
if /I "%MODE%"=="dev" goto :dev
if /I "%MODE%"=="gui" goto :gui
if /I "%MODE%"=="auto" goto :auto

echo [WARN]   Unknown mode "%MODE%". Use auto, dev, gui or cli.
goto :finish

:auto
if exist "%~dp0NetSnipe.UI\Frontend\dist\index.html" (
    where dotnet >nul 2>&1
    if !errorlevel! equ 0 goto :gui
)
if exist "%~dp0NetSnipe.UI\Frontend\node_modules" (
    where dotnet >nul 2>&1
    if !errorlevel! equ 0 goto :dev
)
echo [INFO]   Enhanced GUI is not built or the .NET SDK is unavailable.
echo [INFO]   Falling back to the PowerShell CLI.
goto :cli

:gui
if not exist "%~dp0NetSnipe.UI\Frontend\dist\index.html" (
    echo [FAIL]   Frontend build not found.
    echo [INFO]   Run "run.bat dev" after installing the developer dependencies.
    goto :finish
)
where dotnet >nul 2>&1
if %errorlevel% neq 0 (
    echo [FAIL]   .NET SDK was not found. The development GUI cannot start.
    goto :finish
)
goto :start_gui

:dev
where dotnet >nul 2>&1
if %errorlevel% neq 0 (
    echo [FAIL]   .NET SDK was not found.
    goto :finish
)
where npm.cmd >nul 2>&1
if %errorlevel% neq 0 (
    echo [FAIL]   Node.js/npm was not found. Install the frontend developer dependencies first.
    goto :finish
)
if not exist "%~dp0NetSnipe.UI\Frontend\node_modules" (
    echo [FAIL]   Frontend dependencies are missing.
    echo [INFO]   Run setup-dev.bat once with Internet access, then run this script again.
    goto :finish
)
echo [INFO]   Building the local frontend...
call npm.cmd --prefix "%~dp0NetSnipe.UI\Frontend" run build
if %errorlevel% neq 0 (
    echo [FAIL]   Frontend build failed.
    goto :finish
)

:start_gui
echo [INFO]   Starting the local WebView2 GUI...
dotnet run --project "%~dp0NetSnipe.UI\NetSnipe.UI.csproj" --configuration Debug
goto :finish

:cli
echo [INFO]   Starting the PowerShell CLI...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0NetSnipe.ps1" -Action Menu

:: ─── Handle exit ────────────────────────────────────────────────────────────
if %errorlevel% neq 0 (
    echo.
    echo [WARN]  NetSnipe exited with code %errorlevel%.
)

echo.
echo [INFO]  Press any key to close this window...
pause >nul
:finish
echo.
pause
exit /b
