# Engine/DialogueEngine.ps1 - NPC Dialogue Tree System
# Phase 3 implementation - currently contains basic dialogue display.
# Will be expanded to support branching trees, triggers, and quests.

function Update-Dialogue {
    <#
    .SYNOPSIS
        Handles the dialogue game mode. Loads NPC dialogue data and
        presents conversation options to the player.
    #>

    $target = $Script:GameState.DialogueTarget
    if (-not $target) {
        Add-GameMessage "Nothing to talk to."
        $Script:GameState.GameMode = 'Exploration'
        return
    }

    $npcId = $target.Action.npcId
    $npcName = $target.Name

    # For shop tiles that don't have npcId, derive from shopId
    if (-not $npcId -and $target.Action.type -eq 'shop') {
        # Look for an NPC file matching "shopkeeper_<name>" pattern
        $shopNpcPath = Join-Path $Script:GameRoot "Data\NPCs\shopkeeper_mira.json"
        if (Test-Path $shopNpcPath) {
            $npcId = 'shopkeeper_mira'
        }
    }

    # Try to load NPC dialogue file
    $dialoguePath = Join-Path $Script:GameRoot "Data\NPCs\$npcId.json"
    $dialogue = $null

    if (Test-Path $dialoguePath) {
        try {
            $dialogue = Get-Content $dialoguePath -Raw | ConvertFrom-Json
        }
        catch {
            $dialogue = $null
        }
    }

    if (-not $dialogue) {
        # No dialogue file - show generic message
        Show-SimpleDialogue -SpeakerName $npcName -Lines @(
            "$npcName doesn't have much to say right now.",
            "(Dialogue file not found: $npcId.json)"
        )
        $Script:GameState.GameMode = 'Exploration'
        return
    }

    # Process dialogue tree starting from the entry node
    $currentNode = Get-DialogueNode -Dialogue $dialogue -NodeId "start"
    if (-not $currentNode) {
        $currentNode = Get-DialogueNode -Dialogue $dialogue -NodeId $dialogue.entryNode
    }

    while ($currentNode) {
        # Check if this node has a trigger condition
        if ($currentNode.condition) {
            $conditionMet = Test-DialogueCondition -Condition $currentNode.condition
            if (-not $conditionMet -and $currentNode.elseNode) {
                $currentNode = Get-DialogueNode -Dialogue $dialogue -NodeId $currentNode.elseNode
                continue
            }
            elseif (-not $conditionMet) {
                break
            }
        }

        # Routing node: if text is empty, skip display and follow nextNode silently
        if (-not $currentNode.text -or $currentNode.text -eq '') {
            if ($currentNode.effect) {
                Invoke-DialogueEffect -Effect $currentNode.effect
            }
            if ($currentNode.nextNode) {
                $currentNode = Get-DialogueNode -Dialogue $dialogue -NodeId $currentNode.nextNode
            } else {
                $currentNode = $null
            }
            continue
        }

        # Display the dialogue text
        $lines = @($currentNode.text)
        $speakerName = if ($currentNode.speaker) { $currentNode.speaker } else { $npcName }

        if ($currentNode.choices -and $currentNode.choices.Count -gt 0) {
            # Filter choices by condition (only show choices whose conditions are met)
            $visibleChoices = @()
            foreach ($ch in $currentNode.choices) {
                if ($ch.condition) {
                    $met = Test-DialogueCondition -Condition $ch.condition
                    if ($met) { $visibleChoices += $ch }
                } else {
                    $visibleChoices += $ch
                }
            }
            if ($visibleChoices.Count -eq 0) { $visibleChoices = @($currentNode.choices) }

            # Show dialogue with choices
            Show-SimpleDialogue -SpeakerName $speakerName -Lines $lines
            $choiceLabels = $visibleChoices | ForEach-Object { $_.label }
            $choiceIndex = Show-DialogueChoices -Choices $choiceLabels

            $selectedChoice = $visibleChoices[$choiceIndex]

            # Apply any triggers from the choice
            if ($selectedChoice.setTrigger) {
                $Script:GameState.Triggers[$selectedChoice.setTrigger] = $true
            }

            # Navigate to next node
            if ($selectedChoice.nextNode) {
                $currentNode = Get-DialogueNode -Dialogue $dialogue -NodeId $selectedChoice.nextNode
            }
            else {
                $currentNode = $null
            }
        }
        else {
            # Simple text, no choices
            Show-SimpleDialogue -SpeakerName $speakerName -Lines $lines

            # Apply any triggers
            if ($currentNode.setTrigger) {
                $Script:GameState.Triggers[$currentNode.setTrigger] = $true
            }

            # Apply any special effects
            if ($currentNode.effect) {
                Invoke-DialogueEffect -Effect $currentNode.effect
            }

            # Navigate to next node
            if ($currentNode.nextNode) {
                $currentNode = Get-DialogueNode -Dialogue $dialogue -NodeId $currentNode.nextNode
            }
            else {
                $currentNode = $null
            }
        }
    }

    $Script:GameState.DialogueTarget = $null
    # Only reset to Exploration if an effect didn't already switch mode (e.g. combat)
    if ($Script:GameState.GameMode -eq 'Dialogue') {
        $Script:GameState.GameMode = 'Exploration'
    }
    Invoke-ForceFullRedraw
}

