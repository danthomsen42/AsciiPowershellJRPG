# Engine/SaveLoad.ps1 - Save and Load Game State (Multi-Slot)
# Serializes game state to named JSON files in the Saves/ directory.

# ── Auto-Save ────────────────────────────────────────────────────────────────────

function Invoke-AutoSave {
    <#
    .SYNOPSIS
        Silently auto-saves to the "Autosave" slot. Called on map transitions.
    #>
    Save-GameState -SaveName 'Autosave' | Out-Null
}

# ── Save Slot Discovery ─────────────────────────────────────────────────────────

function Get-SaveSlots {
    <#
    .SYNOPSIS
        Returns an array of save-slot info objects sorted by last-modified date (newest first).
        Each object has: FileName, FilePath, DisplayName, SaveDate, PartyLeader, Level, Map, Gold, Steps.
    #>
    $savePath = Join-Path $Script:GameRoot 'Saves'
    if (-not (Test-Path $savePath)) { return @() }

    $files = @(Get-ChildItem -Path $savePath -Filter '*.json' -File | Sort-Object LastWriteTime -Descending)
    $slots = @()

    foreach ($f in $files) {
        try {
            $data = Get-Content $f.FullName -Raw | ConvertFrom-Json
            $leader = ''
            $level  = 0
            if ($data.Party -and $data.Party.Count -gt 0) {
                $leader = "$($data.Party[0].Name) ($($data.Party[0].Class))"
                $level  = [int]$data.Party[0].Level
            }
            $displayName = if ($data.SaveName) { $data.SaveName } else { $f.BaseName }
            $slots += @{
                FileName    = $f.Name
                FilePath    = $f.FullName
                DisplayName = $displayName
                SaveDate    = if ($data.SaveDate) { $data.SaveDate } else { $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm') }
                PartyLeader = $leader
                Level       = $level
                Map         = if ($data.CurrentMapName) { $data.CurrentMapName } else { '???' }
                Gold        = if ($null -ne $data.Gold) { [int]$data.Gold } else { 0 }
                Steps       = if ($null -ne $data.StepCounter) { [int]$data.StepCounter } else { 0 }
            }
        }
        catch {
            # Corrupt file — skip it
            continue
        }
    }
    # Comma operator forces array context so single-item arrays don't unwrap
    return ,$slots
}

# ── Build Save Slot Label ────────────────────────────────────────────────────────

function Format-SaveSlotLabel {
    param([hashtable]$Slot)
    $name = $Slot.DisplayName
    if ($name.Length -gt 18) { $name = $name.Substring(0, 18) }
    $info = "Lv$($Slot.Level) $($Slot.PartyLeader)"
    if ($info.Length -gt 28) { $info = $info.Substring(0, 28) }
    $date = $Slot.SaveDate
    return "$($name.PadRight(20)) $($info.PadRight(30)) $date"
}

# ── Save ─────────────────────────────────────────────────────────────────────────

function Save-GameState {
    <#
    .SYNOPSIS
        Saves current game state. If $SaveName is given, it becomes the file and
        display name. Legacy $Slot parameter still works for backward compat.
    #>
    param(
        [string]$SaveName = '',
        [int]$Slot = 0
    )

    $savePath = Join-Path $Script:GameRoot 'Saves'
    if (-not (Test-Path $savePath)) {
        New-Item -Path $savePath -ItemType Directory -Force | Out-Null
    }

    # Determine filename
    if ($SaveName) {
        # Sanitise: keep alphanumeric, spaces, hyphens, underscores
        $safeName = ($SaveName -replace '[^a-zA-Z0-9 _\-]', '').Trim()
        if (-not $safeName) { $safeName = 'Save' }
        $fileName = "$safeName.json"
    }
    elseif ($Slot -gt 0) {
        $fileName = "Save$Slot.json"
        $SaveName = "Save$Slot"
    }
    else {
        $fileName = 'Save1.json'
        $SaveName = 'Save1'
    }

    $saveData = @{
        Version        = 2
        SaveName       = $SaveName
        SaveDate       = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        CurrentMapName = $Script:GameState.CurrentMapName
        PlayerPosition = $Script:GameState.PlayerPosition
        Party          = $Script:GameState.Party
        Inventory      = $Script:GameState.Inventory
        Gold           = $Script:GameState.Gold
        Triggers       = $Script:GameState.Triggers
        StepCounter    = $Script:GameState.StepCounter
        TimeOfDay      = $Script:GameState.TimeOfDay
        DayCycleStep   = $Script:GameState.DayCycleStep
        DiscoveredMaps = $Script:GameState.DiscoveredMaps
        Messages       = @($Script:GameState.Messages | Select-Object -Last 10)
    }

    $saveFile = Join-Path $savePath $fileName
    $saveData | ConvertTo-Json -Depth 10 | Set-Content $saveFile -Encoding UTF8
    return $SaveName
}

# ── Load ─────────────────────────────────────────────────────────────────────────

function Load-GameState {
    <#
    .SYNOPSIS
        Loads game state from a named save file or legacy slot.
        Returns $true on success, $false if not found.
    #>
    param(
        [string]$FileName = '',
        [int]$Slot = 0
    )

    $savePath = Join-Path $Script:GameRoot 'Saves'

    if ($FileName) {
        $saveFile = Join-Path $savePath $FileName
    }
    elseif ($Slot -gt 0) {
        $saveFile = Join-Path $savePath "Save$Slot.json"
    }
    else {
        $saveFile = Join-Path $savePath 'Save1.json'
    }

    if (-not (Test-Path $saveFile)) {
        return $false
    }

    try {
        $saveData = Get-Content $saveFile -Raw | ConvertFrom-Json

        # Load the saved map
        $Script:GameState.CurrentMapName = $saveData.CurrentMapName
        $Script:GameState.CurrentMap     = Load-Map -MapName $saveData.CurrentMapName

        # Derive config name: Map-Foo-1 -> MapConfig-Foo-1
        $configName = $saveData.CurrentMapName -replace '^Map-', 'MapConfig-'
        $Script:GameState.CurrentMapConfig = Load-MapConfig -ConfigName $configName

        $Script:GameState.PlayerPosition = @{
            X = [int]($saveData.PlayerPosition.X)
            Y = [int]($saveData.PlayerPosition.Y)
        }

        # Rebuild party members as proper hashtables (ConvertFrom-Json returns PSCustomObject)
        $Script:GameState.Party = @()
        foreach ($member in $saveData.Party) {
            $ht = @{}
            foreach ($prop in $member.PSObject.Properties) {
                $ht[$prop.Name] = $prop.Value
            }
            # Convert Equipment PSCustomObject to hashtable
            if ($ht.Equipment -is [PSCustomObject]) {
                $eq = @{}
                foreach ($p in $ht.Equipment.PSObject.Properties) { $eq[$p.Name] = $p.Value }
                $ht.Equipment = $eq
            }
            # Convert SecondaryAbilities to array
            if ($ht.SecondaryAbilities -is [PSCustomObject] -or $ht.SecondaryAbilities -is [array]) {
                $ht.SecondaryAbilities = @($ht.SecondaryAbilities)
            }
            # Ensure numeric types
            foreach ($numProp in @('Level','EXP','EXPToNext','HP','MaxHP','MP','MaxMP','Strength','Intelligence','Speed','Defense','Accuracy')) {
                if ($ht.ContainsKey($numProp)) { $ht[$numProp] = [int]$ht[$numProp] }
            }
            $Script:GameState.Party += $ht
        }

        $Script:GameState.Gold        = [int]$saveData.Gold
        $Script:GameState.StepCounter = [int]$saveData.StepCounter

        # Day/night cycle
        if ($saveData.TimeOfDay)    { $Script:GameState.TimeOfDay    = $saveData.TimeOfDay }
        if ($null -ne $saveData.DayCycleStep) { $Script:GameState.DayCycleStep = [int]$saveData.DayCycleStep }
        if ($saveData.DiscoveredMaps) {
            $Script:GameState.DiscoveredMaps = @{}
            foreach ($prop in $saveData.DiscoveredMaps.PSObject.Properties) {
                $Script:GameState.DiscoveredMaps[$prop.Name] = $true
            }
        }

        # Rebuild triggers hashtable
        $Script:GameState.Triggers = @{}
        if ($saveData.Triggers -and $saveData.Triggers.PSObject) {
            foreach ($prop in $saveData.Triggers.PSObject.Properties) {
                $Script:GameState.Triggers[$prop.Name] = $prop.Value
            }
        }

        # Rebuild inventory
        $Script:GameState.Inventory = @()
        if ($saveData.Inventory) {
            foreach ($item in $saveData.Inventory) {
                $ht = @{}
                foreach ($prop in $item.PSObject.Properties) { $ht[$prop.Name] = $prop.Value }
                $Script:GameState.Inventory += $ht
            }
        }

        # Restore messages
        $Script:GameState.Messages = @()
        if ($saveData.Messages) {
            $Script:GameState.Messages = @($saveData.Messages)
        }

        $Script:GameState.GameMode = 'Exploration'
        Apply-TileOverrides
        Invoke-ForceFullRedraw

        return $true
    }
    catch {
        return $false
    }
}

# ── Interactive Save Picker (used by menus) ──────────────────────────────────────

function Show-SavePicker {
    <#
    .SYNOPSIS
        Shows existing saves and lets the player pick one to overwrite, or create a new save.
        Returns $null if cancelled. Performs the save and returns the display name on success.
    #>
    Clear-FrameBuffer

    $slots = Get-SaveSlots
    $options = @()

    # First option is always "New Save"
    $options += '[ + New Save ]'

    # Build labels for existing saves
    foreach ($s in $slots) {
        $options += Format-SaveSlotLabel -Slot $s
    }

    $options += '< Cancel >'

    $idx = Draw-SelectionMenu -X 5 -Y 3 -Width 108 -Title 'Save Game' `
                              -Options $options `
                              -BorderColor ([ConsoleColor]::Green) `
                              -TextColor ([ConsoleColor]::White)

    if ($idx -eq ($options.Count - 1)) { return $null }   # Cancel

    if ($idx -eq 0) {
        # New save — prompt for a name
        $saveName = Read-SaveName
        if (-not $saveName) { return $null }
        $result = Save-GameState -SaveName $saveName
        return $result
    }
    else {
        # Overwrite existing save
        $slot = $slots[$idx - 1]

        # Confirm overwrite
        Clear-FrameBuffer
        $confirmOpts = @("Yes, overwrite", "No, go back")
        $msg = "Overwrite '$($slot.DisplayName)'?"
        Set-Text -X ([math]::Floor(($Script:SCREEN_WIDTH - $msg.Length) / 2)) -Y 8 -Text $msg -FgColor ([ConsoleColor]::Yellow)
        Invoke-RenderFrame
        $confirm = Draw-SelectionMenu -X 40 -Y 10 -Width 40 -Title 'Confirm' `
                                      -Options $confirmOpts `
                                      -BorderColor ([ConsoleColor]::DarkYellow) `
                                      -TextColor ([ConsoleColor]::White)
        if ($confirm -ne 0) { return $null }

        # Save using the same filename (keeps the slot identity)
        $result = Save-GameState -SaveName $slot.DisplayName
        return $result
    }
}

