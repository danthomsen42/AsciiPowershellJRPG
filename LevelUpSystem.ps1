# Level Up System - Enhanced Character Progression
# This system provides comprehensive level-up functionality with proper XP requirements,
# stat growth, ability unlocks, and visual feedback

# =============================================================================
# XP REQUIREMENTS AND LEVEL PROGRESSION
# =============================================================================

function Get-XPRequiredForLevel {
    param([int]$Level)
    
    # Progressive XP requirements (Final Fantasy style)
    # Level 1->2: 100 XP
    # Level 2->3: 200 XP  
    # Level 3->4: 350 XP
    # Level 4->5: 550 XP
    # Level 5->6: 800 XP
    # And so on...
    
    if ($Level -le 1) { return 0 }
    if ($Level -eq 2) { return 100 }
    if ($Level -eq 3) { return 300 }      # 100 + 200
    if ($Level -eq 4) { return 650 }      # 300 + 350
    if ($Level -eq 5) { return 1200 }     # 650 + 550
    if ($Level -eq 6) { return 2000 }     # 1200 + 800
    if ($Level -eq 7) { return 3100 }     # 2000 + 1100
    if ($Level -eq 8) { return 4550 }     # 3100 + 1450
    if ($Level -eq 9) { return 6400 }     # 4550 + 1850
    if ($Level -eq 10) { return 8700 }    # 6400 + 2300
    
    # For levels above 10, use exponential growth
    $baseXP = 8700
    for ($i = 11; $i -le $Level; $i++) {
        $baseXP += [math]::Floor($i * 300 + ($i - 10) * 100)
    }
    return $baseXP
}

function Get-XPNeededForNextLevel {
    param([int]$CurrentLevel, [int]$CurrentXP)
    
    $currentLevelXP = Get-XPRequiredForLevel $CurrentLevel
    $nextLevelXP = Get-XPRequiredForLevel ($CurrentLevel + 1)
    
    return $nextLevelXP - $CurrentXP
}

function Get-XPProgressPercent {
    param([int]$CurrentLevel, [int]$CurrentXP)
    
    $currentLevelXP = Get-XPRequiredForLevel $CurrentLevel
    $nextLevelXP = Get-XPRequiredForLevel ($CurrentLevel + 1)
    $progressXP = $CurrentXP - $currentLevelXP
    $levelXPRange = $nextLevelXP - $currentLevelXP
    
    if ($levelXPRange -eq 0) { return 100 }
    return [math]::Min(100, [math]::Floor(($progressXP / $levelXPRange) * 100))
}

# =============================================================================
# STAT GROWTH AND LEVEL-UP BENEFITS
# =============================================================================

function Get-StatGrowthForLevel {
    param([string]$Class, [int]$NewLevel)
    
    # Load character classes
    if (-not $global:CharacterClasses) {
        . "$PSScriptRoot\PartySystem.ps1"
    }
    
    $classData = $global:CharacterClasses[$Class]
    if (-not $classData) {
        Write-Warning "Unknown class: $Class"
        return @{}
    }
    
    # Base growth rates per level
    $growth = @{
        HP = $classData.HPGrowth
        MP = $classData.MPGrowth
        Attack = $classData.AttackGrowth
        Defense = $classData.DefenseGrowth
        Speed = $classData.SpeedGrowth
    }
    
    # Every 5 levels, get bonus stats
    if ($NewLevel % 5 -eq 0) {
        $growth.HP += 2
        $growth.Attack += 1
        $growth.Defense += 1
    }
    
    # Every 10 levels, major stat boost
    if ($NewLevel % 10 -eq 0) {
        $growth.HP += 5
        $growth.MP += 3
        $growth.Attack += 2
        $growth.Defense += 2
        $growth.Speed += 1
    }
    
    return $growth
}

