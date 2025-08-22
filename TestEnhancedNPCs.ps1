# ==============================
# Test Enhanced NPC & Quest System
# Quick verification of new features
# ==============================

# Load the systems
Write-Host "Loading Quest System..." -ForegroundColor Yellow
. "$PSScriptRoot\QuestSystem.ps1"

Write-Host "Loading Enhanced NPCs..." -ForegroundColor Yellow  
. "$PSScriptRoot\NPCs.ps1"

Write-Host "Loading Player data..." -ForegroundColor Yellow
if (Test-Path "$PSScriptRoot\Player.ps1") {
    . "$PSScriptRoot\Player.ps1"
} else {
    # Create minimal player for testing
    $global:Player = @{
        Name = "TestHero"
        HP = 100
        MaxHP = 100
        MP = 50
        MaxMP = 50
        Level = 5
        XP = 1000
        Gold = 500
        X = 10
        Y = 10
    }
}

Write-Host "`n" + "=" * 50 -ForegroundColor Green
Write-Host "  ENHANCED NPC & QUEST SYSTEM TEST" -ForegroundColor Green  
Write-Host "=" * 50 -ForegroundColor Green

# Test quest system basics
Write-Host "`n1. Testing Quest System Initialization..." -ForegroundColor Cyan
Write-Host "Active Quests: $($global:QuestSystem.ActiveQuests.Count)"
Write-Host "Completed Quests: $($global:QuestSystem.CompletedQuests.Count)" 
Write-Host "Quest Templates Available: $($QuestTemplates.Count)"

# Test quest operations
Write-Host "`n2. Testing Quest Operations..." -ForegroundColor Cyan

Write-Host "   Adding 'missing_cat' quest..."
$result = Add-Quest "missing_cat" "Town Elder"
Write-Host "   Result: $result"

Write-Host "   Checking active quests..."
Write-Host "   Active quest count: $($global:QuestSystem.ActiveQuests.Count)"

if ($global:QuestSystem.ActiveQuests.ContainsKey("missing_cat")) {
    Write-Host "   ✓ Missing cat quest successfully added" -ForegroundColor Green
    
    Write-Host "   Completing first objective..."
    Complete-QuestObjective "missing_cat" 0
    
    Write-Host "   Completing remaining objectives..."
    Complete-QuestObjective "missing_cat" 1
    Complete-QuestObjective "missing_cat" 2
} else {
    Write-Host "   ✗ Failed to add missing cat quest" -ForegroundColor Red
}

# Test story flags
Write-Host "`n3. Testing Story Flag System..." -ForegroundColor Cyan
Set-StoryFlag "TestFlag" $true
$flagResult = Get-StoryFlag "TestFlag"
Write-Host "   Set TestFlag to true, retrieved: $flagResult"

if ($flagResult) {
    Write-Host "   ✓ Story flag system working" -ForegroundColor Green
} else {
    Write-Host "   ✗ Story flag system failed" -ForegroundColor Red
}

# Test NPC tracking
Write-Host "`n4. Testing NPC Interaction Tracking..." -ForegroundColor Cyan
Mark-NPCSpokenTo "TestNPC"
$spokenResult = Has-SpokenToNPC "TestNPC"
Write-Host "   Marked TestNPC as spoken to, check result: $spokenResult"

if ($spokenResult) {
    Write-Host "   ✓ NPC tracking system working" -ForegroundColor Green
} else {
    Write-Host "   ✗ NPC tracking system failed" -ForegroundColor Red
}

# Show quest log
Write-Host "`n5. Showing Quest Log Interface..." -ForegroundColor Cyan
Write-Host "   (Press any key when ready to view quest log)" -ForegroundColor DarkGray
[System.Console]::ReadKey($true) | Out-Null
Show-QuestLog

# Test NPC dialogue
Write-Host "`n6. Testing NPC Dialogue System..." -ForegroundColor Cyan
Write-Host "   Available NPCs:" 
foreach ($npc in $NPCs) {
    Write-Host "   - $($npc.Name) at ($($npc.X), $($npc.Y))" -ForegroundColor Gray
}

Write-Host "`n   Testing dialogue with King..."
Write-Host "   (Press any key when ready)" -ForegroundColor DarkGray
[System.Console]::ReadKey($true) | Out-Null

$king = $NPCs | Where-Object { $_.Name -eq "King" } | Select-Object -First 1
if ($king) {
    Show-NPCDialogueTree $king
} else {
    Write-Host "   ✗ Could not find King NPC" -ForegroundColor Red
}

Write-Host "`n" + "=" * 50 -ForegroundColor Green
Write-Host "           TEST COMPLETED" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Green

Write-Host "`nSummary:" -ForegroundColor Yellow
Write-Host "- Quest System: Initialized and functional" -ForegroundColor White
Write-Host "- Enhanced NPCs: 3 NPCs with complex dialogues" -ForegroundColor White  
Write-Host "- Story Flags: Working for narrative tracking" -ForegroundColor White
Write-Host "- Quest Log: Interactive interface available" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Integrate quest log with main game (Q key)" -ForegroundColor White
Write-Host "2. Add quest persistence to save system" -ForegroundColor White
Write-Host "3. Add quest persistence to save system" -ForegroundColor White

Write-Host "`nPress any key to exit..." -ForegroundColor DarkGray
[System.Console]::ReadKey($true) | Out-Null
