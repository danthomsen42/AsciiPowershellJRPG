# Debug Character Creation Process
. .\CharacterCreation.ps1

Write-Host "=== Character Creation Debug ===" -ForegroundColor Cyan

# Manually create a W, M, W, R party to test
Write-Host "Creating W, M, W, R party manually..." -ForegroundColor Yellow

$debugParty = @()
$debugParty += New-CharacterWithRolledStats -Name "Warrior1" -Class "Warrior" -Position 1
$debugParty += New-CharacterWithRolledStats -Name "MageTest" -Class "Mage" -Position 2  
$debugParty += New-CharacterWithRolledStats -Name "Warrior2" -Class "Warrior" -Position 3
$debugParty += New-CharacterWithRolledStats -Name "RogueTest" -Class "Rogue" -Position 4

Write-Host ""
Write-Host "Created Party Details:" -ForegroundColor Green
for ($i = 0; $i -lt $debugParty.Count; $i++) {
    $char = $debugParty[$i]
    Write-Host "  Position $($i+1):" -ForegroundColor White
    Write-Host "    Name: $($char.Name)" -ForegroundColor Gray
    Write-Host "    Class: $($char.Class)" -ForegroundColor Gray
    Write-Host "    ClassData.MapSymbol: $($char.ClassData.MapSymbol)" -ForegroundColor Gray
    Write-Host "    MapSymbol: $($char.MapSymbol)" -ForegroundColor Gray
    Write-Host "    Position: X=$($char.Position.X), Y=$($char.Position.Y)" -ForegroundColor Gray
    Write-Host ""
}

# Initialize this party
Write-Host "Initializing W, M, W, R party..." -ForegroundColor Yellow
Initialize-PartyFromCreation -CreatedParty $debugParty

Write-Host ""
Write-Host "After initialization - Global Party Check:" -ForegroundColor Yellow
for ($i = 0; $i -lt $global:Party.Count; $i++) {
    $member = $global:Party[$i]
    Write-Host "  Global Party[$i]:" -ForegroundColor White
    Write-Host "    Name: $($member.Name), Class: $($member.Class)" -ForegroundColor Gray
    Write-Host "    MapSymbol: $($member.MapSymbol)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Expected formation: W -> M -> W -> R" -ForegroundColor Cyan
Write-Host "Actual formation: $($global:Party.MapSymbol -join ' -> ')" -ForegroundColor Yellow

Write-Host ""
Write-Host "Testing Get-PartyPositions function:" -ForegroundColor Yellow
$partyPositions = Get-PartyPositions $global:Party
Write-Host "PartyPositions keys: $($partyPositions.Keys -join ', ')" -ForegroundColor Gray
foreach ($key in $partyPositions.Keys) {
    $pos = $partyPositions[$key]
    Write-Host "  Position $key - Name: $($pos.Name), Class: $($pos.Class), Symbol: $($pos.Symbol)" -ForegroundColor Gray
}
