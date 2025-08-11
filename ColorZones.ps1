# =============================================================================
# COLOR ZONE SYSTEM - Define colored areas by coordinates
# =============================================================================
# 
# EASY CONFIGURATION: Add colored zones without modifying map data
# CLEAN MAPS: Original maps remain readable ASCII
# FLEXIBLE: Multiple zones, overlapping areas, priority system
#
# Usage in Display.ps1: $color = Get-TileColor $mapName $x $y $tileChar

# *** EASY TOGGLE - Set to $false to completely disable color zones ***
$global:EnableColorZones = $false  # Starting disabled for performance

# *** PERFORMANCE SETTINGS ***
$global:ColorZoneCache = @{}  # Cache for color lookups

# Color zone definitions by map
$global:ColorZones = @{
    "Town" = @(
        # Grass areas (most of the open town area)
        @{
            Name = "TownGrass"
            Character = '.'
            Color = "DarkGreen"
            StartX = 15; EndX = 75
            StartY = 22; EndY = 28
            Priority = 1
        };
        # Castle moat area (water around castle)
        @{
            Name = "CastleMoat" 
            Character = '~'
            Color = "DarkBlue"  # Default water color, but explicitly defined
            StartX = 35; EndX = 60
            StartY = 10; EndY = 21
            Priority = 2
        };
        # Store area (wooden floors)
        @{
            Name = "StoreFloor"
            Character = '.'
            Color = "DarkYellow"
            StartX = 40; EndX = 50
            StartY = 5; EndY = 9
            Priority = 3  # Higher priority overrides grass
        };
        # Castle courtyard (stone floors)
        @{
            Name = "CastleCourtyard"
            Character = '.'
            Color = "Gray"
            StartX = 40; EndX = 55
            StartY = 12; EndY = 18
            Priority = 3
        };
        # Path areas (dirt paths)
        @{
            Name = "TownPaths"
            Character = '.'
            Color = "DarkYellow"
            StartX = 1; EndX = 14
            StartY = 1; EndY = 30
            Priority = 2
        }
    );
    
    "Dungeon" = @(
        # Dungeon floor (stone)
        @{
            Name = "DungeonFloor"
            Character = '.'
            Color = "DarkGray"
            StartX = 1; EndX = 77
            StartY = 1; EndY = 29
            Priority = 1
        };
        # Boss room area (special flooring)
        @{
            Name = "BossRoom"
            Character = '.'
            Color = "DarkRed"
            StartX = 35; EndX = 45
            StartY = 20; EndY = 28
            Priority = 2
        }
    );
    
    "DungeonMap2" = @(
        # Deeper dungeon (darker stone)
        @{
            Name = "DeepDungeonFloor"
            Character = '.'
            Color = "Black"
            StartX = 1; EndX = 77
            StartY = 1; EndY = 29
            Priority = 1
        }
    )
}

# Function to get the appropriate color for a tile
function Get-TileColor {
    param(
        [string]$MapName,
        [int]$X,
        [int]$Y,
        [char]$TileChar
    )
    
    # EARLY RETURN - If color zones disabled, return null immediately
    if (-not $global:EnableColorZones) {
        return $null
    }
    
    # PERFORMANCE - Check cache first
    $cacheKey = "$MapName|$X|$Y|$TileChar"
    if ($global:ColorZoneCache.ContainsKey($cacheKey)) {
        return $global:ColorZoneCache[$cacheKey]
    }
    
    # Return default colors for non-zone tiles
    $defaultColors = @{
        '#' = "DarkGray"    # Walls
        '+' = "Yellow"      # Doors
        'B' = "Red"         # Bosses/Enemies
        'R' = "Magenta"     # Special locations
        'S' = "Cyan"        # Shops/NPCs
        'G' = "Green"       # Guards/NPCs
        'K' = "Yellow"      # King
        'Q' = "Magenta"     # Queen
    }
    
    # Check if we have zones defined for this map
    if (-not $global:ColorZones.ContainsKey($MapName)) {
        $result = $defaultColors[$TileChar]
        $global:ColorZoneCache[$cacheKey] = $result
        return $result
    }
    
    # Find the highest priority zone that matches
    $matchingZones = $global:ColorZones[$MapName] | Where-Object {
        $_.Character -eq $TileChar -and
        $X -ge $_.StartX -and $X -le $_.EndX -and
        $Y -ge $_.StartY -and $Y -le $_.EndY
    } | Sort-Object Priority -Descending
    
    $result = if ($matchingZones.Count -gt 0) {
        $matchingZones[0].Color
    } else {
        $defaultColors[$TileChar]
    }
    
    # Cache the result for future lookups
    $global:ColorZoneCache[$cacheKey] = $result
    return $result
}

