# =============================================================================
# MINOTAUR RENDERING TEST
# =============================================================================

Write-Host "=== MINOTAUR RENDERING TEST ===" -ForegroundColor Red
Write-Host ""

# Load systems
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1"

# Get the Minotaur
$minotaurEnemy = $Minotaur

Write-Host "Testing Minotaur rendering..." -ForegroundColor Yellow
Write-Host "Minotaur details:" -ForegroundColor Green
Write-Host "  Name: $($minotaurEnemy.Name)" -ForegroundColor White
Write-Host "  Size: $($minotaurEnemy.Size)" -ForegroundColor White  
Write-Host "  HP: $($minotaurEnemy.HP)/$($minotaurEnemy.MaxHP)" -ForegroundColor White
Write-Host "  Art lines: $($minotaurEnemy.Art.Count)" -ForegroundColor White

$maxWidth = ($minotaurEnemy.Art | Measure-Object -Property Length -Maximum).Maximum
Write-Host "  Max width: $maxWidth" -ForegroundColor White

Write-Host ""
Write-Host "Raw Minotaur art preview:" -ForegroundColor Cyan
for ($i = 0; $i -lt [math]::Min(5, $minotaurEnemy.Art.Count); $i++) {
    Write-Host "  '$($minotaurEnemy.Art[$i])'" -ForegroundColor Gray
}
Write-Host "  ... (showing first 5 lines)" -ForegroundColor Gray

Write-Host ""
Write-Host "Drawing Minotaur in battle viewport..." -ForegroundColor Yellow

$enemies = @($minotaurEnemy)
Draw-EnhancedCombatViewport $enemies 80 25

Write-Host ""
Write-Host "=== MINOTAUR TEST COMPLETE ===" -ForegroundColor Red
Write-Host "The Minotaur should be visible in the battle area above!" -ForegroundColor Yellow
