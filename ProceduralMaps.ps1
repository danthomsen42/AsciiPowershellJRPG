# ProceduralMaps.ps1
# Procedural map generation for PowerShell JRPG
# Multiple algorithms for different dungeon types

# ==============================
# Room-Based Generation (Diablo-style)
# ==============================

# Pre-made room templates
$RoomTemplates = @{
    "small_empty" = @(
        ".........",
        ".........",
        ".........",
        ".........",
        "........."
    )
    "small_pillars" = @(
        ".........",
        "..#...#..",
        ".........",
        "..#...#..",
        "........."
    )
    "treasure" = @(
        ".........",
        "..#####..",
        "..#...#..",
        "..#.T.#..",
        "..#####.."
    )
    "enemy_nest" = @(
        ".........",
        "..#...#..",
        "....B....",
        "..#...#..",
        "........."
    )
    "corridor_ns" = @(
        "....#....",
        "....#....",
        "....#....",
        "....#....",
        "....#...."
    )
    "corridor_ew" = @(
        ".........",
        ".........",
        "#########",
        ".........",
        "........."
    )
    "intersection" = @(
        "....#....",
        "....#....",
        "#########",
        "....#....",
        "....#...."
    )
}

function New-RoomBasedMap {
    param(
        [int]$Width = 80,
        [int]$Height = 30,
        [int]$RoomSize = 9,
        [string]$Seed = (Get-Random)
    )
    
    # Set random seed for reproducible maps
    [System.Random]$rng = [System.Random]::new($Seed.GetHashCode())
    
    # Initialize map with walls
    $map = @()
    for ($y = 0; $y -lt $Height; $y++) {
        $map += "#" * $Width
    }
    
    # Calculate grid dimensions
    $roomsX = [math]::Floor($Width / $RoomSize)
    $roomsY = [math]::Floor($Height / $RoomSize)
    
    # Place rooms in grid pattern - ensure we have at least some rooms
    $roomGrid = @{}
    $placedRooms = @()
    
    for ($gy = 0; $gy -lt $roomsY; $gy++) {
        for ($gx = 0; $gx -lt $roomsX; $gx++) {
            # 75% chance to place a room (increased from 70%)
            if ($rng.NextDouble() -lt 0.75) {
                $roomTypes = @("small_empty", "small_pillars", "enemy_nest")
                if ($rng.NextDouble() -lt 0.1) { $roomTypes += "treasure" }
                
                $roomType = $roomTypes[$rng.Next($roomTypes.Count)]
                $roomGrid["$gx,$gy"] = $roomType
                $placedRooms += @{ X = $gx; Y = $gy; Type = $roomType }
                
                # Place room on map
                $startX = $gx * $RoomSize
                $startY = $gy * $RoomSize
                
                $template = $RoomTemplates[$roomType]
                for ($ry = 0; $ry -lt $template.Count; $ry++) {
                    $mapY = $startY + $ry
                    if ($mapY -lt $Height) {
                        $row = $map[$mapY].ToCharArray()
                        for ($rx = 0; $rx -lt $template[$ry].Length; $rx++) {
                            $mapX = $startX + $rx
                            if ($mapX -lt $Width) {
                                $row[$mapX] = $template[$ry][$rx]
                            }
                        }
                        $map[$mapY] = -join $row
                    }
                }
            }
        }
    }
    
    # Ensure we have at least one room
    if ($placedRooms.Count -eq 0) {
        $gx = [math]::Floor($roomsX / 2)
        $gy = [math]::Floor($roomsY / 2)
        $roomType = "small_empty"
        $roomGrid["$gx,$gy"] = $roomType
        $placedRooms += @{ X = $gx; Y = $gy; Type = $roomType }
        
        # Place the room
        $startX = $gx * $RoomSize
        $startY = $gy * $RoomSize
        $template = $RoomTemplates[$roomType]
        for ($ry = 0; $ry -lt $template.Count; $ry++) {
            $mapY = $startY + $ry
            if ($mapY -lt $Height) {
                $row = $map[$mapY].ToCharArray()
                for ($rx = 0; $rx -lt $template[$ry].Length; $rx++) {
                    $mapX = $startX + $rx
                    if ($mapX -lt $Width) {
                        $row[$mapX] = $template[$ry][$rx]
                    }
                }
                $map[$mapY] = -join $row
            }
        }
    }
    
    # Connect all rooms using minimum spanning tree approach
    $map = Connect-AllRooms $map $placedRooms $RoomSize $rng
    
    # Add entrance and exit
    $map = Add-MapEntrances $map $rng
    
    # Ensure solid border around the entire map
    $map = Add-SolidBorder $map
    
    return $map
}

