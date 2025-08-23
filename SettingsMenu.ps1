# =============================================================================
# SETTINGS MENU SYSTEM
# =============================================================================
# Comprehensive in-game settings management with persistence
# Accessible via ESC key during gameplay

# Default settings structure
$global:DefaultSettings = @{
    Graphics = @{
        WaterAnimation = $true
        WaterRenderMethod = "ANSI"  # "ANSI" or "CURSOR"
        EnableColorZones = $false   # For future color system
        ViewportWidth = 80
        ViewportHeight = 25
    }
    Audio = @{
        SoundEffects = $true
        Music = $true
        Volume = 50              # 0-100
    }
    Controls = @{
        MovementKeys = "WASD"    # "WASD" or "ARROWS"
        MenuNavigation = "ARROWS" # Always arrows for menus
        ConfirmKey = "ENTER"
        CancelKey = "ESC"
    }
    Gameplay = @{
        AutoSaveFrequency = "BATTLE"  # "NEVER", "BATTLE", "MAP_CHANGE", "FREQUENT"
        BattleDifficulty = "NORMAL"   # "EASY", "NORMAL", "HARD"
        ShowTurnOrder = $true
        ShowDamageNumbers = $true
    }
    System = @{
        SettingsVersion = "1.0"
        LastModified = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
}

# Current settings (loaded from file or defaults)
$global:CurrentSettings = $null

# Settings file path
$global:SettingsFilePath = Join-Path $PSScriptRoot "settings.json"

# =============================================================================
# SETTINGS FILE MANAGEMENT
# =============================================================================

function Load-GameSettings {
    <#
    Load settings from file, create defaults if needed
    #>
    
    if (Test-Path $global:SettingsFilePath) {
        try {
            $loadedSettings = Get-Content $global:SettingsFilePath | ConvertFrom-Json
            
            # Convert PSCustomObject to hashtable with nested hashtables
            $global:CurrentSettings = @{}
            foreach ($category in $loadedSettings.PSObject.Properties) {
                $global:CurrentSettings[$category.Name] = @{}
                foreach ($setting in $category.Value.PSObject.Properties) {
                    $global:CurrentSettings[$category.Name][$setting.Name] = $setting.Value
                }
            }
            
            # Merge with defaults to ensure all settings exist
            Merge-WithDefaults
            
            Write-Host "Settings loaded successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "Error loading settings, using defaults: $($_.Exception.Message)" -ForegroundColor Yellow
            $global:CurrentSettings = $global:DefaultSettings.Clone()
            Save-GameSettings
        }
    }
    else {
        Write-Host "No settings file found, creating defaults..." -ForegroundColor Yellow
        $global:CurrentSettings = $global:DefaultSettings.Clone()
        Save-GameSettings
    }
    
    # Apply loaded settings to game systems
    Apply-GameSettings
}

function Save-GameSettings {
    <#
    Save current settings to file
    #>
    
    try {
        # Update timestamp
        $global:CurrentSettings.System.LastModified = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        
        # Convert to JSON and save
        $global:CurrentSettings | ConvertTo-Json -Depth 3 | Set-Content $global:SettingsFilePath
        Write-Host "Settings saved successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error saving settings: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Merge-WithDefaults {
    <#
    Ensure all default settings exist in current settings
    #>
    
    foreach ($category in $global:DefaultSettings.Keys) {
        if (-not $global:CurrentSettings.ContainsKey($category)) {
            $global:CurrentSettings[$category] = @{}
        }
        
        foreach ($setting in $global:DefaultSettings[$category].Keys) {
            if (-not $global:CurrentSettings[$category].ContainsKey($setting)) {
                $global:CurrentSettings[$category][$setting] = $global:DefaultSettings[$category][$setting]
            }
        }
    }
}

function Apply-GameSettings {
    <#
    Apply current settings to game systems
    #>
    
    # Graphics settings
    $global:EnableWaterAnimation = $global:CurrentSettings.Graphics.WaterAnimation
    $global:WaterRenderMethod = $global:CurrentSettings.Graphics.WaterRenderMethod
    $global:EnableColorZones = $global:CurrentSettings.Graphics.EnableColorZones
    
    # Audio settings (framework for future)
    $global:SoundEffectsEnabled = $global:CurrentSettings.Audio.SoundEffects
    $global:MusicEnabled = $global:CurrentSettings.Audio.Music
    $global:AudioVolume = $global:CurrentSettings.Audio.Volume
    
    # Gameplay settings
    $global:AutoSaveFrequency = $global:CurrentSettings.Gameplay.AutoSaveFrequency
    $global:BattleDifficulty = $global:CurrentSettings.Gameplay.BattleDifficulty
    
    Write-Host "Game settings applied." -ForegroundColor Green
}

function Reset-SettingsToDefaults {
    <#
    Reset all settings to defaults
    #>
    
    $global:CurrentSettings = $global:DefaultSettings.Clone()
    Apply-GameSettings
    Save-GameSettings
    Write-Host "Settings reset to defaults." -ForegroundColor Green
}

# =============================================================================
# SETTINGS MENU INTERFACE
# =============================================================================

function Show-SettingsMenu {
    <#
    Display the main settings menu interface
    #>
    
    $currentCategory = 0
    $categories = @("Graphics", "Audio", "Controls", "Gameplay", "Party", "Save/Load", "System")
    $exitMenu = $false
    
    while (-not $exitMenu) {
        Clear-Host
        Draw-SettingsMenuHeader
        
        # Draw category menu
        Write-Host ""
        Write-Host "Settings Categories:" -ForegroundColor Cyan
        Write-Host ""
        
        for ($i = 0; $i -lt $categories.Count; $i++) {
            $prefix = if ($i -eq $currentCategory) { ">" } else { " " }
            $color = if ($i -eq $currentCategory) { "Yellow" } else { "White" }
            Write-Host "$prefix $($categories[$i])" -ForegroundColor $color
        }
        
        Write-Host ""
        Write-Host "Navigation: Up/Down Select  ENTER Open  ESC Exit  R Reset All" -ForegroundColor DarkGray
        
        # Get input
        $key = [System.Console]::ReadKey($true)
        
        switch ($key.Key) {
            "UpArrow" {
                $currentCategory = ($currentCategory - 1 + $categories.Count) % $categories.Count
            }
            "DownArrow" {
                $currentCategory = ($currentCategory + 1) % $categories.Count
            }
            "Enter" {
                Show-CategorySettings $categories[$currentCategory]
            }
            "R" {
                Show-ResetConfirmation
            }
            "Escape" {
                $exitMenu = $true
            }
        }
    }
}

function Show-CategorySettings {
    param($categoryName)
    <#
    Show settings for a specific category
    #>
    
    # Special handling for Party management
    if ($categoryName -eq "Party") {
        Show-PartyManagementMenu
        return
    }
    
    # Special handling for Save/Load
    if ($categoryName -eq "Save/Load") {
        Show-SaveLoadMenu
        return
    }
    
    $categorySettings = $global:CurrentSettings[$categoryName]
    $settingNames = @($categorySettings.Keys)
    $currentSetting = 0
    $exitCategory = $false
    
    while (-not $exitCategory) {
        Clear-Host
        Draw-SettingsMenuHeader
        
        Write-Host ""
        Write-Host "$categoryName Settings:" -ForegroundColor Cyan
        Write-Host ""
        
        # Draw settings
        for ($i = 0; $i -lt $settingNames.Count; $i++) {
            $settingName = $settingNames[$i]
            $settingValue = $categorySettings[$settingName]
            $prefix = if ($i -eq $currentSetting) { ">" } else { " " }
            $color = if ($i -eq $currentSetting) { "Yellow" } else { "White" }
            
            $displayValue = Format-SettingValue $settingValue
            Write-Host "$prefix $($settingName): $displayValue" -ForegroundColor $color
        }
        
        Write-Host ""
        Write-Host "Navigation: Up/Down Select  Left/Right Change  ESC Back" -ForegroundColor DarkGray
        Write-Host ""
        
        # Show setting description
        if ($currentSetting -lt $settingNames.Count) {
            $description = Get-SettingDescription $categoryName $settingNames[$currentSetting]
            Write-Host $description -ForegroundColor DarkGray
        }
        
        # Get input
        $key = [System.Console]::ReadKey($true)
        
        switch ($key.Key) {
            "UpArrow" {
                $currentSetting = ($currentSetting - 1 + $settingNames.Count) % $settingNames.Count
            }
            "DownArrow" {
                $currentSetting = ($currentSetting + 1) % $settingNames.Count
            }
            "LeftArrow" {
                Change-Setting $categoryName $settingNames[$currentSetting] -1
            }
            "RightArrow" {
                Change-Setting $categoryName $settingNames[$currentSetting] 1
            }
            "Escape" {
                $exitCategory = $true
            }
        }
    }
}

function Draw-SettingsMenuHeader {
    <#
    Draw the settings menu header
    #>
    
    Write-Host "================================================================================" -ForegroundColor Blue
    Write-Host "                          GAME SETTINGS" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Blue
}

function Format-SettingValue {
    param($value)
    <#
    Format a setting value for display
    #>
    
    switch ($value.GetType().Name) {
        "Boolean" { 
            if ($value) { return "ON" } else { return "OFF" }
        }
        "String" { return $value }
        "Int32" { return $value.ToString() }
        default { return $value.ToString() }
    }
}

function Get-SettingDescription {
    param($category, $settingName)
    <#
    Get description text for a setting
    #>
    
    $descriptions = @{
        Graphics = @{
            WaterAnimation = "Enable animated water tiles (may impact performance)"
            WaterRenderMethod = "Rendering method: ANSI (fast) or CURSOR (compatible)"
            EnableColorZones = "Enable colored map zones (future feature)"
            ViewportWidth = "Game viewport width in characters"
            ViewportHeight = "Game viewport height in characters"
        }
        Audio = @{
            SoundEffects = "Enable sound effects during gameplay"
            Music = "Enable background music"
            Volume = "Master volume level (0-100)"
        }
        Controls = @{
            MovementKeys = "Movement controls: WASD or Arrow Keys"
            MenuNavigation = "Menu navigation method"
            ConfirmKey = "Key used to confirm selections"
            CancelKey = "Key used to cancel or go back"
        }
        Gameplay = @{
            AutoSaveFrequency = "When to automatically save game progress"
            BattleDifficulty = "Combat difficulty level"
            ShowTurnOrder = "Display turn order during battles"
            ShowDamageNumbers = "Show damage numbers during combat"
        }
        System = @{
            SettingsVersion = "Settings file format version"
            LastModified = "When settings were last changed"
        }
    }
    
    if ($descriptions.ContainsKey($category) -and $descriptions[$category].ContainsKey($settingName)) {
        return $descriptions[$category][$settingName]
    }
    return "No description available"
}

function Change-Setting {
    param($category, $settingName, $direction)
    <#
    Change a setting value
    #>
    
    $currentValue = $global:CurrentSettings[$category][$settingName]
    $newValue = $currentValue
    
    # Handle different setting types
    switch ($currentValue.GetType().Name) {
        "Boolean" {
            $newValue = -not $currentValue
        }
        "String" {
            $newValue = Cycle-StringSetting $category $settingName $currentValue $direction
        }
        "Int32" {
            $newValue = Change-NumericSetting $category $settingName $currentValue $direction
        }
    }
    
    # Update the setting
    $global:CurrentSettings[$category][$settingName] = $newValue
    
    # Apply and save settings
    Apply-GameSettings
    Save-GameSettings
}

function Cycle-StringSetting {
    param($category, $settingName, $currentValue, $direction)
    <#
    Cycle through string setting options
    #>
    
    $options = @{
        Graphics = @{
            WaterRenderMethod = @("ANSI", "CURSOR")
        }
        Audio = @{}
        Controls = @{
            MovementKeys = @("WASD", "ARROWS")
            MenuNavigation = @("ARROWS")  # Fixed
            ConfirmKey = @("ENTER")       # Fixed
            CancelKey = @("ESC")          # Fixed
        }
        Gameplay = @{
            AutoSaveFrequency = @("NEVER", "BATTLE", "MAP_CHANGE", "FREQUENT")
            BattleDifficulty = @("EASY", "NORMAL", "HARD")
        }
    }
    
    if ($options.ContainsKey($category) -and $options[$category].ContainsKey($settingName)) {
        $settingOptions = $options[$category][$settingName]
        $currentIndex = $settingOptions.IndexOf($currentValue)
        
        if ($currentIndex -ge 0) {
            $newIndex = ($currentIndex + $direction + $settingOptions.Count) % $settingOptions.Count
            return $settingOptions[$newIndex]
        }
    }
    
    return $currentValue
}

function Change-NumericSetting {
    param($category, $settingName, $currentValue, $direction)
    <#
    Change numeric setting with bounds
    #>
    
    $increment = 1
    $min = 0
    $max = 100
    
    # Setting-specific bounds
    switch ("$category.$settingName") {
        "Audio.Volume" { $increment = 5; $min = 0; $max = 100 }
        "Graphics.ViewportWidth" { $increment = 10; $min = 40; $max = 200 }
        "Graphics.ViewportHeight" { $increment = 5; $min = 20; $max = 50 }
        default { $increment = 1; $min = 0; $max = 100 }
    }
    
    $newValue = $currentValue + ($direction * $increment)
    return [Math]::Max($min, [Math]::Min($max, $newValue))
}

function Show-ResetConfirmation {
    <#
    Show confirmation dialog for resetting settings
    #>
    
    Clear-Host
    Draw-SettingsMenuHeader
    
    Write-Host ""
    Write-Host "Reset all settings to defaults?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This will:" -ForegroundColor White
    Write-Host "* Reset all graphics, audio, and gameplay settings" -ForegroundColor White
    Write-Host "* Cannot be undone" -ForegroundColor White
    Write-Host ""
    Write-Host "Y: Yes, reset all settings" -ForegroundColor Red
    Write-Host "N: No, keep current settings" -ForegroundColor Green
    
    do {
        $key = [System.Console]::ReadKey($true)
        switch ($key.KeyChar.ToString().ToUpper()) {
            "Y" {
                Reset-SettingsToDefaults
                Write-Host ""
                Write-Host "Settings have been reset to defaults." -ForegroundColor Green
                Write-Host "Press any key to continue..." -ForegroundColor DarkGray
                [System.Console]::ReadKey($true) | Out-Null
                return
            }
            "N" {
                return
            }
        }
    } while ($true)
}

# =============================================================================
# PARTY MANAGEMENT SYSTEM
# =============================================================================

function Show-PartyManagementMenu {
    <#
    Party management interface for reordering party members
    #>
    
    if (-not $global:Party -or $global:Party.Count -eq 0) {
        Clear-Host
        Draw-SettingsMenuHeader
        Write-Host ""
        Write-Host "No party found! Party management is only available during active gameplay." -ForegroundColor Red
        Write-Host ""
        Write-Host "Press any key to return to settings..." -ForegroundColor DarkGray
        [System.Console]::ReadKey($true) | Out-Null
        return
    }
    
    $currentSelection = 0
    $exitMenu = $false
    $partyBackup = @()
    
    # Create backup of party order
    foreach ($member in $global:Party) {
        $partyBackup += $member.PSObject.Copy()
    }
    
    while (-not $exitMenu) {
        Clear-Host
        Draw-SettingsMenuHeader
        
        Write-Host ""
        Write-Host "Party Management - Reorganize Party Order" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Current party formation (leader first):" -ForegroundColor Yellow
        Write-Host ""
        
        # Display current party order
        for ($i = 0; $i -lt $global:Party.Count; $i++) {
            $member = $global:Party[$i]
            $prefix = if ($i -eq $currentSelection) { ">" } else { " " }
            $color = if ($i -eq $currentSelection) { "Yellow" } else { "White" }
            $leaderText = if ($i -eq 0) { " (LEADER)" } else { "" }
            $colorText = if ($member.Color) { " [$($member.Color)]" } else { "" }
            
            Write-Host "$prefix $($i + 1). $($member.Name) - $($member.Class) [$($member.MapSymbol)]$colorText$leaderText" -ForegroundColor $color
        }
        
        Write-Host ""
        Write-Host "Formation will be: $($global:PartyFormation -join ' -> ')" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Controls:" -ForegroundColor DarkGray
        Write-Host "  Up/Down: Select member" -ForegroundColor DarkGray
        Write-Host "  Left/Right: Move member up/down in order" -ForegroundColor DarkGray
        Write-Host "  R: Reset to original order" -ForegroundColor DarkGray
        Write-Host "  ENTER: Apply changes and exit" -ForegroundColor DarkGray
        Write-Host "  ESC: Cancel and exit" -ForegroundColor DarkGray
        
        # Get input
        $key = [System.Console]::ReadKey($true)
        
        switch ($key.Key) {
            "UpArrow" {
                $currentSelection = ($currentSelection - 1 + $global:Party.Count) % $global:Party.Count
            }
            "DownArrow" {
                $currentSelection = ($currentSelection + 1) % $global:Party.Count
            }
            "LeftArrow" {
                # Move selected member up in order (lower index)
                if ($currentSelection -gt 0) {
                    $temp = $global:Party[$currentSelection]
                    $global:Party[$currentSelection] = $global:Party[$currentSelection - 1]
                    $global:Party[$currentSelection - 1] = $temp
                    
                    # Update positions and trail
                    Update-PartyPositionsAfterReorder
                    $currentSelection--
                }
            }
            "RightArrow" {
                # Move selected member down in order (higher index)
                if ($currentSelection -lt $global:Party.Count - 1) {
                    $temp = $global:Party[$currentSelection]
                    $global:Party[$currentSelection] = $global:Party[$currentSelection + 1]
                    $global:Party[$currentSelection + 1] = $temp
                    
                    # Update positions and trail
                    Update-PartyPositionsAfterReorder
                    $currentSelection++
                }
            }
            "R" {
                # Reset to original order
                $global:Party = @()
                foreach ($member in $partyBackup) {
                    $global:Party += $member.PSObject.Copy()
                }
                Update-PartyPositionsAfterReorder
                Write-Host "Party order reset!" -ForegroundColor Green
                Start-Sleep -Milliseconds 800
            }
            "Enter" {
                # Apply changes and exit
                Update-PartyPositionsAfterReorder
                Write-Host "Party reorganized successfully!" -ForegroundColor Green
                Write-Host "New formation: $($global:PartyFormation -join ' -> ')" -ForegroundColor Cyan
                Start-Sleep -Milliseconds 1500
                $exitMenu = $true
            }
            "Escape" {
                # Cancel changes and restore backup
                $global:Party = @()
                foreach ($member in $partyBackup) {
                    $global:Party += $member.PSObject.Copy()
                }
                Update-PartyPositionsAfterReorder
                $exitMenu = $true
            }
        }
    }
}

function Update-PartyPositionsAfterReorder {
    <#
    Update party positions and formation after reordering
    #>
    
    # Update player object to new leader
    if ($global:Party.Count -gt 0) {
        $leader = $global:Party[0]
        $global:Player.Name = $leader.Name
        $global:Player.Class = $leader.Class
        $global:Player.HP = $leader.HP
        $global:Player.MaxHP = $leader.MaxHP
        $global:Player.Attack = $leader.Attack
        $global:Player.Defense = $leader.Defense
        $global:Player.Speed = $leader.Speed
        $global:Player.MP = $leader.MP
        $global:Player.MaxMP = $leader.MaxMP
        $global:Player.Spells = $leader.Spells
        $global:Player.Equipped = $leader.Equipped
        $global:Player.ClassData = $leader.ClassData
    }
    
    # Update party formation display
    $global:PartyFormation = @()
    for ($i = 0; $i -lt $global:Party.Count; $i++) {
        $symbol = if ($i -eq 0) { "@" } else { $global:Party[$i].MapSymbol }
        $global:PartyFormation += $symbol
    }
    
    # Update party positions (preserve current leader position)
    if ($global:Player -and $global:Player.Position) {
        $leaderX = $global:Player.Position.X
        $leaderY = $global:Player.Position.Y
        
        # Reinitialize trail with current position
        $global:PartyTrail = @()
        for ($i = 0; $i -lt $global:Party.Count * 2; $i++) {
            $global:PartyTrail += @{ X = $leaderX - $i; Y = $leaderY }
        }
        
        # Position party members using trail
        for ($i = 0; $i -lt $global:Party.Count; $i++) {
            $member = $global:Party[$i]
            if ($i -eq 0) {
                # Leader stays at current position
                $member.Position = @{ X = $leaderX; Y = $leaderY }
            } else {
                # Other members follow trail
                $trailIndex = [math]::Min($i * 2, $global:PartyTrail.Count - 1)
                $trailPos = $global:PartyTrail[$trailIndex]
                $member.Position = @{ X = $trailPos.X; Y = $trailPos.Y }
            }
        }
    }
}

# =============================================================================
# SAVE/LOAD MENU INTEGRATION
# =============================================================================

function Show-SaveLoadMenu {
    <#
    Integrated save/load menu for the settings system
    #>
    
    # Load the enhanced save system if not already loaded
    if (-not (Get-Command "Show-SaveMenu" -ErrorAction SilentlyContinue)) {
        if (Test-Path "$PSScriptRoot\EnhancedSaveSystem.ps1") {
            . "$PSScriptRoot\EnhancedSaveSystem.ps1"
        } else {
            Write-Host "Enhanced Save System not found!" -ForegroundColor Red
            Write-Host "Press any key to return..." -ForegroundColor Gray
            [Console]::ReadKey($true) | Out-Null
            return
        }
    }
    
    # Call the enhanced save menu
    Show-SaveMenu
}

# =============================================================================
# INITIALIZATION
# =============================================================================

# Load settings on module import
if (-not $global:CurrentSettings) {
    Load-GameSettings
}

Write-Host "Settings Menu System loaded successfully!" -ForegroundColor Green
