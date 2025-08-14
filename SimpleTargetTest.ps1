# Simple test for clean targeting
Write-Host "Testing Clean Arrow Targeting System" -ForegroundColor Green

# Load required files
. "$PSScriptRoot\NewEnemies.ps1"
. "$PSScriptRoot\EnhancedCombatDisplay.ps1" 
. "$PSScriptRoot\CleanArrowTargeting.ps1"

# Create test enemies
$testEnemies = @(
    @{
        Name = "Test Goblin"
        HP = 20
        MaxHP = 20
        Size = "Small"
        Art = @("  /|\\", " (oo)", "<___>")
    },
    @{
        Name = "Test Orc" 
        HP = 30
        MaxHP = 30
        Size = "Medium"
        Art = @("  ___", " /ORC\\", "( o o )", " \\___/")
    }
)

Write-Host "Created $($testEnemies.Count) test enemies" -ForegroundColor Yellow

# Test drawing
Write-Host "Testing Draw-EnhancedCombatViewport..." -ForegroundColor Cyan
Draw-EnhancedCombatViewport $testEnemies 80 25

Write-Host "Test completed!" -ForegroundColor Green
