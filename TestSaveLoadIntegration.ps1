# Test script for enhanced save and load functionality
# This will create a save and then try to load it

Write-Host "Testing Enhanced Save/Load System Integration" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

# Set up test game state
$global:CurrentMapName = "TestTown"
$global:party = @()
$global:party += [PSCustomObject]@{
    Name = "TestHero"
    Class = "Knight"
    Level = 5
    HP = 80
    MaxHP = 100
    MP = 30
    MaxMP = 40
    Color = "Red"
    Position = [PSCustomObject]@{ X = 15; Y = 8 }
    Equipment = @{
        Weapon = "Steel Sword"
        Armor = "Chain Mail"
        Shield = "Iron Shield"
    }
    Spells = @("Heal", "Fireball")
    XP = 2500
}

$global:Inventory = @{
    "Health Potion" = 3
    "Gold Coins" = 250
}

# Load enhanced save system
. "$PSScriptRoot\EnhancedSaveSystem.ps1"

Write-Host "`nStep 1: Creating a test save..." -ForegroundColor Yellow
$saveResult = Save-ManualSave
if ($saveResult) {
    Write-Host "[PASS] Manual save created successfully" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Manual save failed" -ForegroundColor Red
    exit 1
}

# Find the created save file
$saveFiles = Get-ChildItem "$PSScriptRoot\saves" -Filter "save_*.json" | Sort-Object CreationTime -Descending
if ($saveFiles.Count -eq 0) {
    Write-Host "[FAIL] No save files found after creating save" -ForegroundColor Red
    exit 1
}

$testSaveFile = $saveFiles[0].FullName
Write-Host "Test save file: $($saveFiles[0].Name)" -ForegroundColor Cyan

Write-Host "`nStep 2: Testing StartScreen save preview..." -ForegroundColor Yellow
. "$PSScriptRoot\StartScreen.ps1"

$previewInfo = Get-SaveFilePreview $testSaveFile
Write-Host "Preview Info:" -ForegroundColor White
Write-Host "  Location: $($previewInfo.Location)" -ForegroundColor Gray
Write-Host "  Level: $($previewInfo.Level)" -ForegroundColor Gray
Write-Host "  HP: $($previewInfo.HP)/$($previewInfo.MaxHP)" -ForegroundColor Gray
Write-Host "  Party Size: $($previewInfo.PartySize)" -ForegroundColor Gray
Write-Host "  Save Type: $($previewInfo.SaveType)" -ForegroundColor Gray

if ($previewInfo.Location -eq "TestTown" -and $previewInfo.Level -eq 5) {
    Write-Host "[PASS] Save preview working correctly" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Save preview not working correctly" -ForegroundColor Red
}

Write-Host "`nStep 3: Testing save restore..." -ForegroundColor Yellow

# Clear current game state to test restore
$global:CurrentMapName = ""
$global:party = @()
$global:Inventory = @{}

# Load the save file
try {
    $saveData = Get-Content -Path $testSaveFile -Raw | ConvertFrom-Json
    Restore-SaveState $saveData
    
    # Verify restoration
    if ($global:CurrentMapName -eq "TestTown" -and $global:party.Count -gt 0) {
        Write-Host "[PASS] Save state restored successfully" -ForegroundColor Green
        Write-Host "  Restored map: $global:CurrentMapName" -ForegroundColor Gray
        Write-Host "  Restored party size: $($global:party.Count)" -ForegroundColor Gray
        Write-Host "  Party leader: $($global:party[0].Name)" -ForegroundColor Gray
    } else {
        Write-Host "[FAIL] Save state restoration failed" -ForegroundColor Red
        Write-Host "  Map: $global:CurrentMapName" -ForegroundColor Gray
        Write-Host "  Party size: $($global:party.Count)" -ForegroundColor Gray
    }
} catch {
    Write-Host "[FAIL] Save restore error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
Write-Host "Enhanced Save/Load Integration Test Complete!" -ForegroundColor Cyan
Write-Host "`nStart menu Load Game functionality should now work!" -ForegroundColor Green
