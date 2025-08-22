# ProcMapIntegration.ps1
# Integration guide and helper functions for adding procedural maps to your JRPG

<#
INTEGRATION GUIDE:
==================

To add procedural map generation to your existing JRPG, follow these steps:

1. Source the ProceduralMaps.ps1 file in your Display.ps1:
   . "$PSScriptRoot\ProceduralMaps.ps1"

2. Modify your $Maps hashtable to include procedural maps
3. Update your DoorRegistry to handle procedural map transitions
4. Add map generation triggers to your game loop

Below are the specific code modifications needed:
#>

# ==============================
# Modified Maps.ps1 Integration
# ==============================

<#
Add this to the end of your Maps.ps1 file:

# Source procedural map generation
. "$PSScriptRoot\ProceduralMaps.ps1"

# Generate some procedural maps and add them to the registry
function Initialize-ProceduralMaps {
    # Generate different types of procedural dungeons
    Add-ProceduralMapToRegistry -MapName "ProcDungeon1" -Type "room" -Seed "dungeon_room_123"
    Add-ProceduralMapToRegistry -MapName "ProcCave1" -Type "cave" -Seed "cave_natural_456" 
    Add-ProceduralMapToRegistry -MapName "ProcMaze1" -Type "maze" -Seed "maze_complex_789"
    
    # You can also generate maps on-demand:
    # $global:Maps["RandomDungeon"] = New-ProceduralMap -Type "room"
}

# Generate maps when Maps.ps1 is loaded
Initialize-ProceduralMaps
#>

# ==============================
# Modified Display.ps1 Integration
# ==============================

<#
Add this function to your Display.ps1 file to handle procedural map transitions:
#>

function Handle-ProceduralMapTransition {
    param($playerX, $playerY, $currentMapName)
    
    # Check for special procedural map triggers
    $currentTile = $global:Maps[$currentMapName][$playerY][$playerX]
    
    if ($currentTile -eq '+') {
        # Standard door handling (your existing code)
        $key = "$currentMapName,$playerX,$playerY"
        if ($global:DoorRegistry.ContainsKey($key)) {
            return $global:DoorRegistry[$key]
        }
    }
    
    # Special procedural map triggers
    if ($currentTile -eq 'P') {  # 'P' for Procedural entrance
        # Generate a new random dungeon each time
        $newMapName = "TempDungeon_$(Get-Random)"
        $mapType = Get-Random -InputObject @("room", "cave", "maze")
        
        Write-Host "Entering procedural $mapType dungeon..." -ForegroundColor Green
        Start-Sleep -Milliseconds 500
        
        $global:Maps[$newMapName] = New-ProceduralMap -Type $mapType
        
        # Find a suitable spawn point in the new map
        $spawnPoint = Find-SafeSpawnPoint $global:Maps[$newMapName]
        
        return @{ 
            Map = $newMapName
            X = $spawnPoint.X
            Y = $spawnPoint.Y
        }
    }
    
    return $null
}

function Find-SafeSpawnPoint {
    param($map)
    
    # Find first open floor space
    for ($y = 1; $y -lt $map.Count - 1; $y++) {
        for ($x = 1; $x -lt $map[0].Length - 1; $x++) {
            if ($map[$y][$x] -eq '.') {
                return @{ X = $x; Y = $y }
            }
        }
    }
    
    # Fallback to center
    return @{ 
        X = [math]::Floor($map[0].Length / 2)
        Y = [math]::Floor($map.Count / 2)
    }
}

# ==============================
# Enhanced Door Registry System
# ==============================

<#
Modify your DoorRegistry in Display.ps1 to include procedural map entries:
#>

function Initialize-EnhancedDoorRegistry {
    # Your existing static doors
    $global:DoorRegistry = @{
        "Town,21,29"    = @{ Map = "Dungeon"; X = 21; Y = 29 }
        "Dungeon,21,29" = @{ Map = "Town";    X = 21; Y = 29 }
        "Dungeon,42,24" = @{ Map = "DungeonMap2";    X = 42; Y = 24 }
        "DungeonMap2,42,10" = @{ Map = "Dungeon";    X = 42; Y = 24 }
    }
    
    # Add procedural map connections
    # Connect town to procedural dungeons
    $global:DoorRegistry["Town,30,15"] = @{ Map = "ProcDungeon1"; X = 5; Y = 25 }
    $global:DoorRegistry["Town,35,20"] = @{ Map = "ProcCave1"; X = 10; Y = 25 }
    
    # Procedural maps can connect back to town or to each other
    $global:DoorRegistry["ProcDungeon1,5,25"] = @{ Map = "Town"; X = 30; Y = 15 }
    $global:DoorRegistry["ProcCave1,10,25"] = @{ Map = "Town"; X = 35; Y = 20 }
    
    # Chain procedural dungeons together
    $global:DoorRegistry["ProcDungeon1,40,5"] = @{ Map = "ProcMaze1"; X = 5; Y = 5 }
    $global:DoorRegistry["ProcMaze1,5,5"] = @{ Map = "ProcDungeon1"; X = 40; Y = 5 }
}

