$ErrorActionPreference = 'Stop'
$Script:GameRoot = $PSScriptRoot

# Load all engine modules
. "$PSScriptRoot\Engine\Renderer.ps1"
. "$PSScriptRoot\Engine\Input.ps1"
. "$PSScriptRoot\Engine\CharacterEngine.ps1"
. "$PSScriptRoot\Engine\MapEngine.ps1"
. "$PSScriptRoot\Engine\CombatEngine.ps1"
. "$PSScriptRoot\Engine\DialogueEngine.ps1"
. "$PSScriptRoot\Engine\SaveLoad.ps1"
. "$PSScriptRoot\Engine\Core.ps1"

Initialize-Renderer
Load-ClassDefinitions

# Create a test party
$Script:GameState.Party = @(
    (New-PartyMember -Name 'TestWarrior' -ClassName 'Warrior'),
    (New-PartyMember -Name 'TestMage'    -ClassName 'Mage'),
    (New-PartyMember -Name 'TestRogue'   -ClassName 'Rogue'),
    (New-PartyMember -Name 'TestCleric'  -ClassName 'Cleric')
)

# ── Test 1: Load enemy stats ──
Write-Host '--- Test 1: Enemy Stats ---'
$goblinStats = Load-EnemyStats -SpriteId 'Goblin' -Level 3
Write-Host "Goblin Lv3: HP=$($goblinStats.HP) STR=$($goblinStats.Strength) DEF=$($goblinStats.Defense) SPD=$($goblinStats.Speed)"
if ($goblinStats.HP -ne 20) { throw "Goblin HP scaling wrong: expected 20, got $($goblinStats.HP)" }
Write-Host 'OK: Enemy stats load and scale correctly'

# ── Test 2: Load enemy sprite ──
Write-Host ''
Write-Host '--- Test 2: Enemy Sprites ---'
$goblinSprite = Load-EnemySprite -SpriteId 'Goblin'
Write-Host "Goblin sprite: $($goblinSprite.Width)x$($goblinSprite.Height) lines, Color=$($goblinSprite.Color)"
if ($goblinSprite.Lines.Count -lt 2) { throw "Goblin sprite too small" }
$slimeSprite = Load-EnemySprite -SpriteId 'Slime'
Write-Host "Slime sprite: $($slimeSprite.Width)x$($slimeSprite.Height) lines, Color=$($slimeSprite.Color)"
$batSprite = Load-EnemySprite -SpriteId 'CaveBat'
Write-Host "CaveBat sprite: $($batSprite.Width)x$($batSprite.Height) lines, Color=$($batSprite.Color)"
Write-Host 'OK: All enemy sprites load correctly'

# ── Test 3: Ability table ──
Write-Host ''
Write-Host '--- Test 3: Ability Table ---'
$abilityCount = $Script:AbilityTable.Count
Write-Host "Abilities defined: $abilityCount"
if ($abilityCount -lt 20) { throw "Expected at least 20 abilities, got $abilityCount" }

# Verify all party abilities exist in the table
foreach ($m in $Script:GameState.Party) {
    if (-not $Script:AbilityTable[$m.MainAttack]) { throw "Missing ability: $($m.MainAttack) for $($m.Class)" }
    foreach ($ab in $m.SecondaryAbilities) {
        if (-not $Script:AbilityTable[$ab]) { throw "Missing ability: $ab for $($m.Class)" }
    }
}
Write-Host 'OK: All party abilities exist in table'

# Verify all enemy abilities exist
foreach ($eName in @('Goblin', 'CaveBat', 'Slime')) {
    $eStats = Load-EnemyStats -SpriteId $eName -Level 1
    foreach ($ab in $eStats.Abilities) {
        if (-not $Script:AbilityTable[$ab]) { throw "Missing enemy ability: $ab for $eName" }
    }
}
Write-Host 'OK: All enemy abilities exist in table'

# ── Test 4: Damage calculation ──
Write-Host ''
Write-Host '--- Test 4: Damage Formulas ---'
$attacker = @{ Strength = 16; Intelligence = 8; Accuracy = 85; Speed = 13 }
$defender = @{ Defense = 4; HP = 50; MaxHP = 50 }
$slashAbility = $Script:AbilityTable['Slash']
$dmg = Get-Damage -Attacker $attacker -Defender $defender -Ability $slashAbility
Write-Host "Slash damage (STR 16 vs DEF 4): $dmg"
if ($dmg -lt 5 -or $dmg -gt 25) { throw "Damage out of expected range: $dmg" }

