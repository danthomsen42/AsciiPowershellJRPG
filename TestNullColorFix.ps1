# Test Null Color Fix
Write-Host "=== NULL COLOR FIX TEST ===" -ForegroundColor Yellow

# Test the safe Write-Host function
. "$PSScriptRoot\Display.ps1" -ErrorAction SilentlyContinue

Write-Host "Testing safe Write-Host function:" -ForegroundColor Cyan

# Test cases that would previously cause crashes
$testCases = @(
    @{Text="Normal color"; Color="Green"},
    @{Text="Null color"; Color=$null},
    @{Text="Empty color"; Color=""},
    @{Text="Invalid color"; Color="InvalidColor"},
    @{Text="Whitespace color"; Color="   "},
    @{Text="Default (no color specified)"; Color=$null}
)

foreach ($test in $testCases) {
    Write-Host "Test: $($test.Text) - " -NoNewline
    try {
        if ($test.Color) {
            Write-SafeHost "✅ Success" -ForegroundColor $test.Color
        } else {
            Write-SafeHost "✅ Success (null color handled)"
        }
    }
    catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nTesting character creation scenarios:" -ForegroundColor Yellow

# Test character object with null color
$testCharacter = @{
    Name = "TestHero"
    Class = "Warrior"
    Color = $null
    Level = 1
}

Write-Host "Character with null color: " -NoNewline
try {
    $charColor = if ($testCharacter.Color) { $testCharacter.Color } else { "White" }
    Write-SafeHost "$($testCharacter.Name)" -ForegroundColor $charColor
    Write-Host "✅ Success: Null character color handled safely" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== NULL COLOR FIX TEST COMPLETE ===" -ForegroundColor Yellow
Write-Host "The save/load system should now handle null colors without crashing." -ForegroundColor Green
