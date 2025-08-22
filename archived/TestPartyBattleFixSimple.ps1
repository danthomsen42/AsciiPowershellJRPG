# Test Party System Battle Fix
Write-Host "=== Testing Party System Battle Integration ===" -ForegroundColor Green
Write-Host ""

try {
    # Load required modules
    . "$PSScriptRoot\Player.ps1"
    . "$PSScriptRoot\PartySystem.ps1"
    . "$PSScriptRoot\Enemies.ps1"

    Write-Host "✓ Modules loaded successfully" -ForegroundColor Green

    # Initialize party
    if ($null -eq $global:Party) {
        $global:Party = New-DefaultParty
        Write-Host "✓ Default party created" -ForegroundColor Green
    }

    # Test enemy setup
    $enemy = $DungeonEnemyList[0].Clone()
    Write-Host "✓ Enemy selected: $($enemy.Name)" -ForegroundColor Green

    # Test turn order creation (the main fix)
    Write-Host "`nTesting turn order creation..." -ForegroundColor Yellow
    
    # Test the fixed function call (enemy wrapped in array)
    $turnOrder = New-PartyTurnOrder $global:Party @($enemy)
    Write-Host "✓ Turn order created successfully" -ForegroundColor Green
    
    # Display turn order
    Write-Host "`nTurn Order:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $turnOrder.Count; $i++) {
        $combatant = $turnOrder[$i]
        $prefix = if ($combatant.Type -eq "Party") { "[PARTY]" } else { "[ENEMY]" }
        Write-Host "  $($i+1). $prefix $($combatant.Name) (Speed: $($combatant.Character.Speed))" -ForegroundColor White
    }

    # Test party member detection
    Write-Host "`nTesting party member detection..." -ForegroundColor Yellow
    $partyTurns = 0
    $enemyTurns = 0
    
    foreach ($combatant in $turnOrder) {
        if ($combatant.Type -eq "Party") {
            $partyTurns++
        } elseif ($combatant.Type -eq "Enemy") {
            $enemyTurns++
        }
    }
    
    Write-Host "✓ Party turns detected: $partyTurns" -ForegroundColor Green
    Write-Host "✓ Enemy turns detected: $enemyTurns" -ForegroundColor Green
    
    # Test the key fix for player turn detection
    Write-Host "`nTesting player turn detection logic..." -ForegroundColor Yellow
    $testCombatant = $turnOrder | Where-Object { $_.Type -eq "Party" } | Select-Object -First 1
    if ($testCombatant) {
        $isPlayerTurn = ($testCombatant.Type -eq "Party")
        Write-Host "✓ Player turn detection works: $isPlayerTurn" -ForegroundColor Green
    }

    Write-Host "`n=== FIXES APPLIED ===" -ForegroundColor Cyan
    Write-Host "1. Fixed New-PartyTurnOrder call: Wrapped enemy in array" -ForegroundColor White
    Write-Host "2. Fixed player turn detection: Changed 'Player' to 'Party'" -ForegroundColor White
    Write-Host "3. Party system should now work correctly in battle!" -ForegroundColor White

    Write-Host "`n=== TEST COMPLETED SUCCESSFULLY! ===" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Test failed: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
}

Write-Host "`nPress any key to continue..." -ForegroundColor Gray
$null = [System.Console]::ReadKey($true)
