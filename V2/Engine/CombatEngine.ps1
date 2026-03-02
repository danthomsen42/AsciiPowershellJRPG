# Engine/CombatEngine.ps1 - Full Turn-Based Combat System
# Phase 2: Speed-based turn order, Main/Secondary/Item/Defend/Run actions,
# enemy sprites, damage formulas, drops, EXP/Gold rewards.

# ── Layout Constants ─────────────────────────────────────────────────────────────
$Script:COMBAT_ENEMY_AREA_Y  = 1     # Enemy sprite/name area starts at row 1
$Script:COMBAT_ENEMY_AREA_H  = 14    # Height for enemy display
$Script:COMBAT_PARTY_X       = 1
$Script:COMBAT_PARTY_Y       = 16
$Script:COMBAT_PARTY_W       = 58
$Script:COMBAT_PARTY_H       = 9
$Script:COMBAT_ACTION_X      = 60
$Script:COMBAT_ACTION_Y      = 16
$Script:COMBAT_ACTION_W      = 58
$Script:COMBAT_ACTION_H      = 9
$Script:COMBAT_LOG_Y         = 26
$Script:COMBAT_LOG_LINES     = 3

# ── Battle Text Speed ────────────────────────────────────────────────────────────

function Get-BattleTextDelay {
    <#
    .SYNOPSIS  Returns the pause duration (ms) between combat log messages,
               based on the BattleTextSpeed setting.
    #>
    switch ($Script:Settings.BattleTextSpeed) {
        'Fast'   { return 120 }
        'Slow'   { return 700 }
        default  { return 350 }   # Normal
    }
}

# ── Battle Transition Effects ────────────────────────────────────────────────────

# Available transition styles
$Script:TransitionStyles = @('flash', 'sweep_lr', 'sweep_tb', 'spiral', 'shatter', 'diagonal')

function Invoke-BattleTransition {
    <#
    .SYNOPSIS  Plays a visual transition before entering combat.
    .PARAMETER Style
        Force a specific style (e.g. 'flash'). If empty/null, a random style is chosen.
    #>
    param([string]$Style = '')

    if (-not $Script:Settings.BattleTransitions) { return }

    if (-not $Style -or $Style -eq '' -or $Style -eq 'random') {
        $Style = $Script:TransitionStyles[(Get-Random -Minimum 0 -Maximum $Script:TransitionStyles.Count)]
    }

    $sw = $Script:SCREEN_WIDTH
    $sh = $Script:SCREEN_HEIGHT

    switch ($Style) {
        # ── Flash: rapid black-white-red flash ──
        'flash' {
            $colors = @([ConsoleColor]::White, [ConsoleColor]::Black, [ConsoleColor]::Red, [ConsoleColor]::Black, [ConsoleColor]::DarkRed)
            foreach ($c in $colors) {
                Clear-FrameBuffer
                for ($row = 0; $row -lt $sh; $row++) {
                    Set-Text -X 0 -Y $row -Text (' ' * $sw) -FgColor $c -BgColor $c
                }
                Invoke-RenderFrame
                [System.Threading.Thread]::Sleep(60)
            }
            Clear-FrameBuffer
            Invoke-RenderFrame
        }

        # ── Sweep Left→Right: columns fill with dark blocks ──
        'sweep_lr' {
            $step = [math]::Max(1, [math]::Floor($sw / 12))
            for ($x = 0; $x -lt $sw; $x += $step) {
                $end = [math]::Min($sw, $x + $step)
                $block = [string]::new([char]0x2588, $end - $x)
                for ($row = 0; $row -lt $sh; $row++) {
                    Set-Text -X $x -Y $row -Text $block -FgColor ([ConsoleColor]::DarkRed) -BgColor ([ConsoleColor]::Black)
                }
                Invoke-RenderFrame
                [System.Threading.Thread]::Sleep(25)
            }
            [System.Threading.Thread]::Sleep(100)
            Clear-FrameBuffer
            Invoke-RenderFrame
        }

        # ── Sweep Top→Bottom: rows fill down ──
        'sweep_tb' {
            $step = [math]::Max(1, [math]::Floor($sh / 10))
            $block = [string]::new([char]0x2588, $sw)
            for ($y = 0; $y -lt $sh; $y += $step) {
                $end = [math]::Min($sh, $y + $step)
                for ($row = $y; $row -lt $end; $row++) {
                    Set-Text -X 0 -Y $row -Text $block -FgColor ([ConsoleColor]::DarkRed) -BgColor ([ConsoleColor]::Black)
                }
                Invoke-RenderFrame
                [System.Threading.Thread]::Sleep(30)
            }
            [System.Threading.Thread]::Sleep(100)
            Clear-FrameBuffer
            Invoke-RenderFrame
        }

        # ── Spiral inward ──
        'spiral' {
            $filled = [bool[,]]::new($sw, $sh)
            $block = [char]0x2588
            $left = 0; $right = $sw - 1; $top = 0; $bottom = $sh - 1
            $cellsPerFrame = [math]::Max(1, [math]::Floor(($sw * $sh) / 20))
            $count = 0
            while ($left -le $right -and $top -le $bottom) {
                for ($x = $left; $x -le $right; $x++) {
                    Set-Cell -X $x -Y $top -Char $block -FgColor ([ConsoleColor]::DarkRed)
                    $count++; if ($count % $cellsPerFrame -eq 0) { Invoke-RenderFrame; [System.Threading.Thread]::Sleep(16) }
                }
                $top++
                for ($y = $top; $y -le $bottom; $y++) {
                    Set-Cell -X $right -Y $y -Char $block -FgColor ([ConsoleColor]::DarkRed)
                    $count++; if ($count % $cellsPerFrame -eq 0) { Invoke-RenderFrame; [System.Threading.Thread]::Sleep(16) }
                }
                $right--
                for ($x = $right; $x -ge $left; $x--) {
                    Set-Cell -X $x -Y $bottom -Char $block -FgColor ([ConsoleColor]::DarkRed)
                    $count++; if ($count % $cellsPerFrame -eq 0) { Invoke-RenderFrame; [System.Threading.Thread]::Sleep(16) }
                }
                $bottom--
                for ($y = $bottom; $y -ge $top; $y--) {
                    Set-Cell -X $left -Y $y -Char $block -FgColor ([ConsoleColor]::DarkRed)
                    $count++; if ($count % $cellsPerFrame -eq 0) { Invoke-RenderFrame; [System.Threading.Thread]::Sleep(16) }
                }
                $left++
            }
            Invoke-RenderFrame
            [System.Threading.Thread]::Sleep(100)
            Clear-FrameBuffer
            Invoke-RenderFrame
        }

        # ── Shatter: random blocks fill the screen ──
        'shatter' {
            $block = [string]::new([char]0x2592, 4)
            $iterations = 60
            for ($i = 0; $i -lt $iterations; $i++) {
                $bx = Get-Random -Minimum 0 -Maximum ($sw - 4)
                $by = Get-Random -Minimum 0 -Maximum $sh
                $c = @([ConsoleColor]::DarkRed, [ConsoleColor]::Red, [ConsoleColor]::DarkYellow, [ConsoleColor]::Black)[(Get-Random -Minimum 0 -Maximum 4)]
                Set-Text -X $bx -Y $by -Text $block -FgColor $c -BgColor ([ConsoleColor]::Black)
                if ($i % 5 -eq 0) {
                    Invoke-RenderFrame
                    [System.Threading.Thread]::Sleep(16)
                }
            }
            # Quick fill to black
            for ($row = 0; $row -lt $sh; $row++) {
                Set-Text -X 0 -Y $row -Text (' ' * $sw) -FgColor ([ConsoleColor]::Black) -BgColor ([ConsoleColor]::Black)
            }
            Invoke-RenderFrame
            [System.Threading.Thread]::Sleep(80)
            Clear-FrameBuffer
            Invoke-RenderFrame
        }

        # ── Diagonal wipe ──
        'diagonal' {
            $block = [char]0x2588
            $totalSteps = $sw + $sh
            $step = [math]::Max(1, [math]::Floor($totalSteps / 14))
            for ($d = 0; $d -lt $totalSteps; $d += $step) {
                $dEnd = [math]::Min($totalSteps, $d + $step)
                for ($di = $d; $di -lt $dEnd; $di++) {
                    for ($y = 0; $y -lt $sh; $y++) {
                        $x = $di - $y
                        if ($x -ge 0 -and $x -lt $sw) {
                            Set-Cell -X $x -Y $y -Char $block -FgColor ([ConsoleColor]::DarkRed)
                        }
                    }
                }
                Invoke-RenderFrame
                [System.Threading.Thread]::Sleep(25)
            }
            [System.Threading.Thread]::Sleep(100)
            Clear-FrameBuffer
            Invoke-RenderFrame
        }

        default {
            # Fallback: simple flash
            Clear-FrameBuffer
            Invoke-RenderFrame
            [System.Threading.Thread]::Sleep(200)
        }
    }
}

