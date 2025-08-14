# =============================================================================
# NEW ENEMY SYSTEM - Sized for Enhanced Battle Display
# =============================================================================
# Designed for 80x25 battle viewport with proper sprite sizing

# =============================================================================
# OLD ENEMIES (COMMENTED OUT FOR REFERENCE)
# =============================================================================
# $Enemy1 = @{
#     Name    = "Test"
#     Level   = 1
#     HP      = 20
#     MaxHP   = 20
#     Attack  = 5
#     Defense = 2
#     Speed   = 5
#     MP      = 0
#     MaxMP   = 0
#     BaseXP  = 5
#     Spells  = @() # Basic enemy - no spells
#     Art     = @(
#         "##########",
#         "# (#_#)/ #",
#         "#  -|-/  #",
#         "# / ^    #",
#         "#  / \   #",
#         "##########"
#     )
# }

# =============================================================================
# SMALL ENEMIES (15w x 5h) - Up to 5 can fit across, 9 total possible
# =============================================================================

$Goblin = @{
    Name    = "Goblin"
    Level   = 1
    HP      = 12
    MaxHP   = 12
    Attack  = 4
    Defense = 1
    Speed   = 6
    MP      = 0
    MaxMP   = 0
    BaseXP  = 3
    Size    = "Small"
    Spells  = @()
    Art     = @(
        "   /\\_/\  /\\   ",
        "  ( o.o ) <|   ",
        "   > ^ <       ",
        "  /|   |\\      ",
        " /_|___|_\\     "
    )
}

$Rat = @{
    Name    = "Giant Rat"
    Level   = 1
    HP      = 8
    MaxHP   = 8
    Attack  = 3
    Defense = 0
    Speed   = 8
    MP      = 0
    MaxMP   = 0
    BaseXP  = 2
    Size    = "Small"
    Spells  = @()
    Art     = @(
        "     /|   /|   ",
        "    (_|__/_|   ",
        "   /  @    \\   ",
        "  <___/\\___>   ",
        " ^^         ^^ "
    )
}

$Slime = @{
    Name    = "Slime"
    Level   = 2
    HP      = 15
    MaxHP   = 15
    Attack  = 2
    Defense = 3
    Speed   = 3
    MP      = 5
    MaxMP   = 5
    BaseXP  = 4
    Size    = "Small"
    Spells  = @("Acid Splash")
    Art     = @(
        "      ___      ",
        "    /     \\    ",
        "   ( o   o )   ",
        "    \\  ~  /    ",
        "     \\___/     "
    )
}

$Imp = @{
    Name    = "Fire Imp"
    Level   = 3
    HP      = 18
    MaxHP   = 18
    Attack  = 6
    Defense = 2
    Speed   = 7
    MP      = 8
    MaxMP   = 8
    BaseXP  = 6
    Size    = "Small"
    Spells  = @("Fire")
    Art     = @(
        "     /^^^\\     ",
        "    <  o  >    ",
        "     \\v_v/     ",
        "   \\\\  |  //   ",
        "    \\\\_|_//    "
    )
}

# =============================================================================
# MEDIUM ENEMIES (25w x 8h) - Up to 3 can fit across, 6 total possible
# =============================================================================

$Orc = @{
    Name    = "Orc Warrior"
    Level   = 4
    HP      = 35
    MaxHP   = 35
    Attack  = 8
    Defense = 4
    Speed   = 4
    MP      = 0
    MaxMP   = 0
    BaseXP  = 12
    Size    = "Medium"
    Spells  = @()
    Art     = @(
        "        _____        ",
        "       /     \\       ",
        "      | (o o) |      ",
        "      |   >   |      ",
        "      |  ___  |      ",
        "     /|  \\_/  |\\     ",
        "    / |_______|  \\   ",
        "   /___|_____|___\\   "
    )
}

$Skeleton = @{
    Name    = "Skeleton"
    Level   = 3
    HP      = 25
    MaxHP   = 25
    Attack  = 7
    Defense = 2
    Speed   = 5
    MP      = 10
    MaxMP   = 10
    BaseXP  = 10
    Size    = "Medium"
    Spells  = @("Bone Toss")
    Art     = @(
        "       .---.       ",
        "      /     \\      ",
        "     | () () |     ",
        "      \\  ^  /      ",
        "       |||||       ",
        "      /|||||\\      ",
        "     / |   | \\     ",
        "    |  |   |  |    "
    )
}

