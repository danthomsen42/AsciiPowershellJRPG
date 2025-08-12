# Viewport Rendering Functions

# Function to draw the current viewport of the map
function Draw-Viewport {
    param($map, $playerX, $playerY, $boxWidth, $boxHeight)
    # Calculate viewport origin so player is centered when possible
    $mapWidth = $map[0].Length
    $mapHeight = $map.Count
    $viewX = [math]::Max(0, [math]::Min($playerX - [math]::Floor($boxWidth/2), $mapWidth - $boxWidth))
    $viewY = [math]::Max(0, [math]::Min($playerY - [math]::Floor($boxHeight/2), $mapHeight - $boxHeight))
    
    # Get party positions for rendering (if party system is loaded)
    $partyPositions = @{}
    if ($global:Party) {
        $partyPositions = Get-PartyPositions $global:Party
    }
    
    # Choose rendering method based on water animation settings
    if ($global:EnableWaterAnimation -and $global:WaterRenderMethod -eq "ANSI") {
        # High-performance ANSI rendering with embedded water colors
        Draw-ViewportWithANSI $map $playerX $playerY $boxWidth $boxHeight $viewX $viewY $partyPositions
    } else {
        # Traditional rendering (backwards compatible)
        Draw-ViewportTraditional $map $playerX $playerY $boxWidth $boxHeight $viewX $viewY $partyPositions
    }
}

# High-performance ANSI rendering with embedded water colors
function Draw-ViewportWithANSI {
    param($map, $playerX, $playerY, $boxWidth, $boxHeight, $viewX, $viewY, $partyPositions)
    
    # Ultra-fast rendering using StringBuilder with embedded ANSI color codes
    $output = [System.Text.StringBuilder]::new(8192)  # Larger buffer for ANSI codes
    
    # Build header
    [void]$output.AppendLine("+" + ("-" * $boxWidth) + "+")
    [void]$output.AppendLine("Map: $CurrentMapName | Player: ($playerX,$playerY)")
    
    # Pre-build all viewport rows with embedded ANSI colors
    for ($y = 0; $y -lt $boxHeight; $y++) {
        [void]$output.Append("|")
        
        for ($x = 0; $x -lt $boxWidth; $x++) {
            $worldX = $x + $viewX
            $worldY = $y + $viewY
            $mapChar = $map[$viewY + $y][$viewX + $x]
            
            # Determine what character to display
            $displayChar = $mapChar
            $partyMember = $partyPositions["$worldX,$worldY"]
            
            if ($partyMember) {
                $displayChar = $partyMember.Symbol
            } elseif ($worldX -eq $playerX -and $worldY -eq $playerY) {
                $displayChar = $playerChar
            } else {
                $npcChar = $global:NPCPositionLookup["$worldX,$worldY"]
                if ($npcChar) {
                    $displayChar = $npcChar.Char
                }
            }
            
            # Apply colors based on tile type and zones
            if ($mapChar -eq '~' -and -not $partyMember) {
                # Water tiles get special animation treatment
                $ansiColor = Get-WaterANSIColor $worldX $worldY $global:WaterFrame
                [void]$output.Append("$ansiColor$displayChar$($global:WaterANSIColors['Reset'])")
            } elseif ($global:EnableColorZones -and -not $partyMember -and $worldX -ne $playerX -and $worldY -ne $playerY -and -not $npcChar) {
                # Regular tiles get zone-based coloring (ONLY if color zones enabled)
                $tileColor = Get-TileANSIColor $CurrentMapName $worldX $worldY $mapChar
                if ($tileColor) {
                    [void]$output.Append("$tileColor$displayChar$($global:WaterANSIColors['Reset'])")
                } else {
                    [void]$output.Append($displayChar)
                }
            } else {
                [void]$output.Append($displayChar)
            }
        }
        
        [void]$output.AppendLine("|")
    }
    
    [void]$output.AppendLine("+" + ("-" * $boxWidth) + "+")
    [void]$output.AppendLine("Use Arrow Keys or WASD to move. Press Q to quit. Step on + to change maps.")
    [void]$output.AppendLine("Save: F5=Quick Save   F9=Save Menu   Auto-saves after battles!")
    
    # Single high-performance output with embedded ANSI colors
    [System.Console]::SetCursorPosition(0, 0)
    [System.Console]::Write($output.ToString())
    [System.Console]::Out.Flush()
}

