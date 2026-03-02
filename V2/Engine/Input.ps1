# Engine/Input.ps1 - Input Handling
# Provides non-blocking and blocking key reading, plus a simple text input function.

# ── Boss Key (Screen Hide) ──────────────────────────────────────────────────────
$Script:BossKeyCode = [ConsoleKey]::F12

function Invoke-BossScreen {
    <#
    .SYNOPSIS
        Clears the screen and displays fake PowerShell output.
        Blocks until the boss key is pressed again, then restores the game.
    #>
    # Save cursor state
    $savedCursorVisible = [Console]::CursorVisible
    [Console]::CursorVisible = $false

    # Clear everything and reset colors to look like a normal PS session
    [Console]::BackgroundColor = [ConsoleColor]::DarkMagenta
    [Console]::ForegroundColor = [ConsoleColor]::White
    [Console]::Clear()
    [Console]::SetCursorPosition(0, 0)

    $user = $env:USERNAME
    if (-not $user) { $user = "User" }

    $fakeOutput = @(
        "Windows PowerShell"
        "Copyright (C) Microsoft Corporation. All rights reserved."
        ""
        "Install the latest PowerShell for new features and improvements! https://aka.ms/PSWindows"
        ""
        "PS C:\Users\$user> Get-WindowsUpdate -Install -AcceptAll"
        "Searching for updates..."
        "Found 3 updates to install."
        ""
        "Installing: KB5034441 - 2024-01 Security Update for Windows (x64)"
        "  [####################] 100% - Installed"
        "Installing: KB5034467 - 2024-01 Cumulative Update for .NET Framework"
        "  [####################] 100% - Installed"
        "Installing: KB5035853 - 2024-03 Cumulative Update for Windows"
        "  [####################] 100% - Installed"
        ""
        "Restart may be required to complete installation."
        ""
        "PS C:\Users\$user> Get-Service | Where-Object {`$_.Status -eq 'Running'} | Select-Object -First 8"
        ""
        "Status   Name               DisplayName"
        "------   ----               -----------"
        "Running  AudioEndpointBu... Windows Audio Endpoint Builder"
        "Running  Audiosrv           Windows Audio"
        "Running  BFE                Base Filtering Engine"
        "Running  BrokerInfrastru... Background Tasks Infrastructure Ser..."
        "Running  CDPSvc             Connected Devices Platform Service"
        "Running  CryptSvc           Cryptographic Services"
        "Running  DcomLaunch         DCOM Server Process Launcher"
        "Running  Dhcp               DHCP Client"
        ""
        "PS C:\Users\$user> _"
    )

    foreach ($line in $fakeOutput) {
        [Console]::WriteLine($line)
    }

    # Block until F12 is pressed again
    while ($true) {
        $k = [Console]::ReadKey($true)
        if ($k.Key -eq $Script:BossKeyCode) { break }
    }

    # Restore game screen
    [Console]::CursorVisible = $savedCursorVisible
    [Console]::BackgroundColor = [ConsoleColor]::Black
    [Console]::ForegroundColor = [ConsoleColor]::Gray
    [Console]::Clear()
    Invoke-ForceFullRedraw
    Invoke-RenderFrame
}

function Test-BossKey {
    <#
    .SYNOPSIS
        Checks if a key press is the boss key. If so, triggers the boss screen
        and returns $true. Otherwise returns $false.
    #>
    param([System.ConsoleKeyInfo]$Key)
    if ($Key.Key -eq $Script:BossKeyCode) {
        Invoke-BossScreen
        return $true
    }
    return $false
}

# ── Core Input Functions ─────────────────────────────────────────────────────────

function Read-GameInput {
    <#
    .SYNOPSIS
        Non-blocking key read. Returns $null if no key is pressed.
        Intercepts boss key (F12).
    #>
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if (Test-BossKey -Key $key) { return $null }
        return $key
    }
    return $null
}

function Wait-ForKey {
    <#
    .SYNOPSIS
        Blocking key read. Waits until a key is pressed and returns it.
        Intercepts boss key (F12) — waits for another key after restore.
    #>
    while ($true) {
        $key = [Console]::ReadKey($true)
        if (-not (Test-BossKey -Key $key)) {
            return $key
        }
    }
}

function Wait-ForMovementKey {
    <#
    .SYNOPSIS
        Waits for a key, then flushes any remaining buffered keys.
        Returns only the LAST directional key pressed, preventing input
        queue buildup from causing the player to slide across the map.
        Intercepts boss key (F12).
    #>
    while ($true) {
        $key = [Console]::ReadKey($true)
        if (Test-BossKey -Key $key) { continue }

        # Drain the input buffer — keep the last non-boss key
        while ([Console]::KeyAvailable) {
            $next = [Console]::ReadKey($true)
            if (-not (Test-BossKey -Key $next)) {
                $key = $next
            }
        }

        return $key
    }
}

function Wait-ForMovementKeyOrAnimation {
    <#
    .SYNOPSIS
        Polls for a key press with a timeout. If a key is pressed, flushes the
        buffer and returns the last key. If the timeout expires (no key pressed),
        returns $null so the game loop re-renders animated tiles.
        Intercepts boss key (F12).
    #>
    param([int]$AnimIntervalMs = 300)

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    while ($sw.ElapsedMilliseconds -lt $AnimIntervalMs) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if (Test-BossKey -Key $key) { continue }
            # Drain remaining buffered keys — keep the last non-boss one
            while ([Console]::KeyAvailable) {
                $next = [Console]::ReadKey($true)
                if (-not (Test-BossKey -Key $next)) {
                    $key = $next
                }
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
    Wait-ForKey | Out-Null
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
        if (Test-BossKey -Key $key) { continue }

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
