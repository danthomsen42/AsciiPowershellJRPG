# Test NPC Loading and Position Index
Write-Host "Testing NPC System..." -ForegroundColor Yellow

# Load systems in correct order
. "$PSScriptRoot\QuestSystem.ps1"
. "$PSScriptRoot\NPCs.ps1"

Write-Host "`nNPC Array Status:" -ForegroundColor Cyan
Write-Host "NPCs defined: $($global:NPCs.Count)" -ForegroundColor White

Write-Host "`nNPC Position Lookup Status:" -ForegroundColor Cyan  
Write-Host "Position entries: $($global:NPCPositionLookup.Count)" -ForegroundColor White

if ($global:NPCPositionLookup.Count -gt 0) {
    Write-Host "`nNPC Positions in Lookup:" -ForegroundColor Green
    foreach ($key in $global:NPCPositionLookup.Keys) {
        $npc = $global:NPCPositionLookup[$key]
        Write-Host "  $key -> $($npc.Name) ($($npc.Char))" -ForegroundColor Gray
    }
} else {
    Write-Host "`nNo NPCs found in position lookup!" -ForegroundColor Red
    Write-Host "Manually updating index..." -ForegroundColor Yellow
    Update-NPCPositionIndex
    Write-Host "After update - Position entries: $($global:NPCPositionLookup.Count)" -ForegroundColor White
}

Write-Host "`nTest NPC Detection:" -ForegroundColor Cyan
$testNPC = $global:NPCPositionLookup["42,2"]
if ($testNPC) {
    Write-Host "King found at 42,2: $($testNPC.Name)" -ForegroundColor Green
} else {
    Write-Host "King NOT found at 42,2" -ForegroundColor Red
}

Write-Host "`nPress any key to continue..." -ForegroundColor DarkGray
[System.Console]::ReadKey($true) | Out-Null
