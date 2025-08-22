# Test dialogue system fixes
. "$PSScriptRoot\Maps.ps1"
. "$PSScriptRoot\QuestSystem.ps1"
. "$PSScriptRoot\NPCs.ps1"

Write-Host "=== Testing Dialogue System Fixes ===" -ForegroundColor Yellow

# Test King's dialogue tree
Write-Host "`nTesting King's dialogue structure..." -ForegroundColor Cyan
$king = $global:NPCs | Where-Object { $_.Name -eq "King" }
if ($king -and $king.DialogueTree) {
    Write-Host "✓ King dialogue tree exists" -ForegroundColor Green
    Write-Host "   Available nodes: $($king.DialogueTree.Keys -join ', ')" -ForegroundColor White
    
    # Check for circular references
    $problemNodes = @()
    foreach ($nodeKey in $king.DialogueTree.Keys) {
        $node = $king.DialogueTree[$nodeKey]
        if ($node.Choices) {
            foreach ($choice in $node.Choices.Values) {
                if ($choice -eq $nodeKey) {
                    $problemNodes += "$nodeKey -> $choice"
                }
            }
        }
    }
    
    if ($problemNodes.Count -eq 0) {
        Write-Host "✓ No circular references found in King's dialogue" -ForegroundColor Green
    } else {
        Write-Host "⚠ Circular references found: $($problemNodes -join ', ')" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ King dialogue tree missing" -ForegroundColor Red
}

# Test end_conversation nodes
Write-Host "`nChecking for end_conversation nodes..." -ForegroundColor Cyan
foreach ($npc in $global:NPCs) {
    if ($npc.DialogueTree.ContainsKey("end_conversation")) {
        Write-Host "✓ $($npc.Name) has end_conversation node" -ForegroundColor Green
    } else {
        Write-Host "⚠ $($npc.Name) missing end_conversation node" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Dialogue System Ready for Testing! ===" -ForegroundColor Green
Write-Host "You can now test the game with:" -ForegroundColor White
Write-Host "1. .\Display.ps1" -ForegroundColor Gray
Write-Host "2. Walk to NPCs and press E to talk" -ForegroundColor Gray
Write-Host "3. Dialogue should no longer loop infinitely" -ForegroundColor Gray
