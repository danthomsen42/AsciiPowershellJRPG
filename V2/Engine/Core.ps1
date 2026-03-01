# Engine/Core.ps1 - Core Game Loop, State Management, and HUD Rendering
# This file is loaded LAST because it depends on all other engine modules.

# Set to $true to enable the F9 debug cutscene player.
$Script:DebugMode = $true

# ── Settings ─────────────────────────────────────────────────────────────────────

$Script:SettingsDefaults = @{
    DayNightCycle    = $true
    StatusEffects    = $true
    AutoSave         = $true
    LootRarityLabels = $true
    WorldMap         = $true
}

function Load-Settings {
    <# Loads settings from Data/Settings.json, falling back to defaults. #>
    $path = Join-Path $PSScriptRoot '..\Data\Settings.json'
    $Script:Settings = @{}
    foreach ($k in $Script:SettingsDefaults.Keys) {
        $Script:Settings[$k] = $Script:SettingsDefaults[$k]
    }
    if (Test-Path $path) {
        try {
            $json = Get-Content $path -Raw | ConvertFrom-Json
            foreach ($prop in $json.PSObject.Properties) {
                if ($prop.Name -ne '_comment' -and $Script:Settings.ContainsKey($prop.Name)) {
                    $Script:Settings[$prop.Name] = [bool]$prop.Value
                }
            }
        } catch { <# silently use defaults #> }
    }
}

function Save-Settings {
    <# Persists current settings to Data/Settings.json. #>
    $path = Join-Path $PSScriptRoot '..\Data\Settings.json'
    $obj = [ordered]@{
        _comment         = 'Game settings - toggle features on/off. Editable here or via in-game Settings menu.'
        DayNightCycle    = $Script:Settings.DayNightCycle
        StatusEffects    = $Script:Settings.StatusEffects
        AutoSave         = $Script:Settings.AutoSave
        LootRarityLabels = $Script:Settings.LootRarityLabels
        WorldMap         = $Script:Settings.WorldMap
    }
    $obj | ConvertTo-Json | Set-Content $path -Encoding UTF8
}

Load-Settings

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
    TimeOfDay        = 'Day'           # Dawn | Day | Dusk | Night
    DayCycleStep     = 0               # Steps within current phase
    DiscoveredMaps   = @{}             # Track visited maps for world map
}

# ── Day/Night Cycle ──────────────────────────────────────────────────────────────

$Script:DayCyclePhases = @('Dawn', 'Day', 'Dusk', 'Night')
$Script:DayCycleStepsPerPhase = 80   # Steps per phase (320 steps = full day)

# Color tinting map: maps ConsoleColor to a darker/lighter variant for night/dawn/dusk
$Script:NightColorMap = @{
    [ConsoleColor]::White     = [ConsoleColor]::Gray
    [ConsoleColor]::Gray      = [ConsoleColor]::DarkGray
    [ConsoleColor]::DarkGray  = [ConsoleColor]::DarkGray
    [ConsoleColor]::Cyan      = [ConsoleColor]::DarkCyan
    [ConsoleColor]::DarkCyan  = [ConsoleColor]::DarkBlue
    [ConsoleColor]::Green     = [ConsoleColor]::DarkGreen
    [ConsoleColor]::DarkGreen = [ConsoleColor]::DarkGreen
    [ConsoleColor]::Yellow    = [ConsoleColor]::DarkYellow
    [ConsoleColor]::DarkYellow= [ConsoleColor]::DarkYellow
    [ConsoleColor]::Red       = [ConsoleColor]::DarkRed
    [ConsoleColor]::DarkRed   = [ConsoleColor]::DarkRed
    [ConsoleColor]::Blue      = [ConsoleColor]::DarkBlue
    [ConsoleColor]::DarkBlue  = [ConsoleColor]::DarkBlue
    [ConsoleColor]::Magenta   = [ConsoleColor]::DarkMagenta
    [ConsoleColor]::DarkMagenta = [ConsoleColor]::DarkMagenta
}

