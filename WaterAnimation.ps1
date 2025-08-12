# Water Animation System

# =============================================================================
# WATER ANIMATION SYSTEM (EASILY REMOVABLE - MULTIPLE RENDERING OPTIONS)
# =============================================================================

# *** WATER ANIMATION CONTROL ***
$global:EnableWaterAnimation = $true

# *** RENDERING METHOD SELECTION ***
# Options: "ANSI", "CURSOR", "NONE"
# - "ANSI"   = Fast ANSI escape sequences (recommended for performance)
# - "CURSOR" = Original cursor positioning method (slower but more compatible)
# - "NONE"   = No water animation at all (fastest, static blue water)
$global:WaterRenderMethod = "ANSI"

# EASY REMOVAL: To completely disable water effects:
# $global:EnableWaterAnimation = $false

# EASY FALLBACK: If ANSI doesn't work well:
# $global:WaterRenderMethod = "CURSOR"

# EASY DISABLE: For maximum performance:
# $global:WaterRenderMethod = "NONE"

# Water animation configuration - simple frame counter
$global:WaterFrame = 0

# ANSI Color codes for high-performance rendering (using [char]27 for better compatibility)
$global:WaterANSIColors = @{
    "DarkBlue" = "$([char]27)[34m"
    "Blue"     = "$([char]27)[94m"  # Bright blue
    "DarkCyan" = "$([char]27)[36m"
    "Cyan"     = "$([char]27)[96m"  # Bright cyan
    "Reset"    = "$([char]27)[0m"
}

# Function to get animated water color (backwards compatible)
function Get-WaterColor {
    param([int]$X, [int]$Y, [int]$Frame)
    
    if (-not $global:EnableWaterAnimation -or $global:WaterRenderMethod -eq "NONE") {
        return "DarkBlue"  # Static water color when disabled
    }
    
    # Create wave-like color pattern
    $offset = ($X + $Y + $Frame) % 4
    switch ($offset) {
        0 { return "DarkBlue" }
        1 { return "Blue" }
        2 { return "DarkCyan" }
        3 { return "Cyan" }
    }
}

# Function to get ANSI color code for water
function Get-WaterANSIColor {
    param([int]$X, [int]$Y, [int]$Frame)
    
    if (-not $global:EnableWaterAnimation -or $global:WaterRenderMethod -eq "NONE") {
        return $global:WaterANSIColors["DarkBlue"]
    }
    
    # Create wave-like color pattern
    $offset = ($X + $Y + $Frame) % 4
    switch ($offset) {
        0 { return $global:WaterANSIColors["DarkBlue"] }
        1 { return $global:WaterANSIColors["Blue"] }
        2 { return $global:WaterANSIColors["DarkCyan"] }
        3 { return $global:WaterANSIColors["Cyan"] }
    }
}

# Safe water animation rendering using individual cursor positioning (LEGACY - for compatibility)
function Render-WaterAnimationSafe {
    param($map, $playerX, $playerY, $boxWidth, $boxHeight, $partyPositions)
    
    # Only run if specifically set to CURSOR method
    if (-not $global:EnableWaterAnimation -or $global:WaterRenderMethod -ne "CURSOR") { 
        return 
    }
    
    $mapHeight = $map.Count
    $mapWidth = if ($mapHeight -gt 0) { $map[0].Length } else { 0 }
    $viewX = [math]::Max(0, [math]::Min($playerX - [math]::Floor($boxWidth/2), $mapWidth - $boxWidth))
    $viewY = [math]::Max(0, [math]::Min($playerY - [math]::Floor($boxHeight/2), $mapHeight - $boxHeight))
    
    # Update ALL water tiles (legacy method)
    try {
        for ($y = 0; $y -lt $boxHeight; $y++) {
            for ($x = 0; $x -lt $boxWidth; $x++) {
                $worldX = $x + $viewX
                $worldY = $y + $viewY
                
                # Check if this position has water and is safe to access
                if ($worldY -lt $mapHeight -and $worldX -lt $map[$worldY].Length) {
                    $mapChar = $map[$worldY][$worldX]
                    
                    # Only render water tiles, skip if party member is on this tile
                    if ($mapChar -eq '~' -and -not $partyPositions["$worldX,$worldY"]) {
                        $color = Get-WaterColor $worldX $worldY $global:WaterFrame
                        
                        # Safe cursor positioning with bounds checking
                        $cursorX = $x + 1
                        $cursorY = $y + 2
                        if ($cursorX -lt [System.Console]::BufferWidth -and $cursorY -lt [System.Console]::BufferHeight) {
                            [System.Console]::SetCursorPosition($cursorX, $cursorY)
                            Write-Host '~' -ForegroundColor $color -NoNewline
                        }
                    }
                }
            }
        }
    } catch {
        # If water animation fails, fall back to NONE method
        Write-Host "Water animation error - falling back to static water" -ForegroundColor DarkYellow
        $global:WaterRenderMethod = "NONE"
    }
}
