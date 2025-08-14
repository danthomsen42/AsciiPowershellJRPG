# =============================================================================
# COMPREHENSIVE BATTLE SYSTEM TEST
# =============================================================================
# Tests both clean targeting and proper enemy sprite management

Write-Host "=== BATTLE SYSTEM TEST ===" -ForegroundColor Cyan
Write-Host "Testing clean targeting and sprite persistence..." -ForegroundColor Yellow
Write-Host ""

# Load required systems
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1"
. "$PSScriptRoot\CleanArrowTargeting.ps1"

# Create test party
$global:Party = @(
    @{ Name = "TestWarrior"; Level = 5; HP = 100; MaxHP = 100; MP = 20; MaxMP = 20; Attack = 25; Defense = 15; Speed = 10 }
    @{ Name = "TestMage"; Level = 4; HP = 70; MaxHP = 70; MP = 50; MaxMP = 50; Attack = 15; Defense = 8; Speed = 12 }
)

# Generate multi-enemy encounter for testing
$enemies = Get-RandomEnemyEncounter

Write-Host "Initial Battle State:" -ForegroundColor Green
Write-Host "Enemies: $($enemies.Count)"
foreach ($enemy in $enemies) {
    Write-Host "  - $($enemy.Name) (HP: $($enemy.HP)/$($enemy.MaxHP), Size: $($enemy.Size))" -ForegroundColor White
}

Write-Host ""
Write-Host "Drawing initial battle..." -ForegroundColor Yellow
$boxWidth = 80
$boxHeight = 25

# Test 1: Initial display
Draw-EnhancedCombatViewport $enemies $boxWidth $boxHeight

Write-Host ""
Write-Host "=== TEST 1: Initial Display Successful ===" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to test targeting system..."
$null = [System.Console]::ReadKey($true)

# Test 2: Targeting system (should show clean arrow indicators)
Write-Host "Testing targeting system..." -ForegroundColor Cyan
$target = Show-CleanBattleTargeting $enemies $boxWidth $boxHeight

if ($target) {
    [System.Console]::Clear()
    Write-Host "=== TEST 2: Target Selected ===" -ForegroundColor Green
    Write-Host "Selected: $($target.Name)" -ForegroundColor Yellow
    Write-Host ""
    
    # Test 3: Kill one enemy and check if others remain visible
    Write-Host "Killing $($target.Name) and testing sprite persistence..." -ForegroundColor Cyan
    $target.HP = 0
    
    Write-Host "Before cleanup: $($enemies.Count) enemies"
    $enemies = Clean-EnemyArray $enemies
    Write-Host "After cleanup: $($enemies.Count) enemies"
    
    Write-Host ""
    Write-Host "Remaining enemies:"
    foreach ($enemy in $enemies) {
        Write-Host "  - $($enemy.Name) (HP: $($enemy.HP)/$($enemy.MaxHP))" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Drawing updated battle (remaining enemies should be visible)..." -ForegroundColor Yellow
    Draw-EnhancedCombatViewport $enemies $boxWidth $boxHeight
    
    Write-Host ""
    Write-Host "=== TEST 3: Sprite Persistence Test Complete ===" -ForegroundColor Green
    Write-Host "Check above - all remaining enemies should be visible." -ForegroundColor Yellow
    
} else {
    Write-Host "Targeting was cancelled." -ForegroundColor Red
}

Write-Host ""
Write-Host "=== BATTLE SYSTEM TEST COMPLETE ===" -ForegroundColor Cyan
Write-Host "Please verify:" -ForegroundColor Yellow
Write-Host "1. Targeting arrows appeared ONLY above enemies (not over text)" -ForegroundColor White
Write-Host "2. Text stayed below the battle area during targeting" -ForegroundColor White  
Write-Host "3. Remaining enemy sprites are still visible after cleanup" -ForegroundColor White
