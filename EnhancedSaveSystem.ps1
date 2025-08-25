# =============================================================================
# PHASE 5.4 ENHANCED SAVE SYSTEM - Complete Party & Progression Management
# =============================================================================
# Comprehensive save system supporting:
# - Full party data (stats, colors, equipment, spells)
# - Map position and current location  
# - XP and character progression
# - Inventory and equipped items
# - Save identification with party composition and timestamps
# - Auto-save (single slot) vs Manual saves (multiple slots)

$script:SaveDirectory = "$PSScriptRoot/saves"
$script:AutoSaveFilePath = "$SaveDirectory/autosave.json"
$script:SaveSlotsDirectory = "$SaveDirectory/manual"
$script:MaxManualSaves = 20  # Allow up to 20 manual saves

# Ensure save directories exist
if (-not (Test-Path $SaveDirectory)) {
    New-Item -Path $SaveDirectory -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path $SaveSlotsDirectory)) {
    New-Item -Path $SaveSlotsDirectory -ItemType Directory -Force | Out-Null
}

# =============================================================================
# SAVE DATA STRUCTURE CREATION
# =============================================================================

function New-SaveState {
    param(
        [string]$SaveType = "manual"  # "auto" or "manual"
    )
    
    $saveData = @{
        # Metadata
        GameInfo = @{
            Version = "5.4"
            SaveTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            SaveType = $SaveType
            PlayTime = if ($global:GameStartTime) { ((Get-Date) - $global:GameStartTime).TotalMinutes } else { 0 }
        }
        
        # Map and Position Data
        Location = @{
            CurrentMap = if ($global:CurrentMapName) { $global:CurrentMapName } else { "Town" }
            PlayerX = if ($global:PlayerCurrentX -ne $null) { $global:PlayerCurrentX } else { 40 }
            PlayerY = if ($global:PlayerCurrentY -ne $null) { $global:PlayerCurrentY } else { 12 }
        }
        
        # Complete Party Data
        Party = @{
            Members = @()
            Formation = @()
        }
        
        # Global Inventory (shared items)
        Inventory = @{
            Items = if ($global:Inventory) { $global:Inventory } else { @() }
        }
        
        # Game Progress
        Progress = @{
            TotalXPGained = 0
            BattlesWon = 0
            NPCsSpokenTo = if ($global:SaveState -and $global:SaveState.Player.NPCsSpokenTo) { $global:SaveState.Player.NPCsSpokenTo } else { @() }
            QuestsCompleted = if ($global:SaveState -and $global:SaveState.Player.QuestsCompleted) { $global:SaveState.Player.QuestsCompleted } else { @() }
            AreasDiscovered = if ($global:SaveState -and $global:SaveState.Player.AreasDiscovered) { $global:SaveState.Player.AreasDiscovered } else { @() }
        }
    }
    
    # Save full party data
    if ($global:Party -and $global:Party.Count -gt 0) {
        foreach ($member in $global:Party) {
            $memberData = @{
                Name = $member.Name
                Class = $member.Class
                Level = $member.Level
                Color = $member.Color
                
                # Current Stats
                HP = $member.HP
                MaxHP = $member.MaxHP
                MP = $member.MP
                MaxMP = $member.MaxMP
                
                # Core Stats
                Attack = $member.Attack
                Defense = $member.Defense
                Speed = $member.Speed
                XP = $member.XP
                NextLevelXP = $member.NextLevelXP
                
                # Equipment
                Equipped = if ($member.Equipped) {
                    @{
                        Weapon = $member.Equipped.Weapon
                        Armor = $member.Equipped.Armor
                        Accessory = $member.Equipped.Accessory
                    }
                } else {
                    @{
                        Weapon = $null
                        Armor = $null  
                        Accessory = $null
                    }
                }
                
                # Spells and Abilities
                Spells = if ($member.Spells) { $member.Spells } else { @() }
                
                # Individual Inventory
                Inventory = if ($member.Inventory) { $member.Inventory } else { @() }
                
                # Position Data
                Position = if ($member.Position) {
                    @{
                        X = $member.Position.X
                        Y = $member.Position.Y
                    }
                } else {
                    @{
                        X = 40
                        Y = 12
                    }
                }
                
                # Class Data (for reconstruction)
                MapSymbol = $member.MapSymbol
                ClassData = if ($member.ClassData) {
                    @{
                        MapSymbol = $member.ClassData.MapSymbol
                        BaseHP = $member.ClassData.BaseHP
                        BaseMP = $member.ClassData.BaseMP
                        BaseAttack = $member.ClassData.BaseAttack
                        BaseDefense = $member.ClassData.BaseDefense
                        BaseSpeed = $member.ClassData.BaseSpeed
                        StartingWeapon = $member.ClassData.StartingWeapon
                        StartingArmor = $member.ClassData.StartingArmor
                        Spells = $member.ClassData.Spells
                    }
                } else { $null }
            }
            
            $saveData.Party.Members += $memberData
        }
        
        # Save party formation
        if ($global:PartyFormation) {
            $saveData.Party.Formation = $global:PartyFormation
        }
    }
    
    return $saveData
}

