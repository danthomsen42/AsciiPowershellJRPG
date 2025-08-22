# Quick test of the new IntegratedColors system
. ".\IntegratedColors.ps1"

Write-Host "Testing new IntegratedColors system..." -ForegroundColor Green

# Enable colors
$global:EnableColorZones = $true

# Test the integrated color lookup
$testColor = Get-IntegratedTileColor "Town" 15 15 "."
Write-Host "Color for Town (15,15) '.' = $testColor" -ForegroundColor Yellow

$testANSI = Get-IntegratedTileANSI "Town" 15 15 "."
Write-Host "ANSI code = '$testANSI'" -ForegroundColor Cyan

# Test colored output
Write-Host ""
Write-Host "Testing colored output:"
Write-Host "Regular dot: ."
if ($testANSI) {
    Write-Host "Colored dot: $testANSI.$global:ANSIReset"
} else {
    Write-Host "No color found for that position"
}

Write-Host ""
Write-Host "The new system is much faster because:" -ForegroundColor Green
Write-Host "1. Colors are embedded directly in the text stream (no overdrawing)" -ForegroundColor White
Write-Host "2. Uses efficient zone checking instead of per-tile lookups" -ForegroundColor White
Write-Host "3. No separate rendering passes - everything in one go!" -ForegroundColor White

Read-Host "Press Enter to continue"
