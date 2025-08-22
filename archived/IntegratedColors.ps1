# Integrated Color Map System - No Overdrawing!
# This system integrates colors directly into map rendering like HTML/CSS

# ============================================================================
# COLOR MAP DEFINITIONS - Like CSS Styles for Your Maps
# ============================================================================

# Define color styles for different tile types on each map
$global:MapColorStyles = @{
    "Town" = @{
        # Tile-based coloring (applies to ALL instances of that character)
        "TileColors" = @{
            # "." = "Green"        # All dots are green
            # "#" = "DarkYellow"   # All trees are brown
            # "|" = "DarkGray"     # All walls are gray
            # "~" = "Blue"         # All water is blue
            # "+" = "Yellow"       # All doors are yellow
        }
        
        # Zone-based coloring (specific rectangular areas)
        "ColorZones" = @(
            # Rectangle from (10,10) to (20,20) - all dots in this area are green
            @{
                StartX = 10; StartY = 10; EndX = 20; EndY = 20
                Character = "."; Color = "Green"; Description = "Green grass area"
            }
            # Add more zones as needed
        )
        
        # Line-based coloring (walls, paths, etc.)
        "ColorLines" = @(
            # Horizontal line from (5,5) to (25,5) - all walls are gray
            # @{
            #     StartX = 5; StartY = 5; EndX = 25; EndY = 5
            #     Character = "|"; Color = "DarkGray"; Description = "Stone wall"
            # }
        )
    }
    
    # Add more maps here:
    # "Forest" = @{
    #     "TileColors" = @{
    #         "#" = "DarkGreen"    # All trees are dark green
    #         "." = "Green"        # All ground is light green
    #     }
    # }
}

# ============================================================================
# INTEGRATED COLOR RENDERING - BUILT INTO MAP DISPLAY
# ============================================================================

# Get the color for a specific tile at world coordinates (called during map rendering)
function Get-IntegratedTileColor {
    param($MapName, $WorldX, $WorldY, $TileChar)
    
    if (-not $global:EnableColorZones -or -not $global:MapColorStyles.ContainsKey($MapName)) {
        return $null
    }
    
    $mapStyles = $global:MapColorStyles[$MapName]
    
    # Check zone-based coloring first (most specific)
    if ($mapStyles.ColorZones) {
        foreach ($zone in $mapStyles.ColorZones) {
            if ($WorldX -ge $zone.StartX -and $WorldX -le $zone.EndX -and
                $WorldY -ge $zone.StartY -and $WorldY -le $zone.EndY -and
                $TileChar -eq $zone.Character) {
                return $zone.Color
            }
        }
    }
    
    # Check line-based coloring
    if ($mapStyles.ColorLines) {
        foreach ($line in $mapStyles.ColorLines) {
            # Horizontal line
            if ($line.StartY -eq $line.EndY -and $WorldY -eq $line.StartY -and
                $WorldX -ge [math]::Min($line.StartX, $line.EndX) -and 
                $WorldX -le [math]::Max($line.StartX, $line.EndX) -and
                $TileChar -eq $line.Character) {
                return $line.Color
            }
            # Vertical line
            if ($line.StartX -eq $line.EndX -and $WorldX -eq $line.StartX -and
                $WorldY -ge [math]::Min($line.StartY, $line.EndY) -and 
                $WorldY -le [math]::Max($line.StartY, $line.EndY) -and
                $TileChar -eq $line.Character) {
                return $line.Color
            }
        }
    }
    
    # Check tile-based coloring (least specific, applies everywhere)
    if ($mapStyles.TileColors -and $mapStyles.TileColors.ContainsKey($TileChar)) {
        return $mapStyles.TileColors[$TileChar]
    }
    
    return $null
}

# Generate ANSI color code for integrated rendering
function Get-IntegratedTileANSI {
    param($MapName, $WorldX, $WorldY, $TileChar)
    
    $color = Get-IntegratedTileColor $MapName $WorldX $WorldY $TileChar
    if (-not $color) {
        return ""
    }
    
    # Convert PowerShell color names to ANSI codes
    switch ($color) {
        "Green"     { return "$([char]27)[32m" }
        "Red"       { return "$([char]27)[31m" }
        "Blue"      { return "$([char]27)[34m" }
        "Yellow"    { return "$([char]27)[33m" }
        "Cyan"      { return "$([char]27)[36m" }
        "Magenta"   { return "$([char]27)[35m" }
        "White"     { return "$([char]27)[37m" }
        "DarkGray"  { return "$([char]27)[90m" }
        "DarkGreen" { return "$([char]27)[32m" }
        "DarkYellow" { return "$([char]27)[33m" }
        "DarkRed"   { return "$([char]27)[31m" }
        default     { return "" }
    }
}

# Reset ANSI colors
$global:ANSIReset = "$([char]27)[0m"