# ── Ability Definitions ──────────────────────────────────────────────────────────
# Each ability: Name, Type (physical/magic/heal/buff/debuff), stat used, MP cost,
# power multiplier, accuracy modifier, target (single/all/ally/allAllies)
$Script:AbilityTable = @{
    # ── Warrior ──
    'Slash'         = @{ Type='physical'; Stat='Strength';     MP=0;  Power=1.0;  AccMod=0;   Target='single';    Desc='A standard sword strike.' }
    'Power Strike'  = @{ Type='physical'; Stat='Strength';     MP=5;  Power=1.6;  AccMod=-10; Target='single';    Desc='A devastating heavy blow.' }
    'Shield Bash'   = @{ Type='physical'; Stat='Strength';     MP=3;  Power=0.8;  AccMod=5;   Target='single';    Desc='Bash with shield; high accuracy.' }
    'Wide Slash'    = @{ Type='physical'; Stat='Strength';     MP=4;  Power=0.9;  AccMod=0;   Target='cleave';    Desc='A wide arc hitting the target and its neighbor.' }
    # ── Mage ──
    'Fire Bolt'     = @{ Type='magic';    Stat='Intelligence'; MP=4;  Power=1.3;  AccMod=0;   Target='single';    Desc='A bolt of flame.' }
    'Ice Shard'     = @{ Type='magic';    Stat='Intelligence'; MP=5;  Power=1.1;  AccMod=0;   Target='all';       Desc='Ice shards hit all enemies.' }
    'Lightning'     = @{ Type='magic';    Stat='Intelligence'; MP=7;  Power=1.7;  AccMod=-5;  Target='single';    Desc='A powerful lightning bolt.' }
    'Chain Bolt'    = @{ Type='magic';    Stat='Intelligence'; MP=6;  Power=1.2;  AccMod=-5;  Target='random:3';  Desc='Lightning arcs between up to 3 foes.' }
    'Tidal Wave'    = @{ Type='magic';    Stat='Intelligence'; MP=10; Power=1.0;  AccMod=0;   Target='all';       Desc='A massive wave crashes into every foe.' }
    # ── Rogue ──
    'Backstab'      = @{ Type='physical'; Stat='Strength';     MP=0;  Power=1.2;  AccMod=5;   Target='single';    Desc='A precise strike from the shadows.' }
    'Poison Strike' = @{ Type='physical'; Stat='Strength';     MP=4;  Power=1.0;  AccMod=0;   Target='single';    Desc='Envenomed blade attack.'; StatusEffect='Poison'; StatusChance=60 }
    'Steal'         = @{ Type='special';  Stat='Speed';        MP=2;  Power=0;    AccMod=10;  Target='single';    Desc='Attempt to steal an item.' }
    'Smoke Bomb'    = @{ Type='debuff';   Stat='Speed';        MP=3;  Power=0;    AccMod=100; Target='all';       Desc='Lowers enemy accuracy.'; StatusEffect='Blind'; StatusChance=50 }
    'Fan of Knives' = @{ Type='physical'; Stat='Strength';     MP=5;  Power=0.8;  AccMod=-10; Target='random:3';  Desc='Hurls knives at up to 3 random enemies.' }
    # ── Cleric ──
    'Smite'         = @{ Type='magic';    Stat='Intelligence'; MP=3;  Power=1.2;  AccMod=0;   Target='single';    Desc='Holy damage to one foe.' }
    'Heal'          = @{ Type='heal';     Stat='Intelligence'; MP=5;  Power=1.5;  AccMod=100; Target='ally';      Desc='Restore HP to one ally.' }
    'Bless'         = @{ Type='buff';     Stat='Intelligence'; MP=4;  Power=0;    AccMod=100; Target='allAllies'; Desc='Boost party defense this turn.' }
    'Holy Light'    = @{ Type='magic';    Stat='Intelligence'; MP=8;  Power=1.4;  AccMod=0;   Target='all';       Desc='Holy light damages all enemies.' }
    'Divine Storm'  = @{ Type='magic';    Stat='Intelligence'; MP=6;  Power=1.1;  AccMod=0;   Target='random:4';  Desc='Holy bolts strike up to 4 foes at random.' }
    # ── Ranger ──
    'Arrow Shot'    = @{ Type='physical'; Stat='Strength';     MP=0;  Power=1.0;  AccMod=5;   Target='single';    Desc='A precise arrow.' }
    'Multi-Shot'    = @{ Type='physical'; Stat='Strength';     MP=5;  Power=0.7;  AccMod=-5;  Target='random:3';  Desc='Arrows fly at up to 3 random foes.' }
    'Snare Trap'    = @{ Type='debuff';   Stat='Speed';        MP=3;  Power=0;    AccMod=100; Target='single';    Desc='Slows one enemy.'; StatusEffect='Slow'; StatusChance=70 }
    "Nature's Cure" = @{ Type='heal';     Stat='Intelligence'; MP=4;  Power=1.2;  AccMod=100; Target='ally';      Desc='Herbal healing for one ally.' }
    'Volley'        = @{ Type='physical'; Stat='Strength';     MP=7;  Power=0.6;  AccMod=-5;  Target='all';       Desc='Arrow rain covers every enemy.' }
    # ── Enemy abilities ──
    'Scratch'       = @{ Type='physical'; Stat='Strength';     MP=0;  Power=0.8;  AccMod=0;   Target='single';    Desc='A weak scratch.' }
    'Bite'          = @{ Type='physical'; Stat='Strength';     MP=0;  Power=1.0;  AccMod=0;   Target='single';    Desc='A vicious bite.' }
    'Screech'       = @{ Type='debuff';   Stat='Speed';        MP=0;  Power=0;    AccMod=100; Target='allAllies'; Desc='A disorienting screech.'; StatusEffect='Stun'; StatusChance=25 }
    'Wing Slash'    = @{ Type='physical'; Stat='Strength';     MP=0;  Power=0.9;  AccMod=5;   Target='single';    Desc='Slash with sharp wings.' }
    'Acid Spit'     = @{ Type='magic';    Stat='Intelligence'; MP=0;  Power=1.1;  AccMod=-5;  Target='single';    Desc='Corrosive acid.'; StatusEffect='Poison'; StatusChance=35 }
    'Absorb'        = @{ Type='magic';    Stat='Intelligence'; MP=0;  Power=0.7;  AccMod=0;   Target='single';    Desc='Drains HP from target.' }
    # ── Boss abilities ──
    'Shadow Slash'  = @{ Type='physical'; Stat='Strength';     MP=0;  Power=1.3;  AccMod=0;   Target='cleave';    Desc='A blade wreathed in darkness cleaves two foes.' }
    'Dark Pulse'    = @{ Type='magic';    Stat='Intelligence'; MP=0;  Power=1.0;  AccMod=0;   Target='all';       Desc='A wave of shadow energy hits everyone.'; StatusEffect='Blind'; StatusChance=20 }
    'Soul Drain'    = @{ Type='magic';    Stat='Intelligence'; MP=0;  Power=0.9;  AccMod=5;   Target='single';    Desc='Siphons life force from the target.' }
    # ── New enemy abilities ──
    'Vine Whip'     = @{ Type='physical'; Stat='Strength';     MP=0;  Power=1.1;  AccMod=0;   Target='cleave';    Desc='A thorny vine lashes out at two targets.'; StatusEffect='Slow'; StatusChance=30 }
    'Slam'          = @{ Type='physical'; Stat='Strength';     MP=0;  Power=1.4;  AccMod=-15; Target='single';    Desc='A crushing body slam.'; StatusEffect='Stun'; StatusChance=20 }
}

# ── Status Effect Definitions ────────────────────────────────────────────────────
$Script:StatusEffectDefs = @{
    'Poison' = @{ Duration=3; DamagePercent=0.08; Icon='PSN'; Color=[ConsoleColor]::DarkGreen;  Desc='Takes damage each turn' }
    'Stun'   = @{ Duration=1; SkipTurn=$true;     Icon='STN'; Color=[ConsoleColor]::Yellow;     Desc='Cannot act for 1 turn' }
    'Blind'  = @{ Duration=2; AccuracyMod=-30;    Icon='BLD'; Color=[ConsoleColor]::DarkGray;   Desc='Accuracy greatly reduced' }
    'Slow'   = @{ Duration=2; SpeedMod=-50;       Icon='SLW'; Color=[ConsoleColor]::DarkCyan;   Desc='Speed halved for turn order' }
}

function Apply-StatusEffect {
    <#
    .SYNOPSIS Applies a status effect to a target entity. No stacking — refreshes duration.
    #>
    param([hashtable]$Target, [string]$EffectName, [string]$TargetName)

    if (-not $Script:Settings.StatusEffects) { return }
    if (-not $Target.ContainsKey('StatusEffects')) { $Target.StatusEffects = @() }
    $def = $Script:StatusEffectDefs[$EffectName]
    if (-not $def) { return }

    # Check if already has this effect — refresh duration
    $existing = $Target.StatusEffects | Where-Object { $_.Type -eq $EffectName }
    if ($existing) {
        $existing.Duration = [int]$def.Duration
        Add-CombatLog "$TargetName's $EffectName is refreshed!"
    } else {
        $Target.StatusEffects += @{ Type = $EffectName; Duration = [int]$def.Duration }
        Add-CombatLog "$TargetName is afflicted with $EffectName!"
    }
}

function Process-StatusEffects {
    <#
    .SYNOPSIS
        Processes all status effects on an entity at the start of their turn.
        Returns $true if the entity can act, $false if stunned.
    #>
    param([hashtable]$Entity, [string]$EntityName)

    if (-not $Script:Settings.StatusEffects) { return $true }
    if (-not $Entity.ContainsKey('StatusEffects') -or $Entity.StatusEffects.Count -eq 0) { return $true }

    $canAct = $true
    $newEffects = @()

    foreach ($effect in $Entity.StatusEffects) {
        $eDef = $Script:StatusEffectDefs[$effect.Type]
        switch ($effect.Type) {
            'Poison' {
                $dmg = [math]::Max(1, [math]::Floor([int]$Entity.MaxHP * $eDef.DamagePercent))
                $Entity.HP = [math]::Max(1, [int]$Entity.HP - $dmg)
                Add-CombatLog "$EntityName takes $dmg poison damage!"
            }
            'Stun' {
                Add-CombatLog "$EntityName is stunned and cannot act!"
                $canAct = $false
            }
            'Blind' {
                # Handled in Test-Hit via GetStatusAccuracyMod
            }
            'Slow' {
                # Handled in turn order via GetStatusSpeedMod
            }
        }
        $effect.Duration = [int]$effect.Duration - 1
        if ([int]$effect.Duration -gt 0) {
            $newEffects += $effect
        } else {
            Add-CombatLog "$EntityName's $($effect.Type) wears off."
        }
    }
    $Entity.StatusEffects = $newEffects
    return $canAct
}

