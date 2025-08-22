# Test the new SimpleColors system
. ".\SimpleColors.ps1"

# Initialize simple colors for testing
Initialize-SimpleColors

# Add a single green dot at position 2,3 (inside our 5x5 viewport)
Add-SimpleColorRectangle "Town" 2 3 1 1 "Green"

Write-Host "Testing Simple Colors system..."
Write-Host "Added green dot at position 2,3"

# Display current colors
Write-Host "`nCurrent colors in system:"
if ($global:SimpleColors.ContainsKey("Town")) {
    $townColors = $global:SimpleColors["Town"]
    foreach ($pos in $townColors.Keys) {
        Write-Host "Position $pos : $($townColors[$pos])"
    }
} else {
    Write-Host "No colors found for Town map"
}

# Test the Apply-SimpleColors function (mock parameters)
Write-Host "`nTesting Apply-SimpleColors function..."
Write-Host "Clearing screen and drawing test viewport..."

Clear-Host
Write-Host "+-----+"
Write-Host "|.....|"  
Write-Host "|.....|"
Write-Host "|.....|"
Write-Host "|.....|"
Write-Host "+-----+"

# Apply colors to the mock viewport (viewing world coordinates 0-4, 0-4)
Apply-SimpleColors "Town" 0 0 5 5 99 99 @{}

Write-Host "`n`nColor application complete. There should be a green dot at screen position (3,5)."
Write-Host "If you see a green dot in the box above, the color system is working!"
