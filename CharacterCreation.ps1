# =============================================================================
# CHARACTER CREATION SYSTEM - PHASE 5.3
# =============================================================================
# Final Fantasy 1 style party creation with class selection and naming
# Integrates with existing PartySystem.ps1 and Player.ps1

# Import required systems
if (Test-Path "$PSScriptRoot\PartySystem.ps1") {
    . "$PSScriptRoot\PartySystem.ps1"
}
if (Test-Path "$PSScriptRoot\CharacterCustomization.ps1") {
    . "$PSScriptRoot\CharacterCustomization.ps1"
}

# =============================================================================
# NAME GENERATION SYSTEM - Enhanced Gender Diversity
# =============================================================================

$FantasyNames = @{
    "Warrior" = @("Gareth", "Thane", "Kael", "Roderick", "Magnus", "Aldric", "Baelor", "Corin", "Drake", "Ewan", 
                  "Aria", "Valeria", "Brianna", "Cassandra", "Diana", "Freya", "Gabrielle", "Helena", "Isabella", "Jasmine")
    "Mage" = @("Lysander", "Elias", "Casper", "Magnus", "Theron", "Zara", "Celeste", "Luna", "Iris", "Nova",
               "Morgana", "Seraphina", "Evangeline", "Cordelia", "Beatrice", "Ophelia", "Penelope", "Rosalind", "Vivienne", "Zelda")
    "Healer" = @("Seraphina", "Grace", "Hope", "Faith", "Mercy", "Celeste", "Aurora", "Dawn", "Harmony", "Peace",
                 "Gabriel", "Michael", "Raphael", "Samuel", "Benjamin", "Nathaniel", "Theodore", "Sebastian", "Alexander", "Christopher")
    "Rogue" = @("Shadow", "Raven", "Whisper", "Blade", "Swift", "Dash", "Stealth", "Vex", "Zara", "Quinn",
               "Scarlett", "Raven", "Phoenix", "Storm", "Jade", "Onyx", "Ember", "Frost", "Sage", "Ivy")
}

$MaleNames = @("Aiden", "Blake", "Cade", "Derek", "Ethan", "Felix", "Gavin", "Hunter", "Ivan", "Jaxon", "Kane", "Liam", "Mason", "Noah", "Owen", "Pierce", "Quinn", "Reid", "Seth", "Trent")
$FemaleNames = @("Aria", "Belle", "Cora", "Dara", "Eva", "Faye", "Grace", "Hope", "Ivy", "Jade", "Kate", "Luna", "Maya", "Nina", "Olive", "Page", "Quinn", "Rose", "Sage", "Tess")
$UnisexNames = @("Alex", "Casey", "Drew", "Emery", "Finley", "Gray", "Harper", "Indigo", "Jordan", "Kai", "Logan", "Morgan", "Nova", "Onyx", "Parker", "Quinn", "River", "Sage", "Taylor", "Winter")

# =============================================================================
# CHARACTER COLOR SYSTEM  
# =============================================================================

$CharacterColors = @{
    "Red" = @{ Name = "Red"; Code = "Red"; Symbol = "R" }
    "Blue" = @{ Name = "Blue"; Code = "Blue"; Symbol = "B" }
    "Green" = @{ Name = "Green"; Code = "Green"; Symbol = "G" }
    "Yellow" = @{ Name = "Yellow"; Code = "Yellow"; Symbol = "Y" }
    "Magenta" = @{ Name = "Magenta"; Code = "Magenta"; Symbol = "M" }
    "Cyan" = @{ Name = "Cyan"; Code = "Cyan"; Symbol = "C" }
    "White" = @{ Name = "White"; Code = "White"; Symbol = "W" }
    "Gray" = @{ Name = "Gray"; Code = "Gray"; Symbol = "G" }
}

$DefaultColors = @("Red", "Blue", "Green", "Yellow", "Magenta", "Cyan", "White")

function Get-RandomCharacterColor {
    return $DefaultColors | Get-Random
}

# =============================================================================
# STAT ROLLING SYSTEM
# =============================================================================

function Get-ClassStatRanges {
    param([string]$Class)
    
    $statRanges = @{
        "Warrior" = @{
            HP = @(32, 38); MP = @(3, 7); Attack = @(6, 10); Defense = @(5, 7); Speed = @(4, 8)
        }
        "Mage" = @{
            HP = @(16, 24); MP = @(12, 18); Attack = @(2, 6); Defense = @(2, 4); Speed = @(5, 9)
        }
        "Healer" = @{
            HP = @(22, 28); MP = @(10, 15); Attack = @(3, 7); Defense = @(3, 5); Speed = @(4, 6)
        }
        "Rogue" = @{
            HP = @(24, 32); MP = @(5, 9); Attack = @(5, 9); Defense = @(3, 5); Speed = @(7, 11)
        }
    }
    
    return $statRanges[$Class]
}

