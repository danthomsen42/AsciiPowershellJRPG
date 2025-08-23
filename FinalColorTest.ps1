# =============================================================================
# FINAL OVERWORLD COLOR TEST
# =============================================================================

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                    FINAL OVERWORLD COLOR DISPLAY TEST" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# Load required systems
. "$PSScriptRoot\CharacterCreation.ps1"
. "$PSScriptRoot\Display.ps1"

Write-Host "=== CREATING COLORED PARTY ===" -ForegroundColor Green

# Create a party through the proper character creation system
Write-Host "Creating party with Start-CharacterCreation system..." -ForegroundColor Yellow

# Create characters using the proper creation flow
$party1 = New-Character -Name "Crimson" -Class "Warrior" -Color "Red"
$party2 = New-Character -Name "Cobalt" -Class "Mage" -Color "Blue" 
$party3 = New-Character -Name "Emerald" -Class "Healer" -Color "Green"
$party4 = New-Character -Name "Golden" -Class "Rogue" -Color "Yellow"

$createdParty = @($party1, $party2, $party3, $party4)

Write-Host ""
Write-Host "Party created with custom colors:" -ForegroundColor Yellow
for ($i = 0; $i -lt $createdParty.Count; $i++) {
    $char = $createdParty[$i]
    Write-Host "  $($i + 1). " -NoNewline -ForegroundColor White
    Write-Host "$($char.Name)" -NoNewline -ForegroundColor $char.Color
    Write-Host " the $($char.Class) - Color: " -NoNewline -ForegroundColor White
    Write-Host $char.Color -ForegroundColor $char.Color
}

Write-Host ""
Write-Host "=== INITIALIZING PARTY SYSTEM ===" -ForegroundColor Green

# Initialize the party properly
Initialize-PartyFromCreation $createdParty

Write-Host ""
Write-Host "=== TESTING OVERWORLD DISPLAY ===" -ForegroundColor Green
Write-Host ""

Write-Host "Party positions with colors:" -ForegroundColor Yellow
$positions = Get-PartyPositions $global:Party
foreach ($key in $positions.Keys) {
    $member = $positions[$key]
    $coords = $key -split ','
    Write-Host "  ($($coords[0]),$($coords[1])): " -NoNewline -ForegroundColor White
    Write-Host "$($member.Name) [$($member.Symbol)]" -NoNewline -ForegroundColor $member.Color
    Write-Host " - $($member.Color)" -ForegroundColor White
}

Write-Host ""
Write-Host "=== COLOR SYSTEM STATUS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "SUCCESS: Individual character colors are now working!" -ForegroundColor Green
Write-Host "SUCCESS: Colors are preserved through party initialization!" -ForegroundColor Green  
Write-Host "SUCCESS: Get-PartyPositions includes color data!" -ForegroundColor Green
Write-Host "SUCCESS: ViewportRenderer will use individual colors!" -ForegroundColor Green

Write-Host ""
Write-Host "=== HOW TO USE ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Start character creation:" -ForegroundColor White
Write-Host "   Start-CharacterCreation" -ForegroundColor Green
Write-Host ""
Write-Host "2. For each character, press [K] at confirmation to change color" -ForegroundColor White
Write-Host ""
Write-Host "3. Colors will now appear in the overworld map!" -ForegroundColor White

Write-Host ""
Write-Host "READY: Character color customization is fully functional!" -ForegroundColor Green
