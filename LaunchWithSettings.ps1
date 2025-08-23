# =============================================================================
# SETTINGS MENU DEMONSTRATION & TEST SCRIPT
# =============================================================================
# Launch script that shows off the new Settings Menu system

Clear-Host

Write-Host "================================================================================" -ForegroundColor Blue
Write-Host "           ASCII PowerShell JRPG - Settings Menu System Demo" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "New Features:" -ForegroundColor Yellow
Write-Host "* Press ESC during gameplay to access settings menu" -ForegroundColor White
Write-Host "* Configure graphics, audio, controls, and gameplay options" -ForegroundColor White
Write-Host "* Settings automatically saved to settings.json" -ForegroundColor White
Write-Host "* Real-time application of most settings" -ForegroundColor White
Write-Host ""
Write-Host "Available Settings Categories:" -ForegroundColor Yellow
Write-Host "* Graphics: Water animation, render method, viewport size" -ForegroundColor White
Write-Host "* Audio: Sound effects, music, volume (framework ready)" -ForegroundColor White
Write-Host "* Controls: Movement keys (WASD/Arrows), menu navigation" -ForegroundColor White
Write-Host "* Gameplay: Auto-save frequency, difficulty, battle display" -ForegroundColor White
Write-Host ""
Write-Host "Settings Menu Navigation:" -ForegroundColor Yellow
Write-Host "* Arrow Keys: Navigate options" -ForegroundColor White
Write-Host "* ENTER: Open category or confirm changes" -ForegroundColor White
Write-Host "* Left/Right Arrows: Change setting values" -ForegroundColor White
Write-Host "* ESC: Go back or exit settings" -ForegroundColor White
Write-Host "* R: Reset all settings to defaults" -ForegroundColor White
Write-Host ""

Write-Host "Press any key to launch the game..." -ForegroundColor Green
[System.Console]::ReadKey($true) | Out-Null

# Import all required systems
. "$PSScriptRoot\Display.ps1"
