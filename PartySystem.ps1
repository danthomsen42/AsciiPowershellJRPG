# =============================================================================
# PARTY SYSTEM - PHASE 2.1 MULTIPLE PARTY MEMBERS
# =============================================================================
# Foundation for multi-character gameplay with class-based party members
# Built to integrate seamlessly with Phase 5 Character Creation System
# PHASE 2.2: Snake-Style Following System

# =============================================================================
# SNAKE FOLLOWING SYSTEM VARIABLES
# =============================================================================

# Global movement trail for party following (stores last N positions)
$global:PartyTrail = @()
$global:MaxTrailLength = 10  # How many positions to remember

# =============================================================================
# CHARACTER CLASS DEFINITIONS
# =============================================================================

$CharacterClasses = @{
    "Warrior" = @{
        BaseHP = 35; BaseMP = 5; BaseAttack = 8; BaseDefense = 6; BaseSpeed = 6
        HPGrowth = 3; MPGrowth = 1; AttackGrowth = 2; DefenseGrowth = 2; SpeedGrowth = 1
        StartingWeapon = "Iron Sword"; StartingArmor = "Chain Mail"
        Spells = @("Power Strike")
        Description = "Strong melee fighter with high HP and defense"
        Symbol = "[W]"
        MapSymbol = "W"
    }
    "Mage" = @{
        BaseHP = 20; BaseMP = 15; BaseAttack = 4; BaseDefense = 3; BaseSpeed = 7
        HPGrowth = 2; MPGrowth = 3; AttackGrowth = 1; DefenseGrowth = 1; SpeedGrowth = 2
        StartingWeapon = "Oak Staff"; StartingArmor = "Cloth Robes"
        Spells = @("Fire", "Ice", "Magic Missile")
        Description = "Powerful spell caster with high MP"
        Symbol = "[M]"
        MapSymbol = "M"
    }
    "Healer" = @{
        BaseHP = 25; BaseMP = 12; BaseAttack = 5; BaseDefense = 4; BaseSpeed = 5
        HPGrowth = 2; MPGrowth = 2; AttackGrowth = 1; DefenseGrowth = 2; SpeedGrowth = 1
        StartingWeapon = "Blessed Mace"; StartingArmor = "Holy Vestments"
        Spells = @("Heal", "Cure", "Protect")
        Description = "Support specialist with healing magic"
        Symbol = "[H]"
        MapSymbol = "H"
    }
    "Rogue" = @{
        BaseHP = 28; BaseMP = 7; BaseAttack = 7; BaseDefense = 4; BaseSpeed = 9
        HPGrowth = 2; MPGrowth = 1; AttackGrowth = 2; DefenseGrowth = 1; SpeedGrowth = 2
        StartingWeapon = "Silver Dagger"; StartingArmor = "Leather Armor"
        Spells = @("Backstab", "Poison Strike")
        Description = "Fast attacker with critical hit potential"
        Symbol = "[R]"
        MapSymbol = "R"
    }
}

# =============================================================================
# PARTY MANAGEMENT FUNCTIONS
# =============================================================================

# =============================================================================
# SNAKE FOLLOWING SYSTEM FUNCTIONS  
# =============================================================================

# Initialize party positions for a new map
function Initialize-PartyPositions {
    param([int]$LeaderX, [int]$LeaderY, [array]$Party)
    
    # Clear the movement trail
    $global:PartyTrail = @()
    
    # Place party members in a line behind the leader initially
    for ($i = 0; $i -lt $Party.Count; $i++) {
        $member = $Party[$i]
        if ($i -eq 0) {
            # Leader starts at specified position
            $member.Position.X = $LeaderX
            $member.Position.Y = $LeaderY
        } else {
            # Other members start one space behind in a line
            $member.Position.X = $LeaderX
            $member.Position.Y = [math]::Max(0, $LeaderY - $i)
        }
    }
    
    # Add initial positions to trail
    $global:PartyTrail += @{ X = $LeaderX; Y = $LeaderY }
}

