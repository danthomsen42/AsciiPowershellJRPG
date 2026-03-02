# Engine/QuestEngine.ps1 - Quest Tracking, Secret Discovery, and Quest Log

# ── Quest Data ───────────────────────────────────────────────────────────────────
$Script:QuestDefinitions = $null
$Script:SecretDefinitions = $null

function Load-QuestDefinitions {
    $path = Join-Path $Script:GameRoot "Data\Quests.json"
    if (Test-Path $path) {
        $Script:QuestDefinitions = (Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json).quests
    } else {
        $Script:QuestDefinitions = @()
    }
}

function Load-SecretDefinitions {
    $path = Join-Path $Script:GameRoot "Data\Secrets.json"
    if (Test-Path $path) {
        $Script:SecretDefinitions = (Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json).secrets
    } else {
        $Script:SecretDefinitions = $null
    }
}

# ── Quest State Helpers ──────────────────────────────────────────────────────────

function Start-Quest {
    <#
    .SYNOPSIS  Marks a quest as started via its trigger flag.
    #>
    param([string]$QuestId)
    if (-not $Script:QuestDefinitions) { Load-QuestDefinitions }
    $quest = $Script:QuestDefinitions | Where-Object { $_.id -eq $QuestId }
    if ($quest) {
        $Script:GameState.Triggers[$quest.triggerStart] = $true
        Add-GameMessage "Quest started: $($quest.name)"
    }
}

function Complete-Quest {
    <#
    .SYNOPSIS  Marks a quest as completed and grants rewards.
    #>
    param([string]$QuestId)
    if (-not $Script:QuestDefinitions) { Load-QuestDefinitions }
    $quest = $Script:QuestDefinitions | Where-Object { $_.id -eq $QuestId }
    if (-not $quest) { return }

    $Script:GameState.Triggers[$quest.triggerComplete] = $true

    # Grant rewards
    if ($quest.rewards) {
        if ($quest.rewards.gold) {
            $Script:GameState.Gold += [int]$quest.rewards.gold
            Add-GameMessage "Received $([int]$quest.rewards.gold) gold!"
        }
        if ($quest.rewards.exp) {
            foreach ($m in $Script:GameState.Party) {
                if ([int]$m.HP -gt 0) {
                    Add-EXP -Character $m -Amount ([int]$quest.rewards.exp) | Out-Null
                }
            }
            Add-GameMessage "Party gained $([int]$quest.rewards.exp) EXP!"
        }
        if ($quest.rewards.items) {
            foreach ($itemId in $quest.rewards.items) {
                Add-InventoryItem -ItemId $itemId
            }
            Add-GameMessage "Received quest reward items!"
        }
    }

    Add-GameMessage "Quest completed: $($quest.name)!"
    Invoke-CheckCutscenes -EventType 'quest_complete' -EventData $QuestId
}

function Get-QuestStatus {
    <#
    .SYNOPSIS  Returns 'not_started', 'active', or 'completed' for a quest.
    #>
    param([string]$QuestId)
    if (-not $Script:QuestDefinitions) { Load-QuestDefinitions }
    $quest = $Script:QuestDefinitions | Where-Object { $_.id -eq $QuestId }
    if (-not $quest) { return 'not_started' }

    if ($Script:GameState.Triggers[$quest.triggerComplete]) { return 'completed' }
    if ($Script:GameState.Triggers[$quest.triggerStart])    { return 'active' }
    return 'not_started'
}

# ── Quest Log UI ─────────────────────────────────────────────────────────────────

