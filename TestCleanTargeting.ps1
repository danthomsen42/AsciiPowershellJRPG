# =============================================================================
# TEST: Clean Arrow Targeting System
# =============================================================================

# Load the required systems
. "$PSScriptRoot\Player.ps1"
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1"
. "$PSScriptRoot\CleanArrowTargeting.ps1"

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "    TESTING CLEAN ARROW TARGETING" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Create a simple test with 2 enemies
$enemies = @(
    @{
        Name = "Goblin"
        Level = 3
        HP = 25
        MaxHP = 25
        Attack = 12
        Defense = 8
        Speed = 10
        Size = "Small"
        BaseXP = 15
        Art = @(
            "  /|   /|  "
            " (_|__/_|  "
            "/  @    \\ "
            "<___/\\___>"
            "^^      ^^"
        )
    },
    @{
        Name = "Orc"
        Level = 4
        HP = 35
        MaxHP = 35
        Attack = 15
        Defense = 10
        Speed = 8
        Size = "Medium" 
        BaseXP = 20
        Art = @(
            "    ___    "
            "   /ORC\\   "
            "  ( o-o )  "
            "   \\___/   "
            "  /|||||\\  "
            " <_______> "
            "  |     |  "
            " /|     |\\ "
        )
    }
)

Write-Host "Initial enemies:" -ForegroundColor Yellow
foreach ($enemy in $enemies) {
    Write-Host "  - $($enemy.Name) (HP: $($enemy.HP)/$($enemy.MaxHP))" -ForegroundColor White
}
Write-Host ""

# Test drawing the battle viewport
$boxWidth = 80
$boxHeight = 25

Write-Host "Drawing battle viewport with both enemies..." -ForegroundColor Green
Draw-EnhancedCombatViewport $enemies $boxWidth $boxHeight

Write-Host ""
Write-Host "Press any key to test targeting..."
$null = [System.Console]::ReadKey($true)

# Test the targeting system
Write-Host "Testing clean arrow targeting..." -ForegroundColor Green
$target = Show-CleanBattleTargeting $enemies $boxWidth $boxHeight

if ($target) {
    Write-Host ""
    Write-Host "Target selected: $($target.Name)" -ForegroundColor Yellow
    Write-Host "Dealing 30 damage..."
    
    $target.HP -= 30
    $target.HP = [math]::Max(0, $target.HP)
    
    Write-Host "New HP: $($target.HP)/$($target.MaxHP)" -ForegroundColor Cyan
    
    # Test enemy cleanup
    Write-Host ""
    Write-Host "Cleaning enemy array..." -ForegroundColor Green
    $enemies = Clean-EnemyArray $enemies
    
    Write-Host "Enemies after cleanup: $($enemies.Count)" -ForegroundColor Yellow
    foreach ($enemy in $enemies) {
        Write-Host "  - $($enemy.Name) (HP: $($enemy.HP)/$($enemy.MaxHP))" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Drawing updated battle viewport..." -ForegroundColor Green
    Draw-EnhancedCombatViewport $enemies $boxWidth $boxHeight
    
} else {
    Write-Host "Targeting cancelled." -ForegroundColor Red
}

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Green
