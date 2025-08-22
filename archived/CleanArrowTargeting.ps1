# =======    # CRITICAL: Filter to only alive enemies and ensure clean array
    $aliveEnemies = @($enemies | Where-Object { $null -ne $_ -and $_.HP -gt 0 })
    
    if ($aliveEnemies.Count -eq 0) {
        Write-Host "No enemies to target!" -ForegroundColor Red
        Start-Sleep -Milliseconds 1500
        return $null
    }
    
    # Always show targeting interface, even for single enemy
    # This ensures the enemy sprite is always drawn
    $selectedIndex = 0
    $maxIndex = $aliveEnemies.Count - 1=======================================================
# CLEAN ARROW-BASED ENEMY TARGETING SYSTEM
# =============================================================================
# Shows ONLY arrow indicators in battle area, keeps all text below

# Main targeting function - minimal visual indicators in battle area
function Show-CleanBattleTargeting {
    param($enemies, $boxWidth, $boxHeight)
    
    # Filter to only alive enemies
    $aliveEnemies = @($enemies | Where-Object { $null -ne $_ -and $_.HP -gt 0 })
    
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

# Add ONLY a simple arrow indicator over the selected enemy
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

# Enhanced enemy array cleanup - preserves living enemies properly
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
