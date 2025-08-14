# =============================================================================
# ENHANCED ARROW-BASED ENEMY TARGETING SYSTEM - Fixed Version
# =============================================================================
# Shows targeting arrows in the battle area, fixes enemy deletion bugs

# Main targeting function - shows arrows over enemies in battle area
function Show-BattleArrowTargeting {
    param($enemies, $boxWidth, $boxHeight)
    
    # CRITICAL: Filter to only alive enemies and ensure clean array
    $aliveEnemies = @($enemies | Where-Object { $_ -ne $null -and $_.HP -gt 0 })
    
    if ($aliveEnemies.Count -eq 0) {
        Write-Host "No enemies to target!" -ForegroundColor Red
        Start-Sleep -Milliseconds 1500
        return $null
    }
    
    if ($aliveEnemies.Count -eq 1) {
        return $aliveEnemies[0]
    }
    
    $selectedIndex = 0
    $maxIndex = $aliveEnemies.Count - 1
    
    while ($true) {
        # Clear and redraw battle with targeting arrows
        [System.Console]::Clear()
        Draw-EnhancedCombatViewportWithTargeting $enemies $aliveEnemies[$selectedIndex] $boxWidth $boxHeight
        
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

# Draw battle viewport with targeting arrows over enemies
function Draw-EnhancedCombatViewportWithTargeting {
    param($allEnemies, $targetedEnemy, $boxWidth, $boxHeight)
    
    # Draw normal battle display first
    Draw-EnhancedCombatViewport $allEnemies $boxWidth $boxHeight
    
    # Add targeting arrows over the selected enemy
    if ($targetedEnemy) {
        Add-BattleTargetingArrows $allEnemies $targetedEnemy $boxWidth $boxHeight
    }
}

# Add targeting arrows in the battle area above enemies
function Add-BattleTargetingArrows {
    param($allEnemies, $targetedEnemy, $boxWidth, $boxHeight)
    
    # Get layout to find enemy positions
    $layout = Calculate-BattleLayout $allEnemies $boxWidth $boxHeight
    
    foreach ($row in $layout.Rows) {
        # Only check alive enemies in this row
        $aliveRowEnemies = @($row.Enemies | Where-Object { $_ -ne $null -and $_.HP -gt 0 })
        
        for ($i = 0; $i -lt $aliveRowEnemies.Count; $i++) {
            $enemy = $aliveRowEnemies[$i]
            
            # Check if this is the targeted enemy (compare by name and HP for uniqueness)
            if ($enemy.Name -eq $targetedEnemy.Name -and $enemy.HP -eq $targetedEnemy.HP) {
                
                # Calculate enemy center position
                $enemySpacing = [math]::Floor($boxWidth / $aliveRowEnemies.Count)
                $enemyCenter = ($i * $enemySpacing) + [math]::Floor($enemySpacing / 2)
                
                # Draw targeting arrow above enemy
                $arrowY = [math]::Max(1, $row.StartY - 1)  # Just above the enemy
                
                try {
                    [System.Console]::SetCursorPosition($enemyCenter, $arrowY)
                    Write-Host "▼" -ForegroundColor Yellow -NoNewline
                    
                    # Optional: Add side arrows for extra visibility
                    if ($enemyCenter -gt 2) {
                        [System.Console]::SetCursorPosition($enemyCenter - 2, $arrowY)
                        Write-Host "►" -ForegroundColor Yellow -NoNewline
                    }
                    if ($enemyCenter -lt ($boxWidth - 2)) {
                        [System.Console]::SetCursorPosition($enemyCenter + 2, $arrowY)
                        Write-Host "◄" -ForegroundColor Yellow -NoNewline
                    }
                } catch {
                    # If positioning fails, continue silently
                }
                
                return  # Found and marked the target
            }
        }
    }
}

# Clean up enemy array to prevent null reference issues
function Clean-EnemyArray {
    param($enemies)
    
    # Return only non-null, alive enemies
    return @($enemies | Where-Object { $_ -ne $null -and $_.HP -gt 0 })
}

# Safe enemy filtering that prevents buffer issues
function Get-AliveEnemiesForTargeting {
    param($enemies)
    
    if (-not $enemies -or $enemies.Count -eq 0) {
        return @()
    }
    
    $aliveEnemies = @()
    foreach ($enemy in $enemies) {
        if ($enemy -ne $null -and $enemy.HP -ne $null -and $enemy.HP -gt 0) {
            $aliveEnemies += $enemy
        }
    }
    
    return $aliveEnemies
}
