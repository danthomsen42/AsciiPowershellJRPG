# Engine/CutsceneEngine.ps1 - Cutscene Playback System
# Plays scripted sequences of dialogue panels, screen effects, art, and triggers.
# Cutscenes are defined as JSON files in the Cutscenes/ folder.

# ── Cutscene Data Cache ──────────────────────────────────────────────────────────
$Script:CutsceneDefinitions = $null

function Load-CutsceneDefinitions {
    <#
    .SYNOPSIS  Loads the master cutscene index from Cutscenes/Cutscenes.json.
    #>
    $path = Join-Path $Script:GameRoot "Cutscenes\Cutscenes.json"
    if (Test-Path $path) {
        $Script:CutsceneDefinitions = (Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json).cutscenes
    } else {
        $Script:CutsceneDefinitions = @()
    }
}

# ── Cutscene Trigger Check ───────────────────────────────────────────────────────

function Invoke-CheckCutscenes {
    <#
    .SYNOPSIS
        Call this after map transitions, quest completions, etc.
        Checks all cutscene definitions for trigger conditions.
        Plays the first matching cutscene that hasn't been seen yet.
    .PARAMETER EventType
        The type of event that just happened: 'map_enter', 'quest_complete', 'interact', 'game_start'
    .PARAMETER EventData
        Context for the event, e.g. the map name or quest ID.
    #>
    param(
        [string]$EventType = '',
        [string]$EventData = ''
    )

    if (-not $Script:CutsceneDefinitions) { Load-CutsceneDefinitions }
    if (-not $Script:CutsceneDefinitions) { return }

    foreach ($cs in $Script:CutsceneDefinitions) {
        # Skip if already seen (one-shot cutscenes use a trigger)
        if ($cs.onceTrigger -and $Script:GameState.Triggers[$cs.onceTrigger]) {
            continue
        }

        # Check if this cutscene matches the current event
        $match = $false
        if ($cs.trigger.type -eq $EventType) {
            switch ($EventType) {
                'map_enter' {
                    if ($cs.trigger.map -eq $EventData) { $match = $true }
                }
                'quest_complete' {
                    if ($cs.trigger.questId -eq $EventData) { $match = $true }
                }
                'game_start' {
                    $match = $true
                }
                'interact' {
                    if ($cs.trigger.npcId -eq $EventData) { $match = $true }
                }
                'battle_victory' {
                    if ($cs.trigger.battleId -eq $EventData) { $match = $true }
                }
                default {
                    $match = $true
                }
            }
        }

        # Check additional conditions (require specific triggers to be set)
        if ($match -and $cs.trigger.requireTrigger) {
            if (-not $Script:GameState.Triggers[$cs.trigger.requireTrigger]) {
                $match = $false
            }
        }

        if ($match) {
            # Mark as seen
            if ($cs.onceTrigger) {
                $Script:GameState.Triggers[$cs.onceTrigger] = $true
            }
            # Play it
            Play-Cutscene -CutsceneId $cs.id
            return
        }
    }
}

# ── Main Cutscene Player ─────────────────────────────────────────────────────────