# New function to ensure all rooms are connected
function Connect-AllRooms {
    param($map, $rooms, $roomSize, $rng)
    
    if ($rooms.Count -le 1) {
        return $map
    }
    
    # Create a list of connected components (initially each room is its own component)
    $components = @{}
    for ($i = 0; $i -lt $rooms.Count; $i++) {
        $components[$i] = @($i)
    }
    
    # Connect rooms until all are in one component
    $connected = @()
    $roomsToConnect = $rooms | Sort-Object { $rng.Next() }  # Randomize order
    
    # Start with first room as connected
    $connectedRooms = @($roomsToConnect[0])
    $remainingRooms = $roomsToConnect[1..($roomsToConnect.Count - 1)]
    
    # Connect each remaining room to the nearest connected room
    while ($remainingRooms.Count -gt 0) {
        $bestConnection = $null
        $bestDistance = [int]::MaxValue
        $bestRoomIndex = -1
        
        # Find the closest room to connect
        for ($i = 0; $i -lt $remainingRooms.Count; $i++) {
            $room = $remainingRooms[$i]
            
            foreach ($connectedRoom in $connectedRooms) {
                $distance = [math]::Abs($room.X - $connectedRoom.X) + [math]::Abs($room.Y - $connectedRoom.Y)
                if ($distance -lt $bestDistance) {
                    $bestDistance = $distance
                    $bestConnection = @{ From = $connectedRoom; To = $room }
                    $bestRoomIndex = $i
                }
            }
        }
        
        # Connect the best room
        if ($bestConnection) {
            $map = Create-RoomConnection $map $bestConnection.From $bestConnection.To $roomSize
            $connectedRooms += $remainingRooms[$bestRoomIndex]
            
            # Remove the connected room from remaining rooms (safer array manipulation)
            $newRemainingRooms = @()
            for ($j = 0; $j -lt $remainingRooms.Count; $j++) {
                if ($j -ne $bestRoomIndex) {
                    $newRemainingRooms += $remainingRooms[$j]
                }
            }
            $remainingRooms = $newRemainingRooms
        } else {
            break  # Safety break
        }
    }
    
    # Add some additional random connections for loops (makes exploration more interesting)
    $extraConnections = [math]::Min(3, [math]::Floor($rooms.Count / 3))
    for ($i = 0; $i -lt $extraConnections; $i++) {
        $room1 = $rooms[$rng.Next($rooms.Count)]
        $room2 = $rooms[$rng.Next($rooms.Count)]
        if ($room1 -ne $room2) {
            $map = Create-RoomConnection $map $room1 $room2 $roomSize
        }
    }
    
    return $map
}

function Create-RoomConnection {
    param($map, $room1, $room2, $roomSize)
    
    # Calculate room centers
    $x1 = $room1.X * $roomSize + [math]::Floor($roomSize / 2)
    $y1 = $room1.Y * $roomSize + [math]::Floor($roomSize / 2)
    $x2 = $room2.X * $roomSize + [math]::Floor($roomSize / 2)
    $y2 = $room2.Y * $roomSize + [math]::Floor($roomSize / 2)
    
    # Create L-shaped corridor (horizontal first, then vertical)
    $points = @()
    
    # Horizontal segment
    $minX = [math]::Min($x1, $x2)
    $maxX = [math]::Max($x1, $x2)
    for ($x = $minX; $x -le $maxX; $x++) {
        $points += @{ X = $x; Y = $y1 }
    }
    
    # Vertical segment
    $minY = [math]::Min($y1, $y2)
    $maxY = [math]::Max($y1, $y2)
    for ($y = $minY; $y -le $maxY; $y++) {
        $points += @{ X = $x2; Y = $y }
    }
    
    # Place corridor on map
    foreach ($point in $points) {
        if ($point.Y -lt $map.Count -and $point.X -lt $map[0].Length) {
            $row = $map[$point.Y].ToCharArray()
            $row[$point.X] = '.'
            $map[$point.Y] = -join $row
        }
    }
    
    return $map
}

