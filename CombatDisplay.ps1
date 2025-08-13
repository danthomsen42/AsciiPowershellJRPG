# Combat Display Functions

# Draw the combat viewport in the same box area
function Draw-CombatViewport {
    param($enemyArt, $enemyName, $boxWidth, $boxHeight)
    [System.Console]::SetCursorPosition(0, 0)
    Write-Host ("+" + ("-" * $boxWidth) + "+") -ForegroundColor Yellow
    Write-Host ("Enemy: $enemyName") -ForegroundColor Red
    $artHeight = $enemyArt.Count
    $artWidth = ($enemyArt | Measure-Object -Property Length -Maximum).Maximum
    $startY = [math]::Max(0, [math]::Floor(($boxHeight - $artHeight) / 2))
    $startX = [math]::Max(0, [math]::Floor(($boxWidth - $artWidth) / 2))
    for ($y = 0; $y -lt $boxHeight; $y++) {
        $row = "|"
        if ($y -ge $startY -and $y -lt ($startY + $artHeight)) {
            $artLine = $enemyArt[$y - $startY]
            $padLeft = " " * $startX
            $padRight = " " * ($boxWidth - $startX - $artLine.Length)
            $row += $padLeft + $artLine + $padRight
        } else {
            $row += " " * $boxWidth
        }
        $row += "|"
        Write-Host $row -ForegroundColor DarkGray
    }
    Write-Host ("+" + ("-" * $boxWidth) + "+") -ForegroundColor Yellow
}

# Draw multiple enemies in combat viewport
function Draw-MultiEnemyCombatViewport {
    param($enemies, $boxWidth, $boxHeight)
    [System.Console]::SetCursorPosition(0, 0)
    Write-Host ("+" + ("-" * $boxWidth) + "+") -ForegroundColor Yellow
    
    # Display enemies horizontally with simple representation
    $enemyCount = $enemies.Count
    $aliveEnemies = $enemies | Where-Object { $_.HP -gt 0 }
    
    # Top section shows enemy names
    $enemyLine = "Enemies: "
    foreach ($enemy in $enemies) {
        $status = if ($enemy.HP -le 0) { " [KO]" } else { "" }
        $enemyLine += "$($enemy.Name)$status  "
    }
    Write-Host $enemyLine.Substring(0, [math]::Min($enemyLine.Length, $boxWidth - 2)) -ForegroundColor Red
    
    # Middle section shows simple enemy representations
    for ($y = 1; $y -lt $boxHeight - 1; $y++) {
        $row = "|"
        if ($y -eq [math]::Floor($boxHeight / 2)) {
            # Show simple enemy symbols in the middle row
            $enemySymbols = ""
            for ($i = 0; $i -lt $enemyCount; $i++) {
                $symbol = if ($enemies[$i].HP -le 0) { "[X]" } else { "[$($i + 1)]" }
                $enemySymbols += "$symbol  "
            }
            $padLeft = [math]::Max(0, [math]::Floor(($boxWidth - $enemySymbols.Length) / 2))
            $padRight = [math]::Max(0, $boxWidth - $padLeft - $enemySymbols.Length)
            $row += (" " * $padLeft) + $enemySymbols + (" " * $padRight)
        } else {
            $row += " " * $boxWidth
        }
        $row += "|"
        Write-Host $row -ForegroundColor DarkGray
    }
    Write-Host ("+" + ("-" * $boxWidth) + "+") -ForegroundColor Yellow
}

# Function to display combat messages in a fixed area
function Write-CombatMessage {
    param($Message, $Color = "White", $CurrentTurn = "")
    
    # Ultra-simple approach: just write the message without any positioning
    # This prevents scrolling completely
    if ($CurrentTurn -ne "") {
        Write-Host ">>> $CurrentTurn <<< $Message" -ForegroundColor $Color
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

# Function to display target selection menu for multiple enemies
function Show-EnemyTargetSelection {
    param($enemies)
    
    Write-Host "`nSelect target:" -ForegroundColor Cyan
    $aliveEnemies = @()
    $targetIndex = 1
    
    foreach ($enemy in $enemies) {
        if ($enemy.HP -gt 0) {
            $hpDisplay = [math]::Max(0, $enemy.HP)
            Write-Host "[$targetIndex] $($enemy.Name) (HP: $hpDisplay/$($enemy.MaxHP))" -ForegroundColor Yellow
            $aliveEnemies += @{ Index = $targetIndex; Enemy = $enemy }
            $targetIndex++
        }
    }
    
    if ($aliveEnemies.Count -eq 0) {
        Write-Host "No valid targets!" -ForegroundColor Red
        return $null
    }
    
    Write-Host "[0] Cancel" -ForegroundColor Gray
    Write-Host "Choose target (1-$($aliveEnemies.Count)): " -NoNewline -ForegroundColor White
    
    $targetChoice = [System.Console]::ReadKey($true)
    $targetNum = [int]$targetChoice.KeyChar - 48  # Convert to number
    
    if ($targetNum -eq 0) {
        return $null  # Cancel
    } elseif ($targetNum -ge 1 -and $targetNum -le $aliveEnemies.Count) {
        return $aliveEnemies[$targetNum - 1].Enemy
    } else {
        Write-Host "`nInvalid target selection!" -ForegroundColor Red
        Start-Sleep -Milliseconds 1000
        return $null
    }
}
