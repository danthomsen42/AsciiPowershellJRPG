# Level Up System Test Script
# Demonstrates the enhanced level-up functionality

Write-Host "=== LEVEL UP SYSTEM TEST ===" -ForegroundColor Yellow
Write-Host ""

# Load required systems
. "$PSScriptRoot\PartySystem.ps1"
. "$PSScriptRoot\LevelUpSystem.ps1"

# Create a test party
Write-Host "Creating test party..." -ForegroundColor Cyan
$global:Party = @(
    (New-PartyMember "Gareth" "Warrior" 1),
    (New-PartyMember "Mystara" "Mage" 1),
    (New-PartyMember "Celeste" "Healer" 1),
    (New-PartyMember "Raven" "Rogue" 1)
)

# Initialize XP systems for all party members
Initialize-PartyXP $global:Party

Write-Host "Initial party status:" -ForegroundColor Green
foreach ($member in $global:Party) {
    Write-Host "  $($member.Name) - Level $($member.Level) ($($member.XP) XP)" -ForegroundColor White
}
Write-Host ""

# Test small XP gain (no level up)
Write-Host "1. Testing small XP gain (50 XP)..." -ForegroundColor Yellow
Add-PartyXP $global:Party 50

# Test larger XP gain (should level up)
Write-Host "2. Testing large XP gain (200 XP)..." -ForegroundColor Yellow
Add-PartyXP $global:Party 200

# Test massive XP gain (multiple levels)
Write-Host "3. Testing massive XP gain (1000 XP)..." -ForegroundColor Yellow
Add-PartyXP $global:Party 1000

# Show final party status
Write-Host "Final party status:" -ForegroundColor Green
foreach ($member in $global:Party) {
    $nextLevel = Get-XPRequiredForLevel ($member.Level + 1)
    $progress = Get-XPProgressPercent $member.Level $member.XP
    Write-Host "  $($member.Name) - Level $($member.Level) ($($member.XP)/$nextLevel XP - $progress%)" -ForegroundColor White
    Write-Host "    Stats: HP $($member.MaxHP), MP $($member.MaxMP), ATK $($member.Attack), DEF $($member.Defense), SPD $($member.Speed)" -ForegroundColor Gray
    if ($member.Spells.Count -gt 0) {
        Write-Host "    Spells: $($member.Spells -join ', ')" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "=== TEST COMPLETE ===" -ForegroundColor Yellow
Write-Host "The level-up system is now fully integrated!" -ForegroundColor Green