function New-CharacterWithRolledStats {
    param(
        [string]$Name,
        [string]$Class,
        [int]$Position = 1,
        [string]$Color = ""
    )
    
    if (-not $CharacterClasses.ContainsKey($Class)) {
        Write-Error "Invalid class: $Class"
        return $null
    }
    
    # Assign random color if not specified
    if (-not $Color) {
        $Color = Get-RandomCharacterColor
    }
    
    $classData = $CharacterClasses[$Class]
    $statRanges = Get-ClassStatRanges -Class $Class
    
    # Roll stats within class ranges
    $rolledHP = Get-Random -Minimum $statRanges.HP[0] -Maximum ($statRanges.HP[1] + 1)
    $rolledMP = Get-Random -Minimum $statRanges.MP[0] -Maximum ($statRanges.MP[1] + 1)
    $rolledAttack = Get-Random -Minimum $statRanges.Attack[0] -Maximum ($statRanges.Attack[1] + 1)
    $rolledDefense = Get-Random -Minimum $statRanges.Defense[0] -Maximum ($statRanges.Defense[1] + 1)
    $rolledSpeed = Get-Random -Minimum $statRanges.Speed[0] -Maximum ($statRanges.Speed[1] + 1)
    
    # Apply stat balancing - if one stat is high, others should be slightly lower
    $totalStats = $rolledHP + $rolledMP + $rolledAttack + $rolledDefense + $rolledSpeed
    $baseTotal = ($statRanges.HP[0] + $statRanges.HP[1])/2 + ($statRanges.MP[0] + $statRanges.MP[1])/2 + 
                 ($statRanges.Attack[0] + $statRanges.Attack[1])/2 + ($statRanges.Defense[0] + $statRanges.Defense[1])/2 + 
                 ($statRanges.Speed[0] + $statRanges.Speed[1])/2
    
    # If rolled stats are too high, adjust slightly downward
    if ($totalStats -gt ($baseTotal * 1.1)) {
        $adjustment = [Math]::Floor(($totalStats - $baseTotal * 1.1) / 5)
        $rolledHP = [Math]::Max($statRanges.HP[0], $rolledHP - $adjustment)
        $rolledAttack = [Math]::Max($statRanges.Attack[0], $rolledAttack - $adjustment)
    }
    
    return @{
        Name        = $Name
        Class       = $Class
        Level       = 1
        Position    = @{ X = 40; Y = 12 }  # Proper position object with coordinates
        Color       = $Color
        MaxHP       = $rolledHP
        HP          = $rolledHP
        MaxMP       = $rolledMP
        MP          = $rolledMP
        Attack      = $rolledAttack
        Defense     = $rolledDefense
        Speed       = $rolledSpeed
        XP          = 0
        NextLevelXP = 100  # XP needed for level 2 (will be updated by level system)
        Spells      = $classData.Spells.Clone()
        Inventory   = @()
        Equipped    = @{
            Weapon    = $classData.StartingWeapon
            Armor     = $classData.StartingArmor
            Accessory = $null
        }
        ClassData   = $classData
        MapSymbol   = $classData.MapSymbol
        StatRolls   = 0  # Track number of rerolls
    }
}

function Get-RandomName {
    param(
        [string]$Class = "",
        [string]$Type = "Any"  # "Male", "Female", "Unisex", "Any", or "Class"
    )
    
    $namePool = @()
    
    switch ($Type) {
        "Male" { $namePool = $MaleNames }
        "Female" { $namePool = $FemaleNames }
        "Unisex" { $namePool = $UnisexNames }
        "Class" { 
            if ($Class -and $FantasyNames.ContainsKey($Class)) {
                $namePool = $FantasyNames[$Class]
            }
            else {
                $namePool = $UnisexNames
            }
        }
        "Any" { 
            $namePool = $MaleNames + $FemaleNames + $UnisexNames
            if ($Class -and $FantasyNames.ContainsKey($Class)) {
                $namePool += $FantasyNames[$Class]
            }
        }
    }
    
    if ($namePool.Count -gt 0) {
        return $namePool[(Get-Random -Maximum $namePool.Count)]
    }
    return "Hero"
}

function New-Character {
    param(
        [string]$Name,
        [string]$Class,
        [int]$Position = 1,  # 1-4 for party position
        [string]$Color = ""  # Character color for display
    )
    
    if (-not $CharacterClasses.ContainsKey($Class)) {
        Write-Error "Invalid class: $Class"
        return $null
    }
    
    # Assign random color if not specified
    if (-not $Color) {
        $Color = Get-RandomCharacterColor
    }
    
    $classData = $CharacterClasses[$Class]
    
    return @{
        Name        = $Name
        Class       = $Class
        Level       = 1
        Position    = @{ X = 40; Y = 12 }  # Proper position object with coordinates
        Color       = $Color
        MaxHP       = $classData.BaseHP
        HP          = $classData.BaseHP
        MaxMP       = $classData.BaseMP
        MP          = $classData.BaseMP
        Attack      = $classData.BaseAttack
        Defense     = $classData.BaseDefense
        Speed       = $classData.BaseSpeed
        XP          = 0
        NextLevelXP = 100  # XP needed for level 2 (will be updated by level system)
        Spells      = $classData.Spells.Clone()
        Inventory   = @()
        Equipped    = @{
            Weapon    = $classData.StartingWeapon
            Armor     = $classData.StartingArmor
            Accessory = $null
        }
        ClassData   = $classData
        MapSymbol   = $classData.MapSymbol  # Ensure MapSymbol is set
    }
}