# =============================================================================
# SAVE IDENTIFICATION AND DISPLAY
# =============================================================================

function Get-SaveDisplayInfo {
    param($SaveData)
    
    if (-not $SaveData -or -not $SaveData.Party -or -not $SaveData.Party.Members) {
        return @{
            Title = "Empty Save"
            PartyComposition = "No party data"
            Timestamp = "Unknown"
            Location = "Unknown"
            Details = "No data"
        }
    }
    
    # Create party composition string
    $partyComp = @()
    foreach ($member in $SaveData.Party.Members) {
        $partyComp += "$($member.Class.Substring(0,1).ToUpper())$($member.Level)"
    }
    $partyComposition = $partyComp -join "-"
    
    # Get character names
    $names = @()
    foreach ($member in $SaveData.Party.Members) {
        $names += $member.Name
    }
    $characterNames = $names -join ", "
    
    return @{
        Title = "Party: $partyComposition"
        PartyComposition = $partyComposition
        Timestamp = $SaveData.GameInfo.SaveTime
        Location = $SaveData.Location.CurrentMap
        CharacterNames = $characterNames
        PlayTime = [math]::Round($SaveData.GameInfo.PlayTime, 1)
        Details = "$characterNames on $($SaveData.Location.CurrentMap) - $([math]::Round($SaveData.GameInfo.PlayTime, 1))m played"
    }
}

