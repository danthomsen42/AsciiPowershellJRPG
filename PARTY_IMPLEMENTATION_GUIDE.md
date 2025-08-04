# =============================================================================
# PHASE 2.1 MULTIPLE PARTY MEMBERS - IMPLEMENTATION GUIDE
# =============================================================================

## STRATEGIC APPROACH

This implementation builds the party system foundation that will integrate 
seamlessly with Phase 5 (Character Creation). We're building smart:

1. **Foundation Now** (Phase 2.1): Core party mechanics, default party
2. **Interface Later** (Phase 5.3): Character creation UI on top of foundation

## IMPLEMENTATION STEPS

### STEP 1: CHARACTER CLASS SYSTEM
Create class definitions that Phase 5 will use for character creation.

**File: PartySystem.ps1**
```powershell
# Character Classes with balanced stats
$CharacterClasses = @{
    "Warrior" = @{
        BaseHP = 35; BaseMP = 5; BaseAttack = 8; BaseDefense = 6; BaseSpeed = 6
        HPGrowth = 3; MPGrowth = 1; AttackGrowth = 2; DefenseGrowth = 2; SpeedGrowth = 1
        StartingWeapon = "Iron Sword"; StartingArmor = "Chain Mail"
        Spells = @("Power Strike")
        Description = "Strong melee fighter with high HP and defense"
        Symbol = "⚔️"
    }
    "Mage" = @{
        BaseHP = 20; BaseMP = 15; BaseAttack = 4; BaseDefense = 3; BaseSpeed = 7
        HPGrowth = 2; MPGrowth = 3; AttackGrowth = 1; DefenseGrowth = 1; SpeedGrowth = 2
        StartingWeapon = "Oak Staff"; StartingArmor = "Cloth Robes"
        Spells = @("Fire", "Ice", "Magic Missile")
        Description = "Powerful spell caster with high MP"
        Symbol = "🔮"
    }
    "Healer" = @{
        BaseHP = 25; BaseMP = 12; BaseAttack = 5; BaseDefense = 4; BaseSpeed = 5
        HPGrowth = 2; MPGrowth = 2; AttackGrowth = 1; DefenseGrowth = 2; SpeedGrowth = 1
        StartingWeapon = "Blessed Mace"; StartingArmor = "Holy Vestments"
        Spells = @("Heal", "Cure", "Protect")
        Description = "Support specialist with healing magic"
        Symbol = "✨"
    }
    "Rogue" = @{
        BaseHP = 28; BaseMP = 7; BaseAttack = 7; BaseDefense = 4; BaseSpeed = 9
        HPGrowth = 2; MPGrowth = 1; AttackGrowth = 2; DefenseGrowth = 1; SpeedGrowth = 2
        StartingWeapon = "Silver Dagger"; StartingArmor = "Leather Armor"
        Spells = @("Backstab", "Poison Strike")
        Description = "Fast attacker with critical hit potential"
        Symbol = "🗡️"
    }
}
```

### STEP 2: PARTY MANAGEMENT FUNCTIONS
```powershell
# Create a party member from class template
function New-PartyMember {
    param([string]$Name, [string]$Class, [int]$Level = 1)
    
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
        IsAlive = $true
    }
}

# Default starting party (for Phase 2.1 testing)
function New-DefaultParty {
    return @(
        (New-PartyMember "Gareth" "Warrior" 1),
        (New-PartyMember "Mystara" "Mage" 1),
        (New-PartyMember "Celeste" "Healer" 1),
        (New-PartyMember "Raven" "Rogue" 1)
    )
}
```

### STEP 3: SAVE SYSTEM INTEGRATION
Extend the existing save system to handle party data:

**Modify Display.ps1 save structure:**
```powershell
# Add to $SaveState structure:
Party = @{
    Members = @()  # Array of party member objects
    Formation = "Diamond"  # Battle formation
    Leader = 0  # Index of party leader
}
```

### STEP 4: COMBAT SYSTEM ADAPTATION
**Key Changes to Battle System:**

1. **Turn Order**: Include all party members + enemies
2. **Target Selection**: Player chooses targets for attacks/spells
3. **Party HP Display**: Show all party member status
4. **Victory Conditions**: Battle ends when all enemies OR all party members defeated

**Combat Flow:**
```
Turn Order: [Raven] → Gareth → Enemy1 → Mystara → Celeste → Enemy2
> Raven's Turn: [A]ttack [S]pells [I]tems [D]efend
> Target: Enemy1 | Enemy2
```

### STEP 5: INTEGRATION POINTS

**Files to Modify:**

1. **Display.ps1**:
   - Load PartySystem.ps1
   - Replace single $Player with $Party array
   - Update combat loops for multiple characters
   - Modify save/load for party data

2. **Player.ps1**:
   - Keep as template/legacy reference
   - May become character creation defaults

3. **New: PartySystem.ps1**:
   - All party management functions
   - Character class definitions
   - Party formation logic

## MIGRATION STRATEGY

### Phase 2.1: Foundation
```powershell
# Current single player
$Player = @{ Name="Hero", Class="Warrior", ... }

# Becomes party system
$Party = @(
    @{ Name="Gareth", Class="Warrior", ... },
    @{ Name="Mystara", Class="Mage", ... },
    @{ Name="Celeste", Class="Healer", ... },
    @{ Name="Raven", Class="Rogue", ... }
)
```

### Phase 5.3: Character Creation
```powershell
# Replace New-DefaultParty() with:
$Party = New-PartyFromCreation($UserChoices)
```

## TESTING APPROACH

1. **Start with 2-character party** (easier to test)
2. **Gradually add complexity** (3rd, 4th members)
3. **Test combat thoroughly** before adding overworld features
4. **Ensure save/load works** with party data

## PHASE 5 INTEGRATION PREVIEW

The character creation system will simply call our foundation:

```powershell
# Phase 5.3 Character Creation will do:
$selectedClasses = Get-PlayerClassChoices()  # UI for class selection
$selectedNames = Get-PlayerNameChoices()     # UI for naming
$Party = @()
for ($i = 0; $i -lt $selectedClasses.Count; $i++) {
    $Party += New-PartyMember $selectedNames[$i] $selectedClasses[$i]
}
```

**Perfect integration!** No rework needed - just different initialization method.

## IMMEDIATE BENEFITS

✅ **Rich Combat**: 4-character parties vs enemies immediately  
✅ **Class Diversity**: Different roles and strategies  
✅ **Balanced Gameplay**: Tank, DPS, Healer, Support roles  
✅ **Foundation Ready**: Perfect setup for Phase 5 character creation  
✅ **Testing Platform**: Full party mechanics available for debugging  

## RECOMMENDED IMPLEMENTATION ORDER

1. **Day 1-2**: Create PartySystem.ps1 with class definitions
2. **Day 3-4**: Modify combat system for multiple party members
3. **Day 5-6**: Update save system for party data
4. **Day 7**: Testing and balancing

**This approach gives us:**
- Immediate multi-character gameplay
- Solid foundation for Phase 5
- No throwaway code
- Complete testing of party mechanics

Ready to start building the party system foundation!
