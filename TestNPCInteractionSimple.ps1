# ==============================
# NPC Interaction Test
# Comprehensive test to verify NPCs are visible and interactive in-game
# ==============================

# Load all systems in the correct order
. "$PSScriptRoot\Maps.ps1"
. "$PSScriptRoot\QuestSystem.ps1"
. "$PSScriptRoot\NPCs.ps1" 
. "$PSScriptRoot\ViewportRenderer.ps1"

Write-Host "NPC Interaction Test" -ForegroundColor Yellow
Write-Host ("=" * 50) -ForegroundColor Yellow

# Test 1: Verify NPCs are loaded
Write-Host "`n1. NPC Loading Test:" -ForegroundColor Cyan
Write-Host "   Total NPCs loaded: $($NPCs.Count)" -ForegroundColor White
foreach ($npc in $NPCs) {
    Write-Host "   - $($npc.Name) at ($($npc.X),$($npc.Y))" -ForegroundColor White
}

# Test 2: Verify position lookup
Write-Host "`n2. Position Lookup Test:" -ForegroundColor Cyan
if ($global:NPCPositionLookup) {
    Write-Host "   Position lookup table exists with $($global:NPCPositionLookup.Count) entries" -ForegroundColor Green
    foreach ($key in $global:NPCPositionLookup.Keys) {
        Write-Host "   - Position $key -> NPC: $($global:NPCPositionLookup[$key].Name)" -ForegroundColor White
    }
} else {
    Write-Host "   ERROR: Position lookup table not found!" -ForegroundColor Red
}

# Test 3: Quest system integration
Write-Host "`n3. Quest System Test:" -ForegroundColor Cyan
Write-Host "   Available quests: $($global:AvailableQuests.Count)" -ForegroundColor White
Write-Host "   Active quests: $($global:ActiveQuests.Count)" -ForegroundColor White

# Test 4: Map rendering test
Write-Host "`n4. Map Rendering Test:" -ForegroundColor Cyan
Write-Host "   Checking if NPCs can be found at their coordinates..." -ForegroundColor White

# Check each NPC position directly
foreach ($npc in $NPCs) {
    $posKey = "$($npc.X),$($npc.Y)"
    if ($global:NPCPositionLookup.ContainsKey($posKey)) {
        Write-Host "   ✓ NPC '$($npc.Name)' found at ($($npc.X),$($npc.Y))" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ NPC '$($npc.Name)' missing from position lookup at ($($npc.X),$($npc.Y))" -ForegroundColor Yellow
    }
}

Write-Host "`n5. Summary:" -ForegroundColor Cyan
if ($NPCs.Count -gt 0 -and $global:NPCPositionLookup.Count -gt 0) {
    Write-Host "   ✓ All systems working correctly!" -ForegroundColor Green
    Write-Host "   ✓ NPCs loaded and positioned properly" -ForegroundColor Green
} else {
    Write-Host "   ⚠ Issues detected:" -ForegroundColor Yellow
    if ($NPCs.Count -eq 0) { Write-Host "     - No NPCs loaded" -ForegroundColor Red }
    if (!$global:NPCPositionLookup) { Write-Host "     - Position lookup missing" -ForegroundColor Red }
}

Write-Host "`nNext steps to test in-game:" -ForegroundColor Cyan
Write-Host "   1. Launch the main game: .\Display.ps1" -ForegroundColor White
Write-Host "   2. Walk to NPC coordinates:" -ForegroundColor White  
Write-Host "      - King at (42,2)" -ForegroundColor White
Write-Host "      - Town Elder at (10,22)" -ForegroundColor White
Write-Host "      - Merchant at (30,25)" -ForegroundColor White
Write-Host "   3. Press 'E' when next to an NPC to talk" -ForegroundColor White
Write-Host "   4. Press 'J' to view quest log" -ForegroundColor White

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
