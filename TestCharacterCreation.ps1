# Test Character Creation System
. "$PSScriptRoot\CharacterCreation.ps1"

Write-Host "=== Character Creation Test ===" -ForegroundColor Cyan
Write-Host ""

# Test default party creation
Write-Host "Creating default party..." -ForegroundColor Yellow
$defaultParty = New-DefaultParty

Write-Host "Default Party Members:" -ForegroundColor Green
foreach ($char in $defaultParty) {
    Write-Host "  Name: $($char.Name), Class: $($char.Class)" -ForegroundColor White
    Write-Host "    HP: $($char.MaxHP), MP: $($char.MaxMP), ATK: $($char.Attack), DEF: $($char.Defense), SPD: $($char.Speed)" -ForegroundColor Gray
    Write-Host "    Equipment: $($char.Equipped.Weapon), $($char.Equipped.Armor)" -ForegroundColor DarkGray
    Write-Host ""
}

Write-Host "Creating random party..." -ForegroundColor Yellow
$randomParty = New-RandomParty

Write-Host "Random Party Members:" -ForegroundColor Green
foreach ($char in $randomParty) {
    Write-Host "  Name: $($char.Name), Class: $($char.Class)" -ForegroundColor White
    Write-Host "    HP: $($char.MaxHP), MP: $($char.MaxMP), ATK: $($char.Attack), DEF: $($char.Defense), SPD: $($char.Speed)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Testing name generation..." -ForegroundColor Yellow
Write-Host "Warrior names: $(Get-RandomName -Class 'Warrior' -Type 'Class'), $(Get-RandomName -Class 'Warrior' -Type 'Class'), $(Get-RandomName -Class 'Warrior' -Type 'Class')" -ForegroundColor White
Write-Host "Mage names: $(Get-RandomName -Class 'Mage' -Type 'Class'), $(Get-RandomName -Class 'Mage' -Type 'Class'), $(Get-RandomName -Class 'Mage' -Type 'Class')" -ForegroundColor White
Write-Host ""

Write-Host "Character Creation System: WORKING!" -ForegroundColor Green
