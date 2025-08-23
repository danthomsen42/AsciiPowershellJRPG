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
                            Show-LoadGameMenu
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
    
    for ($i = 0; $i -lt [Math]::Min($saveFiles.Count, 5); $i++) {
        $saveFile = $saveFiles[$i]
        $saveInfo = Get-SaveFilePreview $saveFile.FullName
        
        Write-Host "  [$($i + 1)] $($saveFile.BaseName)" -ForegroundColor White
        Write-Host "      Time: $($saveFile.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
        Write-Host "      Location: $($saveInfo.Location)" -ForegroundColor Gray
        Write-Host "      Level $($saveInfo.Level) - $($saveInfo.HP)/$($saveInfo.MaxHP) HP" -ForegroundColor Gray
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
            Load-SaveFile $selectedSave.FullName
            Start-MainGame
            return
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
    Get preview information from save file
    #>
    
    try {
        $saveData = Get-Content $saveFilePath | ConvertFrom-Json
        return @{
            Location = $saveData.CurrentMapName
            Level = $saveData.Player.Level
            HP = $saveData.Player.HP
            MaxHP = $saveData.Player.MaxHP
        }
    }
    catch {
        return @{
            Location = "Unknown"
            Level = "?"
            HP = "?"
            MaxHP = "?"
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
    Load specific save file
    #>
    
    Write-Host ""
    Write-Host "  Loading save file..." -ForegroundColor Green
    
    # This will integrate with existing save system
    try {
        # Load the save file using existing save system
        . "$PSScriptRoot\SaveSystem.ps1"
        Load-GameState -SaveFilePath $saveFilePath
        
        Write-Host "  ✅ Save file loaded successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "  ❌ Error loading save file: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Press any key to continue..." -ForegroundColor Gray
        [Console]::ReadKey($true) | Out-Null
    }
}

# =============================================================================
# MODULE INITIALIZATION
# =============================================================================

# Global exit flag
$global:ExitGame = $false

Write-Host "Start Screen and Main Menu System loaded!" -ForegroundColor Green
