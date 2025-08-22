# Debug NPC Visibility
Write-Host "Loading systems..." -ForegroundColor Yellow

# Load in same order as Display.ps1  
. "$PSScriptRoot\QuestSystem.ps1"
. "$PSScriptRoot\NPCs.ps1"
. "$PSScriptRoot\Maps.ps1"
. "$PSScriptRoot\MapManager.ps1"

Write-Host "`nNPC Status Check:" -ForegroundColor Cyan
Write-Host "Total NPCs: $($global:NPCs.Count)"
Write-Host "Position entries: $($global:NPCPositionLookup.Count)"

Write-Host "`nNPC Coordinates vs Map:" -ForegroundColor Cyan
$currentMap = $global:Maps["Town"]

foreach ($npc in $global:NPCs) {
    Write-Host "`n$($npc.Name) at ($($npc.X), $($npc.Y)):" -ForegroundColor White
    Write-Host "  Map character at position: '$($currentMap[$npc.Y][$npc.X])'" -ForegroundColor Gray
    Write-Host "  NPC character: '$($npc.Char)'" -ForegroundColor Gray
    Write-Host "  Lookup key: '$($npc.X),$($npc.Y)'" -ForegroundColor Gray
    
    $lookupNPC = $global:NPCPositionLookup["$($npc.X),$($npc.Y)"]
    if ($lookupNPC) {
        Write-Host "  ✓ Found in position lookup" -ForegroundColor Green
    } else {
        Write-Host "  ✗ NOT found in position lookup" -ForegroundColor Red
    }
}

Write-Host "`nTesting Player at NPC Positions:" -ForegroundColor Cyan
$testPositions = @("42,2", "25,10", "15,23")

foreach ($pos in $testPositions) {
    $coords = $pos.Split(",")
    $x = [int]$coords[0]  
    $y = [int]$coords[1]
    
    Write-Host "`nPlayer at ($x, $y):" -ForegroundColor White
    $npcHere = $global:NPCPositionLookup["$x,$y"]
    if ($npcHere) {
        Write-Host "  ✓ Would see: Press E to talk to $($npcHere.Name) ($($npcHere.Char))" -ForegroundColor Green
    } else {
        Write-Host "  ✗ No NPC detected" -ForegroundColor Red
    }
}

Write-Host "`nPress any key to exit..." -ForegroundColor DarkGray
[System.Console]::ReadKey($true) | Out-Null
