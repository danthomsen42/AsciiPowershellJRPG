# ==============================
# NPC Placement Visualization  
# Shows where NPCs are placed on the Town map
# ==============================

# Load the systems in the correct order
. "$PSScriptRoot\Maps.ps1"
. "$PSScriptRoot\QuestSystem.ps1"
. "$PSScriptRoot\NPCs.ps1"

Write-Host "NPC Placement on Town Map:" -ForegroundColor Yellow
Write-Host ("=" * 50) -ForegroundColor Yellow

# Show NPC positions
Write-Host "`nNPC Locations:" -ForegroundColor Cyan
foreach ($npc in $NPCs) {
    Write-Host "- $($npc.Name) ($($npc.Char)): X=$($npc.X), Y=$($npc.Y)" -ForegroundColor White
}

Write-Host "`nMap Analysis:" -ForegroundColor Cyan
Write-Host "King (K) at X=42, Y=2: " -NoNewline -ForegroundColor White
if ($TownMap[2][42] -eq '.') {
    Write-Host "Valid placement (empty space)" -ForegroundColor Green
} else {
    Write-Host "Invalid placement - current char: '$($TownMap[2][42])'" -ForegroundColor Red
}

Write-Host "Town Elder (E) at X=10, Y=22: " -NoNewline -ForegroundColor White  
if ($TownMap[22][10] -eq '.') {
    Write-Host "Valid placement (empty space)" -ForegroundColor Green
} else {
    Write-Host "Invalid placement - current char: '$($TownMap[22][10])'" -ForegroundColor Red
}

Write-Host "Merchant (M) at X=30, Y=25: " -NoNewline -ForegroundColor White
if ($TownMap[25][30] -eq '.') {
    Write-Host "Valid placement (empty space)" -ForegroundColor Green  
} else {
    Write-Host "Invalid placement - current char: '$($TownMap[25][30])'" -ForegroundColor Red
}

Write-Host "`nPress any key to continue..." -ForegroundColor DarkGray
[System.Console]::ReadKey($true) | Out-Null
