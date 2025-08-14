# Test all battle functions
Write-Host "=== TESTING ALL BATTLE FUNCTIONS ===" -ForegroundColor Green
Write-Host ""

# This should load all functions including the ones now in Display.ps1
. "$PSScriptRoot\Display.ps1" -ErrorAction Stop

Write-Host "Testing function availability..." -ForegroundColor Yellow

# Test 1: Clean-EnemyArray
if (Get-Command Clean-EnemyArray -ErrorAction SilentlyContinue) {
    Write-Host "✓ Clean-EnemyArray function available" -ForegroundColor Green
} else {
    Write-Host "✗ Clean-EnemyArray function missing" -ForegroundColor Red
}

# Test 2: Show-CleanBattleTargeting
if (Get-Command Show-CleanBattleTargeting -ErrorAction SilentlyContinue) {
    Write-Host "✓ Show-CleanBattleTargeting function available" -ForegroundColor Green
} else {
    Write-Host "✗ Show-CleanBattleTargeting function missing" -ForegroundColor Red
}

# Test 3: Add-CleanTargetingArrow
if (Get-Command Add-CleanTargetingArrow -ErrorAction SilentlyContinue) {
    Write-Host "✓ Add-CleanTargetingArrow function available" -ForegroundColor Green
} else {
    Write-Host "✗ Add-CleanTargetingArrow function missing" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== FUNCTION AVAILABILITY TEST COMPLETE ===" -ForegroundColor Green
