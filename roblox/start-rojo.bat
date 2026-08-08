@echo off
title Cash Stack - Rojo Server
cd /d "%~dp0"
echo ========================================
echo   CASH STACK - ROJO SERVER
echo   KEEP THIS WINDOW OPEN
echo ========================================
echo.
echo In Roblox Studio:
echo   1. Plugins tab -^> Rojo
echo   2. Connect to 127.0.0.1 port 34872
echo.
where rojo >nul 2>&1
if errorlevel 1 (
  echo Rojo not in PATH. Using winget install path...
  set "PATH=%LOCALAPPDATA%\Microsoft\WinGet\Packages\Rojo.Rojo_Microsoft.Winget.Source_8wekyb3d8bbwe;%PATH%"
)
rojo serve --address 127.0.0.1 --port 34872
echo.
echo Rojo stopped.
pause
