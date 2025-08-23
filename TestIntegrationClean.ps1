# Complete Character Creation Integration Test
Write-Host "=== CHARACTER CREATION INTEGRATION VERIFICATION ===" -ForegroundColor Cyan

# Load all required systems
. ".\CharacterCreation.ps1"
. ".\PartySystem.ps1"
. ".\ViewportRenderer.ps1"

Write-Host "`n1. Testing Character Creation Functions..." -ForegroundColor Yellow

# Test New-DefaultParty
Write-Host "   Creating default party..."
$defaultParty = New-DefaultParty

Write-Host "   Default Party Members:"
for ($i = 0; $i -lt $defaultParty.Count; $i++) {
    $member = $defaultParty[$i]
    Write-Host "   [$i] $($member.Name) - $($member.Class) [$($member.MapSymbol)]"
}

Write-Host "`n2. Testing Party Initialization..." -ForegroundColor Yellow
Initialize-PartyFromCreation -CreatedParty $defaultParty

Write-Host "`n3. Testing Global Variable Setup..." -ForegroundColor Yellow
Write-Host "   global:Player exists: $(if($global:Player){'YES'}else{'NO'})"
Write-Host "   global:Party exists: $(if($global:Party){'YES'}else{'NO'})" 
Write-Host "   global:PartyMembers exists: $(if($global:PartyMembers){'YES'}else{'NO'})"
Write-Host "   global:PartyTrail exists: $(if($global:PartyTrail){'YES'}else{'NO'})"
Write-Host "   global:PartyFormation exists: $(if($global:PartyFormation){'YES'}else{'NO'})"

if ($global:Player) {
    Write-Host "   Player Name: $($global:Player.Name)"
    Write-Host "   Player Class: $($global:Player.Class)"
    Write-Host "   Player Position: ($($global:Player.Position.X),$($global:Player.Position.Y))"
}

Write-Host "`n4. Testing ViewportRenderer Integration..." -ForegroundColor Yellow
if ($global:Party) {
    $positions = Get-PartyPositions -Party $global:Party
    Write-Host "   Party positions available: $($positions.Keys.Count)"
    
    foreach ($key in $positions.Keys) {
        $member = $positions[$key]
        Write-Host "   Position ${key}: $($member.Name) [$($member.Symbol)]"
    }
} else {
    Write-Host "   ERROR: No global party found!" -ForegroundColor Red
}

Write-Host "`n5. Testing Display.ps1 Integration..." -ForegroundColor Yellow

# Check if Display.ps1 conditional loading would work
if ($global:Player -and $global:Party) {
    Write-Host "   SUCCESS: Conditional loading will work - custom party detected"
    Write-Host "   SUCCESS: Display.ps1 will NOT overwrite Player.ps1"
    Write-Host "   SUCCESS: Display.ps1 will NOT overwrite default party"
} else {
    Write-Host "   ERROR: Conditional loading will fail - missing variables" -ForegroundColor Red
}

Write-Host "`n6. Summary:" -ForegroundColor Green
Write-Host "   Character Creation: $(if($defaultParty.Count -eq 4){'PASS'}else{'FAIL'})"
Write-Host "   Party Positioning: $(if($global:PartyTrail.Count -eq 8){'PASS'}else{'FAIL'})" 
Write-Host "   Global Variables: $(if($global:Player -and $global:Party){'PASS'}else{'FAIL'})"
Write-Host "   ViewportRenderer: $(if($positions.Keys.Count -eq 4){'PASS'}else{'FAIL'})"

if ($defaultParty.Count -eq 4 -and $global:PartyTrail.Count -eq 8 -and $global:Player -and $global:Party -and $positions.Keys.Count -eq 4) {
    Write-Host "`nINTEGRATION TEST PASSED! Character creation is ready!" -ForegroundColor Green
} else {
    Write-Host "`nINTEGRATION TEST FAILED! Issues found." -ForegroundColor Red
}

Write-Host "`n=== TEST COMPLETED ===" -ForegroundColor Cyan