function Get-NewSpellsAtLevel {
    param([string]$Class, [int]$Level)
    
    # Define when each class learns new spells
    $spellProgression = @{
        "Warrior" = @{
            3 = @("Taunt")
            5 = @("Shield Wall")
            7 = @("Berserker Rage")
            10 = @("Sword Dance")
            15 = @("Ultimate Strike")
        }
        "Mage" = @{
            3 = @("Ice Shard")
            4 = @("Lightning Bolt")
            6 = @("Meteor")
            8 = @("Blizzard")
            10 = @("Chain Lightning")
            12 = @("Inferno")
            15 = @("Ultima")
        }
        "Healer" = @{
            2 = @("Cure")
            4 = @("Bless")
            6 = @("Greater Heal")
            8 = @("Resurrect")
            10 = @("Holy Light")
            12 = @("Mass Heal")
            15 = @("Divine Intervention")
        }
        "Rogue" = @{
            3 = @("Sneak Attack")
            5 = @("Poison Blade")
            7 = @("Smoke Bomb")
            9 = @("Assassinate")
            12 = @("Shadow Clone")
            15 = @("Death Strike")
        }
    }
    
    if ($spellProgression.ContainsKey($Class) -and $spellProgression[$Class].ContainsKey($Level)) {
        return $spellProgression[$Class][$Level]
    }
    
    return @()
}

# =============================================================================
# LEVEL UP EXECUTION
# =============================================================================

function Invoke-LevelUp {
    param([PSCustomObject]$Character)
    
    $oldLevel = $Character.Level
    $Character.Level++
    $newLevel = $Character.Level
    
    # Get stat growth for this level
    $growth = Get-StatGrowthForLevel $Character.Class $newLevel
    
    # Apply stat increases
    $Character.MaxHP += $growth.HP
    $Character.HP = $Character.MaxHP  # Full heal on level up
    $Character.MaxMP += $growth.MP
    $Character.MP = $Character.MaxMP  # Full MP restore on level up
    $Character.Attack += $growth.Attack
    $Character.Defense += $growth.Defense
    $Character.Speed += $growth.Speed
    
    # Update NextLevelXP requirement
    $Character.NextLevelXP = Get-XPRequiredForLevel ($newLevel + 1)
    
    # Check for new spells
    $newSpells = Get-NewSpellsAtLevel $Character.Class $newLevel
    if ($newSpells.Count -gt 0) {
        foreach ($spell in $newSpells) {
            if ($spell -notin $Character.Spells) {
                $Character.Spells += $spell
            }
        }
    }
    
    # Display level up notification
    Show-LevelUpDisplay $Character $oldLevel $newLevel $growth $newSpells
    
    # Auto-save after level up
    if (Get-Command "Save-AutoSave" -ErrorAction SilentlyContinue) {
        Save-AutoSave
    }
}

function Show-LevelUpDisplay {
    param(
        [PSCustomObject]$Character,
        [int]$OldLevel,
        [int]$NewLevel,
        [hashtable]$Growth,
        [array]$NewSpells
    )
    
    Clear-Host
    
    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║            🌟 LEVEL UP! 🌟           ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "  $($Character.Name) reached Level $NewLevel!" -ForegroundColor Cyan
    Write-Host "  Class: $($Character.Class)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "  📈 STAT INCREASES:" -ForegroundColor Green
    Write-Host "     HP:      +$($Growth.HP) (now $($Character.MaxHP))" -ForegroundColor White
    Write-Host "     MP:      +$($Growth.MP) (now $($Character.MaxMP))" -ForegroundColor White
    Write-Host "     Attack:  +$($Growth.Attack) (now $($Character.Attack))" -ForegroundColor White
    Write-Host "     Defense: +$($Growth.Defense) (now $($Character.Defense))" -ForegroundColor White
    Write-Host "     Speed:   +$($Growth.Speed) (now $($Character.Speed))" -ForegroundColor White
    Write-Host ""
    
    if ($NewSpells.Count -gt 0) {
        Write-Host "  ✨ NEW SPELLS LEARNED:" -ForegroundColor Magenta
        foreach ($spell in $NewSpells) {
            Write-Host "     🔮 $spell" -ForegroundColor Cyan
        }
        Write-Host ""
    }
    
    # Show XP progress to next level
    $nextLevelXP = Get-XPRequiredForLevel ($NewLevel + 1)
    $xpNeeded = $nextLevelXP - $Character.XP
    Write-Host "  Next Level: $xpNeeded XP needed" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    [Console]::ReadKey($true) | Out-Null
}

# =============================================================================
# PARTY XP DISTRIBUTION
# =============================================================================

