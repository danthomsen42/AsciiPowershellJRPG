# ==============================
# Simple NPC Definitions (Performance Test)
# ==============================

# Global game state for quest/event tracking
if (-not $GameState) {
    $GameState = @{ KingQuestAccepted = $false; PrincessRescued = $false }
}

# Performance optimization: NPC position lookup hashtable
$NPCPositionLookup = @{}

# Helper function to rebuild NPC position index
function Update-NPCPositionIndex {
    $global:NPCPositionLookup = @{}
    foreach ($npc in $global:NPCs) {
        $key = "$($npc.X),$($npc.Y)"
        $global:NPCPositionLookup[$key] = $npc
    }
}

# Helper function to get NPC at position (ultra-fast lookup)
function Get-NPCAtPosition {
    param($x, $y)
    return $global:NPCPositionLookup["$x,$y"]
}

# Simple NPC definitions (no complex dialogue trees)
$NPCs = @(
   @{ Name = "King"; X = 5; Y = 2; Char = "K"; CanMove = $false; Message = "Welcome to my kingdom!" }
   @{ Name = "Shopkeeper"; X = 10; Y = 8; Char = "S"; CanMove = $false; Message = "Welcome to my shop!" }
   @{ Name = "Child"; X = 3; Y = 6; Char = "c"; CanMove = $true; Message = "Hi! Want to play?" }
   @{ Name = "Townsperson"; X = 7; Y = 4; Char = "T"; CanMove = $true; Message = "Nice weather today." }
   @{ Name = "Guard"; X = 12; Y = 3; Char = "G"; CanMove = $false; Message = "The town is safe." }
)

# Simple dialogue function (no complex trees)
function Show-NPCDialogue {
    param($npc)
    Write-Host $npc.Message -ForegroundColor Cyan
    Write-Host "(Press any key to continue...)" -ForegroundColor DarkGray
    [System.Console]::ReadKey($true)
}

# Initialize the NPC position lookup hashtable for fast access
Update-NPCPositionIndex
