# Engine/Core.ps1 - Core Game Loop, State Management, and HUD Rendering
# This file is loaded LAST because it depends on all other engine modules.

# Set to $true to enable the F9 debug cutscene player.
$Script:DebugMode = $true

# ── Global Game State ────────────────────────────────────────────────────────────

$Script:GameState = @{
    CurrentMap       = $null
    CurrentMapConfig = $null
    CurrentMapName   = ''
    PlayerPosition   = @{ X = 0; Y = 0 }
    Party            = @()
    Inventory        = @()
    Gold             = 0
    Triggers         = @{}
    GameMode         = 'TitleScreen'   # TitleScreen | PartyCreation | Exploration | Combat | Dialogue | Menu | GameOver
    Running          = $true
    Messages         = @()
    StepCounter      = 0
    DialogueTarget   = $null
}

# ── Initialization ───────────────────────────────────────────────────────────────

function Initialize-Game {
    Initialize-Renderer
    Load-ClassDefinitions
}

# ── Main Game Loop ───────────────────────────────────────────────────────────────

function Start-GameLoop {
    # Show title screen first
    Show-TitleScreen

    while ($Script:GameState.Running) {
        switch ($Script:GameState.GameMode) {
            'TitleScreen'    { Show-TitleScreen }
            'PartyCreation'  {
                Show-PartyCreation
                Invoke-LoadStartingMap
                Invoke-CheckCutscenes -EventType 'game_start'
                $Script:GameState.GameMode = 'Exploration'
            }
            'Exploration'    { Update-Exploration }
            'Combat'         { Update-Combat }
            'Dialogue'       { Update-Dialogue }
            'Menu'           { Show-GameMenu }
            'GameOver'       { Show-GameOver }
        }
    }
}

# ── Title Screen ─────────────────────────────────────────────────────────────────

