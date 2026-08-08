@echo off
title Cash Empire - Blender Roblox Pipeline
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0install_blender_roblox.ps1"
pause