function Show-ClassSelection {
    param([int]$CurrentSelection = 0)
    
    Clear-Host
    
    # Title
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                           CHARACTER CREATION" -ForegroundColor Cyan
    Write-Host "                          Choose Your Classes" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $classes = @("Warrior", "Mage", "Healer", "Rogue")
    
    Write-Host "                            SELECT A CLASS:" -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 0; $i -lt $classes.Count; $i++) {
        $class = $classes[$i]
        $classData = $CharacterClasses[$class]
        
        $prefix = if ($i -eq $CurrentSelection) { "  > " } else { "    " }
        $color = if ($i -eq $CurrentSelection) { "White" } else { "Gray" }
        $highlight = if ($i -eq $CurrentSelection) { "[$class]" } else { " $class " }
        
        Write-Host ("              {0}{1}" -f $prefix, $highlight) -ForegroundColor $color
        
        # Show class details for selected class
        if ($i -eq $CurrentSelection) {
            Write-Host "                  $($classData.Description)" -ForegroundColor DarkCyan
            Write-Host ("                  HP:{0} MP:{1} ATK:{2} DEF:{3} SPD:{4}" -f 
                $classData.BaseHP, $classData.BaseMP, $classData.BaseAttack, 
                $classData.BaseDefense, $classData.BaseSpeed) -ForegroundColor DarkGray
            Write-Host "                  Starting: $($classData.StartingWeapon), $($classData.StartingArmor)" -ForegroundColor DarkGray
            Write-Host ""
        }
    }
    
    Write-Host "                    Use Up/Down to browse, ENTER to select" -ForegroundColor DarkGray
    
    return $classes[$CurrentSelection]
}

function Get-PlayerInput {
    param(
        [string]$Prompt = "Enter name",
        [string]$DefaultValue = "",
        [int]$MaxLength = 12
    )
    
    Write-Host ""
    Write-Host "    $Prompt" -ForegroundColor Yellow
    if ($DefaultValue) {
        Write-Host "    (Press ENTER for '$DefaultValue' or type a new name)" -ForegroundColor DarkGray
    }
    Write-Host "    > " -NoNewline -ForegroundColor White
    
    $userInput = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($userInput) -and $DefaultValue) {
        return $DefaultValue
    }
    
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        return "Hero"
    }
    
    # Limit length and clean input
    $cleanInput = $userInput.Trim().Substring(0, [Math]::Min($userInput.Length, $MaxLength))
    
    # Capitalize first letter
    if ($cleanInput.Length -gt 0) {
        $cleanInput = $cleanInput.Substring(0,1).ToUpper() + $cleanInput.Substring(1).ToLower()
    }
    
    return $cleanInput
}

function Show-CharacterPreview {
    param([array]$Characters)
    
    Clear-Host
    
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                           YOUR PARTY PREVIEW" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $totalHP = 0
    $totalMP = 0
    $totalAttack = 0
    $totalDefense = 0
    $avgSpeed = 0
    
    for ($i = 0; $i -lt $Characters.Count; $i++) {
        $char = $Characters[$i]
        $pos = $i + 1
        
        Write-Host ("  Position {0}: {1} the {2}" -f $pos, $char.Name, $char.Class) -ForegroundColor White
        Write-Host ("             HP: {0,-3} MP: {1,-3} ATK: {2,-3} DEF: {3,-3} SPD: {4}" -f 
            $char.MaxHP, $char.MaxMP, $char.Attack, $char.Defense, $char.Speed) -ForegroundColor Gray
        Write-Host ("             Equipment: {0}, {1}" -f $char.Equipped.Weapon, $char.Equipped.Armor) -ForegroundColor DarkGray
        Write-Host ""
        
        $totalHP += $char.MaxHP
        $totalMP += $char.MaxMP
        $totalAttack += $char.Attack
        $totalDefense += $char.Defense
        $avgSpeed += $char.Speed
    }
    
    $avgSpeed = [Math]::Round($avgSpeed / $Characters.Count, 1)
    
    Write-Host "  PARTY TOTALS:" -ForegroundColor Yellow
    Write-Host ("    Total HP: {0}    Total MP: {1}" -f $totalHP, $totalMP) -ForegroundColor Green
    Write-Host ("    Total ATK: {0}   Total DEF: {1}   Average SPD: {2}" -f $totalAttack, $totalDefense, $avgSpeed) -ForegroundColor Green
    Write-Host ""
    Write-Host "  PARTY FORMATION:" -ForegroundColor Yellow
    Write-Host ("    {0}(Leader) -> {1} -> {2} -> {3}" -f 
        $Characters[0].ClassData.MapSymbol,
        $Characters[1].ClassData.MapSymbol,
        $Characters[2].ClassData.MapSymbol,
        $Characters[3].ClassData.MapSymbol) -ForegroundColor Cyan
    Write-Host ""
}

