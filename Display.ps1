# =============================================================================
# JRPG Display System - Main Controller
# =============================================================================

# Import required modules
. "$PSScriptRoot\CombatDisplay.ps1"
. "$PSScriptRoot\TurnOrder.ps1"
. "$PSScriptRoot\WaterAnimation.ps1"
. "$PSScriptRoot\ViewportRenderer.ps1"
. "$PSScriptRoot\SaveSystem.ps1"
. "$PSScriptRoot\MapManager.ps1"
# Import transition effects
. "$PSScriptRoot\Transitions.ps1"
# Import ONLY the simple color system (fast!)
. "$PSScriptRoot\SimpleColors.ps1"
# Import character coloring system (performance-optimized)
. "$PSScriptRoot\CharacterColors.ps1"
# Import enhanced enemy and battle systems
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1"
# Import Settings Menu System
. "$PSScriptRoot\SettingsMenu.ps1"
# Note: CleanArrowTargeting functions are now defined directly below

# Enhanced enemy array cleanup function - ensures it's always available
function Clean-EnemyArray {
    param($enemies)
    
    if (-not $enemies -or $enemies.Count -eq 0) {
        return @()
    }
    
    # Create new clean array with only living enemies
    $cleanEnemies = @()
    foreach ($enemy in $enemies) {
        if ($null -ne $enemy -and $null -ne $enemy.HP -and $enemy.HP -gt 0) {
            $cleanEnemies += $enemy
        }
    }
    
    return $cleanEnemies
}

# Clean battle targeting function - ensures it's always available
function Show-CleanBattleTargeting {
    param($enemies, $boxWidth, $boxHeight)
    
    # Filter to only alive enemies
    $aliveEnemies = @($enemies | Where-Object { $null -ne $_ -and $_.HP -gt 0 })
    
    if ($aliveEnemies.Count -eq 0) {
        Write-Host "No enemies to target!" -ForegroundColor Red
        Start-Sleep -Milliseconds 1500
        return $null
    }
    
    # Always show targeting interface, even for single enemy
    $selectedIndex = 0
    $maxIndex = $aliveEnemies.Count - 1
    
    while ($true) {
        # Clear and redraw battle with ONLY arrow indicator
        [System.Console]::Clear()
        Draw-EnhancedCombatViewport $aliveEnemies $boxWidth $boxHeight
        Add-CleanTargetingArrow $aliveEnemies $aliveEnemies[$selectedIndex] $boxWidth $boxHeight
        
        # All text stays BELOW the battle area
        [System.Console]::SetCursorPosition(0, $boxHeight + 2)
        Write-Host ""
        Write-Host "=== SELECT TARGET ===" -ForegroundColor Yellow
        Write-Host "Use Left/Right Arrow Keys or A/D to select, Enter to confirm, Q to cancel" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Selected: $($aliveEnemies[$selectedIndex].Name) (HP: $($aliveEnemies[$selectedIndex].HP)/$($aliveEnemies[$selectedIndex].MaxHP))" -ForegroundColor Yellow
        
        # Get input
        $keyPressed = [System.Console]::ReadKey($true)
        
        switch ($keyPressed.Key) {
            "LeftArrow"  { 
                $selectedIndex = [math]::Max(0, $selectedIndex - 1)
            }
            "RightArrow" { 
                $selectedIndex = [math]::Min($maxIndex, $selectedIndex + 1)
            }
            "A"          { 
                $selectedIndex = [math]::Max(0, $selectedIndex - 1)
            }
            "D"          { 
                $selectedIndex = [math]::Min($maxIndex, $selectedIndex + 1)
            }
            "Enter"      { 
                return $aliveEnemies[$selectedIndex] 
            }
            "Q"          { 
                return $null 
            }
            "Escape"     { 
                return $null 
            }
        }
    }
}

# Add targeting arrow function - ensures it's always available
function Add-CleanTargetingArrow {
    param($aliveEnemies, $targetedEnemy, $boxWidth, $boxHeight)
    
    # Get layout for ONLY alive enemies
    $layout = Calculate-BattleLayout $aliveEnemies $boxWidth $boxHeight
    
    foreach ($row in $layout.Rows) {
        for ($i = 0; $i -lt $row.Enemies.Count; $i++) {
            $enemy = $row.Enemies[$i]
            
            # Check if this is the targeted enemy
            if ($enemy.Name -eq $targetedEnemy.Name -and $enemy.HP -eq $targetedEnemy.HP) {
                
                # Calculate enemy center position
                $enemySpacing = [math]::Floor($boxWidth / $row.Enemies.Count)
                $enemyCenter = ($i * $enemySpacing) + [math]::Floor($enemySpacing / 2)
                
                # Draw ONLY a simple arrow above enemy (within battle area bounds)
                $arrowY = [math]::Max(2, $row.StartY - 1)
                
                try {
                    if ($arrowY -lt ($boxHeight - 1)) {  # Make sure we stay within battle area
                        [System.Console]::SetCursorPosition($enemyCenter, $arrowY)
                        Write-Host "^" -ForegroundColor Red -NoNewline
                    }
                } catch {
                    # If positioning fails, continue silently
                }
                
                return  # Found and marked the target
            }
        }
    }
}

# Hashtable of available transitions
$TransitionEffects = @{
    "wipe"  = "ShowWipeTransition"
    "flash" = "ShowFlashTransition"
    "fade"  = "ShowFadeTransition"
}

# Pick transition type (change to "flash" or "fade" to try others)
$ChosenTransition = "flash"

