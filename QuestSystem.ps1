# ==============================
# Quest System for ASCII JRPG
# Enhanced NPC Communication & Quest Tracking
# ==============================

# Quest Management System
if (-not $global:QuestSystem) {
    $global:QuestSystem = @{
        ActiveQuests = @{}
        CompletedQuests = @{}
        QuestCounter = 1
    }
}

# Quest definitions and templates
$QuestTemplates = @{
    "rescue_princess" = @{
        ID = "rescue_princess"
        Name = "Rescue the Princess"
        Description = "The King's daughter has been kidnapped by a dragon. Venture south to the dungeon and rescue her."
        Type = "Main"
        Objectives = @(
            @{ Description = "Find the dragon's lair"; Completed = $false }
            @{ Description = "Defeat the dragon"; Completed = $false }
            @{ Description = "Rescue the princess"; Completed = $false }
            @{ Description = "Return to the King"; Completed = $false }
        )
        Rewards = @{
            XP = 500
            Gold = 1000
            Items = @("Dragon Scale", "Royal Blessing")
        }
        Prerequisites = @()
        Status = "Available"
    }
    
    "missing_cat" = @{
        ID = "missing_cat"
        Name = "Find Whiskers"
        Description = "The town's beloved cat Whiskers has gone missing. Help find her before the children get too sad."
        Type = "Side"
        Objectives = @(
            @{ Description = "Search the town for clues"; Completed = $false }
            @{ Description = "Find Whiskers"; Completed = $false }
            @{ Description = "Return Whiskers safely"; Completed = $false }
        )
        Rewards = @{
            XP = 100
            Gold = 50
            Items = @("Cat Treat", "Lucky Charm")
        }
        Prerequisites = @()
        Status = "Available"
    }
    
    "merchant_escort" = @{
        ID = "merchant_escort"
        Name = "Merchant Escort"
        Description = "A traveling merchant needs protection from bandits on the road to the next town."
        Type = "Side"
        Objectives = @(
            @{ Description = "Meet the merchant at the town gate"; Completed = $false }
            @{ Description = "Escort merchant safely"; Completed = $false }
            @{ Description = "Defeat any bandits encountered"; Completed = $false }
        )
        Rewards = @{
            XP = 200
            Gold = 150
            Items = @("Merchant's Map", "Trade Goods")
        }
        Prerequisites = @("rescue_princess")  # Only available after main quest
        Status = "Locked"
    }
}

# Quest Management Functions
function Add-Quest {
    param(
        [string]$QuestID,
        [string]$GivenBy = "Unknown"
    )
    
    if ($QuestTemplates.ContainsKey($QuestID)) {
        $questTemplate = $QuestTemplates[$QuestID]
        
        # Check prerequisites
        $canAccept = $true
        foreach ($prereq in $questTemplate.Prerequisites) {
            if (-not $global:QuestSystem.CompletedQuests.ContainsKey($prereq)) {
                $canAccept = $false
                break
            }
        }
        
        if ($canAccept) {
            # Deep copy the template to avoid reference issues
            $newQuest = @{
                ID = $questTemplate.ID
                Name = $questTemplate.Name
                Description = $questTemplate.Description
                Type = $questTemplate.Type
                Objectives = @()
                Rewards = $questTemplate.Rewards
                Status = "Active"
                GivenBy = $GivenBy
                AcceptedDate = Get-Date
            }
            
            # Copy objectives
            foreach ($obj in $questTemplate.Objectives) {
                $newQuest.Objectives += @{ 
                    Description = $obj.Description
                    Completed = $obj.Completed 
                }
            }
            
            $global:QuestSystem.ActiveQuests[$QuestID] = $newQuest
            
            Write-Host "Quest Added: $($newQuest.Name)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Prerequisites not met for quest: $($questTemplate.Name)" -ForegroundColor Yellow
            return $false
        }
    }
    return $false
}

