# =============================================================================
# WATER EFFECT DEMO - Asynchronous Character Animation in PowerShell
# =============================================================================

# Water animation state
$script:WaterFrame = 0
$script:LastWaterUpdate = Get-Date

# Function to get water color based on frame and position
function Get-WaterColor {
    param([int]$X, [int]$Y, [int]$Frame)
    
    # Alternate colors based on position and frame for wave effect
    $offset = ($X + $Y + $Frame) % 4
    switch ($offset) {
        0 { return "DarkBlue" }
        1 { return "Blue" }
        2 { return "Cyan" }
        3 { return "DarkCyan" }
    }
}

# Simple demo map with water
$DemoMap = @(
    "####################",
    "#..................#",
    "#...~~~~~~~~~~~~~~~#",
    "#...~~~~~~~~~~~~~~~#",
    "#...~~~~~~~~~~~~~~~#",
    "#..................#",
    "#......@...........#",
    "#..................#",
    "#...~~~~~~~~~~~~~~~#",
    "#...~~~~~~~~~~~~~~~#",
    "#...~~~~~~~~~~~~~~~#",
    "#..................#",
    "####################"
)

# Demo function
function Show-WaterEffectDemo {
    Clear-Host
    Write-Host "Water Effect Demo - Press 'q' to quit" -ForegroundColor Yellow
    Write-Host "Watch the water animate automatically!" -ForegroundColor Green
    Write-Host ""
    
    $running = $true
    while ($running) {
        # Update water animation every 300ms
        if (((Get-Date) - $script:LastWaterUpdate).TotalMilliseconds -gt 300) {
            $script:WaterFrame = ($script:WaterFrame + 1) % 8
            $script:LastWaterUpdate = Get-Date
        }
        
        # Position cursor at top of map
        [Console]::SetCursorPosition(0, 3)
        
        # Render map with animated water
        for ($y = 0; $y -lt $DemoMap.Count; $y++) {
            $row = $DemoMap[$y]
            for ($x = 0; $x -lt $row.Length; $x++) {
                $char = $row[$x]
                if ($char -eq '~') {
                    # Animated water
                    $color = Get-WaterColor $x $y $script:WaterFrame
                    Write-Host '~' -ForegroundColor $color -NoNewline
                } else {
                    # Static elements
                    $color = switch ($char) {
                        '#' { "DarkGray" }
                        '@' { "White" }
                        default { "Gray" }
                    }
                    Write-Host $char -ForegroundColor $color -NoNewline
                }
            }
            Write-Host ""  # New line
        }
        
        Write-Host ""
        Write-Host "Frame: $script:WaterFrame" -ForegroundColor Yellow
        
        # Check for quit input (non-blocking)
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.KeyChar -eq 'q') {
                $running = $false
            }
        }
        
        # Small delay to prevent excessive CPU usage
        Start-Sleep -Milliseconds 50
    }
    
    Clear-Host
    Write-Host "Demo ended!" -ForegroundColor Green
}

# Run the demo
Write-Host "Starting Water Effect Demo..." -ForegroundColor Cyan
Show-WaterEffectDemo