function Show-QuestLog {
    <#
    .SYNOPSIS  Displays active and completed quests with objective tracking.
    #>
    if (-not $Script:QuestDefinitions) { Load-QuestDefinitions }

    $activeQuests    = @()
    $completedQuests = @()

    foreach ($quest in $Script:QuestDefinitions) {
        $status = Get-QuestStatus -QuestId $quest.id
        if ($status -eq 'active')    { $activeQuests += $quest }
        if ($status -eq 'completed') { $completedQuests += $quest }
    }

    $sel = 0
    while ($true) {
        Clear-FrameBuffer
        Draw-Box -X 5 -Y 1 -Width 110 -Height 28 -Color ([ConsoleColor]::Magenta) -BgColor ([ConsoleColor]::Black) -Fill
        Set-Text -X 7 -Y 1 -Text ' Quest Log ' -FgColor ([ConsoleColor]::Magenta)

        $y = 3
        # Active quests
        Set-Text -X 8 -Y $y -Text '--- Active Quests ---' -FgColor ([ConsoleColor]::Yellow)
        $y++

        if ($activeQuests.Count -eq 0) {
            Set-Text -X 10 -Y $y -Text 'No active quests.' -FgColor ([ConsoleColor]::DarkGray)
            $y++
        } else {
            foreach ($q in $activeQuests) {
                Set-Text -X 10 -Y $y -Text "* $($q.name)" -FgColor ([ConsoleColor]::White)
                $y++
                Set-Text -X 12 -Y $y -Text $q.description -FgColor ([ConsoleColor]::Gray)
                $y++

                # Render objectives with checkmarks and progress
                if ($q.objectives) {
                    foreach ($obj in $q.objectives) {
                        $objText   = ''
                        $objColor  = [ConsoleColor]::DarkGray
                        $checkMark = '[ ]'

                        if ($obj -is [string]) {
                            # Legacy plain-string objective (backwards compat)
                            $objText = $obj
                        }
                        elseif ($obj.type -eq 'counter') {
                            $current = [int]$Script:GameState.Triggers[$obj.trigger]
                            $target  = [int]$obj.target
                            if ($current -ge $target) {
                                $checkMark = '[X]'
                                $objColor  = [ConsoleColor]::Green
                                $objText   = ($obj.format -replace '\{current\}', $target) -replace '\{target\}', $target
                            } else {
                                $objText = ($obj.format -replace '\{current\}', $current) -replace '\{target\}', $target
                                $objColor = [ConsoleColor]::Yellow
                            }
                        }
                        elseif ($obj.type -eq 'trigger') {
                            $objText = $obj.text
                            if ($Script:GameState.Triggers[$obj.trigger]) {
                                $checkMark = '[X]'
                                $objColor  = [ConsoleColor]::Green
                            }
                        }
                        else {
                            $objText = if ($obj.text) { $obj.text } else { "$obj" }
                        }

                        Set-Text -X 14 -Y $y -Text "$checkMark $objText" -FgColor $objColor
                        $y++
                    }
                }

                # Show reward info for active quests
                if ($q.rewardSummary) {
                    Set-Text -X 14 -Y $y -Text "Reward: $($q.rewardSummary)" -FgColor ([ConsoleColor]::DarkCyan)
                    $y++
                }
                $y++
            }
        }

        # Completed quests
        if ($y -lt 22) { $y++ }
        Set-Text -X 8 -Y $y -Text '--- Completed Quests ---' -FgColor ([ConsoleColor]::Green)
        $y++

        if ($completedQuests.Count -eq 0) {
            Set-Text -X 10 -Y $y -Text 'No completed quests.' -FgColor ([ConsoleColor]::DarkGray)
        } else {
            foreach ($q in $completedQuests) {
                $rewardStr = if ($q.rewardSummary) { " - Reward: $($q.rewardSummary)" } else { '' }
                Set-Text -X 10 -Y $y -Text "[X] $($q.name)$rewardStr" -FgColor ([ConsoleColor]::DarkGreen)
                $y++

                # Show objectives all checked off
                if ($q.objectives) {
                    foreach ($obj in $q.objectives) {
                        $objText = if ($obj -is [string]) { $obj } elseif ($obj.text) { $obj.text } else { "$obj" }
                        # For counter objectives on completed quests, show the completed format
                        if ($obj.type -eq 'counter' -and $obj.format) {
                            $objText = ($obj.format -replace '\{current\}', $obj.target) -replace '\{target\}', $obj.target
                        }
                        Set-Text -X 14 -Y $y -Text "[X] $objText" -FgColor ([ConsoleColor]::DarkGreen)
                        $y++
                    }
                }
                $y++
            }
        }

        Set-Text -X 8 -Y 27 -Text 'Press any key to return...' -FgColor ([ConsoleColor]::DarkGray)
        Invoke-RenderFrame

        Wait-ForKey | Out-Null
        return
    }
}

# ── Secrets / Hidden Item Discovery ──────────────────────────────────────────────

function Invoke-CheckSecret {
    <#
    .SYNOPSIS
        Called when the player presses E (interact) near a wall.
        Checks if the player's adjacent tiles contain a hidden secret
        for the current map. Uses triggers to track already-found secrets.
    #>
    param(
        [int]$PlayerX,
        [int]$PlayerY,
        [string]$MapName
    )

    if (-not $Script:SecretDefinitions) { Load-SecretDefinitions }
    if (-not $Script:SecretDefinitions) { return $false }

    $mapSecrets = $null
    $prop = $Script:SecretDefinitions.PSObject.Properties[$MapName]
    if ($prop) { $mapSecrets = @($prop.Value) }
    if (-not $mapSecrets -or $mapSecrets.Count -eq 0) { return $false }

    # Check all adjacent wall positions
    $checkPositions = @(
        @{ X = $PlayerX;     Y = $PlayerY - 1 },
        @{ X = $PlayerX;     Y = $PlayerY + 1 },
        @{ X = $PlayerX - 1; Y = $PlayerY },
        @{ X = $PlayerX + 1; Y = $PlayerY }
    )

    foreach ($secret in $mapSecrets) {
        $sx = [int]($secret.position.x)
        $sy = [int]($secret.position.y)

        foreach ($pos in $checkPositions) {
            if ([int]$pos.X -eq $sx -and [int]$pos.Y -eq $sy) {
                # Found a secret at this position
                $triggerName = $secret.trigger

                if ($Script:GameState.Triggers[$triggerName]) {
                    # Already discovered
                    Add-GameMessage $secret.emptyDescription
                    return $true
                }

                # New discovery!
                $Script:GameState.Triggers[$triggerName] = $true
                Add-GameMessage $secret.description

                # Grant reward
                if ($secret.reward) {
                    switch ($secret.reward.type) {
                        'item' {
                            $count = if ($secret.reward.count) { [int]$secret.reward.count } else { 1 }
                            for ($i = 0; $i -lt $count; $i++) {
                                Add-InventoryItem -ItemId $secret.reward.itemId
                            }
                            $def = Get-ItemDefinition -ItemId $secret.reward.itemId
                            $itemName = if ($def) { $def.name } else { $secret.reward.itemId }
                            Add-GameMessage "Found $count x $itemName!"
                        }
                        'gold' {
                            $amount = [int]$secret.reward.amount
                            $Script:GameState.Gold += $amount
                            Add-GameMessage "Found $amount gold!"
                        }
                        'trigger' {
                            if ($secret.reward.setTrigger) {
                                $Script:GameState.Triggers[$secret.reward.setTrigger] = $true
                            }
                        }
                    }
                }
                return $true
            }
        }
    }

    return $false
}
