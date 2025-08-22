# =============================================================================
# ARROW-BASED ENEMY TARGETING SYSTEM
# =============================================================================
# Replaces number-based targeting with arrow key navigation

# Simple horizontal enemy selection with arrow keys
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
            if ($i -lt $maxIndex) { 
                $displayLine += "  |  " 
            }
        }
        
        Write-Host $displayLine -ForegroundColor White
        Write-Host ""
        
        # Show selected enemy details
        $selected = $aliveEnemies[$selectedIndex]
        Write-Host "Selected: $($selected.Name) (HP: $($selected.HP)/$($selected.MaxHP))" -ForegroundColor Yellow
        
        # Get input
        $keyPressed = [System.Console]::ReadKey($true)
        
        switch ($keyPressed.Key) {
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
        for ($clear = 0; $clear -lt 8; $clear++) {
            [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop - 1)
            Write-Host (" " * 80)
            [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop - 1)
        }
    }
}