function Complete-QuestObjective {
    param(
        [string]$QuestID,
        [int]$ObjectiveIndex
    )
    
    if ($global:QuestSystem.ActiveQuests.ContainsKey($QuestID)) {
        $quest = $global:QuestSystem.ActiveQuests[$QuestID]
        if ($ObjectiveIndex -lt $quest.Objectives.Count) {
            $quest.Objectives[$ObjectiveIndex].Completed = $true
            Write-Host "Objective completed: $($quest.Objectives[$ObjectiveIndex].Description)" -ForegroundColor Cyan
            
            # Check if all objectives are complete
            $allComplete = $true
            foreach ($obj in $quest.Objectives) {
                if (-not $obj.Completed) {
                    $allComplete = $false
                    break
                }
            }
            
            if ($allComplete) {
                Complete-Quest $QuestID
            }
        }
    }
}

function Complete-Quest {
    param([string]$QuestID)
    
    if ($global:QuestSystem.ActiveQuests.ContainsKey($QuestID)) {
        $quest = $global:QuestSystem.ActiveQuests[$QuestID]
        $quest.Status = "Completed"
        $quest.CompletedDate = Get-Date
        
        # Move to completed quests
        $global:QuestSystem.CompletedQuests[$QuestID] = $quest
        $global:QuestSystem.ActiveQuests.Remove($QuestID)
        
        # Award rewards
        Award-QuestRewards $quest
        
        Write-Host "Quest Completed: $($quest.Name)!" -ForegroundColor Green
        
        # Unlock any dependent quests
        Unlock-DependentQuests $QuestID
    }
}

function Award-QuestRewards {
    param($Quest)
    
    # Award XP
    if ($Quest.Rewards.XP -gt 0) {
        $global:Player.XP += $Quest.Rewards.XP
        Write-Host "Gained $($Quest.Rewards.XP) XP!" -ForegroundColor Yellow
    }
    
    # Award Gold
    if ($Quest.Rewards.Gold -gt 0) {
        $global:Player.Gold += $Quest.Rewards.Gold
        Write-Host "Received $($Quest.Rewards.Gold) gold!" -ForegroundColor Yellow
    }
    
    # Award Items
    foreach ($item in $Quest.Rewards.Items) {
        # For now just show the message, implement inventory system later
        Write-Host "Received: $item" -ForegroundColor Cyan
    }
}

function Unlock-DependentQuests {
    param([string]$CompletedQuestID)
    
    foreach ($questID in $QuestTemplates.Keys) {
        $template = $QuestTemplates[$questID]
        if ($template.Prerequisites -contains $CompletedQuestID -and 
            -not $global:QuestSystem.ActiveQuests.ContainsKey($questID) -and
            -not $global:QuestSystem.CompletedQuests.ContainsKey($questID)) {
            $template.Status = "Available"
        }
    }
}

function Show-QuestLog {
    Clear-Host
    Write-Host "=" * 50 -ForegroundColor Yellow
    Write-Host "           QUEST LOG" -ForegroundColor Yellow
    Write-Host "=" * 50 -ForegroundColor Yellow
    
    # Show active quests
    if ($global:QuestSystem.ActiveQuests.Count -gt 0) {
        Write-Host "`nACTIVE QUESTS:" -ForegroundColor Green
        Write-Host "-" * 20 -ForegroundColor Green
        
        foreach ($quest in $global:QuestSystem.ActiveQuests.Values) {
            Write-Host "`n[$($quest.Type)] $($quest.Name)" -ForegroundColor Cyan
            Write-Host "Description: $($quest.Description)" -ForegroundColor Gray
            Write-Host "Given by: $($quest.GivenBy)" -ForegroundColor Gray
            
            Write-Host "Objectives:" -ForegroundColor White
            for ($i = 0; $i -lt $quest.Objectives.Count; $i++) {
                $obj = $quest.Objectives[$i]
                $status = if ($obj.Completed) { "[X]" } else { "[ ]" }
                $color = if ($obj.Completed) { "Green" } else { "White" }
                Write-Host "  $status $($obj.Description)" -ForegroundColor $color
            }
        }
    }
    
    # Show completed quests
    if ($global:QuestSystem.CompletedQuests.Count -gt 0) {
        Write-Host "`n`nCOMPLETED QUESTS:" -ForegroundColor DarkGreen
        Write-Host "-" * 20 -ForegroundColor DarkGreen
        
        foreach ($quest in $global:QuestSystem.CompletedQuests.Values) {
            Write-Host "X [$($quest.Type)] $($quest.Name)" -ForegroundColor DarkGreen
        }
    }
    
    if ($global:QuestSystem.ActiveQuests.Count -eq 0 -and $global:QuestSystem.CompletedQuests.Count -eq 0) {
        Write-Host "`nNo quests available." -ForegroundColor Gray
        Write-Host "Talk to NPCs to discover new adventures!" -ForegroundColor Gray
    }
    
    Write-Host "`n" + "=" * 50 -ForegroundColor Yellow
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    [System.Console]::ReadKey($true) | Out-Null
}