function Start-CharacterCreation {
    Clear-Host
    
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                    WELCOME TO CHARACTER CREATION!" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Create your party of 4 adventurers!" -ForegroundColor White
    Write-Host "  Choose any combination of classes for strategic variety:" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    * WARRIOR - Tank with high HP and defense" -ForegroundColor Red
    Write-Host "    * MAGE    - Powerful spells but fragile" -ForegroundColor Blue
    Write-Host "    * HEALER  - Essential support and healing" -ForegroundColor Green
    Write-Host "    * ROGUE   - Fast attacker with stealth" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  You can create any party composition you want!" -ForegroundColor DarkCyan
    Write-Host "  (4 Warriors, 2 Mages + 2 Healers, all different classes, etc.)" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Press any key to begin..." -ForegroundColor DarkGray
    [Console]::ReadKey($true) | Out-Null
    
    $party = @()
    $partyStatus = @("EMPTY", "EMPTY", "EMPTY", "EMPTY")  # Track completion status
    
    # Create 4 party members with full customization
    for ($position = 1; $position -le 4; $position++) {
        $character = Create-SingleCharacter -Position $position -PartyStatus $partyStatus
        
        if ($character) {
            if ($party.Count -ge ($position - 1)) {
                if ($party.Count -eq ($position - 1)) {
                    $party += $character
                } else {
                    $party[$position - 1] = $character
                }
            } else {
                $party += $character
            }
            $partyStatus[$position - 1] = "$($character.Name) ($($character.Class))"
        } else {
            # Auto-generate if skipped
            $randomClass = @("Warrior", "Mage", "Healer", "Rogue")[(Get-Random -Maximum 4)]
            $randomName = Get-RandomName -Class $randomClass -Type "Any"
            $character = New-CharacterWithRolledStats -Name $randomName -Class $randomClass -Position $position
            if ($party.Count -ge ($position - 1)) {
                if ($party.Count -eq ($position - 1)) {
                    $party += $character
                } else {
                    $party[$position - 1] = $character
                }
            } else {
                $party += $character
            }
            $partyStatus[$position - 1] = "$($character.Name) ($($character.Class)) [AUTO]"
        }
    }
    
    # Show final preview and confirmation
    do {
        $confirmed = Show-FinalPartyPreview -Characters $party -AllowEdit $true
        if ($confirmed -eq "EDIT") {
            # Allow editing any character
            $editChoice = Show-EditCharacterMenu -Characters $party
            if ($editChoice -ge 0 -and $editChoice -lt 4) {
                $newCharacter = Create-SingleCharacter -Position ($editChoice + 1) -PartyStatus $partyStatus -EditMode $true
                if ($newCharacter) {
                    $party[$editChoice] = $newCharacter
                    $partyStatus[$editChoice] = "$($newCharacter.Name) ($($newCharacter.Class))"
                }
            }
        } elseif ($confirmed -eq "YES") {
            return $party
        } elseif ($confirmed -eq "RESTART") {
            return Start-CharacterCreation  # Restart entirely
        }
    } while ($true)
}

function Create-SingleCharacter {
    param(
        [int]$Position,
        [array]$PartyStatus,
        [bool]$EditMode = $false
    )
    
    $currentSelection = 0
    $selectedClass = ""
    $characterName = ""
    $currentCharacter = $null
    $stage = "CLASS"  # CLASS -> NAME -> STATS -> CONFIRM
    
    do {
        switch ($stage) {
            "CLASS" {
                $selectedClass = Show-ClassSelectionWithStatus -CurrentSelection $currentSelection -Position $Position -PartyStatus $PartyStatus -EditMode $EditMode
                
                $key = [Console]::ReadKey($true)
                switch ($key.Key) {
                    "UpArrow" { 
                        $currentSelection = ($currentSelection - 1 + 4) % 4
                    }
                    "DownArrow" { 
                        $currentSelection = ($currentSelection + 1) % 4
                    }
                    "Enter" { 
                        $stage = "NAME"
                    }
                    "Escape" {
                        if ($EditMode) {
                            return $null  # Cancel edit
                        } elseif ($Position -gt 1) {
                            return $null  # Go back (handled by main function)
                        }
                    }
                }
            }
            
            "NAME" {
                $characterName = Get-CharacterNameInput -Class $selectedClass -Position $Position -PartyStatus $PartyStatus
                if ($characterName) {
                    $stage = "STATS"
                } else {
                    $stage = "CLASS"  # Go back
                }
            }
            
            "STATS" {
                $result = Show-StatRollingInterface -Name $characterName -Class $selectedClass -Position $Position -PartyStatus $PartyStatus
                if ($result -eq "BACK") {
                    $stage = "NAME"
                } elseif ($result) {
                    $currentCharacter = $result
                    $stage = "CONFIRM"
                } else {
                    $stage = "NAME"
                }
            }
            
            "CONFIRM" {
                $confirmation = Show-CharacterConfirmation -Character $currentCharacter -Position $Position -PartyStatus $PartyStatus
                if ($confirmation -eq "YES") {
                    return $currentCharacter
                } elseif ($confirmation -eq "EDIT_STATS") {
                    $stage = "STATS"
                } elseif ($confirmation -eq "EDIT_NAME") {
                    $stage = "NAME"
                } elseif ($confirmation -eq "EDIT_CLASS") {
                    $stage = "CLASS"
                } elseif ($confirmation -eq "EDIT_COLOR") {
                    # Color selection
                    $newColor = Get-ColorSelection $currentCharacter.Name $currentCharacter.Class
                    $currentCharacter.Color = $newColor
                    $stage = "CONFIRM"  # Stay on confirm screen to see the change
                } else {
                    $stage = "STATS"  # Default back to stats
                }
            }
        }
    } while ($true)
}

