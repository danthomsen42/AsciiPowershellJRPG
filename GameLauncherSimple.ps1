# =============================================================================
# SIMPLE GAME LAUNCHER WITH START SCREEN
# =============================================================================
# Phase 5.1 - Professional game entry point

Clear-Host

Write-Host "================================================================================" -ForegroundColor Blue
Write-Host "                    ASCII PowerShell JRPG - Phase 5.1                         " -ForegroundColor Blue
Write-Host "================================================================================" -ForegroundColor Blue
Write-Host ""

# Simple ASCII title
$titleArt = @"
================================================================================
                     ASCII POWERSHELL JRPG ADVENTURE
================================================================================
                    A Classic JRPG Experience in PowerShell
                           ~ Phase 5.1 Release ~
================================================================================
"@

function Show-MainMenu {
    $menuItems = @("New Game", "Load Game", "Settings", "Credits", "Exit")
    $currentSelection = 0
    $exitMenu = $false
    
    while (-not $exitMenu) {
        Clear-Host
        
        # Show title
        Write-Host $titleArt -ForegroundColor Cyan
        Write-Host ""
        Write-Host "* Developed by Daniel Thomsen * PowerShell JRPG Adventure * 2025 *" -ForegroundColor DarkCyan
        Write-Host ""
        
        # Show menu
        Write-Host "                             MAIN MENU" -ForegroundColor Yellow
        Write-Host "                           =============" -ForegroundColor DarkYellow
        Write-Host ""
        
        for ($i = 0; $i -lt $menuItems.Count; $i++) {
            $prefix = if ($i -eq $currentSelection) { "  > " } else { "    " }
            $color = if ($i -eq $currentSelection) { "White" } else { "Gray" }
            $style = if ($i -eq $currentSelection) { "[$($menuItems[$i])]" } else { " $($menuItems[$i]) " }
            
            Write-Host ("                        {0}{1}" -f $prefix, $style) -ForegroundColor $color
        }
        
        Write-Host ""
        Write-Host "                    Use Up/Down to navigate, ENTER to select" -ForegroundColor DarkGray
        
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
                        Write-Host ""
                        Write-Host "Starting Character Creation..." -ForegroundColor Green
                        Start-Sleep -Milliseconds 1000
                        
                        # Start character creation
                        $newParty = Start-CharacterCreation
                        if ($newParty) {
                            # Initialize party BEFORE loading Display.ps1
                            Initialize-PartyFromCreation -CreatedParty $newParty
                            
                            Write-Host ""
                            Write-Host "Loading game world..." -ForegroundColor Green
                            Start-Sleep -Milliseconds 1000
                            
                            # Now load the game (this will use the initialized party data)
                            . "$PSScriptRoot\Display.ps1"
                            $exitMenu = $true
                        }
                    }
                    1 { # Load Game
                        Write-Host ""
                        Write-Host "Load game feature coming soon..." -ForegroundColor Yellow
                        Start-Sleep -Milliseconds 1500
                    }
                    2 { # Settings
                        . "$PSScriptRoot\SettingsMenu.ps1"
                        Show-SettingsMenu
                    }
                    3 { # Credits
                        Show-Credits
                    }
                    4 { # Exit
                        $exitMenu = $true
                    }
                }
            }
            "Escape" {
                $exitMenu = $true
            }
        }
    }
}

function Show-Credits {
    Clear-Host
    Write-Host $titleArt -ForegroundColor Cyan
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Magenta
    Write-Host "                                CREDITS" -ForegroundColor Magenta
    Write-Host "================================================================================" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Host "  GAME DEVELOPER:" -ForegroundColor Yellow
    Write-Host "     Daniel Thomsen (@danthomsen42)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "  TECHNOLOGY:" -ForegroundColor Yellow
    Write-Host "     Framework: PowerShell 5.1+" -ForegroundColor White
    Write-Host "     Repository: github.com/danthomsen42/AsciiPowershellJRPG" -ForegroundColor White
    Write-Host "     Version: Phase 5.1" -ForegroundColor White
    Write-Host ""
    
    Write-Host "  SPECIAL THANKS:" -ForegroundColor Yellow
    Write-Host "     * ASCII Art Community" -ForegroundColor White
    Write-Host "     * PowerShell Community" -ForegroundColor White
    Write-Host "     * Classic JRPG Inspiration: Final Fantasy, Dragon Quest" -ForegroundColor White
    Write-Host "     * GitHub Copilot for development assistance" -ForegroundColor White
    Write-Host ""
    
    Write-Host "  FEATURES IMPLEMENTED:" -ForegroundColor Yellow
    Write-Host "     * Map-aware NPC system with story progression" -ForegroundColor Green
    Write-Host "     * Enhanced battle system with party management" -ForegroundColor Green
    Write-Host "     * Procedural dungeon generation" -ForegroundColor Green
    Write-Host "     * Comprehensive settings menu system" -ForegroundColor Green
    Write-Host "     * Professional start screen with navigation" -ForegroundColor Green
    Write-Host "     * Final Fantasy 1 style character creation" -ForegroundColor Green
    Write-Host "     * Four-class party system (Warrior/Mage/Healer/Rogue)" -ForegroundColor Green
    Write-Host "     * Persistent save/load system" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "  THANK YOU FOR PLAYING!" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Gray
    [Console]::ReadKey($true) | Out-Null
}

# Load required systems
try {
    . "$PSScriptRoot\SettingsMenu.ps1"
    . "$PSScriptRoot\CharacterCreation.ps1"
    Write-Host "* Game systems loaded successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Show main menu
    Show-MainMenu
}
catch {
    Write-Host "* Error loading game systems: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    [Console]::ReadKey($true) | Out-Null
}

Write-Host "Thank you for playing ASCII PowerShell JRPG!" -ForegroundColor Cyan
