@echo off
setlocal

title NetSnipe developer setup
cd /d "%~dp0"

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [FAIL] Node.js was not found.
    pause
    exit /b 1
)

echo [INFO] Installing frontend dependencies...
call npm.cmd --prefix "%~dp0NetSnipe.UI\Frontend" install
if %errorlevel% neq 0 (
    echo [FAIL] npm install failed.
    pause
    exit /b 1
)

echo [OK] Developer dependencies are ready.
pause
