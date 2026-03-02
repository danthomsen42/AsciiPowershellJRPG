# Engine/Renderer.ps1 - Console Rendering Engine
# Uses double-buffered, diff-based rendering for performance.
# Only cells that change between frames are redrawn.

$Script:SCREEN_WIDTH = 120
$Script:SCREEN_HEIGHT = 30

# ── Compiled helper for array fill (PS5.1 has no [Array]::Fill) ──────────────
if (-not ([System.Management.Automation.PSTypeName]'GameArrayHelper').Type) {
    Add-Type -Language CSharp @"
using System;
public static class GameArrayHelper {
    public static void FillChar(char[] arr, char val)  { for (int i = 0; i < arr.Length; i++) arr[i] = val; }
    public static void FillColor(ConsoleColor[] arr, ConsoleColor val) { for (int i = 0; i < arr.Length; i++) arr[i] = val; }
}
"@
}

# Frame buffers - parallel arrays for performance
$Script:CurrentChars = [char[]]::new($Script:SCREEN_WIDTH * $Script:SCREEN_HEIGHT)
$Script:CurrentFgColors = [System.ConsoleColor[]]::new($Script:SCREEN_WIDTH * $Script:SCREEN_HEIGHT)
$Script:CurrentBgColors = [System.ConsoleColor[]]::new($Script:SCREEN_WIDTH * $Script:SCREEN_HEIGHT)
$Script:PreviousChars = [char[]]::new($Script:SCREEN_WIDTH * $Script:SCREEN_HEIGHT)
$Script:PreviousFgColors = [System.ConsoleColor[]]::new($Script:SCREEN_WIDTH * $Script:SCREEN_HEIGHT)
$Script:PreviousBgColors = [System.ConsoleColor[]]::new($Script:SCREEN_WIDTH * $Script:SCREEN_HEIGHT)

function Initialize-Renderer {
    [GameArrayHelper]::FillChar($Script:CurrentChars,     [char]' ')
    [GameArrayHelper]::FillColor($Script:CurrentFgColors, [ConsoleColor]::Gray)
    [GameArrayHelper]::FillColor($Script:CurrentBgColors, [ConsoleColor]::Black)
    # Set previous to NUL to force full first-frame redraw
    [GameArrayHelper]::FillChar($Script:PreviousChars,     [char]0)
    [GameArrayHelper]::FillColor($Script:PreviousFgColors, [ConsoleColor]::Black)
    [GameArrayHelper]::FillColor($Script:PreviousBgColors, [ConsoleColor]::Black)
}

function Set-Cell {
    param(
        [int]$X,
        [int]$Y,
        [char]$Char,
        [ConsoleColor]$FgColor = [ConsoleColor]::Gray,
        [ConsoleColor]$BgColor = [ConsoleColor]::Black
    )
    if ($X -lt 0 -or $X -ge $Script:SCREEN_WIDTH -or $Y -lt 0 -or $Y -ge $Script:SCREEN_HEIGHT) { return }
    $idx = $Y * $Script:SCREEN_WIDTH + $X
    $Script:CurrentChars[$idx] = $Char
    $Script:CurrentFgColors[$idx] = $FgColor
    $Script:CurrentBgColors[$idx] = $BgColor
}

function Set-Text {
    param(
        [int]$X,
        [int]$Y,
        [string]$Text,
        [ConsoleColor]$FgColor = [ConsoleColor]::Gray,
        [ConsoleColor]$BgColor = [ConsoleColor]::Black
    )
    # Inline buffer writes — avoids per-character Set-Cell function call overhead
    $sw = $Script:SCREEN_WIDTH
    if ($Y -lt 0 -or $Y -ge $Script:SCREEN_HEIGHT) { return }
    $rowBase = $Y * $sw
    $len = $Text.Length
    for ($i = 0; $i -lt $len; $i++) {
        $cx = $X + $i
        if ($cx -lt 0 -or $cx -ge $sw) { continue }
        $idx = $rowBase + $cx
        $Script:CurrentChars[$idx]    = $Text[$i]
        $Script:CurrentFgColors[$idx] = $FgColor
        $Script:CurrentBgColors[$idx] = $BgColor
    }
}

function Clear-FrameBuffer {
    # Fast fill using compiled C# helper (PS 5.1 compatible)
    [GameArrayHelper]::FillChar($Script:CurrentChars, [char]' ')
    [GameArrayHelper]::FillColor($Script:CurrentFgColors, [ConsoleColor]::Gray)
    [GameArrayHelper]::FillColor($Script:CurrentBgColors, [ConsoleColor]::Black)
}

