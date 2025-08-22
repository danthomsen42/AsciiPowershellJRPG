# ==============================
# Enhanced NPC Definitions and Dialogue System
# Integrated with Quest System
# ==============================

# Load Quest System if not already loaded
if (-not $global:QuestSystem) {
    $questSystemPath = Join-Path $PSScriptRoot "QuestSystem.ps1"
    if (Test-Path $questSystemPath) {
        . $questSystemPath
    }
}

# Legacy compatibility - migrate old game state
if (-not $GameState) {
    $GameState = @{ KingQuestAccepted = $false; PrincessRescued = $false }
}

# Migrate legacy quest state to new system
if ($GameState.KingQuestAccepted -and -not (Has-ActiveQuest "rescue_princess") -and -not (Has-CompletedQuest "rescue_princess")) {
    Add-Quest "rescue_princess" "King"
}
if ($GameState.PrincessRescued -and (Has-ActiveQuest "rescue_princess")) {
    Complete-Quest "rescue_princess"
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

 # Enhanced NPC definitions with quest integration
 $global:NPCs = @(
    @{
        Name = "King"; X = 42; Y = 2; Char = "K"; CanMove = $false
        DialogueTree = @{
            # First meeting - quest introduction
            "start" = @{
                Condition = { -not (Has-SpokenToNPC "King") }
                Action = { Mark-NPCSpokenTo "King" }
                Text = "Greetings, brave adventurer! I am the King of this realm. My daughter, the Princess, has been kidnapped by a terrible dragon! Will you help rescue her?"
                Choices = @{
                    "Accept the quest" = "accept_quest"
                    "Ask for more details" = "quest_details"
                    "Decline for now" = "decline_quest"
                }
            }
            # Quest details
            "quest_details" = @{
                Text = "The dragon was last seen flying toward the ancient dungeon south of town. It's dangerous, but I believe a hero like you can succeed. The reward will be substantial - 1000 gold and access to the royal treasury!"
                Choices = @{
                    "Accept the quest" = "accept_quest"
                    "I need time to think" = "decline_quest"
                }
            }
            # Accept quest
            "accept_quest" = @{
                Action = { 
                    Add-Quest "rescue_princess" "King"
                    Set-StoryFlag "KingQuestAccepted" $true
                }
                Text = "Excellent! May the gods protect you on this perilous journey. The dragon's lair lies deep within the southern dungeon. Bring my daughter home safely!"
                Choices = @{
                    "I won't let you down" = "end_conversation"
                }
            }
            # Quest accepted follow-up
            "quest_accepted" = @{
                Condition = { (Has-ActiveQuest "rescue_princess") -and -not (Get-StoryFlag "DragonDefeated") }
                Text = "Time is of the essence! Every moment my daughter remains captive is agony. Please, find the dragon's lair in the southern dungeon!"
                Choices = @{
                    "I'm on my way" = "end_conversation"
                    "Any advice?" = "quest_advice"
                }
            }
            # Quest advice
            "quest_advice" = @{
                Text = "Dragons are ancient and powerful. Make sure you're well-prepared with healing potions and strong equipment. The dungeon entrance should be south of the town walls."
                Choices = @{
                    "Thank you" = "end_conversation"
                }
            }
            # Decline quest
            "decline_quest" = @{
                Text = "I understand if you need time to prepare. This is no simple task. Please reconsider - my daughter's life hangs in the balance!"
                Choices = @{
                    "Actually, I'll help" = "accept_quest"
                    "I'll return later" = "return_later"
                }
            }
            # Return later
            "return_later" = @{
                Text = "Please don't delay too long. Every passing hour brings more danger to the Princess."
                Choices = @{
                    "I understand" = "end_conversation"
                }
            }
            # End conversation
            "end_conversation" = @{
                Text = "Farewell for now, adventurer."
                Choices = @{}
            }
            # Quest completed
            "quest_complete" = @{
                Condition = { Has-CompletedQuest "rescue_princess" }
                Text = "My daughter is safe! You are truly a hero of the realm! As promised, the royal treasury is open to you, and this gold is yours with my eternal gratitude."
                Choices = @{
                    "Happy to help" = "hero_status"
                }
            }
            # Hero status achieved
            "hero_status" = @{
                Condition = { Has-CompletedQuest "rescue_princess" }
                Text = "You will always be welcome in this kingdom. If you ever need anything, please don't hesitate to ask!"
                Choices = @{
                    "Thank you, Your Majesty" = "hero_status"
                    "Any other quests available?" = "additional_quests"
                }
            }
            # Additional quests check
            "additional_quests" = @{
                Text = "I've heard merchants on the trade routes have been troubled by bandits lately. Perhaps a hero such as yourself could help them?"
                Choices = @{
                    "Tell me more" = "merchant_quest_intro"
                    "Maybe later" = "hero_status"
                }
            }
            # Merchant quest introduction
            "merchant_quest_intro" = @{
                Action = { Set-StoryFlag "MerchantQuestAvailable" $true }
                Text = "Speak with the merchants near the town gate. They could use an escort for their next journey. It would be good for trade and the kingdom's prosperity."
                Choices = @{
                    "I'll look into it" = "hero_status"
                }
            }
        }
    }
    @{
        Name = "Town Elder"; X = 10; Y = 22; Char = "E"; CanMove = $false
        DialogueTree = @{
            # First meeting
            "start" = @{
                Condition = { -not (Has-SpokenToNPC "Town Elder") }
                Action = { Mark-NPCSpokenTo "Town Elder" }
                Text = "Welcome, traveler. I am the Town Elder. I've lived in this village for many decades and have seen much change. How may I help you?"
                Choices = @{
                    "Tell me about this town" = "town_info"
                    "Any local problems?" = "local_issues"
                    "Just passing through" = "farewell"
                }
            }
            # Town information
            "town_info" = @{
                Text = "This is a peaceful trading town, though recent events have troubled us. We're known for our skilled craftsmen and the royal castle. The King is a good ruler, but the Princess's kidnapping has shaken everyone."
                Choices = @{
                    "What about local issues?" = "local_issues"
                    "Thank you for the information" = "return_conversation"
                }
            }
            # Local issues - varies based on story progression
            "local_issues" = @{
                Condition = { -not (Has-ActiveQuest "missing_cat") -and -not (Has-CompletedQuest "missing_cat") }
                Text = "Well, it might seem small compared to the Princess's plight, but the children are heartbroken. Our town cat, Whiskers, has been missing for three days. She usually sleeps by the fountain, but no one has seen her."
                Choices = @{
                    "I'll help find Whiskers" = "accept_cat_quest"
                    "That does sound concerning" = "cat_quest_details"
                    "I have bigger concerns" = "return_conversation"
                }
            }
            # Cat quest details
            "cat_quest_details" = @{
                Text = "Whiskers is a small orange tabby, very friendly. She never wanders far from the town center. The children have been searching, but perhaps fresh eyes might spot something they missed."
                Choices = @{
                    "I'll look for her" = "accept_cat_quest"
                    "I hope she turns up" = "return_conversation"
                }
            }
            # Accept cat quest
            "accept_cat_quest" = @{
                Action = { Add-Quest "missing_cat" "Town Elder" }
                Text = "Bless you! Check around the buildings, maybe she got trapped somewhere. The children will be so happy if you can bring Whiskers home safely."
                Choices = @{
                    "I'll start searching now" = "end_conversation"
                }
            }
            # Cat quest active
            "cat_quest_active" = @{
                Condition = { Has-ActiveQuest "missing_cat" }
                Text = "Any sign of Whiskers yet? The children ask me every hour if she's been found."
                Choices = @{
                    "Still searching" = "end_conversation"
                    "Where was she last seen?" = "cat_last_seen"
                }
            }
            # Cat last seen
            "cat_last_seen" = @{
                Text = "Little Timmy saw her chasing a butterfly near the old storage shed behind the blacksmith's shop. That was three days ago, around sunset."
                Choices = @{
                    "I'll check there" = "end_conversation"
                }
            }
            # After completing cat quest
            "cat_quest_complete" = @{
                Condition = { Has-CompletedQuest "missing_cat" }
                Text = "The whole town heard the children's cheers when you brought Whiskers back! You've brought joy to many families. A small kindness, but it means the world to us."
                Choices = @{
                    "Happy to help" = "return_conversation"
                }
            }
            # Return to general conversation
            "return_conversation" = @{
                Condition = { Has-SpokenToNPC "Town Elder" }
                Text = "Good to see you again. How are your adventures progressing?"
                Choices = @{
                    "Tell me about the town" = "town_info"
                    "Any news?" = "town_news"
                    "Farewell" = "farewell"
                }
            }
            # Town news - varies based on story progression
            "town_news" = @{
                Text = $(
                    if (Has-CompletedQuest "rescue_princess") {
                        "The whole kingdom celebrates the Princess's safe return! Trade has picked up, and people are smiling again."
                    } elseif (Has-ActiveQuest "rescue_princess") {
                        "Everyone prays for the Princess's safe return. The King has been pacing the throne room for days."
                    } else {
                        "Things are quiet, though there's always some concern about the safety of our trade routes."
                    }
                )
                Choices = @{
                    "Interesting" = "return_conversation"
                }
            }
            # Farewell
            "farewell" = @{
                Text = "Safe travels, and may fortune smile upon you."
                Choices = @{}
            }
            # End conversation
            "end_conversation" = @{
                Text = "Take care, traveler."
                Choices = @{}
            }
        }
    }
    @{
        Name = "Merchant"; X = 30; Y = 25; Char = "M"; CanMove = $false
        DialogueTree = @{
            # First meeting
            "start" = @{
                Condition = { -not (Has-SpokenToNPC "Merchant") }
                Action = { Mark-NPCSpokenTo "Merchant" }
                Text = "Ah, a potential customer! I'm Marcus, a traveling merchant. I deal in fine goods from across the realm, though business has been... challenging lately."
                Choices = @{
                    "What kind of goods?" = "merchant_wares"
                    "Why challenging?" = "business_troubles"
                    "Just looking around" = "browsing"
                }
            }
            # Merchant wares
            "merchant_wares" = @{
                Text = "I carry healing potions, enchanted trinkets, maps of distant lands, and crafted weapons when I can get them. Unfortunately, my last caravan was attacked by bandits."
                Choices = @{
                    "Attacked by bandits?" = "bandit_attack"
                    "Can I buy something?" = "shop_attempt"
                }
            }
            # Business troubles
            "business_troubles" = @{
                Text = "The trade routes have become dangerous! Bandits attack merchant caravans regularly. I barely escaped with my life last week, and lost most of my valuable inventory."
                Choices = @{
                    "That's terrible!" = "bandit_sympathy"
                    "Why don't you travel with guards?" = "guard_question"
                }
            }
            # Bandit attack details
            "bandit_attack" = @{
                Text = "Aye, nasty bunch they were. Struck just after dawn when we thought we were safe. Took my best healing potions and a set of enchanted armor I was hoping to sell here."
                Choices = @{
                    "Are you planning another trip?" = "next_trip"
                    "Maybe I can help" = "offer_help"
                }
            }
            # Next trip discussion
            "next_trip" = @{
                Condition = { -not (Get-StoryFlag "MerchantQuestAvailable") }
                Text = "I need to make another run soon, or I'll go bankrupt. But I can't afford proper guards, and traveling alone is suicide with these bandits around."
                Choices = @{
                    "What if I helped escort you?" = "escort_suggestion"
                    "Good luck with that" = "return_conversation"
                }
            }
            # After King mentions merchant quest
            "next_trip_king_mentioned" = @{
                Condition = { Get-StoryFlag "MerchantQuestAvailable" }
                Text = "I need to make another trading run to Westbrook, but these bandits have me terrified. I heard the King might have mentioned my plight to a certain hero..."
                Choices = @{
                    "I could escort you" = "accept_escort_quest"
                    "When are you planning to leave?" = "trip_timing"
                }
            }
            # Escort suggestion
            "escort_suggestion" = @{
                Text = "You'd do that? It would be dangerous - these aren't common thieves, but organized bandits with good weapons. But if you're willing, I could pay you well for the protection."
                Choices = @{
                    "I accept the job" = "accept_escort_quest"
                    "Tell me more about the danger" = "danger_details"
                }
            }
            # Accept escort quest (only if prerequisites met)
            "accept_escort_quest" = @{
                Condition = { Has-CompletedQuest "rescue_princess" }
                Action = { Add-Quest "merchant_escort" "Merchant" }
                Text = "Excellent! We'll leave at dawn tomorrow. Meet me at the east gate. I'll pay you 150 gold plus a bonus if we make it safely. You're saving my livelihood!"
                Choices = @{
                    "I'll be there" = "escort_accepted"
                }
            }
            # If trying to accept without prerequisites
            "accept_escort_quest_blocked" = @{
                Condition = { -not (Has-CompletedQuest "rescue_princess") }
                Text = "I appreciate the offer, but honestly, I need someone with a proven reputation. Perhaps after you've made a name for yourself with some heroic deeds?"
                Choices = @{
                    "I understand" = "return_conversation"
                }
            }
            # Escort quest accepted
            "escort_accepted" = @{
                Condition = { Has-ActiveQuest "merchant_escort" }
                Text = "Thank you again for agreeing to help! I'll be at the east gate at dawn with my cart loaded. Hopefully we can avoid the bandits entirely."
                Choices = @{
                    "What's our route?" = "route_details"
                    "I'll be ready" = "end_conversation"
                }
            }
            # Route details
            "route_details" = @{
                Text = "We'll take the main road to Westbrook - it's the shortest route, but also where the bandits like to strike. If we're lucky, your presence will deter them."
                Choices = @{
                    "See you at dawn" = "end_conversation"
                }
            }
            # After completing escort quest
            "escort_complete" = @{
                Condition = { Has-CompletedQuest "merchant_escort" }
                Text = "I can't thank you enough! The trip to Westbrook was profitable, and I'm finally back in business. You're welcome to shop my wares anytime - hero's discount included!"
                Choices = @{
                    "Happy to help commerce" = "return_conversation"
                    "What's available now?" = "enhanced_shop"
                }
            }
            # Enhanced shop after quest
            "enhanced_shop" = @{
                Condition = { Has-CompletedQuest "merchant_escort" }
                Text = "I've restocked with fine goods from Westbrook! Healing potions, enchanted rings, masterwork weapons - all at reduced prices for you, my friend."
                Choices = @{
                    "Show me your wares" = "shop_interface"
                    "Maybe later" = "return_conversation"
                }
            }
            # Regular return conversation
            "return_conversation" = @{
                Condition = { Has-SpokenToNPC "Merchant" }
                Text = $(
                    if (Has-CompletedQuest "merchant_escort") {
                        "Good to see you again, my friend! Business is booming thanks to you."
                    } elseif (Has-ActiveQuest "merchant_escort") {
                        "Ready for our journey? I have the cart loaded and waiting."
                    } else {
                        "Hello again! Still struggling with the bandit problem, but hoping things improve."
                    }
                )
                Choices = @{
                    "How's business?" = "business_update"
                    "Need anything?" = "general_help"
                    "Farewell" = "farewell"
                }
            }
            # Shop interface placeholder
            "shop_interface" = @{
                Text = "[Shop system not yet implemented - but imagine fine wares here!]"
                Choices = @{
                    "Maybe later" = "return_conversation"
                }
            }
            # Farewell
            "farewell" = @{
                Text = "Safe travels, and may your coin purse stay heavy!"
                Choices = @{}
            }
            # End conversation
            "end_conversation" = @{
                Text = "Until we meet again, friend."
                Choices = @{}
            }
        }
    }
)


# Dialogue tree interaction logic

# Enhanced dialogue tree interaction logic with quest integration
function Show-NPCDialogueTree {
    param($npc)
    
    Clear-Host
    Write-Host "=" * 50 -ForegroundColor Blue
    Write-Host "   Talking to $($npc.Name)" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Blue
    Write-Host ""
    
    $currentNode = $null
    
    # Find the appropriate starting node based on conditions
    foreach ($key in $npc.DialogueTree.Keys) {
        $node = $npc.DialogueTree[$key]
        
        # Check if this node has a condition and evaluate it
        if ($node.ContainsKey("Condition")) {
            try {
                $conditionResult = & $node.Condition
                if ($conditionResult) {
                    $currentNode = $key
                    break
                }
            } catch {
                # If condition evaluation fails, skip this node
                continue
            }
        }
    }
    
    # If no conditional node matched, try to find a general node
    if (-not $currentNode) {
        $preferredOrder = @("start", "return_conversation", "quest_complete", "hero_status")
        foreach ($preferred in $preferredOrder) {
            if ($npc.DialogueTree.ContainsKey($preferred)) {
                $testNode = $npc.DialogueTree[$preferred]
                if (-not $testNode.ContainsKey("Condition") -or (& $testNode.Condition)) {
                    $currentNode = $preferred
                    break
                }
            }
        }
    }
    
    # Fallback to first available node
    if (-not $currentNode) {
        $currentNode = $npc.DialogueTree.Keys | Select-Object -First 1
    }
    
    # Dialogue loop
    while ($currentNode -and $npc.DialogueTree.ContainsKey($currentNode)) {
        $node = $npc.DialogueTree[$currentNode]
        
        # Check node condition if it exists
        if ($node.ContainsKey("Condition")) {
            try {
                $conditionResult = & $node.Condition
                if (-not $conditionResult) {
                    # Find alternative node or break
                    $found = $false
                    foreach ($key in $npc.DialogueTree.Keys) {
                        $testNode = $npc.DialogueTree[$key]
                        if (-not $testNode.ContainsKey("Condition") -or (& $testNode.Condition)) {
                            $currentNode = $key
                            $node = $testNode
                            $found = $true
                            break
                        }
                    }
                    if (-not $found) { break }
                }
            } catch {
                # If condition fails to evaluate, break out
                break
            }
        }
        
        # Execute node action if present
        if ($node.ContainsKey("Action")) {
            try {
                & $node.Action
            } catch {
                Write-Host "Error executing dialogue action: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Display the dialogue text
        Write-Host "$($npc.Name): " -NoNewline -ForegroundColor Yellow
        
        # Handle dynamic text evaluation
        $displayText = $node.Text
        if ($displayText -is [ScriptBlock]) {
            try {
                $displayText = & $displayText
            } catch {
                $displayText = "..."
            }
        }
        
        Write-Host $displayText -ForegroundColor White
        Write-Host ""
        
        # Check if there are choices
        if (-not $node.Choices -or $node.Choices.Count -eq 0) {
            break
        }
        
        # Display choices
        $i = 1
        $choiceMap = @{}
        Write-Host "Your response:" -ForegroundColor Green
        foreach ($choice in $node.Choices.Keys) {
            Write-Host "  [$i] $choice" -ForegroundColor Yellow
            $choiceMap[$i] = $choice
            $i++
        }
        
        # Get player choice
        $selected = $null
        Write-Host ""
        while ($null -eq $selected) {
            Write-Host "Choose your response (1-$($choiceMap.Count)): " -NoNewline -ForegroundColor Green
            $keyInput = [System.Console]::ReadKey($true)
            
            if ($keyInput.KeyChar -match '[1-9]') {
                $num = [int]([string]$keyInput.KeyChar)
                if ($choiceMap.ContainsKey($num)) {
                    $selected = $choiceMap[$num]
                    Write-Host $num
                }
            }
        }
        
        # Move to next node based on choice
        $nextNodeKey = $node.Choices[$selected]
        
        # Handle special node transitions
        if ($nextNodeKey -eq "quest_accepted" -and -not $npc.DialogueTree.ContainsKey($nextNodeKey)) {
            # Fallback for missing quest_accepted node
            $nextNodeKey = "return_conversation"
        }
        
        $currentNode = $nextNodeKey
        Write-Host ""
    }
    
    Write-Host "=" * 50 -ForegroundColor Blue
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    [System.Console]::ReadKey($true) | Out-Null
}

# Initialize the NPC position lookup hashtable for fast access
Update-NPCPositionIndex
