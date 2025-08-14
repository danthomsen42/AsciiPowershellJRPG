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
    
    # Choose rendering method
    if ($global:EnableWaterAnimation -and $global:WaterRenderMethod -eq "ANSI") {
        # High-performance ANSI rendering with embedded water colors
        Draw-ViewportWithANSI $map $playerX $playerY $boxWidth $boxHeight $viewX $viewY $partyPositions
    } else {
        # Traditional rendering (fast and compatible)
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
        Apply-SimpleColors $CurrentMapName $viewX $viewY $boxWidth $boxHeight $playerX $playerY $partyPositions
    }
    
    # Apply character colors (only 4-5 positions, very fast!)
    Apply-CharacterColorsToViewport $viewX $viewY $boxWidth $boxHeight $playerX $playerY $partyPositions
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
                $npcChar = $global:NPCPositionLookup["$worldX,$worldY"]
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
    Apply-CharacterColorsToViewport $viewX $viewY $boxWidth $boxHeight $playerX $playerY $partyPositions
    
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
    param($viewX, $viewY, $boxWidth, $boxHeight, $playerX, $playerY, $partyPositions)
    
    # Build colored positions lookup (only party members)
    $coloredPositions = @{}
    
    # Add party member positions with their colors
    foreach ($key in $partyPositions.Keys) {
        $member = $partyPositions[$key]
        $color = Get-CharacterColor $member.Class
        $coloredPositions[$key] = @{
            Symbol = $member.Symbol
            Color = $color
        }
    }
    
    # Add player/leader position if needed
    $playerKey = "$playerX,$playerY"
    if (-not $coloredPositions.ContainsKey($playerKey)) {
        # Get leader's class for color
        $leaderColor = "White"
        if ($global:Party -and $global:Party.Count -gt 0) {
            $leaderColor = Get-CharacterColor $global:Party[0].Class
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
        $screenX = $worldX - $viewX
        $screenY = $worldY - $viewY
        
        if ($screenX -ge 0 -and $screenX -lt $boxWidth -and $screenY -ge 0 -and $screenY -lt $boxHeight) {
            $charInfo = $coloredPositions[$positionKey]
            
            # Calculate console position (account for borders and header)
            $consoleX = $screenX + 1  # +1 for left border
            $consoleY = $screenY + 2  # +2 for top border and header line
            
            try {
                # Fast coloring - just like Write-Host
                [System.Console]::SetCursorPosition($consoleX, $consoleY)
                Write-Host $charInfo.Symbol -ForegroundColor $charInfo.Color -NoNewline
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
