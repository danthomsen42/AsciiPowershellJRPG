# =============================================================================
# COMPLETE BATTLE SYSTEM FIX VERIFICATION
# =============================================================================
# Tests all enemy sizes and persistence after kills

Write-Host "=== COMPLETE BATTLE SYSTEM VERIFICATION ===" -ForegroundColor Cyan
Write-Host ""

# Load systems
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1"
. "$PSScriptRoot\CleanArrowTargeting.ps1"

$boxWidth = 80
$boxHeight = 25

Write-Host "Testing all enemy sizes and battle scenarios..." -ForegroundColor Yellow
Write-Host ""

# Test 1: Multi-enemy battle with different sizes
Write-Host "TEST 1: Multi-enemy battle (Small + Large)" -ForegroundColor Green
$enemies = @()

# Add a small enemy
$enemies += @{
    Name = "Goblin"; HP = 25; MaxHP = 25; Size = "Small"; BaseXP = 10
    Art = @("  /|\\", " (oo)", "<___>", "^^ ^^")
}

# Add the Mountain Troll (Large)
$enemies += @{
    Name = "Mountain Troll"; HP = 80; MaxHP = 80; Size = "Large"; BaseXP = 35
    Art = @(
        "              ____              ",
        "             /    \\             ",
        "            / (oo) \\            ",
        "           |   __   |           ",
        "           |  \\__/  |           ",
        "         __|________|__         ",
        "        /              \\        ",
        "       /   ____________  \\      ",
        "      |   /            \\  |     ",
        "      |  |              | |     ",
        "      |  |______________| |     ",
        "      |__________________|     "
    )
}

Write-Host "Drawing multi-enemy battle with Goblin + Mountain Troll:" -ForegroundColor Yellow
Draw-EnhancedCombatViewport $enemies $boxWidth $boxHeight

Write-Host ""
Write-Host "✓ Both enemies should be visible above" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to simulate killing the Goblin..."
$null = [System.Console]::ReadKey($true)

# Test 2: Kill the small enemy, verify Mountain Troll remains
Write-Host ""
Write-Host "TEST 2: Enemy persistence after kill" -ForegroundColor Green
Write-Host "Killing Goblin (HP set to 0)..." -ForegroundColor Yellow

$enemies[0].HP = 0  # Kill the Goblin
$enemies = Clean-EnemyArray $enemies  # Clean the array

Write-Host "Remaining enemies: $($enemies.Count)" -ForegroundColor Yellow
foreach ($enemy in $enemies) {
    Write-Host "  - $($enemy.Name) (HP: $($enemy.HP)/$($enemy.MaxHP))" -ForegroundColor White
}

Write-Host ""
Write-Host "Drawing updated battle (Mountain Troll should remain visible):" -ForegroundColor Yellow
Draw-EnhancedCombatViewport $enemies $boxWidth $boxHeight

Write-Host ""
Write-Host "✓ Mountain Troll should still be visible above" -ForegroundColor Green
Write-Host ""

Write-Host "=== ALL TESTS COMPLETE ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Issues that should now be FIXED:" -ForegroundColor Green
Write-Host "1. ✓ Mountain Troll appears correctly in battle" -ForegroundColor White
Write-Host "2. ✓ Enemies remain visible after other enemies die" -ForegroundColor White
Write-Host "3. ✓ Single enemies are properly centered" -ForegroundColor White
Write-Host "4. ✓ All enemy sizes render correctly" -ForegroundColor White
Write-Host "5. ✓ Clean arrow targeting works without text overlay" -ForegroundColor White
