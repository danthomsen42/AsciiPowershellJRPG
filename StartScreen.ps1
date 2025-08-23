# =============================================================================
# START SCREEN & MAIN MENU SYSTEM - WORKING VERSION
# =============================================================================
# Professional game presentation with ASCII art, menu navigation, and credits
# Phase 5.1 Implementation

# Simple ASCII title
$global:GameTitleArt = @"
================================================================================
                     ASCII POWERSHELL JRPG ADVENTURE
================================================================================
                    A Classic JRPG Experience in PowerShell
                           ~ Phase 5.1 Release ~
================================================================================
"@

# Credits information
$global:GameCredits = @{
    Title = "ASCII POWERSHELL JRPG"
    Developer = "Daniel Thomsen (@danthomsen42)"
    Framework = "PowerShell 5.1+"
    Repository = "github.com/danthomsen42/AsciiPowershellJRPG"
    Version = "Phase 5.1"
    SpecialThanks = @(
        "ASCII Art Community",
        "PowerShell Community",
        "Classic JRPG Inspiration: Final Fantasy, Dragon Quest",
        "GitHub Copilot for development assistance"
    )
    Year = "2025"
}

# =============================================================================
# MAIN MENU SYSTEM
# =============================================================================

function Show-StartScreen {
    <#
    Main start screen with menu navigation
    #>
    
    $menuItems = @("New Game", "Load Game", "Settings", "Credits", "Exit")
    $currentSelection = 0
    $exitStartScreen = $false
    
    # Hide cursor during menu display
    [Console]::CursorVisible = $false
    
    try {
        while (-not $exitStartScreen) {
            Clear-Host
            
            # Draw title
            Write-Host $global:GameTitleArt -ForegroundColor Cyan
            Write-Host ""
            
            # Draw scrolling credits ticker
            Write-Host "* Developed by $($global:GameCredits.Developer) * PowerShell JRPG Adventure * $($global:GameCredits.Year) *" -ForegroundColor DarkCyan
            Write-Host ""
            
            # Draw main menu
            Write-Host "                             MAIN MENU" -ForegroundColor Yellow
            Write-Host "                           =============" -ForegroundColor DarkYellow
            Write-Host ""
            
            for ($i = 0; $i -lt $menuItems.Count; $i++) {
                $prefix = if ($i -eq $currentSelection) { "  > " } else { "    " }
                $color = if ($i -eq $currentSelection) { "White" } else { "Gray" }
                $style = if ($i -eq $currentSelection) { "[{0}]" -f $menuItems[$i] } else { " {0} " -f $menuItems[$i] }
                
                Write-Host ("                        {0}{1}" -f $prefix, $style) -ForegroundColor $color
            }
            
            Write-Host ""
            Write-Host "                    Use Up/Down to navigate, ENTER to select" -ForegroundColor DarkGray
            Write-Host ""
            
            # Get input
            $key = [Console]::ReadKey($true)
            
            switch ($key.Key) {
                "UpArrow" {
                    $currentSelection = ($currentSelection - 1 + $menuItems.Count) % $menuItems.Count
                }
                "DownArrow" {
                    $currentSelection = ($currentSelection + 1) % $menuItems.Count
                }
                "Enter" {
                    switch ($currentSelection) {
                        0 { # New Game
                            Start-NewGame
                            $exitStartScreen = $true
                        }
                        1 { # Load Game
                            $gameLoaded = Show-LoadGameMenu
                            if ($gameLoaded) {
                                $exitStartScreen = $true
                            }
                        }
                        2 { # Settings
                            Show-SettingsMenu
                        }
                        3 { # Credits
                            Show-CreditsScreen
                        }
                        4 { # Exit
                            $exitStartScreen = $true
                            $global:ExitGame = $true
                        }
                    }
                }
                "Escape" {
                    $currentSelection = 4  # Highlight Exit
                }
            }
        }
    }
    finally {
        # Restore cursor visibility
        [Console]::CursorVisible = $true
    }
}

# =============================================================================
# MENU ACTIONS
# =============================================================================

function Start-NewGame {
    <#
    Initialize new game state and launch main game
    #>
    
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                              NEW ADVENTURE                               ║" -ForegroundColor Green  
    Write-Host "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  * Starting your epic PowerShell JRPG adventure..." -ForegroundColor Yellow
    Write-Host "  * Preparing the world for your arrival..." -ForegroundColor Yellow
    Write-Host "  * Loading game systems..." -ForegroundColor Yellow
    Write-Host ""
    
    # Initialize fresh game state
    Initialize-NewGameState
    
    Write-Host "  * Ready! Your adventure begins now..." -ForegroundColor Green
    Write-Host ""
    Write-Host "Press any key to enter the world..." -ForegroundColor Gray
    [Console]::ReadKey($true) | Out-Null
    
    # Launch main game
    Start-MainGame
}

