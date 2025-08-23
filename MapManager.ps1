# Map Management and Door Registry System

# Load required dependencies first
. "$PSScriptRoot\Maps.ps1"

# Registry of all maps by name
$global:Maps = @{
    "Town"     = $TownMap
    "Dungeon"  = $DungeonMap
    "DungeonMap2" = $DungeonMap2
    "RandomizedDungeon" = $global:RandomizedDungeon
    "TownCastle" = $TownCastle
    # Add more maps here, e.g. "Shop" = $ShopMap
}

# Helper: Print coordinates of all '+' doors in each map (run once to update DoorRegistry)
function PrintDoorCoords {
    param($map, $mapName)
    for ($y = 0; $y -lt $map.Count; $y++) {
        $x = $map[$y].IndexOf('+')
        if ($x -ge 0) { Write-Host "$mapName,$x,$y" }
    }
}
# Uncomment to print door coordinates:
# PrintDoorCoords $TownMap "Town"
# PrintDoorCoords $DungeonMap "Dungeon"

# Door registry: (MapName,X,Y) => @{ Map = "DestinationMapName"; X = entryX; Y = entryY }
$global:DoorRegistry = @{
    # Use the actual coordinates found by PrintDoorCoords
    "Town,21,29"    = @{ Map = "Dungeon"; X = 21; Y = 29 }
    "Dungeon,21,29" = @{ Map = "Town";    X = 21; Y = 29 }
    "Dungeon,42,24" = @{ Map = "DungeonMap2";    X = 42; Y = 24 }
    "DungeonMap2,42,10" = @{ Map = "Dungeon";    X = 42; Y = 24 }
    "Town,50,18"    = @{ Map = "TownCastle"; X = 1; Y = 1 }
    # Add more doors for other maps here
}

# Add randomized dungeon door registry entry after the dungeon is generated
if ($global:RandomDungeonEntrance) {
    $global:DoorRegistry["RandomizedDungeon,$($global:RandomDungeonEntrance.X),$($global:RandomDungeonEntrance.Y)"] = @{ Map = "Town"; X = 70; Y = 26 }
}
