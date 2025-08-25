# Clean New Game Test - Clear all globals and test fresh start
Write-Host "=== CLEAN NEW GAME TEST ===" -ForegroundColor Yellow

Write-Host "Clearing all global variables that might interfere..." -ForegroundColor Cyan

# Clear any existing global variables that might cause issues
$global:CurrentMapName = $null
$global:PlayerCurrentX = $null
$global:PlayerCurrentY = $null
$global:PlayerStartX = $null
$global:PlayerStartY = $null
$global:Player = $null
$global:Party = $null

Write-Host "Globals cleared. Testing map loading..." -ForegroundColor Yellow

# Load the map system fresh
. "$PSScriptRoot\MapManager.ps1"

Write-Host "MapManager loaded. Available maps:" -ForegroundColor Cyan
$global:Maps.Keys | ForEach-Object { Write-Host "- $_" -ForegroundColor Green }

# Test what Display.ps1 should do for a new game
Write-Host "`nSimulating Display.ps1 new game initialization..." -ForegroundColor Yellow

# This is what Display.ps1 does:
if ($global:CurrentMapName) {
    $CurrentMapName = $global:CurrentMapName
    Write-Host "Would load saved map: $CurrentMapName" -ForegroundColor Green
} else {
    $CurrentMapName = "Town"
    $global:CurrentMapName = $CurrentMapName
    Write-Host "Setting default map: $CurrentMapName" -ForegroundColor Green
}

$currentMap = $global:Maps[$CurrentMapName]

if ($currentMap) {
    Write-Host "✅ SUCCESS: Map '$CurrentMapName' loaded correctly" -ForegroundColor Green
    Write-Host "Map is $($currentMap.Count) lines tall" -ForegroundColor Cyan
} else {
    Write-Host "❌ ERROR: Could not load map '$CurrentMapName'" -ForegroundColor Red
    Write-Host "Available maps are:" -ForegroundColor Yellow
    $global:Maps.Keys | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
}

Write-Host "`n=== TEST COMPLETE ===" -ForegroundColor Yellow
Write-Host "Current global state:" -ForegroundColor Cyan
Write-Host "- global:CurrentMapName = '$global:CurrentMapName'"
Write-Host "- CurrentMapName = '$CurrentMapName'"
