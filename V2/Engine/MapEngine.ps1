# Engine/MapEngine.ps1 - Map Loading, Parsing, Viewport Rendering, and Player Movement
# Maps are plain text files with '#' borders. Configs are JSON with tile definitions.

# ── Map Viewport Layout ─────────────────────────────────────────────────────────
$Script:MAP_VIEWPORT_X      = 0    # Screen X offset for map area
$Script:MAP_VIEWPORT_Y      = 1    # Screen Y offset (row 0 = header bar)
$Script:MAP_VIEWPORT_WIDTH  = 80   # Columns visible for map
$Script:MAP_VIEWPORT_HEIGHT = 24   # Rows visible for map

# ── Tile Animation ───────────────────────────────────────────────────────────────
# Time-based animation: frame is derived from wall-clock time so that tiles
# animate at a constant rate regardless of player input or frame rate.
$Script:AnimStartTick   = [Environment]::TickCount
$Script:AnimIntervalMs  = 300   # Milliseconds per animation frame
# Water-style color cycle: wave pattern across 4 frames
$Script:WaterColorCycle = @(
    [ConsoleColor]::DarkBlue,
    [ConsoleColor]::Blue,
    [ConsoleColor]::DarkCyan,
    [ConsoleColor]::Cyan
)

# ── Map Loading ──────────────────────────────────────────────────────────────────

function Load-Map {
    <#
    .SYNOPSIS
        Loads a map text file and returns a map data hashtable.
        Map files are plain text where '#' characters form the border.
    #>
    param([string]$MapName)

    $mapPath = Join-Path $Script:GameRoot "Data\Maps\$MapName.txt"
    if (-not (Test-Path $mapPath)) {
        throw "Map file not found: $mapPath"
    }

    $rawLines = Get-Content $mapPath

    # Filter out empty lines and comments (lines starting with ;)
    $tileRows = @()
    foreach ($line in $rawLines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.TrimStart().StartsWith(';')) { continue }
        $tileRows += $line
    }

    if ($tileRows.Count -eq 0) {
        throw "Map file is empty or contains only comments: $mapPath"
    }

    $mapHeight = $tileRows.Count
    $mapWidth  = ($tileRows | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum

    # Build 2D tile array  [x, y]
    $tiles = [char[,]]::new($mapWidth, $mapHeight)
    for ($y = 0; $y -lt $mapHeight; $y++) {
        for ($x = 0; $x -lt $mapWidth; $x++) {
            if ($x -lt $tileRows[$y].Length) {
                $tiles[$x, $y] = $tileRows[$y][$x]
            }
            else {
                $tiles[$x, $y] = ' '
            }
        }
    }

    return @{
        Name   = $MapName
        Tiles  = $tiles
        Width  = $mapWidth
        Height = $mapHeight
    }
}

function Apply-TileOverrides {
    <#
    .SYNOPSIS
        Checks the current map config for tileOverrides and modifies the loaded
        tile array when trigger conditions are met.  Call after loading a map or
        whenever triggers change (battle victory, quest completion, etc.).
    #>
    $config  = $Script:GameState.CurrentMapConfig
    $mapData = $Script:GameState.CurrentMap
    if (-not $config -or -not $mapData) { return }

    $overrides = $config.tileOverrides
    if (-not $overrides) { return }

    foreach ($ov in $overrides) {
        $apply = $false
        if ($ov.condition -and $ov.condition.trigger) {
            $trigName = $ov.condition.trigger
            $expected = if ($null -ne $ov.condition.value) { $ov.condition.value } else { $true }
            $actual   = $Script:GameState.Triggers[$trigName]
            if ($actual -eq $expected) { $apply = $true }
        }

        if ($apply) {
            $x = [int]$ov.position.x
            $y = [int]$ov.position.y
            if ($x -ge 0 -and $x -lt $mapData.Width -and $y -ge 0 -and $y -lt $mapData.Height) {
                $mapData.Tiles[$x, $y] = [char]($ov.replaceTile)
            }
        }
    }

    # Invalidate the tile-color cache so the renderer picks up changes
    if ($Script:TileColorCache) { $Script:TileColorCache = @{} }
}