function Get-StatusAccuracyMod {
    <# Returns accuracy modifier from status effects (e.g., Blind = -30). #>
    param([hashtable]$Entity)
    $mod = 0
    if ($Entity.ContainsKey('StatusEffects')) {
        foreach ($fx in $Entity.StatusEffects) {
            $def = $Script:StatusEffectDefs[$fx.Type]
            if ($def -and $def.AccuracyMod) { $mod += [int]$def.AccuracyMod }
        }
    }
    return $mod
}

function Get-StatusSpeedMod {
    <# Returns speed modifier from status effects (Slow = -50%). Returns a multiplier. #>
    param([hashtable]$Entity)
    if ($Entity.ContainsKey('StatusEffects')) {
        foreach ($fx in $Entity.StatusEffects) {
            if ($fx.Type -eq 'Slow') { return 0.5 }
        }
    }
    return 1.0
}

function Get-StatusIcons {
    <# Returns status effect icon string for display (e.g. "PSN SLW"). #>
    param([hashtable]$Entity)
    if (-not $Entity.ContainsKey('StatusEffects') -or $Entity.StatusEffects.Count -eq 0) { return '' }
    $icons = @()
    foreach ($fx in $Entity.StatusEffects) {
        $def = $Script:StatusEffectDefs[$fx.Type]
        if ($def) { $icons += $def.Icon }
    }
    return ($icons -join ' ')
}

function Clear-AllStatusEffects {
    <# Clears status effects from all party members (called after combat). #>
    foreach ($m in $Script:GameState.Party) {
        if ($m.ContainsKey('StatusEffects')) { $m.StatusEffects = @() }
    }
}

# ── Multi-Target Resolution ──────────────────────────────────────────────────────

function Resolve-MultiTargets {
    <#
    .SYNOPSIS
        Resolves target list for multi-target abilities.
        Target types:
          'single'    - already resolved (1 target)
          'all'       - all alive enemies/allies
          'allAllies' - all alive party members
          'ally'      - single ally
          'cleave'    - primary target + 1 adjacent alive enemy
          'random:N'  - up to N random alive enemies (can hit same enemy twice)
    #>
    param(
        [string]$TargetType,
        [object]$PrimaryTarget,  # The initially selected target (used for cleave)
        [bool]$IsPartyActor = $true
    )

    # Cleave: returns primary + 1 adjacent alive enemy from the enemy list
    if ($TargetType -eq 'cleave') {
        if ($IsPartyActor) {
            # Player attacking enemies: find index of primary in alive enemies
            $alive = @($Script:CombatState.Enemies | Where-Object { $_.Alive })
            $idx = -1
            for ($i = 0; $i -lt $alive.Count; $i++) {
                if ($alive[$i] -eq $PrimaryTarget) { $idx = $i; break }
            }
            $targets = @($PrimaryTarget)
            # Pick adjacent (prefer right neighbor, fallback left)
            if ($idx -ge 0) {
                if ($idx + 1 -lt $alive.Count) {
                    $targets += $alive[$idx + 1]
                } elseif ($idx - 1 -ge 0) {
                    $targets += $alive[$idx - 1]
                }
            }
            return $targets
        } else {
            # Enemy attacking party: cleave primary + 1 adjacent alive party member
            $alive = @($Script:GameState.Party | Where-Object { [int]$_.HP -gt 0 })
            $idx = -1
            for ($i = 0; $i -lt $alive.Count; $i++) {
                if ($alive[$i] -eq $PrimaryTarget) { $idx = $i; break }
            }
            $targets = @($PrimaryTarget)
            if ($idx -ge 0) {
                if ($idx + 1 -lt $alive.Count) {
                    $targets += $alive[$idx + 1]
                } elseif ($idx - 1 -ge 0) {
                    $targets += $alive[$idx - 1]
                }
            }
            return $targets
        }
    }

    # Random:N
    if ($TargetType -match '^random:(\d+)$') {
        $maxHits = [int]$Matches[1]
        if ($IsPartyActor) {
            $alive = @($Script:CombatState.Enemies | Where-Object { $_.Alive })
        } else {
            $alive = @($Script:GameState.Party | Where-Object { [int]$_.HP -gt 0 })
        }
        $hitCount = [math]::Min($maxHits, $alive.Count)
        # Shuffle and take N  (each enemy hit at most once)
        $shuffled = $alive | Sort-Object { Get-Random }
        return @($shuffled | Select-Object -First $hitCount)
    }

    # Fallback: return primary only
    return @($PrimaryTarget)
}

# ── Sprite Loading ───────────────────────────────────────────────────────────────

function Load-EnemySprite {
    param([string]$SpriteId)

    $spritePath = Join-Path $Script:GameRoot "Data\Enemies\$SpriteId.txt"
    if (-not (Test-Path $spritePath)) { return @{ Lines = @('???'); Width = 3; Height = 1; Color = [ConsoleColor]::Red } }

    $rawLines = Get-Content $spritePath -Encoding UTF8
    $spriteLines = @()
    foreach ($line in $rawLines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.TrimStart().StartsWith(';')) { continue }
        # Strip the # border
        if ($line.StartsWith('#') -and $line.EndsWith('#')) {
            $inner = $line.Substring(1, $line.Length - 2)
            # Skip if it's all #'s (top/bottom border)
            if ($inner -match '^#+$') { continue }
            $spriteLines += $inner
        }
    }
    if ($spriteLines.Count -eq 0) { $spriteLines = @('?') }
    $maxW = ($spriteLines | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum

    # Load color from JSON
    $jsonPath = Join-Path $Script:GameRoot "Data\Enemies\$SpriteId.json"
    $color = [ConsoleColor]::Red
    if (Test-Path $jsonPath) {
        $data = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($data.color) { try { $color = [ConsoleColor]($data.color) } catch {} }
    }

    return @{ Lines = $spriteLines; Width = $maxW; Height = $spriteLines.Count; Color = $color }
}

function Load-EnemyStats {
    param([string]$SpriteId, [int]$Level)

    $jsonPath = Join-Path $Script:GameRoot "Data\Enemies\$SpriteId.json"
    if (-not (Test-Path $jsonPath)) {
        return @{ Name='Unknown'; HP=10; MaxHP=10; MP=0; Strength=5; Intelligence=3; Speed=5; Defense=3; Accuracy=70; EXP=10; Gold=5; Abilities=@('Scratch'); Drops=@(); StatusEffects=@() }
    }

    $data = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $lvlBonus = [math]::Max(0, $Level - 1)
    $sc = $data.levelScaling

    $hp  = [int]$data.baseHP      + $lvlBonus * [int]$sc.HP
    $str = [int]$data.baseStrength + $lvlBonus * [int]$sc.Strength
    $def = [int]$data.baseDefense  + $lvlBonus * [int]$sc.Defense
    $spd = [int]$data.baseSpeed    + $lvlBonus * [int]$sc.Speed
    $exp = [int]$data.baseEXP      + $lvlBonus * [int]$sc.EXP
    $gld = [int]$data.baseGold     + $lvlBonus * [int]$sc.Gold
    $intl = [int]$data.baseIntelligence
    $acc  = [int]$data.baseAccuracy
    $mp   = [int]$data.baseMP

    $abilities = @()
    if ($data.abilities) { $abilities = @($data.abilities) }
    if ($abilities.Count -eq 0) { $abilities = @('Scratch') }

    $drops = @()
    if ($data.drops) { $drops = @($data.drops) }

    return @{
        Name=$data.name; HP=$hp; MaxHP=$hp; MP=$mp; Strength=$str; Intelligence=$intl
        Speed=$spd; Defense=$def; Accuracy=$acc; EXP=$exp; Gold=$gld
        Abilities=$abilities; Drops=$drops; StatusEffects=@()
    }
}

# ── Scripted Battle Data ──────────────────────────────────────────────────────────
$Script:ScriptedBattleDefinitions = $null

function Load-ScriptedBattleDefinitions {
    $path = Join-Path $Script:GameRoot "Data\ScriptedBattles.json"
    if (Test-Path $path) {
        $Script:ScriptedBattleDefinitions = (Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json).battles
    }
}

