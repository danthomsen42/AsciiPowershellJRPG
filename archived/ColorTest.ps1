# Test script to debug color zone positioning
. ".\ColorZones.ps1"

# Enable color zones for testing
$global:EnableColorZones = $true

Write-Host "Testing color zone positioning..." -ForegroundColor Yellow
Write-Host "The green dot should be at world position (10,10)" -ForegroundColor Yellow
Write-Host ""

# Simulate a simple viewport around the colored dot
$testPlayerX = 8
$testPlayerY = 8
$viewX = 5
$viewY = 5
$boxWidth = 10
$boxHeight = 8

# Draw a simple test viewport
Write-Host "+" + ("-" * $boxWidth) + "+"
Write-Host "Test Map | Player: ($testPlayerX,$testPlayerY)"

for ($y = 0; $y -lt $boxHeight; $y++) {
    Write-Host "|" -NoNewline
    for ($x = 0; $x -lt $boxWidth; $x++) {
        $worldX = $x + $viewX
        $worldY = $y + $viewY
        
        if ($worldX -eq $testPlayerX -and $worldY -eq $testPlayerY) {
            Write-Host "@" -NoNewline
        } elseif ($worldX -eq 10 -and $worldY -eq 10) {
            Write-Host "." -NoNewline  # This should be colored green
        } else {
            Write-Host "." -NoNewline
        }
    }
    Write-Host "|"
}

Write-Host "+" + ("-" * $boxWidth) + "+"

# Now apply the color to the specific position
Write-Host ""
Write-Host "Applying green color to position (10,10)..." -ForegroundColor Yellow

$partyPositions = @{}
Render-ColoredTiles "Town" $viewX $viewY $boxWidth $boxHeight $testPlayerX $testPlayerY $partyPositions

Write-Host ""
Write-Host ""
Write-Host "If the dot at world position (10,10) is green, the color system is working!" -ForegroundColor Green
Write-Host "World (10,10) should be at screen position (6,7) in the box above." -ForegroundColor Cyan

Read-Host "Press Enter to exit"