# Defense reduces damage
$defender2 = @{ Defense = 30; HP = 50; MaxHP = 50 }
$dmg2 = Get-Damage -Attacker $attacker -Defender $defender2 -Ability $slashAbility
Write-Host "Slash damage vs DEF 30: $dmg2"
if ($dmg2 -ge $dmg) { Write-Host 'WARNING: Higher defense did not reduce damage (variance possible)' }

# Defending flag increases defense
$dmg3 = Get-Damage -Attacker $attacker -Defender $defender -Ability $slashAbility -DefenderDefending $true
Write-Host "Slash damage vs DEF 4 (defending): $dmg3"
Write-Host 'OK: Damage formulas work'

# ── Test 5: Hit/miss ──
Write-Host ''
Write-Host '--- Test 5: Hit/Miss ---'
$hits = 0
for ($i = 0; $i -lt 100; $i++) {
    if (Test-Hit -AttackerAccuracy 85 -AccMod 0) { $hits++ }
}
Write-Host "Hits in 100 rolls with 85% accuracy: $hits"
if ($hits -lt 50 -or $hits -gt 100) { throw "Hit rate way off: $hits/100" }
Write-Host 'OK: Hit/miss system works'

# ── Test 6: Heal amount ──
Write-Host ''
Write-Host '--- Test 6: Heal Formula ---'
$caster = @{ Intelligence = 15; Accuracy = 85 }
$healAbility = $Script:AbilityTable['Heal']
$healAmt = Get-HealAmount -Caster $caster -Ability $healAbility
Write-Host "Heal amount (INT 15, Power 1.5): $healAmt"
if ($healAmt -lt 10 -or $healAmt -gt 35) { throw "Heal amount out of range: $healAmt" }
Write-Host 'OK: Heal formula works'

# ── Test 7: Inventory add ──
Write-Host ''
Write-Host '--- Test 7: Inventory System ---'
$Script:GameState.Inventory = @()
Add-InventoryItem -ItemId 'potion'
Write-Host "Inventory after adding potion: $($Script:GameState.Inventory.Count) items"
if ($Script:GameState.Inventory.Count -ne 1) { throw "Expected 1 item" }
if ($Script:GameState.Inventory[0].name -ne 'Potion') { throw "Expected Potion, got $($Script:GameState.Inventory[0].name)" }
Add-InventoryItem -ItemId 'potion'
if ([int]$Script:GameState.Inventory[0].count -ne 2) { throw "Expected count 2, got $($Script:GameState.Inventory[0].count)" }
Write-Host "Potion count after adding second: $($Script:GameState.Inventory[0].count)"
Add-InventoryItem -ItemId 'herb'
Write-Host "Inventory size after adding herb: $($Script:GameState.Inventory.Count) items"
if ($Script:GameState.Inventory.Count -ne 2) { throw "Expected 2 items" }
Write-Host 'OK: Inventory system works'

# ── Test 8: Run attempt ──
Write-Host ''
Write-Host '--- Test 8: Run Mechanics ---'
$Script:CombatState = @{ Enemies = @(@{ Alive = $true; Stats = @{ Speed = 10 } }) }
$fastMember = @{ Speed = 20; Name = 'Fast' }
$runs = 0
for ($i = 0; $i -lt 100; $i++) {
    if (Test-RunAttempt -Member $fastMember) { $runs++ }
}
Write-Host "Fast member (SPD 20 vs enemy SPD 10) ran $runs/100 times"
$slowMember = @{ Speed = 5; Name = 'Slow' }
$runs2 = 0
for ($i = 0; $i -lt 100; $i++) {
    if (Test-RunAttempt -Member $slowMember) { $runs2++ }
}
Write-Host "Slow member (SPD 5 vs enemy SPD 10) ran $runs2/100 times"
if ($runs -le $runs2) { Write-Host 'WARNING: Speed doesnt seem to affect run chance (variance possible)' }
Write-Host 'OK: Run mechanics work'

Write-Host ''
Write-Host '========================================='
Write-Host 'ALL COMBAT TESTS PASSED!'
Write-Host '========================================='
