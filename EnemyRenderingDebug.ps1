# =============================================================================
# ENEMY RENDERING DEBUG TEST
# =============================================================================
# Detailed debugging to find why enemies vanish or don't appear

Write-Host "=== ENEMY RENDERING DEBUG ===" -ForegroundColor Red
Write-Host "Investigating enemy disappearance issues..." -ForegroundColor Yellow
Write-Host ""

# Load required systems
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1"

$boxWidth = 80
$boxHeight = 25

# Test different enemy sizes to see which ones work/fail
Write-Host "Creating test enemies of each size..." -ForegroundColor Cyan

$testEnemies = @()

# Small enemy
$testEnemies += @{
    Name = "Test Goblin"
    HP = 20; MaxHP = 20
    Size = "Small"
    Art = @("  /|\\", " (oo)", "<___>")
}

# Medium enemy  
$testEnemies += @{
    Name = "Test Orc"
    HP = 30; MaxHP = 30
    Size = "Medium"
    Art = @("  ___", " /ORC\\", "( o-o )", " \\___/")
}

# Large enemy (like Mountain Troll)
$testEnemies += @{
    Name = "Test Mountain Troll"
    HP = 80; MaxHP = 80
    Size = "Large"
    Art = @(
        "    .-.___.-.",
        "   /           \\",
        "  | MOUNTAIN     |", 
        "  |   TROLL      |",
        "   \\           /",
        "    '-..___.-'",
        "      |     |",
        "     /|     |\\",
        "    / |     | \\",
        "   /  |_____|  \\",
        "      |     |",
        "     ^^^   ^^^"
    )
}

Write-Host "Testing each enemy size individually..." -ForegroundColor Green
Write-Host ""

# Test 1: Small enemy only
Write-Host "TEST 1: Small Enemy Only" -ForegroundColor Yellow
$smallOnly = @($testEnemies[0])
Write-Host "Enemy count: $($smallOnly.Count)"
Write-Host "Enemy: $($smallOnly[0].Name) - HP: $($smallOnly[0].HP) - Size: $($smallOnly[0].Size)"

$layout = Calculate-BattleLayout $smallOnly $boxWidth $boxHeight
Write-Host "Layout rows: $($layout.Rows.Count)"
foreach ($row in $layout.Rows) {
    Write-Host "  Row: Type=$($row.Type), StartY=$($row.StartY), Enemies=$($row.Enemies.Count)"
}

Draw-EnhancedCombatViewport $smallOnly $boxWidth $boxHeight

Write-Host ""
Write-Host "Press any key to test medium enemy..."
$null = [System.Console]::ReadKey($true)

# Test 2: Medium enemy only  
Write-Host "TEST 2: Medium Enemy Only" -ForegroundColor Yellow
$mediumOnly = @($testEnemies[1])
Write-Host "Enemy count: $($mediumOnly.Count)"
Write-Host "Enemy: $($mediumOnly[0].Name) - HP: $($mediumOnly[0].HP) - Size: $($mediumOnly[0].Size)"

$layout = Calculate-BattleLayout $mediumOnly $boxWidth $boxHeight
Write-Host "Layout rows: $($layout.Rows.Count)"
foreach ($row in $layout.Rows) {
    Write-Host "  Row: Type=$($row.Type), StartY=$($row.StartY), Enemies=$($row.Enemies.Count)"
}

Draw-EnhancedCombatViewport $mediumOnly $boxWidth $boxHeight

Write-Host ""
Write-Host "Press any key to test large enemy (Mountain Troll)..."
$null = [System.Console]::ReadKey($true)

# Test 3: Large enemy only (the problematic Mountain Troll)
Write-Host "TEST 3: Large Enemy Only (Mountain Troll)" -ForegroundColor Yellow
$largeOnly = @($testEnemies[2])
Write-Host "Enemy count: $($largeOnly.Count)"
Write-Host "Enemy: $($largeOnly[0].Name) - HP: $($largeOnly[0].HP) - Size: $($largeOnly[0].Size)"
Write-Host "Art lines: $($largeOnly[0].Art.Count)"

$layout = Calculate-BattleLayout $largeOnly $boxWidth $boxHeight
Write-Host "Layout rows: $($layout.Rows.Count)"
foreach ($row in $layout.Rows) {
    Write-Host "  Row: Type=$($row.Type), StartY=$($row.StartY), Enemies=$($row.Enemies.Count)"
}

Write-Host ""
Write-Host "Drawing Mountain Troll..." -ForegroundColor Red
Draw-EnhancedCombatViewport $largeOnly $boxWidth $boxHeight

Write-Host ""
Write-Host "=== DEBUG COMPLETE ===" -ForegroundColor Red
Write-Host "Check which enemy types appeared correctly above." -ForegroundColor Yellow
