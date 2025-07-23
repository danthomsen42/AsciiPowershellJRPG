# Transitions.ps1
# Various transition effects for JRPG

function ShowWipeTransition {
    param($boxWidth, $boxHeight)
    # Clockwise border wipe
    for ($x = 0; $x -lt $boxWidth; $x++) {
        [System.Console]::SetCursorPosition($x + 1, 1)
        Write-Host "#" -NoNewline
        Start-Sleep -Milliseconds 10
    }
    for ($y = 1; $y -lt $boxHeight; $y++) {
        [System.Console]::SetCursorPosition($boxWidth, $y + 1)
        Write-Host "#" -NoNewline
        Start-Sleep -Milliseconds 10
    }
    for ($x = $boxWidth - 1; $x -ge 0; $x--) {
        [System.Console]::SetCursorPosition($x + 1, $boxHeight)
        Write-Host "#" -NoNewline
        Start-Sleep -Milliseconds 10
    }
    for ($y = $boxHeight - 1; $y -ge 1; $y--) {
        [System.Console]::SetCursorPosition(1, $y + 1)
        Write-Host "#" -NoNewline
        Start-Sleep -Milliseconds 10
    }
    Start-Sleep -Milliseconds 300
    for ($y = 0; $y -le $boxHeight + 2; $y++) {
        [System.Console]::SetCursorPosition(0, $y)
        Write-Host (" " * ($boxWidth + 2))
    }
}

function ShowFlashTransition {
    param($boxWidth, $boxHeight)
    # Flash the viewport area
    for ($i = 0; $i -lt 3; $i++) {
        for ($y = 0; $y -le $boxHeight + 2; $y++) {
            [System.Console]::SetCursorPosition(0, $y)
            Write-Host ("#" * ($boxWidth + 2))
        }
        Start-Sleep -Milliseconds 100
        for ($y = 0; $y -le $boxHeight + 2; $y++) {
            [System.Console]::SetCursorPosition(0, $y)
            Write-Host (" " * ($boxWidth + 2))
        }
        Start-Sleep -Milliseconds 100
    }
}

function ShowFadeTransition {
    param($boxWidth, $boxHeight)
    # Fade in the viewport area
    for ($step = 1; $step -le $boxHeight + 2; $step++) {
        for ($y = 0; $y -lt $step; $y++) {
            [System.Console]::SetCursorPosition(0, $y)
            Write-Host ("#" * ($boxWidth + 2))
        }
        Start-Sleep -Milliseconds 30
    }
    Start-Sleep -Milliseconds 200
    for ($y = 0; $y -le $boxHeight + 2; $y++) {
        [System.Console]::SetCursorPosition(0, $y)
        Write-Host (" " * ($boxWidth + 2))
    }
}
