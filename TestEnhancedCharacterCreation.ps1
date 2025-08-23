# Test Enhanced Character Creation System
. .\CharacterCreation.ps1

Write-Host "=== Enhanced Character Creation Test ===" -ForegroundColor Cyan
Write-Host ""

# Test stat ranges
Write-Host "Testing stat ranges..." -ForegroundColor Yellow
$classes = @("Warrior", "Mage", "Healer", "Rogue")
foreach ($class in $classes) {
    $ranges = Get-ClassStatRanges -Class $class
    Write-Host "  $class ranges:" -ForegroundColor White
    Write-Host "    HP: $($ranges.HP[0])-$($ranges.HP[1])  MP: $($ranges.MP[0])-$($ranges.MP[1])  ATK: $($ranges.Attack[0])-$($ranges.Attack[1])  DEF: $($ranges.Defense[0])-$($ranges.Defense[1])  SPD: $($ranges.Speed[0])-$($ranges.Speed[1])" -ForegroundColor Gray
}

Write-Host ""

# Test character creation with stat rolling
Write-Host "Testing character creation with stat rolling..." -ForegroundColor Yellow
$testChar = New-CharacterWithRolledStats -Name "TestHero" -Class "Warrior" -Position 1
Write-Host "  Created: $($testChar.Name) the $($testChar.Class)" -ForegroundColor White
Write-Host "    HP: $($testChar.MaxHP)  MP: $($testChar.MaxMP)  ATK: $($testChar.Attack)  DEF: $($testChar.Defense)  SPD: $($testChar.Speed)" -ForegroundColor Green

Write-Host ""

# Test multiple rolls to show variation
Write-Host "Testing stat variation (5 Mage rolls):" -ForegroundColor Yellow
for ($i = 1; $i -le 5; $i++) {
    $testMage = New-CharacterWithRolledStats -Name "Mage$i" -Class "Mage" -Position 1
    Write-Host "  Roll $i - HP:$($testMage.MaxHP) MP:$($testMage.MaxMP) ATK:$($testMage.Attack) DEF:$($testMage.Defense) SPD:$($testMage.Speed)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Enhanced Character Creation System: READY FOR TESTING!" -ForegroundColor Green
Write-Host "Run .\GameLauncherSimple.ps1 and select 'New Game' to test the full interface." -ForegroundColor Yellow
