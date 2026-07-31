@echo off
setlocal

cd /d "%~dp0.."
echo Building installer EXE...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\build-release.ps1" -SkipPortable
if errorlevel 1 (
    echo.
    echo BUILD FAILED. Read the error above.
    pause
    exit /b 1
)

echo.
echo INSTALLER BUILD COMPLETE.
echo The installer is in artifacts\installer
start "" explorer.exe "%~dp0..\artifacts\installer"
pause