# ==============================
# Seeded Map Generation for Consistency
# ==============================

<#
For maps that should be consistent across playthroughs (like story dungeons),
use seeded generation:
#>

function Generate-StoryDungeon {
    param([string]$StoryProgress)
    
    # Use story progress as seed to ensure consistency
    $seed = "story_$StoryProgress"
    
    switch ($StoryProgress) {
        "early_game" {
            return New-ProceduralMap -Type "room" -Width 60 -Height 25 -Seed $seed
        }
        "mid_game" {
            return New-ProceduralMap -Type "cave" -Width 80 -Height 30 -Seed $seed
        }
        "late_game" {
            return New-ProceduralMap -Type "maze" -Width 100 -Height 35 -Seed $seed
        }
    }
}

# ==============================
# Runtime Map Generation
# ==============================

<#
Add this to your main game loop in Display.ps1 to handle dynamic generation:
#>

function Handle-DynamicMapGeneration {
    param($currentMapName, $playerX, $playerY)
    
    # Check if we're on a special generation trigger
    $tile = $global:Maps[$currentMapName][$playerY][$playerX]
    
    if ($tile -eq 'R') {  # 'R' for Random/Regenerate
        Write-Host "The dungeon shifts around you..." -ForegroundColor Magenta
        
        # Regenerate current map with new seed
        $mapType = "room"  # Or determine based on context
        $global:Maps[$currentMapName] = New-ProceduralMap -Type $mapType
        
        # Find new safe position for player
        $newPos = Find-SafeSpawnPoint $global:Maps[$currentMapName]
        return $newPos
    }
    
    return $null
}

# ==============================
# Map Pool System
# ==============================

<#
For truly random experiences, maintain a pool of pre-generated maps:
#>

$MapPool = @{
    "random_rooms" = @()
    "random_caves" = @() 
    "random_mazes" = @()
}

function Initialize-MapPool {
    param([int]$PoolSize = 5)
    
    Write-Host "Generating map pool..." -ForegroundColor Yellow
    
    # Pre-generate random maps
    for ($i = 0; $i -lt $PoolSize; $i++) {
        $MapPool["random_rooms"] += New-ProceduralMap -Type "room"
        $MapPool["random_caves"] += New-ProceduralMap -Type "cave"
        $MapPool["random_mazes"] += New-ProceduralMap -Type "maze"
    }
    
    Write-Host "Map pool ready!" -ForegroundColor Green
}

function Get-RandomMapFromPool {
    param([string]$Type = "room")
    
    $pool = $MapPool["random_$Type"]
    if ($pool.Count -gt 0) {
        return Get-Random -InputObject $pool
    } else {
        # Fallback to generating new map
        return New-ProceduralMap -Type $Type
    }
}

# ==============================
# Testing and Debug Functions
# ==============================

function Test-ProceduralIntegration {
    Write-Host "=== Testing Procedural Map Integration ===" -ForegroundColor Green
    
    # Test map generation
    Write-Host "Testing map generation..." -ForegroundColor Yellow
    $testMap = New-ProceduralMap -Type "room" -Seed "test123"
    Write-Host "✓ Map generated successfully"
    
    # Test map pool
    Write-Host "Testing map pool..." -ForegroundColor Yellow
    Initialize-MapPool -PoolSize 2
    $poolMap = Get-RandomMapFromPool -Type "room"
    Write-Host "✓ Map pool working"
    
    # Test door finding
    Write-Host "Testing door detection..." -ForegroundColor Yellow
    for ($y = 0; $y -lt $testMap.Count; $y++) {
        for ($x = 0; $x -lt $testMap[0].Length; $x++) {
            if ($testMap[$y][$x] -eq '+') {
                Write-Host "Found door at $x,$y"
            }
        }
    }
    
    Write-Host "✓ Integration test complete!" -ForegroundColor Green
}

# ==============================
# Usage Examples
# ==============================

function Show-IntegrationExamples {
    Write-Host @"
=== USAGE EXAMPLES ===

1. Add to your Maps.ps1:
   . "`$PSScriptRoot\ProceduralMaps.ps1"
   Initialize-ProceduralMaps

2. In your Display.ps1 game loop, replace the map transition check with:
   `$transition = Handle-ProceduralMapTransition `$playerX `$playerY `$CurrentMapName
   if (`$transition) {
       `$CurrentMapName = `$transition.Map
       `$currentMap = `$Maps[`$CurrentMapName]  
       `$playerX = `$transition.X
       `$playerY = `$transition.Y
   }

3. For story dungeons, use seeded generation:
   `$storyDungeon = Generate-StoryDungeon -StoryProgress "early_game"
   `$Maps["Chapter1Dungeon"] = `$storyDungeon

4. For completely random dungeons:
   `$randomDungeon = New-ProceduralMap -Type "cave"
   `$Maps["RandomCave"] = `$randomDungeon

5. To add procedural entrance to existing maps, place 'P' characters:
   In your TownMap, change a '.' to 'P' where you want procedural dungeons

"@ -ForegroundColor Cyan
}