function Show-TitleScreen {
    Clear-FrameBuffer

    # ASCII art title
    $titleArt = @(
        "    _    ____   ____ ___ ___      _ ____  ____   ____ "
        "   / \  / ___| / ___|_ _|_ _|   | |  _ \|  _ \ / ___|"
        "  / _ \ \___ \| |    | | | | _  | | |_) | |_) | |  _ "
        " / ___ \ ___) | |___ | | | || |_| |  __/|  _ <| |_| |"
        "/_/   \_\____/ \____|___|___\___/|_|   |_| \_\\____|"
    )

    $startY = 4
    foreach ($line in $titleArt) {
        $startX = [math]::Floor(($Script:SCREEN_WIDTH - $line.Length) / 2)
        if ($startX -lt 0) { $startX = 0 }
        Set-Text -X $startX -Y $startY -Text $line -FgColor ([ConsoleColor]::Cyan)
        $startY++
    }

    # Subtitle
    $subtitle = "~ The Thornvale Chronicles ~"
    Set-Text -X ([math]::Floor(($Script:SCREEN_WIDTH - $subtitle.Length) / 2)) -Y 11 -Text $subtitle -FgColor ([ConsoleColor]::DarkCyan)

    $subtitle2 = "A PowerShell JRPG Adventure"
    Set-Text -X ([math]::Floor(($Script:SCREEN_WIDTH - $subtitle2.Length) / 2)) -Y 13 -Text $subtitle2 -FgColor ([ConsoleColor]::DarkGray)

    # Menu options
    $options = @("New Game", "Load Game", "Quit")
    $selected = Draw-SelectionMenu -X 45 -Y 16 -Width 30 -Title "Main Menu" `
                                    -Options $options `
                                    -BorderColor ([ConsoleColor]::White) `
                                    -TextColor ([ConsoleColor]::Yellow)

    switch ($selected) {
        0 {
            $Script:GameState.GameMode = 'PartyCreation'
        }
        1 {
            # Show save picker for loading
            $loaded = Show-LoadPicker
            if ($loaded) {
                $Script:GameState.GameMode = 'Exploration'
                Add-GameMessage "Game loaded successfully."
            }
            else {
                Clear-FrameBuffer
                $msg = "No save files found, or load was cancelled."
                Set-Text -X ([math]::Floor(($Script:SCREEN_WIDTH - $msg.Length) / 2)) -Y 15 -Text $msg -FgColor ([ConsoleColor]::Red)
                Set-Text -X ([math]::Floor(($Script:SCREEN_WIDTH - 25) / 2)) -Y 17 -Text "Press any key to return..." -FgColor ([ConsoleColor]::DarkGray)
                Invoke-RenderFrame
                Wait-ForKey | Out-Null
                # Stay on title screen
            }
        }
        2 {
            $Script:GameState.Running = $false
        }
    }
}

# ── Starting Map ─────────────────────────────────────────────────────────────────

function Invoke-LoadStartingMap {
    $Script:GameState.CurrentMap       = Load-Map       -MapName    "Map-TestTown-1"
    $Script:GameState.CurrentMapConfig = Load-MapConfig -ConfigName "MapConfig-TestTown-1"
    $Script:GameState.CurrentMapName   = "Map-TestTown-1"

    $config = $Script:GameState.CurrentMapConfig
    if ($config.startPosition) {
        $Script:GameState.PlayerPosition.X = [int]($config.startPosition.x)
        $Script:GameState.PlayerPosition.Y = [int]($config.startPosition.y)
    }
    else {
        $Script:GameState.PlayerPosition.X = 2
        $Script:GameState.PlayerPosition.Y = 2
    }

    Add-GameMessage "Welcome to $($config.displayName)!"
    Apply-TileOverrides
    Invoke-ForceFullRedraw
}

# ── Exploration Mode ─────────────────────────────────────────────────────────────

function Update-Exploration {
    Clear-FrameBuffer

    $map    = $Script:GameState.CurrentMap
    $config = $Script:GameState.CurrentMapConfig
    $px     = $Script:GameState.PlayerPosition.X
    $py     = $Script:GameState.PlayerPosition.Y

    # ── Header bar (row 0) ──
    $locName = if ($config.displayName) { $config.displayName } else { $Script:GameState.CurrentMapName }
    Set-Text -X 1 -Y 0 -Text $locName -FgColor ([ConsoleColor]::Cyan)

    $stepText = "Steps: $($Script:GameState.StepCounter)"
    Set-Text -X ($Script:SCREEN_WIDTH - $stepText.Length - 1) -Y 0 -Text $stepText -FgColor ([ConsoleColor]::DarkGray)

    # ── Map viewport ──
    Render-Map -MapData $map -MapConfig $config -PlayerX $px -PlayerY $py

    # ── Party status panel (right side) ──
    Render-PartyPanel

    # ── Message bar (bottom) ──
    Render-MessageBar

    Invoke-RenderFrame

    # ── Handle input (non-blocking with animation support) ──
    # Returns $null on animation tick (no key pressed) — loop re-renders with
    # updated water colors. Returns the key when player presses something.
    $key = Wait-ForMovementKeyOrAnimation -AnimIntervalMs 300

    if ($null -eq $key) { return }   # Animation tick — just re-render next frame

    switch ($key.Key) {
        'UpArrow'    { Move-Player -DX 0  -DY -1 }
        'DownArrow'  { Move-Player -DX 0  -DY 1 }
        'LeftArrow'  { Move-Player -DX -1 -DY 0 }
        'RightArrow' { Move-Player -DX 1  -DY 0 }
        'W'          { Move-Player -DX 0  -DY -1 }
        'S'          { Move-Player -DX 0  -DY 1 }
        'A'          { Move-Player -DX -1 -DY 0 }
        'D'          { Move-Player -DX 1  -DY 0 }
        'E'          { Invoke-Interact }
        'Escape'     { $Script:GameState.GameMode = 'Menu' }
        'M'          { $Script:GameState.GameMode = 'Menu' }
        'F9'         { if ($Script:DebugMode) { Invoke-DebugCutscenePlayer } }
    }
}

# ── Interact (E key) ────────────────────────────────────────────────────────────

function Invoke-Interact {
    $px     = $Script:GameState.PlayerPosition.X
    $py     = $Script:GameState.PlayerPosition.Y
    $map    = $Script:GameState.CurrentMap
    $config = $Script:GameState.CurrentMapConfig

    $target = Get-InteractTarget -PlayerX $px -PlayerY $py -MapData $map -MapConfig $config

    if (-not $target) {
        # Check for hidden secrets at adjacent walls
        $foundSecret = Invoke-CheckSecret -PlayerX $px -PlayerY $py -MapName $Script:GameState.CurrentMapName
        if (-not $foundSecret) {
            Add-GameMessage "Nothing to interact with here."
        }
        return
    }

    $action = $target.Action
    switch ($action.type) {
        'npc' {
            $Script:GameState.DialogueTarget = $target
            $Script:GameState.GameMode = 'Dialogue'
        }
        'shop' {
            $Script:GameState.DialogueTarget = $target
            $Script:GameState.GameMode = 'Dialogue'
        }
        'sign' {
            Add-GameMessage "$($target.Name): $($action.text)"
        }
        default {
            # Check for hidden secrets even if there's a non-interactive tile
            $foundSecret = Invoke-CheckSecret -PlayerX $px -PlayerY $py -MapName $Script:GameState.CurrentMapName
            if (-not $foundSecret) {
                Add-GameMessage "You examine the $($target.Name)."
            }
        }
    }
}

# ── Debug Cutscene Player (F9 when $Script:DebugMode = $true) ────────────────────

function Invoke-DebugCutscenePlayer {
    <#
    .SYNOPSIS
        Lists all cutscene JSON files and lets the modder pick one to play instantly.
        Only available when $Script:DebugMode = $true.
    #>
    $cutsceneDir = Join-Path $Script:GameRoot 'Cutscenes'
    $files = @(Get-ChildItem -Path $cutsceneDir -Filter '*.json' |
               Where-Object { $_.Name -ne 'Cutscenes.json' } |
               Sort-Object Name)

    if ($files.Count -eq 0) {
        Add-GameMessage "Debug: No cutscene files found."
        return
    }

    $options = @($files | ForEach-Object { $_.BaseName })
    $options += '<Cancel>'

    $idx = Draw-SelectionMenu -X 10 -Y 3 -Width 50 -Title 'Debug: Play Cutscene' `
                              -Options $options `
                              -BorderColor ([ConsoleColor]::Magenta) `
                              -TextColor ([ConsoleColor]::White)

    if ($idx -ge $files.Count) { return }   # cancelled

    $id = $files[$idx].BaseName
    Play-Cutscene -CutsceneId $id
    Invoke-ForceFullRedraw
}