# Helper function to add entrances and exits to the map
function Add-MapEntrances {
    param($map, $rng)
    
    # Find suitable locations for entrance and exit (floor tiles NOT on the border)
    $floorTiles = @()
    for ($y = 2; $y -lt $map.Count - 2; $y++) {  # Start from row 2, end 2 rows before border
        for ($x = 2; $x -lt $map[0].Length - 2; $x++) {  # Start from col 2, end 2 cols before border
            if ($map[$y][$x] -eq '.') {
                $floorTiles += @{ X = $x; Y = $y }
            }
        }
    }
    
    if ($floorTiles.Count -gt 0) {
        # Place entrance (staircase up)
        $entrance = $floorTiles[$rng.Next($floorTiles.Count)]
        $row = $map[$entrance.Y].ToCharArray()
        $row[$entrance.X] = '<'
        $map[$entrance.Y] = -join $row
        
        # Place exit (staircase down) - try to place it far from entrance
        if ($floorTiles.Count -gt 1) {
            $maxDistance = 0
            $bestExit = $null
            foreach ($tile in $floorTiles) {
                # Skip the entrance tile
                if ($tile.X -eq $entrance.X -and $tile.Y -eq $entrance.Y) { continue }
                
                $distance = [math]::Abs($tile.X - $entrance.X) + [math]::Abs($tile.Y - $entrance.Y)
                if ($distance -gt $maxDistance) {
                    $maxDistance = $distance
                    $bestExit = $tile
                }
            }
            if ($bestExit) {
                $row = $map[$bestExit.Y].ToCharArray()
                $row[$bestExit.X] = '>'
                $map[$bestExit.Y] = -join $row
            }
        }
    }
    
    return $map
}

# Ensure solid border around the entire map
function Add-SolidBorder {
    param($map)
    
    # Ensure top and bottom rows are completely walls
    if ($map.Count -gt 0) {
        $map[0] = "#" * $map[0].Length
        $map[$map.Count - 1] = "#" * $map[0].Length
    }
    
    # Ensure left and right columns are walls
    for ($y = 0; $y -lt $map.Count; $y++) {
        $row = $map[$y].ToCharArray()
        $row[0] = '#'
        $row[$row.Length - 1] = '#'
        $map[$y] = -join $row
    }
    
    return $map
}

# ==============================
# Cellular Automata Generation (Cave-style)
# ==============================

function New-CaveMap {
    param(
        [int]$Width = 80,
        [int]$Height = 30,
        [double]$InitialWallChance = 0.45,
        [int]$Iterations = 5,
        [string]$Seed = (Get-Random)
    )
    
    [System.Random]$rng = [System.Random]::new($Seed.GetHashCode())
    
    # Initialize with random walls/floors
    $map = @()
    for ($y = 0; $y -lt $Height; $y++) {
        $row = ""
        for ($x = 0; $x -lt $Width; $x++) {
            if ($x -eq 0 -or $x -eq ($Width - 1) -or $y -eq 0 -or $y -eq ($Height - 1)) {
                $row += "#"  # Border walls
            } elseif ($rng.NextDouble() -lt $InitialWallChance) {
                $row += "#"
            } else {
                $row += "."
            }
        }
        $map += $row
    }
    
    # Apply cellular automata rules
    for ($iteration = 0; $iteration -lt $Iterations; $iteration++) {
        $newMap = @()
        for ($y = 0; $y -lt $Height; $y++) {
            $row = ""
            for ($x = 0; $x -lt $Width; $x++) {
                if ($x -eq 0 -or $x -eq ($Width - 1) -or $y -eq 0 -or $y -eq ($Height - 1)) {
                    $row += "#"  # Keep border walls
                } else {
                    $wallCount = Count-NeighborWalls $map $x $y
                    if ($wallCount -ge 4) {
                        $row += "#"
                    } else {
                        $row += "."
                    }
                }
            }
            $newMap += $row
        }
        $map = $newMap
    }
    
    # Add some features
    $map = Add-CaveFeatures $map $rng
    
    # Ensure solid border around the entire map
    $map = Add-SolidBorder $map
    
    return $map
}

