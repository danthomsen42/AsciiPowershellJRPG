# Simple test for arrow targeting
Write-Host "=== ARROW TARGETING TEST ===" -ForegroundColor Green

# Load systems
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\ArrowTargetingFixed.ps1"

# Create test enemies
$testEnemies = @(
    $Goblin.Clone(),
    $Orc.Clone(),
    $Slime.Clone()
)

$testEnemies[0].Name = "Goblin Scout"
$testEnemies[1].Name = "Orc Warrior"
$testEnemies[2].Name = "Magic Slime"

Write-Host "Testing arrow-based targeting with 3 enemies:"
foreach ($enemy in $testEnemies) {
    Write-Host "  $($enemy.Name) - HP: $($enemy.HP)" -ForegroundColor White
}

Write-Host "`nStarting arrow targeting test..."
Start-Sleep -Milliseconds 1000

$selectedTarget = Show-SimpleArrowTargeting $testEnemies

if ($selectedTarget) {
    Write-Host "`nYou selected: $($selectedTarget.Name)!" -ForegroundColor Green
} else {
    Write-Host "`nTargeting was cancelled." -ForegroundColor Gray
}

Write-Host "`nArrow targeting test complete!" -ForegroundColor Cyan
