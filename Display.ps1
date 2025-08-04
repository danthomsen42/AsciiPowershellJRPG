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
}

# Function to display combat messages in a fixed area
function Write-CombatMessage {
    param($Message, $Color = "White", $CurrentTurn = "")
    
    # Ultra-simple approach: just write the message without any positioning
    # This prevents scrolling completely
    if ($CurrentTurn -ne "") {
        Write-Host ">>> $CurrentTurn <<< $Message" -ForegroundColor $Color
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

# Function to create turn order based on Speed stats
function New-TurnOrder {
    param($Player, $Enemy)
    
    # Create combatants array with speed and type info
    $combatants = @()
    
    # Add player to combatants
    $combatants += @{
        Name = $Player.Name
        Speed = $Player.Speed
        Type = "Player"
        Entity = $Player
    }
    
    # Add enemy to combatants  
    $combatants += @{
        Name = $Enemy.Name
        Speed = $Enemy.Speed
        Type = "Enemy"
        Entity = $Enemy
    }
    
    # Sort by Speed (highest first), with random tiebreaker
    $turnOrder = $combatants | Sort-Object { $_.Speed + (Get-Random -Minimum 0.0 -Maximum 1.0) } -Descending
    
    return $turnOrder
}

# Function to display turn order to player
function Show-TurnOrder {
    param($TurnOrder, $CurrentTurnIndex)
    
    $orderText = "Turn Order: "
    for ($i = 0; $i -lt $TurnOrder.Count; $i++) {
        $combatant = $TurnOrder[$i]
        if ($i -eq $CurrentTurnIndex) {
            $orderText += "[$($combatant.Name)]"
        } else {
            $orderText += "$($combatant.Name)"
        }
        if ($i -lt $TurnOrder.Count - 1) {
            $orderText += " → "
        }
    }
    
    # Simple approach - just display the turn order
    Write-Host $orderText -ForegroundColor Cyan
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


# =============================================================================
# PHASE 1.4 COMPREHENSIVE SAVE SYSTEM
# =============================================================================

# Save system configuration
$AutoSaveEnabled = $true
$MaxSaveSlots = 5
$SaveDirectory = "$PSScriptRoot/saves"

# Ensure save directory exists
if (-not (Test-Path $SaveDirectory)) {
    New-Item -Path $SaveDirectory -ItemType Directory -Force | Out-Null
}

# Default save paths
$AutoSaveFilePath = "$SaveDirectory/autosave.json"
$QuickSaveFilePath = "$SaveDirectory/quicksave.json"

# Default comprehensive save state structure
$SaveState = @{
    GameInfo = @{
        Version = "1.4"
        SaveTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        PlayTime = 0
        GameStarted = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    Player = @{
        # Core Stats
        XP = 0
        Level = 1
        MonstersDefeated = 0
        
        # Health/Magic
        HP = 30
        MaxHP = 30
        MP = 5
        MaxMP = 5
        
        # Equipment
        Weapon = "Axe"
        Armor = "Leather Armor"
        
        # Position (for map system)
        X = 0
        Y = 0
        CurrentMap = "StartingArea"
        
        # Progress Tracking
        QuestsCompleted = @()
        NPCsSpokenTo = @()
        ItemsCollected = @()
        AreasDiscovered = @()
    }
    Monsters = @{}
    GameEvents = @{
        LastBattleWon = $null
        LastLevelUp = $null
        LastItemFound = $null
        LastNPCTalk = $null
    }
}

# Initialize game start time
$Global:GameStartTime = Get-Date

# Load auto-save if it exists
if (Test-Path $AutoSaveFilePath) {
    try {
        $loadedData = Get-Content $AutoSaveFilePath | ConvertFrom-Json -ErrorAction Stop
        
        # Merge loaded data with default structure (handles version compatibility)
        $SaveState.GameInfo.Version = if ($loadedData.GameInfo.Version) { $loadedData.GameInfo.Version } else { "1.0" }
        $SaveState.GameInfo.SaveTime = if ($loadedData.GameInfo.SaveTime) { $loadedData.GameInfo.SaveTime } else { (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }
        $SaveState.GameInfo.PlayTime = if ($loadedData.GameInfo.PlayTime) { $loadedData.GameInfo.PlayTime } else { 0 }
        $SaveState.GameInfo.GameStarted = if ($loadedData.GameInfo.GameStarted) { $loadedData.GameInfo.GameStarted } else { (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }
        
        # Load player data
        if ($loadedData.Player) {
            $SaveState.Player.XP = if ($loadedData.Player.XP) { $loadedData.Player.XP } else { 0 }
            $SaveState.Player.Level = if ($loadedData.Player.Level) { $loadedData.Player.Level } else { 1 }
            $SaveState.Player.MonstersDefeated = if ($loadedData.Player.MonstersDefeated) { $loadedData.Player.MonstersDefeated } else { 0 }
            $SaveState.Player.HP = if ($loadedData.Player.HP) { $loadedData.Player.HP } else { 30 }
            $SaveState.Player.MaxHP = if ($loadedData.Player.MaxHP) { $loadedData.Player.MaxHP } else { 30 }
            $SaveState.Player.MP = if ($loadedData.Player.MP) { $loadedData.Player.MP } else { 5 }
            $SaveState.Player.MaxMP = if ($loadedData.Player.MaxMP) { $loadedData.Player.MaxMP } else { 5 }
            $SaveState.Player.Weapon = if ($loadedData.Player.Weapon) { $loadedData.Player.Weapon } else { "Axe" }
            $SaveState.Player.Armor = if ($loadedData.Player.Armor) { $loadedData.Player.Armor } else { "Leather Armor" }
            $SaveState.Player.X = if ($loadedData.Player.X) { $loadedData.Player.X } else { 0 }
            $SaveState.Player.Y = if ($loadedData.Player.Y) { $loadedData.Player.Y } else { 0 }
            $SaveState.Player.CurrentMap = if ($loadedData.Player.CurrentMap) { $loadedData.Player.CurrentMap } else { "StartingArea" }
            
            # Load arrays safely
            $SaveState.Player.QuestsCompleted = if ($loadedData.Player.QuestsCompleted) { $loadedData.Player.QuestsCompleted } else { @() }
            $SaveState.Player.NPCsSpokenTo = if ($loadedData.Player.NPCsSpokenTo) { $loadedData.Player.NPCsSpokenTo } else { @() }
            $SaveState.Player.ItemsCollected = if ($loadedData.Player.ItemsCollected) { $loadedData.Player.ItemsCollected } else { @() }
            $SaveState.Player.AreasDiscovered = if ($loadedData.Player.AreasDiscovered) { $loadedData.Player.AreasDiscovered } else { @() }
        }
        
        # Load monsters data
        if ($loadedData.Monsters) {
            $loadedData.Monsters.PSObject.Properties | ForEach-Object {
                $SaveState.Monsters[$_.Name] = $_.Value
            }
        }
        
        # Load game events
        if ($loadedData.GameEvents) {
            $SaveState.GameEvents.LastBattleWon = $loadedData.GameEvents.LastBattleWon
            $SaveState.GameEvents.LastLevelUp = $loadedData.GameEvents.LastLevelUp
            $SaveState.GameEvents.LastItemFound = $loadedData.GameEvents.LastItemFound
            $SaveState.GameEvents.LastNPCTalk = $loadedData.GameEvents.LastNPCTalk
        }
        
        Write-Host "Auto-save loaded successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Failed to load auto-save file. Using defaults." -ForegroundColor Yellow
    }
}

# =============================================================================
# SAVE SYSTEM FUNCTIONS
# =============================================================================

# Auto-save function (called automatically during gameplay)
function AutoSave-GameState {
    if (-not $AutoSaveEnabled) { return }
    
    # Update save metadata
    $SaveState.GameInfo.SaveTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $SaveState.GameInfo.PlayTime = ((Get-Date) - $Global:GameStartTime).TotalMinutes
    
    try {
        $SaveState | ConvertTo-Json -Depth 10 | Set-Content -Path $AutoSaveFilePath
        Write-Host "[AUTO-SAVED]" -ForegroundColor DarkGreen -NoNewline
        Write-Host " " -NoNewline  # Space for formatting
    } catch {
        Write-Host "[AUTO-SAVE FAILED]" -ForegroundColor DarkRed -NoNewline
        Write-Host " " -NoNewline
    }
}

# Manual quick save function
function QuickSave-GameState {
    # Update save metadata
    $SaveState.GameInfo.SaveTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $SaveState.GameInfo.PlayTime = ((Get-Date) - $Global:GameStartTime).TotalMinutes
    
    try {
        $SaveState | ConvertTo-Json -Depth 10 | Set-Content -Path $QuickSaveFilePath
        Write-Host "Game quick-saved successfully!" -ForegroundColor Cyan
    } catch {
        Write-Host "Quick save failed!" -ForegroundColor Red
    }
}

# Manual save to specific slot
function Save-GameToSlot {
    param([int]$SlotNumber)
    
    if ($SlotNumber -lt 1 -or $SlotNumber -gt $MaxSaveSlots) {
        Write-Host "Invalid save slot. Use 1-$MaxSaveSlots." -ForegroundColor Red
        return
    }
    
    $SlotFilePath = "$SaveDirectory/save_slot_$SlotNumber.json"
    
    # Update save metadata
    $SaveState.GameInfo.SaveTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $SaveState.GameInfo.PlayTime = ((Get-Date) - $Global:GameStartTime).TotalMinutes
    
    try {
        $SaveState | ConvertTo-Json -Depth 10 | Set-Content -Path $SlotFilePath
        Write-Host "Game saved to Slot $SlotNumber successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Save to Slot $SlotNumber failed!" -ForegroundColor Red
    }
}

# Load from specific slot
function Load-GameFromSlot {
    param([int]$SlotNumber)
    
    if ($SlotNumber -lt 1 -or $SlotNumber -gt $MaxSaveSlots) {
        Write-Host "Invalid save slot. Use 1-$MaxSaveSlots." -ForegroundColor Red
        return $false
    }
    
    $SlotFilePath = "$SaveDirectory/save_slot_$SlotNumber.json"
    
    if (-not (Test-Path $SlotFilePath)) {
        Write-Host "Save Slot $SlotNumber is empty." -ForegroundColor Yellow
        return $false
    }
    
    try {
        $loadedData = Get-Content $SlotFilePath | ConvertFrom-Json -ErrorAction Stop
        
        # TODO: Implement full state restoration (would need to update player object)
        Write-Host "Save file loaded from Slot $SlotNumber!" -ForegroundColor Green
        Write-Host "Note: Full state restoration will be implemented when needed." -ForegroundColor Yellow
        return $true
    } catch {
        Write-Host "Failed to load from Slot $SlotNumber." -ForegroundColor Red
        return $false
    }
}

# Show all save slots
function Show-SaveSlots {
    Write-Host "`n=== SAVE SLOTS ===" -ForegroundColor Cyan
    
    # Check auto-save
    if (Test-Path $AutoSaveFilePath) {
        $autoSaveInfo = Get-Content $AutoSaveFilePath | ConvertFrom-Json
        Write-Host "AUTO: Level $($autoSaveInfo.Player.Level) - $($autoSaveInfo.GameInfo.SaveTime)" -ForegroundColor Green
    } else {
        Write-Host "AUTO: [Empty]" -ForegroundColor DarkGray
    }
    
    # Check quick save
    if (Test-Path $QuickSaveFilePath) {
        $quickSaveInfo = Get-Content $QuickSaveFilePath | ConvertFrom-Json
        Write-Host "QUICK: Level $($quickSaveInfo.Player.Level) - $($quickSaveInfo.GameInfo.SaveTime)" -ForegroundColor Cyan
    } else {
        Write-Host "QUICK: [Empty]" -ForegroundColor DarkGray
    }
    
    # Check manual save slots
    for ($i = 1; $i -le $MaxSaveSlots; $i++) {
        $SlotFilePath = "$SaveDirectory/save_slot_$i.json"
        if (Test-Path $SlotFilePath) {
            $slotInfo = Get-Content $SlotFilePath | ConvertFrom-Json
            Write-Host "SLOT $i`: Level $($slotInfo.Player.Level) - $($slotInfo.GameInfo.SaveTime)" -ForegroundColor White
        } else {
            Write-Host "SLOT $i`: [Empty]" -ForegroundColor DarkGray
        }
    }
    Write-Host "=================" -ForegroundColor Cyan
}

# Interactive save menu
function Show-SaveMenu {
    Clear-Host
    Write-Host "=== SAVE SYSTEM ===" -ForegroundColor Cyan
    Write-Host "F5  = Quick Save" -ForegroundColor Yellow
    Write-Host "1-5 = Save to Slot" -ForegroundColor Yellow
    Write-Host "Q   = Quick Load" -ForegroundColor Green
    Write-Host "L   = Load from Slot" -ForegroundColor Green
    Write-Host "V   = View All Save Slots" -ForegroundColor White
    Write-Host "ESC = Return to Game" -ForegroundColor Gray
    Write-Host "===================" -ForegroundColor Cyan
    
    while ($true) {
        $input = [System.Console]::ReadKey($true)
        
        switch ($input.Key) {
            "F5" { 
                QuickSave-GameState
                Start-Sleep -Milliseconds 1000
                return 
            }
            "D1" { Save-GameToSlot 1; Start-Sleep -Milliseconds 1000; return }
            "D2" { Save-GameToSlot 2; Start-Sleep -Milliseconds 1000; return }
            "D3" { Save-GameToSlot 3; Start-Sleep -Milliseconds 1000; return }
            "D4" { Save-GameToSlot 4; Start-Sleep -Milliseconds 1000; return }
            "D5" { Save-GameToSlot 5; Start-Sleep -Milliseconds 1000; return }
            "Q" {
                if (Test-Path $QuickSaveFilePath) {
                    Write-Host "Quick save loaded!" -ForegroundColor Green
                    # TODO: Implement full game state restoration
                } else {
                    Write-Host "No quick save found!" -ForegroundColor Red
                }
                Start-Sleep -Milliseconds 1000
                return
            }
            "L" {
                Write-Host "Enter slot number (1-5): " -NoNewline
                $slotInput = [System.Console]::ReadKey($true)
                $slotNum = $null
                if ([int]::TryParse($slotInput.KeyChar, [ref]$slotNum) -and $slotNum -ge 1 -and $slotNum -le 5) {
                    Load-GameFromSlot $slotNum
                } else {
                    Write-Host "Invalid slot number!" -ForegroundColor Red
                }
                Start-Sleep -Milliseconds 1000
                return
            }
            "V" {
                Show-SaveSlots
                Write-Host "`nPress any key to continue..." -ForegroundColor Gray
                [System.Console]::ReadKey($true) | Out-Null
                Show-SaveMenu
                return
            }
            "Escape" { return }
        }
    }
}

# Legacy function for backward compatibility
function Save-GameState {
    AutoSave-GameState
}

# =============================================================================
# AUTO-SAVE TRIGGER FUNCTIONS
# =============================================================================

function Trigger-BattleVictoryAutoSave {
    param($enemyName, $xpGained)
    $SaveState.GameEvents.LastBattleWon = @{
        Enemy = $enemyName
        XPGained = $xpGained
        Time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    AutoSave-GameState
}

function Trigger-LevelUpAutoSave {
    param($newLevel)
    $SaveState.GameEvents.LastLevelUp = @{
        Level = $newLevel
        Time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    AutoSave-GameState
}

function Trigger-ItemFoundAutoSave {
    param($itemName)
    if ($SaveState.Player.ItemsCollected -notcontains $itemName) {
        $SaveState.Player.ItemsCollected += $itemName
    }
    $SaveState.GameEvents.LastItemFound = @{
        Item = $itemName
        Time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    AutoSave-GameState
}

function Trigger-NPCTalkAutoSave {
    param($npcName)
    if ($SaveState.Player.NPCsSpokenTo -notcontains $npcName) {
        $SaveState.Player.NPCsSpokenTo += $npcName
    }
    $SaveState.GameEvents.LastNPCTalk = @{
        NPC = $npcName
        Time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    AutoSave-GameState
}

function Trigger-MapTransitionAutoSave {
    param($newMap, $x, $y)
    $SaveState.Player.CurrentMap = $newMap
    $SaveState.Player.X = $x
    $SaveState.Player.Y = $y
    
    if ($SaveState.Player.AreasDiscovered -notcontains $newMap) {
        $SaveState.Player.AreasDiscovered += $newMap
    }
    
    AutoSave-GameState
}

# =============================================================================
# PLAYER SYNCHRONIZATION FUNCTIONS
# =============================================================================

# Sync save state player data with the actual Player object
function Sync-PlayerFromSaveState {
    param($PlayerObject)
    
    # Update Player object with saved data
    $PlayerObject.XP = $SaveState.Player.XP
    $PlayerObject.Level = $SaveState.Player.Level
    $PlayerObject.HP = $SaveState.Player.HP
    $PlayerObject.MaxHP = $SaveState.Player.MaxHP
    $PlayerObject.MP = $SaveState.Player.MP
    $PlayerObject.MaxMP = $SaveState.Player.MaxMP
    $PlayerObject.Equipped.Weapon = $SaveState.Player.Weapon
    $PlayerObject.Equipped.Armor = $SaveState.Player.Armor
    
    return $PlayerObject
}

# Update save state from Player object changes
function Update-SaveStateFromPlayer {
    param($PlayerObject)
    
    $SaveState.Player.XP = $PlayerObject.XP
    $SaveState.Player.Level = $PlayerObject.Level
    $SaveState.Player.HP = $PlayerObject.HP
    $SaveState.Player.MaxHP = $PlayerObject.MaxHP
    $SaveState.Player.MP = $PlayerObject.MP
    $SaveState.Player.MaxMP = $PlayerObject.MaxMP
    $SaveState.Player.Weapon = $PlayerObject.Equipped.Weapon
    $SaveState.Player.Armor = $PlayerObject.Equipped.Armor
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
    [void]$sb.AppendLine("Save: F5=Quick Save   F9=Save Menu   Auto-saves after battles!")
    
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
                
                # Sync Player object with save state
                $Player = Sync-PlayerFromSaveState $Player
                
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



                # Initialize battle state
                $playerDefending = $false
                $inCombat = $true
                
                # Create turn order based on Speed stats
                $turnOrder = New-TurnOrder $player $enemy
                $currentTurnIndex = 0
                $maxTurns = 100  # Prevent infinite loops
                $turnCount = 0
                
                while ($inCombat -and $turnCount -lt $maxTurns) {
                    $turnCount++
                    
                    # Simple safe approach: minimal clear at start of each combat round
                    # Clear screen only once per turn to reset everything cleanly
                    [System.Console]::Clear()
                    
                    # Redraw the essential combat interface (static elements)
                    Draw-CombatViewport $enemyArt $EnemyName $boxWidth $boxHeight
                    Write-Host "Combat Controls: A=Attack   D=Defend   S=Spells   I=Items   R=Run" -ForegroundColor Cyan
                    
                    # Calculate and display current stats
                    $enemyHPDisplay = [math]::Max(0, $enemy.HP)
                    $enemyMPDisplay = [math]::Max(0, $enemy.MP)
                    $playerHPDisplay = [math]::Max(0, $player.HP)
                    $playerMPDisplay = [math]::Max(0, $player.MP)
                    $playerHPStr = $playerHPDisplay.ToString().PadRight(4)
                    $playerMaxHPStr = $player.MaxHP.ToString().PadRight(4)
                    $playerMPStr = $playerMPDisplay.ToString().PadRight(4)
                    $playerMaxMPStr = $player.MaxMP.ToString().PadRight(4)
                    $enemyHPStr = $enemyHPDisplay.ToString().PadRight(4)
                    $enemyMaxHPStr = $enemy.MaxHP.ToString().PadRight(4)
                    $enemyMPStr = $enemyMPDisplay.ToString().PadRight(4)
                    $enemyMaxMPStr = $enemy.MaxMP.ToString().PadRight(4)
                    
                    Write-Host ("Player HP: $playerHPStr/$playerMaxHPStr   MP: $playerMPStr/$playerMaxMPStr") -ForegroundColor White
                    Write-Host ("Enemy  HP: $enemyHPStr/$enemyMaxHPStr   MP: $enemyMPStr/$enemyMaxMPStr") -ForegroundColor Yellow
                    
                    # Show turn order
                    Show-TurnOrder $turnOrder $currentTurnIndex
                    
                    # Get current combatant
                    $currentCombatant = $turnOrder[$currentTurnIndex]
                    $isPlayerTurn = ($currentCombatant.Type -eq "Player")
                    
                    if ($isPlayerTurn) {
                        # Player turn
                        Write-CombatMessage "Choose your action..." "White" "PLAYER TURN"
                        $input = [System.Console]::ReadKey($true)
                        # Reset defending status at start of turn
                        $playerDefending = $false
                        
                        # Process player action
                        if ($input.Key -eq "A") {
                            # Attack action
                            $damage = [math]::Max(1, $player.Attack - $enemy.Defense)
                            $enemy.HP -= $damage
                            Write-CombatMessage "You attack $EnemyName for $damage damage!" "Yellow"
                            Start-Sleep -Milliseconds 1200
                            
                        } elseif ($input.Key -eq "D") {
                            # Defend action - reduces incoming damage next turn
                            $playerDefending = $true
                            Write-CombatMessage "You brace yourself for the enemy's attack!" "Green"
                            Start-Sleep -Milliseconds 1200
                            
                        } elseif ($input.Key -eq "S") {
                            # Spell casting menu
                            Write-CombatMessage "Opening spell menu..." "Magenta"
                            Start-Sleep -Milliseconds 500
                            
                            # Calculate safe menu position based on console size
                            $menuStartY = 28  # Start menu below message area
                            $maxY = [System.Console]::BufferHeight - 10
                            if ($menuStartY -gt $maxY) {
                                $menuStartY = $maxY
                            }
                            
                            # Clear area below message for spell menu - safely
                            try {
                                for ($clearY = $menuStartY; $clearY -lt ($menuStartY + 8) -and $clearY -lt ([System.Console]::BufferHeight - 1); $clearY++) {
                                    [System.Console]::SetCursorPosition(0, $clearY)
                                    Write-Host (" " * 80)
                                }
                            } catch {
                                # If cursor positioning fails, just clear the screen and continue
                                [System.Console]::Clear()
                            }
                            
                            # Display spell menu in controlled position
                            try {
                                [System.Console]::SetCursorPosition(0, $menuStartY)
                                Write-Host "Available Spells:" -ForegroundColor Magenta
                            } catch {
                                Write-Host "`nAvailable Spells:" -ForegroundColor Magenta
                            }
                            
                            . "$PSScriptRoot\Spells.ps1"
                            $availableSpells = @()
                            $menuLine = $menuStartY + 1
                            
                            for ($i = 0; $i -lt $player.Spells.Count; $i++) {
                                $spellName = $player.Spells[$i]
                                $spell = $Spells | Where-Object { $_.Name -eq $spellName }
                                if ($spell -and $player.MP -ge $spell.MP) {
                                    $availableSpells += $spell
                                    try {
                                        [System.Console]::SetCursorPosition(0, $menuLine)
                                        Write-Host "[$($i+1)] $($spell.Name) (MP: $($spell.MP))" -ForegroundColor Cyan
                                    } catch {
                                        Write-Host "[$($i+1)] $($spell.Name) (MP: $($spell.MP))" -ForegroundColor Cyan
                                    }
                                    $menuLine++
                                }
                            }
                            
                            if ($availableSpells.Count -eq 0) {
                                Write-CombatMessage "No spells available (insufficient MP)!" "Red"
                                Start-Sleep -Milliseconds 1500
                                continue
                            }
                            
                            try {
                                [System.Console]::SetCursorPosition(0, $menuLine)
                                Write-Host "[0] Cancel" -ForegroundColor Gray
                                $menuLine++
                                [System.Console]::SetCursorPosition(0, $menuLine)
                                Write-Host "Choose a spell: " -NoNewline -ForegroundColor White
                            } catch {
                                Write-Host "[0] Cancel" -ForegroundColor Gray
                                Write-Host "Choose a spell: " -NoNewline -ForegroundColor White
                            }
                            
                            $spellChoice = [System.Console]::ReadKey($true)
                            $spellIndex = [int]$spellChoice.KeyChar - 49  # Convert to 0-based index
                            
                            if ($spellChoice.KeyChar -eq '0') {
                                Write-CombatMessage "Spell casting cancelled." "Gray"
                                Start-Sleep -Milliseconds 800
                                continue
                            } elseif ($spellIndex -ge 0 -and $spellIndex -lt $availableSpells.Count) {
                                $selectedSpell = $availableSpells[$spellIndex]
                                $player.MP -= $selectedSpell.MP
                                
                                if ($selectedSpell.Type -eq "Attack") {
                                    $spellDamage = $selectedSpell.Power + [math]::Floor($player.Attack / 2)
                                    $enemy.HP -= $spellDamage
                                    Write-CombatMessage "You cast $($selectedSpell.Name) for $spellDamage damage!" "Magenta"
                                } elseif ($selectedSpell.Type -eq "Recovery") {
                                    $healAmount = [math]::Min($selectedSpell.Power, $player.MaxHP - $player.HP)
                                    $player.HP += $healAmount
                                    Write-CombatMessage "You cast $($selectedSpell.Name) and recover $healAmount HP!" "Green"
                                }
                                Start-Sleep -Milliseconds 1200
                            } else {
                                Write-CombatMessage "Invalid spell selection!" "Red"
                                Start-Sleep -Milliseconds 1200
                                continue
                            }
                            
                        } elseif ($input.Key -eq "I") {
                            # Items menu (basic implementation)
                            Write-CombatMessage "Opening inventory..." "Yellow"
                            Start-Sleep -Milliseconds 500
                            
                            if ($player.Inventory.Count -eq 0) {
                                # Basic item system - add potion if inventory empty for demo
                                if ($player.Inventory -notcontains "Health Potion") {
                                    $player.Inventory += "Health Potion"
                                }
                            }
                            
                            if ($player.Inventory.Count -eq 0) {
                                Write-CombatMessage "No items available!" "Red"
                                Start-Sleep -Milliseconds 1500
                                continue
                            }
                            
                            # Calculate safe menu position
                            $menuStartY = 28  # Start menu below message area
                            $maxY = [System.Console]::BufferHeight - 6
                            if ($menuStartY -gt $maxY) {
                                $menuStartY = $maxY
                            }
                            
                            # Clear area below message for item menu - safely
                            try {
                                for ($clearY = $menuStartY; $clearY -lt ($menuStartY + 5) -and $clearY -lt ([System.Console]::BufferHeight - 1); $clearY++) {
                                    [System.Console]::SetCursorPosition(0, $clearY)
                                    Write-Host (" " * 80)
                                }
                            } catch {
                                # If cursor positioning fails, fall back to normal output
                            }
                            
                            # Display item menu in controlled position
                            try {
                                [System.Console]::SetCursorPosition(0, $menuStartY)
                                Write-Host "Inventory:" -ForegroundColor Yellow
                                
                                [System.Console]::SetCursorPosition(0, $menuStartY + 1)
                                Write-Host "[1] Health Potion (Restores 15 HP)" -ForegroundColor Cyan
                                [System.Console]::SetCursorPosition(0, $menuStartY + 2)
                                Write-Host "[0] Cancel" -ForegroundColor Gray
                                [System.Console]::SetCursorPosition(0, $menuStartY + 3)
                                Write-Host "Choose an item: " -NoNewline -ForegroundColor White
                            } catch {
                                Write-Host "`nInventory:" -ForegroundColor Yellow
                                Write-Host "[1] Health Potion (Restores 15 HP)" -ForegroundColor Cyan
                                Write-Host "[0] Cancel" -ForegroundColor Gray
                                Write-Host "Choose an item: " -NoNewline -ForegroundColor White
                            }
                            
                            $itemChoice = [System.Console]::ReadKey($true)
                            
                            if ($itemChoice.KeyChar -eq '0') {
                                Write-CombatMessage "Item use cancelled." "Gray"
                                Start-Sleep -Milliseconds 800
                                continue
                            } elseif ($itemChoice.KeyChar -eq '1' -and $player.Inventory -contains "Health Potion") {
                                $healAmount = [math]::Min(15, $player.MaxHP - $player.HP)
                                $player.HP += $healAmount
                                $player.Inventory = $player.Inventory | Where-Object { $_ -ne "Health Potion" }
                                Write-CombatMessage "You use a Health Potion and recover $healAmount HP!" "Green"
                                Start-Sleep -Milliseconds 1200
                            } else {
                                Write-CombatMessage "Invalid item selection!" "Red"
                                Start-Sleep -Milliseconds 1200
                                continue
                            }
                            
                        } elseif ($input.Key -eq "R") {
                            # Attempt to flee
                            $fleeChance = 75 + ($player.Level * 5)  # Base 75% + 5% per level
                            $fleeRoll = Get-Random -Minimum 1 -Maximum 101
                            
                            if ($fleeRoll -le $fleeChance) {
                                Write-CombatMessage "You successfully escaped!" "Green"
                                Start-Sleep -Milliseconds 1500
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
                                break
                            } else {
                                Write-CombatMessage "Couldn't escape!" "Red"
                                Start-Sleep -Milliseconds 1200
                            }
                            
                        } else {
                            # Invalid input
                            Write-CombatMessage "Invalid action! Use A/D/S/I/R" "Red"
                            Start-Sleep -Milliseconds 800
                            continue
                        }
                        
                    } else {
                        # Enemy turn - Enhanced AI with spell casting
                        . "$PSScriptRoot\Spells.ps1"
                        
                        $enemyAction = "attack"  # Default action
                        $spellToCast = $null
                        
                        # AI Decision Logic
                        if ($enemy.Spells.Count -gt 0 -and $enemy.MP -gt 0) {
                            # Check available spells
                            $availableSpells = @()
                            foreach ($spellName in $enemy.Spells) {
                                $spell = $Spells | Where-Object { $_.Name -eq $spellName }
                                if ($spell -and $enemy.MP -ge $spell.MP) {
                                    $availableSpells += $spell
                                }
                            }
                            
                            if ($availableSpells.Count -gt 0) {
                                # AI Decision Making
                                $healingSpells = $availableSpells | Where-Object { $_.Type -eq "Recovery" }
                                $attackSpells = $availableSpells | Where-Object { $_.Type -eq "Attack" }
                                
                                # Healing logic: heal if health is below 40%
                                if ($healingSpells.Count -gt 0 -and $enemy.HP -le ($enemy.MaxHP * 0.4)) {
                                    $spellToCast = $healingSpells[0]
                                    $enemyAction = "heal"
                                }
                                # Attack spell logic: 60% chance to cast attack spell if available
                                elseif ($attackSpells.Count -gt 0 -and (Get-Random -Minimum 1 -Maximum 101) -le 60) {
                                    $spellToCast = $attackSpells | Get-Random
                                    $enemyAction = "spell"
                                }
                            }
                        }
                        
                        # Execute enemy action
                        if ($enemyAction -eq "heal" -and $spellToCast) {
                            # Enemy heals itself
                            $enemy.MP -= $spellToCast.MP
                            $healAmount = [math]::Min($spellToCast.Power, $enemy.MaxHP - $enemy.HP)
                            $enemy.HP += $healAmount
                            Write-CombatMessage "$EnemyName casts $($spellToCast.Name) and recovers $healAmount HP!" "Yellow" "ENEMY TURN"
                            
                        } elseif ($enemyAction -eq "spell" -and $spellToCast) {
                            # Enemy casts attack spell
                            $enemy.MP -= $spellToCast.MP
                            $spellDamage = $spellToCast.Power + [math]::Floor($enemy.Attack / 2)
                            
                            # Apply defense bonus if player defended
                            if ($playerDefending) {
                                $spellDamage = [math]::Max(1, [math]::Floor($spellDamage / 2))
                                Write-CombatMessage "$EnemyName casts $($spellToCast.Name), but your defense reduces the damage to $spellDamage!" "Blue" "ENEMY TURN"
                            } else {
                                Write-CombatMessage "$EnemyName casts $($spellToCast.Name) for $spellDamage damage!" "Magenta" "ENEMY TURN"
                            }
                            
                            $player.HP -= $spellDamage
                            
                        } else {
                            # Basic attack
                            $enemyDamage = [math]::Max(1, $enemy.Attack - $player.Defense)
                            
                            # Apply defense bonus if player defended
                            if ($playerDefending) {
                                $enemyDamage = [math]::Max(1, [math]::Floor($enemyDamage / 2))
                                Write-CombatMessage "$EnemyName attacks, but your defense reduces the damage to $enemyDamage!" "Blue" "ENEMY TURN"
                            } else {
                                Write-CombatMessage "$EnemyName attacks you for $enemyDamage damage!" "Red" "ENEMY TURN"
                            }
                            
                            $player.HP -= $enemyDamage
                        }
                        
                        Start-Sleep -Milliseconds 2000  # Pause to read the enemy action
                    }
                    
                    # Check if enemy is defeated
                    if ($enemy.HP -le 0) {
                        $xpGained = $enemy.Level * $enemy.BaseXP
                        $player.XP += $xpGained
                        Write-CombatMessage "$EnemyName defeated! You gained $xpGained XP. Total XP: $($player.XP)" "Green"
                        # Update save state for monster kill
                        $SaveState.Player.XP = $player.XP
                        $SaveState.Player.MonstersDefeated++
                        if (-not $SaveState.Monsters.ContainsKey($EnemyName)) {
                            $SaveState.Monsters[$EnemyName] = 0
                        }
                        $SaveState.Monsters[$EnemyName]++
                        
                        # Trigger auto-save for battle victory
                        Trigger-BattleVictoryAutoSave -enemyName $EnemyName -xpGained $xpGained
                        
                        # Update global save state with final player stats
                        Update-SaveStateFromPlayer $player
                        
                        Start-Sleep -Milliseconds 2000
                        # Clear input buffer when exiting battle
                        while ([System.Console]::KeyAvailable) {
                            [System.Console]::ReadKey($true) | Out-Null
                        }
                        $battleMode = $false
                        $inCombat = $false
                        $battleCooldown = 100  # 100 frames of cooldown before next battle
                        [System.Console]::Clear()
                        break
                    }
                    
                    # Check if player is defeated
                    if ($player.HP -le 0) {
                        Write-CombatMessage "You were defeated!" "Magenta"
                        Start-Sleep -Milliseconds 2000
                        # Clear input buffer when exiting battle
                        while ([System.Console]::KeyAvailable) {
                            [System.Console]::ReadKey($true) | Out-Null
                        }
                        $battleMode = $false
                        $inCombat = $false
                        $battleCooldown = 100  # 100 frames of cooldown before next battle
                        [System.Console]::Clear()
                        break
                    }
                    
                    # Advance to next turn
                    $currentTurnIndex = ($currentTurnIndex + 1) % $turnOrder.Count
                    
                    # Reset defending status for enemy turns (player defending only lasts one enemy attack)
                    if ($currentCombatant.Type -eq "Enemy") {
                        $playerDefending = $false
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
                "F5"        { QuickSave-GameState }
                "F9"        { Show-SaveMenu }
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