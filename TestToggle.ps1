# Quick test of the color zone toggle system
. "$PSScriptRoot\ColorZones.ps1"

Write-Host "=== COLOR ZONES TOGGLE TEST ===" -ForegroundColor Cyan

Write-Host "`nTesting with zones DISABLED (default):"
$color1 = Get-TileColor "Town" 25 24 '.'
$ansi1 = Get-TileANSIColor "Town" 25 24 '.'
Write-Host "  Color result: '$color1'"
Write-Host "  ANSI result: '$ansi1'"

Write-Host "`nEnabling color zones..."
Set-ColorZones $true

Write-Host "`nTesting with zones ENABLED:"
$color2 = Get-TileColor "Town" 25 24 '.'
$ansi2 = Get-TileANSIColor "Town" 25 24 '.'
Write-Host "  Color result: '$color2'"
Write-Host "  ANSI result: '$ansi2'"

Write-Host "`nDisabling color zones again..."
Set-ColorZones $false

Write-Host "`nTesting with zones DISABLED again:"
$color3 = Get-TileColor "Town" 25 24 '.'
$ansi3 = Get-TileANSIColor "Town" 25 24 '.'
Write-Host "  Color result: '$color3'"
Write-Host "  ANSI result: '$ansi3'"

Write-Host "`n=== TOGGLE TEST COMPLETE ===" -ForegroundColor Green
