# =============================================================================
# CHARACTER COLORS SYSTEM - High Performance Character-Only Coloring
# =============================================================================
# This system ONLY colors the 4-5 party member characters, NOT the world tiles.
# Avoids all performance issues of the ColorZones system by limiting scope.

# Character color definitions (simple and fast)
$global:CharacterColors = @{
    "Warrior" = "Cyan"      # W - Cyan for tank/leader
    "Mage"    = "Magenta"   # M - Magenta for magic user  
    "Healer"  = "Yellow"    # H - Yellow for support
    "Rogue"   = "Green"     # R - Green for stealth/speed
}

# Alternative color schemes (commented out - pick one)
# $global:CharacterColors = @{
#     "Warrior" = "Red"       # W - Red for warrior
#     "Mage"    = "Blue"      # M - Blue for magic
#     "Healer"  = "Yellow"    # H - Yellow for healing
#     "Rogue"   = "Green"     # R - Green for rogue
# }

# Simple function to get character color by class
function Get-CharacterColor {
    param([string]$Class)
    
    if ($global:CharacterColors.ContainsKey($Class)) {
        return $global:CharacterColors[$Class]
    }
    return "White"  # Default color
}

# Enhanced viewport rendering with colored characters
function Render-ColoredViewport {
    param($map, $viewX, $viewY, $boxWidth, $boxHeight, $playerX, $playerY, $playerChar, $partyPositions)
    
    # Pre-calculate NPCs in viewport area (performance optimization)
    $npcPositions = @{}
    if ($global:NPCs) {
        foreach ($npc in $global:NPCs) {
            if ($npc.Map -eq $global:CurrentMapName) {
                $npcX = $npc.X
                $npcY = $npc.Y
                # Only include NPCs that might be visible in viewport
                if ($npcX -ge $viewX -and $npcX -lt ($viewX + $boxWidth) -and 
                    $npcY -ge $viewY -and $npcY -lt ($viewY + $boxHeight)) {
                    $npcPositions["$npcX,$npcY"] = $npc
                }
            }
        }
    }
    
    # Build output string for performance (same as your current system)
    $output = New-Object System.Text.StringBuilder
    [void]$output.AppendLine("+" + ("-" * $boxWidth) + "+")
    
    # Build position lookup for characters that need coloring
    $coloredPositions = @{}
    
    # Add party member positions with their colors
    foreach ($key in $partyPositions.Keys) {
        $member = $partyPositions[$key]
        $color = Get-CharacterColor $member.Class
        $coloredPositions[$key] = @{
            Symbol = $member.Symbol
            Color = $color
            IsCharacter = $true
        }
    }
    
    # Add player position if needed (using leader's color)
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
            IsCharacter = $true
        }
    }
    
    # Render each row
    for ($y = 0; $y -lt $boxHeight; $y++) {
        [void]$output.Append("|")
        
        for ($x = 0; $x -lt $boxWidth; $x++) {
            $worldX = $x + $viewX
            $worldY = $y + $viewY
            $positionKey = "$worldX,$worldY"
            
            # Check if this position has a colored character
            if ($coloredPositions.ContainsKey($positionKey)) {
                $charInfo = $coloredPositions[$positionKey]
                [void]$output.Append($charInfo.Symbol)
            } else {
                # Regular map tile (no coloring)
                $mapChar = $map[$viewY + $y][$viewX + $x]
                
                # Check for NPCs using pre-calculated positions (fast!)
                $npcChar = $npcPositions["$worldX,$worldY"]
                if ($npcChar) {
                    [void]$output.Append($npcChar.Char)
                } else {
                    [void]$output.Append($mapChar)
                }
            }
        }
        [void]$output.AppendLine("|")
    }
    
    [void]$output.AppendLine("+" + ("-" * $boxWidth) + "+")
    [void]$output.AppendLine("Use Arrow Keys or WASD to move. Press Q to quit. Step on + to change maps.")
    
    # Output the entire viewport at once
    $viewportText = $output.ToString()
    Write-Host $viewportText -NoNewline
    
    # NOW apply colors - only to the 4-5 character positions!
    Apply-CharacterColors $coloredPositions $viewX $viewY $boxWidth $boxHeight
}

# Apply colors to character positions only (called after main rendering)
function Apply-CharacterColors {
    param($coloredPositions, $viewX, $viewY, $boxWidth, $boxHeight)
    
    foreach ($positionKey in $coloredPositions.Keys) {
        $coords = $positionKey -split ','
        $worldX = [int]$coords[0]
        $worldY = [int]$coords[1]
        
        # Check if this character is visible in current viewport
        $screenX = $worldX - $viewX
        $screenY = $worldY - $viewY
        
        if ($screenX -ge 0 -and $screenX -lt $boxWidth -and $screenY -ge 0 -and $screenY -lt $boxHeight) {
            $charInfo = $coloredPositions[$positionKey]
            
            # Calculate console position (account for borders)
            $consoleX = $screenX + 1  # +1 for left border
            $consoleY = $screenY + 1  # +1 for top border
            
            try {
                # Simple, fast coloring - just like Write-Host
                [System.Console]::SetCursorPosition($consoleX, $consoleY)
                $safeColor = if ($charInfo.Color) { $charInfo.Color } else { "White" }
                Write-Host $charInfo.Symbol -ForegroundColor $safeColor -NoNewline
            } catch {
                # If positioning fails, continue silently
            }
        }
    }
}

# Alternative simple approach - modify existing renderer to use colors inline
function Get-ColoredCharacterOutput {
    param($symbol, $class)
    
    $color = Get-CharacterColor $class
    # This would be used in a Write-Host call with -ForegroundColor
    return @{
        Symbol = $symbol
        Color = $color
    }
}
