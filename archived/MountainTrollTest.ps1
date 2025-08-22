# =============================================================================
# MOUNTAIN TROLL SPECIFIC TEST
# =============================================================================
# Testing the specific case that was reported as not appearing

Write-Host "=== MOUNTAIN TROLL TEST ===" -ForegroundColor Red
Write-Host "Testing Mountain Troll rendering specifically..." -ForegroundColor Yellow
Write-Host ""

# Load required systems
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1"

# Get the actual Mountain Troll enemy definition
$mountainTroll = $null
$allEnemies = @($Goblin, $Orc, $Skeleton, $Spider, $Slime, $FireImp, $IceElemental, $ShadowBeast, $GiantRat, $Troll, $Minotaur, $Dragon)

foreach ($enemy in $allEnemies) {
    if ($enemy.Name -eq "Mountain Troll") {
        $mountainTroll = $enemy
        break
    }
}

if ($mountainTroll -eq $null) {
    Write-Host "ERROR: Mountain Troll not found in enemy definitions!" -ForegroundColor Red
    exit
}

Write-Host "Found Mountain Troll enemy definition:" -ForegroundColor Green
Write-Host "  Name: $($mountainTroll.Name)" -ForegroundColor White
Write-Host "  Size: $($mountainTroll.Size)" -ForegroundColor White
Write-Host "  HP: $($mountainTroll.HP)/$($mountainTroll.MaxHP)" -ForegroundColor White
Write-Host "  Art lines: $($mountainTroll.Art.Count)" -ForegroundColor White

# Check the art width
$maxWidth = ($mountainTroll.Art | Measure-Object -Property Length -Maximum).Maximum
Write-Host "  Max art width: $maxWidth characters" -ForegroundColor White
Write-Host ""

# Show the raw art for debugging
Write-Host "Raw Mountain Troll art:" -ForegroundColor Cyan
for ($i = 0; $i -lt $mountainTroll.Art.Count; $i++) {
    Write-Host "  Line $($i + 1): '$($mountainTroll.Art[$i])' (Length: $($mountainTroll.Art[$i].Length))" -ForegroundColor Gray
}
Write-Host ""

# Create a battle with just the Mountain Troll
$enemies = @($mountainTroll)
$boxWidth = 80
$boxHeight = 25

Write-Host "Testing layout calculation..." -ForegroundColor Yellow
$layout = Calculate-BattleLayout $enemies $boxWidth $boxHeight
Write-Host "Layout calculated - Rows: $($layout.Rows.Count)" -ForegroundColor Green

foreach ($row in $layout.Rows) {
    Write-Host "  Row: Type=$($row.Type), StartY=$($row.StartY), Height=$($row.Height), Enemies=$($row.Enemies.Count)" -ForegroundColor White
}

Write-Host ""
Write-Host "Drawing Mountain Troll battle viewport..." -ForegroundColor Yellow
Write-Host "If the troll doesn't appear below, there's a rendering issue!" -ForegroundColor Red
Write-Host ""

Draw-EnhancedCombatViewport $enemies $boxWidth $boxHeight

Write-Host ""
Write-Host "=== MOUNTAIN TROLL TEST COMPLETE ===" -ForegroundColor Red
Write-Host "Did the Mountain Troll appear in the battle area above? (Y/N)" -ForegroundColor Yellow
