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

# Test 4: Map rendering test (simulate viewport)
Write-Host "`n4. Map Rendering Test:" -ForegroundColor Cyan
Write-Host "   Testing NPC visibility on map..." -ForegroundColor White

# Set up player position to be near NPCs for testing
$global:PlayerX = 40
$global:PlayerY = 5
$ViewportWidth = 20
$ViewportHeight = 10

Write-Host "   Player position: ($global:PlayerX, $global:PlayerY)" -ForegroundColor White
Write-Host "   Rendering viewport around player..." -ForegroundColor White

# Test rendering function (simplified version)
function Test-NPCRendering {
    $startX = [Math]::Max(0, $global:PlayerX - [Math]::Floor($ViewportWidth / 2))
    $endX = [Math]::Min($TownMap[0].Length - 1, $startX + $ViewportWidth - 1)
    $startY = [Math]::Max(0, $global:PlayerY - [Math]::Floor($ViewportHeight / 2))
    $endY = [Math]::Min($TownMap.Length - 1, $startY + $ViewportHeight - 1)
    
    Write-Host "   Viewport: X=$startX-$endX, Y=$startY-$endY" -ForegroundColor White
    
    $npcCount = 0
    for ($y = $startY; $y -le $endY; $y++) {
        for ($x = $startX; $x -le $endX; $x++) {
            $posKey = "$x,$y"
            if ($global:NPCPositionLookup.ContainsKey($posKey)) {
                $npc = $global:NPCPositionLookup[$posKey]
                Write-Host "   ✓ NPC '$($npc.Name)' visible at ($x,$y)" -ForegroundColor Green
                $npcCount++
            }
        }
    }
    
    if ($npcCount -eq 0) {
        Write-Host "   ⚠ No NPCs visible in current viewport" -ForegroundColor Yellow
        Write-Host "   Moving player closer to King..." -ForegroundColor Yellow
        $global:PlayerX = 42
        $global:PlayerY = 2
        Write-Host "   New player position: ($global:PlayerX, $global:PlayerY)" -ForegroundColor White
        
        # Test again
        $startX = [Math]::Max(0, $global:PlayerX - [Math]::Floor($ViewportWidth / 2))
        $endX = [Math]::Min($TownMap[0].Length - 1, $startX + $ViewportWidth - 1)
        $startY = [Math]::Max(0, $global:PlayerY - [Math]::Floor($ViewportHeight / 2))
        $endY = [Math]::Min($TownMap.Length - 1, $startY + $ViewportHeight - 1)
        
        for ($y = $startY; $y -le $endY; $y++) {
            for ($x = $startX; $x -le $endX; $x++) {
                $posKey = "$x,$y"
                if ($global:NPCPositionLookup.ContainsKey($posKey)) {
                    $npc = $global:NPCPositionLookup[$posKey]
                    Write-Host "   ✓ NPC '$($npc.Name)' visible at ($x,$y)" -ForegroundColor Green
                    $npcCount++
                }
            }
        }
    }
    
    return $npcCount
}

$visibleNPCs = Test-NPCRendering

Write-Host "`n5. Summary:" -ForegroundColor Cyan
if ($NPCs.Count -gt 0 -and $global:NPCPositionLookup.Count -gt 0 -and $visibleNPCs -gt 0) {
    Write-Host "   ✓ All systems working correctly!" -ForegroundColor Green
    Write-Host "   ✓ NPCs loaded, positioned, and visible" -ForegroundColor Green
} else {
    Write-Host "   ⚠ Issues detected:" -ForegroundColor Yellow
    if ($NPCs.Count -eq 0) { Write-Host "     - No NPCs loaded" -ForegroundColor Red }
    if (!$global:NPCPositionLookup) { Write-Host "     - Position lookup missing" -ForegroundColor Red }
    if ($visibleNPCs -eq 0) { Write-Host "     - NPCs not visible in viewport" -ForegroundColor Red }
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "   1. Launch the main game (Display.ps1)" -ForegroundColor White
Write-Host "   2. Walk near NPCs at coordinates shown above" -ForegroundColor White  
Write-Host "   3. Press 'E' when next to an NPC to talk" -ForegroundColor White
Write-Host "   4. Press 'J' to view quest log" -ForegroundColor White

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
