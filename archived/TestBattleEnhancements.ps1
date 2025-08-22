# Test the enhanced battle system with dead enemy removal and arrow targeting
Write-Host "=== ENHANCED BATTLE FEATURES TEST ===" -ForegroundColor Green
Write-Host ""

# Load systems
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1"
. "$PSScriptRoot\ArrowTargeting.ps1"

# Create test encounter with multiple enemies
$testEnemies = @(
    $Goblin.Clone(),
    $Orc.Clone(),
    $Slime.Clone()
)

# Give them unique names for testing
$testEnemies[0].Name = "Goblin Scout"
$testEnemies[1].Name = "Orc Warrior" 
$testEnemies[2].Name = "Acid Slime"

Write-Host "=== FEATURE 1: DEAD ENEMY REMOVAL ===" -ForegroundColor Yellow
Write-Host "Starting battle with 3 enemies:"
foreach ($enemy in $testEnemies) {
    Write-Host "  $($enemy.Name) - HP: $($enemy.HP)" -ForegroundColor White
}

Write-Host "`nPress any key to see initial battle display..."
$null = [System.Console]::ReadKey($true)
[System.Console]::Clear()

# Show initial display
Draw-EnhancedCombatViewport $testEnemies 80 25

Write-Host "`nNow killing the Orc Warrior..."
$testEnemies[1].HP = 0  # Kill the Orc
Start-Sleep -Milliseconds 1000

Write-Host "Press any key to see updated display (Orc should be gone)..."
$null = [System.Console]::ReadKey($true)
[System.Console]::Clear()

# Show updated display - Orc should be gone
Draw-EnhancedCombatViewport $testEnemies 80 25

Write-Host "`nKilling the Slime too..."
$testEnemies[2].HP = 0  # Kill the Slime
Start-Sleep -Milliseconds 1000

Write-Host "Press any key to see display with only Goblin alive..."
$null = [System.Console]::ReadKey($true)
[System.Console]::Clear()

# Show display with only 1 enemy
Draw-EnhancedCombatViewport $testEnemies 80 25

Write-Host ""
Write-Host "Feature 1 complete! Dead enemies are removed from display." -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to test Feature 2: Arrow Targeting..."
$null = [System.Console]::ReadKey($true)

# Reset enemies for targeting test
foreach ($enemy in $testEnemies) {
    $enemy.HP = $enemy.MaxHP  # Restore all to full health
}

Write-Host ""
Write-Host "=== FEATURE 2: ARROW TARGETING ===" -ForegroundColor Yellow
Write-Host "All enemies restored. Testing arrow-based targeting..."
Write-Host "You should be able to use arrow keys or WASD to select targets!"
Start-Sleep -Milliseconds 1500

# Test the arrow targeting system
$selectedTarget = Show-SimpleArrowTargeting $testEnemies

if ($selectedTarget) {
    Write-Host ""
    Write-Host "You selected: $($selectedTarget.Name)!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Targeting cancelled." -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== BOTH FEATURES READY! ===" -ForegroundColor Green
Write-Host "✓ Dead enemies are removed from display"
Write-Host "✓ Arrow-based enemy targeting implemented"
Write-Host ""
Write-Host "The enhanced battle system is ready to use in your main game!" -ForegroundColor Cyan
