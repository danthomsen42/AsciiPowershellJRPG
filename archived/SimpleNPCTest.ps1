# Simple NPC test
. "$PSScriptRoot\Maps.ps1"
. "$PSScriptRoot\QuestSystem.ps1"
. "$PSScriptRoot\NPCs.ps1"

Write-Host "=== NPC Test Results ===" -ForegroundColor Yellow

Write-Host "NPCs variable type: $($global:NPCs.GetType().Name)" -ForegroundColor Cyan
Write-Host "NPCs is array: $($global:NPCs -is [array])" -ForegroundColor Cyan

if ($global:NPCs -is [array]) {
    Write-Host "NPCs count: $($global:NPCs.Length)" -ForegroundColor Green
    foreach ($npc in $global:NPCs) {
        Write-Host "- $($npc.Name) at ($($npc.X),$($npc.Y))" -ForegroundColor White
    }
} else {
    Write-Host "ERROR: NPCs is not an array!" -ForegroundColor Red
}

Write-Host "`nPosition lookup:" -ForegroundColor Cyan
if ($global:NPCPositionLookup) {
    Write-Host "Lookup count: $($global:NPCPositionLookup.Count)" -ForegroundColor Green
    foreach ($key in $global:NPCPositionLookup.Keys) {
        Write-Host "- $key -> $($global:NPCPositionLookup[$key].Name)" -ForegroundColor White
    }
} else {
    Write-Host "ERROR: Position lookup missing!" -ForegroundColor Red
}
