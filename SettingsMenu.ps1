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
    $categories = @("Graphics", "Audio", "Controls", "Gameplay", "System")
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
# INITIALIZATION
# =============================================================================

# Load settings on module import
if (-not $global:CurrentSettings) {
    Load-GameSettings
}

Write-Host "Settings Menu System loaded successfully!" -ForegroundColor Green