function Get-DialogueNode {
    param(
        [object]$Dialogue,
        [string]$NodeId
    )
    if (-not $NodeId -or -not $Dialogue.nodes) { return $null }
    $node = $Dialogue.nodes | Where-Object { $_.id -eq $NodeId }
    return $node
}

function Test-DialogueCondition {
    <#
    .SYNOPSIS
        Tests a dialogue condition against the current trigger state.
    #>
    param([object]$Condition)

    if ($Condition.trigger) {
        $triggerName = $Condition.trigger
        $actualValue = $Script:GameState.Triggers[$triggerName]

        # Numeric minimum check: { "trigger": "goblin_kills", "minValue": 3 }
        if ($null -ne $Condition.minValue) {
            $result = ([int]$actualValue -ge [int]$Condition.minValue)
        }
        else {
            # Exact value check: { "trigger": "foo", "value": 2 }
            $expectedValue = if ($null -ne $Condition.value) { $Condition.value } else { $true }
            $result = ($actualValue -eq $expectedValue)
        }

        # Negate support: { "trigger": "boss_defeated", "negate": true }
        if ($Condition.negate -eq $true) { return (-not $result) }
        return $result
    }
    return $true
}

function Show-SimpleDialogue {
    <#
    .SYNOPSIS
        Shows dialogue text in a box at the bottom of the screen.
        Waits for keypress to advance.
    #>
    param(
        [string]$SpeakerName,
        [string[]]$Lines
    )

    # Word-wrap lines to fit dialogue box
    $maxWidth = 110
    $wrappedLines = @()
    foreach ($line in $Lines) {
        if ($line.Length -le $maxWidth) {
            $wrappedLines += $line
        }
        else {
            # Simple word wrap
            $words = $line -split ' '
            $current = ""
            foreach ($word in $words) {
                if (($current.Length + $word.Length + 1) -gt $maxWidth) {
                    $wrappedLines += $current
                    $current = $word
                }
                else {
                    if ($current) { $current += " " }
                    $current += $word
                }
            }
            if ($current) { $wrappedLines += $current }
        }
    }

    # Draw dialogue box over the bottom portion of screen
    $boxY = $Script:SCREEN_HEIGHT - 8
    $boxHeight = 7
    Draw-Box -X 2 -Y $boxY -Width 116 -Height $boxHeight -Color ([ConsoleColor]::White) -BgColor ([ConsoleColor]::Black) -Fill
    Set-Text -X 4 -Y $boxY -Text " $SpeakerName " -FgColor ([ConsoleColor]::Yellow) -BgColor ([ConsoleColor]::Black)

    for ($i = 0; $i -lt $wrappedLines.Count -and $i -lt ($boxHeight - 2); $i++) {
        Set-Text -X 4 -Y ($boxY + 1 + $i) -Text $wrappedLines[$i] -FgColor ([ConsoleColor]::White) -BgColor ([ConsoleColor]::Black)
    }

    $promptText = "[Press any key to continue]"
    Set-Text -X (116 - $promptText.Length) -Y ($boxY + $boxHeight - 2) -Text $promptText -FgColor ([ConsoleColor]::DarkGray) -BgColor ([ConsoleColor]::Black)

    Invoke-RenderFrame
    Wait-ForKey | Out-Null
}

function Show-DialogueChoices {
    <#
    .SYNOPSIS
        Shows a list of dialogue choices. Returns the index of the selected choice.
    #>
    param([string[]]$Choices)

    $boxY = $Script:SCREEN_HEIGHT - 8
    $choiceIndex = Draw-SelectionMenu -X 5 -Y ($boxY - $Choices.Count - 2) `
                                       -Width 50 -Title "Choose" -Options $Choices `
                                       -BorderColor ([ConsoleColor]::Yellow) `
                                       -TextColor ([ConsoleColor]::White)
    return $choiceIndex
}

function Invoke-DialogueEffect {
    <#
    .SYNOPSIS
        Executes a special effect triggered by a dialogue node.
    #>
    param([string]$Effect)

    switch ($Effect) {
        'heal_party' {
            foreach ($member in $Script:GameState.Party) {
                $member.HP = $member.MaxHP
                $member.MP = $member.MaxMP
            }
            Add-GameMessage "Your party has been fully healed!"
        }
        'open_shop_buy' {
            # Find the shop ID from the dialogue target
            $shopId = 'general_store'
            if ($Script:GameState.DialogueTarget -and $Script:GameState.DialogueTarget.Action.shopId) {
                $shopId = $Script:GameState.DialogueTarget.Action.shopId
            }
            Show-ShopBuy -ShopId $shopId
            Invoke-ForceFullRedraw
        }
        'open_shop_sell' {
            Show-ShopSell
            Invoke-ForceFullRedraw
        }
        default {
            # Check for quest start/complete patterns
            if ($Effect -match '^start_quest_(.+)$') {
                Start-Quest -QuestId $Matches[1]
            }
            elseif ($Effect -match '^complete_quest_(.+)$') {
                Complete-Quest -QuestId $Matches[1]
            }
            elseif ($Effect -match '^start_battle_(.+)$') {
                Start-ScriptedBattle -BattleId $Matches[1]
            }
            elseif ($Effect -match '^play_cutscene_(.+)$') {
                Play-Cutscene -CutsceneId $Matches[1]
            }
            # Unknown effect - ignore silently
        }
    }
}
