# Viewport Rendering Functions

# Function to draw the current viewport of the map
function Draw-Viewport {
    param($map, $playerX, $playerY, $boxWidth, $boxHeight)
    
    # Get map dimensions
    $mapWidth = $map[0].Length
    $mapHeight = $map.Count
    
    # Check if map is smaller than viewport and needs centering
    $centerMap = ($mapWidth -lt $boxWidth) -or ($mapHeight -lt $boxHeight)
    
    if ($centerMap) {
        # Calculate centering offsets for small maps
        $mapOffsetX = [math]::Max(0, [math]::Floor(($boxWidth - $mapWidth) / 2))
        $mapOffsetY = [math]::Max(0, [math]::Floor(($boxHeight - $mapHeight) / 2))
        
        # For centered maps, show entire map (no scrolling)
        $viewX = 0
        $viewY = 0
        $actualBoxWidth = $mapWidth
        $actualBoxHeight = $mapHeight
    } else {
        # Normal viewport calculation for large maps (player-centered)
        $viewX = [math]::Max(0, [math]::Min($playerX - [math]::Floor($boxWidth/2), $mapWidth - $boxWidth))
        $viewY = [math]::Max(0, [math]::Min($playerY - [math]::Floor($boxHeight/2), $mapHeight - $boxHeight))
        $mapOffsetX = 0
        $mapOffsetY = 0
        $actualBoxWidth = $boxWidth
        $actualBoxHeight = $boxHeight
    }
    
    # Get party positions for rendering (if party system is loaded)
    $partyPositions = @{}
    if ($global:Party) {
        $partyPositions = Get-PartyPositions $global:Party
    }
    
    # Choose rendering method with centering support
    if ($global:EnableWaterAnimation -and $global:WaterRenderMethod -eq "ANSI") {
        # High-performance ANSI rendering with embedded water colors
        Draw-ViewportWithANSI $map $playerX $playerY $boxWidth $boxHeight $viewX $viewY $partyPositions $mapOffsetX $mapOffsetY $actualBoxWidth $actualBoxHeight $centerMap
    } else {
        # Traditional rendering (fast and compatible)
        Draw-ViewportTraditional $map $playerX $playerY $boxWidth $boxHeight $viewX $viewY $partyPositions $mapOffsetX $mapOffsetY $actualBoxWidth $actualBoxHeight $centerMap
    }
}

# High-performance ANSI rendering with embedded water colors
function Draw-ViewportWithANSI {
    param($map, $playerX, $playerY, $boxWidth, $boxHeight, $viewX, $viewY, $partyPositions, $mapOffsetX = 0, $mapOffsetY = 0, $actualBoxWidth = $boxWidth, $actualBoxHeight = $boxHeight, $centerMap = $false)
    
    # Safety check for null map
    if (-not $map -or $map.Count -eq 0) {
        Write-Host "Error: Map is null or empty in Draw-ViewportWithANSI" -ForegroundColor Red
        return
    }
    
    # Pre-calculate NPCs in viewport area (performance optimization)
    $npcPositions = @{}
    if ($global:NPCs) {
        foreach ($npc in $global:NPCs) {
            if ($npc.Map -eq $global:CurrentMapName) {
                $npcX = $npc.X
                $npcY = $npc.Y
                # Only include NPCs that might be visible in viewport
                if ($npcX -ge $viewX -and $npcX -lt ($viewX + $actualBoxWidth) -and 
                    $npcY -ge $viewY -and $npcY -lt ($viewY + $actualBoxHeight)) {
                    $npcPositions["$npcX,$npcY"] = $npc
                }
            }
        }
    }
    
    # Ultra-fast rendering using StringBuilder with embedded ANSI color codes
    $output = [System.Text.StringBuilder]::new(8192)  # Larger buffer for ANSI codes
    
    # Build header
    [void]$output.AppendLine("+" + ("-" * $boxWidth) + "+")
    [void]$output.AppendLine("Map: $CurrentMapName | Player: ($playerX,$playerY)")
    
    # Pre-build all viewport rows with embedded ANSI colors and centering support
    for ($y = 0; $y -lt $boxHeight; $y++) {
        [void]$output.Append("|")
        
        for ($x = 0; $x -lt $boxWidth; $x++) {
            if ($centerMap) {
                # Handle centered small maps
                $mapX = $x - $mapOffsetX
                $mapY = $y - $mapOffsetY
                
                # Check if we're within the actual map bounds
                if ($mapX -ge 0 -and $mapX -lt $map[0].Length -and $mapY -ge 0 -and $mapY -lt $map.Count) {
                    $worldX = $mapX + $viewX
                    $worldY = $mapY + $viewY
                    $mapChar = $map[$mapY][$mapX]
                } else {
                    # Outside map bounds - use empty space (not dots)
                    [void]$output.Append(" ")
                    continue
                }
            } else {
                # Normal large map handling
                $worldX = $x + $viewX
                $worldY = $y + $viewY
                
                # Safe map access with bounds checking
                $mapChar = '.'  # Default character
                if ($worldY -ge 0 -and $worldY -lt $map.Count -and 
                    $worldX -ge 0 -and $worldX -lt $map[0].Length) {
                    $mapChar = $map[$worldY][$worldX]
                }
            }
            
            # Determine what character to display
            $displayChar = $mapChar
            $partyMember = $partyPositions["$worldX,$worldY"]
            
            if ($partyMember) {
                $displayChar = $partyMember.Symbol
            } elseif ($worldX -eq $playerX -and $worldY -eq $playerY) {
                $displayChar = $playerChar
            } else {
                # Check for NPCs using pre-calculated positions (fast!)
                $npcChar = $npcPositions["$worldX,$worldY"]
                if ($npcChar) {
                    $displayChar = $npcChar.Char
                }
            }
            
            # No inline coloring - render normally for speed
            if ($mapChar -eq '~' -and -not $partyMember) {
                # Water tiles get special animation treatment
                $ansiColor = Get-WaterANSIColor $worldX $worldY $global:WaterFrame
                [void]$output.Append("$ansiColor$displayChar$($global:WaterANSIColors['Reset'])")
            } else {
                # Regular tiles - no color processing during main rendering
                [void]$output.Append($displayChar)
            }
        }
        
        [void]$output.AppendLine("|")
    }
    
    # Single high-performance output (no embedded colors for main rendering)
    [System.Console]::SetCursorPosition(0, 0)
    [System.Console]::Write($output.ToString())
    [System.Console]::Out.Flush()
    
    # Apply colors ONLY to specific positions (super fast!)
    if ($global:EnableColorZones) {
        if ($centerMap) {
            Apply-SimpleColors $CurrentMapName $viewX $viewY $actualBoxWidth $actualBoxHeight $playerX $playerY $partyPositions $mapOffsetX $mapOffsetY
        } else {
            Apply-SimpleColors $CurrentMapName $viewX $viewY $boxWidth $boxHeight $playerX $playerY $partyPositions
        }
    }
    
    # Apply character colors (only 4-5 positions, very fast!)
    if ($centerMap) {
        # For centered maps, pass the full viewport dimensions for bounds checking, not the smaller map size
        Apply-CharacterColorsToViewport $viewX $viewY $boxWidth $boxHeight $playerX $playerY $partyPositions $mapOffsetX $mapOffsetY
    } else {
        Apply-CharacterColorsToViewport $viewX $viewY $boxWidth $boxHeight $playerX $playerY $partyPositions
    }
}