function Load-MapConfig {
    <#
    .SYNOPSIS
        Loads a map configuration JSON file.
    #>
    param([string]$ConfigName)

    $configPath = Join-Path $Script:GameRoot "Data\Maps\$ConfigName.json"
    if (-not (Test-Path $configPath)) {
        throw "Map config not found: $configPath"
    }

    return (Get-Content $configPath -Raw | ConvertFrom-Json)
}

# ── Tile Queries ─────────────────────────────────────────────────────────────────

function Get-TileInfo {
    <#
    .SYNOPSIS
        Returns the config entry for a given tile character, or $null.
    #>
    param(
        [char]$TileChar,
        [object]$MapConfig
    )
    $charStr = [string]$TileChar
    $prop = $MapConfig.tiles.PSObject.Properties[$charStr]
    if ($prop) { return $prop.Value }
    return $null
}

function Get-TileColor {
    param([char]$TileChar, [object]$MapConfig)
    $info = Get-TileInfo -TileChar $TileChar -MapConfig $MapConfig
    if ($info -and $info.color) {
        try { return [ConsoleColor]($info.color) } catch {}
    }
    # Fallback defaults
    switch ($TileChar) {
        '#' { return [ConsoleColor]::DarkGray }
        '.' { return [ConsoleColor]::DarkGray }
        '~' { return [ConsoleColor]::Cyan }
        default { return [ConsoleColor]::Gray }
    }
}

function Get-TileBgColor {
    param([char]$TileChar, [object]$MapConfig)
    $info = Get-TileInfo -TileChar $TileChar -MapConfig $MapConfig
    if ($info -and $info.bgColor) {
        try { return [ConsoleColor]($info.bgColor) } catch {}
    }
    return [ConsoleColor]::Black
}

function Test-TilePassable {
    param([char]$TileChar, [object]$MapConfig)
    $info = Get-TileInfo -TileChar $TileChar -MapConfig $MapConfig
    if ($info) {
        return [bool]$info.passable
    }
    # Default: '#' is impassable
    if ($TileChar -eq '#') { return $false }
    return $true
}

function Get-TileAction {
    <#
    .SYNOPSIS
        Checks if a specific position has a map connection (door) defined.
        Returns an action hashtable or $null.
    #>
    param(
        [int]$X,
        [int]$Y,
        [object]$MapConfig
    )
    if ($MapConfig.connections) {
        foreach ($conn in $MapConfig.connections.PSObject.Properties) {
            $door = $conn.Value
            if ([int]($door.position.x) -eq $X -and [int]($door.position.y) -eq $Y) {
                return @{
                    Type         = 'Door'
                    TargetMap    = $door.targetMap
                    TargetConfig = $door.targetConfig
                    TargetX      = [int]($door.targetPosition.x)
                    TargetY      = [int]($door.targetPosition.y)
                }
            }
        }
    }
    return $null
}

function Get-InteractTarget {
    <#
    .SYNOPSIS
        Checks tiles adjacent to the player for interactable objects (NPCs, signs).
        Returns the first action found, or $null.
    #>
    param(
        [int]$PlayerX,
        [int]$PlayerY,
        [object]$MapData,
        [object]$MapConfig
    )

    $directions = @(
        @{ X = $PlayerX;     Y = $PlayerY - 1 },   # Up
        @{ X = $PlayerX;     Y = $PlayerY + 1 },   # Down
        @{ X = $PlayerX - 1; Y = $PlayerY },        # Left
        @{ X = $PlayerX + 1; Y = $PlayerY }          # Right
    )

    foreach ($dir in $directions) {
        $tx = $dir.X; $ty = $dir.Y
        if ($tx -lt 0 -or $tx -ge $MapData.Width -or $ty -lt 0 -or $ty -ge $MapData.Height) { continue }

        $tile = $MapData.Tiles[$tx, $ty]
        $info = Get-TileInfo -TileChar $tile -MapConfig $MapConfig
        if ($info -and $info.action) {
            return @{
                Action = $info.action
                Tile   = [string]$tile
                X      = $tx
                Y      = $ty
                Name   = if ($info.name) { $info.name } else { [string]$tile }
            }
        }
    }
    return $null
}

