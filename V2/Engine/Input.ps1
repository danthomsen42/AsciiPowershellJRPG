# Engine/Input.ps1 - Input Handling
# Provides non-blocking and blocking key reading, plus a simple text input function.

function Read-GameInput {
    <#
    .SYNOPSIS
        Non-blocking key read. Returns $null if no key is pressed.
    #>
    if ([Console]::KeyAvailable) {
        return [Console]::ReadKey($true)
    }
    return $null
}

function Wait-ForKey {
    <#
    .SYNOPSIS
        Blocking key read. Waits until a key is pressed and returns it.
    #>
    return [Console]::ReadKey($true)
}

function Wait-ForMovementKey {
    <#
    .SYNOPSIS
        Waits for a key, then flushes any remaining buffered keys.
        Returns only the LAST directional key pressed, preventing input
        queue buildup from causing the player to slide across the map.
    #>
    $key = [Console]::ReadKey($true)

    # Drain the input buffer — keep the last key
    while ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
    }

    return $key
}

function Wait-ForMovementKeyOrAnimation {
    <#
    .SYNOPSIS
        Polls for a key press with a timeout. If a key is pressed, flushes the
        buffer and returns the last key. If the timeout expires (no key pressed),
        returns $null so the game loop re-renders animated tiles.
        Animation frame is time-based (computed in Render-Map), so tiles animate
        smoothly regardless of whether the player is pressing keys or idle.
    #>
    param([int]$AnimIntervalMs = 300)

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    while ($sw.ElapsedMilliseconds -lt $AnimIntervalMs) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            # Drain remaining buffered keys — keep the last one
            while ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
            }
            $sw.Stop()
            return $key
        }
        # Sleep ~16ms between polls (~60 checks/sec) to avoid CPU spin
        [System.Threading.Thread]::Sleep(16)
    }

    $sw.Stop()
    return $null
}

function Wait-ForConfirm {
    <#
    .SYNOPSIS
        Shows a prompt and waits for any key press.
    #>
    param([string]$Message = "Press any key to continue...")
    Set-Text -X 1 -Y ($Script:SCREEN_HEIGHT - 1) -Text $Message -FgColor ([ConsoleColor]::Yellow)
    Invoke-RenderFrame
    [Console]::ReadKey($true) | Out-Null
}

function Read-TextInput {
    <#
    .SYNOPSIS
        Simple inline text input. Shows cursor and allows typing.
        Enter confirms, Escape cancels (returns empty), Backspace deletes.
    #>
    param(
        [int]$X,
        [int]$Y,
        [int]$MaxLength = 16,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )

    $text = ""
    [Console]::CursorVisible = $true
    [Console]::SetCursorPosition($X, $Y)

    # Show underscore placeholder
    for ($i = 0; $i -lt $MaxLength; $i++) {
        Set-Cell -X ($X + $i) -Y $Y -Char '_' -FgColor ([ConsoleColor]::DarkGray)
    }
    Invoke-RenderFrame
    [Console]::SetCursorPosition($X, $Y)

    while ($true) {
        $key = [Console]::ReadKey($true)

        if ($key.Key -eq 'Enter') {
            break
        }
        elseif ($key.Key -eq 'Escape') {
            $text = ""
            break
        }
        elseif ($key.Key -eq 'Backspace') {
            if ($text.Length -gt 0) {
                $text = $text.Substring(0, $text.Length - 1)
                Set-Cell -X ($X + $text.Length) -Y $Y -Char '_' -FgColor ([ConsoleColor]::DarkGray)
                Invoke-RenderFrame
                [Console]::SetCursorPosition($X + $text.Length, $Y)
            }
        }
        elseif ($text.Length -lt $MaxLength -and -not [char]::IsControl($key.KeyChar)) {
            $text += $key.KeyChar
            Set-Cell -X ($X + $text.Length - 1) -Y $Y -Char $key.KeyChar -FgColor $Color
            Invoke-RenderFrame
            [Console]::SetCursorPosition($X + $text.Length, $Y)
        }
    }

    [Console]::CursorVisible = $false
    return $text
}
