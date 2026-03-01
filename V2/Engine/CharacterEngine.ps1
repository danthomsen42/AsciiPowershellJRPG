# Engine/CharacterEngine.ps1 - Character Classes, Party Management, and Leveling

function Load-ClassDefinitions {
    <#
    .SYNOPSIS
        Loads class definitions from Data/Classes/Classes.json into $Script:ClassDefinitions.
    #>
    $classPath = Join-Path $Script:GameRoot "Data\Classes\Classes.json"
    if (-not (Test-Path $classPath)) {
        throw "Class definitions not found: $classPath"
    }
    $Script:ClassDefinitions = Get-Content $classPath -Raw | ConvertFrom-Json
}

function New-PartyMember {
    <#
    .SYNOPSIS
        Creates a new party member hashtable from a class name.
    #>
    param(
        [string]$Name,
        [string]$ClassName
    )

    $classDef = $Script:ClassDefinitions.classes | Where-Object { $_.name -eq $ClassName }
    if (-not $classDef) {
        throw "Unknown class: $ClassName"
    }

    return @{
        Name               = $Name
        Class              = $ClassName
        Symbol             = $classDef.symbol
        Level              = 1
        EXP                = 0
        EXPToNext          = [int]$classDef.baseEXPToLevel
        HP                 = [int]$classDef.baseHP
        MaxHP              = [int]$classDef.baseHP
        MP                 = [int]$classDef.baseMP
        MaxMP              = [int]$classDef.baseMP
        Strength           = [int]$classDef.baseStrength
        Intelligence       = [int]$classDef.baseIntelligence
        Speed              = [int]$classDef.baseSpeed
        Defense            = [int]$classDef.baseDefense
        Accuracy           = [int]$classDef.baseAccuracy
        MainAttack         = $classDef.defaultMainAttack
        SecondaryAbilities = @($classDef.defaultSecondaryAbilities)
        Equipment          = @{
            Weapon    = $classDef.startingWeapon
            Armor     = $classDef.startingArmor
            Accessory = $null
        }
        StatusEffects      = @()
    }
}

# ── Effective Stats (base + equipment bonuses) ───────────────────────────────────

function Get-EffectiveStat {
    <#
    .SYNOPSIS
        Returns the effective value of a stat, including equipment bonuses.
        Works for both party members (have Equipment) and enemies (plain stats hash).
    #>
    param([hashtable]$Entity, [string]$StatName)
    $base = [int]$Entity[$StatName]
    if ($Entity.ContainsKey('Equipment') -and $Entity.Equipment) {
        foreach ($slot in @('Weapon', 'Armor', 'Accessory')) {
            $eqName = $Entity.Equipment[$slot]
            if (-not $eqName) { continue }
            $itemDef = Get-ItemDefinition -ItemId $eqName
            if ($itemDef -and $itemDef.statBonus -and $itemDef.statBonus.PSObject) {
                $bonusProp = $itemDef.statBonus.PSObject.Properties[$StatName]
                if ($bonusProp) { $base += [int]$bonusProp.Value }
            }
        }
    }
    return $base
}

function Get-AllEquipmentBonuses {
    <#
    .SYNOPSIS
        Returns a hashtable of all stat bonuses from a character's equipment.
    #>
    param([hashtable]$Character)
    $bonuses = @{ Strength = 0; Intelligence = 0; Speed = 0; Defense = 0; Accuracy = 0 }
    if (-not $Character.ContainsKey('Equipment') -or -not $Character.Equipment) { return $bonuses }
    foreach ($slot in @('Weapon', 'Armor', 'Accessory')) {
        $eqName = $Character.Equipment[$slot]
        if (-not $eqName) { continue }
        $itemDef = Get-ItemDefinition -ItemId $eqName
        if ($itemDef -and $itemDef.statBonus -and $itemDef.statBonus.PSObject) {
            foreach ($prop in $itemDef.statBonus.PSObject.Properties) {
                if ($bonuses.ContainsKey($prop.Name)) {
                    $bonuses[$prop.Name] += [int]$prop.Value
                }
            }
        }
    }
    return $bonuses
}

# ── Leveling ─────────────────────────────────────────────────────────────────────

function Add-EXP {
    <#
    .SYNOPSIS
        Adds EXP to a character and handles level-ups. Returns $true if they leveled.
    #>
    param(
        [hashtable]$Character,
        [int]$Amount
    )

    $Character.EXP += $Amount
    $leveled = $false

    while ($Character.EXP -ge $Character.EXPToNext) {
        $Character.EXP -= $Character.EXPToNext
        $Character.Level++
        $leveled = $true

        # Apply pseudo-random stat growth
        Invoke-LevelUpGrowth -Character $Character

        # Increase EXP threshold (15% per level)
        $Character.EXPToNext = [math]::Floor($Character.EXPToNext * 1.15)
    }

    return $leveled
}

