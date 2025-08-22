# Test Clean-EnemyArray function availability
. "$PSScriptRoot\Display.ps1"

Write-Host "Testing Clean-EnemyArray function..." -ForegroundColor Green

# Create test enemies
$testEnemies = @(
    @{ Name = "Enemy1"; HP = 10; MaxHP = 10 },
    @{ Name = "Enemy2"; HP = 0; MaxHP = 10 },  # Dead enemy
    @{ Name = "Enemy3"; HP = 5; MaxHP = 10 }
)

Write-Host "Before cleanup: $($testEnemies.Count) enemies"
$cleaned = Clean-EnemyArray $testEnemies
Write-Host "After cleanup: $($cleaned.Count) enemies"

foreach ($enemy in $cleaned) {
    Write-Host "  - $($enemy.Name) (HP: $($enemy.HP))"
}

Write-Host "Clean-EnemyArray function test complete!" -ForegroundColor Green