function Play-Cutscene {
    <#
    .SYNOPSIS  Loads and plays a cutscene by ID.
    #>
    param([string]$CutsceneId)

    $csPath = Join-Path $Script:GameRoot "Cutscenes\$CutsceneId.json"
    if (-not (Test-Path $csPath)) {
        Add-GameMessage "Cutscene not found: $CutsceneId"
        return
    }

    $csData = Get-Content $csPath -Raw -Encoding UTF8 | ConvertFrom-Json

    foreach ($step in $csData.steps) {
        switch ($step.type) {
            'dialogue' {
                Invoke-CutsceneDialogue -Step $step
            }
            'narration' {
                Invoke-CutsceneNarration -Step $step
            }
            'art' {
                Invoke-CutsceneArt -Step $step
            }
            'effect' {
                Invoke-CutsceneEffect -Step $step
            }
            'set_trigger' {
                if ($step.trigger) {
                    $val = if ($null -ne $step.value) { $step.value } else { $true }
                    $Script:GameState.Triggers[$step.trigger] = $val
                }
            }
            'delay' {
                $ms = if ($step.ms) { [int]$step.ms } else { 1000 }
                [System.Threading.Thread]::Sleep($ms)
            }
            'clear' {
                Clear-FrameBuffer
                Invoke-RenderFrame
            }
            'start_battle' {
                if ($step.battleId) {
                    Start-ScriptedBattle -BattleId $step.battleId
                    # Battle runs in update loop; cutscene ends here
                    return
                }
            }
            'message' {
                if ($step.text) {
                    Add-GameMessage $step.text
                }
            }
            'heal_party' {
                foreach ($member in $Script:GameState.Party) {
                    $member.HP = $member.MaxHP
                    $member.MP = $member.MaxMP
                }
            }
            'animated_art' {
                Invoke-CutsceneAnimatedArt -Step $step
            }
            'map_sequence' {
                Invoke-CutsceneMapSequence -Step $step
            }
        }
    }

    Invoke-ForceFullRedraw
}

# ── Cutscene Step Handlers ───────────────────────────────────────────────────────

function Invoke-CutsceneDialogue {
    <#
    .SYNOPSIS  Shows a speaker's dialogue in a box. Waits for keypress.
    #>
    param([object]$Step)

    $speaker = if ($Step.speaker) { $Step.speaker } else { '???' }
    $lines   = @()
    if ($Step.text -is [array]) {
        $lines = @($Step.text)
    } else {
        $lines = @($Step.text)
    }

    $speakerColor = Get-CutsceneColor -ColorName $Step.speakerColor -Default ([ConsoleColor]::Yellow)
    $textColor    = Get-CutsceneColor -ColorName $Step.textColor -Default ([ConsoleColor]::White)
    $borderColor  = Get-CutsceneColor -ColorName $Step.borderColor -Default ([ConsoleColor]::White)

    $boxY = $Script:SCREEN_HEIGHT - 8
    $boxHeight = 7
    Draw-Box -X 2 -Y $boxY -Width 116 -Height $boxHeight -Color $borderColor -BgColor ([ConsoleColor]::Black) -Fill
    Set-Text -X 4 -Y $boxY -Text " $speaker " -FgColor $speakerColor -BgColor ([ConsoleColor]::Black)

    # Word-wrap and display
    $wrappedLines = Invoke-WordWrap -Lines $lines -MaxWidth 110
    for ($i = 0; $i -lt $wrappedLines.Count -and $i -lt ($boxHeight - 2); $i++) {
        Set-Text -X 4 -Y ($boxY + 1 + $i) -Text $wrappedLines[$i] -FgColor $textColor -BgColor ([ConsoleColor]::Black)
    }

    $promptText = "[Press any key to continue]"
    Set-Text -X (116 - $promptText.Length) -Y ($boxY + $boxHeight - 2) -Text $promptText -FgColor ([ConsoleColor]::DarkGray) -BgColor ([ConsoleColor]::Black)
    Invoke-RenderFrame
    Wait-ForKey | Out-Null
}