# ── HUD Rendering ────────────────────────────────────────────────────────────────

function Render-PartyPanel {
    $panelX      = 82
    $panelY      = 1
    $panelWidth  = 37
    $panelHeight = 24

    Draw-Box -X $panelX -Y $panelY -Width $panelWidth -Height $panelHeight -Color ([ConsoleColor]::DarkCyan) -Fill
    Set-Text -X ($panelX + 2) -Y $panelY -Text " Party " -FgColor ([ConsoleColor]::Cyan)

    $y = $panelY + 1
    foreach ($member in $Script:GameState.Party) {
        if ($null -eq $member) { continue }

        # Name and level
        $nameText = "$($member.Symbol) $($member.Name) Lv.$($member.Level)"
        Set-Text -X ($panelX + 2) -Y $y -Text $nameText -FgColor ([ConsoleColor]::White)
        $y++

        # HP bar
        $hpPct = if ([int]$member.MaxHP -gt 0) { [int]$member.HP / [int]$member.MaxHP } else { 0 }
        $hpColor = if ($hpPct -gt 0.5) { [ConsoleColor]::Green }
                   elseif ($hpPct -gt 0.25) { [ConsoleColor]::Yellow }
                   else { [ConsoleColor]::Red }
        Set-Text -X ($panelX + 2) -Y $y -Text "HP:" -FgColor ([ConsoleColor]::Gray)
        Draw-ProgressBar -X ($panelX + 5) -Y $y -Width 18 -Percent $hpPct -FilledColor $hpColor
        $hpText = "$($member.HP)/$($member.MaxHP)"
        Set-Text -X ($panelX + 24) -Y $y -Text $hpText -FgColor ([ConsoleColor]::Gray)
        $y++

        # MP bar
        $mpPct = if ([int]$member.MaxMP -gt 0) { [int]$member.MP / [int]$member.MaxMP } else { 0 }
        Set-Text -X ($panelX + 2) -Y $y -Text "MP:" -FgColor ([ConsoleColor]::Gray)
        Draw-ProgressBar -X ($panelX + 5) -Y $y -Width 18 -Percent $mpPct -FilledColor ([ConsoleColor]::Blue)
        $mpText = "$($member.MP)/$($member.MaxMP)"
        Set-Text -X ($panelX + 24) -Y $y -Text $mpText -FgColor ([ConsoleColor]::Gray)
        $y++

        $y++  # spacing between members
    }

    # Gold at bottom of panel
    Set-Text -X ($panelX + 2) -Y ($panelY + $panelHeight - 2) -Text "Gold: $($Script:GameState.Gold)" -FgColor ([ConsoleColor]::DarkYellow)
}

