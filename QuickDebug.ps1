# Quick debug test
. .\ViewportRenderer.ps1

# Test the coloring system
$testMap = $global:Maps["StoreMap1"]
$mapWidth = $testMap[0].Length  # Should be 22
$mapHeight = $testMap.Count     # Should be 11
$boxWidth = 80
$boxHeight = 25

Write-Host "StoreMap1 size: $mapWidth x $mapHeight" -ForegroundColor Yellow
Write-Host "Viewport size: $boxWidth x $boxHeight" -ForegroundColor Yellow

$centerMap = ($mapWidth -lt $boxWidth) -or ($mapHeight -lt $boxHeight)
Write-Host "Should center: $centerMap" -ForegroundColor Yellow

if ($centerMap) {
    $mapOffsetX = [math]::Floor(($boxWidth - $mapWidth) / 2)
    $mapOffsetY = [math]::Floor(($boxHeight - $mapHeight) / 2)
    Write-Host "Offsets: X=$mapOffsetX, Y=$mapOffsetY" -ForegroundColor Yellow
    
    $actualBoxWidth = $mapWidth
    $actualBoxHeight = $mapHeight
    Write-Host "Actual box size: $actualBoxWidth x $actualBoxHeight" -ForegroundColor Yellow
}
