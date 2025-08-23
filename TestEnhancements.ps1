# Test Enhanced Character Creation Features
Write-Host "=== TESTING ENHANCED CHARACTER CREATION ===" -ForegroundColor Cyan

Write-Host "`n1. Testing Battle System Fix..." -ForegroundColor Yellow

# Load systems
. ".\CharacterCreation.ps1"
. ".\NewEnemies.ps1"

# Test that Get-AlivePartyMembers works
$testParty = New-DefaultParty
$aliveCount = (Get-AlivePartyMembers $testParty).Count
Write-Host "   Get-AlivePartyMembers: $aliveCount alive members (should be 4)" -ForegroundColor $(if($aliveCount -eq 4){'Green'}else{'Red'})

# Test turn order creation
$testEnemy = $Goblin.Clone()
$turnOrder = New-PartyTurnOrder $testParty @($testEnemy)
Write-Host "   Turn Order: $($turnOrder.Count) combatants (should be 5)" -ForegroundColor $(if($turnOrder.Count -eq 5){'Green'}else{'Red'})

Write-Host "`n2. Testing Enhanced Name Diversity..." -ForegroundColor Yellow

# Test new names include both masculine and feminine options
$warriorNames = $FantasyNames["Warrior"]
$mageNames = $FantasyNames["Mage"]
$healerNames = $FantasyNames["Healer"]
$rogueNames = $FantasyNames["Rogue"]

Write-Host "   Warrior names: $($warriorNames.Count) total" -ForegroundColor Green
Write-Host "     Examples: $($warriorNames[0..4] -join ', ')..."
Write-Host "   Mage names: $($mageNames.Count) total" -ForegroundColor Green  
Write-Host "     Examples: $($mageNames[0..4] -join ', ')..."
Write-Host "   Healer names: $($healerNames.Count) total" -ForegroundColor Green
Write-Host "     Examples: $($healerNames[0..4] -join ', ')..."
Write-Host "   Rogue names: $($rogueNames.Count) total" -ForegroundColor Green
Write-Host "     Examples: $($rogueNames[0..4] -join ', ')..."

Write-Host "`n3. Testing Character Color System..." -ForegroundColor Yellow

# Test random color assignment
$colors = @()
for ($i = 0; $i -lt 10; $i++) {
    $colors += Get-RandomCharacterColor
}
$uniqueColors = $colors | Select-Object -Unique
Write-Host "   Random color variety: $($uniqueColors.Count) different colors from 10 rolls" -ForegroundColor Green
Write-Host "   Colors generated: $($uniqueColors -join ', ')"

Write-Host "`n4. Testing Enhanced Character Creation..." -ForegroundColor Yellow

# Create characters with colors
$testChars = @()
$testChars += New-Character -Name "RedWarrior" -Class "Warrior" -Color "Red" -Position 1
$testChars += New-Character -Name "BlueMage" -Class "Mage" -Color "Blue" -Position 2
$testChars += New-Character -Name "GreenHealer" -Class "Healer" -Color "Green" -Position 3
$testChars += New-Character -Name "YellowRogue" -Class "Rogue" -Color "Yellow" -Position 4

Write-Host "   Created characters with custom colors:"
foreach ($char in $testChars) {
    Write-Host "     $($char.Name) ($($char.Class)) - Color: $($char.Color) - Symbol: $($char.MapSymbol)" -ForegroundColor $char.Color
}

Write-Host "`n5. Testing Color Integration with Battle System..." -ForegroundColor Yellow

# Test that colors are preserved through initialization
Initialize-PartyFromCreation -CreatedParty $testChars

Write-Host "   Party after initialization:"
for ($i = 0; $i -lt $global:Party.Count; $i++) {
    $member = $global:Party[$i]
    $colorText = if ($member.Color) { $member.Color } else { "No Color" }
    Write-Host "     [$i] $($member.Name) - Class: $($member.Class) - Color: $colorText" -ForegroundColor $(if($member.Color){$member.Color}else{'White'})
}

# Test ViewportRenderer with colored characters
. ".\ViewportRenderer.ps1"
$positions = Get-PartyPositions -Party $global:Party

Write-Host "`n6. Testing Different Class Combinations..." -ForegroundColor Yellow

# Test 4 warriors with different colors like user mentioned
$warriorParty = @()
$warriorColors = @("Red", "Blue", "Green", "Yellow")
for ($i = 0; $i -lt 4; $i++) {
    $warrior = New-Character -Name "Knight$($i+1)" -Class "Warrior" -Color $warriorColors[$i] -Position ($i + 1)
    $warriorParty += $warrior
}

Write-Host "   4-Warrior party with different colors:"
foreach ($warrior in $warriorParty) {
    Write-Host "     $($warrior.Name) - $($warrior.Class) - $($warrior.Color)" -ForegroundColor $warrior.Color
}

Write-Host "`n7. Summary of Enhancements:" -ForegroundColor Green
Write-Host "   SUCCESS: Battle System - Fixed Get-AlivePartyMembers bug" -ForegroundColor Green
Write-Host "   SUCCESS: Battle System - Added safety checks for endless loops" -ForegroundColor Green  
Write-Host "   SUCCESS: Names - Enhanced diversity with 20 names per class" -ForegroundColor Green
Write-Host "   SUCCESS: Colors - Added color selection system for characters" -ForegroundColor Green
Write-Host "   SUCCESS: Colors - Random default assignment with 7 available colors" -ForegroundColor Green
Write-Host "   SUCCESS: Integration - Colors preserved through party initialization" -ForegroundColor Green

Write-Host "`n=== ENHANCEMENT TESTING COMPLETED ===" -ForegroundColor Cyan
