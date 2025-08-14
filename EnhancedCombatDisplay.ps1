# =============================================================================
# ENHANCED COMBAT DISPLAY - Supports Multiple Enemy Sizes and Layouts
# =============================================================================
# Designed for 80x25 battle viewport with proper sprite positioning

# Enhanced combat viewport that handles different enemy sizes and layouts
function Draw-EnhancedCombatViewport {
    param($enemies, $boxWidth, $boxHeight)
    
    # Clear screen and draw border
    [System.Console]::SetCursorPosition(0, 0)
    Write-Host ("+" + ("-" * $boxWidth) + "+") -ForegroundColor Yellow
    
    # Analyze enemy composition and choose layout
    $layout = Calculate-BattleLayout $enemies $boxWidth $boxHeight
    
    # Render enemies using calculated layout
    Render-EnemiesWithLayout $enemies $layout $boxWidth $boxHeight
    
    # Draw bottom border
    Write-Host ("+" + ("-" * $boxWidth) + "+") -ForegroundColor Yellow
}

# Calculate optimal layout for given enemies
function Calculate-BattleLayout {
    param($enemies, $boxWidth, $boxHeight)
    
    # Use enemies as-is (they should already be cleaned by the caller)
    $aliveEnemies = $enemies
    
    $smallEnemies = @($aliveEnemies | Where-Object { $_.Size -eq "Small" })
    $mediumEnemies = @($aliveEnemies | Where-Object { $_.Size -eq "Medium" })
    $largeEnemies = @($aliveEnemies | Where-Object { $_.Size -eq "Large" })
    $bossEnemies = @($aliveEnemies | Where-Object { $_.Size -eq "Boss" })
    
    $layout = @{
        Rows = @()
        TotalHeight = 0
    }
    
    # Boss enemies get full screen
    if ($bossEnemies.Count -gt 0) {
        $layout.Rows += @{
            Type = "Boss"
            Enemies = @($bossEnemies[0])  # Only one boss at a time
            StartY = 2
            Height = 15
        }
        $layout.TotalHeight = 15
        return $layout
    }
    
    $currentY = 2  # Start after border and header
    $availableHeight = $boxHeight - 3  # Account for borders
    
    # Large enemies get their own row (up to 2 across)
    if ($largeEnemies.Count -gt 0) {
        $largeRow = @{
            Type = "Large"
            Enemies = @($largeEnemies | Select-Object -First 2)  # Max 2 large enemies
            StartY = $currentY
            Height = 12
        }
        $layout.Rows += $largeRow
        $currentY += 12
        $availableHeight -= 12
    }
    
    # Medium enemies (up to 3 across per row)
    if ($mediumEnemies.Count -gt 0 -and $availableHeight -ge 8) {
        $mediumRow = @{
            Type = "Medium"
            Enemies = @($mediumEnemies | Select-Object -First 3)  # Max 3 medium enemies
            StartY = $currentY
            Height = 8
        }
        $layout.Rows += $mediumRow
        $currentY += 8
        $availableHeight -= 8
    }
    
    # Small enemies (up to 5 across per row)
    if ($smallEnemies.Count -gt 0 -and $availableHeight -ge 5) {
        $smallRow = @{
            Type = "Small"
            Enemies = @($smallEnemies | Select-Object -First 5)  # Max 5 small enemies
            StartY = $currentY
            Height = 5
        }
        $layout.Rows += $smallRow
        $currentY += 5
        $availableHeight -= 5
        
        # Add second row of small enemies if space and enemies available
        $remainingSmall = @($smallEnemies | Select-Object -Skip 5)
        if ($remainingSmall.Count -gt 0 -and $availableHeight -ge 5) {
            $smallRow2 = @{
                Type = "Small"
                Enemies = @($remainingSmall | Select-Object -First 5)
                StartY = $currentY
                Height = 5
            }
            $layout.Rows += $smallRow2
        }
    }
    
    return $layout
}