# Function to get ANSI color code for any tile
function Get-TileANSIColor {
    param(
        [string]$MapName,
        [int]$X,
        [int]$Y,
        [char]$TileChar
    )
    
    # EARLY RETURN - If color zones disabled, return empty string immediately
    if (-not $global:EnableColorZones) {
        return ""
    }
    
    # ANSI Color code mapping (using [char]27 for better compatibility)
    $ANSIColors = @{
        "Black"       = "$([char]27)[30m"
        "DarkRed"     = "$([char]27)[31m"
        "DarkGreen"   = "$([char]27)[32m"
        "DarkYellow"  = "$([char]27)[33m"
        "DarkBlue"    = "$([char]27)[34m"
        "DarkMagenta" = "$([char]27)[35m"
        "DarkCyan"    = "$([char]27)[36m"
        "DarkGray"    = "$([char]27)[37m"
        "Gray"        = "$([char]27)[90m"   # Bright black
        "Red"         = "$([char]27)[91m"   # Bright red
        "Green"       = "$([char]27)[92m"   # Bright green
        "Yellow"      = "$([char]27)[93m"   # Bright yellow
        "Blue"        = "$([char]27)[94m"   # Bright blue
        "Magenta"     = "$([char]27)[95m"   # Bright magenta
        "Cyan"        = "$([char]27)[96m"   # Bright cyan
        "White"       = "$([char]27)[97m"   # Bright white
        "Reset"       = "$([char]27)[0m"
    }
    
    $color = Get-TileColor $MapName $X $Y $TileChar
    if ($color -and $ANSIColors.ContainsKey($color)) {
        return $ANSIColors[$color]
    }
    
    # Default to no color
    return ""
}

# Function to add a new color zone (for dynamic additions)
function Add-ColorZone {
    param(
        [string]$MapName,
        [string]$ZoneName,
        [char]$Character,
        [string]$Color,
        [int]$StartX, [int]$EndX,
        [int]$StartY, [int]$EndY,
        [int]$Priority = 1
    )
    
    if (-not $global:ColorZones.ContainsKey($MapName)) {
        $global:ColorZones[$MapName] = @()
    }
    
    $newZone = @{
        Name = $ZoneName
        Character = $Character
        Color = $Color
        StartX = $StartX; EndX = $EndX
        StartY = $StartY; EndY = $EndY
        Priority = $Priority
    }
    
    $global:ColorZones[$MapName] += $newZone
    Write-Host "Added color zone '$ZoneName' to map '$MapName'" -ForegroundColor Green
}

# Function to list all zones for a map (debugging)
function Show-ColorZones {
    param([string]$MapName)
    
    if (-not $global:ColorZones.ContainsKey($MapName)) {
        Write-Host "No color zones defined for map: $MapName" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Color Zones for $($MapName):" -ForegroundColor Cyan
    foreach ($zone in $global:ColorZones[$MapName]) {
        Write-Host "  $($zone.Name): '$($zone.Character)' -> $($zone.Color)" -ForegroundColor White
        Write-Host "    Area: ($($zone.StartX),$($zone.StartY)) to ($($zone.EndX),$($zone.EndY)) [Priority: $($zone.Priority)]" -ForegroundColor DarkGray
    }
}

# Function to enable/disable color zones and clear cache
function Set-ColorZones {
    param([bool]$Enabled)
    
    $global:EnableColorZones = $Enabled
    $global:ColorZoneCache = @{}  # Clear cache when toggling
    
    if ($Enabled) {
        Write-Host "Color zones ENABLED - Map areas will be colored" -ForegroundColor Green
    } else {
        Write-Host "Color zones DISABLED - Map will use default colors only" -ForegroundColor Yellow
    }
}

# Function to clear color cache (useful when zones are modified)
function Clear-ColorZoneCache {
    $global:ColorZoneCache = @{}
    Write-Host "Color zone cache cleared" -ForegroundColor Cyan
}

# EASY CONFIGURATION EXAMPLES:
#
# ENABLE/DISABLE COLOR ZONES:
# Set-ColorZones $true   # Enable colored zones
# Set-ColorZones $false  # Disable (back to default colors only)
# 
# To make all '.' tiles in the town center green:
# Add-ColorZone "Town" "CenterGrass" '.' "Green" 20 60 15 25 1
#
# To make a specific building floor brown:
# Add-ColorZone "Town" "Tavern" '.' "DarkYellow" 10 20 5 10 2
#
# To change water color in a specific area:
# Add-ColorZone "Town" "PondWater" '~' "Cyan" 30 40 8 15 1
#
# PERFORMANCE COMMANDS:
# Clear-ColorZoneCache   # Clear cache if zones are modified
