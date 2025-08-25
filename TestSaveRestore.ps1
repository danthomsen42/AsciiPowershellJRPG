# Test Save/Load State Restoration
# This script tests the complete save/load cycle to ensure position and map are properly restored

Write-Host "=== Save/Load System Test ===" -ForegroundColor Yellow

# Load the save system
. "$PSScriptRoot\EnhancedSaveSystem.ps1"

# Simulate being in Display.ps1 with current position
$global:PlayerCurrentX = 25
$global:PlayerCurrentY = 8
$global:CurrentMapName = "forest"

Write-Host "Current position: ($global:PlayerCurrentX, $global:PlayerCurrentY) on map: $global:CurrentMapName" -ForegroundColor Cyan

# Create a save
Write-Host "`nCreating save..." -ForegroundColor Yellow
$saveState = New-SaveState
if ($saveState) {
    $saveFile = "$PSScriptRoot\saves\test_save.json"
    $saveState | ConvertTo-Json -Depth 10 | Out-File -FilePath $saveFile -Encoding UTF8
    Write-Host "Save created: $saveFile" -ForegroundColor Green
    
    # Show what was saved
    Write-Host "`nSaved data:" -ForegroundColor Yellow
    Write-Host "- Map: $($saveState.Location.CurrentMap)"
    Write-Host "- Position: ($($saveState.Location.PlayerX), $($saveState.Location.PlayerY))"
} else {
    Write-Host "Failed to create save!" -ForegroundColor Red
    exit
}

# Clear current position (simulate game restart)
Write-Host "`nClearing current position..." -ForegroundColor Yellow
$global:PlayerCurrentX = $null
$global:PlayerCurrentY = $null
$global:CurrentMapName = $null
$global:PlayerStartX = $null
$global:PlayerStartY = $null

# Load the save
Write-Host "`nLoading save..." -ForegroundColor Yellow
if (Test-Path $saveFile) {
    $loadedSave = Get-Content $saveFile -Raw | ConvertFrom-Json
    $restoreResult = Restore-SaveState $loadedSave
    
    if ($restoreResult) {
        Write-Host "Save loaded successfully!" -ForegroundColor Green
        Write-Host "Restored position variables:" -ForegroundColor Yellow
        Write-Host "- PlayerStartX: $global:PlayerStartX"
        Write-Host "- PlayerStartY: $global:PlayerStartY" 
        Write-Host "- CurrentMapName: $global:CurrentMapName"
        
        # Test that Display.ps1 would use these correctly
        if ($global:PlayerStartX -and $global:PlayerStartY) {
            $playerX = $global:PlayerStartX
            $playerY = $global:PlayerStartY
            $global:PlayerCurrentX = $playerX
            $global:PlayerCurrentY = $playerY
            Write-Host "`nDisplay.ps1 would start at: ($playerX, $playerY) on map: $global:CurrentMapName" -ForegroundColor Green
        } else {
            Write-Host "`nERROR: Position variables not set correctly!" -ForegroundColor Red
        }
    } else {
        Write-Host "Failed to restore save!" -ForegroundColor Red
    }
} else {
    Write-Host "Save file not found!" -ForegroundColor Red
}

# Cleanup test file
Remove-Item $saveFile -ErrorAction SilentlyContinue

Write-Host "`n=== Test Complete ===" -ForegroundColor Yellow
