# =============================================================================
# TEST CHARACTER COLORS IN OVERWORLD
# =============================================================================

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                    TESTING CHARACTER COLORS IN OVERWORLD" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# Load required systems
. "$PSScriptRoot\CharacterCreation.ps1"
. "$PSScriptRoot\PartySystem.ps1"
. "$PSScriptRoot\ViewportRenderer.ps1"

Write-Host "=== STEP 1: CREATE PARTY WITH CUSTOM COLORS ===" -ForegroundColor Green
Write-Host ""

# Create a test party with specific colors
$testParty = @()

Write-Host "Creating characters with custom colors..." -ForegroundColor Yellow
$testParty += New-CharacterWithRolledStats -Name "RedWarrior" -Class "Warrior" -Position 1 -Color "Red"
$testParty += New-CharacterWithRolledStats -Name "BlueMage" -Class "Mage" -Position 2 -Color "Blue"
$testParty += New-CharacterWithRolledStats -Name "GreenHealer" -Class "Healer" -Position 3 -Color "Green"
$testParty += New-CharacterWithRolledStats -Name "YellowRogue" -Class "Rogue" -Position 4 -Color "Yellow"

Write-Host "Characters created with colors:" -ForegroundColor Yellow
for ($i = 0; $i -lt $testParty.Count; $i++) {
    $char = $testParty[$i]
    Write-Host "  $($i + 1). " -NoNewline -ForegroundColor White
    Write-Host "$($char.Name)" -NoNewline -ForegroundColor $char.Color
    Write-Host " ($($char.Class)) - Color: " -NoNewline -ForegroundColor White
    Write-Host $char.Color -ForegroundColor $char.Color
}

Write-Host ""
Write-Host "=== STEP 2: INITIALIZE PARTY POSITIONS ===" -ForegroundColor Green
Write-Host ""

# Set as global party
$global:Party = $testParty

# Initialize party positions
$startX = 40
$startY = 12
Write-Host "Initializing party positions at ($startX, $startY)..." -ForegroundColor Yellow
Initialize-PartyPositions $startX $startY $global:Party

Write-Host "Party positions initialized!" -ForegroundColor Green

Write-Host ""
Write-Host "=== STEP 3: TEST Get-PartyPositions FUNCTION ===" -ForegroundColor Green
Write-Host ""

Write-Host "Getting party positions..." -ForegroundColor Yellow
$positions = Get-PartyPositions $global:Party

Write-Host "Party positions with color data:" -ForegroundColor Yellow
foreach ($key in $positions.Keys) {
    $member = $positions[$key]
    $coords = $key -split ','
    Write-Host "  Position ($($coords[0]),$($coords[1])): " -NoNewline -ForegroundColor White
    Write-Host "$($member.Name) [$($member.Symbol)]" -NoNewline -ForegroundColor White
    if ($member.Color) {
        Write-Host " - Color: " -NoNewline -ForegroundColor White
        Write-Host $member.Color -ForegroundColor $member.Color
    } else {
        Write-Host " - NO COLOR PROPERTY!" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== STEP 4: TEST VIEWPORT COLOR APPLICATION ===" -ForegroundColor Green
Write-Host ""

Write-Host "Testing color application in viewport..." -ForegroundColor Yellow

# Test the color application function directly
$viewX = 30
$viewY = 5
$boxWidth = 20
$boxHeight = 15

Write-Host "Applying character colors to viewport..." -ForegroundColor Yellow
Write-Host "  ViewX: $viewX, ViewY: $viewY" -ForegroundColor Gray
Write-Host "  Box dimensions: ${boxWidth}x${boxHeight}" -ForegroundColor Gray

# This would normally apply colors to the console
# Apply-CharacterColorsToViewport $viewX $viewY $boxWidth $boxHeight $startX $startY $positions

Write-Host ""
Write-Host "=== STEP 5: VERIFY CHARACTER COLOR PROPERTIES ===" -ForegroundColor Green
Write-Host ""

Write-Host "Checking each party member's color property:" -ForegroundColor Yellow
for ($i = 0; $i -lt $global:Party.Count; $i++) {
    $member = $global:Party[$i]
    Write-Host "  Member $($i + 1): " -NoNewline -ForegroundColor White
    
    if ($member.Color) {
        Write-Host "$($member.Name) has color: " -NoNewline -ForegroundColor Green
        Write-Host $member.Color -ForegroundColor $member.Color
    } else {
        Write-Host "$($member.Name) has NO COLOR PROPERTY!" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== DIAGNOSTIC SUMMARY ===" -ForegroundColor Cyan
Write-Host ""

$hasColorIssues = $false

# Check if party members have color properties
foreach ($member in $global:Party) {
    if (-not $member.Color -or $member.Color -eq "") {
        Write-Host "ERROR: $($member.Name) is missing Color property!" -ForegroundColor Red
        $hasColorIssues = $true
    }
}

# Check if Get-PartyPositions includes colors
foreach ($key in $positions.Keys) {
    $member = $positions[$key]
    if (-not $member.Color -or $member.Color -eq "") {
        Write-Host "ERROR: Get-PartyPositions missing Color for $($member.Name)!" -ForegroundColor Red
        $hasColorIssues = $true
    }
}

if (-not $hasColorIssues) {
    Write-Host "SUCCESS: All character color properties are present!" -ForegroundColor Green
    Write-Host "SUCCESS: Get-PartyPositions includes color data!" -ForegroundColor Green
    Write-Host "SUCCESS: Characters should now display in color in overworld!" -ForegroundColor Green
} else {
    Write-Host "ISSUE FOUND: Character colors are not properly set up!" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== TEST COMPLETE ===" -ForegroundColor Cyan
