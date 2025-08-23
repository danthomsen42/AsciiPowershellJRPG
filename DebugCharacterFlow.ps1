# Debug Character Creation Flow
Write-Host "=== DEBUGGING CHARACTER CREATION FLOW ===" -ForegroundColor Cyan

# Load character creation system
. ".\CharacterCreation.ps1"

Write-Host "`n1. Testing Start-CharacterCreation..." -ForegroundColor Yellow
Write-Host "   (This will simulate the full character creation process)"

# Test character creation - create 4 warriors as mentioned by user
Write-Host "`nCreating a party of 4 Warriors..." -ForegroundColor Green

# Simulate the character creation process
$testParty = @()
for ($i = 0; $i -lt 4; $i++) {
    $warrior = New-Character -Name "Warrior$($i+1)" -Class "Warrior" -Position ($i + 1)
    $testParty += $warrior
}

Write-Host "Created party members:"
for ($i = 0; $i -lt $testParty.Count; $i++) {
    $member = $testParty[$i]
    Write-Host "   [$i] $($member.Name) - $($member.Class) [$($member.MapSymbol)]"
}

Write-Host "`n2. Testing Initialize-PartyFromCreation..." -ForegroundColor Yellow
Initialize-PartyFromCreation -CreatedParty $testParty

Write-Host "`n3. Testing Global Variables Before Display.ps1..." -ForegroundColor Yellow
Write-Host "   global:Player exists: $(if($global:Player){'YES - ' + $global:Player.Name + ' (' + $global:Player.Class + ')'}else{'NO'})"
Write-Host "   global:Party exists: $(if($global:Party){'YES - ' + $global:Party.Count + ' members'}else{'NO'})"
Write-Host "   global:PartyMembers exists: $(if($global:PartyMembers){'YES - ' + $global:PartyMembers.Count + ' members'}else{'NO'})"

if ($global:Party) {
    Write-Host "   Party composition:"
    for ($i = 0; $i -lt $global:Party.Count; $i++) {
        $member = $global:Party[$i]
        Write-Host "     [$i] $($member.Name) - $($member.Class) [$($member.MapSymbol)] @ ($($member.Position.X),$($member.Position.Y))"
    }
}

Write-Host "`n4. Simulating Display.ps1 Loading..." -ForegroundColor Yellow
Write-Host "   Loading PartySystem.ps1..."
. ".\PartySystem.ps1"

Write-Host "`n5. Testing Party State After PartySystem Load..." -ForegroundColor Yellow
Write-Host "   global:Party still exists: $(if($global:Party){'YES - ' + $global:Party.Count + ' members'}else{'NO - LOST!'})"

if ($global:Party) {
    Write-Host "   Party still contains warriors:"
    for ($i = 0; $i -lt $global:Party.Count; $i++) {
        $member = $global:Party[$i]
        Write-Host "     [$i] $($member.Name) - $($member.Class) [$($member.MapSymbol)]"
    }
} else {
    Write-Host "   ERROR: Party was lost!" -ForegroundColor Red
}

Write-Host "`n6. Testing Display.ps1 Party Logic..." -ForegroundColor Yellow

# Simulate Display.ps1 party initialization logic
if (-not $global:Party) {
    Write-Host "   Display.ps1 would create NEW DEFAULT PARTY (PROBLEM!)" -ForegroundColor Red
    $global:Party = New-DefaultParty
    Write-Host "   Default party created - this is the bug!"
} else {
    Write-Host "   Display.ps1 would PRESERVE custom party (GOOD!)" -ForegroundColor Green
}

Write-Host "`n7. Final Party State:" -ForegroundColor Yellow
if ($global:Party) {
    for ($i = 0; $i -lt $global:Party.Count; $i++) {
        $member = $global:Party[$i]
        Write-Host "   [$i] $($member.Name) - $($member.Class) [$($member.MapSymbol)]"
    }
}

Write-Host "`n=== DEBUG COMPLETED ===" -ForegroundColor Cyan
