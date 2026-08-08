# Cash Empire — open Blender + plugin install helpers
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pluginDir = Join-Path $root "plugins"
$exportDir = Join-Path $root "export"
$blendDir = Join-Path $root "blender"

New-Item -ItemType Directory -Force -Path $pluginDir, $exportDir, $blendDir | Out-Null

# Find blender.exe
$blender = $null
$candidates = @(
  "${env:ProgramFiles}\Blender Foundation\Blender 5.2\blender.exe",
  "${env:ProgramFiles}\Blender Foundation\Blender 5.1\blender.exe",
  "${env:ProgramFiles}\Blender Foundation\Blender 5.0\blender.exe",
  "${env:ProgramFiles}\Blender Foundation\Blender 4.5\blender.exe",
  "${env:ProgramFiles}\Blender Foundation\Blender 4.2\blender.exe",
  "${env:LOCALAPPDATA}\Programs\Blender Foundation\Blender\blender.exe"
)
foreach ($c in $candidates) {
  if (Test-Path $c) { $blender = $c; break }
}
if (-not $blender) {
  $found = Get-ChildItem "${env:ProgramFiles}\Blender Foundation" -Recurse -Filter "blender.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($found) { $blender = $found.FullName }
}

Write-Host "=== Cash Empire Blender ↔ Roblox ===" -ForegroundColor Cyan
Write-Host "Plugin folder: $pluginDir"
Write-Host "Export folder: $exportDir"
Write-Host ""

$zips = Get-ChildItem $pluginDir -Filter "*.zip" -ErrorAction SilentlyContinue
if ($zips) {
  Write-Host "Plugin zip(s) ready:" -ForegroundColor Green
  $zips | ForEach-Object { Write-Host "  $($_.FullName)" }
} else {
  Write-Host "No plugin zip yet. Downloading latest..." -ForegroundColor Yellow
  $api = Invoke-RestMethod -Uri "https://api.github.com/repos/Roblox/roblox-blender-plugin/releases/latest" -Headers @{ "User-Agent" = "CashEmpire" }
  $asset = $api.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
  if ($asset) {
    $out = Join-Path $pluginDir $asset.name
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $out -UseBasicParsing
    Write-Host "Downloaded: $out" -ForegroundColor Green
  }
}

Write-Host ""
Write-Host "In Blender:" -ForegroundColor Yellow
Write-Host "  1. Edit > Preferences > Add-ons > Install from Disk"
Write-Host "  2. Select the zip in assets\plugins (do NOT unzip)"
Write-Host "  3. Enable 'Upload to Roblox'"
Write-Host "  4. N panel > Roblox > Install Dependencies > restart > Log in"
Write-Host "  5. Select mesh > Upload  OR  run export_roblox_fbx.py"
Write-Host ""

if ($blender) {
  Write-Host "Launching Blender: $blender" -ForegroundColor Green
  Start-Process $blender
} else {
  Write-Host "Blender not found. Install then re-run this script." -ForegroundColor Red
  Write-Host "  winget install BlenderFoundation.Blender"
}

explorer.exe $pluginDir
explorer.exe $exportDir