function Invoke-RenderFrame {
    # Diff-based rendering with batched writes:
    # Groups consecutive changed cells on the same row that share fg+bg color
    # into a single [Console]::Write(string) call. This massively reduces the
    # number of expensive .NET interop calls from 1-per-cell to 1-per-run.

    $sw = $Script:SCREEN_WIDTH
    $cChars = $Script:CurrentChars
    $cFg    = $Script:CurrentFgColors
    $cBg    = $Script:CurrentBgColors
    $pChars = $Script:PreviousChars
    $pFg    = $Script:PreviousFgColors
    $pBg    = $Script:PreviousBgColors

    for ($y = 0; $y -lt $Script:SCREEN_HEIGHT; $y++) {
        $rowStart = $y * $sw
        $x = 0

        while ($x -lt $sw) {
            $idx = $rowStart + $x

            # Skip unchanged cells
            if ($cChars[$idx] -eq $pChars[$idx] -and
                $cFg[$idx] -eq $pFg[$idx] -and
                $cBg[$idx] -eq $pBg[$idx]) {
                $x++
                continue
            }

            # Found a changed cell - start a batch run
            $runStartX = $x
            $runFg = $cFg[$idx]
            $runBg = $cBg[$idx]
            $sb = [System.Text.StringBuilder]::new(32)
            [void]$sb.Append($cChars[$idx])
            $pChars[$idx] = $cChars[$idx]
            $pFg[$idx]    = $cFg[$idx]
            $pBg[$idx]    = $cBg[$idx]
            $x++

            # Extend the run: include consecutive cells that are EITHER:
            #   (a) changed and same color, OR
            #   (b) unchanged but sandwiched (avoid a SetCursorPosition to skip 1-2 cells)
            while ($x -lt $sw) {
                $idx = $rowStart + $x
                $changed = ($cChars[$idx] -ne $pChars[$idx] -or $cFg[$idx] -ne $pFg[$idx] -or $cBg[$idx] -ne $pBg[$idx])

                if ($changed -and $cFg[$idx] -eq $runFg -and $cBg[$idx] -eq $runBg) {
                    # Same color, extend the run
                    [void]$sb.Append($cChars[$idx])
                    $pChars[$idx] = $cChars[$idx]
                    $pFg[$idx]    = $cFg[$idx]
                    $pBg[$idx]    = $cBg[$idx]
                    $x++
                }
                elseif (-not $changed -and $cFg[$idx] -eq $runFg -and $cBg[$idx] -eq $runBg) {
                    # Unchanged but same color — include it to avoid a gap (cheaper than SetCursorPosition)
                    [void]$sb.Append($cChars[$idx])
                    $x++
                }
                else {
                    break
                }
            }

            # Flush the run
            [Console]::SetCursorPosition($runStartX, $y)
            [Console]::ForegroundColor = $runFg
            [Console]::BackgroundColor = $runBg
            [Console]::Write($sb.ToString())
        }
    }

    # Reset colors
    [Console]::ForegroundColor = [ConsoleColor]::Gray
    [Console]::BackgroundColor = [ConsoleColor]::Black
}

function Invoke-ForceFullRedraw {
    # Invalidate the previous buffer so every cell redraws on next Invoke-RenderFrame
    [GameArrayHelper]::FillChar($Script:PreviousChars, [char]0)
}

# ── UI Drawing Helpers ──────────────────────────────────────────────────────────

function Draw-Box {
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [ConsoleColor]$Color = [ConsoleColor]::White,
        [ConsoleColor]$BgColor = [ConsoleColor]::Black,
        [switch]$Fill
    )
    # Box-drawing characters (Unicode)
    $topLeft     = [char]0x250C  # ┌
    $topRight    = [char]0x2510  # ┐
    $bottomLeft  = [char]0x2514  # └
    $bottomRight = [char]0x2518  # ┘
    $horizontal  = [char]0x2500  # ─
    $vertical    = [char]0x2502  # │

    $sw = $Script:SCREEN_WIDTH
    $sh = $Script:SCREEN_HEIGHT
    $cc = $Script:CurrentChars
    $cf = $Script:CurrentFgColors
    $cb = $Script:CurrentBgColors

    $x2 = $X + $Width - 1
    $y2 = $Y + $Height - 1

    for ($row = $Y; $row -le $y2; $row++) {
        if ($row -lt 0 -or $row -ge $sh) { continue }
        $rowBase = $row * $sw

        for ($col = $X; $col -le $x2; $col++) {
            if ($col -lt 0 -or $col -ge $sw) { continue }
            $idx = $rowBase + $col

            $ch = $null
            if ($row -eq $Y) {
                if ($col -eq $X) { $ch = $topLeft }
                elseif ($col -eq $x2) { $ch = $topRight }
                else { $ch = $horizontal }
            }
            elseif ($row -eq $y2) {
                if ($col -eq $X) { $ch = $bottomLeft }
                elseif ($col -eq $x2) { $ch = $bottomRight }
                else { $ch = $horizontal }
            }
            elseif ($col -eq $X -or $col -eq $x2) {
                $ch = $vertical
            }
            elseif ($Fill) {
                $ch = ' '
            }

            if ($null -ne $ch) {
                $cc[$idx] = $ch
                $cf[$idx] = $Color
                $cb[$idx] = $BgColor
            }
        }
    }
}

