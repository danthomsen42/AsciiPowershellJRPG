# =============================================================================
# SETTINGS MENU STANDALONE TEST
# =============================================================================
# Test the Settings Menu system independently

Clear-Host

Write-Host "Settings Menu System Standalone Test" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Blue
Write-Host ""

# Import just the settings system
. "$PSScriptRoot\SettingsMenu.ps1"

Write-Host "Current Settings Status:" -ForegroundColor Yellow
Write-Host "* Settings file: $global:SettingsFilePath" -ForegroundColor White
Write-Host "* Water Animation: $($global:CurrentSettings.Graphics.WaterAnimation)" -ForegroundColor White
Write-Host "* Water Render Method: $($global:CurrentSettings.Graphics.WaterRenderMethod)" -ForegroundColor White
Write-Host "* Movement Keys: $($global:CurrentSettings.Controls.MovementKeys)" -ForegroundColor White
Write-Host "* Auto-save Frequency: $($global:CurrentSettings.Gameplay.AutoSaveFrequency)" -ForegroundColor White
Write-Host ""

Write-Host "Press ENTER to open Settings Menu, or any other key to exit..." -ForegroundColor Green
$key = [System.Console]::ReadKey($true)

if ($key.Key -eq "Enter") {
    Show-SettingsMenu
    
    Write-Host ""
    Write-Host "Settings menu closed. Final settings:" -ForegroundColor Yellow
    Write-Host "* Water Animation: $($global:CurrentSettings.Graphics.WaterAnimation)" -ForegroundColor White
    Write-Host "* Water Render Method: $($global:CurrentSettings.Graphics.WaterRenderMethod)" -ForegroundColor White
    Write-Host "* Movement Keys: $($global:CurrentSettings.Controls.MovementKeys)" -ForegroundColor White
    Write-Host "* Auto-save Frequency: $($global:CurrentSettings.Gameplay.AutoSaveFrequency)" -ForegroundColor White
}

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Green
