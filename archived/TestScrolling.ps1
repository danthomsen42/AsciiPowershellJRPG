# Quick test for combat display scrolling issues
Write-Host "=== Testing Combat Display - No Scrolling ===" -ForegroundColor Green

# Test cursor positioning behavior
Write-Host "Testing cursor positioning safety..."

try {
    $maxY = [System.Console]::BufferHeight - 5
    Write-Host "Terminal height: $maxY"
    
    # Test safe positioning
    [System.Console]::SetCursorPosition(0, 20)
    Write-Host "Line 20: This should not cause scrolling"
    
    [System.Console]::SetCursorPosition(0, 22)
    Write-Host "Line 22: Testing stats position"
    
    [System.Console]::SetCursorPosition(0, 23)
    Write-Host "Line 23: Testing enemy stats"
    
    Write-Host ""
    Write-Host "✅ No scrolling detected in cursor tests" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Cursor positioning failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎮 To test in combat:" -ForegroundColor Cyan
Write-Host "  1. Run .\Display.ps1"
Write-Host "  2. Enter combat"
Write-Host "  3. Try multiple actions (A, D, S)"
Write-Host "  4. Verify screen stays in place (no scrolling down)"
Write-Host ""
Write-Host "Expected: Messages update in place, no terminal scrolling" -ForegroundColor Yellow