$Script:DuskColorMap = @{
    [ConsoleColor]::White     = [ConsoleColor]::Yellow
    [ConsoleColor]::Gray      = [ConsoleColor]::DarkYellow
    [ConsoleColor]::Cyan      = [ConsoleColor]::DarkCyan
    [ConsoleColor]::Green     = [ConsoleColor]::DarkYellow
}

function Update-DayCycle {
    <# Advances the day/night cycle by one step. Call from Move-Player. #>
    if (-not $Script:Settings.DayNightCycle) { return }
    $Script:GameState.DayCycleStep++
    if ($Script:GameState.DayCycleStep -ge $Script:DayCycleStepsPerPhase) {
        $Script:GameState.DayCycleStep = 0
        $idx = $Script:DayCyclePhases.IndexOf($Script:GameState.TimeOfDay)
        $idx = ($idx + 1) % 4
        $Script:GameState.TimeOfDay = $Script:DayCyclePhases[$idx]
        $phaseName = $Script:GameState.TimeOfDay
        switch ($phaseName) {
            'Dawn'  { Add-GameMessage 'The first light of dawn breaks over the horizon.' }
            'Day'   { Add-GameMessage 'The sun climbs high. Daytime has arrived.' }
            'Dusk'  { Add-GameMessage 'The sun sets, painting the sky in warm hues.' }
            'Night' { Add-GameMessage 'Darkness falls. The night is upon you...' }
        }
        # Invalidate tile color cache for tint change
        $Script:_tileColorCache = $null
    }
}

function Get-TimeOfDayIcon {
    switch ($Script:GameState.TimeOfDay) {
        'Dawn'  { return '*' }
        'Day'   { return 'o' }
        'Dusk'  { return '*' }
        'Night' { return '.' }
    }
    return '?'
}

