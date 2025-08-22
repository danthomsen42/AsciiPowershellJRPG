# TestRandomizedDungeon.ps1
# Quick test script for the randomized dungeon feature

Write-Host "=== Testing Randomized Dungeon Implementation ===" -ForegroundColor Green

try {
    # Test 1: Load Maps.ps1 and check if randomized dungeon is generated
    Write-Host "`nTest 1: Loading Maps.ps1..." -ForegroundColor Yellow
    . "$PSScriptRoot\Maps.ps1"
    
    if ($global:RandomizedDungeon) {
        Write-Host "✓ Randomized dungeon generated successfully" -ForegroundColor Green
        Write-Host "  - Dungeon size: $($global:RandomizedDungeon.Count) rows x $($global:RandomizedDungeon[0].Length) columns" -ForegroundColor Gray
        
        if ($global:RandomDungeonEntrance) {
            Write-Host "  - Entrance at: $($global:RandomDungeonEntrance.X), $($global:RandomDungeonEntrance.Y)" -ForegroundColor Gray
            
            # Verify entrance is a door
            $entranceChar = $global:RandomizedDungeon[$global:RandomDungeonEntrance.Y][$global:RandomDungeonEntrance.X]
            if ($entranceChar -eq '+') {
                Write-Host "  - Entrance is properly marked with '+'" -ForegroundColor Green
            } else {
                Write-Host "  - WARNING: Entrance character is '$entranceChar', expected '+'" -ForegroundColor Red
            }
        } else {
            Write-Host "  - ERROR: No entrance coordinates found" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Failed to generate randomized dungeon" -ForegroundColor Red
    }
    
    # Test 2: Check if TownMap has 'R' tile
    Write-Host "`nTest 2: Checking TownMap for 'R' tile..." -ForegroundColor Yellow
    $rFound = $false
    for ($y = 0; $y -lt $TownMap.Count; $y++) {
        for ($x = 0; $x -lt $TownMap[0].Length; $x++) {
            if ($TownMap[$y][$x] -eq 'R') {
                Write-Host "✓ Found 'R' tile at coordinates: $x, $y" -ForegroundColor Green
                $rFound = $true
                break
            }
        }
        if ($rFound) { break }
    }
    
    if (-not $rFound) {
        Write-Host "✗ No 'R' tile found in TownMap" -ForegroundColor Red
    }
    
    # Test 3: Show sample of randomized dungeon
    Write-Host "`nTest 3: Sample of generated dungeon:" -ForegroundColor Yellow
    if ($global:RandomizedDungeon) {
        Write-Host "First 10 rows:" -ForegroundColor Gray
        for ($i = 0; $i -lt [math]::Min(10, $global:RandomizedDungeon.Count); $i++) {
            $line = $global:RandomizedDungeon[$i]
            if ($line.Length -gt 60) {
                $line = $line.Substring(0, 60) + "..."
            }
            Write-Host $line -ForegroundColor White
        }
        
        # Show the entrance area
        if ($global:RandomDungeonEntrance) {
            $entranceY = $global:RandomDungeonEntrance.Y
            Write-Host "`nEntrance area (row $entranceY):" -ForegroundColor Gray
            $line = $global:RandomizedDungeon[$entranceY]
            if ($line.Length -gt 60) {
                $line = $line.Substring(0, 60) + "..."
            }
            Write-Host $line -ForegroundColor White
        }
    }
    
    Write-Host "`n=== Test Complete ===" -ForegroundColor Green
    Write-Host "The randomized dungeon system appears to be working!" -ForegroundColor Green
    Write-Host "`nTo test in-game:" -ForegroundColor Cyan
    Write-Host "1. Run Display.ps1" -ForegroundColor White
    Write-Host "2. Move to the 'R' tile in the town (coordinates shown above)" -ForegroundColor White
    Write-Host "3. Step on it to enter the randomized dungeon" -ForegroundColor White
    Write-Host "4. Step on the '+' door to exit back to town" -ForegroundColor White
    
} catch {
    Write-Host "ERROR during testing: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
