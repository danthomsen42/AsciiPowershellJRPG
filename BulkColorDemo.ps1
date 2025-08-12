# Demo: Bulk Color Rectangle Example
# This shows exactly how to color a large section of characters at once

. ".\ColorZones.ps1"

Write-Host "=== BULK COLOR DEMO ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Creating a 10x10 rectangle of green dots from (10,10) to (20,20)..." -ForegroundColor Yellow

# Enable color zones
$global:EnableColorZones = $true

# Add your specific example: rectangle of green dots from (10,10) to (20,20)
Add-ColorRectangle $global:ColorZones["Town"] 10 10 20 20 "." "Green"

Write-Host "Added $($global:ColorZones["Town"].Count) colored positions!" -ForegroundColor Green
Write-Host ""

Write-Host "The ColorZones now contain:" -ForegroundColor Yellow
$count = 0
foreach ($pos in $global:ColorZones["Town"].Keys) {
    $info = $global:ColorZones["Town"][$pos]
    Write-Host "  $pos = '$($info.Char)' in $($info.Color)" -ForegroundColor White
    $count++
    if ($count -gt 5) {
        Write-Host "  ... and $($global:ColorZones["Town"].Count - $count) more positions" -ForegroundColor DarkGray
        break
    }
}

Write-Host ""
Write-Host "OTHER BULK EXAMPLES YOU CAN TRY:" -ForegroundColor Magenta
Write-Host ""

Write-Host "# Create different colored areas:" -ForegroundColor White
Write-Host 'Add-ColorRectangle $global:ColorZones["Town"] 25 10 30 15 "#" "DarkYellow"  # Brown trees' -ForegroundColor DarkYellow
Write-Host 'Add-ColorRectangle $global:ColorZones["Town"] 5 5 8 8 "~" "Blue"            # Blue water pond' -ForegroundColor Blue
Write-Host ""

Write-Host "# Create lines:" -ForegroundColor White  
Write-Host 'Add-ColorLine $global:ColorZones["Town"] 0 5 50 5 "|" "DarkGray"            # Gray wall (horizontal)' -ForegroundColor DarkGray
Write-Host 'Add-ColorLine $global:ColorZones["Town"] 15 0 15 30 "|" "DarkGray"          # Gray wall (vertical)' -ForegroundColor DarkGray
Write-Host ""

Write-Host "# Create borders:" -ForegroundColor White
Write-Host 'Add-ColorBorder $global:ColorZones["Town"] 35 35 45 45 "#" "Red"            # Red fence outline' -ForegroundColor Red

Write-Host ""
Write-Host "Now run the game (.\Display.ps1) to see the green rectangle!" -ForegroundColor Green

Read-Host "Press Enter to continue"
