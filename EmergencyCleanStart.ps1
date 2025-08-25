# EMERGENCY CLEAN NEW GAME STARTER
# This bypasses all potential issues and starts fresh

Write-Host "=== EMERGENCY CLEAN NEW GAME STARTER ===" -ForegroundColor Red
Write-Host "This will start a completely fresh new game..." -ForegroundColor Yellow

# Force clear ALL potentially problematic globals
$variablesToClear = @(
    'CurrentMapName', 'PlayerStartX', 'PlayerStartY', 'PlayerCurrentX', 'PlayerCurrentY',
    'Player', 'Party', 'SaveState', 'Maps', 'DoorRegistry', 'NPCs'
)

Write-Host "Clearing global variables..." -ForegroundColor Cyan
foreach ($var in $variablesToClear) {
    Set-Variable -Name $var -Value $null -Scope Global -Force
    Write-Host "- Cleared global:$var"
}

Write-Host "`nForcing clean map initialization..." -ForegroundColor Yellow

# Load only essential systems
Write-Host "Loading MapManager..." -ForegroundColor Cyan
. "$PSScriptRoot\MapManager.ps1"

# Verify map loading works
Write-Host "Testing map system..." -ForegroundColor Yellow
if ($global:Maps -and $global:Maps.ContainsKey("Town")) {
    Write-Host "✅ Town map available" -ForegroundColor Green
} else {
    Write-Host "❌ Town map missing!" -ForegroundColor Red
    return
}

# Force set correct values
Write-Host "Setting clean game state..." -ForegroundColor Yellow
$global:CurrentMapName = "Town"
$global:PlayerCurrentX = 40
$global:PlayerCurrentY = 12

Write-Host "Starting Display.ps1..." -ForegroundColor Green
Write-Host "Map should load as: $global:CurrentMapName" -ForegroundColor Cyan

# Start the game
. "$PSScriptRoot\Display.ps1"