$WolfBeast = @{
    Name    = "Dire Wolf"
    Level   = 5
    HP      = 42
    MaxHP   = 42
    Attack  = 10
    Defense = 5
    Speed   = 9
    MP      = 0
    MaxMP   = 0
    BaseXP  = 15
    Size    = "Medium"
    Spells  = @()
    Art     = @(
        "    /\\   /\\    ",
        "   /  \\_/  \\   ",
        "  /  ^   ^  \\  ",
        " <  (  o  )  > ",
        "  \\    v    /  ",
        "   \\ \\___/ /   ",
        "    \\_____/    ",
        "   ^^     ^^   "
    )
}

$DarkMage = @{
    Name    = "Dark Mage"
    Level   = 6
    HP      = 30
    MaxHP   = 30
    Attack  = 5
    Defense = 3
    Speed   = 6
    MP      = 25
    MaxMP   = 25
    BaseXP  = 18
    Size    = "Medium"
    Spells  = @("Fire", "Ice", "Dark Bolt")
    Art     = @(
        "       .-.-.       ",
        "      /     \\      ",
        "     ( -   - )     ",
        "      |  _  |      ",
        "    __|_____|__    ",
        "   /___________\\   ",
        "  |_____________|  ",
        "       |   |       "
    )
}

# =============================================================================
# LARGE ENEMIES (40w x 12h) - Up to 2 can fit across, 4 total possible
# =============================================================================

$Troll = @{
    Name    = "Mountain Troll"
    Level   = 8
    HP      = 80
    MaxHP   = 80
    Attack  = 15
    Defense = 8
    Speed   = 3
    MP      = 0
    MaxMP   = 0
    BaseXP  = 35
    Size    = "Large"
    Spells  = @()
    Art     = @(
        "              ____              ",
        "             /    \\             ",
        "            / (oo) \\            ",
        "           |   __   |           ",
        "           |  \\__/  |           ",
        "         __|________|__         ",
        "        /              \\        ",
        "       /   ____________  \\      ",
        "      |   /            \\  |     ",
        "      |  |              | |     ",
        "      |  |______________| |     ",
        "      |__________________|     "
    )
}

$Minotaur = @{
    Name    = "Minotaur"
    Level   = 7
    HP      = 65
    MaxHP   = 65
    Attack  = 12
    Defense = 6
    Speed   = 5
    MP      = 8
    MaxMP   = 8
    BaseXP  = 28
    Size    = "Large"
    Spells  = @("Charge")
    Art     = @(
        "            ^^    ^^            ",
        "           (  \\  /  )           ",
        "            \\  \\/  /            ",
        "             \\    /             ",
        "         ____|____|____         ",
        "        /             \\        ",
        "       /  (o)     (o)  \\       ",
        "      |       ___       |      ",
        "      |      \\___/      |      ",
        "      |_________________|      ",
        "       |_______________|       ",
        "        |||         |||        "
    )
}

# =============================================================================
# BOSS ENEMIES (60w x 15h) - Only 1 can fit, used for special encounters
# =============================================================================

$DragonBoss = @{
    Name    = "Ancient Dragon"
    Level   = 15
    HP      = 200
    MaxHP   = 200
    Attack  = 25
    Defense = 15
    Speed   = 8
    MP      = 50
    MaxMP   = 50
    BaseXP  = 100
    Size    = "Boss"
    Spells  = @("Dragon Fire", "Ice Storm", "Heal")
    Art     = @(
        "                     ___====-_  _-====___                     ",
        "               _--^^^#####//      \\\\#####^^^--_               ",
        "            _-^##########//  (    )  \\\\##########^-_           ",
        "           -############//    |\\^^/|   \\\\############-         ",
        "         _/############//     (@::@)    \\\\############\\_       ",
        "        /#############//       \\\\//      \\\\#############\\      ",
        "       -###############//        )|(       \\\\###############-   ",
        "      /################//        )|(        \\\\################\\  ",
        "     /#################//        )|(         \\\\#################\\ ",
        "    -###################//      /^^^^\\       \\\\###################-",
        "   _####################//     |      |      \\\\####################_",
        "  /#####################//     \\      /       \\\\#####################\\",
        " |######################//      \\____/        \\\\######################|",
        " |#####################//                       \\\\#####################|",
        " \\###################//                          \\\\###################/"
    )
}

# =============================================================================
# ENEMY GROUPS BY SIZE AND AREA
# =============================================================================

$SmallEnemies = @($Goblin, $Rat, $Slime, $Imp)
$MediumEnemies = @($Orc, $Skeleton, $WolfBeast, $DarkMage)
$LargeEnemies = @($Troll, $Minotaur)
$BossEnemies = @($DragonBoss)