# Traditional rendering method (backwards compatible)
function Draw-ViewportTraditional {
    param($map, $playerX, $playerY, $boxWidth, $boxHeight, $viewX, $viewY, $partyPositions, $mapOffsetX = 0, $mapOffsetY = 0, $actualBoxWidth = $boxWidth, $actualBoxHeight = $boxHeight, $centerMap = $false)
    
    # Pre-calculate NPCs in viewport area (performance optimization)
    $npcPositions = @{}
    if ($global:NPCs) {
        foreach ($npc in $global:NPCs) {
            if ($npc.Map -eq $global:CurrentMapName) {
                $npcX = $npc.X
                $npcY = $npc.Y
                # Only include NPCs that might be visible in viewport
                if ($npcX -ge $viewX -and $npcX -lt ($viewX + $actualBoxWidth) -and 
                    $npcY -ge $viewY -and $npcY -lt ($viewY + $actualBoxHeight)) {
                    $npcPositions["$npcX,$npcY"] = $npc
                }
            }
        }
    }
    
    # Traditional StringBuilder approach (same as original)
    $output = [System.Text.StringBuilder]::new(4096)
    
    # Build header
    [void]$output.AppendLine("+" + ("-" * $boxWidth) + "+")
    [void]$output.AppendLine("Map: $CurrentMapName | Player: ($playerX,$playerY)")
    
    # Pre-build all viewport rows with centering support
    for ($y = 0; $y -lt $boxHeight; $y++) {
        [void]$output.Append("|")
        
        for ($x = 0; $x -lt $boxWidth; $x++) {
            if ($centerMap) {
                # Handle centered small maps
                $mapX = $x - $mapOffsetX
                $mapY = $y - $mapOffsetY
                
                # Check if we're within the actual map bounds
                if ($mapX -ge 0 -and $mapX -lt $map[0].Length -and $mapY -ge 0 -and $mapY -lt $map.Count) {
                    $worldX = $mapX + $viewX
                    $worldY = $mapY + $viewY
                    $mapChar = $map[$mapY][$mapX]
                } else {
                    # Outside map bounds - use empty space (not dots)
                    [void]$output.Append(" ")
                    continue
                }
            } else {
                # Normal large map handling
                $worldX = $x + $viewX
                $worldY = $y + $viewY
                $mapChar = $map[$viewY + $y][$viewX + $x]
            }
            
            # Determine what character to display and apply integrated colors
            $displayChar = $mapChar
            $partyMember = $partyPositions["$worldX,$worldY"]
            if ($partyMember) {
                $displayChar = $partyMember.Symbol
                [void]$output.Append($displayChar)
            } elseif ($worldX -eq $playerX -and $worldY -eq $playerY) {
                $displayChar = $playerChar
                [void]$output.Append($displayChar)
            } else {
                # Check for NPCs using pre-calculated positions (fast!)
                $npcChar = $npcPositions["$worldX,$worldY"]
                if ($npcChar) {
                    $displayChar = $npcChar.Char
                    [void]$output.Append($displayChar)
                } else {
                    # Regular tiles - no color processing during main rendering
                    [void]$output.Append($displayChar)
                }
            }
        }
        
        [void]$output.AppendLine("|")
    }
    
    [void]$output.AppendLine("+" + ("-" * $boxWidth) + "+")
    [void]$output.AppendLine("Use Arrow Keys or WASD to move. Press Q to quit. Step on + to change maps.")
    [void]$output.AppendLine("Save: F5=Quick Save   F9=Save Menu   Auto-saves after battles!")
    
    # Compatible console positioning and output (fast!)
    [System.Console]::SetCursorPosition(0, 0)
    [System.Console]::Write($output.ToString())
    [System.Console]::Out.Flush()
    
    # Apply colors ONLY to specific positions (super fast!)
    if ($global:EnableColorZones) {
        Apply-SimpleColors $CurrentMapName $viewX $viewY $boxWidth $boxHeight $playerX $playerY $partyPositions
    }
    
    # Apply character colors (only 4-5 positions, very fast!)
    if ($centerMap) {
        # For centered maps, pass the full viewport dimensions for bounds checking, not the smaller map size
        Apply-CharacterColorsToViewport $viewX $viewY $boxWidth $boxHeight $playerX $playerY $partyPositions $mapOffsetX $mapOffsetY
    } else {
        Apply-CharacterColorsToViewport $viewX $viewY $boxWidth $boxHeight $playerX $playerY $partyPositions
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

# Apply character colors to party members only (high performance)
function Apply-CharacterColorsToViewport {
    param($viewX, $viewY, $boxWidth, $boxHeight, $playerX, $playerY, $partyPositions, $mapOffsetX = 0, $mapOffsetY = 0)
    
    # Build colored positions lookup (only party members)
    $coloredPositions = @{}
    
    # Add party member positions with their individual colors
    foreach ($key in $partyPositions.Keys) {
        $member = $partyPositions[$key]
        # Use individual character color if available, fall back to class color
        $color = if ($member.Color -and $member.Color -ne "") { 
            $member.Color 
        } else { 
            Get-CharacterColor $member.Class 
        }
        $coloredPositions[$key] = @{
            Symbol = $member.Symbol
            Color = $color
        }
    }
    
    # Add player/leader position if needed
    $playerKey = "$playerX,$playerY"
    if (-not $coloredPositions.ContainsKey($playerKey)) {
        # Get leader's individual color or fall back to class color
        $leaderColor = "White"
        if ($global:Party -and $global:Party.Count -gt 0) {
            $leaderColor = if ($global:Party[0].Color -and $global:Party[0].Color -ne "") { 
                $global:Party[0].Color 
            } else { 
                Get-CharacterColor $global:Party[0].Class 
            }
        }
        $coloredPositions[$playerKey] = @{
            Symbol = $playerChar
            Color = $leaderColor
        }
    }
    
    # Apply colors to visible character positions only
    foreach ($positionKey in $coloredPositions.Keys) {
        $coords = $positionKey -split ','
        $worldX = [int]$coords[0]
        $worldY = [int]$coords[1]
        
        # Check if this character is visible in current viewport
        # For centered maps, we need to account for the offset
        if ($mapOffsetX -gt 0 -or $mapOffsetY -gt 0) {
            # Centered map: translate world coordinates to screen coordinates
            $screenX = $worldX - $viewX + $mapOffsetX
            $screenY = $worldY - $viewY + $mapOffsetY
        } else {
            # Normal map: standard coordinate translation
            $screenX = $worldX - $viewX
            $screenY = $worldY - $viewY
        }
        
        if ($screenX -ge 0 -and $screenX -lt $boxWidth -and $screenY -ge 0 -and $screenY -lt $boxHeight) {
            $charInfo = $coloredPositions[$positionKey]
            
            # Calculate console position (account for borders and header)
            $consoleX = $screenX + 1  # +1 for left border
            $consoleY = $screenY + 2  # +2 for top border and header line
            
            try {
                # Fast coloring - just like Write-Host
                [System.Console]::SetCursorPosition($consoleX, $consoleY)
                $safeColor = if ($charInfo.Color) { $charInfo.Color } else { "White" }
                Write-Host $charInfo.Symbol -ForegroundColor $safeColor -NoNewline
            } catch {
                # If positioning fails, continue silently
            }
        }
    }
    
    # Move cursor to safe position (bottom of viewport) to prevent flashing cursor
    try {
        # Move cursor below the game area where it won't be distracting
        [System.Console]::SetCursorPosition(0, $boxHeight + 6)
        # Optionally hide cursor visibility (may not work in all terminals)
        # [System.Console]::CursorVisible = $false
    } catch {
        # If positioning fails, continue silently
    }
}