function Add-PartyXP {
    param([array]$Party, [int]$XP, [bool]$ShowDetails = $true)
    
    # Get living party members
    $aliveMembers = @($Party | Where-Object { $_.HP -gt 0 })
    if ($aliveMembers.Count -eq 0) { 
        if ($ShowDetails) {
            Write-Host "No living party members to receive XP!" -ForegroundColor Red
        }
        return 
    }
    
    # Distribute XP evenly among living members
    $xpPerMember = [math]::Floor($XP / $aliveMembers.Count)
    $levelUpMembers = @()
    
    if ($ShowDetails) {
        Write-Host ""
        Write-Host "XP Distribution:" -ForegroundColor Yellow
        Write-Host "  Total XP: $XP" -ForegroundColor White
        Write-Host "  Per Member: $xpPerMember XP" -ForegroundColor White
        Write-Host ""
    }
    
    foreach ($member in $aliveMembers) {
        $oldXP = $member.XP
        $member.XP += $xpPerMember
        
        if ($ShowDetails) {
            Write-Host "  $($member.Name): $oldXP → $($member.XP) XP" -ForegroundColor Cyan
        }
        
        # Check for level ups
        $leveledUp = $false
        while ($member.XP -ge (Get-XPRequiredForLevel ($member.Level + 1))) {
            Invoke-LevelUp $member
            $leveledUp = $true
        }
        
        if ($leveledUp) {
            $levelUpMembers += $member
        }
    }
    
    if ($ShowDetails -and $levelUpMembers.Count -eq 0) {
        Write-Host ""
        Write-Host "Press any key to continue..." -ForegroundColor DarkGray
        [Console]::ReadKey($true) | Out-Null
    }
    
    return $levelUpMembers
}

# =============================================================================
# CHARACTER INFORMATION DISPLAY
# =============================================================================

function Show-CharacterLevelInfo {
    param([PSCustomObject]$Character)
    
    $currentLevelXP = Get-XPRequiredForLevel $Character.Level
    $nextLevelXP = Get-XPRequiredForLevel ($Character.Level + 1)
    $progressXP = $Character.XP - $currentLevelXP
    $neededXP = $nextLevelXP - $Character.XP
    $progressPercent = Get-XPProgressPercent $Character.Level $Character.XP
    
    Write-Host "  Level $($Character.Level) $($Character.Class)" -ForegroundColor Yellow
    Write-Host "  XP: $($Character.XP)/$nextLevelXP ($progressPercent%) - $neededXP needed" -ForegroundColor Gray
    
    # Show XP progress bar
    $barLength = 20
    $filledLength = [math]::Floor($barLength * $progressPercent / 100)
    $bar = "█" * $filledLength + "░" * ($barLength - $filledLength)
    Write-Host "  [$bar]" -ForegroundColor Green
}

function Show-PartyLevelOverview {
    param([array]$Party)
    
    Clear-Host
    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          PARTY LEVEL STATUS          ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($member in $Party) {
        Write-Host "🔸 $($member.Name)" -ForegroundColor White
        Show-CharacterLevelInfo $member
        Write-Host ""
    }
    
    # Calculate party averages
    $avgLevel = [math]::Round(($Party | Measure-Object -Property Level -Average).Average, 1)
    $totalXP = ($Party | Measure-Object -Property XP -Sum).Sum
    
    Write-Host "Party Average Level: $avgLevel" -ForegroundColor Yellow
    Write-Host "Total Party XP: $totalXP" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to return..." -ForegroundColor DarkGray
    [Console]::ReadKey($true) | Out-Null
}

# =============================================================================
# INITIALIZATION AND VALIDATION
# =============================================================================

function Initialize-CharacterXP {
    param([PSCustomObject]$Character)
    
    # Ensure NextLevelXP is set correctly
    if (-not $Character.NextLevelXP -or $Character.NextLevelXP -eq 0) {
        $Character.NextLevelXP = Get-XPRequiredForLevel ($Character.Level + 1)
    }
    
    # Validate XP is reasonable for level
    $expectedMinXP = Get-XPRequiredForLevel $Character.Level
    if ($Character.XP -lt $expectedMinXP) {
        Write-Warning "Character $($Character.Name) has less XP than expected for level $($Character.Level). Adjusting..."
        $Character.XP = $expectedMinXP
    }
}

function Initialize-PartyXP {
    param([array]$Party)
    
    foreach ($member in $Party) {
        Initialize-CharacterXP $member
    }
}

Write-Host "Enhanced Level Up System loaded!" -ForegroundColor Green
Write-Host "  Progressive XP requirements" -ForegroundColor Gray
Write-Host "  Stat growth with milestone bonuses" -ForegroundColor Gray
Write-Host "  New spell learning at specific levels" -ForegroundColor Gray
Write-Host "  Visual level-up celebrations" -ForegroundColor Gray
Write-Host "  Party XP distribution with level-up detection" -ForegroundColor Gray