# Combined lists for different areas
$ForestEnemies = @($Goblin, $Rat, $WolfBeast, $Imp)
$DungeonEnemies = @($Skeleton, $Slime, $Orc, $DarkMage, $Troll)
$CaveEnemies = @($Rat, $Goblin, $Minotaur, $Troll)

# Main enemy lists (replacing old ones)
$EnemyList = @($Goblin, $Rat, $Orc, $Skeleton)  # Basic overworld
$DungeonEnemyList = @($Skeleton, $Slime, $DarkMage, $Troll)  # Dungeon encounters

# =============================================================================
# BATTLE LAYOUT SYSTEM
# =============================================================================

# Generate varied enemy encounters based on area and difficulty
function Get-RandomEnemyEncounter {
    param(
        [string]$Area = "Overworld",
        [int]$Difficulty = 1
    )
    
    $encounter = @()
    
    # TEMPORARY: For Dungeon area, only spawn small enemies to debug "last sprite vanishing" issue
    if ($Area -eq "Dungeon") {
        Write-Host "DEBUG: Dungeon area - spawning only small enemies" -ForegroundColor Yellow
        $layoutType = Get-Random -Minimum 1 -Maximum 4  # Only small enemy patterns
        
        switch ($layoutType) {
            1 { 
                # Single small enemy
                $encounter += (Get-Random -InputObject $SmallEnemies).Clone()
            }
            2 { 
                # Two small enemies
                $encounter += (Get-Random -InputObject $SmallEnemies).Clone()
                $encounter += (Get-Random -InputObject $SmallEnemies).Clone()
            }
            3 { 
                # Three small enemies
                for ($i = 0; $i -lt 3; $i++) {
                    $encounter += (Get-Random -InputObject $SmallEnemies).Clone()
                }
            }
        }
    } else {
        # Normal encounter system for non-Dungeon areas
        $layoutType = Get-Random -Minimum 1 -Maximum 8  # 7 different layout types
        
        switch ($layoutType) {
        1 { 
            # Small Swarm: 3-5 small enemies
            $count = Get-Random -Minimum 3 -Maximum 6
            for ($i = 0; $i -lt $count; $i++) {
                $encounter += (Get-Random -InputObject $SmallEnemies).Clone()
            }
        }
        2 { 
            # Medium Pair: 2 medium enemies
            $encounter += (Get-Random -InputObject $MediumEnemies).Clone()
            $encounter += (Get-Random -InputObject $MediumEnemies).Clone()
        }
        3 { 
            # Mixed Small/Medium: 2 small + 1 medium
            $encounter += (Get-Random -InputObject $SmallEnemies).Clone()
            $encounter += (Get-Random -InputObject $SmallEnemies).Clone()
            $encounter += (Get-Random -InputObject $MediumEnemies).Clone()
        }
        4 { 
            # Single Large: 1 large enemy
            $encounter += (Get-Random -InputObject $LargeEnemies).Clone()
        }
        5 { 
            # Large + Small Support: 1 large + 2 small
            $encounter += (Get-Random -InputObject $LargeEnemies).Clone()
            $encounter += (Get-Random -InputObject $SmallEnemies).Clone()
            $encounter += (Get-Random -InputObject $SmallEnemies).Clone()
        }
        6 { 
            # Triple Medium: 3 medium enemies (challenging)
            for ($i = 0; $i -lt 3; $i++) {
                $encounter += (Get-Random -InputObject $MediumEnemies).Clone()
            }
        }
        7 { 
            # Boss Encounter (rare): 1 boss enemy
            if ($Difficulty -ge 5) {
                $encounter += (Get-Random -InputObject $BossEnemies).Clone()
            } else {
                # Fallback to large enemy for lower difficulties
                $encounter += (Get-Random -InputObject $LargeEnemies).Clone()
            }
        }
        } # End of non-Dungeon encounter system
    }
    
    # Add unique identifiers to enemies of same type
    $typeCount = @{}
    foreach ($enemy in $encounter) {
        if ($typeCount.ContainsKey($enemy.Name)) {
            $typeCount[$enemy.Name]++
            $enemy.Name = "$($enemy.Name) $($typeCount[$enemy.Name])"
        } else {
            $typeCount[$enemy.Name] = 1
            $count = ($encounter | Where-Object { $_.Name -eq $enemy.Name } | Measure-Object).Count
            if ($count -gt 1) {
                $enemy.Name = "$($enemy.Name) 1"
            }
        }
    }
    
    return $encounter
}
