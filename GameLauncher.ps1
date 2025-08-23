# =============================================================================
# MAIN GAME LAUNCHER - Phase 5.1 Start Screen Integration
# =============================================================================
# Professional game entry point with start screen, main menu, and credits

# Clear console and set up environment
Clear-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║                    ASCII PowerShell JRPG - Phase 5.1                   ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""
Write-Host "* Loading game systems..." -ForegroundColor Yellow

# Import required systems
try {
    . "$PSScriptRoot\StartScreen.ps1"
    
    # Import core game systems (but don't auto-start)
    . "$PSScriptRoot\SaveSystem.ps1"
    . "$PSScriptRoot\Player.ps1" 
    . "$PSScriptRoot\Maps.ps1"
    . "$PSScriptRoot\MapManager.ps1"
    . "$PSScriptRoot\NPCs.ps1"
    . "$PSScriptRoot\PartySystem.ps1"
    
    # Import settings system
    . "$PSScriptRoot\SettingsMenu.ps1"
    
    Write-Host "* Game systems loaded successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Show start screen and main menu
    Show-StartScreen
    
    # Check if user chose to exit
    if ($global:ExitGame) {
        Write-Host ""
        Write-Host "Thank you for playing ASCII PowerShell JRPG!" -ForegroundColor Cyan
        Write-Host "Adventure awaits your return..." -ForegroundColor Gray
    }
}
catch {
    Write-Host "* Error loading game systems: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    [Console]::ReadKey($true) | Out-Null
}

Write-Host ""
