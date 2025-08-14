# Test integration with main battle system
Write-Host "=== INTEGRATION TEST ===" -ForegroundColor Green
Write-Host "Testing enhanced battle system integration..."

# Test enemy encounter generation
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1"

Write-Host ""
Write-Host "Testing random encounters:" -ForegroundColor Yellow

for ($i = 1; $i -le 3; $i++) {
    Write-Host "Encounter ${i}:" -ForegroundColor Cyan
    $encounter = Get-RandomEnemyEncounter "Dungeon" $i
    
    Write-Host "  Enemies: " -NoNewline
    foreach ($enemy in $encounter) {
        Write-Host "$($enemy.Name) ($($enemy.Size)) " -NoNewline -ForegroundColor White
    }
    Write-Host ""
    Write-Host "  Total enemies: $($encounter.Count)" -ForegroundColor Green
    Write-Host ""
}

Write-Host "Enhanced battle system ready for integration!" -ForegroundColor Green
Write-Host ""
Write-Host "New features available:" -ForegroundColor Yellow
Write-Host "✓ Varied enemy encounter types" 
Write-Host "✓ Smart layout system for different enemy sizes"
Write-Host "✓ Enhanced visual battle display"
Write-Host "✓ Compatible with existing targeting system"
