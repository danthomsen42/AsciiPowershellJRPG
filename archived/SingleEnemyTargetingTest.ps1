# =============================================================================
# SINGLE ENEMY TARGETING FIX TEST
# =============================================================================
# Tests the specific issue where last enemy sprite vanishes

Write-Host "=== SINGLE ENEMY TARGETING TEST ===" -ForegroundColor Red
Write-Host "Testing the last enemy sprite visibility issue..." -ForegroundColor Yellow
Write-Host ""

# Load systems
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1"
. "$PSScriptRoot\CleanArrowTargeting.ps1"

$boxWidth = 80
$boxHeight = 25

Write-Host "Creating single enemy scenario..." -ForegroundColor Green

# Create a single enemy (simulating the last enemy alive)
$lastEnemy = @{
    Name = "Last Goblin"
    HP = 15
    MaxHP = 15
    Size = "Small"
    BaseXP = 10
    Art = @(
        "  /|\\  /|\\  ",
        " (_|__/_|  ",
        "/  @    \\ ",
        "<___/\\___>",
        "^^      ^^"
    )
}

$enemies = @($lastEnemy)

Write-Host "Enemy count: $($enemies.Count)" -ForegroundColor Yellow
Write-Host "Enemy: $($enemies[0].Name) - HP: $($enemies[0].HP)" -ForegroundColor White
Write-Host ""

Write-Host "Testing single enemy targeting (this should show the enemy sprite)..." -ForegroundColor Cyan
Write-Host "The enemy should be visible in the battle area during targeting!" -ForegroundColor Yellow
Write-Host ""

# Test the targeting - this should now show the enemy sprite
$target = Show-CleanBattleTargeting $enemies $boxWidth $boxHeight

if ($target) {
    [System.Console]::Clear()
    Write-Host "=== SINGLE ENEMY TARGETING SUCCESS ===" -ForegroundColor Green
    Write-Host "Target selected: $($target.Name)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Final verification - drawing the enemy again:" -ForegroundColor Cyan
    Draw-EnhancedCombatViewport $enemies $boxWidth $boxHeight
    Write-Host ""
    Write-Host "✓ Last enemy should be visible above!" -ForegroundColor Green
} else {
    Write-Host "Targeting was cancelled." -ForegroundColor Red
}

Write-Host ""
Write-Host "=== SINGLE ENEMY TEST COMPLETE ===" -ForegroundColor Red
Write-Host "The enemy sprite should have been visible during targeting." -ForegroundColor Yellow