# ── Map Rendering ────────────────────────────────────────────────────────────────

function Render-Map {
    <#
    .SYNOPSIS
        Draws the map to the frame buffer within the viewport.
        Centers on the player if the map is larger than the viewport.
        Uses cached tile color lookups and inlined buffer writes for performance.
    #>
    param(
        [object]$MapData,
        [object]$MapConfig,
        [int]$PlayerX,
        [int]$PlayerY
    )

    # ── Build tile color cache (once per map config change) ──
    # Maps char -> [fg, bg] so we avoid repeated PSObject property lookups
    # Also tracks which tiles are animated (color cycling)
    if ($null -eq $Script:_tileColorCache -or $Script:_tileColorCacheConfig -ne $MapConfig) {
        $Script:_tileColorCache = @{}
        $Script:_animatedTileSet = @{}
        $Script:_tileColorCacheConfig = $MapConfig
        if ($MapConfig.tiles -and $MapConfig.tiles.PSObject) {
            foreach ($prop in $MapConfig.tiles.PSObject.Properties) {
                $ch = $prop.Name
                $info = $prop.Value
                $fg = [ConsoleColor]::Gray
                $bg = [ConsoleColor]::Black
                if ($info.color) { try { $fg = [ConsoleColor]($info.color) } catch {} }
                if ($info.bgColor) { try { $bg = [ConsoleColor]($info.bgColor) } catch {} }
                $Script:_tileColorCache[$ch] = @($fg, $bg)
                if ($info.animated -eq $true) {
                    $Script:_animatedTileSet[$ch] = $true
                }
            }
        }
    }
    $colorCache = $Script:_tileColorCache
    $animSet    = $Script:_animatedTileSet
    $waterColors = $Script:WaterColorCycle
    $animFrame   = [int](([Environment]::TickCount - $Script:AnimStartTick) / $Script:AnimIntervalMs)

    # ── Calculate viewport offset to center on player ──
    $viewOffsetX = 0
    $viewOffsetY = 0

    if ($MapData.Width -gt $Script:MAP_VIEWPORT_WIDTH) {
        $viewOffsetX = $PlayerX - [math]::Floor($Script:MAP_VIEWPORT_WIDTH / 2)
        $viewOffsetX = [math]::Max(0, [math]::Min($viewOffsetX, $MapData.Width - $Script:MAP_VIEWPORT_WIDTH))
    }
    if ($MapData.Height -gt $Script:MAP_VIEWPORT_HEIGHT) {
        $viewOffsetY = $PlayerY - [math]::Floor($Script:MAP_VIEWPORT_HEIGHT / 2)
        $viewOffsetY = [math]::Max(0, [math]::Min($viewOffsetY, $MapData.Height - $Script:MAP_VIEWPORT_HEIGHT))
    }

    # ── Direct buffer references for speed ──
    $sw     = $Script:SCREEN_WIDTH
    $cChars = $Script:CurrentChars
    $cFg    = $Script:CurrentFgColors
    $cBg    = $Script:CurrentBgColors
    $tiles  = $MapData.Tiles
    $mapW   = $MapData.Width
    $mapH   = $MapData.Height
    $vpX    = $Script:MAP_VIEWPORT_X
    $vpY    = $Script:MAP_VIEWPORT_Y
    $vpW    = $Script:MAP_VIEWPORT_WIDTH
    $vpH    = $Script:MAP_VIEWPORT_HEIGHT

    # Player character
    $playerChar = [char]'@'
    if ($Script:GameState.Party.Count -gt 0) {
        $playerChar = [char]$Script:GameState.Party[0].Symbol
    }

    $defaultFg = [ConsoleColor]::Gray
    $defaultBg = [ConsoleColor]::Black
    $playerFg  = [ConsoleColor]::White
    $playerBg  = [ConsoleColor]::DarkBlue
    $voidFg    = [ConsoleColor]::Black
    $voidBg    = [ConsoleColor]::Black

    for ($vy = 0; $vy -lt $vpH; $vy++) {
        $mapY = $vy + $viewOffsetY
        $screenRowBase = ($vy + $vpY) * $sw + $vpX

        for ($vx = 0; $vx -lt $vpW; $vx++) {
            $mapX = $vx + $viewOffsetX
            $idx  = $screenRowBase + $vx

            if ($mapX -ge 0 -and $mapX -lt $mapW -and $mapY -ge 0 -and $mapY -lt $mapH) {
                if ($mapX -eq $PlayerX -and $mapY -eq $PlayerY) {
                    $cChars[$idx] = $playerChar
                    $cFg[$idx]    = $playerFg
                    $cBg[$idx]    = $playerBg
                }
                else {
                    $tile = $tiles[$mapX, $mapY]
                    $cChars[$idx] = $tile
                    $tileStr = [string]$tile
                    $colors = $colorCache[$tileStr]
                    if ($colors) {
                        $cBg[$idx] = $colors[1]
                        if ($animSet[$tileStr]) {
                            # Animated tile: cycle fg color in a wave pattern
                            $offset = ($mapX + $mapY + $animFrame) % 4
                            $cFg[$idx] = $waterColors[$offset]
                        }
                        else {
                            $cFg[$idx] = $colors[0]
                        }
                    }
                    else {
                        $cFg[$idx] = $defaultFg
                        $cBg[$idx] = $defaultBg
                    }
                }
            }
            else {
                $cChars[$idx] = ' '
                $cFg[$idx]    = $voidFg
                $cBg[$idx]    = $voidBg
            }
        }
    }
}

