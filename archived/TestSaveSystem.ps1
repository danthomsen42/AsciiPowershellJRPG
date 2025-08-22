# =============================================================================
# PHASE 1.4 SAVE SYSTEM TEST SCRIPT
# =============================================================================

Write-Host "=== SAVE SYSTEM TEST SCRIPT ===" -ForegroundColor Cyan
Write-Host "Testing Phase 1.4 Comprehensive Save System" -ForegroundColor Yellow

# Load the save system (first part of Display.ps1)
$SaveSystemStart = Get-Content "Display.ps1" | Select-Object -First 500
$SaveSystemCode = ($SaveSystemStart | Where-Object { $_ -match "PHASE 1.4|Save|function.*Save|AutoSave|QuickSave" }) -join "`n"

# Test 1: Check if save directory is created
Write-Host "`n--- Test 1: Save Directory Creation ---" -ForegroundColor Green
$SaveDirectory = "$PSScriptRoot/saves"
if (Test-Path $SaveDirectory) {
    Write-Host "✓ Save directory exists: $SaveDirectory" -ForegroundColor Green
} else {
    Write-Host "✗ Save directory not found!" -ForegroundColor Red
}

# Test 2: Check save file structure
Write-Host "`n--- Test 2: Save File Structure ---" -ForegroundColor Green
$AutoSaveFilePath = "$SaveDirectory/autosave.json"
if (Test-Path $AutoSaveFilePath) {
    try {
        $saveData = Get-Content $AutoSaveFilePath | ConvertFrom-Json
        Write-Host "✓ Auto-save file exists and is valid JSON" -ForegroundColor Green
        Write-Host "  Version: $($saveData.GameInfo.Version)" -ForegroundColor White
        Write-Host "  Save Time: $($saveData.GameInfo.SaveTime)" -ForegroundColor White
        Write-Host "  Player Level: $($saveData.Player.Level)" -ForegroundColor White
        Write-Host "  Player XP: $($saveData.Player.XP)" -ForegroundColor White
        Write-Host "  Player HP: $($saveData.Player.HP)/$($saveData.Player.MaxHP)" -ForegroundColor White
        Write-Host "  Player MP: $($saveData.Player.MP)/$($saveData.Player.MaxMP)" -ForegroundColor White
        Write-Host "  Equipment: $($saveData.Player.Weapon), $($saveData.Player.Armor)" -ForegroundColor White
        Write-Host "  Monsters Defeated: $($saveData.Player.MonstersDefeated)" -ForegroundColor White
        Write-Host "  Areas Discovered: $($saveData.Player.AreasDiscovered.Count)" -ForegroundColor White
        Write-Host "  NPCs Spoken To: $($saveData.Player.NPCsSpokenTo.Count)" -ForegroundColor White
        Write-Host "  Items Collected: $($saveData.Player.ItemsCollected.Count)" -ForegroundColor White
    } catch {
        Write-Host "✗ Auto-save file is corrupted: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "- Auto-save file not found (expected on first run)" -ForegroundColor Yellow
}

# Test 3: List all save slots
Write-Host "`n--- Test 3: Available Save Slots ---" -ForegroundColor Green
for ($i = 1; $i -le 5; $i++) {
    $SlotFilePath = "$SaveDirectory/save_slot_$i.json"
    if (Test-Path $SlotFilePath) {
        try {
            $slotData = Get-Content $SlotFilePath | ConvertFrom-Json
            Write-Host "✓ Slot $i`: Level $($slotData.Player.Level) - $($slotData.GameInfo.SaveTime)" -ForegroundColor Green
        } catch {
            Write-Host "✗ Slot $i`: Corrupted save file" -ForegroundColor Red
        }
    } else {
        Write-Host "- Slot $i`: [Empty]" -ForegroundColor DarkGray
    }
}

# Check quick save
$QuickSaveFilePath = "$SaveDirectory/quicksave.json"
if (Test-Path $QuickSaveFilePath) {
    try {
        $quickData = Get-Content $QuickSaveFilePath | ConvertFrom-Json
        Write-Host "✓ Quick Save: Level $($quickData.Player.Level) - $($quickData.GameInfo.SaveTime)" -ForegroundColor Cyan
    } catch {
        Write-Host "✗ Quick Save: Corrupted save file" -ForegroundColor Red
    }
} else {
    Write-Host "- Quick Save: [Empty]" -ForegroundColor DarkGray
}

# Test 4: Check legacy save compatibility
Write-Host "`n--- Test 4: Legacy Save Compatibility ---" -ForegroundColor Green
$LegacySavePath = "$PSScriptRoot/savegame.json"
if (Test-Path $LegacySavePath) {
    try {
        $legacyData = Get-Content $LegacySavePath | ConvertFrom-Json
        Write-Host "✓ Legacy save file found" -ForegroundColor Green
        Write-Host "  Legacy XP: $($legacyData.Player.XP)" -ForegroundColor White
        Write-Host "  Legacy Level: $($legacyData.Player.Level)" -ForegroundColor White
        Write-Host "  Legacy Monsters Defeated: $($legacyData.Player.MonstersDefeated)" -ForegroundColor White
        Write-Host "  Monster types tracked: $($legacyData.Monsters.PSObject.Properties.Count)" -ForegroundColor White
    } catch {
        Write-Host "✗ Legacy save file is corrupted" -ForegroundColor Red
    }
} else {
    Write-Host "- No legacy save file found" -ForegroundColor Yellow
}

Write-Host "`n=== SAVE SYSTEM TEST COMPLETE ===" -ForegroundColor Cyan
Write-Host "New Save System Features:" -ForegroundColor Yellow
Write-Host "• Auto-save after battle victories" -ForegroundColor White
Write-Host "• F5 for Quick Save" -ForegroundColor White
Write-Host "• F9 for Save Menu (5 manual slots)" -ForegroundColor White
Write-Host "• Comprehensive player state tracking" -ForegroundColor White
Write-Host "• Game session tracking (play time, version)" -ForegroundColor White
Write-Host "• Progress tracking (NPCs, items, areas)" -ForegroundColor White
Write-Host "• Backward compatibility with legacy saves" -ForegroundColor White

Read-Host "`nPress Enter to continue"
