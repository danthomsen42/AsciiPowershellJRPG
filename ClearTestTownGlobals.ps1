# Clear All TestTown References and Check Global State
Write-Host "=== GLOBAL VARIABLE CLEANUP ===" -ForegroundColor Yellow

Write-Host "Current problematic global variables:" -ForegroundColor Cyan
Write-Host "- CurrentMapName: '$global:CurrentMapName'"
Write-Host "- PlayerStartX: '$global:PlayerStartX'" 
Write-Host "- PlayerStartY: '$global:PlayerStartY'"
Write-Host "- PlayerCurrentX: '$global:PlayerCurrentX'"
Write-Host "- PlayerCurrentY: '$global:PlayerCurrentY'"

if ($global:CurrentMapName -eq "TestTown") {
    Write-Host "❌ FOUND PROBLEM: CurrentMapName is set to TestTown!" -ForegroundColor Red
    Write-Host "Clearing TestTown reference..." -ForegroundColor Yellow
    $global:CurrentMapName = $null
} else {
    Write-Host "✅ CurrentMapName is clean: '$global:CurrentMapName'" -ForegroundColor Green
}

# Clear all save-related globals to ensure fresh start
Write-Host "`nClearing all save-related global variables..." -ForegroundColor Yellow
$global:CurrentMapName = $null
$global:PlayerStartX = $null
$global:PlayerStartY = $null  
$global:PlayerCurrentX = $null
$global:PlayerCurrentY = $null

Write-Host "✅ All global variables cleared!" -ForegroundColor Green

Write-Host "`nNow testing a fresh Display.ps1 start..." -ForegroundColor Cyan
Write-Host "You should now be able to start a new game without TestTown errors." -ForegroundColor Green

Write-Host "`n=== CLEANUP COMPLETE ===" -ForegroundColor Yellow
Write-Host "Try starting your new game again now." -ForegroundColor White