function Start-ScriptedBattle {
    <#
    .SYNOPSIS
        Starts a pre-defined battle (boss fight, story battle, etc.).
        Unlike random encounters, enemies are fixed and running may be disabled.
    #>
    param([string]$BattleId)

    if (-not $Script:ScriptedBattleDefinitions) { Load-ScriptedBattleDefinitions }
    $battle = $Script:ScriptedBattleDefinitions.PSObject.Properties[$BattleId]
    if (-not $battle) {
        Add-GameMessage "Battle definition not found: $BattleId"
        return
    }
    $battleDef = $battle.Value

    # Play transition effect (battleDef.transition can force a specific style)
    $transStyle = if ($battleDef.transition) { $battleDef.transition } else { '' }
    Invoke-BattleTransition -Style $transStyle

    $Script:GameState.GameMode = 'Combat'

    # Build enemy list from the battle definition
    $enemyList = @()
    foreach ($entry in $battleDef.enemies) {
        $count = if ($entry.count) { [int]$entry.count } else { 1 }
        $level = if ($entry.level) { [int]$entry.level } else { 1 }
        for ($i = 0; $i -lt $count; $i++) {
            $stats  = Load-EnemyStats  -SpriteId $entry.spriteId -Level $level
            $sprite = Load-EnemySprite -SpriteId $entry.spriteId
            # Override name if specified in battle def
            if ($entry.name) { $stats.Name = $entry.name }
            $enemyList += @{
                Name     = if ($entry.name) { $entry.name } else { $stats.Name }
                SpriteId = $entry.spriteId
                Level    = $level
                Stats    = $stats
                Sprite   = $sprite
                Alive    = $true
                DefBuff  = $false
            }
        }
    }

    if ($enemyList.Count -eq 0) {
        Add-GameMessage "No enemies in battle: $BattleId"
        $Script:GameState.GameMode = 'Exploration'
        return
    }

    # Build turn order
    $combatants = @()
    foreach ($m in $Script:GameState.Party) {
        $combatants += @{ Type='party'; Ref=$m; Speed=[int]($m.Speed); Name=$m.Name }
    }
    foreach ($e in $enemyList) {
        $combatants += @{ Type='enemy'; Ref=$e; Speed=[int]($e.Stats.Speed); Name=$e.Name }
    }
    $combatants = $combatants | Sort-Object @{Expression={$_.Speed};Descending=$true}, @{Expression={if($_.Type -eq 'party'){0}else{1}}}

    $Script:CombatState = @{
        Enemies          = $enemyList
        TurnOrder        = @($combatants)
        CurrentTurnIndex = 0
        CombatLog        = @("$($battleDef.name) attacks!")
        IsResolved       = $false
        PlayerRan        = $false
        EXPGained        = 0
        GoldGained       = 0
        TurnPhase        = 'PlayerAction'
        ActivePartyIdx   = 0
        RunAttempts      = @{}
        DefendFlags      = @{}
        ScriptedBattleId = $BattleId
        CanRun           = if ($null -ne $battleDef.canRun) { [bool]$battleDef.canRun } else { $true }
    }

    $bossMsg = if ($battleDef.name) { $battleDef.name } else { 'A powerful foe' }
    Add-GameMessage "$bossMsg attacks! ($($enemyList.Count) foe$(if($enemyList.Count -gt 1){'s'}))"
}

# ── Encounter Initialization ─────────────────────────────────────────────────────

function Start-RandomEncounter {
    param([object]$MapConfig)

    Invoke-BattleTransition

    $Script:GameState.GameMode = 'Combat'

    # Determine which enemies appear
    $enemyList = @()
    if ($MapConfig.encounters.enemies) {
        foreach ($entry in $MapConfig.encounters.enemies) {
            $roll = Get-Random -Minimum 0 -Maximum 100
            $eChance  = [int]($entry.chance)
            if ($roll -lt $eChance) {
                $eMinCount = [int]($entry.minCount)
                $eMaxCount = [int]($entry.maxCount) + 1
                $count = Get-Random -Minimum $eMinCount -Maximum $eMaxCount
                for ($i = 0; $i -lt $count; $i++) {
                    $eMinLvl = [int]($entry.minLevel)
                    $eMaxLvl = [int]($entry.maxLevel) + 1
                    $lvl = Get-Random -Minimum $eMinLvl -Maximum $eMaxLvl
                    $stats = Load-EnemyStats -SpriteId $entry.spriteId -Level $lvl
                    $sprite = Load-EnemySprite -SpriteId $entry.spriteId
                    $enemyList += @{
                        Name     = $entry.name
                        SpriteId = $entry.spriteId
                        Level    = $lvl
                        Stats    = $stats
                        Sprite   = $sprite
                        Alive    = $true
                        DefBuff  = $false
                    }
                }
            }
        }
    }

    # If no enemies rolled, add a default goblin
    if ($enemyList.Count -eq 0) {
        $stats  = Load-EnemyStats  -SpriteId 'Goblin' -Level 1
        $sprite = Load-EnemySprite -SpriteId 'Goblin'
        $enemyList += @{ Name='Goblin'; SpriteId='Goblin'; Level=1; Stats=$stats; Sprite=$sprite; Alive=$true; DefBuff=$false }
    }

    # Build turn order (sorted by speed descending; ties favor party)
    $combatants = @()
    foreach ($m in $Script:GameState.Party) {
        $combatants += @{ Type='party'; Ref=$m; Speed=[int]($m.Speed); Name=$m.Name }
    }
    foreach ($e in $enemyList) {
        $combatants += @{ Type='enemy'; Ref=$e; Speed=[int]($e.Stats.Speed); Name=$e.Name }
    }
    # Sort: higher speed first, party members win ties
    $combatants = $combatants | Sort-Object @{Expression={$_.Speed};Descending=$true}, @{Expression={if($_.Type -eq 'party'){0}else{1}}}

    $Script:CombatState = @{
        Enemies          = $enemyList
        TurnOrder        = @($combatants)
        CurrentTurnIndex = 0
        CombatLog        = @("Enemies appear!")
        IsResolved       = $false
        PlayerRan        = $false
        EXPGained        = 0
        GoldGained       = 0
        TurnPhase        = 'PlayerAction'   # PlayerAction | EnemyAction | Animating | Victory | Defeat | Fled
        ActivePartyIdx   = 0                 # Which party member is picking action
        RunAttempts      = @{}               # Track who tried to run this turn
        DefendFlags      = @{}               # Track who is defending
    }

    Add-GameMessage "Enemies appear! ($($enemyList.Count) foe$(if($enemyList.Count -gt 1){'s'}))"
}

# ── Damage Calculation ───────────────────────────────────────────────────────────

function Get-Damage {
    param(
        [hashtable]$Attacker,     # Stats hashtable (party member or enemy Stats)
        [hashtable]$Defender,     # Stats hashtable
        [hashtable]$Ability,
        [bool]$DefenderDefending = $false
    )

    $stat = Get-EffectiveStat -Entity $Attacker -StatName $Ability.Stat
    $baseDmg = [math]::Max(1, [math]::Floor($stat * [double]$Ability.Power))
    $defense = Get-EffectiveStat -Entity $Defender -StatName 'Defense'
    if ($DefenderDefending) { $defense = [math]::Floor($defense * 1.5) }

    $dmg = [math]::Max(1, $baseDmg - [math]::Floor($defense / 2))
    # Add ±15% variance
    $variance = [math]::Max(1, [math]::Floor($dmg * 0.15))
    $dmg += Get-Random -Minimum (-$variance) -Maximum ($variance + 1)
    return [math]::Max(1, $dmg)
}

function Test-Hit {
    param(
        [int]$AttackerAccuracy,
        [int]$AccMod
    )
    $hitChance = [math]::Min(99, [math]::Max(10, $AttackerAccuracy + $AccMod))
    $roll = Get-Random -Minimum 0 -Maximum 100
    return $roll -lt $hitChance
}

function Get-HealAmount {
    param([hashtable]$Caster, [hashtable]$Ability)
    $stat = Get-EffectiveStat -Entity $Caster -StatName $Ability.Stat
    $base = [math]::Max(5, [math]::Floor($stat * [double]$Ability.Power))
    $variance = [math]::Max(1, [math]::Floor($base * 0.1))
    $base += Get-Random -Minimum (-$variance) -Maximum ($variance + 1)
    return [math]::Max(5, $base)
}

# ── Combat Log Helper ────────────────────────────────────────────────────────────

function Add-CombatLog {
    param([string]$Msg)
    $Script:CombatState.CombatLog += $Msg
    # Keep only last 20 messages
    if ($Script:CombatState.CombatLog.Count -gt 20) {
        $Script:CombatState.CombatLog = @($Script:CombatState.CombatLog | Select-Object -Last 20)
    }
}

# ── Apply Action ─────────────────────────────────────────────────────────────────

