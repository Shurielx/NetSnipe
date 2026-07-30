@echo off
setlocal

cd /d "%~dp0.."
echo Building portable ZIP and installer EXE...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\build-release.ps1"
if errorlevel 1 (
    echo.
    echo BUILD FAILED. Read the error above.
    pause
    exit /b 1
)

echo.
echo BUILD COMPLETE.
echo Opening artifacts folder...
start "" explorer.exe "%~dp0..\artifacts"
pause
