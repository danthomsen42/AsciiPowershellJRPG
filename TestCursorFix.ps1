# Test Safe Cursor Positioning
Write-Host "=== CURSOR POSITIONING FIX TEST ===" -ForegroundColor Yellow

Write-Host "Current console buffer dimensions:" -ForegroundColor Cyan
Write-Host "- Buffer Width: $([Console]::BufferWidth)"
Write-Host "- Buffer Height: $([Console]::BufferHeight)"
Write-Host "- Window Width: $([Console]::WindowWidth)" 
Write-Host "- Window Height: $([Console]::WindowHeight)"

$boxHeight = 25
$requiredHeight = $boxHeight + 6

Write-Host "`nGame requirements:" -ForegroundColor Yellow
Write-Host "- Box Height: $boxHeight"
Write-Host "- Required Buffer Height: $requiredHeight"
Write-Host "- Status: $(if ([Console]::BufferHeight -ge $requiredHeight) { 'OK' } else { 'NEEDS ADJUSTMENT' })" -ForegroundColor $(if ([Console]::BufferHeight -ge $requiredHeight) { 'Green' } else { 'Red' })

Write-Host "`nTesting safe cursor positioning..." -ForegroundColor Cyan

# Load the safe function
. "$PSScriptRoot\Display.ps1" -ErrorAction SilentlyContinue

# Test various positions
$testPositions = @(
    @{X=0; Y=($boxHeight + 2); Description="Target area (boxHeight + 2)"},
    @{X=0; Y=($boxHeight + 4); Description="Error message area (boxHeight + 4)"},
    @{X=0; Y=29; Description="Previous problem position (29)"},
    @{X=0; Y=([Console]::BufferHeight - 1); Description="Last safe line"}
)

foreach ($pos in $testPositions) {
    Write-Host "Testing position ($($pos.X), $($pos.Y)) - $($pos.Description)" -ForegroundColor White
    try {
        Set-SafeCursorPosition $pos.X $pos.Y
        Write-Host "✅ Success: Safe positioning worked" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== CURSOR POSITIONING TEST COMPLETE ===" -ForegroundColor Yellow
Write-Host "The game should now handle cursor positioning safely without crashes." -ForegroundColor Green