function Render-MessageBar {
    $msgY     = 26
    $msgHeight = 4

    Draw-Box -X 0 -Y $msgY -Width $Script:SCREEN_WIDTH -Height $msgHeight -Color ([ConsoleColor]::DarkGray) -Fill

    # Show last 2 messages
    $messages = $Script:GameState.Messages
    if ($messages.Count -gt 0) {
        $start = [math]::Max(0, $messages.Count - 2)
        $drawY = $msgY + 1
        for ($i = $start; $i -lt $messages.Count -and $drawY -lt ($msgY + $msgHeight - 1); $i++) {
            $msgText = $messages[$i]
            if ($msgText.Length -gt ($Script:SCREEN_WIDTH - 4)) {
                $msgText = $msgText.Substring(0, $Script:SCREEN_WIDTH - 4)
            }
            Set-Text -X 2 -Y $drawY -Text $msgText -FgColor ([ConsoleColor]::Gray)
            $drawY++
        }
    }

    # Controls hint at very bottom
    Set-Text -X 2 -Y 29 -Text "[Arrows/WASD] Move  [E] Interact  [M/Esc] Menu" -FgColor ([ConsoleColor]::DarkGray)
}

# ── Game Menu ────────────────────────────────────────────────────────────────────

function Show-GameMenu {
    Clear-FrameBuffer

    $menuOptions = @("Party Status", "Party Management", "Inventory", "Quest Log", "Save Game", "Return to Game", "Quit to Title")

    $selected = Draw-SelectionMenu -X 35 -Y 6 -Width 50 -Title "Menu" `
                                    -Options $menuOptions `
                                    -BorderColor ([ConsoleColor]::White) `
                                    -TextColor ([ConsoleColor]::Yellow)

    switch ($selected) {
        0 { Show-PartyStatus }
        1 { Show-PartyManagement }
        2 { Show-Inventory }
        3 { Show-QuestLog }
        4 {
            $result = Show-SavePicker
            if ($result) {
                Add-GameMessage "Saved to '$result'!"
            }
            $Script:GameState.GameMode = 'Exploration'
        }
        5 { $Script:GameState.GameMode = 'Exploration' }
        6 { $Script:GameState.GameMode = 'TitleScreen' }
    }

    Invoke-ForceFullRedraw
}

function Show-PartyStatus {
    Clear-FrameBuffer

    Draw-TextBox -X 5 -Y 1 -Width 110 -Height 28 -Title "Party Status" `
                 -BorderColor ([ConsoleColor]::Cyan) -BgColor ([ConsoleColor]::Black)

    $y = 3
    foreach ($member in $Script:GameState.Party) {
        if ($null -eq $member) { continue }

        Set-Text -X 8 -Y $y -Text "[$($member.Symbol)] $($member.Name) - $($member.Class) (Level $($member.Level))" -FgColor ([ConsoleColor]::White)
        $y++
        Set-Text -X 10 -Y $y -Text "HP: $($member.HP)/$($member.MaxHP)  MP: $($member.MP)/$($member.MaxMP)  EXP: $($member.EXP)/$($member.EXPToNext)" -FgColor ([ConsoleColor]::Green)
        $y++
        Set-Text -X 10 -Y $y -Text "STR: $($member.Strength)  INT: $($member.Intelligence)  SPD: $($member.Speed)  DEF: $($member.Defense)  ACC: $($member.Accuracy)" -FgColor ([ConsoleColor]::Gray)
        $y++
        Set-Text -X 10 -Y $y -Text "Weapon: $($member.Equipment.Weapon)  Armor: $($member.Equipment.Armor)  Accessory: $(if($member.Equipment.Accessory){$member.Equipment.Accessory}else{'(none)'})" -FgColor ([ConsoleColor]::DarkGray)
        $y++
        Set-Text -X 10 -Y $y -Text "Main: $($member.MainAttack)  Skills: $(($member.SecondaryAbilities -join ', '))" -FgColor ([ConsoleColor]::DarkGray)
        $y += 2
    }

    Set-Text -X 8 -Y 26 -Text "Press any key to return..." -FgColor ([ConsoleColor]::DarkGray)
    Invoke-RenderFrame
    Wait-ForKey | Out-Null
    $Script:GameState.GameMode = 'Menu'
}

