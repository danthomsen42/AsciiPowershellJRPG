# =============================================================================
# ENHANCED BATTLE SYSTEM TEST
# =============================================================================
# Test the new enemy sizes and battle layouts

Write-Host "=== ENHANCED BATTLE SYSTEM TEST ===" -ForegroundColor Green
Write-Host ""

# Load the new systems
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1"

# Test different battle scenarios
$testScenarios = @(
    @{
        Name = "Small Swarm"
        Enemies = @($Goblin.Clone(), $Rat.Clone(), $Slime.Clone(), $Imp.Clone())
    },
    @{
        Name = "Medium Pair" 
        Enemies = @($Orc.Clone(), $Skeleton.Clone())
    },
    @{
        Name = "Mixed Battle"
        Enemies = @($Goblin.Clone(), $Orc.Clone(), $Slime.Clone())
    },
    @{
        Name = "Large Enemy"
        Enemies = @($Troll.Clone())
    },
    @{
        Name = "Boss Encounter"
        Enemies = @($DragonBoss.Clone())
    },
    @{
        Name = "Large + Support"
        Enemies = @($Minotaur.Clone(), $Imp.Clone(), $Rat.Clone())
    }
)

foreach ($scenario in $testScenarios) {
    Write-Host "=== $($scenario.Name) ===" -ForegroundColor Yellow
    Write-Host "Enemies: " -NoNewline
    foreach ($enemy in $scenario.Enemies) {
        Write-Host "$($enemy.Name) ($($enemy.Size)) " -NoNewline -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "Press any key to see this battle layout..."
    $null = [System.Console]::ReadKey($true)
    [System.Console]::Clear()
    
    # Simulate the battle display
    Draw-EnhancedCombatViewport $scenario.Enemies 80 25
    
    Write-Host ""
    Write-Host "Layout complete! Press any key for next scenario..." -ForegroundColor Green
    $null = [System.Console]::ReadKey($true)
    [System.Console]::Clear()
}

Write-Host "=== RANDOM ENCOUNTER TEST ===" -ForegroundColor Magenta
Write-Host "Testing the random encounter generator..."
Write-Host ""

for ($i = 1; $i -le 5; $i++) {
    $encounter = Get-RandomEnemyEncounter "Dungeon" $i
    Write-Host "Random Encounter #$i - Difficulty $i" -ForegroundColor Yellow
    Write-Host "Enemies: " -NoNewline
    foreach ($enemy in $encounter) {
        Write-Host "$($enemy.Name) ($($enemy.Size)) " -NoNewline -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "Press any key to see this encounter..."
    $null = [System.Console]::ReadKey($true)
    [System.Console]::Clear()
    
    Draw-EnhancedCombatViewport $encounter 80 25
    
    Write-Host ""
    Write-Host "Press any key for next encounter..." -ForegroundColor Green
    $null = [System.Console]::ReadKey($true)
    [System.Console]::Clear()
}

Write-Host "=== BATTLE SYSTEM TEST COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Summary of new features:" -ForegroundColor Yellow
Write-Host "✓ 4 enemy sizes: Small (15x5), Medium (25x8), Large (40x12), Boss (60x15)"
Write-Host "✓ Smart layout system adapts to enemy composition"
Write-Host "✓ 7 different encounter types with varied arrangements"
Write-Host "✓ Proper sprite positioning and spacing"
Write-Host "✓ Visual enemy status (alive/KO coloring)"
Write-Host ""
Write-Host "Ready to integrate into main battle system!" -ForegroundColor Green