function Invoke-CutsceneNarration {
    <#
    .SYNOPSIS  Shows narration text centered on a dark screen. Atmospheric.
    #>
    param([object]$Step)

    Clear-FrameBuffer

    $textColor   = Get-CutsceneColor -ColorName $Step.textColor -Default ([ConsoleColor]::DarkGray)
    $borderColor = Get-CutsceneColor -ColorName $Step.borderColor -Default ([ConsoleColor]::DarkCyan)

    $lines = @()
    if ($Step.text -is [array]) { $lines = @($Step.text) } else { $lines = @($Step.text) }

    $wrappedLines = Invoke-WordWrap -Lines $lines -MaxWidth 90

    # Center vertically
    $totalLines = $wrappedLines.Count
    $startY = [math]::Max(2, [math]::Floor(($Script:SCREEN_HEIGHT - $totalLines) / 2))

    # Optional border box
    if ($Step.boxed) {
        $boxWidth  = 96
        $boxHeight = $totalLines + 4
        $boxX      = [math]::Floor(($Script:SCREEN_WIDTH - $boxWidth) / 2)
        $boxY      = $startY - 2
        Draw-Box -X $boxX -Y $boxY -Width $boxWidth -Height $boxHeight -Color $borderColor -BgColor ([ConsoleColor]::Black) -Fill
        $startY = $boxY + 2
    }

    for ($i = 0; $i -lt $wrappedLines.Count; $i++) {
        $line = $wrappedLines[$i]
        $lineX = [math]::Floor(($Script:SCREEN_WIDTH - $line.Length) / 2)
        Set-Text -X $lineX -Y ($startY + $i) -Text $line -FgColor $textColor
    }

    $promptText = "[Press any key]"
    Set-Text -X ([math]::Floor(($Script:SCREEN_WIDTH - $promptText.Length) / 2)) -Y ($Script:SCREEN_HEIGHT - 2) -Text $promptText -FgColor ([ConsoleColor]::DarkGray)
    Invoke-RenderFrame
    Wait-ForKey | Out-Null
}

function Invoke-CutsceneArtLines {
    <#
    .SYNOPSIS  Renders art lines with optional per-cell FG/BG color maps.
    .DESCRIPTION  Groups consecutive characters that share the same fg+bg color
                  into runs, calling Set-Text once per run for efficiency.
    #>
    param(
        [string[]]$Lines,
        [int]$StartX,
        [int]$StartY,
        [ConsoleColor]$DefaultFg,
        [object]$ColorMap,
        [object]$BgColorMap
    )
    $defaultBg = [ConsoleColor]::Black
    $hasFg = $null -ne $ColorMap -and $ColorMap.Count -gt 0
    $hasBg = $null -ne $BgColorMap -and $BgColorMap.Count -gt 0

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        if ($line.Length -eq 0) { continue }

        $lineFg = $null
        $lineBg = $null
        if ($hasFg -and $i -lt $ColorMap.Count -and $null -ne $ColorMap[$i]) {
            $lineFg = @($ColorMap[$i])
        }
        if ($hasBg -and $i -lt $BgColorMap.Count -and $null -ne $BgColorMap[$i]) {
            $lineBg = @($BgColorMap[$i])
        }

        if ($null -eq $lineFg -and $null -eq $lineBg) {
            # No per-cell colors — fast path
            Set-Text -X $StartX -Y ($StartY + $i) -Text $line -FgColor $DefaultFg
            continue
        }

        # Per-cell rendering with color runs
        $runStart = 0
        $runFg = $DefaultFg
        $runBg = $defaultBg
        if ($null -ne $lineFg -and $lineFg.Count -gt 0 -and $lineFg[0] -and $lineFg[0] -ne '') {
            $runFg = Get-CutsceneColor -ColorName $lineFg[0] -Default $DefaultFg
        }
        if ($null -ne $lineBg -and $lineBg.Count -gt 0 -and $lineBg[0] -and $lineBg[0] -ne '') {
            $runBg = Get-CutsceneColor -ColorName $lineBg[0] -Default $defaultBg
        }

        for ($ci = 1; $ci -le $line.Length; $ci++) {
            $cellFg = $DefaultFg
            $cellBg = $defaultBg
            if ($ci -lt $line.Length) {
                if ($null -ne $lineFg -and $ci -lt $lineFg.Count -and $lineFg[$ci] -and $lineFg[$ci] -ne '') {
                    $cellFg = Get-CutsceneColor -ColorName $lineFg[$ci] -Default $DefaultFg
                }
                if ($null -ne $lineBg -and $ci -lt $lineBg.Count -and $lineBg[$ci] -and $lineBg[$ci] -ne '') {
                    $cellBg = Get-CutsceneColor -ColorName $lineBg[$ci] -Default $defaultBg
                }
            }
            if ($ci -eq $line.Length -or $cellFg -ne $runFg -or $cellBg -ne $runBg) {
                $runText = $line.Substring($runStart, $ci - $runStart)
                Set-Text -X ($StartX + $runStart) -Y ($StartY + $i) -Text $runText -FgColor $runFg -BgColor $runBg
                $runStart = $ci
                $runFg = $cellFg
                $runBg = $cellBg
            }
        }
    }
}

