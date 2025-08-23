# =============================================================================
# COLOR CUSTOMIZATION DEMONSTRATION
# =============================================================================
# Test script to show both color selection and overworld display

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                      CHARACTER COLOR CUSTOMIZATION TEST" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# Load required systems
Write-Host "Loading systems..." -ForegroundColor Yellow
. "$PSScriptRoot\CharacterCreation.ps1"
. "$PSScriptRoot\PartyColorCustomization.ps1"
. "$PSScriptRoot\Display.ps1"

Write-Host ""
Write-Host "=== 1. CHARACTER COLOR CUSTOMIZATION DURING CREATION ===" -ForegroundColor Green
Write-Host ""

Write-Host "Available customization options during character creation:" -ForegroundColor Yellow
Write-Host "  - When confirming a character, press [K] to change their color" -ForegroundColor White
Write-Host "  - You'll see a color picker with 7 options and live preview" -ForegroundColor White
Write-Host "  - Colors are preserved throughout the game" -ForegroundColor White

Write-Host ""
Write-Host "Available Colors:" -ForegroundColor Yellow
foreach ($color in $DefaultColors) {
    Write-Host "  * " -NoNewline -ForegroundColor White
    Write-Host $color -ForegroundColor $color
}

Write-Host ""
Write-Host "=== 2. PARTY COLOR CUSTOMIZATION (AFTER PARTY CREATION) ===" -ForegroundColor Green
Write-Host ""

Write-Host "Functions available for post-creation color changes:" -ForegroundColor Yellow
Write-Host "  * Start-PartyColorCustomization - Interactive menu to change any member's color" -ForegroundColor White
Write-Host "  * Set-PartyMemberColor <index> <color> - Direct color assignment" -ForegroundColor White
Write-Host "  * Get-PartyColorSummary - View current party colors" -ForegroundColor White

Write-Host ""
Write-Host "=== 3. OVERWORLD COLOR DISPLAY ===" -ForegroundColor Green
Write-Host ""

Write-Host "Character colors now appear in the overworld!" -ForegroundColor Yellow
Write-Host "  - Each party member displays with their individual color" -ForegroundColor White
Write-Host "  - Leader (@) shows their selected color" -ForegroundColor White
Write-Host "  - Party members (M, H, R) show their individual colors" -ForegroundColor White
Write-Host "  - No more class-based coloring - each character is unique" -ForegroundColor White

Write-Host ""
Write-Host "=== 4. TESTING WITH SAMPLE PARTY ===" -ForegroundColor Green
Write-Host ""

# Create a sample party with custom colors to demonstrate
Write-Host "Creating sample party with custom colors..." -ForegroundColor Yellow

$sampleParty = @()
$sampleParty += New-CharacterWithRolledStats -Name "RedWarrior" -Class "Warrior" -Position 1 -Color "Red"
$sampleParty += New-CharacterWithRolledStats -Name "BlueMage" -Class "Mage" -Position 2 -Color "Blue"
$sampleParty += New-CharacterWithRolledStats -Name "GreenHealer" -Class "Healer" -Position 3 -Color "Green"
$sampleParty += New-CharacterWithRolledStats -Name "YellowRogue" -Class "Rogue" -Position 4 -Color "Yellow"

# Set as global party for testing
$global:Party = $sampleParty

Write-Host ""
Write-Host "Sample party created with custom colors:" -ForegroundColor Yellow
Get-PartyColorSummary

Write-Host ""
Write-Host "=== 5. TESTING OVERWORLD COLOR RENDERING ===" -ForegroundColor Green
Write-Host ""

Write-Host "Initializing party positions..." -ForegroundColor Yellow
$playerX = 40
$playerY = 12
Initialize-PartyPositions $playerX $playerY $global:Party

Write-Host "Getting party positions for rendering test..." -ForegroundColor Yellow
$partyPositions = Get-PartyPositions $global:Party

Write-Host "Party positions with colors:" -ForegroundColor Yellow
foreach ($key in $partyPositions.Keys) {
    $member = $partyPositions[$key]
    $coords = $key -split ','
    Write-Host "  Position ($($coords[0]),$($coords[1])): " -NoNewline -ForegroundColor White
    Write-Host "$($member.Name) [$($member.Symbol)]" -NoNewline -ForegroundColor $member.Color
    Write-Host " - Color: $($member.Color)" -ForegroundColor White
}

Write-Host ""
Write-Host "=== HOW TO USE THE COLOR SYSTEMS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. DURING CHARACTER CREATION:" -ForegroundColor Yellow
Write-Host "   Run: Start-CharacterCreation" -ForegroundColor White
Write-Host "   When confirming each character, press [K] to customize their color" -ForegroundColor White
Write-Host ""
Write-Host "2. AFTER PARTY IS CREATED:" -ForegroundColor Yellow
Write-Host "   Run: Start-PartyColorCustomization" -ForegroundColor White
Write-Host "   Select party member by number (1-4) to change their color" -ForegroundColor White
Write-Host ""
Write-Host "3. DIRECT COLOR CHANGES:" -ForegroundColor Yellow
Write-Host "   Run: Set-PartyMemberColor 0 'Magenta'  # Change leader to magenta" -ForegroundColor White
Write-Host "   Run: Set-PartyMemberColor 1 'Cyan'     # Change member 2 to cyan" -ForegroundColor White
Write-Host ""
Write-Host "4. VIEW CURRENT COLORS:" -ForegroundColor Yellow
Write-Host "   Run: Get-PartyColorSummary" -ForegroundColor White
Write-Host ""
Write-Host "The colors will automatically appear in the overworld map!" -ForegroundColor Green

Write-Host ""
Write-Host "=== TEST COMPLETE ===" -ForegroundColor Cyan
Write-Host "All color systems are ready to use!" -ForegroundColor Green
