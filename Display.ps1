# Draw the combat viewport in the same box area
function Draw-CombatViewport {
    param($enemyArt, $enemyName, $boxWidth, $boxHeight)
    [System.Console]::SetCursorPosition(0, 0)
    Write-Host ("+" + ("-" * $boxWidth) + "+") -ForegroundColor Yellow
    Write-Host ("Enemy: $enemyName") -ForegroundColor Red
    $artHeight = $enemyArt.Count
    $artWidth = ($enemyArt | Measure-Object -Property Length -Maximum).Maximum
    $startY = [math]::Max(0, [math]::Floor(($boxHeight - $artHeight) / 2))
    $startX = [math]::Max(0, [math]::Floor(($boxWidth - $artWidth) / 2))
    for ($y = 0; $y -lt $boxHeight; $y++) {
        $row = "|"
        if ($y -ge $startY -and $y -lt ($startY + $artHeight)) {
            $artLine = $enemyArt[$y - $startY]
            $padLeft = " " * $startX
            $padRight = " " * ($boxWidth - $startX - $artLine.Length)
            $row += $padLeft + $artLine + $padRight
        } else {
            $row += " " * $boxWidth
        }
        $row += "|"
        Write-Host $row -ForegroundColor DarkGray
    }
    Write-Host ("+" + ("-" * $boxWidth) + "+") -ForegroundColor Yellow
    Write-Host "Press R to Run away and return to the map." -ForegroundColor Cyan
    [System.Console]::Out.Flush()
}
# Set console output encoding to UTF-8 for Unicode support
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Import transition effects
. "$PSScriptRoot\Transitions.ps1"

# Hashtable of available transitions
$TransitionEffects = @{
    "wipe"  = "ShowWipeTransition"
    "flash" = "ShowFlashTransition"
    "fade"  = "ShowFadeTransition"
}

# Pick transition type (change to "flash" or "fade" to try others)
$ChosenTransition = "flash"
# ==============================
# JRPG Real-Time Movement Demo (Real-Time Updates)
# ==============================

# Enable ANSI escape codes (optional, but not needed for SetCursorPosition)
# Remove stray output (True True) and unnecessary code

# Set box dimensions
$boxWidth = 50
$boxHeight = 20


# ==============================
# Save/Load System for Player State
# ==============================
$SaveFilePath = "$PSScriptRoot/savegame.json"

# Default save state structure
$SaveState = @{
    Player = @{
        XP = 0
        Level = 1
        MonstersDefeated = 0
    }
    Monsters = @{}
}

# Load save state if file exists
if (Test-Path $SaveFilePath) {
    try {
        $loadedData = Get-Content $SaveFilePath | ConvertFrom-Json -ErrorAction Stop
        # Convert PSCustomObject back to proper hashtables
        $SaveState = @{
            Player = @{
                XP = $loadedData.Player.XP
                Level = $loadedData.Player.Level
                MonstersDefeated = $loadedData.Player.MonstersDefeated
            }
            Monsters = @{}
        }
        # Convert monsters object to hashtable
        if ($loadedData.Monsters) {
            $loadedData.Monsters.PSObject.Properties | ForEach-Object {
                $SaveState.Monsters[$_.Name] = $_.Value
            }
        }
    } catch {
        Write-Host "Failed to load save file. Using defaults." -ForegroundColor Red
    }
}

# Helper: Save current state to file
function Save-GameState {
    $SaveState | ConvertTo-Json | Set-Content -Path $SaveFilePath
}

# Set initial player position (centered, inside box)
$playerX = [math]::Floor($boxWidth / 2)
$playerY = [math]::Floor($boxHeight / 2)

# ASCII character for player
$playerChar = "@"

# Load NPCs (simple version for performance testing)
. "$PSScriptRoot\NPCs_Simple.ps1"

# Load maps
. "$PSScriptRoot\Maps.ps1"

# Load enemies
. "$PSScriptRoot\Enemies.ps1"

# Pause for startup error visibility (after imports)
Read-Host "Press Enter to continue..."

