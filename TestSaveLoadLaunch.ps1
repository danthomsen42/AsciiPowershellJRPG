# Test Save/Load Game Launch
Write-Host "=== SAVE/LOAD GAME LAUNCH TEST ===" -ForegroundColor Yellow

# Create a test save first
Write-Host "Setting up test environment..." -ForegroundColor Cyan
. "$PSScriptRoot\MapManager.ps1"
. "$PSScriptRoot\EnhancedSaveSystem.ps1"

# Set up test game state
$global:CurrentMapName = "Town"
$global:PlayerCurrentX = 30
$global:PlayerCurrentY = 15

Write-Host "Creating test save..." -ForegroundColor Yellow
$testSave = Save-ManualSave
if ($testSave.Success) {
    Write-Host "✅ Test save created: $($testSave.Message)" -ForegroundColor Green
    
    # Clear the current state
    Write-Host "Clearing current game state..." -ForegroundColor Yellow
    $global:CurrentMapName = $null
    $global:PlayerCurrentX = $null
    $global:PlayerCurrentY = $null
    $global:PlayerStartX = $null
    $global:PlayerStartY = $null
    
    Write-Host "Current state after clearing:" -ForegroundColor Cyan
    Write-Host "- CurrentMapName: '$global:CurrentMapName'"
    Write-Host "- PlayerCurrentX: '$global:PlayerCurrentX'"
    Write-Host "- PlayerCurrentY: '$global:PlayerCurrentY'"
    
    Write-Host "`nTesting load system..." -ForegroundColor Yellow
    Write-Host "Note: This should restore game state and launch Display.ps1" -ForegroundColor Cyan
    Write-Host "When the game starts, press Q to quit and return here." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to test loading the save..." -ForegroundColor White
    [Console]::ReadKey($true) | Out-Null
    
    # Test the save menu (this should launch the game)
    Show-SaveMenu
    
    Write-Host "`nBack from save system!" -ForegroundColor Green
    Write-Host "If the game launched successfully, the load system is working!" -ForegroundColor Yellow
    
} else {
    Write-Host "❌ Failed to create test save: $($testSave.Message)" -ForegroundColor Red
}

Write-Host "`n=== TEST COMPLETE ===" -ForegroundColor Yellow
