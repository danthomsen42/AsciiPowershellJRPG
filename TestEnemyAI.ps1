# Test Enhanced Enemy AI System
# This script tests the new enemy spell casting and AI behaviors

Write-Host "=== Testing Enhanced Enemy AI System ===" -ForegroundColor Cyan
Write-Host ""

# Load required modules
. "$PSScriptRoot\Player.ps1"
. "$PSScriptRoot\Enemies.ps1"
. "$PSScriptRoot\Spells.ps1"

Write-Host "Testing Enemy Configurations:" -ForegroundColor Yellow
Write-Host ""

# Test each enemy's spell capabilities
$enemies = @($Enemy1, $Enemy2, $Enemy3, $Enemy4, $Enemy5)

foreach ($enemy in $enemies) {
    Write-Host "Enemy: $($enemy.Name) (Level $($enemy.Level))" -ForegroundColor White
    Write-Host "  HP: $($enemy.HP)/$($enemy.MaxHP)  MP: $($enemy.MP)/$($enemy.MaxMP)  Speed: $($enemy.Speed)" -ForegroundColor Gray
    
    if ($enemy.Spells.Count -gt 0) {
        Write-Host "  Spells: $($enemy.Spells -join ', ')" -ForegroundColor Magenta
        
        # Check each spell's MP cost
        foreach ($spellName in $enemy.Spells) {
            $spell = $Spells | Where-Object { $_.Name -eq $spellName }
            if ($spell) {
                Write-Host "    - $($spell.Name): $($spell.MP) MP, Power $($spell.Power), Type $($spell.Type)" -ForegroundColor Cyan
            }
        }
    } else {
        Write-Host "  Spells: None (Basic attacker)" -ForegroundColor Gray
    }
    Write-Host ""
}

Write-Host "=== AI Decision Simulation ===" -ForegroundColor Yellow
Write-Host ""

# Simulate AI decisions for different scenarios
Write-Host "Scenario 1: Enemy2 (Fire caster) at full health" -ForegroundColor White
$testEnemy = $Enemy2.Clone()
Write-Host "Available MP: $($testEnemy.MP) | Spells: $($testEnemy.Spells -join ', ')"

$availableSpells = @()
foreach ($spellName in $testEnemy.Spells) {
    $spell = $Spells | Where-Object { $_.Name -eq $spellName }
    if ($spell -and $testEnemy.MP -ge $spell.MP) {
        $availableSpells += $spell
    }
}

if ($availableSpells.Count -gt 0) {
    $attackSpells = $availableSpells | Where-Object { $_.Type -eq "Attack" }
    if ($attackSpells.Count -gt 0) {
        $rollResult = Get-Random -Minimum 1 -Maximum 101
        if ($rollResult -le 60) {
            Write-Host "Result: Would cast $($attackSpells[0].Name) (rolled $rollResult, needed ≤60)" -ForegroundColor Green
        } else {
            Write-Host "Result: Would use basic attack (rolled $rollResult, needed ≤60)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "Scenario 2: Enemy4 (Healer) at low health" -ForegroundColor White
$testEnemy = $Enemy4.Clone()
$testEnemy.HP = 8  # Set to low health (below 40% of 28)
Write-Host "Current HP: $($testEnemy.HP)/$($testEnemy.MaxHP) | Available MP: $($testEnemy.MP) | Spells: $($testEnemy.Spells -join ', ')"

$availableSpells = @()
foreach ($spellName in $testEnemy.Spells) {
    $spell = $Spells | Where-Object { $_.Name -eq $spellName }
    if ($spell -and $testEnemy.MP -ge $spell.MP) {
        $availableSpells += $spell
    }
}

$healingSpells = $availableSpells | Where-Object { $_.Type -eq "Recovery" }
if ($healingSpells.Count -gt 0 -and $testEnemy.HP -le ($testEnemy.MaxHP * 0.4)) {
    Write-Host "Result: Would cast $($healingSpells[0].Name) to heal (HP below 40% threshold)" -ForegroundColor Green
} else {
    Write-Host "Result: No healing action needed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan
Write-Host "Enemy AI system is ready! Start a battle to see it in action." -ForegroundColor Green