# Update party positions when leader moves (snake-following)
function Update-PartyPositions {
    param([int]$NewLeaderX, [int]$NewLeaderY, [array]$Party)
    
    if ($Party.Count -eq 0) { return }
    
    # Add new leader position to front of trail
    $global:PartyTrail = @(@{ X = $NewLeaderX; Y = $NewLeaderY }) + $global:PartyTrail
    
    # Trim trail to max length
    if ($global:PartyTrail.Count -gt $global:MaxTrailLength) {
        $global:PartyTrail = $global:PartyTrail[0..($global:MaxTrailLength-1)]
    }
    
    # Update party member positions from trail
    for ($i = 0; $i -lt $Party.Count; $i++) {
        $member = $Party[$i]
        if ($i -eq 0) {
            # Leader gets the new position
            $member.Position.X = $NewLeaderX
            $member.Position.Y = $NewLeaderY
        } elseif ($i -lt $global:PartyTrail.Count) {
            # Other members follow the trail with spacing
            $trailIndex = [math]::Min($i * 2, $global:PartyTrail.Count - 1)  # 2-space separation
            $trailPos = $global:PartyTrail[$trailIndex]
            $member.Position.X = $trailPos.X
            $member.Position.Y = $trailPos.Y
        }
    }
}

# Get party member positions for rendering
function Get-PartyPositions {
    param([array]$Party)
    
    $positions = @{}
    foreach ($member in $Party) {
        if ($member.Position) {
            $key = "$($member.Position.X),$($member.Position.Y)"
            $positions[$key] = @{
                Name = $member.Name
                Class = $member.Class
                Symbol = $member.MapSymbol
                IsLeader = ($Party.IndexOf($member) -eq 0)
            }
        }
    }
    return $positions
}

# Handle map transitions for entire party
function Move-PartyToMap {
    param([int]$NewX, [int]$NewY, [array]$Party, [string]$MapName)
    
    # Move leader to new position
    if ($Party.Count -gt 0) {
        $Party[0].Position.X = $NewX
        $Party[0].Position.Y = $NewY
    }
    
    # Initialize party positions on new map
    Initialize-PartyPositions $NewX $NewY $Party
    
    # Update save state if needed
    if ($global:SaveState) {
        $global:SaveState.Player.X = $NewX
        $global:SaveState.Player.Y = $NewY
        $global:SaveState.Player.CurrentMap = $MapName
    }
}

# =============================================================================
# ORIGINAL PARTY MANAGEMENT FUNCTIONS
# =============================================================================

# Create a party member from class template
function New-PartyMember {
    param(
        [string]$Name, 
        [string]$Class, 
        [int]$Level = 1
    )
    
    if (-not $CharacterClasses.ContainsKey($Class)) {
        throw "Unknown character class: $Class"
    }
    
    $classData = $CharacterClasses[$Class]
    
    return @{
        Name = $Name
        Class = $Class
        Level = $Level
        HP = $classData.BaseHP + ($classData.HPGrowth * ($Level - 1))
        MaxHP = $classData.BaseHP + ($classData.HPGrowth * ($Level - 1))
        MP = $classData.BaseMP + ($classData.MPGrowth * ($Level - 1))
        MaxMP = $classData.BaseMP + ($classData.MPGrowth * ($Level - 1))
        Attack = $classData.BaseAttack + ($classData.AttackGrowth * ($Level - 1))
        Defense = $classData.BaseDefense + ($classData.DefenseGrowth * ($Level - 1))
        Speed = $classData.BaseSpeed + ($classData.SpeedGrowth * ($Level - 1))
        XP = 0
        Spells = $classData.Spells.Clone()
        Inventory = @()
        Equipped = @{
            Weapon = $classData.StartingWeapon
            Armor = $classData.StartingArmor
            Accessory = $null
        }
        Symbol = $classData.Symbol
        MapSymbol = $classData.MapSymbol
        IsAlive = $true
        Position = @{ X = 0; Y = 0 }  # For snake-style following (Phase 2.2)
    }
}

# Create default starting party (for Phase 2.1 testing)
function New-DefaultParty {
    return @(
        (New-PartyMember "Gareth" "Warrior" 1),
        (New-PartyMember "Mystara" "Mage" 1),
        (New-PartyMember "Celeste" "Healer" 1),
        (New-PartyMember "Raven" "Rogue" 1)
    )
}

# Get party member by name
function Get-PartyMember {
    param([string]$Name, [array]$Party)
    
    return $Party | Where-Object { $_.Name -eq $Name }
}

# Get alive party members
function Get-AlivePartyMembers {
    param([array]$Party)
    
    return $Party | Where-Object { $_.IsAlive -eq $true }
}

# Check if party is defeated (all members dead)
function Test-PartyDefeated {
    param([array]$Party)
    
    $aliveMembers = Get-AlivePartyMembers $Party
    return $aliveMembers.Count -eq 0
}