function Show-LoadGameMenu {
    <#
    Display available save files for loading
    #>
    
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║                              LOAD GAME                                  ║" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
    
    # Check for existing save files
    $saveFiles = @()
    $savesFolder = Join-Path $PSScriptRoot "saves"
    
    if (Test-Path $savesFolder) {
        $saveFiles = Get-ChildItem $savesFolder -Filter "*.json" | Sort-Object LastWriteTime -Descending
    }
    
    if ($saveFiles.Count -eq 0) {
        Write-Host "  No saved games found." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Start a New Game to begin your adventure!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Press any key to return to main menu..." -ForegroundColor Gray
        [Console]::ReadKey($true) | Out-Null
        return
    }
    
    # Display save files with preview
    Write-Host "  Available Save Games:" -ForegroundColor Yellow
    Write-Host "  ═══════════════════════" -ForegroundColor DarkYellow
    Write-Host ""
    
    for ($i = 0; $i -lt [Math]::Min($saveFiles.Count, 10); $i++) {
        $saveFile = $saveFiles[$i]
        $saveInfo = Get-SaveFilePreview $saveFile.FullName
        
        Write-Host "  [$($i + 1)] $($saveFile.BaseName)" -ForegroundColor White
        Write-Host "      Created: $($saveFile.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
        Write-Host "      Location: $($saveInfo.Location) | Party: $($saveInfo.PartySize) members" -ForegroundColor Gray
        Write-Host "      Leader: Level $($saveInfo.Level) - $($saveInfo.HP)/$($saveInfo.MaxHP) HP" -ForegroundColor Gray
        if ($saveInfo.SaveType -ne "unknown") {
            Write-Host "      Type: $($saveInfo.SaveType) | Play Time: $([math]::Round($saveInfo.PlayTime, 1)) minutes" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    Write-Host "Enter save number (1-$($saveFiles.Count)) or ESC to return: " -ForegroundColor Yellow -NoNewline
    
    do {
        $key = [Console]::ReadKey($true)
        $choice = $key.KeyChar.ToString()
        
        if ($key.Key -eq "Escape") {
            return
        }
        
        if ($choice -match '^[1-9]$' -and [int]$choice -le $saveFiles.Count) {
            $selectedSave = $saveFiles[[int]$choice - 1]
            $loadSuccess = Load-SaveFile $selectedSave.FullName
            if ($loadSuccess) {
                # Successfully loaded - start the main game
                Start-MainGame
                return $true  # Signal that we loaded successfully
            }
            # If load failed, return to load menu
        }
    } while ($true)
}

function Show-CreditsScreen {
    <#
    Display full credits screen
    #>
    
    Clear-Host
    Write-Host $global:SimpleTitleArt -ForegroundColor Cyan
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                                CREDITS                                  ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Host "  GAME DEVELOPER:" -ForegroundColor Yellow
    Write-Host "     $($global:GameCredits.Developer)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "  TECHNOLOGY:" -ForegroundColor Yellow
    Write-Host "     Framework: $($global:GameCredits.Framework)" -ForegroundColor White
    Write-Host "     Repository: $($global:GameCredits.Repository)" -ForegroundColor White
    Write-Host "     Version: $($global:GameCredits.Version)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "  SPECIAL THANKS:" -ForegroundColor Yellow
    foreach ($thanks in $global:GameCredits.SpecialThanks) {
        Write-Host "     * $thanks" -ForegroundColor White
    }
    Write-Host ""
    
    Write-Host "  FEATURES IMPLEMENTED:" -ForegroundColor Yellow
    Write-Host "     * Map-aware NPC system with story progression" -ForegroundColor Green
    Write-Host "     * Enhanced battle system with party management" -ForegroundColor Green
    Write-Host "     * Procedural dungeon generation" -ForegroundColor Green
    Write-Host "     * Comprehensive settings menu system" -ForegroundColor Green
    Write-Host "     * Professional start screen with navigation" -ForegroundColor Green
    Write-Host "     * Persistent save/load system" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "  THANK YOU FOR PLAYING!" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Gray
    [Console]::ReadKey($true) | Out-Null
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

function Get-SaveFilePreview {
    param($saveFilePath)
    <#
    Get preview information from enhanced save file
    #>
    
    try {
        $saveData = Get-Content $saveFilePath -Raw | ConvertFrom-Json
        
        # Extract info from enhanced save structure
        $location = if ($saveData.Location.CurrentMap) { $saveData.Location.CurrentMap } else { "Unknown" }
        
        # Get first party member info (leader)
        if ($saveData.Party.Members -and $saveData.Party.Members.Count -gt 0) {
            $leader = $saveData.Party.Members[0]
            return @{
                Location = $location
                Level = $leader.Level
                HP = $leader.HP
                MaxHP = $leader.MaxHP
                PartySize = $saveData.Party.Members.Count
                SaveType = $saveData.GameInfo.SaveType
                PlayTime = $saveData.GameInfo.PlayTime
            }
        } else {
            # Fallback for saves without party data
            return @{
                Location = $location
                Level = "?"
                HP = "?"
                MaxHP = "?"
                PartySize = 0
                SaveType = "unknown"
                PlayTime = 0
            }
        }
    }
    catch {
        return @{
            Location = "Unknown"
            Level = "?"
            HP = "?"
            MaxHP = "?"
            PartySize = 0
            SaveType = "corrupted"
            PlayTime = 0
        }
    }
}
    }
}

function Initialize-NewGameState {
    <#
    Set up fresh game state for new adventure
    #>
    
    # This will integrate with existing save system
    # Reset any global game state variables
    $global:CurrentMapName = "Town"
    
    # Clear any existing save state for new game
    if (Get-Variable -Name "SaveState" -ErrorAction SilentlyContinue) {
        Remove-Variable -Name "SaveState" -Scope Global -ErrorAction SilentlyContinue
    }
}

function Start-MainGame {
    <#
    Launch the main game loop
    #>
    
    # Import and launch the main game system
    . "$PSScriptRoot\Display.ps1"
}

function Load-SaveFile {
    param($saveFilePath)
    <#
    Load specific save file using enhanced save system
    #>
    
    Write-Host ""
    Write-Host "  Loading save file..." -ForegroundColor Green
    
    try {
        # Load the enhanced save system if not already loaded
        if (-not (Get-Command Restore-SaveState -ErrorAction SilentlyContinue)) {
            . "$PSScriptRoot\EnhancedSaveSystem.ps1"
        }
        
        # Load and parse the save file
        $saveData = Get-Content -Path $saveFilePath -Raw | ConvertFrom-Json
        
        # Show preview and confirm load
        Show-SavePreview $saveData ([System.IO.Path]::GetFileNameWithoutExtension($saveFilePath))
        Write-Host ""
        Write-Host "Load this save? (Y/N): " -NoNewline -ForegroundColor Yellow
        $key = [Console]::ReadKey($true)
        Write-Host ""
        
        if ($key.Key -eq 'Y') {
            # Restore the game state
            Restore-SaveState $saveData
            Write-Host "  ✅ Save file loaded successfully!" -ForegroundColor Green
            Start-Sleep -Milliseconds 1000
            return $true
        } else {
            Write-Host "  Load cancelled." -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "  ❌ Error loading save file: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Press any key to continue..." -ForegroundColor Gray
        [Console]::ReadKey($true) | Out-Null
        return $false
    }
}

function Show-CreditsScreen {
    <#
    Display full credits screen
    #>
    
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                                CREDITS                                  ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  ASCII PowerShell JRPG" -ForegroundColor Yellow
    Write-Host "  A text-based RPG adventure built in PowerShell" -ForegroundColor White
    Write-Host ""
    Write-Host "  Developer: Game Development Team" -ForegroundColor Yellow
    Write-Host "  Year: 2025" -ForegroundColor White
    Write-Host ""
    Write-Host "  Special thanks to the PowerShell community!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Gray
    [Console]::ReadKey($true) | Out-Null
}

function Initialize-NewGameState {
    <#
    Set up fresh game state for new adventure
    #>
    
    # This will integrate with existing save system
    # Reset any global game state variables
    $global:CurrentMapName = "Town"
    
    # Clear any existing save state for new game
    if (Get-Variable -Name "SaveState" -ErrorAction SilentlyContinue) {
        Remove-Variable -Name "SaveState" -Scope Global -ErrorAction SilentlyContinue
    }
}

function Start-MainGame {
    <#
    Launch the main game loop
    #>
    
    # Import and launch the main game system
    . "$PSScriptRoot\Display.ps1"
}

# =============================================================================
# MODULE INITIALIZATION
# =============================================================================

# Global exit flag
$global:ExitGame = $false

Write-Host "Start Screen and Main Menu System loaded!" -ForegroundColor Green
