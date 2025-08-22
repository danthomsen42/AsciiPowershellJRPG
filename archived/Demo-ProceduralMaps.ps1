# Demo-ProceduralMaps.ps1
# Quick demonstration of procedural map generation for your JRPG

# Import the procedural map functions
. "$PSScriptRoot\ProceduralMaps.ps1"

function Show-MapDemo {
    param([string]$Type = "all")
    
    Clear-Host
    Write-Host "=== PowerShell JRPG Procedural Map Demo ===" -ForegroundColor Green
    Write-Host ""
    
    if ($Type -eq "all" -or $Type -eq "room") {
        Write-Host "1. ROOM-BASED DUNGEON (Diablo-style)" -ForegroundColor Yellow
        Write-Host "   Features: Connected rooms, corridors, treasure chambers" -ForegroundColor Gray
        $roomMap = New-ProceduralMap -Type "room" -Width 60 -Height 20 -Seed "demo1"
        Display-MapSection $roomMap "Room-Based Map"
        Write-Host ""
        Read-Host "Press Enter to continue..."
        Write-Host ""
    }
    
    if ($Type -eq "all" -or $Type -eq "cave") {
        Write-Host "2. CAVE SYSTEM (Cellular Automata)" -ForegroundColor Yellow
        Write-Host "   Features: Natural cave-like passages, organic layout" -ForegroundColor Gray
        $caveMap = New-ProceduralMap -Type "cave" -Width 60 -Height 20 -Seed "demo2"
        Display-MapSection $caveMap "Cave System"
        Write-Host ""
        Read-Host "Press Enter to continue..."
        Write-Host ""
    }
    
    if ($Type -eq "all" -or $Type -eq "maze") {
        Write-Host "3. MAZE DUNGEON (Recursive Backtracking)" -ForegroundColor Yellow
        Write-Host "   Features: Twisting passages, dead ends with treasures" -ForegroundColor Gray
        $mazeMap = New-ProceduralMap -Type "maze" -Width 60 -Height 20 -Seed "demo3"
        Display-MapSection $mazeMap "Maze Dungeon"
        Write-Host ""
        Read-Host "Press Enter to continue..."
        Write-Host ""
    }
}

function Display-MapSection {
    param($map, $title)
    
    Write-Host "--- $title ---" -ForegroundColor Cyan
    
    # Color coding for display
    foreach ($line in $map) {
        $coloredLine = ""
        foreach ($char in $line.ToCharArray()) {
            switch ($char) {
                '#' { $coloredLine += [char]0x1b + "[90m" + $char }  # Dark gray for walls
                '.' { $coloredLine += [char]0x1b + "[37m" + $char }  # White for floors
                '+' { $coloredLine += [char]0x1b + "[93m" + $char }  # Yellow for doors
                'B' { $coloredLine += [char]0x1b + "[91m" + $char }  # Red for enemies
                'T' { $coloredLine += [char]0x1b + "[92m" + $char }  # Green for treasure
                default { $coloredLine += [char]0x1b + "[37m" + $char }
            }
        }
        $coloredLine += [char]0x1b + "[0m"  # Reset color
        Write-Host $coloredLine
    }
    
    Write-Host ""
    Write-Host "Legend: # = Wall, . = Floor, + = Door, B = Enemy, T = Treasure" -ForegroundColor DarkGray
}

function Test-SeedConsistency {
    Write-Host "=== Testing Seed Consistency ===" -ForegroundColor Green
    Write-Host "Generating the same map twice with seed 'test123'..." -ForegroundColor Yellow
    
    $map1 = New-ProceduralMap -Type "room" -Width 40 -Height 15 -Seed "test123"
    $map2 = New-ProceduralMap -Type "room" -Width 40 -Height 15 -Seed "test123"
    
    $identical = $true
    for ($i = 0; $i -lt $map1.Count; $i++) {
        if ($map1[$i] -ne $map2[$i]) {
            $identical = $false
            break
        }
    }
    
    if ($identical) {
        Write-Host "✓ Seeds produce consistent results!" -ForegroundColor Green
        Write-Host "This means story dungeons will be the same every playthrough." -ForegroundColor Gray
    } else {
        Write-Host "✗ Seed consistency failed" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "First generation:" -ForegroundColor Cyan
    $map1[0..4] | ForEach-Object { Write-Host $_ -ForegroundColor White }
    
    Write-Host ""
    Write-Host "Second generation (should be identical):" -ForegroundColor Cyan
    $map2[0..4] | ForEach-Object { Write-Host $_ -ForegroundColor White }
}
}