# ==============================
# JRPG Real-Time Movement Demo (Real-Time Updates)
# ==============================
# 
# WATER ANIMATION CONFIGURATION:
# - Set $global:EnableWaterAnimation = $false to completely disable water effects
# - Set $global:WaterRenderMethod to:
#   * "ANSI"   = Fast ANSI escape sequences (best performance, modern terminals)
#   * "CURSOR" = Original cursor positioning (slower, maximum compatibility)  
#   * "NONE"   = Static water without animation (fastest, no effects)

# Enable ANSI escape codes (optional, but not needed for SetCursorPosition)
# Remove stray output (True True) and unnecessary code

# Set box dimensions
$boxWidth = 80
$boxHeight = 25

# Set console output encoding to UTF-8 for Unicode support
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Enable color zones (start small - just one green dot!)
# Color system configuration (using new simple system)
$global:EnableColorZones = $false  # Enable limited colors

# ============================================================================
# EXPERIMENTAL COLOR SETUP (for testing with fast rendering)
# ============================================================================

# Initialize the simple color system and add some colorful examples
Initialize-SimpleColors

# Example 1: Single green dot (1x1 rectangle)
Add-SimpleColorRectangle "Town" 32 18 1 1 "Green"

# Example 2: Small red rectangle (2x2)
Add-SimpleColorRectangle "Town" 28 16 2 2 "Red"

# Example 3: Blue horizontal line (4x1)
Add-SimpleColorRectangle "Town" 25 22 4 1 "Blue"

# Example 4: Yellow vertical line (1x3)
Add-SimpleColorRectangle "Town" 35 19 1 3 "Yellow"

# Example 5: Cyan square (3x3)
Add-SimpleColorRectangle "Town" 26 24 3 3 "Cyan"

Write-Host "Added colorful rectangles around player area!" -ForegroundColor Yellow
Write-Host "Green dot at (32,18), Red 2x2 at (28,16), Blue line at (25,22), Yellow line at (35,19), Cyan 3x3 at (26,24)" -ForegroundColor Gray

# =============================================================================
# PARTY INITIALIZATION (after save system loads)
# =============================================================================

# Party initialization will happen after PartySystem.ps1 is loaded

# Set initial player position (centered, inside box)
$playerX = [math]::Floor($boxWidth / 2)
$playerY = [math]::Floor($boxHeight / 2)

# ASCII character for player
$playerChar = "@"

# Load Quest System first
. "$PSScriptRoot\QuestSystem.ps1"

# Load Enhanced NPCs with Quest Integration
. "$PSScriptRoot\NPCs.ps1"

# Load maps
. "$PSScriptRoot\Maps.ps1"

# NPC Interaction function
function Show-NPCInteraction {
    param($playerX, $playerY)
    
    # Check all adjacent positions for NPCs
    $adjacentPositions = @(
        @{ X = $playerX - 1; Y = $playerY },     # Left
        @{ X = $playerX + 1; Y = $playerY },     # Right
        @{ X = $playerX; Y = $playerY - 1 },     # Up
        @{ X = $playerX; Y = $playerY + 1 },     # Down
        @{ X = $playerX; Y = $playerY }          # Same position
    )
    
    $nearbyNPCs = @()
    # Check for NPCs on current map
    foreach ($pos in $adjacentPositions) {
        $npc = Get-NPCAtPosition $pos.X $pos.Y $global:CurrentMapName
        if ($npc) {
            $nearbyNPCs += $npc
        }
    }
    
    if ($nearbyNPCs.Count -eq 0) {
        Write-Host "No one to talk to here." -ForegroundColor Yellow
        Start-Sleep -Milliseconds 1000
        return
    }
    
    # If multiple NPCs, let player choose (for future expansion)
    $npcToTalkTo = $nearbyNPCs[0]
    
    # Start dialogue with the NPC
    $npcData = $global:NPCs | Where-Object { $_.Name -eq $npcToTalkTo.Name } | Select-Object -First 1
    if ($npcData) {
        Show-NPCDialogueTree $npcData
    } else {
        Write-Host "Error: NPC data not found for $($npcToTalkTo.Name)" -ForegroundColor Red
        Start-Sleep -Milliseconds 1000
    }
}

# NEW: Use IntegratedColors.ps1 only - no ColorZones.ps1!
# (IntegratedColors.ps1 is already loaded above)

# Load enemies
. "$PSScriptRoot\Enemies.ps1"

# Load party system (Phase 2.1/2.2)
# Load PartySystem.ps1 for party functions
. "$PSScriptRoot\PartySystem.ps1"

# Initialize global party from save data or create new party (only if no custom party exists)
if (-not $global:Party) {
    if ($SaveState.Party.Members -and $SaveState.Party.Members.Count -gt 0) {
        $global:Party = ConvertFrom-PartySaveData $SaveState.Party.Members
        Write-Host "Party loaded from save data!" -ForegroundColor Green
    } else {
        $global:Party = New-DefaultParty
        Write-Host "New party assembled! Ready for adventure!" -ForegroundColor Green
    }
} else {
    Write-Host "Using custom party from character creation!" -ForegroundColor Green
}

# Pause for startup error visibility (after imports)
Read-Host "Press Enter to continue..."

# Clear screen before starting the game
Clear-Host

# Start in town
$CurrentMapName = "Town"
$currentMap = $global:Maps[$CurrentMapName]

# Verify map loaded correctly
if (-not $currentMap) {
    Write-Host "ERROR: Could not load map '$CurrentMapName'. Please check Maps.ps1 and MapManager.ps1" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
}
 
 # Initialize party positions if party exists
 if ($global:Party) {
     Initialize-PartyPositions $playerX $playerY $global:Party
 }

 # Initialize simple water animation counter
 $global:FrameCounter = 0

 $running = $true
 $battleMode = $false
 $battleCooldown = 0  # Prevent immediate battles after exiting one

