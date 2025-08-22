# Test a simple enemy display first
Write-Host "=== SIMPLE ENEMY TEST ===" -ForegroundColor Green

# Load the new systems
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1"

# Test one small enemy
Write-Host "Testing Goblin (Small enemy):" -ForegroundColor Yellow
$testGoblin = $Goblin.Clone()
foreach ($line in $testGoblin.Art) {
    Write-Host $line -ForegroundColor Green
}

Write-Host ""
Write-Host "Testing Orc (Medium enemy):" -ForegroundColor Yellow  
$testOrc = $Orc.Clone()
foreach ($line in $testOrc.Art) {
    Write-Host $line -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Enemy sprites loaded successfully!" -ForegroundColor Green
Write-Host "Goblin: $($testGoblin.Name) - Size: $($testGoblin.Size) - HP: $($testGoblin.HP)"
Write-Host "Orc: $($testOrc.Name) - Size: $($testOrc.Size) - HP: $($testOrc.HP)"