function Show-IntegrationInstructions {
    Write-Host "=== HOW TO INTEGRATE INTO YOUR JRPG ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "STEP 1: Add procedural generation to Maps.ps1" -ForegroundColor Yellow
    Write-Host "Add this line to the end of your Maps.ps1:" -ForegroundColor Gray
    Write-Host '    . "$PSScriptRoot\ProceduralMaps.ps1"' -ForegroundColor White
    Write-Host ""
    
    Write-Host "STEP 2: Generate procedural maps" -ForegroundColor Yellow  
    Write-Host "Add these lines after your static map definitions:" -ForegroundColor Gray
    Write-Host '    $Maps["ProcDungeon1"] = New-ProceduralMap -Type "room" -Seed "dungeon1"' -ForegroundColor White
    Write-Host '    $Maps["ProcCave1"] = New-ProceduralMap -Type "cave" -Seed "cave1"' -ForegroundColor White
    Write-Host '    $Maps["ProcMaze1"] = New-ProceduralMap -Type "maze" -Seed "maze1"' -ForegroundColor White
    Write-Host ""
    
    Write-Host "STEP 3: Update your DoorRegistry" -ForegroundColor Yellow
    Write-Host "Add entries to connect your static maps to procedural ones:" -ForegroundColor Gray
    Write-Host '    $DoorRegistry["Town,50,25"] = @{ Map = "ProcDungeon1"; X = 5; Y = 25 }' -ForegroundColor White
    Write-Host '    $DoorRegistry["ProcDungeon1,5,25"] = @{ Map = "Town"; X = 50; Y = 25 }' -ForegroundColor White
    Write-Host ""
    
    Write-Host "STEP 4: Add procedural entrances to existing maps" -ForegroundColor Yellow
    Write-Host "Edit your TownMap and change some '.' characters to 'P' where you want" -ForegroundColor Gray
    Write-Host "procedural dungeon entrances. Then modify your map transition logic to" -ForegroundColor Gray
    Write-Host "handle 'P' tiles." -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "STEP 5: For truly random dungeons" -ForegroundColor Yellow
    Write-Host "Generate maps on-the-fly in your game loop:" -ForegroundColor Gray
    Write-Host '    if ($currentTile -eq "R") {' -ForegroundColor White
    Write-Host '        $randomMap = New-ProceduralMap -Type (Get-Random -InputObject @("room","cave","maze"))' -ForegroundColor White
    Write-Host '        $Maps["TempDungeon"] = $randomMap' -ForegroundColor White
    Write-Host '        # Transition player to TempDungeon' -ForegroundColor White
    Write-Host '    }' -ForegroundColor White
    Write-Host ""
    
    Write-Host "BENEFITS:" -ForegroundColor Green
    Write-Host "- Infinite replayability" -ForegroundColor Gray
    Write-Host "- Different dungeon types for variety" -ForegroundColor Gray
    Write-Host "- Consistent story dungeons with seeds" -ForegroundColor Gray
    Write-Host "- Easy to add to existing codebase" -ForegroundColor Gray
    Write-Host "- Maintains your current map/door system" -ForegroundColor Gray
}

# Main demo menu
function Start-Demo {
    do {
        Clear-Host
        Write-Host "=== Procedural Map Generation Demo ===" -ForegroundColor Green
        Write-Host ""
        Write-Host "1. Show all map types" -ForegroundColor Yellow
        Write-Host "2. Show room-based dungeons only" -ForegroundColor Yellow  
        Write-Host "3. Show cave systems only" -ForegroundColor Yellow
        Write-Host "4. Show maze dungeons only" -ForegroundColor Yellow
        Write-Host "5. Test seed consistency" -ForegroundColor Yellow
        Write-Host "6. Show integration instructions" -ForegroundColor Yellow
        Write-Host "Q. Quit" -ForegroundColor Yellow
        Write-Host ""
        
        $choice = Read-Host "Select option"
        
        switch ($choice.ToUpper()) {
            "1" { Show-MapDemo -Type "all" }
            "2" { Show-MapDemo -Type "room" }
            "3" { Show-MapDemo -Type "cave" } 
            "4" { Show-MapDemo -Type "maze" }
            "5" { Test-SeedConsistency; Read-Host "Press Enter to continue" }
            "6" { Show-IntegrationInstructions; Read-Host "Press Enter to continue" }
            "Q" { return }
            default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
        }
    } while ($true)
}
}

# Start the demo
if ($MyInvocation.InvocationName -ne '.') {
    Start-Demo
}