function Draw-TextBox {
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [string]$Title = '',
        [string[]]$Lines = @(),
        [ConsoleColor]$BorderColor = [ConsoleColor]::White,
        [ConsoleColor]$TextColor = [ConsoleColor]::Gray,
        [ConsoleColor]$BgColor = [ConsoleColor]::Black
    )

    Draw-Box -X $X -Y $Y -Width $Width -Height $Height -Color $BorderColor -BgColor $BgColor -Fill

    if ($Title) {
        $titleText = " $Title "
        $titleX = $X + [math]::Floor(($Width - $titleText.Length) / 2)
        Set-Text -X $titleX -Y $Y -Text $titleText -FgColor $BorderColor -BgColor $BgColor
    }

    $maxTextWidth = $Width - 2
    for ($i = 0; $i -lt $Lines.Count -and $i -lt ($Height - 2); $i++) {
        $line = $Lines[$i]
        if ($line.Length -gt $maxTextWidth) {
            $line = $line.Substring(0, $maxTextWidth)
        }
        Set-Text -X ($X + 1) -Y ($Y + 1 + $i) -Text $line -FgColor $TextColor -BgColor $BgColor
    }
}

function Draw-SelectionMenu {
    <#
    .SYNOPSIS
        Draws a selection menu and returns the index of the chosen option.
        Arrow keys to navigate, Enter to select.
    #>
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [string]$Title = '',
        [string[]]$Options,
        [ConsoleColor]$BorderColor = [ConsoleColor]::White,
        [ConsoleColor]$TextColor = [ConsoleColor]::Gray,
        [ConsoleColor]$HighlightFg = [ConsoleColor]::Black,
        [ConsoleColor]$HighlightBg = [ConsoleColor]::White,
        [ConsoleColor]$BgColor = [ConsoleColor]::Black,
        [int]$DefaultIndex = 0
    )

    $height = $Options.Count + 2
    $selectedIndex = $DefaultIndex

    while ($true) {
        Draw-Box -X $X -Y $Y -Width $Width -Height $height -Color $BorderColor -BgColor $BgColor -Fill
        if ($Title) {
            $titleText = " $Title "
            $titleX = $X + [math]::Floor(($Width - $titleText.Length) / 2)
            Set-Text -X $titleX -Y $Y -Text $titleText -FgColor $BorderColor -BgColor $BgColor
        }

        for ($i = 0; $i -lt $Options.Count; $i++) {
            $optText = $Options[$i]
            if ($optText.Length -gt ($Width - 4)) {
                $optText = $optText.Substring(0, $Width - 4)
            }
            if ($i -eq $selectedIndex) {
                # Highlighted
                $prefix = "> "
                Set-Text -X ($X + 1) -Y ($Y + 1 + $i) -Text "$prefix$optText" -FgColor $HighlightFg -BgColor $HighlightBg
                # Fill rest of line with highlight
                $remaining = $Width - 2 - $prefix.Length - $optText.Length
                if ($remaining -gt 0) {
                    Set-Text -X ($X + 1 + $prefix.Length + $optText.Length) -Y ($Y + 1 + $i) -Text (' ' * $remaining) -FgColor $HighlightFg -BgColor $HighlightBg
                }
            }
            else {
                Set-Text -X ($X + 1) -Y ($Y + 1 + $i) -Text "  $optText" -FgColor $TextColor -BgColor $BgColor
            }
        }

        Invoke-RenderFrame

        $key = [Console]::ReadKey($true)
        if (Test-BossKey -Key $key) { continue }
        switch ($key.Key) {
            'UpArrow' {
                $selectedIndex--
                if ($selectedIndex -lt 0) { $selectedIndex = $Options.Count - 1 }
            }
            'DownArrow' {
                $selectedIndex++
                if ($selectedIndex -ge $Options.Count) { $selectedIndex = 0 }
            }
            'Enter' {
                return $selectedIndex
            }
        }
    }
}

function Draw-ProgressBar {
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [double]$Percent,        # 0.0 to 1.0
        [ConsoleColor]$FilledColor = [ConsoleColor]::Green,
        [ConsoleColor]$EmptyColor = [ConsoleColor]::DarkGray,
        [ConsoleColor]$BgColor = [ConsoleColor]::Black
    )

    if ($Y -lt 0 -or $Y -ge $Script:SCREEN_HEIGHT) { return }

    $filled = [math]::Floor($Percent * $Width)
    $filled = [math]::Max(0, [math]::Min($Width, $filled))

    $sw = $Script:SCREEN_WIDTH
    $rowBase = $Y * $sw
    $filledChar = [char]0x2588  # █
    $emptyChar  = [char]0x2591  # ░

    for ($i = 0; $i -lt $Width; $i++) {
        $cx = $X + $i
        if ($cx -lt 0 -or $cx -ge $sw) { continue }
        $idx = $rowBase + $cx
        if ($i -lt $filled) {
            $Script:CurrentChars[$idx]    = $filledChar
            $Script:CurrentFgColors[$idx] = $FilledColor
            $Script:CurrentBgColors[$idx] = $BgColor
        }
        else {
            $Script:CurrentChars[$idx]    = $emptyChar
            $Script:CurrentFgColors[$idx] = $EmptyColor
            $Script:CurrentBgColors[$idx] = $BgColor
        }
    }
}