function Count-NeighborWalls {
    param($map, $x, $y)
    
    $count = 0
    for ($dy = -1; $dy -le 1; $dy++) {
        for ($dx = -1; $dx -le 1; $dx++) {
            $nx = $x + $dx
            $ny = $y + $dy
            
            if ($nx -lt 0 -or $nx -ge $map[0].Length -or $ny -lt 0 -or $ny -ge $map.Count) {
                $count++  # Treat out-of-bounds as walls
            } elseif ($map[$ny][$nx] -eq '#') {
                $count++
            }
        }
    }
    return $count
}

function Add-CaveFeatures {
    param($map, $rng)
    
    # Add some enemies in open areas
    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        $x = $rng.Next(1, $map[0].Length - 1)
        $y = $rng.Next(1, $map.Count - 1)
        
        if ($map[$y][$x] -eq '.' -and (Count-NeighborWalls $map $x $y) -eq 0) {
            $row = $map[$y].ToCharArray()
            $row[$x] = 'B'
            $map[$y] = -join $row
        }
    }
    
    # Add entrance/exit
    $map = Add-MapEntrances $map $rng
    
    return $map
}

# ==============================
# Simple Maze Generation
# ==============================

function New-MazeMap {
    param(
        [int]$Width = 80,
        [int]$Height = 30,
        [string]$Seed = (Get-Random)
    )
    
    [System.Random]$rng = [System.Random]::new($Seed.GetHashCode())
    
    # Ensure odd dimensions for proper maze generation
    $mazeWidth = if ($Width % 2 -eq 0) { $Width - 1 } else { $Width }
    $mazeHeight = if ($Height % 2 -eq 0) { $Height - 1 } else { $Height }
    
    # Initialize with all walls
    $map = @()
    for ($y = 0; $y -lt $mazeHeight; $y++) {
        $map += "#" * $mazeWidth
    }
    
    # Generate maze using recursive backtracking
    $stack = @()
    $visited = @{}
    
    # Start at (1,1)
    $currentX = 1
    $currentY = 1
    $visited["$currentX,$currentY"] = $true
    
    # Carve initial cell
    $row = $map[$currentY].ToCharArray()
    $row[$currentX] = '.'
    $map[$currentY] = -join $row
    
    while ($true) {
        $neighbors = Get-UnvisitedNeighbors $currentX $currentY $mazeWidth $mazeHeight $visited
        
        if ($neighbors.Count -gt 0) {
            # Choose random neighbor
            $neighbor = $neighbors[$rng.Next($neighbors.Count)]
            $stack += @{ X = $currentX; Y = $currentY }
            
            # Remove wall between current and neighbor
            $wallX = $currentX + (($neighbor.X - $currentX) / 2)
            $wallY = $currentY + (($neighbor.Y - $currentY) / 2)
            
            $row = $map[$wallY].ToCharArray()
            $row[$wallX] = '.'
            $map[$wallY] = -join $row
            
            $row = $map[$neighbor.Y].ToCharArray()
            $row[$neighbor.X] = '.'
            $map[$neighbor.Y] = -join $row
            
            $currentX = $neighbor.X
            $currentY = $neighbor.Y
            $visited["$currentX,$currentY"] = $true
        } elseif ($stack.Count -gt 0) {
            # Backtrack
            $prev = $stack[-1]
            $stack = $stack[0..($stack.Count - 2)]
            $currentX = $prev.X
            $currentY = $prev.Y
        } else {
            break
        }
    }
    
    # Add some openings and features
    $map = Add-MazeFeatures $map $rng
    
    # Ensure solid border around the entire map
    $map = Add-SolidBorder $map
    
    return $map
}

function Get-UnvisitedNeighbors {
    param($x, $y, $width, $height, $visited)
    
    $neighbors = @()
    $directions = @(
        @{ X = 0; Y = -2 },  # Up
        @{ X = 2; Y = 0 },   # Right  
        @{ X = 0; Y = 2 },   # Down
        @{ X = -2; Y = 0 }   # Left
    )
    
    foreach ($dir in $directions) {
        $nx = $x + $dir.X
        $ny = $y + $dir.Y
        
        if ($nx -gt 0 -and $nx -lt ($width - 1) -and $ny -gt 0 -and $ny -lt ($height - 1)) {
            if (-not $visited.ContainsKey("$nx,$ny")) {
                $neighbors += @{ X = $nx; Y = $ny }
            }
        }
    }
    
    return $neighbors
}

