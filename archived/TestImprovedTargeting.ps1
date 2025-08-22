# =============================================================================
# TEST: Improved Arrow Targeting and Enemy Cleanup
# =============================================================================

# Load the required systems
. "$PSScriptRoot\Player.ps1"
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1"
. "$PSScriptRoot\ImprovedArrowTargetingFixed.ps1"

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "    TESTING IMPROVED ARROW TARGETING" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Initialize party
$global:Party = @(
    @{ Name = "Warrior"; Level = 5; HP = 100; MaxHP = 100; MP = 20; MaxMP = 20; Attack = 25; Defense = 15; Speed = 10 }
    @{ Name = "Mage"; Level = 4; HP = 70; MaxHP = 70; MP = 50; MaxMP = 50; Attack = 15; Defense = 8; Speed = 12 }
    @{ Name = "Healer"; Level = 4; HP = 80; MaxHP = 80; MP = 60; MaxMP = 60; Attack = 12; Defense = 10; Speed = 14 }
    @{ Name = "Rogue"; Level = 5; HP = 85; MaxHP = 85; MP = 30; MaxMP = 30; Attack = 22; Defense = 12; Speed = 18 }
)

# Get a random encounter with multiple enemies
$enemies = Get-RandomEnemyEncounter

Write-Host "Generated encounter with $($enemies.Count) enemies:" -ForegroundColor Yellow
foreach ($enemy in $enemies) {
    Write-Host "  - $($enemy.Name) (HP: $($enemy.HP)/$($enemy.MaxHP))" -ForegroundColor White
}
Write-Host ""

# Test drawing the battle viewport
Write-Host "Drawing battle viewport..." -ForegroundColor Green
$boxWidth = 80
$boxHeight = 25

Draw-EnhancedCombatViewport $enemies $boxWidth $boxHeight

Write-Host ""
Write-Host "Press any key to test arrow targeting..."
$null = [System.Console]::ReadKey($true)

# Test the new arrow targeting
Write-Host "Testing arrow targeting..." -ForegroundColor Green
$target = Show-BattleArrowTargeting $enemies $boxWidth $boxHeight

if ($target) {
    Write-Host ""
    Write-Host "Target selected: $($target.Name)" -ForegroundColor Yellow
    Write-Host "Dealing 30 damage..."
    
    $target.HP -= 30
    $target.HP = [math]::Max(0, $target.HP)
    
    Write-Host "New HP: $($target.HP)/$($target.MaxHP)" -ForegroundColor Cyan
    
    # Test enemy cleanup
    Write-Host ""
    Write-Host "Testing enemy cleanup..." -ForegroundColor Green
    $cleanedEnemies = Clean-EnemyArray $enemies
    
    Write-Host "Enemies after cleanup: $($cleanedEnemies.Count)" -ForegroundColor Yellow
    foreach ($enemy in $cleanedEnemies) {
        Write-Host "  - $($enemy.Name) (HP: $($enemy.HP)/$($enemy.MaxHP))" -ForegroundColor White
    }
} else {
    Write-Host "Targeting cancelled." -ForegroundColor Red
}

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Green