function Show-LoadPicker {
    <#
    .SYNOPSIS
        Shows existing saves and lets the player pick one to load.
        Returns $true if loaded, $false if cancelled or no saves.
    #>
    Clear-FrameBuffer

    $slots = Get-SaveSlots

    if ($slots.Count -eq 0) {
        return $false   # No saves
    }

    $options = @()
    foreach ($s in $slots) {
        $options += Format-SaveSlotLabel -Slot $s
    }
    $options += '< Cancel >'

    $idx = Draw-SelectionMenu -X 5 -Y 3 -Width 108 -Title 'Load Game' `
                              -Options $options `
                              -BorderColor ([ConsoleColor]::Cyan) `
                              -TextColor ([ConsoleColor]::White)

    if ($idx -ge $slots.Count) { return $false }   # Cancel

    $slot = $slots[$idx]
    $loaded = Load-GameState -FileName $slot.FileName
    return $loaded
}

function Read-SaveName {
    <#
    .SYNOPSIS
        Simple text entry for save file name. Returns the name or empty string if cancelled.
        Supports typing, backspace, enter, and escape.
    #>
    $name   = ''
    $maxLen = 30
    $promptY = 12

    while ($true) {
        Clear-FrameBuffer

        $prompt = 'Enter a name for your save (Esc to cancel):'
        Set-Text -X ([math]::Floor(($Script:SCREEN_WIDTH - $prompt.Length) / 2)) -Y $promptY -Text $prompt -FgColor ([ConsoleColor]::Yellow)

        # Draw input box
        $boxX = 30
        $boxW = 60
        Draw-Box -X $boxX -Y ($promptY + 2) -Width $boxW -Height 3 -Color ([ConsoleColor]::White) -Fill
        $display = $name + '_'
        Set-Text -X ($boxX + 2) -Y ($promptY + 3) -Text $display -FgColor ([ConsoleColor]::White) -BgColor ([ConsoleColor]::Black)

        $charCount = "$($name.Length)/$maxLen"
        Set-Text -X ($boxX + $boxW - $charCount.Length - 2) -Y ($promptY + 4) -Text $charCount -FgColor ([ConsoleColor]::DarkGray)

        Invoke-RenderFrame

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            'Enter' {
                $trimmed = $name.Trim()
                if ($trimmed.Length -gt 0) { return $trimmed }
            }
            'Escape' { return '' }
            'Backspace' {
                if ($name.Length -gt 0) { $name = $name.Substring(0, $name.Length - 1) }
            }
            default {
                $ch = $key.KeyChar
                # Allow printable characters that are filename-safe
                if ($ch -match '[a-zA-Z0-9 _\-]' -and $name.Length -lt $maxLen) {
                    $name += $ch
                }
            }
        }
    }
}
