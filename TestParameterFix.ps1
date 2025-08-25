# Test script to verify the hashtable parameter fix

Write-Host "Testing Save/Load Parameter Fix" -ForegroundColor Cyan
Write-Host "=" * 40 -ForegroundColor Cyan

# Set up test game state
$global:CurrentMapName = "TestTown"
$global:Player = [PSCustomObject]@{
    Position = [PSCustomObject]@{ X = 20; Y = 10 }
}
$global:party = @()
$global:party += [PSCustomObject]@{
    Name = "TestHero"
    Class = "Knight"
    Level = 3
    HP = 60
    MaxHP = 80
    Color = "Red"
}
$global:Inventory = @{ "Health Potion" = 2 }

# Load enhanced save system
. "$PSScriptRoot\EnhancedSaveSystem.ps1"

Write-Host "`n1. Creating test save..." -ForegroundColor Yellow
$saveResult = Save-AutoSave

if ($saveResult) {
    Write-Host "[PASS] Save created successfully" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Save creation failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n2. Testing save load..." -ForegroundColor Yellow

try {
    # Load the autosave file
    $autoSaveFile = "$PSScriptRoot\saves\autosave.json"
    if (Test-Path $autoSaveFile) {
        $saveData = Get-Content $autoSaveFile -Raw | ConvertFrom-Json
        
        # Test the Show-SavePreview function (this was causing the error)
        Write-Host "Testing Show-SavePreview function..." -ForegroundColor Cyan
        Show-SavePreview $saveData "Test Save"
        
        Write-Host "`n[PASS] Show-SavePreview worked without parameter type errors" -ForegroundColor Green
        
        # Test the Restore-SaveState function
        Write-Host "`nTesting Restore-SaveState function..." -ForegroundColor Cyan
        Restore-SaveState $saveData
        
        Write-Host "[PASS] Restore-SaveState worked without parameter type errors" -ForegroundColor Green
        
        Write-Host "`n[SUCCESS] All parameter type issues fixed!" -ForegroundColor Green -BackgroundColor Black
        
    } else {
        Write-Host "[FAIL] Autosave file not found" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Error during load test: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception)" -ForegroundColor Gray
}

Write-Host "`n" + ("=" * 40) -ForegroundColor Cyan
Write-Host "Parameter Fix Test Complete" -ForegroundColor Cyan
