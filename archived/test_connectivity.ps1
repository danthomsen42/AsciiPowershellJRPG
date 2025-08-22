# Test script for procedural map connectivity
. .\ProceduralMaps.ps1

Write-Host "Testing procedural map generation..."

try {
    $map = New-RoomBasedMap -Width 40 -Height 20
    Write-Host "Map generated successfully!"
    Write-Host "Map has $($map.Count) rows"
    
    # Count rooms and corridors
    $roomCount = 0
    $corridorCount = 0
    foreach ($row in $map) {
        for ($i = 0; $i -lt $row.Length; $i++) {
            if ($row[$i] -eq '.') { $corridorCount++ }
        }
    }
    
    Write-Host "Found $corridorCount floor tiles"
    
    # Display first few rows
    Write-Host "First 10 rows:"
    for ($i = 0; $i -lt [math]::Min(10, $map.Count); $i++) {
        Write-Host $map[$i]
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "Stack trace: $($_.ScriptStackTrace)"
}
