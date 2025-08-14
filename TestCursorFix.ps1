# Quick test for character colors with cursor fix
Write-Host "Testing cursor positioning fix..." -ForegroundColor Green

# Load required modules
. "$PSScriptRoot\CharacterColors.ps1"
. "$PSScriptRoot\PartySystem.ps1"

# Test cursor positioning
Write-Host "`nTesting cursor behavior:" -ForegroundColor Yellow

Write-Host "Before coloring - cursor here: " -NoNewline
Write-Host "WMHR" -ForegroundColor White

Write-Host "After coloring with positioning: " -NoNewline
[System.Console]::SetCursorPosition(35, 4)
Write-Host "W" -ForegroundColor Cyan -NoNewline
[System.Console]::SetCursorPosition(36, 4)
Write-Host "M" -ForegroundColor Magenta -NoNewline
[System.Console]::SetCursorPosition(37, 4)
Write-Host "H" -ForegroundColor Yellow -NoNewline
[System.Console]::SetCursorPosition(38, 4)
Write-Host "R" -ForegroundColor Green -NoNewline

# Move cursor to safe position
[System.Console]::SetCursorPosition(0, 8)
Write-Host "`nCursor should now be positioned safely below."

Write-Host "`nIf you don't see a flashing cursor near the colored characters, the fix works!" -ForegroundColor Green
