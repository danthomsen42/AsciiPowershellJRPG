# Test both rendering modes
Write-Host "Testing Single-Buffer vs Multi-Step Rendering" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Instructions:" -ForegroundColor Yellow
Write-Host "1. The game will start in Multi-Step rendering mode (default)" -ForegroundColor Gray
Write-Host "2. Press 'R' during gameplay to switch to Single-Buffer rendering" -ForegroundColor Gray
Write-Host "3. Press 'R' again to switch back to Multi-Step rendering" -ForegroundColor Gray
Write-Host "4. Compare performance and visual quality between the two modes" -ForegroundColor Gray
Write-Host ""
Write-Host "Expected improvements with Single-Buffer rendering:" -ForegroundColor Green
Write-Host "- Reduced or eliminated flickering" -ForegroundColor White
Write-Host "- Potentially faster performance" -ForegroundColor White
Write-Host "- Colors embedded directly in the output string" -ForegroundColor White
Write-Host ""
Write-Host "Starting game in 3 seconds..." -ForegroundColor Yellow
Start-Sleep 3

.\Display.ps1
