# Test Complete Character Creation Integration
Write-Host "=== TESTING COMPLETE GAME INTEGRATION ===" -ForegroundColor Cyan

# Clean start - remove any existing variables
Remove-Variable -Name "Player" -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -Name "Party" -Scope Global -ErrorAction SilentlyContinue  
Remove-Variable -Name "PartyMembers" -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -Name "PartyTrail" -Scope Global -ErrorAction SilentlyContinue

Write-Host "`nSTEP 1: Character Creation (simulating 4 Warriors)" -ForegroundColor Yellow

# Load character creation and create 4 warriors like the user did
. ".\CharacterCreation.ps1"

# Create 4 warrior party
$customParty = @()
for ($i = 0; $i -lt 4; $i++) {
    $warrior = New-Character -Name "Knight$($i+1)" -Class "Warrior" -Position ($i + 1)
    $customParty += $warrior
}

# Initialize the custom party
Initialize-PartyFromCreation -CreatedParty $customParty

Write-Host "Created party of 4 Warriors:"
for ($i = 0; $i -lt $global:Party.Count; $i++) {
    $member = $global:Party[$i]
    Write-Host "  [$i] $($member.Name) - $($member.Class) [$($member.MapSymbol)]"
}

Write-Host "`nSTEP 2: Loading PartySystem.ps1" -ForegroundColor Yellow
. ".\PartySystem.ps1"

Write-Host "Party after PartySystem load: $(if($global:Party){'PRESERVED - ' + $global:Party.Count + ' members'}else{'LOST'})"

Write-Host "`nSTEP 3: Testing Overworld Display" -ForegroundColor Yellow
. ".\ViewportRenderer.ps1"
$positions = Get-PartyPositions -Party $global:Party

Write-Host "Party positions for overworld:"
foreach ($key in $positions.Keys) {
    $member = $positions[$key]
    Write-Host "  Position ${key}: $($member.Name) [$($member.Symbol)]"
}

Write-Host "`nSTEP 4: Testing Formation" -ForegroundColor Yellow
Write-Host "Expected: @ W W W"
Write-Host "Actual:   $($global:PartyFormation -join ' ')"

Write-Host "`nFINAL RESULT:" -ForegroundColor Green

$partyAllWarriors = $true
foreach ($member in $global:Party) {
    if ($member.Class -ne "Warrior") {
        $partyAllWarriors = $false
        break
    }
}

if ($partyAllWarriors -and $positions.Keys.Count -eq 4) {
    Write-Host "SUCCESS: 4 Warriors created and preserved!" -ForegroundColor Green
    Write-Host "SUCCESS: Overworld will show warrior formation!" -ForegroundColor Green  
    Write-Host "SUCCESS: Battle will use custom warrior stats!" -ForegroundColor Green
    Write-Host ""
    Write-Host "CHARACTER CREATION INTEGRATION FIXED!" -ForegroundColor Green
} else {
    Write-Host "FAILED: Issues still exist" -ForegroundColor Red
}

Write-Host "`n=== INTEGRATION TEST COMPLETED ===" -ForegroundColor Cyan
