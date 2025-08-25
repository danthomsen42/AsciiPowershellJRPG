# Test Map Loading - Verify Town map loads correctly
Write-Host "=== Map Loading Test ===" -ForegroundColor Yellow

# Load map manager
. "$PSScriptRoot\MapManager.ps1"

Write-Host "Available maps:" -ForegroundColor Cyan
$global:Maps.Keys | ForEach-Object { Write-Host "- $_" }

Write-Host "`nTesting default map loading:" -ForegroundColor Yellow
$testMapName = "Town"
$testMap = $global:Maps[$testMapName]

if ($testMap) {
    Write-Host "✅ SUCCESS: Map '$testMapName' loaded correctly" -ForegroundColor Green
    Write-Host "Map size: $($testMap.Count) lines, $($testMap[0].Length) characters wide" -ForegroundColor Cyan
    Write-Host "First line: $($testMap[0])" -ForegroundColor Gray
} else {
    Write-Host "❌ ERROR: Map '$testMapName' failed to load" -ForegroundColor Red
    Write-Host "Available maps in Maps variable:" -ForegroundColor Yellow
    $global:Maps.Keys | ForEach-Object { Write-Host "  $_" }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Yellow