function Invoke-CutsceneArt {
    <#
    .SYNOPSIS  Displays ASCII art from a file or inline, centered on screen.
    #>
    param([object]$Step)

    Clear-FrameBuffer

    $artLines = @()
    if ($Step.artFile) {
        $artPath = Join-Path $Script:GameRoot "Cutscenes\$($Step.artFile)"
        if (Test-Path $artPath) {
            $artLines = @(Get-Content $artPath -Encoding UTF8)
        }
    }
    elseif ($Step.art -is [array]) {
        $artLines = @($Step.art)
    }

    $artColor = Get-CutsceneColor -ColorName $Step.artColor -Default ([ConsoleColor]::White)

    # Center the art
    $maxLen = 0
    foreach ($al in $artLines) { if ($al.Length -gt $maxLen) { $maxLen = $al.Length } }
    $artStartX = [math]::Max(0, [math]::Floor(($Script:SCREEN_WIDTH - $maxLen) / 2))
    $artStartY = [math]::Max(0, [math]::Floor(($Script:SCREEN_HEIGHT - $artLines.Count) / 2) - 2)

    $hasColorMap = $null -ne $Step.colorMap -and $Step.colorMap.Count -gt 0

    Invoke-CutsceneArtLines -Lines $artLines -StartX $artStartX -StartY $artStartY `
        -DefaultFg $artColor -ColorMap $Step.colorMap -BgColorMap $Step.bgColorMap

    # Optional caption under the art
    if ($Step.caption) {
        $captionColor = Get-CutsceneColor -ColorName $Step.captionColor -Default ([ConsoleColor]::DarkGray)
        $captionX = [math]::Floor(($Script:SCREEN_WIDTH - $Step.caption.Length) / 2)
        Set-Text -X $captionX -Y ($artStartY + $artLines.Count + 2) -Text $Step.caption -FgColor $captionColor
    }

    $promptText = "[Press any key]"
    Set-Text -X ([math]::Floor(($Script:SCREEN_WIDTH - $promptText.Length) / 2)) -Y ($Script:SCREEN_HEIGHT - 2) -Text $promptText -FgColor ([ConsoleColor]::DarkGray)
    Invoke-RenderFrame
    Wait-ForKey | Out-Null
}

function Invoke-CutsceneEffect {
    <#
    .SYNOPSIS  Screen effect: fade_in, fade_out, flash, shake.
    #>
    param([object]$Step)

    switch ($Step.effect) {
        'fade_out' {
            # Progressively darken the screen
            $steps = if ($Step.steps) { [int]$Step.steps } else { 5 }
            $delayMs = if ($Step.delayMs) { [int]$Step.delayMs } else { 150 }
            for ($s = 0; $s -lt $steps; $s++) {
                Clear-FrameBuffer
                Invoke-RenderFrame
                [System.Threading.Thread]::Sleep($delayMs)
            }
        }
        'fade_in' {
            # Just a delay before the next frame renders
            $delayMs = if ($Step.delayMs) { [int]$Step.delayMs } else { 500 }
            [System.Threading.Thread]::Sleep($delayMs)
            Invoke-ForceFullRedraw
        }
        'flash' {
            # Brief bright flash
            $flashColor = Get-CutsceneColor -ColorName $Step.color -Default ([ConsoleColor]::White)
            $flashCount = if ($Step.count) { [int]$Step.count } else { 3 }
            $delayMs    = if ($Step.delayMs) { [int]$Step.delayMs } else { 100 }

            for ($f = 0; $f -lt $flashCount; $f++) {
                Clear-FrameBuffer
                # Fill screen with flash color
                for ($row = 0; $row -lt $Script:SCREEN_HEIGHT; $row++) {
                    Set-Text -X 0 -Y $row -Text (' ' * $Script:SCREEN_WIDTH) -FgColor $flashColor -BgColor $flashColor
                }
                Invoke-RenderFrame
                [System.Threading.Thread]::Sleep($delayMs)
                Clear-FrameBuffer
                Invoke-RenderFrame
                [System.Threading.Thread]::Sleep($delayMs)
            }
        }
        'shake' {
            # Simulate screen shake by briefly offsetting text
            $shakeCount = if ($Step.count) { [int]$Step.count } else { 4 }
            $delayMs    = if ($Step.delayMs) { [int]$Step.delayMs } else { 80 }

            for ($s = 0; $s -lt $shakeCount; $s++) {
                $msgText = if ($Step.text) { $Step.text } else { '' }
                Clear-FrameBuffer
                $offset = if ($s % 2 -eq 0) { 2 } else { -2 }
                if ($msgText) {
                    $mX = [math]::Floor(($Script:SCREEN_WIDTH - $msgText.Length) / 2) + $offset
                    Set-Text -X $mX -Y 15 -Text $msgText -FgColor ([ConsoleColor]::Red)
                }
                Invoke-RenderFrame
                [System.Threading.Thread]::Sleep($delayMs)
            }
        }
        'pause' {
            $delayMs = if ($Step.delayMs) { [int]$Step.delayMs } else { 1000 }
            [System.Threading.Thread]::Sleep($delayMs)
        }
    }
}

# ── Animated Art (Sprite-Sheet Style) ─────────────────────────────────────────────

function Invoke-CutsceneAnimatedArt {
    <#
    .SYNOPSIS
        Plays a frame-by-frame animation. Each frame is an array of strings
        drawn centered on screen, cycled at a configurable speed.

        JSON schema:
        {
            "type": "animated_art",
            "frames": [
                ["frame0 line1", "frame0 line2", ...],
                ["frame1 line1", "frame1 line2", ...],
                ...
            ],
            "frameDelayMs": 200,
            "loops": 3,
            "artColor": "Red",
            "colorMaps": [ [[row0col0color, ...], ...], ... ],
            "caption": "Optional text below",
            "captionColor": "Gray",
            "holdLastFrame": true,
            "waitForKey": true
        }
    #>
    param([object]$Step)

    $frames   = @($Step.frames)
    if ($frames.Count -eq 0) { return }

    $delayMs  = if ($Step.frameDelayMs) { [int]$Step.frameDelayMs } else { 200 }
    $loops    = if ($Step.loops)        { [int]$Step.loops }        else { 1 }
    $artColor = Get-CutsceneColor -ColorName $Step.artColor -Default ([ConsoleColor]::White)
    $caption  = $Step.caption
    $capColor = Get-CutsceneColor -ColorName $Step.captionColor -Default ([ConsoleColor]::DarkGray)
    $hold     = if ($null -ne $Step.holdLastFrame) { [bool]$Step.holdLastFrame } else { $true }
    $waitKey  = if ($null -ne $Step.waitForKey) { [bool]$Step.waitForKey } else { $true }

    # Pre-compute per-frame data
    $frameData = @()
    foreach ($f in $frames) {
        $lines = @($f)
        $maxLen = 0
        foreach ($l in $lines) { if ($l.Length -gt $maxLen) { $maxLen = $l.Length } }
        $startX = [math]::Max(0, [math]::Floor(($Script:SCREEN_WIDTH  - $maxLen)       / 2))
        $startY = [math]::Max(0, [math]::Floor(($Script:SCREEN_HEIGHT - $lines.Count)  / 2) - 2)
        $frameData += @{ Lines = $lines; StartX = $startX; StartY = $startY; MaxLen = $maxLen }
    }

    $hasColorMaps   = $null -ne $Step.colorMaps   -and $Step.colorMaps.Count -gt 0
    $hasBgColorMaps = $null -ne $Step.bgColorMaps -and $Step.bgColorMaps.Count -gt 0

    for ($loop = 0; $loop -lt $loops; $loop++) {
        for ($fi = 0; $fi -lt $frames.Count; $fi++) {
            $fd = $frameData[$fi]
            Clear-FrameBuffer

            # Get per-frame colorMaps if available
            $frameColorMap = $null
            $frameBgColorMap = $null
            if ($hasColorMaps -and $fi -lt $Step.colorMaps.Count -and $null -ne $Step.colorMaps[$fi]) {
                $frameColorMap = $Step.colorMaps[$fi]
            }
            if ($hasBgColorMaps -and $fi -lt $Step.bgColorMaps.Count -and $null -ne $Step.bgColorMaps[$fi]) {
                $frameBgColorMap = $Step.bgColorMaps[$fi]
            }

            Invoke-CutsceneArtLines -Lines $fd.Lines -StartX $fd.StartX -StartY $fd.StartY `
                -DefaultFg $artColor -ColorMap $frameColorMap -BgColorMap $frameBgColorMap

            if ($caption) {
                $cx = [math]::Floor(($Script:SCREEN_WIDTH - $caption.Length) / 2)
                Set-Text -X $cx -Y ($fd.StartY + $fd.Lines.Count + 2) -Text $caption -FgColor $capColor
            }

            # On the very last frame of the last loop, optionally show "press key"
            $isLast = ($loop -eq $loops - 1 -and $fi -eq $frames.Count - 1)
            if ($isLast -and $hold -and $waitKey) {
                $pt = "[Press any key]"
                Set-Text -X ([math]::Floor(($Script:SCREEN_WIDTH - $pt.Length) / 2)) -Y ($Script:SCREEN_HEIGHT - 2) -Text $pt -FgColor ([ConsoleColor]::DarkGray)
            }

            Invoke-RenderFrame
            if ($isLast -and $hold -and $waitKey) {
                Wait-ForKey | Out-Null
                return
            }
            [System.Threading.Thread]::Sleep($delayMs)
        }
    }
}