function Initialize-PartyFromCreation {
    param([array]$CreatedParty)
    
    if (-not $CreatedParty -or $CreatedParty.Count -eq 0) {
        Write-Error "No party provided for initialization"
        return
    }
    
    # Set up the main player as the party leader (this overwrites Player.ps1)
    $global:Player = @{
        Name        = $CreatedParty[0].Name
        Class       = $CreatedParty[0].Class
        Level       = $CreatedParty[0].Level
        MaxHP       = $CreatedParty[0].MaxHP
        HP          = $CreatedParty[0].HP
        Attack      = $CreatedParty[0].Attack
        Defense     = $CreatedParty[0].Defense
        Speed       = $CreatedParty[0].Speed
        MP          = $CreatedParty[0].MP
        MaxMP       = $CreatedParty[0].MaxMP
        XP          = $CreatedParty[0].XP
        Spells      = $CreatedParty[0].Spells
        Inventory   = $CreatedParty[0].Inventory
        Equipped    = $CreatedParty[0].Equipped
        Position    = @{ X = 40; Y = 12 }  # Default starting position
    }
    
    # Initialize the full party system (using both variable names for compatibility)
    $global:PartyMembers = $CreatedParty
    $global:Party = $CreatedParty  # ViewportRenderer uses this variable
    
    # Set up proper party positioning with trail spacing
    $startX = 40
    $startY = 12
    
    # Initialize the party trail with spaced positions (snake formation)
    $global:PartyTrail = @()
    for ($i = 0; $i -lt $CreatedParty.Count * 2; $i++) {
        # Create a trail going backwards (left) from starting position
        $global:PartyTrail += @{ X = $startX - $i; Y = $startY }
    }
    
    # Position party members using the trail system
    for ($i = 0; $i -lt $CreatedParty.Count; $i++) {
        $member = $CreatedParty[$i]
        if ($i -eq 0) {
            # Leader at starting position
            $member.Position = @{ X = $startX; Y = $startY }
        } else {
            # Other members follow trail with 2-space separation
            $trailIndex = [math]::Min($i * 2, $global:PartyTrail.Count - 1)
            $trailPos = $global:PartyTrail[$trailIndex]
            $member.Position = @{ X = $trailPos.X; Y = $trailPos.Y }
        }
        
        # Ensure MapSymbol is set from ClassData
        if ($member.ClassData -and $member.ClassData.MapSymbol) {
            $member.MapSymbol = $member.ClassData.MapSymbol
        }
    }
    
    # Ensure party formation symbols are set
    $global:PartyFormation = @()
    for ($i = 0; $i -lt $CreatedParty.Count; $i++) {
        $symbol = if ($i -eq 0) { "@" } else { $CreatedParty[$i].MapSymbol }
        $global:PartyFormation += $symbol
    }
    
    Write-Host ""
    Write-Host "Party initialized successfully!" -ForegroundColor Green
    Write-Host "Leader: $($global:Player.Name) the $($global:Player.Class) @ ($startX,$startY)" -ForegroundColor Yellow
    
    for ($i = 1; $i -lt $CreatedParty.Count; $i++) {
        $member = $CreatedParty[$i]
        Write-Host "Member $($i + 1): $($member.Name) the $($member.Class) [$($member.MapSymbol)] @ ($($member.Position.X),$($member.Position.Y))" -ForegroundColor Yellow
    }
    
    Write-Host "Party formation: $($global:PartyFormation -join ' -> ')" -ForegroundColor Cyan
    Start-Sleep -Milliseconds 2000
}

# =============================================================================
# QUICK START FUNCTIONS
# =============================================================================

function New-DefaultParty {
    # Create a balanced default party for quick testing
    $party = @()
    $party += New-Character -Name "Hero" -Class "Warrior" -Position 1
    $party += New-Character -Name "Sage" -Class "Mage" -Position 2  
    $party += New-Character -Name "Grace" -Class "Healer" -Position 3
    $party += New-Character -Name "Shadow" -Class "Rogue" -Position 4
    
    return $party
}

