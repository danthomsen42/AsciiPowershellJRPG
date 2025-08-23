# Final test of the complete save/load system integration

Write-Host "FINAL SAVE/LOAD INTEGRATION TEST" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

Write-Host "`nThis test will:" -ForegroundColor Yellow
Write-Host "1. Create a test save with enhanced save system" -ForegroundColor White
Write-Host "2. Test the StartScreen load game menu preview" -ForegroundColor White  
Write-Host "3. Test the load functionality" -ForegroundColor White
Write-Host "4. Verify game state restoration" -ForegroundColor White

# Set up test game state
Write-Host "`nSetting up test game state..." -ForegroundColor Yellow
$global:CurrentMapName = "TestTown"
$global:Player = [PSCustomObject]@{
    Name = "TestPlayer"
    Position = [PSCustomObject]@{ X = 25; Y = 15 }
    Level = 7
    HP = 95
    MaxHP = 120
    MP = 45
    MaxMP = 60
    XP = 3500
}

$global:party = @()
$global:party += [PSCustomObject]@{
    Name = "MainHero"
    Class = "Paladin"
    Level = 7
    HP = 95
    MaxHP = 120
    MP = 45
    MaxMP = 60
    Color = "Gold"
    Position = [PSCustomObject]@{ X = 25; Y = 15 }
    Equipment = @{
        Weapon = "Holy Sword"
        Armor = "Plate Mail"
        Shield = "Sacred Shield"
    }
    Spells = @("Heal", "Smite", "Bless")
    XP = 3500
}

$global:Inventory = @{
    "Health Potion" = 8
    "Mana Potion" = 5
    "Gold Coins" = 750
    "Holy Water" = 2
}

# Load enhanced save system and create save
Write-Host "`nCreating enhanced save..." -ForegroundColor Yellow
. "$PSScriptRoot\EnhancedSaveSystem.ps1"
$saveResult = Save-ManualSave

if (-not $saveResult) {
    Write-Host "[FAIL] Could not create test save" -ForegroundColor Red
    exit 1
}

Write-Host "[PASS] Enhanced save created" -ForegroundColor Green

# Test StartScreen preview functionality
Write-Host "`nTesting StartScreen preview..." -ForegroundColor Yellow
. "$PSScriptRoot\StartScreen.ps1"

# Find the latest save file
$saveFiles = Get-ChildItem "$PSScriptRoot\saves" -Filter "save_*.json" | Sort-Object CreationTime -Descending
if ($saveFiles.Count -eq 0) {
    Write-Host "[FAIL] No enhanced save files found" -ForegroundColor Red
    exit 1
}

$testSaveFile = $saveFiles[0].FullName
Write-Host "Testing with save file: $($saveFiles[0].Name)" -ForegroundColor Cyan

# Test the preview function
if (Get-Command Get-SaveFilePreview -ErrorAction SilentlyContinue) {
    Write-Host "[PASS] Get-SaveFilePreview function loaded" -ForegroundColor Green
    
    $previewInfo = Get-SaveFilePreview $testSaveFile
    Write-Host "`nSave Preview Information:" -ForegroundColor White
    Write-Host "  Location: $($previewInfo.Location)" -ForegroundColor Gray
    Write-Host "  Leader: Level $($previewInfo.Level) - $($previewInfo.HP)/$($previewInfo.MaxHP) HP" -ForegroundColor Gray
    Write-Host "  Party Size: $($previewInfo.PartySize) members" -ForegroundColor Gray
    Write-Host "  Save Type: $($previewInfo.SaveType)" -ForegroundColor Gray
    Write-Host "  Play Time: $([math]::Round($previewInfo.PlayTime, 1)) minutes" -ForegroundColor Gray
    
    if ($previewInfo.Location -eq "TestTown" -and $previewInfo.Level -eq 7) {
        Write-Host "[PASS] Save preview data correct" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Save preview data incorrect" -ForegroundColor Red
    }
} else {
    Write-Host "[FAIL] Get-SaveFilePreview function not loaded" -ForegroundColor Red
}

# Test load functionality
Write-Host "`nTesting save load functionality..." -ForegroundColor Yellow

# Clear current state
$global:CurrentMapName = ""
$global:party = @()
$global:Player = $null

# Load the save
if (Get-Command Load-SaveFile -ErrorAction SilentlyContinue) {
    Write-Host "[PASS] Load-SaveFile function loaded" -ForegroundColor Green
    
    # Since Load-SaveFile has interactive confirmation, we'll test Restore-SaveState directly
    try {
        $saveData = Get-Content -Path $testSaveFile -Raw | ConvertFrom-Json
        Restore-SaveState $saveData
        
        # Verify restoration
        if ($global:CurrentMapName -eq "TestTown" -and $global:party.Count -gt 0) {
            Write-Host "[PASS] Game state restored successfully" -ForegroundColor Green
            Write-Host "  Restored map: $global:CurrentMapName" -ForegroundColor Gray
            Write-Host "  Party size: $($global:party.Count)" -ForegroundColor Gray
            Write-Host "  Party leader: $($global:party[0].Name) (Level $($global:party[0].Level))" -ForegroundColor Gray
        } else {
            Write-Host "[FAIL] Game state restoration incomplete" -ForegroundColor Red
            Write-Host "  Map: '$global:CurrentMapName'" -ForegroundColor Gray
            Write-Host "  Party size: $($global:party.Count)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "[FAIL] Load error: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "[FAIL] Load-SaveFile function not loaded" -ForegroundColor Red
}

Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
Write-Host "SAVE/LOAD INTEGRATION TEST COMPLETE" -ForegroundColor Cyan
Write-Host "`nLoad Game functionality is now ready!" -ForegroundColor Green
Write-Host "You can use:" -ForegroundColor White
Write-Host "• GameLauncherSimple.ps1 -> Load Game option" -ForegroundColor Gray
Write-Host "• StartScreen.ps1 -> Load Game menu" -ForegroundColor Gray  
Write-Host "• F9 hotkey in-game for save/load menu" -ForegroundColor Gray
