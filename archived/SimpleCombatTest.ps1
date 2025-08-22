# SimpleCombatTest.ps1 - Test combat display layout

Write-Host "Testing combat layout fixes..." -ForegroundColor Green

# Load modules
. "$PSScriptRoot\Player.ps1"
. "$PSScriptRoot\Enemies.ps1"

# Test basic layout without complex function extraction
$player = $Player.Clone()
$enemy = $Enemy1.Clone()

Write-Host "Player Stats: HP=$($player.HP)/$($player.MaxHP) MP=$($player.MP)/$($player.MaxMP) Speed=$($player.Speed)" -ForegroundColor Cyan
Write-Host "Enemy Stats: HP=$($enemy.HP) Speed=$($enemy.Speed)" -ForegroundColor Red

Write-Host "`nLayout should be:" -ForegroundColor Yellow
Write-Host "1. Enemy viewport (with box)" -ForegroundColor Gray
Write-Host "2. HP/MP stats line" -ForegroundColor Gray  
Write-Host "3. Combat controls line" -ForegroundColor Gray
Write-Host "4. Turn order line" -ForegroundColor Gray
Write-Host "5. Combat messages below" -ForegroundColor Gray

Write-Host "`nNow try running Display.ps1 and walking into an enemy to test!" -ForegroundColor Green
