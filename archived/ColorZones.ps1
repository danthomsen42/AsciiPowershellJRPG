# Efficient Color Zone System - Using Native PowerShell Coloring
# This uses the same fast coloring method as Write-Host -ForegroundColor

# ============================================================================
# HELPER FUNCTIONS FOR BULK COLORING - DEFINED FIRST:
# ============================================================================

# Create a rectangular area of colored tiles
function Add-ColorRectangle {
    param($MapZones, $StartX, $StartY, $EndX, $EndY, $Character, $Color)
    
    for ($x = $StartX; $x -le $EndX; $x++) {
        for ($y = $StartY; $y -le $EndY; $y++) {
            $MapZones["$x,$y"] = @{ Char = $Character; Color = $Color }
        }
    }
}

# Create a line of colored tiles
function Add-ColorLine {
    param($MapZones, $StartX, $StartY, $EndX, $EndY, $Character, $Color)
    
    # Horizontal line
    if ($StartY -eq $EndY) {
        $minX = [math]::Min($StartX, $EndX)
        $maxX = [math]::Max($StartX, $EndX)
        for ($x = $minX; $x -le $maxX; $x++) {
            $MapZones["$x,$StartY"] = @{ Char = $Character; Color = $Color }
        }
    }
    # Vertical line
    elseif ($StartX -eq $EndX) {
        $minY = [math]::Min($StartY, $EndY)
        $maxY = [math]::Max($StartY, $EndY)
        for ($y = $minY; $y -le $maxY; $y++) {
            $MapZones["$StartX,$y"] = @{ Char = $Character; Color = $Color }
        }
    }
}

# Create a border/outline
function Add-ColorBorder {
    param($MapZones, $StartX, $StartY, $EndX, $EndY, $Character, $Color)
    
    # Top and bottom borders
    for ($x = $StartX; $x -le $EndX; $x++) {
        $MapZones["$x,$StartY"] = @{ Char = $Character; Color = $Color }  # Top
        $MapZones["$x,$EndY"] = @{ Char = $Character; Color = $Color }    # Bottom
    }
    
    # Left and right borders
    for ($y = $StartY; $y -le $EndY; $y++) {
        $MapZones["$StartX,$y"] = @{ Char = $Character; Color = $Color }  # Left
        $MapZones["$EndX,$y"] = @{ Char = $Character; Color = $Color }    # Right
    }
}

# ============================================================================
# HOW TO ADD COLORS TO YOUR GAME:
# ============================================================================
# 1. Find the map name (like "Town", "Forest", etc.)
# 2. Find the world coordinates (X,Y) where you want color
# 3. Specify the character that should be colored (like ".", "#", "~", etc.)
# 4. Choose a color name (Green, Red, Blue, Yellow, Cyan, Magenta, White, etc.)
#
# EXAMPLE EXPANSIONS:
# - Make trees (#) brown: "15,5" = @{ Char = "#"; Color = "DarkYellow" }
# - Make water (~) blue: "8,12" = @{ Char = "~"; Color = "Blue" }  
# - Make walls (|) gray: "20,20" = @{ Char = "|"; Color = "DarkGray" }
# - Make doors (+) yellow: "10,0" = @{ Char = "+"; Color = "Yellow" }
#
# ADDING NEW MAPS:
# Just add a new map name with its own coordinate list:
# "Forest" = @{
#     "5,5" = @{ Char = "#"; Color = "DarkGreen" }
#     "6,5" = @{ Char = "#"; Color = "DarkGreen" }
# }
# ============================================================================

# Define color zones for each map
$global:ColorZones = @{
    "Town" = @{
        # Format: "X,Y" = @{ Char = "character"; Color = "colorname" }
        
        # Single tile example:
        "10,10" = @{ Char = "."; Color = "Green" }        # Green grass patch
        
        # BULK COLORING EXAMPLES - Uncomment to use:
        # (These are just examples - modify coordinates as needed)
    }
}

# ============================================================================
# BULK COLORING EXAMPLES:
# ============================================================================
# 
# # Create a 10x10 green grass rectangle from (10,10) to (20,20)
# Add-ColorRectangle $global:ColorZones["Town"] 10 10 20 20 "." "Green"
#
# # Create a horizontal line of brown trees from (5,5) to (15,5)  
# Add-ColorLine $global:ColorZones["Town"] 5 5 15 5 "#" "DarkYellow"
#
# # Create a vertical line of gray walls from (8,8) to (8,18)
# Add-ColorLine $global:ColorZones["Town"] 8 8 8 18 "|" "DarkGray"
#
# # Create a border around an area (outline only)
# Add-ColorBorder $global:ColorZones["Town"] 25 25 35 35 "#" "DarkGray"
#
# # Multiple areas with different colors:
# Add-ColorRectangle $global:ColorZones["Town"] 40 10 45 15 "." "DarkGreen"  # Dark grass
# Add-ColorRectangle $global:ColorZones["Town"] 40 16 45 20 "." "Green"      # Light grass
#
# ============================================================================

