# QuickTest.ps1 - Simple functionality test

Write-Host "=== Quick Randomized Dungeon Test ===" -ForegroundColor Green

# Load the Maps
. .\Maps.ps1

Write-Host "✓ Maps loaded" -ForegroundColor Green
Write-Host "  Randomized dungeon: $($global:RandomizedDungeon.Count) rows" -ForegroundColor Gray
Write-Host "  Entrance at: $($global:RandomDungeonEntrance.X), $($global:RandomDungeonEntrance.Y)" -ForegroundColor Gray

# Check if R tile exists in town
$rFound = $false
for ($y = 0; $y -lt $TownMap.Count; $y++) {
    $rIndex = $TownMap[$y].IndexOf('R')
    if ($rIndex -ge 0) {
        Write-Host "✓ R tile found at: $rIndex, $y" -ForegroundColor Green
        $rFound = $true
        break
    }
}

if (-not $rFound) {
    Write-Host "✗ R tile not found in TownMap" -ForegroundColor Red
}

# Show entrance area of dungeon
Write-Host "Entrance area of randomized dungeon:" -ForegroundColor Yellow
$entranceY = $global:RandomDungeonEntrance.Y
for ($i = [math]::Max(0, $entranceY - 2); $i -le [math]::Min($global:RandomizedDungeon.Count - 1, $entranceY + 2); $i++) {
    $line = $global:RandomizedDungeon[$i]
    $prefix = if ($i -eq $entranceY) { ">>> " } else { "    " }
    Write-Host "$prefix$line" -ForegroundColor $(if ($i -eq $entranceY) { "Cyan" } else { "Gray" })
}

Write-Host "Setup looks good! Try running Display.ps1 and walk to the R tile." -ForegroundColor Green
