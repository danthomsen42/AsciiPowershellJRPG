# =============================================================================
# ARROW-BASED ENEMY TARGETING SYSTEM
# =============================================================================
# Replaces number-based targeting with arrow key navigation

# Show enemy selection with arrow-based targeting
function Show-ArrowEnemyTargeting {
    param($enemies, $boxWidth, $boxHeight)
    
    $aliveEnemies = $enemies | Where-Object { $_.HP -gt 0 }
    
    if ($aliveEnemies.Count -eq 0) {
        Write-Host "No enemies to target!" -ForegroundColor Red
        Start-Sleep -Milliseconds 1000
        return $null
    }
    
    if ($aliveEnemies.Count -eq 1) {
        # Auto-select if only one enemy alive
        return $aliveEnemies[0]
    }
    
    $selectedIndex = 0
    $maxIndex = $aliveEnemies.Count - 1
    
    while ($true) {
        # Clear and redraw battle display with targeting overlay
        [System.Console]::Clear()
        Draw-EnhancedCombatViewportWithTargeting $enemies $boxWidth $boxHeight $aliveEnemies[$selectedIndex]
        
        Write-Host ""
        Write-Host "=== TARGET SELECTION ===" -ForegroundColor Yellow
        Write-Host "Use Arrow Keys/WASD to select target, Enter to confirm, Escape to cancel" -ForegroundColor Cyan
        Write-Host ""
        
        # Show selectable enemies with highlight
        for ($i = 0; $i -lt $aliveEnemies.Count; $i++) {
            $enemy = $aliveEnemies[$i]
            $prefix = if ($i -eq $selectedIndex) { ">>> " } else { "    " }
            $color = if ($i -eq $selectedIndex) { "Yellow" } else { "White" }
            Write-Host "$prefix$($enemy.Name) (HP: $($enemy.HP)/$($enemy.MaxHP))" -ForegroundColor $color
        }
        
        # Get input
        $input = [System.Console]::ReadKey($true)
        
        switch ($input.Key) {
            "LeftArrow"  { $selectedIndex = [math]::Max(0, $selectedIndex - 1) }
            "RightArrow" { $selectedIndex = [math]::Min($maxIndex, $selectedIndex + 1) }
            "UpArrow"    { $selectedIndex = [math]::Max(0, $selectedIndex - 1) }
            "DownArrow"  { $selectedIndex = [math]::Min($maxIndex, $selectedIndex + 1) }
            "A"          { $selectedIndex = [math]::Max(0, $selectedIndex - 1) }
            "D"          { $selectedIndex = [math]::Min($maxIndex, $selectedIndex + 1) }
            "W"          { $selectedIndex = [math]::Max(0, $selectedIndex - 1) }
            "S"          { $selectedIndex = [math]::Min($maxIndex, $selectedIndex + 1) }
            "Enter"      { return $aliveEnemies[$selectedIndex] }
            "Escape"     { return $null }
            "Q"          { return $null }
        }
    }
}

# Enhanced combat viewport with targeting overlay
function Draw-EnhancedCombatViewportWithTargeting {
    param($enemies, $boxWidth, $boxHeight, $targetedEnemy)
    
    # Draw the normal battle display
    Draw-EnhancedCombatViewport $enemies $boxWidth $boxHeight
    
    # Add targeting indicators
    if ($targetedEnemy) {
        Add-TargetingIndicators $enemies $targetedEnemy $boxWidth $boxHeight
    }
}

