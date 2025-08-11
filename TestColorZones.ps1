# =============================================================================
# COLOR ZONES TESTING SCRIPT
# =============================================================================
# This script demonstrates the color zone system without running the full game

# Load required files
. "$PSScriptRoot\ColorZones.ps1"

Write-Host "=== COLOR ZONES DEMO ===" -ForegroundColor Cyan
Write-Host ""

# Test the color zone system
Write-Host "Testing Town Map Color Zones:" -ForegroundColor Yellow

# Test some coordinates in the town grass area
$testCoords = @(
    @{ X=20; Y=25; Char='.'; Expected="TownGrass" }
    @{ X=45; Y=15; Char='.'; Expected="CastleCourtyard" }
    @{ X=5; Y=10; Char='.'; Expected="TownPaths" }
    @{ X=45; Y=7; Char='.'; Expected="StoreFloor" }
    @{ X=40; Y=12; Char='~'; Expected="CastleMoat" }
    @{ X=10; Y=10; Char='#'; Expected="Default Wall" }
)

foreach ($coord in $testCoords) {
    $color = Get-TileColor "Town" $coord.X $coord.Y $coord.Char
    $ansiColor = Get-TileANSIColor "Town" $coord.X $coord.Y $coord.Char
    
    Write-Host "  Coord ($($coord.X),$($coord.Y)) '$($coord.Char)' -> " -NoNewline
    if ($ansiColor) {
        Write-Host "$ansiColor$($coord.Char)$($global:WaterANSIColors['Reset']) " -NoNewline
    } else {
        Write-Host "$($coord.Char) " -NoNewline
    }
    Write-Host "[$color] ($($coord.Expected))" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "All defined zones for Town map:" -ForegroundColor Yellow
Show-ColorZones "Town"

Write-Host ""
Write-Host "All defined zones for Dungeon map:" -ForegroundColor Yellow  
Show-ColorZones "Dungeon"

Write-Host ""
Write-Host "=== DYNAMIC ZONE ADDITION DEMO ===" -ForegroundColor Cyan

# Add a new zone dynamically
Add-ColorZone "Town" "TestArea" '.' "Red" 60 65 20 25 5

Write-Host "Updated Town zones:" -ForegroundColor Yellow
Show-ColorZones "Town"

# Test the new zone
$newColor = Get-TileColor "Town" 62 22 '.'
Write-Host "New zone test at (62,22): Color = $newColor" -ForegroundColor Green

Write-Host ""
Write-Host "=== COLOR ZONE SYSTEM READY! ===" -ForegroundColor Green
Write-Host "The color zones are now integrated into Display.ps1" -ForegroundColor White
Write-Host "Run the main game to see colored areas in action!" -ForegroundColor White
