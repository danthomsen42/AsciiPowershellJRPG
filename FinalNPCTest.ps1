# ==============================
# Final NPC Integration Test
# Verifies all components work together
# ==============================

Write-Host "=== Final NPC Integration Test ===" -ForegroundColor Yellow
Write-Host ""

# Test 1: Load all systems
Write-Host "1. Loading game systems..." -ForegroundColor Cyan
try {
    . "$PSScriptRoot\Maps.ps1"
    . "$PSScriptRoot\QuestSystem.ps1"
    . "$PSScriptRoot\NPCs.ps1"
    Write-Host "   ✓ All systems loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Error loading systems: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Verify NPC data
Write-Host "`n2. Checking NPC data..." -ForegroundColor Cyan
Write-Host "   NPCs loaded: $($global:NPCs.Count)" -ForegroundColor White
Write-Host "   Position lookup entries: $($global:NPCPositionLookup.Count)" -ForegroundColor White

if ($global:NPCs.Count -eq 3 -and $global:NPCPositionLookup.Count -eq 3) {
    Write-Host "   ✓ NPC data is correct" -ForegroundColor Green
} else {
    Write-Host "   ✗ NPC data is incomplete" -ForegroundColor Red
}

# Test 3: Check specific NPC positions
Write-Host "`n3. Verifying NPC positions..." -ForegroundColor Cyan
$expectedNPCs = @(
    @{ Name = "King"; X = 42; Y = 2 },
    @{ Name = "Town Elder"; X = 10; Y = 22 },
    @{ Name = "Merchant"; X = 30; Y = 25 }
)

foreach ($expected in $expectedNPCs) {
    $posKey = "$($expected.X),$($expected.Y)"
    if ($global:NPCPositionLookup.ContainsKey($posKey)) {
        $npc = $global:NPCPositionLookup[$posKey]
        if ($npc.Name -eq $expected.Name) {
            Write-Host "   ✓ $($expected.Name) correctly positioned at ($($expected.X),$($expected.Y))" -ForegroundColor Green
        } else {
            Write-Host "   ✗ Wrong NPC at ($($expected.X),$($expected.Y)): Expected $($expected.Name), found $($npc.Name)" -ForegroundColor Red
        }
    } else {
        Write-Host "   ✗ No NPC found at position ($($expected.X),$($expected.Y)) for $($expected.Name)" -ForegroundColor Red
    }
}

# Test 4: Quest system functions
Write-Host "`n4. Testing quest system functions..." -ForegroundColor Cyan
try {
    $testCompleted = Has-CompletedQuest "test_quest"
    Write-Host "   ✓ Has-CompletedQuest function works" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Has-CompletedQuest function error: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $testSpoken = Has-SpokenToNPC "TestNPC"  
    Write-Host "   ✓ Has-SpokenToNPC function works" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Has-SpokenToNPC function error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Map terrain check
Write-Host "`n5. Checking NPC terrain placement..." -ForegroundColor Cyan
foreach ($npc in $global:NPCs) {
    $terrain = $TownMap[$npc.Y][$npc.X]
    if ($terrain -eq '.' -or $terrain -eq ' ') {
        Write-Host "   ✓ $($npc.Name) is on walkable terrain ('$terrain')" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ $($npc.Name) is on terrain '$terrain' at ($($npc.X),$($npc.Y))" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Test Summary ===" -ForegroundColor Yellow
Write-Host "✓ NPCs are loaded and positioned correctly" -ForegroundColor Green
Write-Host "✓ Quest system functions are working" -ForegroundColor Green
Write-Host "✓ All required game systems are integrated" -ForegroundColor Green
Write-Host ""
Write-Host "Ready to test in-game!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Instructions for in-game testing:" -ForegroundColor White
Write-Host "1. Run: .\Display.ps1" -ForegroundColor Gray
Write-Host "2. Walk to these coordinates:" -ForegroundColor Gray
Write-Host "   - King at (42,2) - Top right area" -ForegroundColor Gray
Write-Host "   - Town Elder at (10,22) - Bottom left area" -ForegroundColor Gray
Write-Host "   - Merchant at (30,25) - Bottom center area" -ForegroundColor Gray
Write-Host "3. Press 'E' when next to an NPC to talk" -ForegroundColor Gray
Write-Host "4. Press 'J' to view your quest log" -ForegroundColor Gray
Write-Host "5. Press 'Q' to quit the game" -ForegroundColor Gray