function New-RandomParty {
    # Create a randomized party
    $classes = @("Warrior", "Mage", "Healer", "Rogue")
    $party = @()
    
    for ($i = 0; $i -lt 4; $i++) {
        $class = $classes[$i]  # One of each class
        $name = Get-RandomName -Class $class -Type "Any"
        $party += New-Character -Name $name -Class $class -Position ($i + 1)
    }
    
    return $party
}

# =============================================================================
# ENHANCED CHARACTER CREATION FUNCTIONS
# =============================================================================

function Show-ClassSelectionWithStatus {
    param(
        [int]$CurrentSelection = 0,
        [int]$Position,
        [array]$PartyStatus,
        [bool]$EditMode = $false
    )
    
    Clear-Host
    
    $title = if ($EditMode) { "EDIT CHARACTER $Position" } else { "CHARACTER $Position CREATION" }
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                           $title" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Show party status
    Write-Host "  PARTY STATUS:" -ForegroundColor Yellow
    for ($i = 0; $i -lt 4; $i++) {
        $status = $PartyStatus[$i]
        $prefix = if (($i + 1) -eq $Position) { "  >> " } else { "     " }
        $color = if (($i + 1) -eq $Position) { "White" } else { 
            if ($status -eq "EMPTY") { "DarkGray" } else { "Green" }
        }
        Write-Host "$prefix Position $($i + 1): $status" -ForegroundColor $color
    }
    Write-Host ""
    
    $classes = @("Warrior", "Mage", "Healer", "Rogue")
    
    Write-Host "                            SELECT CLASS:" -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 0; $i -lt $classes.Count; $i++) {
        $class = $classes[$i]
        $classData = $CharacterClasses[$class]
        $statRanges = Get-ClassStatRanges -Class $class
        
        $prefix = if ($i -eq $CurrentSelection) { "  > " } else { "    " }
        $color = if ($i -eq $CurrentSelection) { "White" } else { "Gray" }
        $highlight = if ($i -eq $CurrentSelection) { "[$class]" } else { " $class " }
        
        Write-Host ("              {0}{1}" -f $prefix, $highlight) -ForegroundColor $color
        
        # Show class details for selected class
        if ($i -eq $CurrentSelection) {
            Write-Host "                  $($classData.Description)" -ForegroundColor DarkCyan
            Write-Host ("                  HP: {0}-{1}  MP: {2}-{3}  ATK: {4}-{5}  DEF: {6}-{7}  SPD: {8}-{9}" -f 
                $statRanges.HP[0], $statRanges.HP[1], $statRanges.MP[0], $statRanges.MP[1],
                $statRanges.Attack[0], $statRanges.Attack[1], $statRanges.Defense[0], $statRanges.Defense[1],
                $statRanges.Speed[0], $statRanges.Speed[1]) -ForegroundColor DarkGray
            Write-Host "                  Equipment: $($classData.StartingWeapon), $($classData.StartingArmor)" -ForegroundColor DarkGray
            Write-Host ""
        }
    }
    
    Write-Host "                    Use Up/Down to browse, ENTER to select" -ForegroundColor DarkGray
    if ($EditMode -or $Position -gt 1) {
        Write-Host "                    ESC to cancel/go back" -ForegroundColor DarkGray
    }
    
    return $classes[$CurrentSelection]
}

function Get-CharacterNameInput {
    param(
        [string]$Class,
        [int]$Position,
        [array]$PartyStatus
    )
    
    Clear-Host
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                     CHARACTER $Position - $Class" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Show party status
    Write-Host "  PARTY STATUS:" -ForegroundColor Yellow
    for ($i = 0; $i -lt 4; $i++) {
        $status = $PartyStatus[$i]
        $prefix = if (($i + 1) -eq $Position) { "  >> " } else { "     " }
        $color = if (($i + 1) -eq $Position) { "White" } else { 
            if ($status -eq "EMPTY") { "DarkGray" } else { "Green" }
        }
        Write-Host "$prefix Position $($i + 1): $status" -ForegroundColor $color
    }
    Write-Host ""
    
    $suggestedName = Get-RandomName -Class $Class -Type "Class"
    $characterName = Get-PlayerInput -Prompt "Enter name for your $Class" -DefaultValue $suggestedName
    
    return $characterName
}

