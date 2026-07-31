@echo off
setlocal

cd /d "%~dp0.."
echo Building portable ZIP only...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\build-release.ps1" -SkipInstaller -SkipWebView2Download
if errorlevel 1 (
    echo.
    echo BUILD FAILED. Read the error above.
    pause
    exit /b 1
)

echo.
echo PORTABLE BUILD COMPLETE.
echo The ZIP is in the artifacts folder with the channel/version name.
start "" explorer.exe "%~dp0..\artifacts"
pause