# UNCOMMENT THE LINES BELOW TO TEST BULK COLORING:
# (This will create your 10x10 green rectangle from (10,10) to (20,20))

# Add-ColorRectangle $global:ColorZones["Town"] 10 10 20 20 "." "Green"

# MORE BULK EXAMPLES (uncomment to use):
# Add-ColorRectangle $global:ColorZones["Town"] 25 10 30 15 "#" "DarkYellow"  # Brown trees
# Add-ColorLine $global:ColorZones["Town"] 0 5 50 5 "|" "DarkGray"            # Horizontal wall
# Add-ColorBorder $global:ColorZones["Town"] 35 35 45 45 "#" "Red"            # Red border

# Add more maps here as needed:
# $global:ColorZones["Forest"] = @{
#     # Example: Create forest areas with bulk functions
# }

# $global:ColorZones["Dungeon"] = @{
#     # Example: Create stone walls and lava areas
# }

# ============================================================================
# AVAILABLE COLORS:
# ============================================================================
# Basic Colors: Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, 
#               DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, 
#               Yellow, White
#
# SUGGESTED COLOR SCHEMES:
# - Grass/Nature: Green, DarkGreen
# - Trees/Wood: DarkYellow (brown), Yellow  
# - Water: Blue, Cyan, DarkBlue
# - Stone/Walls: Gray, DarkGray, White
# - Fire/Lava: Red, DarkRed, Magenta
# - Doors/Important: Yellow, Cyan, White
# - Special Items: Magenta, Cyan
# ============================================================================

# ============================================================================

# Fast color lookup - only called for specific positions we know need coloring
function Get-ColoredTile {
    param($MapName, $X, $Y, $TileChar)
    
    # Only check if we have color zones enabled and for this specific map
    if (-not $global:EnableColorZones -or -not $global:ColorZones.ContainsKey($MapName)) {
        return $null
    }
    
    $positionKey = "$X,$Y"
    $mapZones = $global:ColorZones[$MapName]
    
    # Fast hashtable lookup - only for positions we know are colored
    if ($mapZones.ContainsKey($positionKey)) {
        $zoneInfo = $mapZones[$positionKey]
        if ($zoneInfo.Char -eq $TileChar) {
            return $zoneInfo.Color
        }
    }
    
    return $null
}

# Apply color to a specific console position using native PowerShell coloring
function Set-ColoredTile {
    param($X, $Y, $Character, $Color)
    
    try {
        # Use native console positioning and Write-Host coloring (same as "Write-Host 'text' -ForegroundColor Green")
        [System.Console]::SetCursorPosition($X, $Y)
        Write-Host $Character -ForegroundColor $Color -NoNewline
        # Force immediate output without cursor interference
        [System.Console]::Out.Flush()
    } catch {
        # If positioning fails, just continue silently
    }
}

# Render all colored tiles for a map viewport efficiently
function Render-ColoredTiles {
    param($MapName, $ViewX, $ViewY, $BoxWidth, $BoxHeight, $PlayerX, $PlayerY, $PartyPositions)
    
    if (-not $global:EnableColorZones -or -not $global:ColorZones.ContainsKey($MapName)) {
        return
    }
    
    $mapZones = $global:ColorZones[$MapName]
    
    # Only process the colored positions we know about (very fast)
    foreach ($positionKey in $mapZones.Keys) {
        $coords = $positionKey -split ','
        $worldX = [int]$coords[0]
        $worldY = [int]$coords[1]
        
        # Check if this colored tile is within the current viewport
        $screenX = $worldX - $ViewX
        $screenY = $worldY - $ViewY
        
        if ($screenX -ge 0 -and $screenX -lt $BoxWidth -and $screenY -ge 0 -and $screenY -lt $BoxHeight) {
            # Check if this position isn't currently occupied by player, party, or NPCs
            $partyMember = $PartyPositions["$worldX,$worldY"]
            $isPlayerPosition = ($worldX -eq $PlayerX -and $worldY -eq $PlayerY)
            $npcChar = $null
            if ($global:NPCPositionLookup) {
                $npcChar = $global:NPCPositionLookup["$worldX,$worldY"]
            }
            
            # Only skip coloring if something is actually ON this tile right now
            if (-not $partyMember -and -not $isPlayerPosition -and -not $npcChar) {
                $zoneInfo = $mapZones[$positionKey]
                
                # Use native PowerShell coloring - same speed as Write-Host commands
                $cursorX = $screenX + 1  # Account for box border
                $cursorY = $screenY + 2  # Account for box border and header
                Set-ColoredTile $cursorX $cursorY $zoneInfo.Char $zoneInfo.Color
            }
        }
    }
}
