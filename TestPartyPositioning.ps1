# Test Party Positioning Fix
Write-Host "Testing Character Creation Party Positioning..." -ForegroundColor Cyan

# Load dependencies
. ".\CharacterCreation.ps1"
. ".\ViewportRenderer.ps1"
. ".\PartySystem.ps1"

# Use the simplified function approach
Write-Host "Creating test party using New-DefaultParty..." -ForegroundColor Yellow

$testParty = New-DefaultParty

Write-Host "`nInitializing party..." -ForegroundColor Yellow
Initialize-PartyFromCreation -CreatedParty $testParty

# Test party positioning
Write-Host "`n=== PARTY POSITIONING TEST ===" -ForegroundColor Cyan

Write-Host "`nParty Trail Status:" -ForegroundColor Yellow
if ($global:PartyTrail) {
    Write-Host "PartyTrail Count: $($global:PartyTrail.Count)"
    for ($i = 0; $i -lt [math]::Min(8, $global:PartyTrail.Count); $i++) {
        $pos = $global:PartyTrail[$i]
        Write-Host "Trail[$i]: ($($pos.X),$($pos.Y))"
    }
} else {
    Write-Host "PartyTrail: NOT SET" -ForegroundColor Red
}

Write-Host "`nParty Member Positions:" -ForegroundColor Yellow
for ($i = 0; $i -lt $testParty.Count; $i++) {
    $member = $testParty[$i]
    Write-Host "Member $i ($($member.Name)): ($($member.Position.X),$($member.Position.Y)) [$($member.MapSymbol)]"
}

Write-Host "`nGet-PartyPositions result:" -ForegroundColor Yellow
$positions = Get-PartyPositions -Party $testParty
Write-Host "PartyPositions keys: $($positions.Keys -join ', ')"
Write-Host "Position count: $($positions.Keys.Count)"

# Show details of each position
foreach ($key in $positions.Keys) {
    $memberInfo = $positions[$key]
    Write-Host "Position ${key}: $($memberInfo.Name) [$($memberInfo.Symbol)] (Leader: $($memberInfo.IsLeader))"
}

Write-Host "`nExpected formation: W -> M -> H -> R" -ForegroundColor Green
$actualFormation = @()
foreach ($member in $testParty) {
    $actualFormation += $member.MapSymbol
}
Write-Host "Actual formation: $($actualFormation -join ' -> ')" -ForegroundColor Green

Write-Host "`nTest completed!" -ForegroundColor Cyan