function Invoke-CombatAction {
    <#
    .SYNOPSIS
        Executes an ability from an attacker onto target(s).
        Returns array of log messages.
    #>
    param(
        [hashtable]$Actor,        # The combatant (party member or enemy Stats hash)
        [string]$ActorName,
        [string]$AbilityName,
        [object[]]$Targets,       # Array of target refs (party members or enemy entries)
        [bool]$IsPartyActor = $true
    )

    $ability = $Script:AbilityTable[$AbilityName]
    if (-not $ability) {
        Add-CombatLog "$ActorName tries $AbilityName... but nothing happens!"
        return
    }

    # Check MP cost
    $mpCost = [int]$ability.MP
    if ($mpCost -gt 0 -and [int]$Actor.MP -lt $mpCost) {
        Add-CombatLog "$ActorName doesn't have enough MP for $AbilityName!"
        return
    }
    if ($mpCost -gt 0) { $Actor.MP -= $mpCost }

    switch ($ability.Type) {
        'physical' {
            foreach ($t in $Targets) {
                $tStats = if ($IsPartyActor) { $t.Stats } else { $t }
                $tName  = if ($IsPartyActor) { $t.Name } else { $t.Name }
                $isDefending = $false
                if ($IsPartyActor -and $t.DefBuff) { $isDefending = $true }
                if (-not $IsPartyActor -and $Script:CombatState.DefendFlags[$tName]) { $isDefending = $true }
                $blindMod = Get-StatusAccuracyMod -Entity $Actor
                if (Test-Hit -AttackerAccuracy (Get-EffectiveStat -Entity $Actor -StatName 'Accuracy') -AccMod ([int]$ability.AccMod + $blindMod)) {
                    $dmg = Get-Damage -Attacker $Actor -Defender $tStats -Ability $ability -DefenderDefending $isDefending
                    $tStats.HP = [math]::Max(0, [int]$tStats.HP - $dmg)
                    Add-CombatLog "$ActorName uses $AbilityName on $tName for $dmg damage!"
                    if ([int]$tStats.HP -le 0) {
                        if ($IsPartyActor) { $t.Alive = $false }
                        Add-CombatLog "$tName is defeated!"
                    }
                    # Apply status effect if ability has one
                    if ($ability.StatusEffect -and [int]$tStats.HP -gt 0) {
                        $statusRoll = Get-Random -Minimum 0 -Maximum 100
                        if ($statusRoll -lt [int]$ability.StatusChance) {
                            Apply-StatusEffect -Target $tStats -EffectName $ability.StatusEffect -TargetName $tName
                        }
                    }
                } else {
                    Add-CombatLog "$ActorName uses $AbilityName on $tName... Miss!"
                }
            }
        }
        'magic' {
            foreach ($t in $Targets) {
                $tStats = if ($IsPartyActor) { $t.Stats } else { $t }
                $tName  = if ($IsPartyActor) { $t.Name } else { $t.Name }
                $isDefending = $false
                if ($IsPartyActor -and $t.DefBuff) { $isDefending = $true }
                if (-not $IsPartyActor -and $Script:CombatState.DefendFlags[$tName]) { $isDefending = $true }
                $blindMod = Get-StatusAccuracyMod -Entity $Actor
                if (Test-Hit -AttackerAccuracy (Get-EffectiveStat -Entity $Actor -StatName 'Accuracy') -AccMod ([int]$ability.AccMod + $blindMod)) {
                    $dmg = Get-Damage -Attacker $Actor -Defender $tStats -Ability $ability -DefenderDefending $isDefending
                    $tStats.HP = [math]::Max(0, [int]$tStats.HP - $dmg)
                    Add-CombatLog "$ActorName casts $AbilityName on $tName for $dmg damage!"
                    if ([int]$tStats.HP -le 0) {
                        if ($IsPartyActor) { $t.Alive = $false }
                        Add-CombatLog "$tName is defeated!"
                    }
                    # Absorb heals attacker for half damage
                    if ($AbilityName -eq 'Absorb') {
                        $healAmt = [math]::Floor($dmg / 2)
                        $Actor.HP = [math]::Min([int]$Actor.MaxHP, [int]$Actor.HP + $healAmt)
                        Add-CombatLog "$ActorName absorbs $healAmt HP!"
                    }
                    # Apply status effect if ability has one
                    if ($ability.StatusEffect -and [int]$tStats.HP -gt 0) {
                        $statusRoll = Get-Random -Minimum 0 -Maximum 100
                        if ($statusRoll -lt [int]$ability.StatusChance) {
                            Apply-StatusEffect -Target $tStats -EffectName $ability.StatusEffect -TargetName $tName
                        }
                    }
                } else {
                    Add-CombatLog "$ActorName casts $AbilityName on $tName... Miss!"
                }
            }
        }
        'heal' {
            foreach ($t in $Targets) {
                $tRef  = $t
                $tName = $t.Name
                $healAmt = Get-HealAmount -Caster $Actor -Ability $ability
                $tRef.HP = [math]::Min([int]$tRef.MaxHP, [int]$tRef.HP + $healAmt)
                Add-CombatLog "$ActorName uses $AbilityName on $tName, restoring $healAmt HP!"
            }
        }
        'buff' {
            Add-CombatLog "$ActorName uses $AbilityName! Party defense boosted!"
            foreach ($m in $Script:GameState.Party) {
                $Script:CombatState.DefendFlags[$m.Name] = $true
            }
        }
        'debuff' {
            Add-CombatLog "$ActorName uses $AbilityName!"
            # Apply status effect if ability has one
            if ($ability.StatusEffect) {
                foreach ($t in $Targets) {
                    $tStats = if ($IsPartyActor) { $t.Stats } else { $t }
                    $tName  = if ($IsPartyActor) { $t.Name } else { $t.Name }
                    if ([int]$tStats.HP -gt 0) {
                        $statusRoll = Get-Random -Minimum 0 -Maximum 100
                        if ($statusRoll -lt [int]$ability.StatusChance) {
                            Apply-StatusEffect -Target $tStats -EffectName $ability.StatusEffect -TargetName $tName
                        } else {
                            Add-CombatLog "$tName resists the effect!"
                        }
                    }
                }
            }
        }
        'special' {
            if ($AbilityName -eq 'Steal') {
                $t = $Targets[0]
                $tName = if ($IsPartyActor) { $t.Name } else { $t.Name }
                $stealRoll = Get-Random -Minimum 0 -Maximum 100
                if ($stealRoll -lt 40) {
                    $goldStolen = Get-Random -Minimum 1 -Maximum (5 + [int]$Actor.Speed)
                    $Script:GameState.Gold += $goldStolen
                    Add-CombatLog "$ActorName steals $goldStolen gold from $tName!"
                } else {
                    Add-CombatLog "$ActorName tries to steal from $tName... Failed!"
                }
            }
        }
    }
}

# ── Rendering ────────────────────────────────────────────────────────────────────

function Render-CombatScreen {
    <#
    .SYNOPSIS
        Draws the full combat UI: enemy sprites, party panel, action prompts, combat log.
    #>
    param(
        [string]$ActionPrompt = '',
        [string[]]$MenuOptions = @(),
        [int]$SelectedIndex = 0,
        [string]$ActiveMemberName = ''
    )

    Clear-FrameBuffer

    # ── Header ──
    Set-Text -X 1 -Y 0 -Text '=== BATTLE ===' -FgColor ([ConsoleColor]::Red)

    # ── Enemy Area ──
    $enemies = $Script:CombatState.Enemies
    # Calculate total width needed for sprites side-by-side
    $spacing = 2
    $drawX = 2
    foreach ($e in $enemies) {
        $sprite = $e.Sprite
        # Name + level label
        $label = "$($e.Name) Lv.$($e.Level)"
        $labelColor = if ($e.Alive) { [ConsoleColor]::White } else { [ConsoleColor]::DarkGray }
        Set-Text -X $drawX -Y 2 -Text $label -FgColor $labelColor

        # HP bar
        if ($e.Alive) {
            $hpPct = [math]::Max(0, [int]($e.Stats.HP)) / [math]::Max(1, [int]($e.Stats.MaxHP))
            $barW = [math]::Max($sprite.Width, $label.Length)
            $hpColor = if ($hpPct -gt 0.5) { [ConsoleColor]::Green } elseif ($hpPct -gt 0.25) { [ConsoleColor]::Yellow } else { [ConsoleColor]::Red }
            $filledW = [math]::Max(0, [math]::Floor($hpPct * $barW))
            $hpText = "HP:$([int]($e.Stats.HP))/$([int]($e.Stats.MaxHP))"
            Set-Text -X $drawX -Y 3 -Text $hpText -FgColor $hpColor
            # Status effect icons
            $statusIcons = Get-StatusIcons -Entity $e.Stats
            if ($statusIcons) {
                Set-Text -X $drawX -Y 4 -Text $statusIcons -FgColor ([ConsoleColor]::Magenta)
            }
        } else {
            Set-Text -X $drawX -Y 3 -Text 'DEFEATED' -FgColor ([ConsoleColor]::DarkGray)
        }

        # Sprite
        $sprY = 5
        if ($e.Alive) {
            foreach ($line in $sprite.Lines) {
                Set-Text -X $drawX -Y $sprY -Text $line -FgColor $sprite.Color
                $sprY++
            }
        } else {
            Set-Text -X $drawX -Y $sprY -Text '---' -FgColor ([ConsoleColor]::DarkGray)
        }

        $drawX += [math]::Max($sprite.Width, $label.Length) + $spacing
        if ($drawX -gt 100) { break }  # Don't overflow screen
    }

    # ── Horizontal separator ──
    $sepLine = [string]::new([char]0x2500, 118)
    Set-Text -X 1 -Y 15 -Text $sepLine -FgColor ([ConsoleColor]::DarkGray)

    # ── Party Panel ──
    Draw-Box -X $Script:COMBAT_PARTY_X -Y $Script:COMBAT_PARTY_Y -Width $Script:COMBAT_PARTY_W -Height $Script:COMBAT_PARTY_H `
             -Color ([ConsoleColor]::Cyan) -BgColor ([ConsoleColor]::Black) -Fill
    Set-Text -X ($Script:COMBAT_PARTY_X + 2) -Y $Script:COMBAT_PARTY_Y -Text ' Party ' -FgColor ([ConsoleColor]::Cyan)

    $py = $Script:COMBAT_PARTY_Y + 1
    foreach ($m in $Script:GameState.Party) {
        $isActive = ($m.Name -eq $ActiveMemberName)
        $isDead   = ([int]$m.HP -le 0)

        $prefix = if ($isActive) { '>' } else { ' ' }
        $nameText = "$prefix $($m.Symbol) $($m.Name)"
        $statsText = "HP:$($m.HP)/$($m.MaxHP)  MP:$($m.MP)/$($m.MaxMP)"

        $nameColor = [ConsoleColor]::Gray
        if ($isDead) { $nameColor = [ConsoleColor]::DarkGray }
        elseif ($isActive) { $nameColor = [ConsoleColor]::White }

        $hpColor = [ConsoleColor]::Green
        if ($isDead) { $hpColor = [ConsoleColor]::DarkRed }
        elseif ([int]$m.HP -le [int]$m.MaxHP / 4) { $hpColor = [ConsoleColor]::Red }
        elseif ([int]$m.HP -le [int]$m.MaxHP / 2) { $hpColor = [ConsoleColor]::Yellow }

        Set-Text -X ($Script:COMBAT_PARTY_X + 2) -Y $py -Text $nameText -FgColor $nameColor
        Set-Text -X ($Script:COMBAT_PARTY_X + 22) -Y $py -Text $statsText -FgColor $hpColor

        if ($Script:CombatState.DefendFlags[$m.Name]) {
            Set-Text -X ($Script:COMBAT_PARTY_X + 48) -Y $py -Text 'DEF' -FgColor ([ConsoleColor]::Cyan)
        }
        # Status effect icons
        $statusIcons = Get-StatusIcons -Entity $m
        if ($statusIcons) {
            Set-Text -X ($Script:COMBAT_PARTY_X + 52) -Y $py -Text $statusIcons -FgColor ([ConsoleColor]::Magenta)
        }
        $py++
        if ($py -ge ($Script:COMBAT_PARTY_Y + $Script:COMBAT_PARTY_H - 1)) { break }
    }

    # ── Action Panel ──
    Draw-Box -X $Script:COMBAT_ACTION_X -Y $Script:COMBAT_ACTION_Y -Width $Script:COMBAT_ACTION_W -Height $Script:COMBAT_ACTION_H `
             -Color ([ConsoleColor]::Yellow) -BgColor ([ConsoleColor]::Black) -Fill

    if ($ActionPrompt) {
        Set-Text -X ($Script:COMBAT_ACTION_X + 2) -Y $Script:COMBAT_ACTION_Y -Text " $ActionPrompt " -FgColor ([ConsoleColor]::Yellow)
    }

    $ay = $Script:COMBAT_ACTION_Y + 1
    for ($i = 0; $i -lt $MenuOptions.Count; $i++) {
        if ($i -eq $SelectedIndex) {
            Set-Text -X ($Script:COMBAT_ACTION_X + 2) -Y $ay -Text "> $($MenuOptions[$i])" -FgColor ([ConsoleColor]::Black) -BgColor ([ConsoleColor]::White)
            $fillLen = $Script:COMBAT_ACTION_W - 4 - $MenuOptions[$i].Length - 2
            if ($fillLen -gt 0) {
                Set-Text -X ($Script:COMBAT_ACTION_X + 4 + $MenuOptions[$i].Length) -Y $ay -Text (' ' * $fillLen) -FgColor ([ConsoleColor]::Black) -BgColor ([ConsoleColor]::White)
            }
        } else {
            Set-Text -X ($Script:COMBAT_ACTION_X + 2) -Y $ay -Text "  $($MenuOptions[$i])" -FgColor ([ConsoleColor]::Gray)
        }
        $ay++
        if ($ay -ge ($Script:COMBAT_ACTION_Y + $Script:COMBAT_ACTION_H - 1)) { break }
    }

    # ── Combat Log ──
    $logY = $Script:COMBAT_LOG_Y
    $logLines = $Script:CombatState.CombatLog
    $startIdx = [math]::Max(0, $logLines.Count - $Script:COMBAT_LOG_LINES)
    for ($i = $startIdx; $i -lt $logLines.Count; $i++) {
        $lineColor = if ($i -eq $logLines.Count - 1) { [ConsoleColor]::White } else { [ConsoleColor]::DarkGray }
        Set-Text -X 2 -Y $logY -Text $logLines[$i] -FgColor $lineColor
        $logY++
    }

    Invoke-RenderFrame
}