function Add-MazeFeatures {
    param($map, $rng)
    
    # Add some dead-end rewards
    for ($y = 1; $y -lt $map.Count - 1; $y++) {
        for ($x = 1; $x -lt $map[0].Length - 1; $x++) {
            if ($map[$y][$x] -eq '.') {
                $openCount = 0
                if ($map[$y-1][$x] -eq '.') { $openCount++ }
                if ($map[$y+1][$x] -eq '.') { $openCount++ }
                if ($map[$y][$x-1] -eq '.') { $openCount++ }
                if ($map[$y][$x+1] -eq '.') { $openCount++ }
                
                # Dead end with 10% treasure chance
                if ($openCount -eq 1 -and $rng.NextDouble() -lt 0.1) {
                    $row = $map[$y].ToCharArray()
                    $row[$x] = 'T'
                    $map[$y] = -join $row
                }
            }
        }
    }
    
    # Add entrance/exit
    $map = Add-MapEntrances $map $rng
    
    return $map
}

# ==============================
# Integration Functions
# ==============================

function New-ProceduralMap {
    param(
        [string]$Type = "room",  # "room", "cave", "maze"
        [int]$Width = 80,
        [int]$Height = 30,
        [string]$Seed = $null
    )
    
    if (-not $Seed) {
        $Seed = Get-Random
    }
    
    switch ($Type.ToLower()) {
        "room" { return New-RoomBasedMap -Width $Width -Height $Height -Seed $Seed }
        "cave" { return New-CaveMap -Width $Width -Height $Height -Seed $Seed }
        "maze" { return New-MazeMap -Width $Width -Height $Height -Seed $Seed }
        default { return New-RoomBasedMap -Width $Width -Height $Height -Seed $Seed }
    }
}

# Function to add to your existing Maps.ps1
function Add-ProceduralMapToRegistry {
    param(
        [string]$MapName,
        [string]$Type = "room",
        [string]$Seed = $null
    )
    
    $procMap = New-ProceduralMap -Type $Type -Seed $Seed
    $global:Maps[$MapName] = $procMap
    
    # Auto-register doors (find all '+' characters)
    for ($y = 0; $y -lt $procMap.Count; $y++) {
        for ($x = 0; $x -lt $procMap[0].Length; $x++) {
            if ($procMap[$y][$x] -eq '+') {
                Write-Host "Found door in $MapName at $x,$y - add to DoorRegistry manually"
            }
        }
    }
    
    Write-Host "Generated and registered procedural map: $MapName (Type: $Type, Seed: $Seed)"
    return $procMap
}

# Example usage function
function Demo-ProceduralMaps {
    Write-Host "=== Procedural Map Generation Demo ===" -ForegroundColor Green
    
    # Generate examples of each type
    Write-Host "`nGenerating Room-based map..." -ForegroundColor Yellow
    $roomMap = New-ProceduralMap -Type "room" -Seed "demo1"
    
    Write-Host "`nGenerating Cave map..." -ForegroundColor Yellow  
    $caveMap = New-ProceduralMap -Type "cave" -Seed "demo2"
    
    Write-Host "`nGenerating Maze map..." -ForegroundColor Yellow
    $mazeMap = New-ProceduralMap -Type "maze" -Seed "demo3"
    
    # Display first few lines of each
    Write-Host "`nRoom Map Preview:" -ForegroundColor Cyan
    $roomMap[0..4] | ForEach-Object { Write-Host $_ }
    
    Write-Host "`nCave Map Preview:" -ForegroundColor Cyan
    $caveMap[0..4] | ForEach-Object { Write-Host $_ }
    
    Write-Host "`nMaze Map Preview:" -ForegroundColor Cyan
    $mazeMap[0..4] | ForEach-Object { Write-Host $_ }
    
    Write-Host "`nDemo complete! Use Add-ProceduralMapToRegistry to add these to your game." -ForegroundColor Green
}