# ── Player Movement ──────────────────────────────────────────────────────────────

function Move-Player {
    <#
    .SYNOPSIS
        Attempts to move the player by (DX, DY). Checks bounds, collision,
        door transitions, and random encounters.
    #>
    param(
        [int]$DX,
        [int]$DY
    )

    $newX = $Script:GameState.PlayerPosition.X + $DX
    $newY = $Script:GameState.PlayerPosition.Y + $DY

    $mapData   = $Script:GameState.CurrentMap
    $mapConfig = $Script:GameState.CurrentMapConfig

    # Bounds check
    if ($newX -lt 0 -or $newX -ge $mapData.Width -or $newY -lt 0 -or $newY -ge $mapData.Height) {
        return
    }

    $tile = $mapData.Tiles[$newX, $newY]

    # Passability check
    if (-not (Test-TilePassable -TileChar $tile -MapConfig $mapConfig)) {
        return
    }

    # Move the player
    $Script:GameState.PlayerPosition.X = $newX
    $Script:GameState.PlayerPosition.Y = $newY
    $Script:GameState.StepCounter++

    # Check for door / map transition at new position
    $action = Get-TileAction -X $newX -Y $newY -MapConfig $mapConfig
    if ($action -and $action.Type -eq 'Door') {
        $Script:GameState.CurrentMap       = Load-Map       -MapName    $action.TargetMap
        $Script:GameState.CurrentMapConfig = Load-MapConfig -ConfigName $action.TargetConfig
        $Script:GameState.CurrentMapName   = $action.TargetMap
        $Script:GameState.PlayerPosition.X = $action.TargetX
        $Script:GameState.PlayerPosition.Y = $action.TargetY
        Apply-TileOverrides
        Invoke-ForceFullRedraw
        Add-GameMessage "Entered $($Script:GameState.CurrentMapConfig.displayName)."
        Invoke-CheckCutscenes -EventType 'map_enter' -EventData $action.TargetMap
        return
    }

    # Check for random encounter
    if ($mapConfig.encounters -and $mapConfig.encounters.enabled) {
        $chance = [int]($mapConfig.encounters.chance)   # percent per step
        $roll = Get-Random -Minimum 0 -Maximum 100
        if ($roll -lt $chance) {
            Start-RandomEncounter -MapConfig $mapConfig
        }
    }
}