function Show-StatRollingInterface {
    param(
        [string]$Name,
        [string]$Class,
        [int]$Position,
        [array]$PartyStatus
    )
    
    $character = New-CharacterWithRolledStats -Name $Name -Class $Class -Position $Position
    $rerollCount = 0
    $maxRerolls = 5
    
    do {
        Clear-Host
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "                   $Name THE $Class - STATS" -ForegroundColor Cyan
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Show party status
        Write-Host "  PARTY STATUS:" -ForegroundColor Yellow
        for ($i = 0; $i -lt 4; $i++) {
            $status = $PartyStatus[$i]
            $prefix = if (($i + 1) -eq $Position) { "  >> " } else { "     " }
            $color = if (($i + 1) -eq $Position) { "White" } else { 
                if ($status -eq "EMPTY") { "DarkGray" } else { "Green" }
            }
            Write-Host "$prefix Position $($i + 1): $status" -ForegroundColor $color
        }
        Write-Host ""
        
        # Show character stats
        Write-Host "  ROLLED STATS:" -ForegroundColor Yellow
        $statRanges = Get-ClassStatRanges -Class $Class
        
        Write-Host ("    Health Points (HP): {0,-3} (Range: {1}-{2})" -f $character.MaxHP, $statRanges.HP[0], $statRanges.HP[1]) -ForegroundColor $(if ($character.MaxHP -ge ($statRanges.HP[0] + $statRanges.HP[1])/2) { "Green" } else { "Yellow" })
        Write-Host ("    Magic Points  (MP): {0,-3} (Range: {1}-{2})" -f $character.MaxMP, $statRanges.MP[0], $statRanges.MP[1]) -ForegroundColor $(if ($character.MaxMP -ge ($statRanges.MP[0] + $statRanges.MP[1])/2) { "Green" } else { "Yellow" })
        Write-Host ("    Attack        (ATK): {0,-3} (Range: {1}-{2})" -f $character.Attack, $statRanges.Attack[0], $statRanges.Attack[1]) -ForegroundColor $(if ($character.Attack -ge ($statRanges.Attack[0] + $statRanges.Attack[1])/2) { "Green" } else { "Yellow" })
        Write-Host ("    Defense       (DEF): {0,-3} (Range: {1}-{2})" -f $character.Defense, $statRanges.Defense[0], $statRanges.Defense[1]) -ForegroundColor $(if ($character.Defense -ge ($statRanges.Defense[0] + $statRanges.Defense[1])/2) { "Green" } else { "Yellow" })
        Write-Host ("    Speed         (SPD): {0,-3} (Range: {1}-{2})" -f $character.Speed, $statRanges.Speed[0], $statRanges.Speed[1]) -ForegroundColor $(if ($character.Speed -ge ($statRanges.Speed[0] + $statRanges.Speed[1])/2) { "Green" } else { "Yellow" })
        Write-Host ""
        
        Write-Host "    Equipment: $($character.Equipped.Weapon), $($character.Equipped.Armor)" -ForegroundColor DarkGray
        Write-Host ""
        
        if ($rerollCount -lt $maxRerolls) {
            Write-Host "  [ENTER] Keep these stats  [R] Re-roll stats ($($maxRerolls - $rerollCount) left)  [ESC] Go back" -ForegroundColor White
        } else {
            Write-Host "  [ENTER] Keep these stats  [ESC] Go back  (No re-rolls remaining)" -ForegroundColor White
        }
        
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "Enter" {
                return $character
            }
            "R" {
                if ($rerollCount -lt $maxRerolls) {
                    $character = New-CharacterWithRolledStats -Name $Name -Class $Class -Position $Position
                    $rerollCount++
                }
            }
            "Escape" {
                return "BACK"
            }
        }
    } while ($true)
}

function Show-CharacterConfirmation {
    param(
        [object]$Character,
        [int]$Position,
        [array]$PartyStatus
    )
    
    Clear-Host
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "              CHARACTER $Position COMPLETE - CONFIRM" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Show party status
    Write-Host "  PARTY STATUS:" -ForegroundColor Yellow
    for ($i = 0; $i -lt 4; $i++) {
        $status = if (($i + 1) -eq $Position) { "$($Character.Name) ($($Character.Class))" } else { $PartyStatus[$i] }
        $prefix = if (($i + 1) -eq $Position) { "  >> " } else { "     " }
        $color = if (($i + 1) -eq $Position) { "White" } else { 
            if ($status -eq "EMPTY") { "DarkGray" } else { "Green" }
        }
        Write-Host "$prefix Position $($i + 1): $status" -ForegroundColor $color
    }
    Write-Host ""
    
    # Show complete character details
    Write-Host "  CHARACTER DETAILS:" -ForegroundColor Yellow
    Write-Host "    Name: $($Character.Name)" -ForegroundColor White
    Write-Host "    Class: $($Character.Class)" -ForegroundColor White
    Write-Host "    Color: " -NoNewline -ForegroundColor White
    $charColor = if ($Character.Color) { $Character.Color } else { "White" }
    Write-Host $Character.Color -ForegroundColor $charColor
    Write-Host "    HP: $($Character.MaxHP)  MP: $($Character.MaxMP)  ATK: $($Character.Attack)  DEF: $($Character.Defense)  SPD: $($Character.Speed)" -ForegroundColor Green
    Write-Host "    Equipment: $($Character.Equipped.Weapon), $($Character.Equipped.Armor)" -ForegroundColor Gray
    Write-Host "    Spells: $($Character.Spells -join ', ')" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  [Y] Confirm  [C] Change class  [N] Change name  [K] Change color  [S] Re-roll stats" -ForegroundColor White
    
    do {
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "Y" { return "YES" }
            "C" { return "EDIT_CLASS" }
            "N" { return "EDIT_NAME" }
            "K" { return "EDIT_COLOR" }
            "S" { return "EDIT_STATS" }
        }
    } while ($true)
}

