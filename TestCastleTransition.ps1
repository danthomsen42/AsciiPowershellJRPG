# Test Castle Entry Simulation
Write-Host "=== Simulating Castle Entry Scenario ===" -ForegroundColor Yellow

try {
    # Load all required systems
    Write-Host "Loading systems..." -ForegroundColor Cyan
    . "$PSScriptRoot\QuestSystem.ps1"
    . "$PSScriptRoot\NPCs.ps1"
    . "$PSScriptRoot\Maps.ps1"
    . "$PSScriptRoot\MapManager.ps1"
    
    # Simulate being in Town at the castle door
    Write-Host "Setting up scenario: Player at castle door..." -ForegroundColor Cyan
    $CurrentMapName = "Town"
    $global:CurrentMapName = $CurrentMapName
    $currentMap = $global:Maps[$CurrentMapName]
    $playerX = 50
    $playerY = 18
    
    Write-Host "Player at Town ($playerX, $playerY): '$($currentMap[$playerY][$playerX])'"
    
    # Check if on door
    if ($currentMap[$playerY][$playerX] -eq '+') {
        Write-Host "Player is on a door! Simulating transition..." -ForegroundColor Yellow
        
        $key = "$CurrentMapName,$playerX,$playerY"
        Write-Host "Door key: '$key'"
        
        if ($global:DoorRegistry.ContainsKey($key)) {
            $dest = $global:DoorRegistry[$key]
            Write-Host "Destination: $($dest.Map) at ($($dest.X), $($dest.Y))"
            
            # Simulate transition
            $NewMapName = $dest.Map
            $newMap = $global:Maps[$NewMapName]
            $newPlayerX = $dest.X
            $newPlayerY = $dest.Y
            
            Write-Host "Transitioning to $NewMapName..."
            
            # Test the new map
            if ($newMap -and $newMap.Count -gt $newPlayerY -and $newMap[$newPlayerY].Length -gt $newPlayerX) {
                Write-Host "New position ($newPlayerX, $newPlayerY): '$($newMap[$newPlayerY][$newPlayerX])'"
                
                # Simulate movement bounds checking for new map
                Write-Host "Testing movement bounds in new map..." -ForegroundColor Cyan
                $testX = [math]::Min($newMap[0].Length - 1, $newPlayerX + 1)
                $testY = [math]::Min($newMap.Count - 1, $newPlayerY + 1)
                Write-Host "Right move test: X=$testX (max: $($newMap[0].Length - 1))"
                Write-Host "Down move test: Y=$testY (max: $($newMap.Count - 1))"
                
                # Test accessing positions
                Write-Host "Testing array access..." -ForegroundColor Cyan
                for ($y = 0; $y -lt [math]::Min(5, $newMap.Count); $y++) {
                    for ($x = 0; $x -lt [math]::Min(10, $newMap[0].Length); $x++) {
                        $char = $newMap[$y][$x]
                        # Just access the character - this is where errors might occur
                    }
                }
                Write-Host "Array access test passed!"
                
                Write-Host "SUCCESS: Castle entry simulation completed!" -ForegroundColor Green
            } else {
                Write-Host "ERROR: Invalid destination position or map!" -ForegroundColor Red
            }
        } else {
            Write-Host "ERROR: Door not found in registry!" -ForegroundColor Red
        }
    } else {
        Write-Host "ERROR: Player not on a door tile!" -ForegroundColor Red
    }
    
} catch {
    Write-Host "ERROR CAUGHT: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
    Write-Host "Stack Trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace
}

Write-Host "`nPress any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