# Display party status (for debugging and UI)
function Show-PartyStatus {
    param([array]$Party)
    
    Write-Host "`n=== PARTY STATUS ===" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Party.Count; $i++) {
        $member = $Party[$i]
        $status = if ($member.IsAlive) { "ALIVE" } else { "KO" }
        $statusColor = if ($member.IsAlive) { "Green" } else { "Red" }
        
        Write-Host "$($i+1). $($member.Name) [$($member.Class)]" -ForegroundColor White -NoNewline
        Write-Host " $($member.Symbol)" -NoNewline
        Write-Host " - $status" -ForegroundColor $statusColor
        Write-Host "   HP: $($member.HP)/$($member.MaxHP)  MP: $($member.MP)/$($member.MaxMP)  " -NoNewline
        Write-Host "ATK: $($member.Attack)  DEF: $($member.Defense)  SPD: $($member.Speed)" -ForegroundColor Gray
        Write-Host "   Equipment: $($member.Equipped.Weapon), $($member.Equipped.Armor)" -ForegroundColor DarkGray
    }
    Write-Host "===================" -ForegroundColor Cyan
}

# Level up a party member
function Invoke-PartyMemberLevelUp {
    param([hashtable]$Member)
    
    $classData = $CharacterClasses[$Member.Class]
    $Member.Level++
    
    # Apply stat growth
    $Member.MaxHP += $classData.HPGrowth
    $Member.HP += $classData.HPGrowth  # Full heal on level up
    $Member.MaxMP += $classData.MPGrowth
    $Member.MP += $classData.MPGrowth  # Full MP restore on level up
    $Member.Attack += $classData.AttackGrowth
    $Member.Defense += $classData.DefenseGrowth
    $Member.Speed += $classData.SpeedGrowth
    
    Write-Host "$($Member.Name) reached Level $($Member.Level)!" -ForegroundColor Yellow
    Write-Host "Stats increased! HP+$($classData.HPGrowth) MP+$($classData.MPGrowth) ATK+$($classData.AttackGrowth) DEF+$($classData.DefenseGrowth) SPD+$($classData.SpeedGrowth)" -ForegroundColor Green
}

# Distribute XP to party and handle level ups
function Add-PartyXP {
    param([array]$Party, [int]$XP)
    
    $aliveMembers = Get-AlivePartyMembers $Party
    if ($aliveMembers.Count -eq 0) { return }
    
    $xpPerMember = [math]::Floor($XP / $aliveMembers.Count)
    
    foreach ($member in $aliveMembers) {
        $member.XP += $xpPerMember
        
        # Check for level up (simple formula: 100 XP per level)
        $xpNeeded = $member.Level * 100
        while ($member.XP -ge $xpNeeded) {
            $member.XP -= $xpNeeded
            Invoke-PartyMemberLevelUp $member
            $xpNeeded = $member.Level * 100
        }
    }
    
    Write-Host "Party gained $xpPerMember XP each!" -ForegroundColor Cyan
}

# =============================================================================
# COMBAT INTEGRATION FUNCTIONS
# =============================================================================

# Create turn order including all party members and enemies
function New-PartyTurnOrder {
    param([array]$Party, [array]$Enemies)
    
    $combatants = @()
    
    # Add alive party members
    $aliveMembers = Get-AlivePartyMembers $Party
    foreach ($member in $aliveMembers) {
        $combatants += @{
            Name = $member.Name
            Speed = $member.Speed
            Type = "Party"
            Character = $member
        }
    }
    
    # Add alive enemies
    foreach ($enemy in $Enemies) {
        if ($enemy.HP -gt 0) {
            $combatants += @{
                Name = $enemy.Name
                Speed = $enemy.Speed
                Type = "Enemy" 
                Character = $enemy
            }
        }
    }
    
    # Sort by Speed (highest first), with random tiebreaker
    $turnOrder = $combatants | Sort-Object { $_.Speed + (Get-Random -Minimum 0.0 -Maximum 1.0) } -Descending
    
    return $turnOrder
}

# Display party turn order
function Show-PartyTurnOrder {
    param($TurnOrder, $CurrentTurnIndex)
    
    $orderText = "Turn Order: "
    for ($i = 0; $i -lt $TurnOrder.Count; $i++) {
        $combatant = $TurnOrder[$i]
        $prefix = if ($combatant.Type -eq "Party") { "[P]" } else { "[E]" }
        
        if ($i -eq $CurrentTurnIndex) {
            $orderText += "[$prefix$($combatant.Name)]"
        } else {
            $orderText += "$prefix$($combatant.Name)"
        }
        if ($i -lt $TurnOrder.Count - 1) {
            $orderText += " -> "
        }
    }
    
    Write-Host $orderText -ForegroundColor Cyan
}

