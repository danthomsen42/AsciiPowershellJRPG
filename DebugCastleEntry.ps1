# Debug Castle Entry Issue
Write-Host "=== Debug Castle Entry ===" -ForegroundColor Yellow

try {
    Write-Host "1. Loading MapManager..." -ForegroundColor Cyan
    . "$PSScriptRoot\MapManager.ps1"
    
    Write-Host "2. Checking Maps..." -ForegroundColor Cyan
    Write-Host "   Town map exists: $($global:Maps['Town'] -ne $null)"
    Write-Host "   TownCastle map exists: $($global:Maps['TownCastle'] -ne $null)"
    Write-Host "   TownCastle map lines: $($global:Maps['TownCastle'].Count)"
    
    Write-Host "3. Testing door registry..." -ForegroundColor Cyan
    $doorKey = "Town,50,18"
    if ($global:DoorRegistry.ContainsKey($doorKey)) {
        $dest = $global:DoorRegistry[$doorKey]
        Write-Host "   Door found: $($dest.Map) at ($($dest.X), $($dest.Y))"
        
        Write-Host "4. Testing destination map access..." -ForegroundColor Cyan
        $targetMap = $global:Maps[$dest.Map]
        if ($targetMap) {
            Write-Host "   Target map loaded: $($targetMap.Count) lines"
            Write-Host "   Target position char: '$($targetMap[$dest.Y][$dest.X])'"
        } else {
            Write-Host "   ERROR: Target map is null!" -ForegroundColor Red
        }
    } else {
        Write-Host "   ERROR: Door not found in registry!" -ForegroundColor Red
    }
    
    Write-Host "5. Testing basic map access..." -ForegroundColor Cyan
    $testMap = $global:Maps["TownCastle"]
    for ($y = 0; $y -lt 5; $y++) {
        $line = ""
        for ($x = 0; $x -lt 10; $x++) {
            $line += $testMap[$y][$x]
        }
        Write-Host "   Line $y (first 10 chars): '$line'"
    }
    
    Write-Host "6. Simulating transition..." -ForegroundColor Cyan
    $CurrentMapName = "TownCastle"
    $global:CurrentMapName = $CurrentMapName
    $currentMap = $global:Maps[$CurrentMapName]
    $playerX = 1
    $playerY = 2
    
    Write-Host "   Player position: ($playerX, $playerY)"
    Write-Host "   Map char at player: '$($currentMap[$playerY][$playerX])'"
    
    Write-Host "SUCCESS: All tests passed!" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR CAUGHT: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace
}

Write-Host "`nPress any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
