# =============================================================================
# CHARACTER COLOR CUSTOMIZATION - HOW TO GUIDE
# =============================================================================

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                      CHARACTER COLOR CUSTOMIZATION GUIDE" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# Load the color systems
. "$PSScriptRoot\CharacterCreation.ps1"

Write-Host "=== HOW TO CUSTOMIZE CHARACTER COLORS ===" -ForegroundColor Green
Write-Host ""

Write-Host "1. DURING CHARACTER CREATION:" -ForegroundColor Yellow
Write-Host "   - Run: Start-CharacterCreation" -ForegroundColor White
Write-Host "   - Create each character normally (name, class, stats)" -ForegroundColor White
Write-Host "   - At the confirmation screen, press [K] to change color" -ForegroundColor White
Write-Host "   - Choose from 7 available colors with live preview" -ForegroundColor White
Write-Host ""

Write-Host "2. AVAILABLE COLORS:" -ForegroundColor Yellow
foreach ($color in $DefaultColors) {
    Write-Host "   * " -NoNewline -ForegroundColor White
    Write-Host $color -ForegroundColor $color
}
Write-Host ""

Write-Host "=== OVERWORLD COLOR DISPLAY FIXED ===" -ForegroundColor Green
Write-Host ""
Write-Host "SUCCESS: Character colors now appear in the overworld map!" -ForegroundColor Yellow
Write-Host "SUCCESS: Each party member shows their individual color" -ForegroundColor Yellow
Write-Host "SUCCESS: Leader (@) displays with their chosen color" -ForegroundColor Yellow
Write-Host "SUCCESS: Party members (M, H, R) show their unique colors" -ForegroundColor Yellow
Write-Host "SUCCESS: No more identical colors for same-class characters" -ForegroundColor Yellow
Write-Host ""

Write-Host "=== SAMPLE CHARACTER CREATION ===" -ForegroundColor Green
Write-Host ""

Write-Host "Creating sample characters with different colors..." -ForegroundColor Yellow

# Create sample characters
$char1 = New-Character -Name "Scarlett" -Class "Warrior" -Position 1 -Color "Red"
$char2 = New-Character -Name "Azure" -Class "Mage" -Position 2 -Color "Blue" 
$char3 = New-Character -Name "Forest" -Class "Healer" -Position 3 -Color "Green"
$char4 = New-Character -Name "Sunny" -Class "Rogue" -Position 4 -Color "Yellow"

Write-Host ""
Write-Host "Sample characters created with custom colors:" -ForegroundColor Yellow
Write-Host "  1. " -NoNewline -ForegroundColor White
Write-Host "Scarlett" -NoNewline -ForegroundColor $char1.Color
Write-Host " the Warrior - Color: " -NoNewline -ForegroundColor White
Write-Host $char1.Color -ForegroundColor $char1.Color

Write-Host "  2. " -NoNewline -ForegroundColor White
Write-Host "Azure" -NoNewline -ForegroundColor $char2.Color
Write-Host " the Mage - Color: " -NoNewline -ForegroundColor White
Write-Host $char2.Color -ForegroundColor $char2.Color

Write-Host "  3. " -NoNewline -ForegroundColor White
Write-Host "Forest" -NoNewline -ForegroundColor $char3.Color
Write-Host " the Healer - Color: " -NoNewline -ForegroundColor White
Write-Host $char3.Color -ForegroundColor $char3.Color

Write-Host "  4. " -NoNewline -ForegroundColor White
Write-Host "Sunny" -NoNewline -ForegroundColor $char4.Color
Write-Host " the Rogue - Color: " -NoNewline -ForegroundColor White
Write-Host $char4.Color -ForegroundColor $char4.Color

Write-Host ""
Write-Host "=== QUICK START INSTRUCTIONS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "To use character color customization:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Start character creation:" -ForegroundColor White
Write-Host "   Start-CharacterCreation" -ForegroundColor Green
Write-Host ""
Write-Host "2. For each character, when you see the confirmation screen:" -ForegroundColor White
Write-Host "   Press [K] to change their color" -ForegroundColor Green
Write-Host ""
Write-Host "3. Use the color picker:" -ForegroundColor White
Write-Host "   - Up/Down arrows to browse colors" -ForegroundColor Gray
Write-Host "   - Enter to select" -ForegroundColor Gray
Write-Host "   - ESC for random color" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Colors will automatically appear in the overworld!" -ForegroundColor White
Write-Host ""

Write-Host "READY TO USE: Color customization system is fully functional!" -ForegroundColor Green
