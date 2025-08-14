# =============================================================================
# SINGLE ENEMY DEBUG TEST
# =============================================================================
# Tests specifically the case where only one enemy remains

Write-Host "=== SINGLE ENEMY DEBUG TEST ===" -ForegroundColor Cyan
Write-Host ""

# Load required systems
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1"
. "$PSScriptRoot\CleanArrowTargeting.ps1"

# Create a single test enemy
$singleEnemy = @(
    @{
        Name = "Lone Goblin"
        Level = 3
        HP = 20
        MaxHP = 20
        Attack = 12
        Defense = 8
        Speed = 10
        Size = "Small"
        BaseXP = 15
        Art = @(
            "  /|\\  /|\\  "
            " (_|__/_|  "
            "/  @    \\ "
            "<___/\\___>"
            "^^      ^^"
        )
    }
)

Write-Host "Testing single enemy display..." -ForegroundColor Green
$boxWidth = 80
$boxHeight = 25

# Test the layout calculation for single enemy
$layout = Calculate-BattleLayout $singleEnemy $boxWidth $boxHeight
Write-Host "Layout calculated - Rows: $($layout.Rows.Count)" -ForegroundColor Yellow

foreach ($row in $layout.Rows) {
    Write-Host "  Row Type: $($row.Type), StartY: $($row.StartY), Height: $($row.Height), Enemies: $($row.Enemies.Count)" -ForegroundColor White
}

Write-Host ""
Write-Host "Drawing single enemy battle viewport..." -ForegroundColor Green
Draw-EnhancedCombatViewport $singleEnemy $boxWidth $boxHeight

Write-Host ""
Write-Host "Press any key to test targeting on single enemy..."
$null = [System.Console]::ReadKey($true)

# Test targeting on single enemy
$target = Show-CleanBattleTargeting $singleEnemy $boxWidth $boxHeight

if ($target) {
    Write-Host ""
    Write-Host "Single enemy targeting successful: $($target.Name)" -ForegroundColor Green
} else {
    Write-Host "Single enemy targeting failed or cancelled" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== SINGLE ENEMY TEST COMPLETE ===" -ForegroundColor Cyan