function Get-TintedColor {
    <# Returns a color tinted for current time of day. Only Night affects colors. #>
    param([ConsoleColor]$Color)
    if (-not $Script:Settings.DayNightCycle) { return $Color }
    $phase = $Script:GameState.TimeOfDay
    if ($phase -eq 'Night') {
        $mapped = $Script:NightColorMap[$Color]
        if ($mapped) { return $mapped }
    }
    elseif ($phase -eq 'Dusk') {
        $mapped = $Script:DuskColorMap[$Color]
        if ($mapped) { return $mapped }
    }
    return $Color
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
    $Script:GameState.DiscoveredMaps["Map-TestTown-1"] = $true

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

    # Time of day indicator (only when day/night cycle enabled)
    if ($Script:Settings.DayNightCycle) {
        $timeIcon = Get-TimeOfDayIcon
        $timeText = "[$timeIcon] $($Script:GameState.TimeOfDay)"
        $timeColor = switch ($Script:GameState.TimeOfDay) {
            'Dawn'  { [ConsoleColor]::Yellow }
            'Day'   { [ConsoleColor]::White }
            'Dusk'  { [ConsoleColor]::DarkYellow }
            'Night' { [ConsoleColor]::DarkCyan }
        }
        Set-Text -X 50 -Y 0 -Text $timeText -FgColor $timeColor
    }

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

    $menuOptions = @("Party Status", "Party Management", "Inventory", "Quest Log")
    if ($Script:Settings.WorldMap) { $menuOptions += "World Map" }
    $menuOptions += @("Settings", "Save Game", "Return to Game", "Quit to Title")

    $selected = Draw-SelectionMenu -X 35 -Y 6 -Width 50 -Title "Menu" `
                                    -Options $menuOptions `
                                    -BorderColor ([ConsoleColor]::White) `
                                    -TextColor ([ConsoleColor]::Yellow)

    $choice = $menuOptions[$selected]
    switch ($choice) {
        'Party Status'      { Show-PartyStatus }
        'Party Management'  { Show-PartyManagement }
        'Inventory'         { Show-Inventory }
        'Quest Log'         { Show-QuestLog }
        'World Map'         { Show-WorldMap }
        'Settings'          { Show-SettingsMenu }
        'Save Game'         {
            $result = Show-SavePicker
            if ($result) {
                Add-GameMessage "Saved to '$result'!"
            }
            $Script:GameState.GameMode = 'Exploration'
        }
        'Return to Game'    { $Script:GameState.GameMode = 'Exploration' }
        'Quit to Title'     { $Script:GameState.GameMode = 'TitleScreen' }
    }

    Invoke-ForceFullRedraw
}

# ── Settings Menu ────────────────────────────────────────────────────────────────

function Show-SettingsMenu {
    $settingKeys = @(
        @{ Key = 'DayNightCycle';    Label = 'Day/Night Cycle' }
        @{ Key = 'StatusEffects';    Label = 'Status Effects' }
        @{ Key = 'AutoSave';         Label = 'Auto-Save on Map Transitions' }
        @{ Key = 'LootRarityLabels'; Label = 'Loot Rarity Labels' }
        @{ Key = 'WorldMap';         Label = 'World Map Menu Option' }
    )

    $running = $true
    while ($running) {
        Clear-FrameBuffer

        Draw-TextBox -X 20 -Y 3 -Width 80 -Height 22 -Title "Settings" `
                     -BorderColor ([ConsoleColor]::Yellow) -BgColor ([ConsoleColor]::Black)

        $y = 5
        $options = @()
        foreach ($s in $settingKeys) {
            $val = $Script:Settings[$s.Key]
            $state = if ($val) { '[ON]  ' } else { '[OFF] ' }
            $options += "$state $($s.Label)"
        }
        $options += 'Back'

        $sel = Draw-SelectionMenu -X 30 -Y 6 -Width 60 -Title "Toggle Features" `
                                   -Options $options `
                                   -BorderColor ([ConsoleColor]::Yellow) `
                                   -TextColor ([ConsoleColor]::White)

        if ($sel -ge 0 -and $sel -lt $settingKeys.Count) {
            $key = $settingKeys[$sel].Key
            $Script:Settings[$key] = -not $Script:Settings[$key]
            # When disabling day/night mid-game, reset to Day to clear tinting
            if ($key -eq 'DayNightCycle' -and -not $Script:Settings[$key]) {
                $Script:GameState.TimeOfDay  = 'Day'
                $Script:GameState.DayCycleStep = 0
                $Script:_tileColorCache = $null
            }
            Save-Settings
        }
        else {
            $running = $false
        }
    }

    $Script:GameState.GameMode = 'Menu'
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
        # Show effective stats with equipment bonuses
        $bonuses = Get-AllEquipmentBonuses -Character $member
        $strB = if ($bonuses.Strength -gt 0) { "(+$($bonuses.Strength))" } else { '' }
        $intB = if ($bonuses.Intelligence -gt 0) { "(+$($bonuses.Intelligence))" } else { '' }
        $spdB = if ($bonuses.Speed -gt 0) { "(+$($bonuses.Speed))" } else { '' }
        $defB = if ($bonuses.Defense -gt 0) { "(+$($bonuses.Defense))" } else { '' }
        $accB = if ($bonuses.Accuracy -gt 0) { "(+$($bonuses.Accuracy))" } else { '' }
        $eSTR = Get-EffectiveStat -Entity $member -StatName 'Strength'
        $eINT = Get-EffectiveStat -Entity $member -StatName 'Intelligence'
        $eSPD = Get-EffectiveStat -Entity $member -StatName 'Speed'
        $eDEF = Get-EffectiveStat -Entity $member -StatName 'Defense'
        $eACC = Get-EffectiveStat -Entity $member -StatName 'Accuracy'
        Set-Text -X 10 -Y $y -Text "STR:$eSTR$strB  INT:$eINT$intB  SPD:$eSPD$spdB  DEF:$eDEF$defB  ACC:$eACC$accB" -FgColor ([ConsoleColor]::Gray)
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

# ── World Map ────────────────────────────────────────────────────────────────────

# Defines all locations and their ASCII-art positions/connections for the world map
$Script:WorldMapData = @(
    @{ Id = 'Map-TestTown-1';     Name = 'Thornvale Village';       X = 20;  Y = 12; Connections = @('Map-DarkCavern-1','Map-Shop-1','Map-CastleTown-1','Map-WhisperForest-1') }
    @{ Id = 'Map-Shop-1';         Name = 'General Store';           X = 20;  Y = 6;  Connections = @('Map-TestTown-1') }
    @{ Id = 'Map-DarkCavern-1';   Name = 'Dark Cavern';             X = 55;  Y = 18; Connections = @('Map-TestTown-1','Map-CastleTown-1','Map-DeepCavern-1') }
    @{ Id = 'Map-CastleTown-1';   Name = 'Castle Town';             X = 55;  Y = 6;  Connections = @('Map-TestTown-1','Map-DarkCavern-1','Map-Shop-1') }
    @{ Id = 'Map-WhisperForest-1'; Name = 'Whispering Forest';      X = 20;  Y = 20; Connections = @('Map-TestTown-1') }
    @{ Id = 'Map-DeepCavern-1';   Name = 'Deep Cavern';             X = 82;  Y = 18; Connections = @('Map-DarkCavern-1') }
)

function Show-WorldMap {
    Clear-FrameBuffer

    Draw-TextBox -X 3 -Y 0 -Width 114 -Height 29 -Title "World Map" `
                 -BorderColor ([ConsoleColor]::Cyan) -BgColor ([ConsoleColor]::Black)

    $discovered = $Script:GameState.DiscoveredMaps
    $currentMap = $Script:GameState.CurrentMapName

    # Draw connections first (lines between locations)
    foreach ($loc in $Script:WorldMapData) {
        $isFound = $discovered.ContainsKey($loc.Id)
        if (-not $isFound) { continue }

        $sx = $loc.X + 4   # center of node box
        $sy = $loc.Y + 1

        foreach ($connId in $loc.Connections) {
            $target = $Script:WorldMapData | Where-Object { $_.Id -eq $connId }
            if (-not $target) { continue }
            $targetFound = $discovered.ContainsKey($connId)
            if (-not $targetFound) { continue }

            $tx = $target.X + 4
            $ty = $target.Y + 1

            # Draw simple orthogonal path: vertical then horizontal
            $lineColor = [ConsoleColor]::DarkGray
            $midY = [math]::Floor(($sy + $ty) / 2)

            # Vertical segment from source
            $yStart = [math]::Min($sy, $midY)
            $yEnd   = [math]::Max($sy, $midY)
            for ($y = $yStart; $y -le $yEnd; $y++) {
                Set-Text -X $sx -Y $y -Text '|' -FgColor $lineColor
            }
            # Horizontal segment
            $xStart = [math]::Min($sx, $tx)
            $xEnd   = [math]::Max($sx, $tx)
            for ($x = $xStart; $x -le $xEnd; $x++) {
                Set-Text -X $x -Y $midY -Text '-' -FgColor $lineColor
            }
            # Vertical segment to target
            $yStart2 = [math]::Min($midY, $ty)
            $yEnd2   = [math]::Max($midY, $ty)
            for ($y = $yStart2; $y -le $yEnd2; $y++) {
                Set-Text -X $tx -Y $y -Text '|' -FgColor $lineColor
            }
        }
    }

    # Draw location nodes on top
    foreach ($loc in $Script:WorldMapData) {
        $isFound = $discovered.ContainsKey($loc.Id)
        $isCurrent = ($loc.Id -eq $currentMap)

        if ($isFound) {
            $nameText = $loc.Name
            $nodeColor = if ($isCurrent) { [ConsoleColor]::Yellow } else { [ConsoleColor]::White }
            $marker    = if ($isCurrent) { '>>>' } else { ' * ' }

            Set-Text -X $loc.X -Y $loc.Y -Text $marker -FgColor $nodeColor
            Set-Text -X ($loc.X + 3) -Y $loc.Y -Text " $nameText " -FgColor $nodeColor
        }
        else {
            Set-Text -X $loc.X -Y $loc.Y -Text ' ? ' -FgColor ([ConsoleColor]::DarkGray)
            Set-Text -X ($loc.X + 3) -Y $loc.Y -Text ' ???' -FgColor ([ConsoleColor]::DarkGray)
        }
    }

    # Legend
    Set-Text -X 6 -Y 25 -Text '>>> = Current Location    * = Discovered    ? = Unknown' -FgColor ([ConsoleColor]::DarkGray)
    Set-Text -X 6 -Y 27 -Text 'Press any key to return...' -FgColor ([ConsoleColor]::DarkGray)

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
