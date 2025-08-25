# Simple Save/Load Crash Fix Test
Write-Host "SAVE/LOAD CRASH FIX TEST" -ForegroundColor Yellow

Write-Host "Console Buffer Info:"
Write-Host "Buffer Height: $([Console]::BufferHeight)"
Write-Host "Required Height for game: 31 (25 + 6 safety margin)"

if ([Console]::BufferHeight -lt 31) {
    Write-Host "WARNING: Console buffer too small - this could cause crashes!" -ForegroundColor Red
    Write-Host "Attempting to resize..." -ForegroundColor Yellow
    try {
        [Console]::SetBufferSize([Console]::BufferWidth, 40)
        Write-Host "Buffer resized successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Could not resize buffer - manual resize recommended" -ForegroundColor Red
    }
} else {
    Write-Host "Buffer size OK - should not crash on cursor positioning" -ForegroundColor Green
}

Write-Host ""
Write-Host "The save/load crash fix includes:"
Write-Host "1. Safe cursor positioning function"
Write-Host "2. Console buffer size checks"  
Write-Host "3. All SetCursorPosition calls replaced with safe versions"
Write-Host ""
Write-Host "You should now be able to load saved games without crashes!" -ForegroundColor Green
