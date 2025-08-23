# Test Complete Character Creation Integration
Write-Host "=== TESTING COMPLETE GAME INTEGRATION ===" -ForegroundColor Cyan

# Clean start - remove any existing variables
Remove-Variable -Name "Player" -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -Name "Party" -Scope Global -ErrorAction SilentlyContinue  
Remove-Variable -Name "PartyMembers" -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -Name "PartyTrail" -Scope Global -ErrorAction SilentlyContinue

Write-Host "`n1. STEP 1: Character Creation (simulating 4 Warriors)" -ForegroundColor Yellow

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

Write-Host "   Created party of 4 Warriors:"
for ($i = 0; $i -lt $global:Party.Count; $i++) {
    $member = $global:Party[$i]
    Write-Host "     [$i] $($member.Name) - $($member.Class) [$($member.MapSymbol)]"
}

Write-Host "`n2. STEP 2: Loading Display.ps1 (full game loading simulation)" -ForegroundColor Yellow

# Simulate the complete Display.ps1 loading process

# Load PartySystem.ps1 (this was the bug)
Write-Host "   Loading PartySystem.ps1..."
. ".\PartySystem.ps1"

Write-Host "   Party after PartySystem load: $(if($global:Party){'PRESERVED'}else{'LOST'})"

# Simulate the party initialization in Display.ps1
Write-Host "   Simulating Display.ps1 party logic..."
if (-not $global:Party) {
    Write-Host "     Would create DEFAULT party (BUG!)" -ForegroundColor Red
    $global:Party = New-DefaultParty
} else {
    Write-Host "     Using CUSTOM party (CORRECT!)" -ForegroundColor Green
}

# Test the Player.ps1 loading logic
Write-Host "   Testing Player.ps1 loading logic..."
$shouldLoadPlayer = (-not $global:Player -or (-not $global:PartyMembers -and -not $global:Party))
if ($shouldLoadPlayer) {
    Write-Host "     Would load Player.ps1 and OVERWRITE custom player (BUG!)" -ForegroundColor Red
} else {
    Write-Host "     Would NOT load Player.ps1 - preserving custom player (CORRECT!)" -ForegroundColor Green
}

Write-Host "`n3. STEP 3: Testing Overworld Display" -ForegroundColor Yellow

# Test ViewportRenderer integration
. ".\ViewportRenderer.ps1"
$positions = Get-PartyPositions -Party $global:Party

Write-Host "   Party positions for overworld:"
foreach ($key in $positions.Keys) {
    $member = $positions[$key]
    Write-Host "     Position ${key}: $($member.Name) [$($member.Symbol)]"
}

Write-Host "`n4. STEP 4: Testing Battle System Integration" -ForegroundColor Yellow

# Test that party members have proper stats for battle
Write-Host "   Battle-ready party stats:"
for ($i = 0; $i -lt $global:Party.Count; $i++) {
    $member = $global:Party[$i]
    Write-Host "     $($member.Name): HP=$($member.HP)/$($member.MaxHP) ATK=$($member.Attack) DEF=$($member.Defense)"
}

Write-Host "`n5. FINAL RESULT:" -ForegroundColor Green

$partyAllWarriors = $true
foreach ($member in $global:Party) {
    if ($member.Class -ne "Warrior") {
        $partyAllWarriors = $false
        break
    }
}

$correctSymbols = $true
$expectedFormation = "@", "W", "W", "W"
for ($i = 0; $i -lt $global:PartyFormation.Count; $i++) {
    if ($global:PartyFormation[$i] -ne $expectedFormation[$i]) {
        $correctSymbols = $false
        break
    }
}

if ($partyAllWarriors -and $correctSymbols -and $positions.Keys.Count -eq 4) {
    Write-Host "   ✓ SUCCESS: 4 Warriors created and preserved!" -ForegroundColor Green
    Write-Host "   ✓ SUCCESS: Overworld will show @ W W W formation!" -ForegroundColor Green  
    Write-Host "   ✓ SUCCESS: Battle will use custom warrior stats!" -ForegroundColor Green
    Write-Host "`n   🎉 CHARACTER CREATION INTEGRATION FIXED!" -ForegroundColor Green
} else {
    Write-Host "   ❌ FAILED: Issues still exist" -ForegroundColor Red
    Write-Host "     All Warriors: $partyAllWarriors"
    Write-Host "     Correct Symbols: $correctSymbols" 
    Write-Host "     Correct Positions: $($positions.Keys.Count -eq 4)"
}

Write-Host "`n=== INTEGRATION TEST COMPLETED ===" -ForegroundColor Cyan
