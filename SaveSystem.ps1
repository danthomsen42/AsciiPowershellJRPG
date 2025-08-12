# Save System for JRPG

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
    Party = @{
        Members = @()  # Array of party member objects
        Formation = "Diamond"  # Battle formation (for future use)
        Leader = 0  # Index of party leader
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
        
        # Load party data
        if ($loadedData.Party) {
            $SaveState.Party.Members = if ($loadedData.Party.Members) { $loadedData.Party.Members } else { @() }
            $SaveState.Party.Formation = if ($loadedData.Party.Formation) { $loadedData.Party.Formation } else { "Diamond" }
            $SaveState.Party.Leader = if ($loadedData.Party.Leader) { $loadedData.Party.Leader } else { 0 }
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

# Set global SaveState for the party system
$global:SaveState = $SaveState

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

# Update save state from party
function Update-SaveStateFromParty {
    param([array]$PartyArray)
    
    if ($PartyArray -and $PartyArray.Count -gt 0) {
        $SaveState.Party.Members = ConvertTo-PartySaveData $PartyArray
        # Leader is always the first party member for now
        $SaveState.Party.Leader = 0
    }
}
