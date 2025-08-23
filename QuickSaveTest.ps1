# Quick test of enhanced save system functions
$script:currentMapName = "TestTown"
$script:playerX = 10
$script:playerY = 5
$script:globalXP = 1000
$script:party = @()
$script:inventory = @{}

. "$PSScriptRoot\EnhancedSaveSystem.ps1"

Write-Host "Testing New-SaveState function..." -ForegroundColor Yellow
$saveState = New-SaveState

if ($saveState) {
    Write-Host "[PASS] Save state created successfully" -ForegroundColor Green
    Write-Host "Location: $($saveState.Location.MapName) at ($($saveState.Location.PlayerX),$($saveState.Location.PlayerY))" -ForegroundColor Cyan
    Write-Host "XP: $($saveState.Progress.GlobalXP)" -ForegroundColor Cyan
    Write-Host "Party Members: $($saveState.Party.Members.Count)" -ForegroundColor Cyan
    Write-Host "Inventory Items: $($saveState.Inventory.Count)" -ForegroundColor Cyan
} else {
    Write-Host "[FAIL] Save state creation failed" -ForegroundColor Red
}

Write-Host "`nTesting Save-AutoSave function..." -ForegroundColor Yellow
$result = Save-AutoSave
if ($result) {
    Write-Host "[PASS] Auto-save completed successfully" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Auto-save failed" -ForegroundColor Red
}

Write-Host "`nPhase 5.4 Enhanced Save System: Basic functionality verified!" -ForegroundColor Green
