# Test Multi-Enemy Battle System
# Simple test to verify the new multi-enemy battle functionality

Write-Host "Testing Multi-Enemy Battle System..." -ForegroundColor Cyan

# Import required files
. "$PSScriptRoot\PartySystem.ps1"
. "$PSScriptRoot\Player.ps1"
. "$PSScriptRoot\Enemies.ps1"

# Initialize test environment
Write-Host "Initializing party and battle system..." -ForegroundColor Yellow

# Initialize party
$global:Party = New-DefaultParty

Write-Host "`nTest Configuration:" -ForegroundColor Green
Write-Host "- Multi-enemy battles (1-3 enemies)" -ForegroundColor White
Write-Host "- Simple enemy AI (50% spell chance)" -ForegroundColor White
Write-Host "- Target selection for attacks and spells" -ForegroundColor White
Write-Host "- Obliterate spell available (1 MP, 1000 damage)" -ForegroundColor White
Write-Host "`nTo test the multi-enemy system:" -ForegroundColor Yellow
Write-Host "1. Run the main Display.ps1 file" -ForegroundColor White  
Write-Host "2. Move around until you encounter enemies" -ForegroundColor White
Write-Host "3. You should now face 1-3 enemies at once" -ForegroundColor White
Write-Host "4. Use 'A' for Attack (will show target selection if multiple enemies)" -ForegroundColor White
Write-Host "5. Use 'S' for Spells (attack spells will show target selection)" -ForegroundColor White
Write-Host "6. Try the 'Obliterate' spell to instantly kill enemies for testing" -ForegroundColor White
Write-Host "`nMulti-Enemy Battle System successfully initialized!" -ForegroundColor Green
