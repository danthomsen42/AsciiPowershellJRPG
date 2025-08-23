# Debug the coloring issue
. .\ViewportRenderer.ps1
. .\Display.ps1

# Show current party positions
Write-Host "Party positions:" -ForegroundColor Yellow
foreach ($key in $partyPositions.Keys) {
    $member = $partyPositions[$key]
    Write-Host "  $key -> $($member.Symbol) ($($member.Class))" -ForegroundColor White
}

# Show current map info
Write-Host "Current map: $CurrentMapName" -ForegroundColor Yellow
$currentMap = $global:Maps[$CurrentMapName]
Write-Host "Map size: $($currentMap[0].Length) x $($currentMap.Count)" -ForegroundColor Yellow

Write-Host "Player position: $playerX, $playerY" -ForegroundColor Yellow

Write-Host "Press any key to continue..." -ForegroundColor DarkGray
$null = [System.Console]::ReadKey($true)
