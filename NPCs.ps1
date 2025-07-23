# ==============================
# NPC Definitions and Dialogue System
# ==============================

# NPC definitions

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

 # Dialogue tree-based NPC definitions
 $NPCs = @(
    @{
        Name = "King"; X = 5; Y = 2; Char = "K"; CanMove = $false
        DialogueTree = @{
            # Initial quest offer (only if not accepted)
            "start" = @{
                Condition = { -not $GameState.KingQuestAccepted }
                Text = "Will you please rescue my daughter, the Princess, from the evil dragon?"
                Choices = @{
                    "Accept" = "accept"
                    "Decline" = "decline"
                }
            }
            # Accept quest (sets flag)
            "accept" = @{
                Action = { $GameState.KingQuestAccepted = $true }
                Text = "Thank you! The dragon was last seen entering the dungeon to the south!"
                Choices = @{
                    "Continue" = "repeatAccept"
                }
            }
            # Decline quest (loops back)
            "decline" = @{
                Text = "Please reconsider!"
                Choices = @{
                    "Continue" = "start"
                }
            }
            # Repeat accept dialogue until princess is rescued
            "repeatAccept" = @{
                Condition = { $GameState.KingQuestAccepted -and -not $GameState.PrincessRescued }
                Text = "Thank you! The dragon was last seen entering the dungeon to the south!"
                Choices = @{
                    "Continue" = "repeatAccept"
                }
            }
            # After princess is rescued
            "rescued" = @{
                Condition = { $GameState.PrincessRescued }
                Text = "Thank you for rescuing my daughter! Anything in the treasure room is yours!"
                Choices = @{
                    "Continue" = "rescued"
                }
            }
        }
    }
    @{
        Name = "Shopkeeper"; X = 10; Y = 8; Char = "S"; CanMove = $false
        DialogueTree = @{
            "start" = @{
                Text = "Welcome to my shop!"
                Choices = @{
                    "Buy" = "buy"
                    "Sell" = "sell"
                    "Leave" = "end"
                }
            }
            "buy" = @{
                Text = "Here's what I have for sale. (Pretend list)"
                Choices = @{
                    "Back" = "start"
                }
            }
            "sell" = @{
                Text = "What would you like to sell? (Pretend list)"
                Choices = @{
                    "Back" = "start"
                }
            }
            "end" = @{
                Text = "Come again!"
                Choices = @{}
            }
        }
    }
    @{
        Name = "Child"; X = 3; Y = 6; Char = "c"; CanMove = $true
        DialogueTree = @{
            "start" = @{
                Text = "Hi! Do you want to play?"
                Choices = @{
                    "Yes" = "play"
                    "No" = "end"
                }
            }
            "play" = @{
                Text = "Yay! Let's play ball."
                Choices = @{
                    "Continue" = "end"
                }
            }
            "end" = @{
                Text = "Bye!"
                Choices = @{}
            }
        }
    }
    @{
        Name = "Townsperson"; X = 7; Y = 4; Char = "T"; CanMove = $true
        DialogueTree = @{
            "start" = @{
                Text = "Nice weather today."
                Choices = @{
                    "Continue" = "end"
                }
            }
            "end" = @{
                Text = "See you around!"
                Choices = @{}
            }
        }
    }
    @{
        Name = "Guard"; X = 12; Y = 5; Char = "G"; CanMove = $false
        DialogueTree = @{
            "start" = @{
                Text = "Stay out of trouble."
                Choices = @{
                    "Continue" = "end"
                }
            }
            "end" = @{
                Text = "Move along."
                Choices = @{}
            }
        }
    }
)


# Dialogue tree interaction logic

# Dialogue tree interaction logic with conditions and actions
function Show-NPCDialogueTree {
    param($npc)
    $currentNode = $null
    # Find the first valid node (based on Condition)
    foreach ($key in $npc.DialogueTree.Keys) {
        $node = $npc.DialogueTree[$key]
        if ($key -eq "start" -or ($node.ContainsKey("Condition") -and (& $node.Condition))) {
            $currentNode = $key
            break
        }
    }
    if (-not $currentNode) { $currentNode = "start" }
    while ($true) {
        $node = $npc.DialogueTree[$currentNode]
        # If node has Condition, check it
        if ($node.ContainsKey("Condition") -and -not (& $node.Condition)) {
            # Find next valid node
            $found = $false
            foreach ($key in $npc.DialogueTree.Keys) {
                $testNode = $npc.DialogueTree[$key]
                if ($testNode.ContainsKey("Condition") -and (& $testNode.Condition)) {
                    $currentNode = $key
                    $node = $testNode
                    $found = $true
                    break
                }
            }
            if (-not $found) { break }
        }
        # If node has Action, run it
        if ($node.ContainsKey("Action")) {
            & $node.Action
        }
        Write-Host $node.Text -ForegroundColor Cyan
        if ($node.Choices.Count -eq 0) {
            break
        }
        $i = 1
        $choiceMap = @{}
        foreach ($choice in $node.Choices.Keys) {
            Write-Host ("[$i] $choice") -ForegroundColor Yellow
            $choiceMap[$i] = $choice
            $i++
        }
        $selected = $null
        while ($null -eq $selected) {
            Write-Host "Choose an option: " -NoNewline
            $input = [System.Console]::ReadKey($true)
            if ($input.KeyChar -match '[1-9]') {
                $num = [int]$input.KeyChar
                if ($choiceMap.ContainsKey($num)) {
                    $selected = $choiceMap[$num]
                }
            }
        }
        $currentNode = $node.Choices[$selected]
        Write-Host "" # Blank line for spacing
    }
    Write-Host "(Press any key to continue...)" -ForegroundColor DarkGray
    [System.Console]::ReadKey($true)
}

# Initialize the NPC position lookup hashtable for fast access
Update-NPCPositionIndex