# Enhanced Game State Management
if (-not $global:GameState) {
    $global:GameState = @{}
}

# Initialize enhanced game state
if (-not $global:GameState.ContainsKey('NPCsSpokenTo')) { $global:GameState.NPCsSpokenTo = @() }
if (-not $global:GameState.ContainsKey('StoryFlags')) { $global:GameState.StoryFlags = @{} }
if (-not $global:GameState.ContainsKey('CurrentMap')) { $global:GameState.CurrentMap = "MainTown" }
if (-not $global:GameState.ContainsKey('VisitedMaps')) { $global:GameState.VisitedMaps = @("MainTown") }

# Story progression functions
function Set-StoryFlag {
    param([string]$Flag, [bool]$Value = $true)
    $global:GameState.StoryFlags[$Flag] = $Value
}

function Get-StoryFlag {
    param([string]$Flag)
    return $global:GameState.StoryFlags.ContainsKey($Flag) -and $global:GameState.StoryFlags[$Flag]
}

function Mark-NPCSpokenTo {
    param([string]$NPCName)
    if ($global:GameState.NPCsSpokenTo -notcontains $NPCName) {
        $global:GameState.NPCsSpokenTo += $NPCName
    }
}

function Has-SpokenToNPC {
    param([string]$NPCName)
    return $global:GameState.NPCsSpokenTo -contains $NPCName
}

# Quest condition helper functions
function Has-ActiveQuest {
    param([string]$QuestID)
    return $global:QuestSystem.ActiveQuests.ContainsKey($QuestID)
}

function Has-CompletedQuest {
    param([string]$QuestID)
    return $global:QuestSystem.CompletedQuests.ContainsKey($QuestID)
}

function Get-QuestObjectiveStatus {
    param([string]$QuestID, [int]$ObjectiveIndex)
    if (Has-ActiveQuest $QuestID) {
        $quest = $global:QuestSystem.ActiveQuests[$QuestID]
        if ($ObjectiveIndex -lt $quest.Objectives.Count) {
            return $quest.Objectives[$ObjectiveIndex].Completed
        }
    }
    return $false
}

# Party composition checks for dialogue conditions
function Has-PartyMember {
    param([string]$Class)
    # For future party system integration
    # For now, assume single character
    return $false
}

function Get-PartySize {
    # For future party system integration
    return 1
}

# Map and location functions
function Set-CurrentMap {
    param([string]$MapName)
    $global:GameState.CurrentMap = $MapName
    if ($global:GameState.VisitedMaps -notcontains $MapName) {
        $global:GameState.VisitedMaps += $MapName
    }
}

function Get-CurrentMap {
    return $global:GameState.CurrentMap
}

function Has-VisitedMap {
    param([string]$MapName)
    return $global:GameState.VisitedMaps -contains $MapName
}

Write-Host "Quest System initialized successfully!" -ForegroundColor Green
