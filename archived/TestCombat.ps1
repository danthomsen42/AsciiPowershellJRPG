# TestCombat.ps1 - Quick combat test to verify layout fixes

Write-Host "=== Testing Combat Layout ===" -ForegroundColor Green

# Load required modules
. "$PSScriptRoot\Player.ps1"
. "$PSScriptRoot\Enemies.ps1"
. "$PSScriptRoot\Spells.ps1"

# Load the combat functions from Display.ps1
$displayContent = Get-Content "$PSScriptRoot\Display.ps1" -Raw

# Extract and execute just the function definitions we need
$functionsToExtract = @(
    'function Draw-CombatViewport',
    'function Write-CombatMessage', 
    'function New-TurnOrder',
    'function Show-TurnOrder'
)

foreach ($functionName in $functionsToExtract) {
    $pattern = "(?s)$functionName.*?(?=function |\Z)"
    $regexMatches = [regex]::Matches($displayContent, $pattern)
    if ($regexMatches.Count -gt 0) {
        $functionCode = $regexMatches[0].Value
        Invoke-Expression $functionCode
        Write-Host "✓ Extracted $functionName" -ForegroundColor Green
    } else {
        Write-Host "✗ Could not extract $functionName" -ForegroundColor Red
    }
}

# Simple combat test
$player = $Player.Clone()
$enemy = $Enemy1.Clone()  # Use first enemy for testing
$boxWidth = 50
$boxHeight = 18

Write-Host "`nStarting combat test..." -ForegroundColor Yellow
Write-Host "Player Speed: $($player.Speed)" -ForegroundColor Cyan
Write-Host "Enemy Speed: $($enemy.Speed)" -ForegroundColor Cyan

# Create turn order
$turnOrder = New-TurnOrder $player $enemy

Write-Host "`nCombat Layout Test:" -ForegroundColor Yellow
[System.Console]::Clear()

# Test the layout
Draw-CombatViewport $enemy.Art $enemy.Name $boxWidth $boxHeight

# Display HP/MP stats
$playerHPStr = $player.HP.ToString().PadRight(4)
$playerMaxHPStr = $player.MaxHP.ToString().PadRight(4)
$playerMPStr = $player.MP.ToString().PadRight(4)
$playerMaxMPStr = $player.MaxMP.ToString().PadRight(4)
$enemyHPStr = $enemy.HP.ToString().PadRight(4)
Write-Host ("Player HP: $playerHPStr/$playerMaxHPStr   MP: $playerMPStr/$playerMaxMPStr   Enemy HP: $enemyHPStr    ") -ForegroundColor White

# Display combat controls
Write-Host "Combat Controls: A=Attack   D=Defend   S=Spells   I=Items   R=Run" -ForegroundColor Cyan

# Show turn order
Show-TurnOrder $turnOrder 0

# Test combat message
Write-CombatMessage "Combat layout test - this message should appear below turn order!" "Green" "PLAYER TURN"

Write-Host "`n`nLayout test complete! Check positioning above." -ForegroundColor Green
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = [System.Console]::ReadKey($true)