# Display party combat status
function Show-PartyCombatStatus {
    param([array]$Party)
    
    Write-Host "`n=== PARTY STATUS ===" -ForegroundColor Green
    for ($i = 0; $i -lt $Party.Count; $i++) {
        $member = $Party[$i]
        if ($member.IsAlive) {
            $hpBar = Get-HPBar $member.HP $member.MaxHP 10
            $mpBar = Get-MPBar $member.MP $member.MaxMP 8
            Write-Host "$($i+1). $($member.Name) [$($member.Class)] $($member.Symbol)" -ForegroundColor White
            Write-Host "   HP: $hpBar $($member.HP)/$($member.MaxHP)" -ForegroundColor Green
            Write-Host "   MP: $mpBar $($member.MP)/$($member.MaxMP)" -ForegroundColor Blue
        } else {
            Write-Host "$($i+1). $($member.Name) [$($member.Class)] 💀 [KO]" -ForegroundColor Red
        }
    }
    Write-Host "===================" -ForegroundColor Green
}

# Helper function to create HP bar
function Get-HPBar {
    param([int]$Current, [int]$Max, [int]$Length = 10)
    
    $percentage = if ($Max -gt 0) { $Current / $Max } else { 0 }
    $filled = [math]::Floor($percentage * $Length)
    $empty = $Length - $filled
    
    return ("#" * $filled) + ("-" * $empty)
}

# Helper function to create MP bar  
function Get-MPBar {
    param([int]$Current, [int]$Max, [int]$Length = 8)
    
    $percentage = if ($Max -gt 0) { $Current / $Max } else { 0 }
    $filled = [math]::Floor($percentage * $Length)
    $empty = $Length - $filled
    
    return ("=" * $filled) + ("-" * $empty)
}

# =============================================================================
# SAVE SYSTEM INTEGRATION
# =============================================================================

# Convert party to save-friendly format
function ConvertTo-PartySaveData {
    param([array]$Party)
    
    $saveData = @()
    foreach ($member in $Party) {
        $saveData += @{
            Name = $member.Name
            Class = $member.Class
            Level = $member.Level
            HP = $member.HP
            MaxHP = $member.MaxHP
            MP = $member.MP
            MaxMP = $member.MaxMP
            Attack = $member.Attack
            Defense = $member.Defense
            Speed = $member.Speed
            XP = $member.XP
            Spells = $member.Spells
            Inventory = $member.Inventory
            Equipped = $member.Equipped
            IsAlive = $member.IsAlive
            Position = $member.Position
        }
    }
    
    return $saveData
}

# Restore party from save data
function ConvertFrom-PartySaveData {
    param([array]$SaveData)
    
    $party = @()
    foreach ($memberData in $SaveData) {
        $member = @{
            Name = $memberData.Name
            Class = $memberData.Class
            Level = $memberData.Level
            HP = $memberData.HP
            MaxHP = $memberData.MaxHP
            MP = $memberData.MP
            MaxMP = $memberData.MaxMP
            Attack = $memberData.Attack
            Defense = $memberData.Defense
            Speed = $memberData.Speed
            XP = if ($memberData.XP) { $memberData.XP } else { 0 }
            Spells = if ($memberData.Spells) { $memberData.Spells } else { @() }
            Inventory = if ($memberData.Inventory) { $memberData.Inventory } else { @() }
            Equipped = if ($memberData.Equipped) { $memberData.Equipped } else { @{} }
            IsAlive = if ($memberData.IsAlive -ne $null) { $memberData.IsAlive } else { $true }
            Position = if ($memberData.Position) { $memberData.Position } else { @{ X = 0; Y = 0 } }
            Symbol = $CharacterClasses[$memberData.Class].Symbol
            MapSymbol = $CharacterClasses[$memberData.Class].MapSymbol
        }
        
        $party += $member
    }
    
    return $party
}

# =============================================================================
# PARTY INITIALIZATION
# =============================================================================

# Global party variable (will be initialized by Display.ps1)
$global:Party = $null

Write-Host "Party System loaded! Character classes: Warrior, Mage, Healer, Rogue" -ForegroundColor Green
