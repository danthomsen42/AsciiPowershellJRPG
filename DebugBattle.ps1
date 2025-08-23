# Debug Battle System Turn Order
Write-Host "=== BATTLE SYSTEM DEBUG ===" -ForegroundColor Cyan

# Load required systems
. ".\CharacterCreation.ps1"
. ".\NewEnemies.ps1"

# Create a test party
$testParty = New-DefaultParty
Initialize-PartyFromCreation -CreatedParty $testParty

# Create test enemies from the available enemy data
$testEnemies = @()
$testEnemies += $Goblin.Clone()  # Use the hashtable directly

Write-Host "`nCreated Test Scenario:" -ForegroundColor Yellow
Write-Host "Party Members:"
for ($i = 0; $i -lt $testParty.Count; $i++) {
    $member = $testParty[$i]
    Write-Host "  [$i] $($member.Name) - HP: $($member.HP)/$($member.MaxHP), Speed: $($member.Speed)"
}

Write-Host "Enemies:"
for ($i = 0; $i -lt $testEnemies.Count; $i++) {
    $enemy = $testEnemies[$i]
    Write-Host "  [$i] $($enemy.Name) - HP: $($enemy.HP)/$($enemy.MaxHP), Speed: $($enemy.Speed)"
}

Write-Host "`nTesting Turn Order Creation..." -ForegroundColor Yellow
$turnOrder = New-PartyTurnOrder $testParty $testEnemies

if ($turnOrder -and $turnOrder.Count -gt 0) {
    Write-Host "Turn Order Created Successfully:"
    for ($i = 0; $i -lt $turnOrder.Count; $i++) {
        $combatant = $turnOrder[$i]
        Write-Host "  [$i] $($combatant.Character.Name) ($($combatant.Type)) - Speed: $($combatant.Character.Speed)"
    }
} else {
    Write-Host "ERROR: Turn Order Creation Failed!" -ForegroundColor Red
    Write-Host "Turn Order: $turnOrder"
    Write-Host "Turn Order Count: $($turnOrder.Count)"
}

Write-Host "`nTesting Turn Advancement..." -ForegroundColor Yellow
if ($turnOrder -and $turnOrder.Count -gt 0) {
    $currentTurnIndex = 0
    $maxTurns = 10 # Safety limit
    
    for ($turn = 1; $turn -le $maxTurns; $turn++) {
        $currentCombatant = $turnOrder[$currentTurnIndex]
        Write-Host "Turn $turn - Index: $currentTurnIndex - $($currentCombatant.Character.Name) ($($currentCombatant.Type))"
        
        # Simulate turn advancement like in Display.ps1
        $currentTurnIndex = ($currentTurnIndex + 1) % $turnOrder.Count
        
        # Check if we're cycling properly
        if ($turn -gt 1 -and $currentTurnIndex -eq 0) {
            Write-Host "   -> Completed full cycle, back to start" -ForegroundColor Green
        }
    }
} else {
    Write-Host "Cannot test turn advancement - no valid turn order" -ForegroundColor Red
}

Write-Host "`n=== BATTLE SYSTEM DIAGNOSIS ===" -ForegroundColor Yellow

# Test critical battle functions
Write-Host "Testing Get-AlivePartyMembers..."
$aliveMembers = Get-AlivePartyMembers $testParty
Write-Host "Alive party members: $($aliveMembers.Count)"

Write-Host "Testing enemy alive check..."
$aliveEnemies = @()
foreach ($enemy in $testEnemies) {
    if ($enemy.HP -gt 0) {
        $aliveEnemies += $enemy
    }
}
Write-Host "Alive enemies: $($aliveEnemies.Count)"

# Potential loop conditions
if ($aliveMembers.Count -eq 0) {
    Write-Host "CRITICAL: No alive party members - battle should end with defeat" -ForegroundColor Red
}
if ($aliveEnemies.Count -eq 0) {
    Write-Host "CRITICAL: No alive enemies - battle should end with victory" -ForegroundColor Red
}
if ($aliveMembers.Count -gt 0 -and $aliveEnemies.Count -gt 0) {
    Write-Host "NORMAL: Both sides have living combatants - battle continues" -ForegroundColor Green
}

Write-Host "`n=== DEBUG COMPLETED ===" -ForegroundColor Cyan