# Registry of all maps by name
$Maps = @{
    "Town"     = $TownMap
    "Dungeon"  = $DungeonMap
    "DungeonMap2" = $DungeonMap2
    "RandomizedDungeon" = $global:RandomizedDungeon
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
$DoorRegistry = @{
    # Use the actual coordinates found by PrintDoorCoords
    "Town,21,29"    = @{ Map = "Dungeon"; X = 21; Y = 29 }
    "Dungeon,21,29" = @{ Map = "Town";    X = 21; Y = 29 }
    "Dungeon,42,24" = @{ Map = "DungeonMap2";    X = 42; Y = 24 }
    "DungeonMap2,42,10" = @{ Map = "Dungeon";    X = 42; Y = 24 }
    # Add more doors for other maps here
}

# Add randomized dungeon door registry entry after the dungeon is generated
if ($global:RandomDungeonEntrance) {
    $DoorRegistry["RandomizedDungeon,$($global:RandomDungeonEntrance.X),$($global:RandomDungeonEntrance.Y)"] = @{ Map = "Town"; X = 70; Y = 26 }
}

# Function to draw the current viewport of the map
function Draw-Viewport {
    param($map, $playerX, $playerY, $boxWidth, $boxHeight)
    # Calculate viewport origin so player is centered when possible
    $mapWidth = $map[0].Length
    $mapHeight = $map.Count
    $viewX = [math]::Max(0, [math]::Min($playerX - [math]::Floor($boxWidth/2), $mapWidth - $boxWidth))
    $viewY = [math]::Max(0, [math]::Min($playerY - [math]::Floor($boxHeight/2), $mapHeight - $boxHeight))
    
    # Build entire frame as one large string for fastest output
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("+" + ("-" * $boxWidth) + "+")
    [void]$sb.AppendLine("Map: $CurrentMapName | Player: ($playerX,$playerY)")
    
    # Pre-build all viewport rows
    for ($y = 0; $y -lt $boxHeight; $y++) {
        $mapRow = $map[$viewY + $y].Substring($viewX, $boxWidth)
        $rowChars = $mapRow.ToCharArray()
        
        # Fast character replacement using array indexing
        for ($x = 0; $x -lt $boxWidth; $x++) {
            $worldX = $x + $viewX
            $worldY = $y + $viewY
            if ($worldX -eq $playerX -and $worldY -eq $playerY) {
                $rowChars[$x] = $playerChar
            } else {
                # Ultra-fast NPC lookup - direct hashtable access
                $npcChar = $global:NPCPositionLookup["$worldX,$worldY"]
                if ($npcChar) {
                    $rowChars[$x] = $npcChar.Char
                }
            }
        }
        [void]$sb.AppendLine("|" + (-join $rowChars) + "|")
    }
    
    [void]$sb.AppendLine("+" + ("-" * $boxWidth) + "+")
    [void]$sb.AppendLine("Use Arrow Keys or WASD to move. Press Q to quit. Step on + to change maps.")
    
    # Single output operation - no colors for maximum speed
    [System.Console]::SetCursorPosition(0, 0)
    [System.Console]::Write($sb.ToString())
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

 # Start in town
 $CurrentMapName = "Town"
 $currentMap = $Maps[$CurrentMapName]

 $running = $true
 $battleMode = $false
 $battleCooldown = 0  # Prevent immediate battles after exiting one

try {
    while ($running) {
        $errorMsg = $null
        try {
            if ($battleMode) {
                # Load player and enemy stats
                . "$PSScriptRoot\Player.ps1"
                . "$PSScriptRoot\Enemies.ps1"
                # Select enemy list based on current map
                if ($CurrentMapName -eq "Dungeon") {
                    $enemy = (Get-Random -InputObject $DungeonEnemyList).Clone()
                } elseif ($CurrentMapName -eq "DungeonMap2") {
                    $enemy = (Get-Random -InputObject @($enemy2, $enemy3)).Clone()
                } else {
                    $enemy = (Get-Random -InputObject $DungeonEnemyList).Clone()
                }
                $player = $Player.Clone()
                $EnemyName = $enemy.Name
                $enemyArt = $enemy.Art



                $inCombat = $true
                while ($inCombat) {
                    # Draw combat viewport with HP info
                    [System.Console]::SetCursorPosition(0, 0)
                    Draw-CombatViewport $enemyArt $EnemyName $boxWidth $boxHeight
                    $enemyHPDisplay = [math]::Max(0, $enemy.HP)
                    $playerHPDisplay = [math]::Max(0, $player.HP)
                    $playerHPStr = $playerHPDisplay.ToString().PadRight(4)
                    $playerMaxHPStr = $player.MaxHP.ToString().PadRight(4)
                    $enemyHPStr = $enemyHPDisplay.ToString().PadRight(4)
                    Write-Host ("Player HP: $playerHPStr/$playerMaxHPStr   Enemy HP: $enemyHPStr    ") -ForegroundColor White
                    Write-Host "X: Attack   R: Run" -ForegroundColor Cyan
                    $input = [System.Console]::ReadKey($true)
                    if ($input.Key -eq "X") {
                        $damage = [math]::Max(1, $player.Attack - $enemy.Defense)
                        $enemy.HP -= $damage
                        Write-Host "You attack $EnemyName for $damage damage!"
                        Start-Sleep -Milliseconds 500
                        if ($enemy.HP -le 0) {
                            $xpGained = $enemy.Level * $enemy.BaseXP
                            $player.XP += $xpGained
                            Write-Host "$EnemyName defeated! You gained $xpGained XP. Total XP: $($player.XP)"
                            # Update save state for monster kill (save only here)
                            $SaveState.Player.XP = $player.XP
                            $SaveState.Player.MonstersDefeated++
                            if (-not $SaveState.Monsters.ContainsKey($EnemyName)) {
                                $SaveState.Monsters[$EnemyName] = 0
                            }
                            $SaveState.Monsters[$EnemyName]++
                            Save-GameState
                            Start-Sleep -Milliseconds 1500
                            # Clear input buffer when exiting battle
                            while ([System.Console]::KeyAvailable) {
                                [System.Console]::ReadKey($true) | Out-Null
                            }
                            $battleMode = $false
                            $inCombat = $false
                            $battleCooldown = 100  # 100 frames of cooldown before next battle
                            [System.Console]::Clear()
                            continue
                        }
                        # Enemy turn
                        $enemyDamage = [math]::Max(1, $enemy.Attack - $player.Defense)
                        $player.HP -= $enemyDamage
                        Write-Host "$EnemyName attacks you for $enemyDamage damage!"
                        Start-Sleep -Milliseconds 500
                        if ($player.HP -le 0) {
                            Write-Host "You were defeated!" -ForegroundColor Magenta
                            Start-Sleep -Milliseconds 1500
                            # Clear input buffer when exiting battle
                            while ([System.Console]::KeyAvailable) {
                                [System.Console]::ReadKey($true) | Out-Null
                            }
                            $battleMode = $false
                            $inCombat = $false
                            $battleCooldown = 100  # 100 frames of cooldown before next battle
                            [System.Console]::Clear()
                            continue
                        }
                    } elseif ($input.Key -eq "R") {
                        # Track monster as encountered only if not already in hashtable
                        if (-not $SaveState.Monsters.ContainsKey($EnemyName)) {
                            $SaveState.Monsters[$EnemyName] = 0
                            Save-GameState
                        }
                        # Clear input buffer when exiting battle
                        while ([System.Console]::KeyAvailable) {
                            [System.Console]::ReadKey($true) | Out-Null
                        }
                        $battleMode = $false
                        $inCombat = $false
                        $battleCooldown = 100  # 100 frames of cooldown before next battle
                        [System.Console]::Clear()
                        continue
                    }
                }
                continue
            }

            Draw-Viewport $currentMap $playerX $playerY $boxWidth $boxHeight

            # Read a key without waiting for Enter
            $key = [System.Console]::ReadKey($true)

            # Calculate new position
            $newX = $playerX
            $newY = $playerY
            $moved = $false
            switch ($key.Key) {
                "LeftArrow" { $newX = [math]::Max(0, $playerX - 1); $moved = $true }
                "A"         { $newX = [math]::Max(0, $playerX - 1); $moved = $true }
                "RightArrow"{ $newX = [math]::Min($currentMap[0].Length - 1, $playerX + 1); $moved = $true }
                "D"         { $newX = [math]::Min($currentMap[0].Length - 1, $playerX + 1); $moved = $true }
                "UpArrow"   { $newY = [math]::Max(0, $playerY - 1); $moved = $true }
                "W"         { $newY = [math]::Max(0, $playerY - 1); $moved = $true }
                "DownArrow" { $newY = [math]::Min($currentMap.Count - 1, $playerY + 1); $moved = $true }
                "S"         { $newY = [math]::Min($currentMap.Count - 1, $playerY + 1); $moved = $true }
                "Q"         { $running = $false }
            }

            # Collision: only move if not wall
            if ($currentMap[$newY][$newX] -ne '#') {
                $playerX = $newX
                $playerY = $newY
            }
            
            # Clear input buffer to prevent movement lag (only in exploration mode)
            if ($moved) {
                while ([System.Console]::KeyAvailable) {
                    [System.Console]::ReadKey($true) | Out-Null
                }
            }

            # NPC interaction - direct hashtable lookup
            $npcHere = $global:NPCPositionLookup["$playerX,$playerY"]
            if ($npcHere) {
                Write-Host "Press E to talk to $($npcHere.Name) ($($npcHere.Char))" -ForegroundColor Yellow
                $input = [System.Console]::ReadKey($true)
                if ($input.Key -eq "E") {
                    Show-NPCDialogue $npcHere
                }
            }

            # Map switching: step on a door symbol ('+')
            if ($currentMap[$playerY][$playerX] -eq '+') {
                $key = "$CurrentMapName,$playerX,$playerY"
                if ($DoorRegistry.ContainsKey($key)) {
                    & $TransitionEffects[$ChosenTransition] $boxWidth $boxHeight
                    $dest = $DoorRegistry[$key]
                    $CurrentMapName = $dest.Map
                    $currentMap = $Maps[$CurrentMapName]
                    $playerX = $dest.X
                    $playerY = $dest.Y
                }
            }

            # Randomized dungeon entrance: step on 'R' symbol
            if ($currentMap[$playerY][$playerX] -eq 'R') {
                Write-Host "Entering the randomized dungeon..." -ForegroundColor Green
                Start-Sleep -Milliseconds 500
                
                # Generate a new randomized dungeon each time
                $global:RandomizedDungeon = New-RandomizedDungeon
                $Maps["RandomizedDungeon"] = $global:RandomizedDungeon
                
                # Add door registry entry for exiting the dungeon
                $exitKey = "RandomizedDungeon,$($global:RandomDungeonEntrance.X),$($global:RandomDungeonEntrance.Y)"
                $DoorRegistry[$exitKey] = @{ Map = "Town"; X = 70; Y = 26 }
                
                # Transition to the dungeon
                & $TransitionEffects[$ChosenTransition] $boxWidth $boxHeight
                $CurrentMapName = "RandomizedDungeon"
                $currentMap = $Maps[$CurrentMapName]
                $playerX = $global:RandomDungeonEntrance.X
                $playerY = $global:RandomDungeonEntrance.Y
            }

            # Random battle trigger in Dungeon (with cooldown)
            if ($CurrentMapName -eq "Dungeon" -and $battleCooldown -le 0) {
                $encounterRoll = Get-Random -Minimum 1 -Maximum 21
                if ($encounterRoll -eq 1) {
                    # Clear input buffer before entering battle to prevent movement spill-over
                    while ([System.Console]::KeyAvailable) {
                        [System.Console]::ReadKey($true) | Out-Null
                    }
                    $battleMode = $true
                    [System.Console]::Clear()
                    continue
                }
            }
            
            # Decrease battle cooldown
            if ($battleCooldown -gt 0) {
                $battleCooldown--
            }
        } catch {
            $errorMsg = $_.Exception.Message
        }

        if ($errorMsg) {
            [System.Console]::SetCursorPosition(0, $boxHeight + 4)
            Write-Host "ERROR: $errorMsg" -ForegroundColor Red
            $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
            $logPath = Join-Path $scriptDir 'error.log'
            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            if (!(Test-Path $logPath)) { New-Item -Path $logPath -ItemType File -Force | Out-Null }
            "[$timestamp] $errorMsg" | Add-Content -Path $logPath
        }

        Start-Sleep -Milliseconds 20
    }
    # End of while ($running) loop
    # Move cursor below the box for end message
    [System.Console]::SetCursorPosition(0, $boxHeight + 3)
    Write-Host "`nThanks for playing!"
}
# End of main try block
catch {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $logPath = Join-Path $scriptDir 'error.log'
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $startupError = $_.Exception.Message
    if (!(Test-Path $logPath)) { New-Item -Path $logPath -ItemType File -Force | Out-Null }
    "[$timestamp] STARTUP ERROR: $startupError" | Add-Content -Path $logPath
    Write-Host "Startup ERROR: $startupError" -ForegroundColor Red
}