function Show-Inventory {
    Clear-FrameBuffer

    $lines = @()
    if ($Script:GameState.Inventory.Count -eq 0) {
        $lines += "Your inventory is empty."
    }
    else {
        foreach ($item in $Script:GameState.Inventory) {
            $qty = if ($item.count) { $item.count } elseif ($item.Quantity) { $item.Quantity } else { 1 }
            # Look up real definition to fix items saved before the name-lookup fix
            $def = Get-ItemDefinition -ItemId $item.id
            if (-not $def -and $item.name) { $def = Get-ItemDefinition -ItemId $item.name }
            $desc = if ($def) { $def.description } elseif ($item.description) { $item.description } elseif ($item.Description) { $item.Description } else { '' }
            $name = if ($def) { $def.name } elseif ($item.name) { $item.name } elseif ($item.Name) { $item.Name } else { $item.id }
            $lines += "$name x$qty - $desc"
        }
    }
    $lines += ""
    $lines += "Gold: $($Script:GameState.Gold)"

    $boxHeight = [math]::Max(6, $lines.Count + 4)
    if ($boxHeight -gt 24) { $boxHeight = 24 }

    Draw-TextBox -X 10 -Y 5 -Width 100 -Height $boxHeight -Title "Inventory" `
                 -Lines $lines -BorderColor ([ConsoleColor]::Yellow) -TextColor ([ConsoleColor]::Gray)

    Set-Text -X 12 -Y (5 + $boxHeight + 1) -Text "Press any key to return..." -FgColor ([ConsoleColor]::DarkGray)
    Invoke-RenderFrame
    Wait-ForKey | Out-Null
    $Script:GameState.GameMode = 'Menu'
}

function Show-GameOver {
    Clear-FrameBuffer

    $text = "G A M E   O V E R"
    Set-Text -X ([math]::Floor(($Script:SCREEN_WIDTH - $text.Length) / 2)) -Y 12 -Text $text -FgColor ([ConsoleColor]::Red)

    $subtext = "Press any key to return to title..."
    Set-Text -X ([math]::Floor(($Script:SCREEN_WIDTH - $subtext.Length) / 2)) -Y 15 -Text $subtext -FgColor ([ConsoleColor]::DarkGray)

    Invoke-RenderFrame
    Wait-ForKey | Out-Null
    $Script:GameState.GameMode = 'TitleScreen'
}

# ── Utility ──────────────────────────────────────────────────────────────────────

function Add-GameMessage {
    param([string]$Message)
    $Script:GameState.Messages += $Message
    # Keep only last 50 messages
    if ($Script:GameState.Messages.Count -gt 50) {
        $Script:GameState.Messages = @($Script:GameState.Messages | Select-Object -Last 50)
    }
}