# Traditional rendering method (backwards compatible)
function Draw-ViewportTraditional {
    param($map, $playerX, $playerY, $boxWidth, $boxHeight, $viewX, $viewY, $partyPositions)
    
    # Traditional StringBuilder approach (same as original)
    $output = [System.Text.StringBuilder]::new(4096)
    
    # Build header
    [void]$output.AppendLine("+" + ("-" * $boxWidth) + "+")
    [void]$output.AppendLine("Map: $CurrentMapName | Player: ($playerX,$playerY)")
    
    # Pre-build all viewport rows
    for ($y = 0; $y -lt $boxHeight; $y++) {
        [void]$output.Append("|")
        
        for ($x = 0; $x -lt $boxWidth; $x++) {
            $worldX = $x + $viewX
            $worldY = $y + $viewY
            $mapChar = $map[$viewY + $y][$viewX + $x]
            
            # Determine what character to display
            $displayChar = $mapChar
            $partyMember = $partyPositions["$worldX,$worldY"]
            if ($partyMember) {
                $displayChar = $partyMember.Symbol
            } elseif ($worldX -eq $playerX -and $worldY -eq $playerY) {
                $displayChar = $playerChar
            } else {
                $npcChar = $global:NPCPositionLookup["$worldX,$worldY"]
                if ($npcChar) {
                    $displayChar = $npcChar.Char
                }
            }
            
            [void]$output.Append($displayChar)
        }
        
        [void]$output.AppendLine("|")
    }
    
    [void]$output.AppendLine("+" + ("-" * $boxWidth) + "+")
    [void]$output.AppendLine("Use Arrow Keys or WASD to move. Press Q to quit. Step on + to change maps.")
    [void]$output.AppendLine("Save: F5=Quick Save   F9=Save Menu   Auto-saves after battles!")
    
    # Compatible console positioning and output
    [System.Console]::SetCursorPosition(0, 0)
    [System.Console]::Write($output.ToString())
    
    # Apply zone-based coloring using individual positioning (for backwards compatibility)
    if ($global:EnableColorZones -and $global:WaterRenderMethod -eq "CURSOR") {
        # Apply colors to zone tiles using individual cursor positioning (ONLY if zones enabled)
        $mapHeight = $map.Count
        $mapWidth = if ($mapHeight -gt 0) { $map[0].Length } else { 0 }
        
        try {
            for ($y = 0; $y -lt $boxHeight; $y++) {
                for ($x = 0; $x -lt $boxWidth; $x++) {
                    $worldX = $x + $viewX
                    $worldY = $y + $viewY
                    
                    # Check if this position is safe to access
                    if ($worldY -lt $mapHeight -and $worldX -lt $map[$worldY].Length) {
                        $mapChar = $map[$worldY][$worldX]
                        $partyMember = $partyPositions["$worldX,$worldY"]
                        $npcChar = $global:NPCPositionLookup["$worldX,$worldY"]
                        
                        # Only color tiles that aren't covered by player, party, or NPCs
                        if (-not $partyMember -and $worldX -ne $playerX -and $worldY -ne $playerY -and -not $npcChar) {
                            $color = Get-TileColor $CurrentMapName $worldX $worldY $mapChar
                            
                            if ($color) {
                                # Safe cursor positioning with bounds checking
                                $cursorX = $x + 1
                                $cursorY = $y + 2
                                if ($cursorX -lt [System.Console]::BufferWidth -and $cursorY -lt [System.Console]::BufferHeight) {
                                    [System.Console]::SetCursorPosition($cursorX, $cursorY)
                                    Write-Host $mapChar -ForegroundColor $color -NoNewline
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            # If coloring fails, continue without colors
            Write-Host "Zone coloring error - continuing without colors" -ForegroundColor DarkYellow
        }
    }
    
    # Water animation rendering using individual positioning (if needed)
    if ($global:EnableWaterAnimation -and $global:WaterRenderMethod -eq "CURSOR") {
        Render-WaterAnimationSafe $map $playerX $playerY $boxWidth $boxHeight $partyPositions
    }
    
    [System.Console]::Out.Flush()
}

# Move cursor to a specific position inside the box
function Set-CursorInBox {
    param($x, $y)
    # Set cursor position using .NET Console API (works in most Windows terminals)
    # The play area starts at row 1, col 1 (inside the box border)
    $row = $y + 1  # .NET is 0-based, box border is at row 0
    $col = $x + 1  # .NET is 0-based, box border is at col 0
    [System.Console]::SetCursorPosition($col, $row)
}