# ── Menu Selection Helper (within combat) ────────────────────────────────────────

function Select-CombatOption {
    <#
    .SYNOPSIS
        Shows a menu in the action panel and returns the selected index.
        Supports Escape to go back (returns -1).
    #>
    param(
        [string]$Prompt,
        [string[]]$Options,
        [string]$ActiveMember = ''
    )

    $sel = 0
    while ($true) {
        Render-CombatScreen -ActionPrompt $Prompt -MenuOptions $Options -SelectedIndex $sel -ActiveMemberName $ActiveMember
        $key = Wait-ForKey
        switch ($key.Key) {
            'UpArrow'   { $sel--; if ($sel -lt 0) { $sel = $Options.Count - 1 } }
            'DownArrow' { $sel++; if ($sel -ge $Options.Count) { $sel = 0 } }
            'Enter'     { return $sel }
            'Escape'    { return -1 }
        }
    }
}

# ── Target Selection ─────────────────────────────────────────────────────────────

function Select-EnemyTarget {
    param([string]$ActiveMember = '')
    $aliveEnemies = @()
    $enemyNames   = @()
    foreach ($e in $Script:CombatState.Enemies) {
        if ($e.Alive) {
            $aliveEnemies += $e
            $enemyNames   += "$($e.Name) Lv.$($e.Level) (HP:$([int]($e.Stats.HP)))"
        }
    }
    if ($aliveEnemies.Count -eq 0) { return $null }
    if ($aliveEnemies.Count -eq 1) { return $aliveEnemies[0] }

    $idx = Select-CombatOption -Prompt 'Target?' -Options $enemyNames -ActiveMember $ActiveMember
    if ($idx -lt 0) { return $null }
    return $aliveEnemies[$idx]
}

function Select-AllyTarget {
    param([string]$ActiveMember = '')
    $allyNames = @()
    foreach ($m in $Script:GameState.Party) {
        $status = if ([int]$m.HP -le 0) { ' [KO]' } else { " (HP:$($m.HP)/$($m.MaxHP))" }
        $allyNames += "$($m.Name)$status"
    }

    $idx = Select-CombatOption -Prompt 'Choose Ally' -Options $allyNames -ActiveMember $ActiveMember
    if ($idx -lt 0) { return $null }
    return $Script:GameState.Party[$idx]
}

# ── Item Use in Combat ───────────────────────────────────────────────────────────

function Use-CombatItem {
    param([hashtable]$Actor, [string]$ActiveMember = '')

    # Filter usable items
    $usable = @()
    foreach ($item in $Script:GameState.Inventory) {
        if ($item.type -eq 'consumable') {
            $usable += $item
        }
    }
    if ($usable.Count -eq 0) {
        Add-CombatLog "No usable items!"
        return $false
    }

    $itemNames = $usable | ForEach-Object { "$($_.name) x$($_.count) - $($_.description)" }
    $idx = Select-CombatOption -Prompt 'Use Item' -Options @($itemNames) -ActiveMember $ActiveMember
    if ($idx -lt 0) { return $false }

    $chosen = $usable[$idx]

    # Pick target ally
    $target = Select-AllyTarget -ActiveMember $ActiveMember
    if (-not $target) { return $false }

    # Apply item
    switch ($chosen.effect) {
        'heal' {
            $healAmt = [int]$chosen.value
            if ([int]$target.HP -le 0) {
                Add-CombatLog "$($target.Name) is KO'd! Can't use $($chosen.name)."
                return $false
            }
            $target.HP = [math]::Min([int]$target.MaxHP, [int]$target.HP + $healAmt)
            Add-CombatLog "$($Actor.Name) uses $($chosen.name) on $($target.Name), restoring $healAmt HP!"
        }
        'restoreMP' {
            $restoreAmt = [int]$chosen.value
            $target.MP = [math]::Min([int]$target.MaxMP, [int]$target.MP + $restoreAmt)
            Add-CombatLog "$($Actor.Name) uses $($chosen.name) on $($target.Name), restoring $restoreAmt MP!"
        }
        'revive' {
            if ([int]$target.HP -gt 0) {
                Add-CombatLog "$($target.Name) doesn't need reviving!"
                return $false
            }
            $target.HP = [math]::Max(1, [math]::Floor([int]$target.MaxHP * [int]$chosen.value / 100))
            Add-CombatLog "$($Actor.Name) uses $($chosen.name)! $($target.Name) is revived!"
        }
        'curePoison' {
            if ($target.ContainsKey('StatusEffects')) {
                $had = $target.StatusEffects | Where-Object { $_.Type -eq 'Poison' }
                if ($had) {
                    $target.StatusEffects = @($target.StatusEffects | Where-Object { $_.Type -ne 'Poison' })
                    Add-CombatLog "$($Actor.Name) uses $($chosen.name)! $($target.Name)'s poison is cured!"
                } else {
                    Add-CombatLog "$($target.Name) isn't poisoned."
                    return $false
                }
            } else {
                Add-CombatLog "$($target.Name) isn't poisoned."
                return $false
            }
        }
        'fullRestore' {
            if ([int]$target.HP -le 0) {
                Add-CombatLog "$($target.Name) is KO'd! Can't use $($chosen.name)."
                return $false
            }
            $target.HP = [int]$target.MaxHP
            $target.MP = [int]$target.MaxMP
            if ($target.ContainsKey('StatusEffects')) { $target.StatusEffects = @() }
            Add-CombatLog "$($Actor.Name) uses $($chosen.name) on $($target.Name)! Fully restored!"
        }
        default {
            Add-CombatLog "$($Actor.Name) uses $($chosen.name)... but it has no combat effect."
            return $false
        }
    }

    # Consume the item
    $chosen.count--
    if ($chosen.count -le 0) {
        $Script:GameState.Inventory = @($Script:GameState.Inventory | Where-Object { $_.id -ne $chosen.id })
    }
    return $true
}

# ── Run Attempt ──────────────────────────────────────────────────────────────────

function Test-RunAttempt {
    param([hashtable]$Member)
    # Block running in scripted battles where canRun is false
    if ($Script:CombatState.CanRun -eq $false) {
        return $false
    }
    # Base 40% + 2% per speed point above average enemy speed
    $avgEnemySpd = 0
    $aliveCount  = 0
    foreach ($e in $Script:CombatState.Enemies) {
        if ($e.Alive) { $avgEnemySpd += [int]($e.Stats.Speed); $aliveCount++ }
    }
    if ($aliveCount -gt 0) { $avgEnemySpd = [math]::Floor($avgEnemySpd / $aliveCount) }

    $memberSpd = Get-EffectiveStat -Entity $Member -StatName 'Speed'
    $chance = 40 + ($memberSpd - $avgEnemySpd) * 2
    $chance = [math]::Max(10, [math]::Min(90, $chance))
    $roll = Get-Random -Minimum 0 -Maximum 100
    return ($roll -lt $chance)
}

# ── Victory / Defeat Handling ────────────────────────────────────────────────────

