# Quick Integration Test
. .\CharacterCreation.ps1

Write-Host "=== Quick Integration Test ===" -ForegroundColor Cyan

# Create a test party
Write-Host "Creating test party..." -ForegroundColor Yellow
$testParty = @()
$testParty += New-CharacterWithRolledStats -Name "TestWarrior" -Class "Warrior" -Position 1
$testParty += New-CharacterWithRolledStats -Name "TestMage" -Class "Mage" -Position 2  
$testParty += New-CharacterWithRolledStats -Name "TestHealer" -Class "Healer" -Position 3
$testParty += New-CharacterWithRolledStats -Name "TestRogue" -Class "Rogue" -Position 4

Write-Host "Test Party Created:" -ForegroundColor Green
for ($i = 0; $i -lt $testParty.Count; $i++) {
    $char = $testParty[$i]
    Write-Host "  Position $($i+1): $($char.Name) the $($char.Class) [$($char.ClassData.MapSymbol)]" -ForegroundColor White
}

# Initialize the party
Write-Host ""
Write-Host "Initializing party..." -ForegroundColor Yellow
Initialize-PartyFromCreation -CreatedParty $testParty

# Test the global variables
Write-Host ""
Write-Host "Testing global variables:" -ForegroundColor Yellow
Write-Host "  `$global:Player.Name: $($global:Player.Name)" -ForegroundColor White
Write-Host "  `$global:Player.Class: $($global:Player.Class)" -ForegroundColor White
Write-Host "  `$global:Party.Count: $($global:Party.Count)" -ForegroundColor White
Write-Host "  Party MapSymbols: $($global:Party.MapSymbol -join ', ')" -ForegroundColor White

Write-Host ""
Write-Host "Integration Test Complete!" -ForegroundColor Green
Write-Host "The custom party should now be available when Display.ps1 loads." -ForegroundColor Yellow