function Show-FinalPartyPreview {
    param(
        [array]$Characters,
        [bool]$AllowEdit = $false
    )
    
    Clear-Host
    
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                           FINAL PARTY PREVIEW" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $totalHP = 0
    $totalMP = 0
    $totalAttack = 0
    $totalDefense = 0
    $avgSpeed = 0
    
    for ($i = 0; $i -lt $Characters.Count; $i++) {
        $char = $Characters[$i]
        $pos = $i + 1
        
        Write-Host ("  Position {0}: {1} the {2}" -f $pos, $char.Name, $char.Class) -ForegroundColor White
        Write-Host ("             HP: {0,-3} MP: {1,-3} ATK: {2,-3} DEF: {3,-3} SPD: {4}" -f 
            $char.MaxHP, $char.MaxMP, $char.Attack, $char.Defense, $char.Speed) -ForegroundColor Gray
        Write-Host ("             Equipment: {0}, {1}" -f $char.Equipped.Weapon, $char.Equipped.Armor) -ForegroundColor DarkGray
        Write-Host ""
        
        $totalHP += $char.MaxHP
        $totalMP += $char.MaxMP
        $totalAttack += $char.Attack
        $totalDefense += $char.Defense
        $avgSpeed += $char.Speed
    }
    
    $avgSpeed = [Math]::Round($avgSpeed / $Characters.Count, 1)
    
    Write-Host "  PARTY TOTALS:" -ForegroundColor Yellow
    Write-Host ("    Total HP: {0}    Total MP: {1}" -f $totalHP, $totalMP) -ForegroundColor Green
    Write-Host ("    Total ATK: {0}   Total DEF: {1}   Average SPD: {2}" -f $totalAttack, $totalDefense, $avgSpeed) -ForegroundColor Green
    Write-Host ""
    Write-Host "  OVERWORLD FORMATION:" -ForegroundColor Yellow
    Write-Host ("    {0}(Leader) -> {1} -> {2} -> {3}" -f 
        $Characters[0].ClassData.MapSymbol,
        $Characters[1].ClassData.MapSymbol,
        $Characters[2].ClassData.MapSymbol,
        $Characters[3].ClassData.MapSymbol) -ForegroundColor Cyan
    Write-Host ""
    
    if ($AllowEdit) {
        Write-Host "  [Y] Begin adventure!  [E] Edit a character  [R] Restart completely" -ForegroundColor White
        
        do {
            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                "Y" { return "YES" }
                "E" { return "EDIT" }
                "R" { return "RESTART" }
            }
        } while ($true)
    } else {
        Write-Host "  [Y] Begin adventure!  [N] Restart party creation" -ForegroundColor White
        
        do {
            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                "Y" { return "YES" }
                "N" { return "RESTART" }
            }
        } while ($true)
    }
}

function Show-EditCharacterMenu {
    param([array]$Characters)
    
    Clear-Host
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                         EDIT CHARACTER MENU" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  Select a character to edit:" -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 0; $i -lt $Characters.Count; $i++) {
        $char = $Characters[$i]
        Write-Host ("    [{0}] Position {1}: {2} the {3}" -f ($i + 1), ($i + 1), $char.Name, $char.Class) -ForegroundColor White
        Write-Host ("        HP:{0} MP:{1} ATK:{2} DEF:{3} SPD:{4}" -f $char.MaxHP, $char.MaxMP, $char.Attack, $char.Defense, $char.Speed) -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "  Press 1-4 to select character, ESC to cancel" -ForegroundColor DarkGray
    
    do {
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "D1" { return 0 }
            "D2" { return 1 }
            "D3" { return 2 }
            "D4" { return 3 }
            "Escape" { return -1 }
        }
    } while ($true)
}

# =============================================================================
# EXPORT FUNCTIONS
# =============================================================================

# Make functions available globally
$global:CharacterCreationFunctions = @{
    "Start-CharacterCreation" = ${function:Start-CharacterCreation}
    "Initialize-PartyFromCreation" = ${function:Initialize-PartyFromCreation}
    "New-DefaultParty" = ${function:New-DefaultParty}
    "New-RandomParty" = ${function:New-RandomParty}
    "New-Character" = ${function:New-Character}
    "Get-RandomName" = ${function:Get-RandomName}
}

Write-Host "Character Creation System loaded! Functions available:" -ForegroundColor Green
Write-Host "  * Start-CharacterCreation - Full character creation interface" -ForegroundColor Yellow
Write-Host "  * New-DefaultParty - Quick balanced party" -ForegroundColor Yellow
Write-Host "  * New-RandomParty - Random party generation" -ForegroundColor Yellow
