# Test script to demonstrate map-aware NPC system
# Loads NPCs and demonstrates the Move-NPC functionality

. .\NPCs.ps1

Write-Host "=== Map-Aware NPC System Demonstration ===" -ForegroundColor Cyan
Write-Host ""

# Show initial NPC positions
Write-Host "Initial NPC Positions:" -ForegroundColor Green
foreach ($npc in $global:NPCs) {
    Write-Host "  $($npc.Name): Map '$($npc.Map)' at ($($npc.X), $($npc.Y))" -ForegroundColor White
}

Write-Host ""
Write-Host "Testing Get-NPCAtPosition function:" -ForegroundColor Green

# Test getting NPCs on different maps
$kingInCastle = Get-NPCAtPosition 36 2 "TownCastle"
if ($kingInCastle) {
    Write-Host "  Found King in TownCastle: $($kingInCastle.Name)" -ForegroundColor White
} else {
    Write-Host "  No King found in TownCastle at (36,2)" -ForegroundColor Red
}

$elderInTown = Get-NPCAtPosition 10 22 "Town"
if ($elderInTown) {
    Write-Host "  Found NPC in Town: $($elderInTown.Name)" -ForegroundColor White
} else {
    Write-Host "  No NPC found in Town at (10,22)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Testing Move-NPC functionality:" -ForegroundColor Green

# Move King to Town square
Write-Host "  Moving King from TownCastle to Town square..." -ForegroundColor Yellow
Move-NPC "King" "Town" 15 15

# Verify the move
$kingInTown = Get-NPCAtPosition 15 15 "Town"
if ($kingInTown) {
    Write-Host "  ✅ Success! King is now in Town at (15,15)" -ForegroundColor Green
} else {
    Write-Host "  ❌ Failed! King not found in expected position" -ForegroundColor Red
}

# Check that King is no longer in castle
$kingStillInCastle = Get-NPCAtPosition 36 2 "TownCastle" 
if ($kingStillInCastle) {
    Write-Host "  ❌ Problem: King still found in TownCastle" -ForegroundColor Red
} else {
    Write-Host "  ✅ Good: King no longer in TownCastle" -ForegroundColor Green
}

Write-Host ""
Write-Host "Final NPC Positions:" -ForegroundColor Green
foreach ($npc in $global:NPCs) {
    Write-Host "  $($npc.Name): Map '$($npc.Map)' at ($($npc.X), $($npc.Y))" -ForegroundColor White
}

Write-Host ""
Write-Host "Story Progression Example:" -ForegroundColor Cyan
Write-Host "  - King starts in TownCastle (throne room)" -ForegroundColor White
Write-Host "  - After rescuing princess, King moves to Town square for celebration" -ForegroundColor White
Write-Host "  - During siege, King could move to dungeon for safety" -ForegroundColor White
Write-Host "  - NPCs can be repositioned dynamically as story unfolds!" -ForegroundColor White

Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor DarkGray
$null = [System.Console]::ReadKey($true)
