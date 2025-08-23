# =============================================================================
# SIMPLE SETTINGS MENU TEST
# =============================================================================

$global:TestSettings = @{
    Graphics = @{
        WaterAnimation = $true
        WaterRenderMethod = "ANSI"
    }
    Audio = @{
        Volume = 50
    }
}

function Show-SimpleSettingsMenu {
    Write-Host "Simple Settings Menu Test" -ForegroundColor Cyan
    Write-Host "Water Animation: $($global:TestSettings.Graphics.WaterAnimation)"
    Write-Host "Volume: $($global:TestSettings.Audio.Volume)"
}

Write-Host "Simple Settings Menu System loaded!" -ForegroundColor Green
