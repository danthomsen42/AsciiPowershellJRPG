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