# Render enemies according to calculated layout
function Render-EnemiesWithLayout {
    param($enemies, $layout, $boxWidth, $boxHeight)
    
    # Show only alive enemies at top
    Write-Host "Enemies: " -NoNewline -ForegroundColor Red
    $aliveEnemies = $enemies  # Use enemies as-is (should already be cleaned)
    foreach ($enemy in $aliveEnemies) {
        $enemyText = "$($enemy.Name) "
        if ($enemyText.Length -lt ($boxWidth - 10)) {
            Write-Host $enemyText -NoNewline -ForegroundColor White
        }
    }
    Write-Host ""  # New line after enemy list
    
    # Render each row according to layout
    foreach ($row in $layout.Rows) {
        switch ($row.Type) {
            "Boss" {
                Render-BossRow $row.Enemies $row.StartY $boxWidth
            }
            "Large" {
                Render-LargeRow $row.Enemies $row.StartY $boxWidth
            }
            "Medium" {
                Render-MediumRow $row.Enemies $row.StartY $boxWidth
            }
            "Small" {
                Render-SmallRow $row.Enemies $row.StartY $boxWidth
            }
        }
    }
    
    # Fill remaining space if needed
    $lastRow = if ($layout.Rows.Count -gt 0) { $layout.Rows[-1] } else { @{ StartY = 2; Height = 0 } }
    $fillStart = $lastRow.StartY + $lastRow.Height
    $fillEnd = $boxHeight - 1
    
    for ($y = $fillStart; $y -lt $fillEnd; $y++) {
        Write-Host ("|" + (" " * $boxWidth) + "|") -ForegroundColor DarkGray
    }
}

# Render boss enemies (60w x 15h, centered)
function Render-BossRow {
    param($enemies, $startY, $boxWidth)
    
    $boss = $enemies[0]  # Only one boss
    $art = $boss.Art
    
    # Calculate centering
    $maxWidth = ($art | Measure-Object -Property Length -Maximum).Maximum
    $startX = [math]::Max(0, [math]::Floor(($boxWidth - $maxWidth) / 2))
    
    for ($i = 0; $i -lt $art.Count; $i++) {
        [System.Console]::SetCursorPosition(0, $startY + $i)
        $row = "|"
        
        # Add boss art centered
        $artLine = $art[$i]
        $padLeft = " " * $startX
        $padRight = " " * [math]::Max(0, ($boxWidth - $startX - $artLine.Length))
        $row += $padLeft + $artLine + $padRight + "|"
        
        # Apply color based on enemy status
        Write-Host $row -ForegroundColor Red  # All enemies should be alive at this point
    }
}

# Render large enemies (up to 2 across, variable width)
function Render-LargeRow {
    param($enemies, $startY, $boxWidth)
    
    $enemyCount = $enemies.Count
    
    # Get the actual width of the first enemy's art
    $firstEnemyMaxWidth = ($enemies[0].Art | Measure-Object -Property Length -Maximum).Maximum
    
    # For single enemy, center it. For multiple enemies, distribute evenly
    if ($enemyCount -eq 1) {
        $spacing = $boxWidth
        $centerOffset = [math]::Floor(($boxWidth - $firstEnemyMaxWidth) / 2)
    } else {
        $spacing = [math]::Floor($boxWidth / $enemyCount)
        $centerOffset = 0
    }
    
    # Render each row of the large enemies
    for ($artRow = 0; $artRow -lt 12; $artRow++) {
        [System.Console]::SetCursorPosition(0, $startY + $artRow)
        $row = "|"
        
        for ($enemyIndex = 0; $enemyIndex -lt $enemyCount; $enemyIndex++) {
            $enemy = $enemies[$enemyIndex]
            $artLine = if ($artRow -lt $enemy.Art.Count) { $enemy.Art[$artRow] } else { " " * $firstEnemyMaxWidth }
            
            # Position enemy art
            if ($enemyCount -eq 1) {
                # Center single enemy
                $row += " " * $centerOffset + $artLine
            } else {
                # Multiple enemies - distribute evenly
                $startX = $enemyIndex * $spacing
                $padLeft = " " * [math]::Max(0, $startX - $row.Length + 1)
                $row += $padLeft + $artLine
                
                # Add spacing between enemies
                if ($enemyIndex -lt ($enemyCount - 1)) {
                    $enemyMaxWidth = ($enemy.Art | Measure-Object -Property Length -Maximum).Maximum
                    $row += " " * [math]::Max(0, ($spacing - $enemyMaxWidth))
                }
            }
        }
        
        # Pad to full width
        $row += " " * [math]::Max(0, ($boxWidth - $row.Length + 1)) + "|"
        
        # Apply coloring based on enemy status
        $color = "White"  # All enemies should be alive at this point
        Write-Host $row -ForegroundColor $color
    }
}