function Resolve-Victory {
    # Calculate total EXP + Gold from defeated enemies
    $totalEXP  = 0
    $totalGold = 0
    $dropItems = @()

    foreach ($e in $Script:CombatState.Enemies) {
        $totalEXP  += [int]($e.Stats.EXP)
        $totalGold += [int]($e.Stats.Gold)

        # Roll for drops
        if ($e.Stats.Drops) {
            foreach ($drop in $e.Stats.Drops) {
                $roll = Get-Random -Minimum 0 -Maximum 100
                if ($roll -lt [int]($drop.chance)) {
                    $rarity = if ($drop.rarity) { $drop.rarity } else { 'common' }
                    $dropItems += @{ item = $drop.item; rarity = $rarity }
                }
            }
        }
    }

    # Track kills by enemy type for quest objectives
    foreach ($e in $Script:CombatState.Enemies) {
        $killKey = ($e.Name -replace ' ', '_').ToLower() + "_kills"
        if (-not $Script:GameState.Triggers[$killKey]) {
            $Script:GameState.Triggers[$killKey] = 0
        }
        $Script:GameState.Triggers[$killKey] = [int]$Script:GameState.Triggers[$killKey] + 1
    }

    $Script:GameState.Gold += $totalGold
    Add-CombatLog "Victory! Gained $totalEXP EXP and $totalGold Gold."

    # Add drops to inventory with rarity labels
    foreach ($dropInfo in $dropItems) {
        Add-InventoryItem -ItemId $dropInfo.item
        $rarityLabel = ''
        if ($Script:Settings.LootRarityLabels) {
            $rarityLabel = switch ($dropInfo.rarity) {
                'uncommon'  { ' [Uncommon]' }
                'rare'      { ' [Rare!]' }
                'legendary' { ' [LEGENDARY!]' }
                default     { '' }
            }
        }
        Add-CombatLog "Obtained: $($dropInfo.item)$rarityLabel"
    }

    # Distribute EXP to living party members
    foreach ($m in $Script:GameState.Party) {
        if ([int]$m.HP -gt 0) {
            $leveled = Add-EXP -Character $m -Amount $totalEXP
            if ($leveled) {
                Add-CombatLog "$($m.Name) leveled up to Lv.$($m.Level)!"
            }
        }
    }

    Add-GameMessage "Victory! +$($totalEXP) EXP, +$($totalGold) Gold."

    # Handle scripted battle victory (boss fights)
    if ($Script:CombatState.ScriptedBattleId) {
        $battleId = $Script:CombatState.ScriptedBattleId
        if (-not $Script:ScriptedBattleDefinitions) { Load-ScriptedBattleDefinitions }
        $bProp = $Script:ScriptedBattleDefinitions.PSObject.Properties[$battleId]
        if ($bProp) {
            $battleDef = $bProp.Value

            # Set victory trigger
            if ($battleDef.victoryTrigger) {
                $Script:GameState.Triggers[$battleDef.victoryTrigger] = $true
            }

            # Grant bonus rewards on top of normal enemy drops
            if ($battleDef.bonusRewards) {
                if ($battleDef.bonusRewards.gold) {
                    $bGold = [int]$battleDef.bonusRewards.gold
                    $Script:GameState.Gold += $bGold
                    Add-CombatLog "Bonus reward: $bGold gold!"
                }
                if ($battleDef.bonusRewards.exp) {
                    $bExp = [int]$battleDef.bonusRewards.exp
                    foreach ($m in $Script:GameState.Party) {
                        if ([int]$m.HP -gt 0) {
                            Add-EXP -Character $m -Amount $bExp | Out-Null
                        }
                    }
                    Add-CombatLog "Bonus reward: $bExp EXP!"
                }
                if ($battleDef.bonusRewards.items) {
                    foreach ($itemId in $battleDef.bonusRewards.items) {
                        Add-InventoryItem -ItemId $itemId
                        $def = Get-ItemDefinition -ItemId $itemId
                        $iName = if ($def) { $def.name } else { $itemId }
                        Add-CombatLog "Bonus reward: $iName!"
                    }
                }
            }

            # Show victory message
            if ($battleDef.victoryMessage) {
                Add-GameMessage $battleDef.victoryMessage
            }

            # Apply tile overrides now that a trigger changed
            Apply-TileOverrides
        }
    }
}

function Add-InventoryItem {
    param([string]$ItemId)

    # Check if already in inventory (match by id or name for robustness)
    $existing = $Script:GameState.Inventory | Where-Object { $_.id -eq $ItemId -or $_.name -eq $ItemId }
    if ($existing) {
        $existing.count++
        return
    }

    # Look up item definition (match by id or name to handle display-name drops)
    $itemsPath = Join-Path $Script:GameRoot "Data\Items\Items.json"
    if (Test-Path $itemsPath) {
        $itemData = (Get-Content $itemsPath -Raw -Encoding UTF8 | ConvertFrom-Json).items | Where-Object { $_.id -eq $ItemId -or $_.name -eq $ItemId } | Select-Object -First 1
        if ($itemData) {
            $Script:GameState.Inventory += @{
                id          = $itemData.id
                name        = $itemData.name
                description = $itemData.description
                type        = $itemData.type
                effect      = $itemData.effect
                value       = [int]$itemData.value
                buyPrice    = [int]$itemData.buyPrice
                sellPrice   = [int]$itemData.sellPrice
                count       = 1
            }
            return
        }
    }

    # Fallback: unknown item
    $Script:GameState.Inventory += @{
        id = $ItemId; name = $ItemId; description = 'Unknown item.'; type = 'material'; effect = 'none'; value = 0; count = 1
    }
}

# ── Main Combat Loop ─────────────────────────────────────────────────────────────