function Invoke-LevelUpGrowth {
    <#
    .SYNOPSIS
        Rolls for each stat increase based on class growth rates.
        Each stat has a % chance to increase by minGain..maxGain.
    #>
    param([hashtable]$Character)

    $classDef = $Script:ClassDefinitions.classes | Where-Object { $_.name -eq $Character.Class }
    $growth   = $classDef.growthRates

    $stats = @('HP', 'MP', 'Strength', 'Intelligence', 'Speed', 'Defense', 'Accuracy')

    foreach ($stat in $stats) {
        $statGrowth = $growth.PSObject.Properties[$stat]
        if (-not $statGrowth) { continue }

        $chance  = [int]($statGrowth.Value.chance)
        $minGain = [int]($statGrowth.Value.minGain)
        $maxGain = [int]($statGrowth.Value.maxGain)

        $roll = Get-Random -Minimum 0 -Maximum 100
        if ($roll -lt $chance) {
            $gain = Get-Random -Minimum $minGain -Maximum ($maxGain + 1)
            $Character.$stat += $gain

            # Keep MaxHP/MaxMP in sync
            if ($stat -eq 'HP') { $Character.MaxHP += $gain }
            if ($stat -eq 'MP') { $Character.MaxMP += $gain }
        }
    }

    # Full restoration on level up
    $Character.HP = $Character.MaxHP
    $Character.MP = $Character.MaxMP
}

# ── Party Creation Screen ────────────────────────────────────────────────────────

function Show-PartyCreation {
    <#
    .SYNOPSIS
        Interactive party creation: pick 4 classes and name each member.
    #>
    $Script:GameState.Party = @()
    $classNames = $Script:ClassDefinitions.classes | ForEach-Object { $_.name }

    for ($slot = 0; $slot -lt 4; $slot++) {
        # ── Class selection screen ──
        Clear-FrameBuffer
        Draw-TextBox -X 10 -Y 1 -Width 100 -Height 28 -Title "Create Party Member $($slot + 1) of 4" `
                     -BorderColor ([ConsoleColor]::Cyan) -BgColor ([ConsoleColor]::Black)

        Set-Text -X 14 -Y 3 -Text "Choose a class:" -FgColor ([ConsoleColor]::White)

        for ($c = 0; $c -lt $classNames.Count; $c++) {
            $cls = $Script:ClassDefinitions.classes[$c]
            $rowY = 5 + ($c * 4)

            # Class name line
            $classLine = "$($c + 1). [$($cls.symbol)] $($cls.name)"
            Set-Text -X 16 -Y $rowY -Text $classLine -FgColor ([ConsoleColor]::Yellow)

            # Stats line
            $statsLine = "   HP:$($cls.baseHP)  MP:$($cls.baseMP)  STR:$($cls.baseStrength)  INT:$($cls.baseIntelligence)  SPD:$($cls.baseSpeed)  DEF:$($cls.baseDefense)  ACC:$($cls.baseAccuracy)"
            Set-Text -X 16 -Y ($rowY + 1) -Text $statsLine -FgColor ([ConsoleColor]::Gray)

            # Description
            Set-Text -X 16 -Y ($rowY + 2) -Text "   $($cls.description)" -FgColor ([ConsoleColor]::DarkGray)
        }

        # Show already-chosen members
        if ($Script:GameState.Party.Count -gt 0) {
            Set-Text -X 14 -Y 23 -Text "Current party:" -FgColor ([ConsoleColor]::DarkCyan)
            $partyStr = ($Script:GameState.Party | ForEach-Object { "$($_.Symbol) $($_.Name)" }) -join "  |  "
            Set-Text -X 16 -Y 24 -Text $partyStr -FgColor ([ConsoleColor]::Cyan)
        }

        Set-Text -X 14 -Y 26 -Text "Press 1-$($classNames.Count) to select class" -FgColor ([ConsoleColor]::White)
        Invoke-RenderFrame

        # Wait for valid selection
        $selectedClass = $null
        while ($null -eq $selectedClass) {
            $key = Wait-ForKey
            $num = [int]$key.KeyChar - [int][char]'0'
            if ($num -ge 1 -and $num -le $classNames.Count) {
                $selectedClass = $classNames[$num - 1]
            }
        }

        # ── Name input screen ──
        Clear-FrameBuffer
        Draw-TextBox -X 20 -Y 10 -Width 80 -Height 7 -Title "Name Your $selectedClass" `
                     -BorderColor ([ConsoleColor]::Cyan) -BgColor ([ConsoleColor]::Black)
        Set-Text -X 24 -Y 12 -Text "Enter name (or press Enter for default): " -FgColor ([ConsoleColor]::White)
        Invoke-RenderFrame

        $memberName = Read-TextInput -X 65 -Y 12 -MaxLength 16
        if ([string]::IsNullOrWhiteSpace($memberName)) {
            $memberName = "$selectedClass$($slot + 1)"
        }

        $member = New-PartyMember -Name $memberName -ClassName $selectedClass
        $Script:GameState.Party += $member
    }

    # ── Summary ──
    Clear-FrameBuffer
    Draw-TextBox -X 20 -Y 5 -Width 80 -Height 20 -Title "Your Party" `
                 -BorderColor ([ConsoleColor]::Green) -BgColor ([ConsoleColor]::Black)

    $y = 7
    foreach ($m in $Script:GameState.Party) {
        Set-Text -X 24 -Y $y -Text "[$($m.Symbol)] $($m.Name) the $($m.Class)" -FgColor ([ConsoleColor]::Yellow)
        $y++
        Set-Text -X 26 -Y $y -Text "HP:$($m.MaxHP)  MP:$($m.MaxMP)  STR:$($m.Strength)  INT:$($m.Intelligence)  SPD:$($m.Speed)  DEF:$($m.Defense)" -FgColor ([ConsoleColor]::Gray)
        $y += 2
    }

    Set-Text -X 24 -Y 22 -Text "Press any key to begin your adventure!" -FgColor ([ConsoleColor]::White)
    Invoke-RenderFrame
    Wait-ForKey | Out-Null
}