# Render medium enemies (25w x 8h, up to 3 across)
function Render-MediumRow {
    param($enemies, $startY, $boxWidth)
    
    $enemyCount = $enemies.Count
    
    # For single enemy, center it. For multiple enemies, distribute evenly
    if ($enemyCount -eq 1) {
        $spacing = $boxWidth
        $centerOffset = [math]::Floor(($boxWidth - 25) / 2)  # Center the 25-wide enemy
    } else {
        $spacing = [math]::Floor($boxWidth / $enemyCount)
        $centerOffset = 0
    }
    
    # Render each row of the medium enemies
    for ($artRow = 0; $artRow -lt 8; $artRow++) {
        [System.Console]::SetCursorPosition(0, $startY + $artRow)
        $row = "|"
        
        for ($enemyIndex = 0; $enemyIndex -lt $enemyCount; $enemyIndex++) {
            $enemy = $enemies[$enemyIndex]
            $artLine = if ($artRow -lt $enemy.Art.Count) { $enemy.Art[$artRow] } else { " " * 25 }
            
            # Position enemy art
            if ($enemyCount -eq 1) {
                # Center single enemy
                $row += " " * $centerOffset + $artLine
            } else {
                # Multiple enemies - distribute evenly
                $startX = $enemyIndex * $spacing
                $padLeft = " " * [math]::Max(0, $startX - $row.Length + 1)
                $row += $padLeft + $artLine
                
                # Add spacing between enemies
                if ($enemyIndex -lt ($enemyCount - 1)) {
                    $row += " " * [math]::Max(0, ($spacing - 25))
                }
            }
        }
        
        # Pad to full width
        $row += " " * [math]::Max(0, ($boxWidth - $row.Length + 1)) + "|"
        
        # Apply coloring based on enemy status
        $color = "White"  # All enemies should be alive at this point
        Write-Host $row -ForegroundColor $color
    }
}

# Render small enemies (15w x 5h, up to 5 across)
function Render-SmallRow {
    param($enemies, $startY, $boxWidth)
    
    $enemyCount = $enemies.Count
    
    # For single enemy, center it. For multiple enemies, distribute evenly
    if ($enemyCount -eq 1) {
        $spacing = $boxWidth
        $centerOffset = [math]::Floor(($boxWidth - 15) / 2)  # Center the 15-wide enemy
    } else {
        $spacing = [math]::Floor($boxWidth / $enemyCount)
        $centerOffset = 0
    }
    
    # Render each row of the small enemies
    for ($artRow = 0; $artRow -lt 5; $artRow++) {
        [System.Console]::SetCursorPosition(0, $startY + $artRow)
        $row = "|"
        
        for ($enemyIndex = 0; $enemyIndex -lt $enemyCount; $enemyIndex++) {
            $enemy = $enemies[$enemyIndex]
            $artLine = if ($artRow -lt $enemy.Art.Count) { $enemy.Art[$artRow] } else { " " * 15 }
            
            # Position enemy art
            if ($enemyCount -eq 1) {
                # Center single enemy
                $row += " " * $centerOffset + $artLine
            } else {
                # Multiple enemies - distribute evenly
                $startX = $enemyIndex * $spacing
                $padLeft = " " * [math]::Max(0, $startX - $row.Length + 1)
                $row += $padLeft + $artLine
                
                # Add spacing between enemies
                if ($enemyIndex -lt ($enemyCount - 1)) {
                    $row += " " * [math]::Max(0, ($spacing - 15))
                }
            }
        }
        
        # Pad to full width
        $row += " " * [math]::Max(0, ($boxWidth - $row.Length + 1)) + "|"
        
        # Apply coloring based on enemy status
        $color = "White"  # All enemies should be alive at this point
        Write-Host $row -ForegroundColor $color
    }
}