function Update-Combat {
    <#
    .SYNOPSIS
        Full turn-based combat loop. Each call processes one complete round:
        1. All party members choose actions (top-down by speed)
        2. Turn order executes (speed-sorted, party wins ties)
        3. Enemies take their turns
        4. Check victory/defeat
    #>

    # ── Reset per-round state ──
    $Script:CombatState.RunAttempts = @{}
    $Script:CombatState.DefendFlags = @{}

    $anyoneRan = $false

    # ── Phase 1: Gather party actions ──
    $partyActions = @{}   # memberName -> @{ Action; AbilityName; Targets }

    for ($pi = 0; $pi -lt $Script:GameState.Party.Count; $pi++) {
        $member = $Script:GameState.Party[$pi]
        if ([int]$member.HP -le 0) { continue }  # Skip KO'd members

        $actionChosen = $false
        while (-not $actionChosen) {
            $mainOptions = @('Main Attack', 'Secondary', 'Item', 'Defend', 'Run')
            $sel = Select-CombatOption -Prompt "$($member.Name)'s Turn" -Options $mainOptions -ActiveMember $member.Name

            switch ($sel) {
                0 {
                    # Main Attack
                    $target = Select-EnemyTarget -ActiveMember $member.Name
                    if ($target) {
                        $partyActions[$member.Name] = @{ Action='attack'; AbilityName=$member.MainAttack; Targets=@($target) }
                        $actionChosen = $true
                    }
                }
                1 {
                    # Secondary abilities
                    $secAbilities = @($member.SecondaryAbilities)
                    if ($secAbilities.Count -eq 0) {
                        Add-CombatLog "$($member.Name) has no secondary abilities!"
                    } else {
                        # Build option list with MP costs
                        $secOptions = @()
                        foreach ($ab in $secAbilities) {
                            $abDef = $Script:AbilityTable[$ab]
                            $mpStr = if ($abDef -and [int]$abDef.MP -gt 0) { " (MP:$($abDef.MP))" } else { '' }
                            $secOptions += "$ab$mpStr"
                        }
                        $secIdx = Select-CombatOption -Prompt 'Secondary' -Options $secOptions -ActiveMember $member.Name
                        if ($secIdx -ge 0) {
                            $chosenAbility = $secAbilities[$secIdx]
                            $abDef = $Script:AbilityTable[$chosenAbility]
                            if ($abDef) {
                                # Determine target based on ability type
                                $targets = @()
                                switch -Regex ($abDef.Target) {
                                    '^single$' {
                                        $t = Select-EnemyTarget -ActiveMember $member.Name
                                        if ($t) { $targets = @($t) }
                                    }
                                    '^all$' {
                                        $targets = @($Script:CombatState.Enemies | Where-Object { $_.Alive })
                                    }
                                    '^ally$' {
                                        $t = Select-AllyTarget -ActiveMember $member.Name
                                        if ($t) { $targets = @($t) }
                                    }
                                    '^allAllies$' {
                                        $targets = @($Script:GameState.Party | Where-Object { [int]$_.HP -gt 0 })
                                    }
                                    '^cleave$' {
                                        $t = Select-EnemyTarget -ActiveMember $member.Name
                                        if ($t) { $targets = Resolve-MultiTargets -TargetType 'cleave' -PrimaryTarget $t -IsPartyActor $true }
                                    }
                                    '^random:\d+$' {
                                        $targets = Resolve-MultiTargets -TargetType $abDef.Target -PrimaryTarget $null -IsPartyActor $true
                                    }
                                }
                                if ($targets.Count -gt 0) {
                                    $partyActions[$member.Name] = @{ Action='ability'; AbilityName=$chosenAbility; Targets=$targets }
                                    $actionChosen = $true
                                }
                            }
                        }
                    }
                }
                2 {
                    # Item
                    $used = Use-CombatItem -Actor $member -ActiveMember $member.Name
                    if ($used) {
                        $partyActions[$member.Name] = @{ Action='item'; AbilityName=''; Targets=@() }
                        $actionChosen = $true
                    }
                }
                3 {
                    # Defend
                    $Script:CombatState.DefendFlags[$member.Name] = $true
                    $partyActions[$member.Name] = @{ Action='defend'; AbilityName=''; Targets=@() }
                    Add-CombatLog "$($member.Name) takes a defensive stance!"
                    $actionChosen = $true
                }
                4 {
                    # Run
                    $Script:CombatState.RunAttempts[$member.Name] = $true
                    $partyActions[$member.Name] = @{ Action='run'; AbilityName=''; Targets=@() }
                    $actionChosen = $true
                }
                default {
                    # Escape pressed at top-level -> treat as defend
                }
            }
        }
    }

    # ── Phase 2: Execute turn order ──

    # First check if anyone is trying to run
    $runSuccess = $false
    foreach ($mName in $Script:CombatState.RunAttempts.Keys) {
        $member = $Script:GameState.Party | Where-Object { $_.Name -eq $mName }
        if ($member -and (Test-RunAttempt -Member $member)) {
            $runSuccess = $true
            Add-CombatLog "$mName finds an opening! Party escapes!"
            break
        }
    }

    if ($runSuccess) {
        if ($Script:CombatState.RunAttempts.Count -gt 0 -and -not $runSuccess) {
            # Shouldn't reach here but safety
        }
        Render-CombatScreen -ActionPrompt 'Escaped!'
        [System.Threading.Thread]::Sleep(([int]((Get-BattleTextDelay) / 350.0 * 800)))
        Add-GameMessage "You fled from battle!"
        Clear-AllStatusEffects
        $Script:GameState.GameMode = 'Exploration'
        Invoke-ForceFullRedraw
        return
    }

    if ($Script:CombatState.RunAttempts.Count -gt 0 -and -not $runSuccess) {
        if ($Script:CombatState.CanRun -eq $false) {
            Add-CombatLog "There's no escape from this battle!"
        } else {
            Add-CombatLog "Couldn't escape! The party is exposed!"
        }
    }

    # Execute actions in turn order (party members who chose attack/ability)
    foreach ($combatant in $Script:CombatState.TurnOrder) {
        # Check if combat is already over
        $aliveEnemies = @($Script:CombatState.Enemies | Where-Object { $_.Alive })
        $aliveParty   = @($Script:GameState.Party | Where-Object { [int]$_.HP -gt 0 })
        if ($aliveEnemies.Count -eq 0 -or $aliveParty.Count -eq 0) { break }

        if ($combatant.Type -eq 'party') {
            $member = $combatant.Ref
            if ([int]$member.HP -le 0) { continue }

            # Process status effects at start of turn
            $canAct = Process-StatusEffects -Entity $member -EntityName $member.Name
            if (-not $canAct) {
                Render-CombatScreen -ActiveMemberName $member.Name
                [System.Threading.Thread]::Sleep((Get-BattleTextDelay))
                continue
            }

            $action = $partyActions[$member.Name]
            if (-not $action) { continue }

            switch ($action.Action) {
                'attack' {
                    # Re-validate target is alive; retarget if needed
                    $targets = @($action.Targets | Where-Object { $_.Alive })
                    if ($targets.Count -eq 0) {
                        $targets = @($Script:CombatState.Enemies | Where-Object { $_.Alive } | Select-Object -First 1)
                    }
                    if ($targets.Count -gt 0) {
                        Invoke-CombatAction -Actor $member -ActorName $member.Name -AbilityName $action.AbilityName -Targets $targets -IsPartyActor $true
                    }
                }
                'ability' {
                    $abDef = $Script:AbilityTable[$action.AbilityName]
                    if ($abDef) {
                        $tgtType = $abDef.Target
                        if ($tgtType -eq 'single' -or $tgtType -eq 'all' -or $tgtType -eq 'cleave' -or $tgtType -match '^random:\d+$') {
                            # Re-validate: filter dead enemies from stored targets
                            $targets = @($action.Targets | Where-Object { $_.Alive })
                            # For random:N, re-roll at execution time for freshness
                            if ($tgtType -match '^random:\d+$') {
                                $targets = Resolve-MultiTargets -TargetType $tgtType -PrimaryTarget $null -IsPartyActor $true
                            }
                            elseif ($tgtType -eq 'cleave' -and $targets.Count -gt 0) {
                                $targets = Resolve-MultiTargets -TargetType 'cleave' -PrimaryTarget $targets[0] -IsPartyActor $true
                            }
                            elseif ($targets.Count -eq 0 -and $tgtType -eq 'single') {
                                $targets = @($Script:CombatState.Enemies | Where-Object { $_.Alive } | Select-Object -First 1)
                            }
                        } else {
                            $targets = $action.Targets
                        }
                        $isPartyActor = ($tgtType -ne 'ally' -and $tgtType -ne 'allAllies')
                        if ($targets.Count -gt 0) {
                            Invoke-CombatAction -Actor $member -ActorName $member.Name -AbilityName $action.AbilityName -Targets $targets -IsPartyActor $isPartyActor
                        }
                    }
                }
                'item' { } # Already applied during selection
                'defend' { } # Already flagged
                'run' { } # Already handled above
            }

            # Brief pause for readability
            Render-CombatScreen -ActiveMemberName $member.Name
            [System.Threading.Thread]::Sleep((Get-BattleTextDelay))
        }
        elseif ($combatant.Type -eq 'enemy') {
            $enemyEntry = $combatant.Ref
            if (-not $enemyEntry.Alive) { continue }

            # Process status effects at start of turn
            $canAct = Process-StatusEffects -Entity $enemyEntry.Stats -EntityName $enemyEntry.Name
            if (-not $canAct) {
                # Check if enemy died from poison
                if ([int]$enemyEntry.Stats.HP -le 0) {
                    $enemyEntry.Alive = $false
                    Add-CombatLog "$($enemyEntry.Name) succumbs to poison!"
                }
                Render-CombatScreen
                [System.Threading.Thread]::Sleep((Get-BattleTextDelay))
                continue
            }

            # Enemy AI: pick random ability, resolve targets based on ability type
            $abilities = @($enemyEntry.Stats.Abilities)
            $chosenAbility = $abilities[(Get-Random -Minimum 0 -Maximum $abilities.Count)]
            $abDef = $Script:AbilityTable[$chosenAbility]

            $aliveParty = @($Script:GameState.Party | Where-Object { [int]$_.HP -gt 0 })
            if ($aliveParty.Count -eq 0) { break }

            $tgtType = if ($abDef) { $abDef.Target } else { 'single' }
            switch -Regex ($tgtType) {
                '^all$' {
                    $enemyTargets = @($aliveParty)
                }
                '^allAllies$' {
                    # Enemy buffs/debuffs targeting all allies of the attacker (= all alive enemies)
                    $enemyTargets = @($Script:CombatState.Enemies | Where-Object { $_.Alive })
                }
                '^cleave$' {
                    $primary = $aliveParty[(Get-Random -Minimum 0 -Maximum $aliveParty.Count)]
                    $enemyTargets = Resolve-MultiTargets -TargetType 'cleave' -PrimaryTarget $primary -IsPartyActor $false
                }
                '^random:\d+$' {
                    $enemyTargets = Resolve-MultiTargets -TargetType $tgtType -PrimaryTarget $null -IsPartyActor $false
                }
                default {
                    $enemyTargets = @($aliveParty[(Get-Random -Minimum 0 -Maximum $aliveParty.Count)])
                }
            }

            Invoke-CombatAction -Actor $enemyEntry.Stats -ActorName "$($enemyEntry.Name)" `
                                -AbilityName $chosenAbility -Targets $enemyTargets -IsPartyActor $false

            Render-CombatScreen
            [System.Threading.Thread]::Sleep((Get-BattleTextDelay))
        }
    }

    # ── Phase 3: Check victory / defeat ──
    $aliveEnemies = @($Script:CombatState.Enemies | Where-Object { $_.Alive })
    $aliveParty   = @($Script:GameState.Party | Where-Object { [int]$_.HP -gt 0 })

    if ($aliveEnemies.Count -eq 0) {
        # VICTORY
        Add-CombatLog '--- VICTORY! ---'
        Resolve-Victory

        Render-CombatScreen -ActionPrompt 'VICTORY!'
        [System.Threading.Thread]::Sleep(([int]((Get-BattleTextDelay) / 350.0 * 600)))

        # Show results screen
        $resultLines = @($Script:CombatState.CombatLog | Select-Object -Last 8)
        $sel = Select-CombatOption -Prompt 'Battle Results' -Options @('Continue')

        # Check for post-battle cutscenes (boss victories, etc.)
        $battleId = $Script:CombatState.ScriptedBattleId
        Clear-AllStatusEffects
        $Script:GameState.GameMode = 'Exploration'
        Invoke-ForceFullRedraw
        if ($battleId) {
            Invoke-CheckCutscenes -EventType 'battle_victory' -EventData $battleId
        }
        return
    }

    if ($aliveParty.Count -eq 0) {
        # DEFEAT
        Add-CombatLog '--- DEFEAT ---'
        Render-CombatScreen -ActionPrompt 'DEFEAT'
        [System.Threading.Thread]::Sleep(([int]((Get-BattleTextDelay) / 350.0 * 1000)))

        Add-GameMessage "Your party has been defeated..."
        # For now: restore party to 1HP each and return to exploration
        foreach ($m in $Script:GameState.Party) {
            if ([int]$m.HP -le 0) { $m.HP = 1 }
        }
        Clear-AllStatusEffects
        $Script:GameState.GameMode = 'Exploration'
        Invoke-ForceFullRedraw
        return
    }

    # Round continues — clear defend flags for enemies at end of round
    foreach ($e in $Script:CombatState.Enemies) { $e.DefBuff = $false }

    # Clear party defend flags at end of round
    $Script:CombatState.DefendFlags = @{}
}
