# Simple Efficient Color System - Version 3
# NO ANSI codes - just use simple position-based coloring

# ============================================================================
# SUPER SIMPLE COLOR CONFIGURATION
# ============================================================================
# Just define which coordinates should have which colors - that's it!

$global:SimpleColors = @{
    "Town" = @{
        # Just specify: "X,Y" = "ColorName" 
        "15,15" = "Green"      # One green dot to test
        # Add more like: "16,15" = "Green", "17,15" = "Blue", etc.
    }
}

# ============================================================================
# ONE SIMPLE FUNCTION - GET COLOR FOR A POSITION
# ============================================================================
function Initialize-SimpleColors {
    $global:SimpleColors = @{}
    Write-Host "Simple color system initialized" -ForegroundColor Green
}

function Get-SimpleColor {
    param($MapName, $X, $Y)
    
    # Super fast - just check if colors are enabled and if this exact position has a color
    if (-not $global:EnableColorZones -or -not $global:SimpleColors.ContainsKey($MapName)) {
        return $null
    }
    
    $positionKey = "$X,$Y"
    if ($global:SimpleColors[$MapName].ContainsKey($positionKey)) {
        return $global:SimpleColors[$MapName][$positionKey]
    }
    
    return $null
}

# ============================================================================
# SUPER EFFICIENT COLOR APPLICATION - ONLY COLOR SPECIFIC POSITIONS
# ============================================================================
function Apply-SimpleColors {
    param($MapName, $ViewX, $ViewY, $BoxWidth, $BoxHeight, $PlayerX, $PlayerY, $PartyPositions)
    
    # Skip if no colors defined for this map
    if (-not $global:SimpleColors.ContainsKey($MapName)) {
        return
    }
    
    $mapColors = $global:SimpleColors[$MapName]
    
    # Only process the exact positions that have colors (VERY fast!)
    foreach ($positionKey in $mapColors.Keys) {
        $coords = $positionKey -split ','
        $worldX = [int]$coords[0]
        $worldY = [int]$coords[1]
        
        # Check if this position is in the viewport
        $screenX = $worldX - $ViewX
        $screenY = $worldY - $ViewY
        
        if ($screenX -ge 0 -and $screenX -lt $BoxWidth -and $screenY -ge 0 -and $screenY -lt $BoxHeight) {
            # Check if position is not occupied by player/party
            $partyMember = $PartyPositions["$worldX,$worldY"]
            $isPlayerPosition = ($worldX -eq $PlayerX -and $worldY -eq $PlayerY)
            
            if (-not $partyMember -and -not $isPlayerPosition) {
                # Apply color using native PowerShell Write-Host (fast!)
                try {
                    $cursorX = $screenX + 1  # Account for box border
                    $cursorY = $screenY + 2  # Account for box border and header
                    
                    # Validate cursor position before setting it
                    if ($cursorX -ge 0 -and $cursorY -ge 0 -and $cursorX -lt $Host.UI.RawUI.WindowSize.Width -and $cursorY -lt $Host.UI.RawUI.WindowSize.Height) {
                        [System.Console]::SetCursorPosition($cursorX, $cursorY)
                        
                        $color = $mapColors[$positionKey]
                        Write-Host "." -ForegroundColor $color -NoNewline
                    }
                } catch {
                    # If positioning fails, continue silently (prevents crashes)
                }
            }
        }
    }
}

# ============================================================================
# BULK COLOR HELPERS (optional)
# ============================================================================
function Add-SimpleColorRectangle {
    param($MapName, $StartX, $StartY, $Width, $Height, $Color)
    
    if (-not $global:SimpleColors.ContainsKey($MapName)) {
        $global:SimpleColors[$MapName] = @{}
    }
    
    $EndX = $StartX + $Width - 1
    $EndY = $StartY + $Height - 1
    
    for ($x = $StartX; $x -le $EndX; $x++) {
        for ($y = $StartY; $y -le $EndY; $y++) {
            $global:SimpleColors[$MapName]["$x,$y"] = $Color
        }
    }
}

# ============================================================================
# USAGE EXAMPLES:
# ============================================================================
# Single tiles: $global:SimpleColors["Town"]["15,15"] = "Green"
# Bulk areas:   Add-SimpleColorRectangle "Town" 10 10 20 20 "Green"
# ============================================================================

Write-Host "Simple Color System Loaded (No ANSI)" -ForegroundColor Green