function Show-SavePreview {
    param(
        $SaveData,
        [string]$SaveFile
    )
    
    $info = Get-SaveDisplayInfo $SaveData
    
    Clear-Host
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                               SAVE PREVIEW" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Save File: " -NoNewline -ForegroundColor White
    Write-Host $SaveFile -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Party Composition: " -NoNewline -ForegroundColor White
    Write-Host $info.PartyComposition -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Characters:" -ForegroundColor White
    foreach ($member in $SaveData.Party.Members) {
        Write-Host "  • " -NoNewline -ForegroundColor White
        $memberColor = if ($member.Color) { $member.Color } else { "White" }
        Write-Host "$($member.Name)" -NoNewline -ForegroundColor $memberColor
        Write-Host " the " -NoNewline -ForegroundColor White
        Write-Host "$($member.Class)" -NoNewline -ForegroundColor Green
        Write-Host " (Level $($member.Level)) " -NoNewline -ForegroundColor White
        Write-Host "HP: $($member.HP)/$($member.MaxHP) MP: $($member.MP)/$($member.MaxMP)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Location: " -NoNewline -ForegroundColor White
    Write-Host "$($info.Location) ($($SaveData.Location.PlayerX),$($SaveData.Location.PlayerY))" -ForegroundColor Yellow
    
    Write-Host "Save Time: " -NoNewline -ForegroundColor White
    Write-Host $info.Timestamp -ForegroundColor Gray
    
    Write-Host "Play Time: " -NoNewline -ForegroundColor White
    Write-Host "$($info.PlayTime) minutes" -ForegroundColor Gray
    
    Write-Host ""
}

# =============================================================================
# AUTO-SAVE SYSTEM (SINGLE SLOT)
# =============================================================================

function Save-AutoSave {
    try {
        $saveData = New-SaveState -SaveType "auto"
        $saveData | ConvertTo-Json -Depth 10 | Set-Content -Path $script:AutoSaveFilePath -Encoding UTF8
        Write-Host "Auto-saved successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Auto-save failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Load-AutoSave {
    if (-not (Test-Path $script:AutoSaveFilePath)) {
        Write-Host "No auto-save found" -ForegroundColor Yellow
        return $false
    }
    
    try {
        $saveData = Get-Content -Path $script:AutoSaveFilePath -Raw | ConvertFrom-Json
        Show-SavePreview $saveData "Auto-Save"
        
        Write-Host "Load this auto-save? (Y/N): " -NoNewline -ForegroundColor Yellow
        $key = [Console]::ReadKey($true)
        Write-Host ""
        
        if ($key.Key -eq 'Y') {
            Restore-SaveState $saveData
            Write-Host "Auto-save loaded successfully!" -ForegroundColor Green
            Write-Host "Starting game..." -ForegroundColor Green
            Start-Sleep -Milliseconds 1000
            
            # Launch the game with the loaded state
            . "$PSScriptRoot\Display.ps1"
            return $true
        }
        return $false
    } catch {
        Write-Host "Failed to load auto-save: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# =============================================================================
# MANUAL SAVE SYSTEM (MULTIPLE SLOTS)
# =============================================================================

function Save-ManualSave {
    param([string]$SaveName = "")
    
    # Generate save name if not provided
    if (-not $SaveName) {
        $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
        $SaveName = "save_$timestamp"
    }
    
    $savePath = "$SaveSlotsDirectory/$SaveName.json"
    
    try {
        $saveData = New-SaveState -SaveType "manual"
        $saveData | ConvertTo-Json -Depth 10 | Set-Content -Path $savePath -Encoding UTF8
        
        $info = Get-SaveDisplayInfo $saveData
        Write-Host "Manual save created: $SaveName" -ForegroundColor Green
        Write-Host "  Party: $($info.PartyComposition)" -ForegroundColor White
        Write-Host "  Location: $($info.Location)" -ForegroundColor White
        return $savePath
    } catch {
        Write-Host "Manual save failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-ManualSaves {
    $saveFiles = Get-ChildItem -Path $SaveSlotsDirectory -Filter "*.json" -ErrorAction SilentlyContinue
    $saves = @()
    
    foreach ($file in $saveFiles) {
        try {
            $saveData = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $info = Get-SaveDisplayInfo $saveData
            
            $saves += @{
                FileName = $file.Name
                FilePath = $file.FullName
                SaveData = $saveData
                DisplayInfo = $info
            }
        } catch {
            Write-Host "Warning: Could not read save file $($file.Name)" -ForegroundColor Yellow
        }
    }
    
    # Sort by timestamp (newest first)
    return $saves | Sort-Object { $_.SaveData.GameInfo.SaveTime } -Descending
}

function Show-SaveMenu {
    $saves = Get-ManualSaves
    
    do {
        Clear-Host
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "                              SAVE/LOAD MENU" -ForegroundColor Cyan
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "[S] Create New Manual Save" -ForegroundColor Green
        Write-Host "[A] Load Auto-Save" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Manual Saves:" -ForegroundColor White
        
        if ($saves.Count -eq 0) {
            Write-Host "  No manual saves found" -ForegroundColor Gray
        } else {
            for ($i = 0; $i -lt $saves.Count; $i++) {
                $save = $saves[$i]
                $info = $save.DisplayInfo
                Write-Host "  [$($i + 1)] " -NoNewline -ForegroundColor White
                Write-Host "$($info.Title)" -NoNewline -ForegroundColor Green
                Write-Host " - $($info.Timestamp)" -ForegroundColor Gray
            }
        }
        
        Write-Host ""
        Write-Host "[ESC] Back to game" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Select option: " -NoNewline -ForegroundColor Yellow
        
        $key = [Console]::ReadKey($true)
        Write-Host ""
        
        switch ($key.Key) {
            'S' {
                Save-ManualSave
                Write-Host "Press any key to continue..." -ForegroundColor Gray
                [Console]::ReadKey($true) | Out-Null
            }
            'A' {
                Load-AutoSave
            }
            'Escape' {
                return
            }
            default {
                # Check if it's a number for loading saves
                $saveIndex = [int]::TryParse($key.KeyChar, [ref]$null)
                if ($saveIndex -and $saveIndex -ge 1 -and $saveIndex -le $saves.Count) {
                    $selectedSave = $saves[$saveIndex - 1]
                    Show-SavePreview $selectedSave.SaveData $selectedSave.FileName
                    
                    Write-Host "Load this save? (Y/N): " -NoNewline -ForegroundColor Yellow
                    $loadKey = [Console]::ReadKey($true)
                    Write-Host ""
                    
                    if ($loadKey.Key -eq 'Y') {
                        Restore-SaveState $selectedSave.SaveData
                        Write-Host "Save loaded successfully!" -ForegroundColor Green
                        Write-Host "Starting game..." -ForegroundColor Green
                        Start-Sleep -Milliseconds 1000
                        
                        # Launch the game with the loaded state
                        . "$PSScriptRoot\Display.ps1"
                        return  # Exit the save menu since we're launching the game
                    } else {
                        Write-Host "Load cancelled." -ForegroundColor Yellow
                        Write-Host "Press any key to continue..." -ForegroundColor Gray
                        [Console]::ReadKey($true) | Out-Null
                    }
                }
            }
        }
    } while ($true)
}

# =============================================================================
# SAVE STATE RESTORATION
# =============================================================================

function Restore-SaveState {
    param($SaveData)
    
    if (-not $SaveData) {
        Write-Host "No save data to restore" -ForegroundColor Red
        return
    }

    try {
        Write-Host "Restoring game state..." -ForegroundColor Yellow
        
        # Set global variables that the game systems expect
        $global:CurrentMapName = $SaveData.Location.CurrentMap
        $global:PlayerStartX = $SaveData.Location.PlayerX
        $global:PlayerStartY = $SaveData.Location.PlayerY
        
        # Also set the old-style save state format for compatibility
        $global:SaveState = @{
            Player = @{
                CurrentMap = $SaveData.Location.CurrentMap
                X = $SaveData.Location.PlayerX
                Y = $SaveData.Location.PlayerY
                NPCsSpokenTo = if ($SaveData.Progress.NPCsSpokenTo) { $SaveData.Progress.NPCsSpokenTo } else { @() }
                QuestsCompleted = if ($SaveData.Progress.QuestsCompleted) { $SaveData.Progress.QuestsCompleted } else { @() }
                AreasDiscovered = if ($SaveData.Progress.AreasDiscovered) { $SaveData.Progress.AreasDiscovered } else { @() }
            }
            Party = @{
                Members = @()
            }
        }

        # Restore party data
        if ($SaveData.Party -and $SaveData.Party.Members) {
            $global:Party = @()
            
            foreach ($memberData in $SaveData.Party.Members) {
                # Create party member as PSCustomObject (matching game format)
                $member = [PSCustomObject]@{
                    Name = $memberData.Name
                    Class = $memberData.Class
                    Level = $memberData.Level
                    Color = $memberData.Color
                    
                    # Stats
                    HP = $memberData.HP
                    MaxHP = $memberData.MaxHP
                    MP = $memberData.MP
                    MaxMP = $memberData.MaxMP
                    Attack = if ($memberData.Attack) { $memberData.Attack } else { 10 }
                    Defense = if ($memberData.Defense) { $memberData.Defense } else { 8 }
                    Speed = if ($memberData.Speed) { $memberData.Speed } else { 6 }
                    XP = $memberData.XP
                    NextLevelXP = if ($memberData.NextLevelXP) { $memberData.NextLevelXP } else { 100 }
                    
                    # Equipment
                    Equipped = if ($memberData.Equipped) { $memberData.Equipped } else { @{} }
                    
                    # Spells and inventory
                    Spells = if ($memberData.Spells) { $memberData.Spells } else { @() }
                    Inventory = if ($memberData.Inventory) { $memberData.Inventory } else { @() }
                    
                    # Position - set to saved location
                    Position = [PSCustomObject]@{
                        X = $SaveData.Location.PlayerX
                        Y = $SaveData.Location.PlayerY
                    }
                    
                    # Class data
                    MapSymbol = if ($memberData.MapSymbol) { $memberData.MapSymbol } else { "@" }
                    ClassData = $memberData.ClassData
                }
                
                $global:Party += $member
                $global:SaveState.Party.Members += $memberData
            }
            
            Write-Host "  Restored $($global:Party.Count) party members" -ForegroundColor Green
            
            # Initialize XP system for proper NextLevelXP calculations
            if (Test-Path "$PSScriptRoot\LevelUpSystem.ps1") {
                . "$PSScriptRoot\LevelUpSystem.ps1"
                Initialize-PartyXP $global:Party
                Write-Host "  Initialized level progression system" -ForegroundColor Green
            }
        }

        # Restore global inventory
        if ($SaveData.Inventory -and $SaveData.Inventory.Items) {
            $global:Inventory = $SaveData.Inventory.Items
            Write-Host "  Restored inventory with $($global:Inventory.Count) item types" -ForegroundColor Green
        }
        
        Write-Host "  Map: $($SaveData.Location.CurrentMap)" -ForegroundColor Green
        Write-Host "  Position: ($($SaveData.Location.PlayerX), $($SaveData.Location.PlayerY))" -ForegroundColor Green
        
        Write-Host "Game state restored successfully!" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "Failed to restore save state: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Error details: $($_.Exception)" -ForegroundColor Gray
        return $false
    }
}# =============================================================================
# HOTKEY AND SETTINGS INTEGRATION
# =============================================================================

function Invoke-QuickSave {
    Save-ManualSave
}

function Invoke-SaveMenu {
    Show-SaveMenu
}

# Export functions for use by other systems
Write-Host "Phase 5.4 Enhanced Save System loaded!" -ForegroundColor Green
Write-Host "  * Save-AutoSave - Automatic single-slot saves" -ForegroundColor Yellow
Write-Host "  * Save-ManualSave - Create new manual save" -ForegroundColor Yellow
Write-Host "  * Show-SaveMenu - Interactive save/load interface" -ForegroundColor Yellow
Write-Host "  * Invoke-QuickSave - Hotkey quick save" -ForegroundColor Yellow