# ── Map Sequence (Scripted Map Playback) ─────────────────────────────────────────

function Invoke-CutsceneMapSequence {
    <#
    .SYNOPSIS
        Displays a map with scripted entity movement and dialogue.
        The player has no control; events play out automatically.

        JSON schema:
        {
            "type": "map_sequence",
            "mapFile": "Map-Forest-1.txt",           -- optional, load from file
            "inlineMap": ["####", "#..#", "####"],    -- or define map inline
            "mapWidth": 30, "mapHeight": 15,          -- viewport override
            "tileColors": { "#": "DarkGreen", ".": "Green" },
            "entities": [
                { "id": "mage", "char": "M", "color": "Cyan", "x": 2, "y": 5 },
                { "id": "goblin1", "char": "G", "color": "Green", "x": -1, "y": -1, "hidden": true }
            ],
            "events": [
                { "action": "move", "entity": "mage", "path": [[3,5],[4,5],[5,5]], "stepDelayMs": 200 },
                { "action": "dialogue", "speaker": "Mage", "text": "I hear something...", "speakerColor": "Cyan" },
                { "action": "show", "entity": "goblin1", "x": 7, "y": 4 },
                { "action": "show", "entity": "goblin2", "x": 7, "y": 5 },
                { "action": "show", "entity": "goblin3", "x": 7, "y": 6 },
                { "action": "delay", "ms": 500 },
                { "action": "dialogue", "speaker": "Mage", "text": "Oh no!", "speakerColor": "Cyan" },
                { "action": "hide", "entity": "mage" },
                { "action": "narration", "text": "The mage was never seen again..." }
            ]
        }
    #>
    param([object]$Step)

    # ── Load map data ──
    $mapLines = @()
    if ($Step.mapFile) {
        $mapPath = Join-Path $Script:GameRoot "Data\Maps\$($Step.mapFile)"
        if (Test-Path $mapPath) {
            $raw = Get-Content $mapPath -Encoding UTF8
            foreach ($line in $raw) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                if ($line.TrimStart().StartsWith(';')) { continue }
                $mapLines += $line
            }
        }
    }
    elseif ($Step.inlineMap -is [array]) {
        $mapLines = @($Step.inlineMap)
    }
    if ($mapLines.Count -eq 0) { return }

    $mapH = $mapLines.Count
    $mapW = ($mapLines | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum

    # Build tile char array
    $tiles = [char[,]]::new($mapW, $mapH)
    for ($y = 0; $y -lt $mapH; $y++) {
        for ($x = 0; $x -lt $mapW; $x++) {
            if ($x -lt $mapLines[$y].Length) { $tiles[$x, $y] = $mapLines[$y][$x] }
            else { $tiles[$x, $y] = ' ' }
        }
    }

    # Tile color map
    $tileColorMap = @{}
    if ($Step.tileColors -and $Step.tileColors.PSObject) {
        foreach ($p in $Step.tileColors.PSObject.Properties) {
            try { $tileColorMap[$p.Name] = [ConsoleColor]($p.Value) } catch {}
        }
    }

    # Viewport sizing
    $vpW = if ($Step.mapWidth)  { [int]$Step.mapWidth }  else { [math]::Min($mapW, 80) }
    $vpH = if ($Step.mapHeight) { [int]$Step.mapHeight } else { [math]::Min($mapH, 20) }
    $vpX = [math]::Max(0, [math]::Floor(($Script:SCREEN_WIDTH  - $vpW) / 2))
    $vpY = [math]::Max(1, [math]::Floor(($Script:SCREEN_HEIGHT - $vpH) / 2) - 2)

    # ── Entities ──
    $entities = @{}
    if ($Step.entities) {
        foreach ($e in $Step.entities) {
            $entities[$e.id] = @{
                Char   = if ($e.char) { [char]($e.char) } else { [char]'?' }
                Color  = (Get-CutsceneColor -ColorName $e.color -Default ([ConsoleColor]::White))
                X      = if ($null -ne $e.x) { [int]$e.x } else { -1 }
                Y      = if ($null -ne $e.y) { [int]$e.y } else { -1 }
                Hidden = if ($e.hidden) { $true } else { $false }
            }
        }
    }

    # ── Render helper ──
    $renderMap = {
        Clear-FrameBuffer

        # Title bar
        $title = if ($Step.title) { $Step.title } else { '' }
        if ($title) {
            $tx = [math]::Floor(($Script:SCREEN_WIDTH - $title.Length) / 2)
            Set-Text -X $tx -Y 0 -Text $title -FgColor ([ConsoleColor]::Yellow)
        }

        # Draw tiles
        for ($ry = 0; $ry -lt $vpH -and $ry -lt $mapH; $ry++) {
            for ($rx = 0; $rx -lt $vpW -and $rx -lt $mapW; $rx++) {
                $ch = $tiles[$rx, $ry]
                $fc = $tileColorMap[[string]$ch]
                if (-not $fc) { $fc = [ConsoleColor]::Gray }
                Set-Text -X ($vpX + $rx) -Y ($vpY + $ry) -Text ([string]$ch) -FgColor $fc
            }
        }

        # Draw entities
        foreach ($eKey in $entities.Keys) {
            $ent = $entities[$eKey]
            if ($ent.Hidden) { continue }
            if ($ent.X -ge 0 -and $ent.Y -ge 0 -and $ent.X -lt $vpW -and $ent.Y -lt $vpH) {
                Set-Text -X ($vpX + $ent.X) -Y ($vpY + $ent.Y) -Text ([string]$ent.Char) -FgColor $ent.Color
            }
        }

        Invoke-RenderFrame
    }

    # Initial render
    & $renderMap

    # ── Process events ──
    if ($Step.events) {
        foreach ($evt in $Step.events) {
            switch ($evt.action) {
                'move' {
                    $ent = $entities[$evt.entity]
                    if (-not $ent) { continue }
                    $ent.Hidden = $false
                    $stepDelay = if ($evt.stepDelayMs) { [int]$evt.stepDelayMs } else { 200 }
                    foreach ($pt in $evt.path) {
                        $ent.X = [int]$pt[0]
                        $ent.Y = [int]$pt[1]
                        & $renderMap
                        [System.Threading.Thread]::Sleep($stepDelay)
                    }
                }
                'show' {
                    $ent = $entities[$evt.entity]
                    if (-not $ent) { continue }
                    $ent.Hidden = $false
                    if ($null -ne $evt.x) { $ent.X = [int]$evt.x }
                    if ($null -ne $evt.y) { $ent.Y = [int]$evt.y }
                    & $renderMap
                    if ($evt.delayMs) { [System.Threading.Thread]::Sleep([int]$evt.delayMs) }
                }
                'hide' {
                    $ent = $entities[$evt.entity]
                    if (-not $ent) { continue }
                    $ent.Hidden = $true
                    & $renderMap
                }
                'dialogue' {
                    # Render map in background, dialogue box at bottom
                    & $renderMap
                    $speaker  = if ($evt.speaker) { $evt.speaker } else { '???' }
                    $spkColor = Get-CutsceneColor -ColorName $evt.speakerColor -Default ([ConsoleColor]::Yellow)
                    $txtColor = Get-CutsceneColor -ColorName $evt.textColor    -Default ([ConsoleColor]::White)
                    $lines    = @($evt.text)
                    $wrappedLines = Invoke-WordWrap -Lines $lines -MaxWidth 110

                    $boxY = $Script:SCREEN_HEIGHT - 8
                    $boxH = 7
                    Draw-Box -X 2 -Y $boxY -Width 116 -Height $boxH -Color ([ConsoleColor]::White) -BgColor ([ConsoleColor]::Black) -Fill
                    Set-Text -X 4 -Y $boxY -Text " $speaker " -FgColor $spkColor -BgColor ([ConsoleColor]::Black)
                    for ($i = 0; $i -lt $wrappedLines.Count -and $i -lt ($boxH - 2); $i++) {
                        Set-Text -X 4 -Y ($boxY + 1 + $i) -Text $wrappedLines[$i] -FgColor $txtColor -BgColor ([ConsoleColor]::Black)
                    }
                    $pt = "[Press any key]"
                    Set-Text -X (116 - $pt.Length) -Y ($boxY + $boxH - 2) -Text $pt -FgColor ([ConsoleColor]::DarkGray) -BgColor ([ConsoleColor]::Black)
                    Invoke-RenderFrame
                    Wait-ForKey | Out-Null
                }
                'narration' {
                    Invoke-CutsceneNarration -Step $evt
                }
                'delay' {
                    $ms = if ($evt.ms) { [int]$evt.ms } else { 500 }
                    [System.Threading.Thread]::Sleep($ms)
                }
                'effect' {
                    Invoke-CutsceneEffect -Step $evt
                }
            }
        }
    }
}

# ── Helpers ──────────────────────────────────────────────────────────────────────

function Get-CutsceneColor {
    <#
    .SYNOPSIS  Converts a color name string to [ConsoleColor]. Returns default if invalid.
    #>
    param(
        [string]$ColorName,
        [ConsoleColor]$Default = [ConsoleColor]::White
    )
    if (-not $ColorName) { return $Default }
    try {
        return [ConsoleColor]$ColorName
    } catch {
        return $Default
    }
}

function Invoke-WordWrap {
    <#
    .SYNOPSIS  Word-wraps an array of lines to a maximum width.
    #>
    param(
        [string[]]$Lines,
        [int]$MaxWidth = 110
    )

    $result = @()
    foreach ($line in $Lines) {
        if ($line.Length -le $MaxWidth) {
            $result += $line
        } else {
            $words = $line -split ' '
            $current = ""
            foreach ($word in $words) {
                if (($current.Length + $word.Length + 1) -gt $MaxWidth) {
                    $result += $current
                    $current = $word
                } else {
                    if ($current) { $current += " " }
                    $current += $word
                }
            }
            if ($current) { $result += $current }
        }
    }
    return $result
}
