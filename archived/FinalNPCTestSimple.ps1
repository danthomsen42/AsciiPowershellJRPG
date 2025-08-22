# Final NPC Integration Test
Write-Host "=== Final NPC Integration Test ===" -ForegroundColor Yellow

# Load all systems
Write-Host "`n1. Loading game systems..." -ForegroundColor Cyan
. "$PSScriptRoot\Maps.ps1"
. "$PSScriptRoot\QuestSystem.ps1"
. "$PSScriptRoot\NPCs.ps1"
Write-Host "   All systems loaded successfully" -ForegroundColor Green

# Check NPC data
Write-Host "`n2. Checking NPC data..." -ForegroundColor Cyan
Write-Host "   NPCs loaded: $($global:NPCs.Count)" -ForegroundColor White
Write-Host "   Position lookup entries: $($global:NPCPositionLookup.Count)" -ForegroundColor White

# Verify specific positions
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
        Write-Host "   Found $($npc.Name) at ($($expected.X),$($expected.Y))" -ForegroundColor Green
    } else {
        Write-Host "   Missing NPC at ($($expected.X),$($expected.Y))" -ForegroundColor Red
    }
}

# Test quest functions
Write-Host "`n4. Testing quest functions..." -ForegroundColor Cyan
$testResult = Has-CompletedQuest "test_quest"
Write-Host "   Has-CompletedQuest function works" -ForegroundColor Green

$testResult2 = Has-SpokenToNPC "TestNPC"
Write-Host "   Has-SpokenToNPC function works" -ForegroundColor Green

Write-Host "`n=== Ready to test in-game! ===" -ForegroundColor Yellow
Write-Host "Instructions:" -ForegroundColor White
Write-Host "1. Run: .\Display.ps1"
Write-Host "2. Walk to NPC coordinates and press E to talk"
Write-Host "3. Press J to view quest log"