# Add visual targeting indicators (arrows, highlights, etc.)
function Add-TargetingIndicators {
    param($enemies, $targetedEnemy, $boxWidth, $boxHeight)
    
    # Find the targeted enemy's position in the layout
    $aliveEnemies = $enemies | Where-Object { $_.HP -gt 0 }
    $layout = Calculate-BattleLayout $enemies $boxWidth $boxHeight
    
    # Add targeting arrows/indicators based on enemy position
    foreach ($row in $layout.Rows) {
        $rowEnemies = $row.Enemies | Where-Object { $_.HP -gt 0 }
        for ($i = 0; $i -lt $rowEnemies.Count; $i++) {
            $enemy = $rowEnemies[$i]
            if ($enemy.Name -eq $targetedEnemy.Name) {
                # Calculate position for targeting indicator
                $indicatorY = $row.StartY - 1  # Above the enemy
                $enemySpacing = [math]::Floor($boxWidth / $rowEnemies.Count)
                $indicatorX = ($i * $enemySpacing) + [math]::Floor($enemySpacing / 2)
                
                # Draw targeting arrow above enemy
                try {
                    [System.Console]::SetCursorPosition($indicatorX, $indicatorY)
                    Write-Host "▼" -ForegroundColor Yellow -NoNewline
                } catch {
                    # If positioning fails, continue silently
                }
                
                # Optional: Draw targeting arrows to the sides
                try {
                    $enemyMidY = $row.StartY + [math]::Floor($row.Height / 2)
                    [System.Console]::SetCursorPosition(0, $enemyMidY)
                    Write-Host "►" -ForegroundColor Yellow -NoNewline
                    [System.Console]::SetCursorPosition($boxWidth + 1, $enemyMidY)
                    Write-Host "◄" -ForegroundColor Yellow -NoNewline
                } catch {
                    # If positioning fails, continue silently
                }
                
                break
            }
        }
    }
    
    # Move cursor to safe position
    try {
        [System.Console]::SetCursorPosition(0, $boxHeight + 3)
    } catch {
        # If positioning fails, continue silently
    }
}

# Simple horizontal enemy selection (for cases where layout is complex)
function Show-SimpleArrowTargeting {
    param($enemies)
    
    $aliveEnemies = $enemies | Where-Object { $_.HP -gt 0 }
    
    if ($aliveEnemies.Count -eq 0) {
        Write-Host "No enemies to target!" -ForegroundColor Red
        Start-Sleep -Milliseconds 1000
        return $null
    }
    
    if ($aliveEnemies.Count -eq 1) {
        return $aliveEnemies[0]
    }
    
    $selectedIndex = 0
    $maxIndex = $aliveEnemies.Count - 1
    
    while ($true) {
        Write-Host "`n=== SELECT TARGET ===" -ForegroundColor Yellow
        Write-Host "Use Left/Right Arrow Keys or A/D to select, Enter to confirm, Q to cancel" -ForegroundColor Cyan
        Write-Host ""
        
        # Show enemies horizontally with arrow indicator
        $displayLine = ""
        for ($i = 0; $i -lt $aliveEnemies.Count; $i++) {
            $enemy = $aliveEnemies[$i]
            $indicator = if ($i -eq $selectedIndex) { "►" } else { " " }
            $displayLine += "$indicator$($enemy.Name) "
            if ($i -lt $maxIndex) { $displayLine += "  |  " }
        }
        
        Write-Host $displayLine -ForegroundColor White
        Write-Host ""
        
        # Show selected enemy details
        $selected = $aliveEnemies[$selectedIndex]
        Write-Host "Selected: $($selected.Name) (HP: $($selected.HP)/$($selected.MaxHP))" -ForegroundColor Yellow
        
        # Get input
        $input = [System.Console]::ReadKey($true)
        
        switch ($input.Key) {
            "LeftArrow"  { $selectedIndex = [math]::Max(0, $selectedIndex - 1) }
            "RightArrow" { $selectedIndex = [math]::Min($maxIndex, $selectedIndex + 1) }
            "A"          { $selectedIndex = [math]::Max(0, $selectedIndex - 1) }
            "D"          { $selectedIndex = [math]::Min($maxIndex, $selectedIndex + 1) }
            "Enter"      { return $aliveEnemies[$selectedIndex] }
            "Q"          { return $null }
            "Escape"     { return $null }
        }
        
        # Clear previous display for next iteration
        Write-Host "`n`n`n`n" 
        [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop - 8)
    }
}
