# Simple test to check if Get-SaveFilePreview works
Write-Host "Testing Get-SaveFilePreview function..." -ForegroundColor Yellow

# Load StartScreen
. "$PSScriptRoot\StartScreen.ps1"

# Check if function exists
if (Get-Command Get-SaveFilePreview -ErrorAction SilentlyContinue) {
    Write-Host "[PASS] Get-SaveFilePreview function found!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Get-SaveFilePreview function not found!" -ForegroundColor Red
}

# List all functions from StartScreen
Write-Host "`nAll functions from StartScreen.ps1:" -ForegroundColor Cyan
Get-Command -CommandType Function | Where-Object { $_.Source -eq "" } | Select-Object Name