try {
    while ($running) {
        $errorMsg = $null
        try {
            if ($battleMode) {
                # Only load default Player.ps1 if no custom party exists
                if (-not $global:Player -or (-not $global:PartyMembers -and -not $global:Party)) {
                    . "$PSScriptRoot\Player.ps1"
                }
                
                # Party is already initialized globally
                
                # Sync Player object with save state
                $Player = Sync-PlayerFromSaveState $Player
                
                . "$PSScriptRoot\NewEnemies.ps1"
                # Enhanced Enemy Selection Logic - uses new varied encounter system
                $enemies = Get-RandomEnemyEncounter $CurrentMapName 3  # Difficulty level 3
                
                # Keep legacy variables for compatibility (using first enemy)
                $enemy = $enemies[0]
                $EnemyName = $enemy.Name
                $enemyArt = $enemy.Art



                # Initialize battle state
                $partyDefending = @{}
                foreach ($member in $Party) {
                    $partyDefending[$member.Name] = $false
                }
                $inCombat = $true
                $invalidKeyCount = 0  # Track invalid keypresses without slowing combat
                
                # Clear input buffer at battle start to prevent overworld key spillover
                Write-Host "Battle starting..." -ForegroundColor Yellow
                while ([System.Console]::KeyAvailable) {
                    [System.Console]::ReadKey($true) | Out-Null
                }
                Start-Sleep -Milliseconds 500
                
                # Create turn order for party vs enemies
                $turnOrder = New-PartyTurnOrder $Party $enemies
                $currentTurnIndex = 0
                $maxTurns = 100  # Prevent infinite loops
                $turnCount = 0
                
                while ($inCombat -and $turnCount -lt $maxTurns) {
                    $turnCount++
                    
                    # Simple safe approach: minimal clear at start of each combat round
                    # Clear screen only once per turn to reset everything cleanly
                    [System.Console]::Clear()
                    
                    # Redraw the combat interface (enhanced version)
                    Draw-EnhancedCombatViewport $enemies $boxWidth $boxHeight
                    Write-Host "Combat Controls: A=Attack   D=Defend   S=Spells   I=Items   R=Run" -ForegroundColor Cyan
                    
                    # Display party status
                    Write-Host "`nParty Status:" -ForegroundColor Green
                    foreach ($member in $Party) {
                        $hpDisplay = [math]::Max(0, $member.HP)
                        $mpDisplay = [math]::Max(0, $member.MP)
                        $hpStr = $hpDisplay.ToString().PadRight(3)
                        $maxHPStr = $member.MaxHP.ToString().PadRight(3)
                        $mpStr = $mpDisplay.ToString().PadRight(3)
                        $maxMPStr = $member.MaxMP.ToString().PadRight(3)
                        
                        $status = if ($member.HP -le 0) { " [KO]" } else { "" }
                        Write-Host ("  $($member.Name) ($($member.Class)): HP $hpStr/$maxHPStr MP $mpStr/$maxMPStr$status") -ForegroundColor White
                    }
                    
                    # Display enemy status (all enemies)
                    Write-Host "`nEnemy Status:" -ForegroundColor Yellow
                    foreach ($enemyObj in $enemies) {
                        $enemyHPDisplay = [math]::Max(0, $enemyObj.HP)
                        $enemyMPDisplay = [math]::Max(0, $enemyObj.MP)
                        $enemyHPStr = $enemyHPDisplay.ToString().PadRight(4)
                        $enemyMaxHPStr = $enemyObj.MaxHP.ToString().PadRight(4)
                        $enemyMPStr = $enemyMPDisplay.ToString().PadRight(4)
                        $enemyMaxMPStr = $enemyObj.MaxMP.ToString().PadRight(4)
                        
                        $status = if ($enemyObj.HP -le 0) { " [KO]" } else { "" }
                        Write-Host ("  $($enemyObj.Name): HP $enemyHPStr/$enemyMaxHPStr   MP $enemyMPStr/$enemyMaxMPStr$status") -ForegroundColor White
                    }
                    
                    # Show turn order
                    Show-PartyTurnOrder $turnOrder $currentTurnIndex
                    
                    # Get current combatant
                    $currentCombatant = $turnOrder[$currentTurnIndex]
                    $isPlayerTurn = ($currentCombatant.Type -eq "Party")
                    
                    if ($isPlayerTurn) {
                        # Party member turn
                        $currentMember = $currentCombatant.Character
                        Write-CombatMessage "$($currentMember.Name) - Choose action..." "White" "$($currentMember.Name.ToUpper()) TURN"
                        $input = [System.Console]::ReadKey($true)
                        # Reset defending status at start of turn
                        $partyDefending[$currentMember.Name] = $false
                        
                        # Process party member action
                        if ($input.Key -eq "A") {
                            # Attack action with target selection
                            $aliveEnemies = Clean-EnemyArray $enemies
                            if ($aliveEnemies.Count -eq 0) {
                                Write-CombatMessage "No enemies to attack!" "Red"
                                Start-Sleep -Milliseconds 1200
                                continue
                            }
                            
                            $target = Show-CleanBattleTargeting $enemies $boxWidth $boxHeight
                            
                            if ($target) {
                                $damage = [math]::Max(1, $currentMember.Attack - $target.Defense)
                                $target.HP -= $damage
                                Write-CombatMessage "$($currentMember.Name) attacks $($target.Name) for $damage damage!" "Yellow"
                                
                                # Clean up dead enemies from the array
                                $enemies = Clean-EnemyArray $enemies
                                
                                Start-Sleep -Milliseconds 1200
                            } else {
                                Write-CombatMessage "Attack cancelled." "Gray"
                                Start-Sleep -Milliseconds 800
                                continue
                            }
                            
                        } elseif ($input.Key -eq "D") {
                            # Defend action - reduces incoming damage next turn
                            $partyDefending[$currentMember.Name] = $true
                            Write-CombatMessage "$($currentMember.Name) braces for the enemy's attack!" "Green"
                            Start-Sleep -Milliseconds 1200
                            
                        } elseif ($input.Key -eq "S") {
                            # Spell casting menu
                            Write-CombatMessage "Opening spell menu..." "Magenta"
                            Start-Sleep -Milliseconds 500
                            
                            # Calculate safe menu position based on console size
                            $menuStartY = 28  # Start menu below message area
                            $maxY = [System.Console]::BufferHeight - 10
                            if ($menuStartY -gt $maxY) {
                                $menuStartY = $maxY
                            }
                            
                            # Clear area below message for spell menu - safely
                            try {
                                for ($clearY = $menuStartY; $clearY -lt ($menuStartY + 8) -and $clearY -lt ([System.Console]::BufferHeight - 1); $clearY++) {
                                    [System.Console]::SetCursorPosition(0, $clearY)
                                    Write-Host (" " * 80)
                                }
                            } catch {
                                # If cursor positioning fails, just clear the screen and continue
                                [System.Console]::Clear()
                            }
                            
                            # Display spell menu in controlled position
                            try {
                                [System.Console]::SetCursorPosition(0, $menuStartY)
                                Write-Host "Available Spells:" -ForegroundColor Magenta
                            } catch {
                                Write-Host "`nAvailable Spells:" -ForegroundColor Magenta
                            }
                            
                            . "$PSScriptRoot\Spells.ps1"
                            $availableSpells = @()
                            $menuLine = $menuStartY + 1
                            
                            for ($i = 0; $i -lt $currentMember.Spells.Count; $i++) {
                                $spellName = $currentMember.Spells[$i]
                                $spell = $Spells | Where-Object { $_.Name -eq $spellName }
                                if ($spell -and $currentMember.MP -ge $spell.MP) {
                                    $availableSpells += $spell
                                    try {
                                        [System.Console]::SetCursorPosition(0, $menuLine)
                                        Write-Host "[$($i+1)] $($spell.Name) (MP: $($spell.MP))" -ForegroundColor Cyan
                                    } catch {
                                        Write-Host "[$($i+1)] $($spell.Name) (MP: $($spell.MP))" -ForegroundColor Cyan
                                    }
                                    $menuLine++
                                }
                            }
                            
                            if ($availableSpells.Count -eq 0) {
                                Write-CombatMessage "No spells available (insufficient MP)!" "Red"
                                Start-Sleep -Milliseconds 1500
                                continue
                            }
                            
                            try {
                                [System.Console]::SetCursorPosition(0, $menuLine)
                                Write-Host "[0] Cancel" -ForegroundColor Gray
                                $menuLine++
                                [System.Console]::SetCursorPosition(0, $menuLine)
                                Write-Host "Choose a spell: " -NoNewline -ForegroundColor White
                            } catch {
                                Write-Host "[0] Cancel" -ForegroundColor Gray
                                Write-Host "Choose a spell: " -NoNewline -ForegroundColor White
                            }
                            
                            $spellChoice = [System.Console]::ReadKey($true)
                            $spellIndex = [int]$spellChoice.KeyChar - 49  # Convert to 0-based index
                            
                            if ($spellChoice.KeyChar -eq '0') {
                                Write-CombatMessage "Spell casting cancelled." "Gray"
                                Start-Sleep -Milliseconds 800
                                continue
                            } elseif ($spellIndex -ge 0 -and $spellIndex -lt $availableSpells.Count) {
                                $selectedSpell = $availableSpells[$spellIndex]
                                $currentMember.MP -= $selectedSpell.MP
                                
                                if ($selectedSpell.Type -eq "Attack") {
                                    # Attack spell with target selection
                                    $aliveEnemies = Clean-EnemyArray $enemies
                                    if ($aliveEnemies.Count -eq 0) {
                                        Write-CombatMessage "No enemies to target!" "Red"
                                        # Refund MP since spell couldn't be cast
                                        $currentMember.MP += $selectedSpell.MP
                                        Start-Sleep -Milliseconds 1200
                                        continue
                                    }
                                    
                                    $target = Show-CleanBattleTargeting $enemies $boxWidth $boxHeight
                                    
                                    if ($target) {
                                        $spellDamage = $selectedSpell.Power + [math]::Floor($currentMember.Attack / 2)
                                        $target.HP -= $spellDamage
                                        Write-CombatMessage "$($currentMember.Name) casts $($selectedSpell.Name) on $($target.Name) for $spellDamage damage!" "Magenta"
                                        
                                        # Clean up dead enemies from the array
                                        $enemies = Clean-EnemyArray $enemies
                                        
                                    } else {
                                        # Refund MP if spell was cancelled
                                        $currentMember.MP += $selectedSpell.MP
                                        Write-CombatMessage "Spell cancelled." "Gray"
                                        Start-Sleep -Milliseconds 800
                                        continue
                                    }
                                } elseif ($selectedSpell.Type -eq "Recovery") {
                                    # For healing spells, let party member choose target (simplified to self for now)
                                    $healAmount = [math]::Min($selectedSpell.Power, $currentMember.MaxHP - $currentMember.HP)
                                    $currentMember.HP += $healAmount
                                    Write-CombatMessage "$($currentMember.Name) casts $($selectedSpell.Name) and recovers $healAmount HP!" "Green"
                                }
                                Start-Sleep -Milliseconds 1200
                            } else {
                                Write-CombatMessage "Invalid spell selection!" "Red"
                                Start-Sleep -Milliseconds 1200
                                continue
                            }
                            
                        } elseif ($input.Key -eq "I") {
                            # Items menu (basic implementation)
                            Write-CombatMessage "Opening inventory..." "Yellow"
                            Start-Sleep -Milliseconds 500
                            
                            if ($currentMember.Inventory.Count -eq 0) {
                                # Basic item system - add potion if inventory empty for demo
                                if ($currentMember.Inventory -notcontains "Health Potion") {
                                    $currentMember.Inventory += "Health Potion"
                                }
                            }
                            
                            if ($currentMember.Inventory.Count -eq 0) {
                                Write-CombatMessage "No items available!" "Red"
                                Start-Sleep -Milliseconds 1500
                                continue
                            }
                            
                            # Calculate safe menu position
                            $menuStartY = 28  # Start menu below message area
                            $maxY = [System.Console]::BufferHeight - 6
                            if ($menuStartY -gt $maxY) {
                                $menuStartY = $maxY
                            }
                            
                            # Clear area below message for item menu - safely
                            try {
                                for ($clearY = $menuStartY; $clearY -lt ($menuStartY + 5) -and $clearY -lt ([System.Console]::BufferHeight - 1); $clearY++) {
                                    [System.Console]::SetCursorPosition(0, $clearY)
                                    Write-Host (" " * 80)
                                }
                            } catch {
                                # If cursor positioning fails, fall back to normal output
                            }
                            
                            # Display item menu in controlled position
                            try {
                                [System.Console]::SetCursorPosition(0, $menuStartY)
                                Write-Host "Inventory:" -ForegroundColor Yellow
                                
                                [System.Console]::SetCursorPosition(0, $menuStartY + 1)
                                Write-Host "[1] Health Potion (Restores 15 HP)" -ForegroundColor Cyan
                                [System.Console]::SetCursorPosition(0, $menuStartY + 2)
                                Write-Host "[0] Cancel" -ForegroundColor Gray
                                [System.Console]::SetCursorPosition(0, $menuStartY + 3)
                                Write-Host "Choose an item: " -NoNewline -ForegroundColor White
                            } catch {
                                Write-Host "`nInventory:" -ForegroundColor Yellow
                                Write-Host "[1] Health Potion (Restores 15 HP)" -ForegroundColor Cyan
                                Write-Host "[0] Cancel" -ForegroundColor Gray
                                Write-Host "Choose an item: " -NoNewline -ForegroundColor White
                            }
                            
                            $itemChoice = [System.Console]::ReadKey($true)
                            
                            if ($itemChoice.KeyChar -eq '0') {
                                Write-CombatMessage "Item use cancelled." "Gray"
                                Start-Sleep -Milliseconds 800
                                continue
                            } elseif ($itemChoice.KeyChar -eq '1' -and $currentMember.Inventory -contains "Health Potion") {
                                $healAmount = [math]::Min(15, $currentMember.MaxHP - $currentMember.HP)
                                $currentMember.HP += $healAmount
                                $currentMember.Inventory = $currentMember.Inventory | Where-Object { $_ -ne "Health Potion" }
                                Write-CombatMessage "$($currentMember.Name) uses a Health Potion and recovers $healAmount HP!" "Green"
                                Start-Sleep -Milliseconds 1200
                            } else {
                                Write-CombatMessage "Invalid item selection!" "Red"
                                Start-Sleep -Milliseconds 1200
                                continue
                            }
                            
                        } elseif ($input.Key -eq "R") {
                            # Attempt to flee
                            $fleeChance = 75 + ($player.Level * 5)  # Base 75% + 5% per level
                            $fleeRoll = Get-Random -Minimum 1 -Maximum 101
                            
                            if ($fleeRoll -le $fleeChance) {
                                Write-CombatMessage "You successfully escaped!" "Green"
                                Start-Sleep -Milliseconds 1500
                                # Track monster as encountered only if not already in hashtable
                                if (-not $SaveState.Monsters.ContainsKey($EnemyName)) {
                                    $SaveState.Monsters[$EnemyName] = 0
                                    Save-GameState
                                }
                                # Clear input buffer when exiting battle
                                while ([System.Console]::KeyAvailable) {
                                    [System.Console]::ReadKey($true) | Out-Null
                                }
                                $battleMode = $false
                                $inCombat = $false
                                $battleCooldown = 100  # 100 frames of cooldown before next battle
                                [System.Console]::Clear()
                                break
                            } else {
                                Write-CombatMessage "Couldn't escape!" "Red"
                                Start-Sleep -Milliseconds 1200
                            }
                            
                        } else {
                            # Invalid input - show brief message without blocking combat flow
                            $invalidKeyCount++
                            $keyPressed = if ($input.KeyChar) { $input.KeyChar } else { $input.Key.ToString() }
                            Write-Host "[$keyPressed] - Use A/D/S/I/R" -ForegroundColor DarkRed
                            continue
                        }
                        
                    } else {
                        # Enemy turn - Enhanced AI with spell casting
                        $currentEnemy = $currentCombatant.Character
                        . "$PSScriptRoot\Spells.ps1"
                        
                        $enemyAction = "attack"  # Default action
                        $spellToCast = $null
                        
                        # AI Decision Logic (Simple AI as requested)
                        if ($currentEnemy.Spells.Count -gt 0 -and $currentEnemy.MP -gt 0) {
                            # Check available spells
                            $availableSpells = @()
                            foreach ($spellName in $currentEnemy.Spells) {
                                $spell = $Spells | Where-Object { $_.Name -eq $spellName }
                                if ($spell -and $currentEnemy.MP -ge $spell.MP) {
                                    $availableSpells += $spell
                                }
                            }
                            
                            if ($availableSpells.Count -gt 0) {
                                # Simple AI Decision Making
                                $healingSpells = $availableSpells | Where-Object { $_.Type -eq "Recovery" }
                                $attackSpells = $availableSpells | Where-Object { $_.Type -eq "Attack" }
                                
                                # Healing logic: heal if health is below 40%
                                if ($healingSpells.Count -gt 0 -and $currentEnemy.HP -le ($currentEnemy.MaxHP * 0.4)) {
                                    $spellToCast = $healingSpells[0]
                                    $enemyAction = "heal"
                                }
                                # Attack spell logic: 50% chance to cast attack spell if available (simplified)
                                elseif ($attackSpells.Count -gt 0 -and (Get-Random -Minimum 1 -Maximum 101) -le 50) {
                                    $spellToCast = $attackSpells | Get-Random
                                    $enemyAction = "spell"
                                }
                            }
                        }
                        
                        # Execute enemy action
                        if ($enemyAction -eq "heal" -and $spellToCast) {
                            # Enemy heals itself
                            $currentEnemy.MP -= $spellToCast.MP
                            $healAmount = [math]::Min($spellToCast.Power, $currentEnemy.MaxHP - $currentEnemy.HP)
                            $currentEnemy.HP += $healAmount
                            Write-CombatMessage "$($currentEnemy.Name) casts $($spellToCast.Name) and recovers $healAmount HP!" "Yellow" "ENEMY TURN"
                            
                        } elseif ($enemyAction -eq "spell" -and $spellToCast) {
                            # Enemy casts attack spell - choose random living party member
                            $currentEnemy.MP -= $spellToCast.MP
                            $spellDamage = $spellToCast.Power + [math]::Floor($currentEnemy.Attack / 2)
                            
                            $aliveMembers = @($Party | Where-Object { $_.HP -gt 0 })
                            if ($aliveMembers.Count -gt 0) {
                                $target = $aliveMembers | Get-Random
                                
                                # Apply defense bonus if target defended
                                if ($partyDefending[$target.Name]) {
                                    $spellDamage = [math]::Max(1, [math]::Floor($spellDamage / 2))
                                    Write-CombatMessage "$($currentEnemy.Name) casts $($spellToCast.Name) on $($target.Name), but their defense reduces the damage to $spellDamage!" "Blue" "ENEMY TURN"
                                } else {
                                    Write-CombatMessage "$($currentEnemy.Name) casts $($spellToCast.Name) on $($target.Name) for $spellDamage damage!" "Magenta" "ENEMY TURN"
                                }
                                
                                $target.HP -= $spellDamage
                                $target.HP = [math]::Max(0, $target.HP)
                            }
                            
                        } else {
                            # Basic attack - choose random living party member
                            $aliveMembers = @($Party | Where-Object { $_.HP -gt 0 })
                            if ($aliveMembers.Count -gt 0) {
                                $target = $aliveMembers | Get-Random
                                $enemyDamage = [math]::Max(1, $currentEnemy.Attack - $target.Defense)
                                
                                # Apply defense bonus if target defended
                                if ($partyDefending[$target.Name]) {
                                    $enemyDamage = [math]::Max(1, [math]::Floor($enemyDamage / 2))
                                    Write-CombatMessage "$($currentEnemy.Name) attacks $($target.Name), but their defense reduces the damage to $enemyDamage!" "Blue" "ENEMY TURN"
                                } else {
                                    Write-CombatMessage "$($currentEnemy.Name) attacks $($target.Name) for $enemyDamage damage!" "Red" "ENEMY TURN"
                                }
                                
                                $target.HP -= $enemyDamage
                                $target.HP = [math]::Max(0, $target.HP)
                            }
                        }
                        
                        Start-Sleep -Milliseconds 2000  # Pause to read the enemy action
                    }
                    
                    # Check if all enemies are defeated
                    $aliveEnemies = Clean-EnemyArray $enemies
                    if ($aliveEnemies.Count -eq 0) {
                        # Calculate total XP from all defeated enemies
                        $totalXpGained = 0
                        foreach ($defeatedEnemy in $enemies) {
                            $totalXpGained += ($defeatedEnemy.Level * $defeatedEnemy.BaseXP)
                        }
                        
                        # Distribute XP to all living party members
                        $aliveMembers = @($Party | Where-Object { $_.HP -gt 0 })
                        $xpPerMember = [math]::Floor($totalXpGained / $aliveMembers.Count)
                        
                        foreach ($member in $aliveMembers) {
                            $member.XP += $xpPerMember
                        }
                        
                        $enemyNames = ($enemies | ForEach-Object { $_.Name }) -join ", "
                        Write-CombatMessage "All enemies defeated! Party gained $totalXpGained XP total ($xpPerMember each)!" "Green"
                        
                        # Update save state for monster kills (using party leader for global stats)
                        $partyLeader = $Party[0]
                        $SaveState.Player.XP = $partyLeader.XP
                        
                        # Track each defeated enemy
                        foreach ($defeatedEnemy in $enemies) {
                            $SaveState.Player.MonstersDefeated++
                            if (-not $SaveState.Monsters.ContainsKey($defeatedEnemy.Name)) {
                                $SaveState.Monsters[$defeatedEnemy.Name] = 0
                            }
                            $SaveState.Monsters[$defeatedEnemy.Name]++
                        }
                        
                        # Trigger auto-save for battle victory
                        Trigger-BattleVictoryAutoSave -enemyName $enemyNames -xpGained $totalXpGained
                        
                        # Update global save state with party data
                        Update-SaveStateFromParty $Party
                        
                        Start-Sleep -Milliseconds 2000
                        # Clear input buffer when exiting battle
                        while ([System.Console]::KeyAvailable) {
                            [System.Console]::ReadKey($true) | Out-Null
                        }
                        $battleMode = $false
                        $inCombat = $false
                        $battleCooldown = 100  # 100 frames of cooldown before next battle
                        [System.Console]::Clear()
                        break
                    }
                    
                    # Check if party is defeated (all members at 0 HP)
                    $aliveMembers = @($Party | Where-Object { $_.HP -gt 0 })
                    if ($aliveMembers.Count -eq 0) {
                        Write-CombatMessage "Your party was defeated!" "Magenta"
                        Start-Sleep -Milliseconds 2000
                        # Clear input buffer when exiting battle
                        while ([System.Console]::KeyAvailable) {
                            [System.Console]::ReadKey($true) | Out-Null
                        }
                        $battleMode = $false
                        $inCombat = $false
                        $battleCooldown = 100  # 100 frames of cooldown before next battle
                        [System.Console]::Clear()
                        break
                    }
                    
                    # BATTLE SAFETY CHECKS - Prevent endless loops
                    $alivePartyMembers = Get-AlivePartyMembers $Party
                    $aliveEnemies = Clean-EnemyArray $enemies
                    
                    # Safety check 1: No valid turn order
                    if (-not $turnOrder -or $turnOrder.Count -eq 0) {
                        Write-CombatMessage "BATTLE ERROR: Invalid turn order detected!" "Red"
                        Write-CombatMessage "Battle ending..." "Yellow"
                        $battleMode = $false
                        $inCombat = $false
                        continue
                    }
                    
                    # Safety check 2: Party defeated  
                    if ($alivePartyMembers.Count -eq 0) {
                        Write-CombatMessage "All party members have been defeated!" "Red"
                        Write-CombatMessage "GAME OVER" "Red"
                        Start-Sleep -Milliseconds 2000
                        $battleMode = $false
                        $inCombat = $false
                        continue
                    }
                    
                    # Safety check 3: All enemies defeated
                    if ($aliveEnemies.Count -eq 0) {
                        Write-CombatMessage "All enemies defeated!" "Green"
                        Write-CombatMessage "Victory!" "Yellow"
                        Start-Sleep -Milliseconds 2000
                        $battleMode = $false
                        $inCombat = $false
                        continue
                    }
                    
                    # Advance to next turn
                    $currentTurnIndex = ($currentTurnIndex + 1) % $turnOrder.Count
                    
                    # Reset defending status for enemy turns (defending only lasts one enemy attack)
                    if ($currentCombatant.Type -eq "Enemy") {
                        foreach ($member in $Party) {
                            $partyDefending[$member.Name] = $false
                        }
                    }
                }
                continue
            }

            # Update water animation with simple frame counter (runs every loop, independent of movement)
            $global:FrameCounter++
            if ($global:EnableWaterAnimation -and ($global:FrameCounter % 10) -eq 0) {
                # Update water frame every 10 game loops for smooth animation
                $global:WaterFrame = ($global:WaterFrame + 1) % 8
            }

            Draw-Viewport $currentMap $playerX $playerY $boxWidth $boxHeight

            # Read a key without waiting for Enter (with timeout so animation continues)
            if ([System.Console]::KeyAvailable) {
                $key = [System.Console]::ReadKey($true)
            } else {
                # Small delay to prevent CPU spinning, but keep animation going
                Start-Sleep -Milliseconds 50
                continue  # Continue the loop to keep animation running
            }

            # Calculate new position (only if we have a key press)
            $newX = $playerX
            $newY = $playerY
            $moved = $false
            
            if ($key) {
                switch ($key.Key) {
                    "LeftArrow" { $newX = [math]::Max(0, $playerX - 1); $moved = $true }
                    "A"         { $newX = [math]::Max(0, $playerX - 1); $moved = $true }
                    "RightArrow"{ $newX = [math]::Min($currentMap[0].Length - 1, $playerX + 1); $moved = $true }
                    "D"         { $newX = [math]::Min($currentMap[0].Length - 1, $playerX + 1); $moved = $true }
                    "UpArrow"   { $newY = [math]::Max(0, $playerY - 1); $moved = $true }
                    "W"         { $newY = [math]::Max(0, $playerY - 1); $moved = $true }
                    "DownArrow" { $newY = [math]::Min($currentMap.Count - 1, $playerY + 1); $moved = $true }
                    "S"         { $newY = [math]::Min($currentMap.Count - 1, $playerY + 1); $moved = $true }
                    "Q"         { $running = $false }
                    "Escape"    { Show-SettingsMenu }
                    "J"         { Show-QuestLog }
                    "E"         { Show-NPCInteraction $playerX $playerY }
                    "F5"        { QuickSave-GameState }
                    "F9"        { Show-SaveMenu }
                }
            }

            # Collision: only move if not wall and player actually pressed a movement key
            if ($moved -and $currentMap -and $currentMap[$newY] -and $currentMap[$newY][$newX] -ne '#') {
                $playerX = $newX
                $playerY = $newY
                
                # Update party positions for snake-following (if party system is loaded)
                if ($global:Party) {
                    Update-PartyPositions $playerX $playerY $global:Party
                }
            }
            
            # Clear input buffer to prevent movement lag (only in exploration mode)
            if ($moved) {
                while ([System.Console]::KeyAvailable) {
                    [System.Console]::ReadKey($true) | Out-Null
                }
            }

            # NPC interaction - map-aware hashtable lookup
            $npcHere = Get-NPCAtPosition $playerX $playerY $CurrentMapName
            if ($npcHere) {
                Write-Host "Press E to talk to $($npcHere.Name) ($($npcHere.Char))" -ForegroundColor Yellow
                $keyInput = [System.Console]::ReadKey($true)
                if ($keyInput.Key -eq "E") {
                    Show-NPCDialogueTree $npcHere
                }
            }

            # Map switching: step on a door symbol ('+')
            if ($currentMap -and $currentMap[$playerY] -and $currentMap[$playerY][$playerX] -eq '+') {
                $key = "$CurrentMapName,$playerX,$playerY"
                if ($global:DoorRegistry.ContainsKey($key)) {
                    & $TransitionEffects[$ChosenTransition] $boxWidth $boxHeight
                    $dest = $global:DoorRegistry[$key]
                    $CurrentMapName = $dest.Map
                    $currentMap = $global:Maps[$CurrentMapName]
                    $playerX = $dest.X
                    $playerY = $dest.Y
                    
                    # Move entire party to new map
                    if ($global:Party) {
                        Move-PartyToMap $playerX $playerY $global:Party $CurrentMapName
                    }
                }
            }

            # Randomized dungeon entrance: step on 'R' symbol
            if ($currentMap -and $currentMap[$playerY] -and $currentMap[$playerY][$playerX] -eq 'R') {
                Write-Host "Entering the randomized dungeon..." -ForegroundColor Green
                Start-Sleep -Milliseconds 500
                
                # Generate a new randomized dungeon each time
                $global:RandomizedDungeon = New-RandomizedDungeon
                $global:Maps["RandomizedDungeon"] = $global:RandomizedDungeon
                
                # Add door registry entry for exiting the dungeon
                $exitKey = "RandomizedDungeon,$($global:RandomDungeonEntrance.X),$($global:RandomDungeonEntrance.Y)"
                $global:DoorRegistry[$exitKey] = @{ Map = "Town"; X = 70; Y = 26 }
                
                # Transition to the dungeon
                & $TransitionEffects[$ChosenTransition] $boxWidth $boxHeight
                $CurrentMapName = "RandomizedDungeon"
                $currentMap = $global:Maps[$CurrentMapName]
                $playerX = $global:RandomDungeonEntrance.X
                $playerY = $global:RandomDungeonEntrance.Y
                
                # Move entire party to randomized dungeon
                if ($global:Party) {
                    Move-PartyToMap $playerX $playerY $global:Party $CurrentMapName
                }
            }

            # Random battle trigger in Dungeon (with cooldown)
            if ($CurrentMapName -eq "Dungeon" -and $battleCooldown -le 0) {
                $encounterRoll = Get-Random -Minimum 1 -Maximum 21
                if ($encounterRoll -eq 1) {
                    # Clear input buffer before entering battle to prevent movement spill-over
                    while ([System.Console]::KeyAvailable) {
                        [System.Console]::ReadKey($true) | Out-Null
                    }
                    $battleMode = $true
                    [System.Console]::Clear()
                    continue
                }
            }
            
            # Decrease battle cooldown
            if ($battleCooldown -gt 0) {
                $battleCooldown--
            }
        } catch {
            $errorMsg = $_.Exception.Message
        }

        if ($errorMsg) {
            [System.Console]::SetCursorPosition(0, $boxHeight + 4)
            Write-Host "ERROR: $errorMsg" -ForegroundColor Red
            $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
            $logPath = Join-Path $scriptDir 'error.log'
            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            if (!(Test-Path $logPath)) { New-Item -Path $logPath -ItemType File -Force | Out-Null }
            
            # Try multiple times to write to log in case of file lock
            $attempts = 0
            $maxAttempts = 3
            while ($attempts -lt $maxAttempts) {
                try {
                    "[$timestamp] $errorMsg" | Add-Content -Path $logPath -ErrorAction Stop
                    break
                } catch {
                    $attempts++
                    if ($attempts -ge $maxAttempts) {
                        # If we can't write to the log, just write to console
                        Write-Host "ERROR (log write failed): $errorMsg" -ForegroundColor Red
                    } else {
                        Start-Sleep -Milliseconds 100
                    }
                }
            }
        }

        Start-Sleep -Milliseconds 20
    }
    # End of while ($running) loop
    
    # Move cursor below the box for end message
    [System.Console]::SetCursorPosition(0, $boxHeight + 3)
    Write-Host "`nThanks for playing!"
}
# End of main try block
catch {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $logPath = Join-Path $scriptDir 'error.log'
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $startupError = $_.Exception.Message
    if (!(Test-Path $logPath)) { New-Item -Path $logPath -ItemType File -Force | Out-Null }
    
    # Try multiple times to write to log in case of file lock
    $attempts = 0
    $maxAttempts = 3
    while ($attempts -lt $maxAttempts) {
        try {
            "[$timestamp] STARTUP ERROR: $startupError" | Add-Content -Path $logPath -ErrorAction Stop
            break
        } catch {
            $attempts++
            if ($attempts -ge $maxAttempts) {
                # If we can't write to the log, just continue
                break
            } else {
                Start-Sleep -Milliseconds 100
            }
        }
    }
    Write-Host "Startup ERROR: $startupError" -ForegroundColor Red
}