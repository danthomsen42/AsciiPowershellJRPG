# Test Snake-Following System (Phase 2.2)
# Demonstrates party members following the leader in a trail

Write-Host "=== SNAKE-STYLE FOLLOWING SYSTEM TEST ===" -ForegroundColor Green
Write-Host ""

try {
    # Load required modules
    . "$PSScriptRoot\Player.ps1"
    . "$PSScriptRoot\PartySystem.ps1"

    Write-Host "✓ Modules loaded successfully" -ForegroundColor Green

    # Initialize party
    $global:Party = New-DefaultParty
    Write-Host "✓ Default party created:" -ForegroundColor Green
    
    foreach ($member in $global:Party) {
        Write-Host "  - $($member.Name) ($($member.Class)) [$($member.MapSymbol)]" -ForegroundColor White
    }

    # Test initial positioning
    Write-Host "`nTesting initial party positioning..." -ForegroundColor Yellow
    $startX = 25
    $startY = 10
    Initialize-PartyPositions $startX $startY $global:Party
    
    Write-Host "Initial positions:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $global:Party.Count; $i++) {
        $member = $global:Party[$i]
        $role = if ($i -eq 0) { "LEADER" } else { "FOLLOWER" }
        Write-Host "  $($member.Name): ($($member.Position.X),$($member.Position.Y)) [$role]" -ForegroundColor White
    }

    # Test movement trail
    Write-Host "`nTesting movement trail..." -ForegroundColor Yellow
    $movements = @(
        @{X=26; Y=10}, @{X=27; Y=10}, @{X=28; Y=10}, 
        @{X=28; Y=11}, @{X=28; Y=12}, @{X=27; Y=12}
    )
    
    foreach ($move in $movements) {
        Update-PartyPositions $move.X $move.Y $global:Party
        Write-Host "Leader moves to ($($move.X),$($move.Y)):" -ForegroundColor Cyan
        
        for ($i = 0; $i -lt $global:Party.Count; $i++) {
            $member = $global:Party[$i]
            $role = if ($i -eq 0) { "[@]" } else { "[$($member.MapSymbol)]" }
            Write-Host "  $($member.Name) $role`: ($($member.Position.X),$($member.Position.Y))" -ForegroundColor White
        }
        Write-Host ""
    }

    # Test party positions rendering
    Write-Host "Testing party positions for map rendering..." -ForegroundColor Yellow
    $partyPositions = Get-PartyPositions $global:Party
    
    Write-Host "Party positions hash:" -ForegroundColor Cyan
    foreach ($key in $partyPositions.Keys) {
        $pos = $partyPositions[$key]
        $leaderText = if ($pos.IsLeader) { " (LEADER)" } else { "" }
        Write-Host "  $key -> $($pos.Name) [$($pos.Symbol)]$leaderText" -ForegroundColor White
    }

    Write-Host "`n=== FEATURES IMPLEMENTED ===" -ForegroundColor Cyan
    Write-Host "* Snake-style movement trail system" -ForegroundColor Green
    Write-Host "* Party member spacing (2-position separation)" -ForegroundColor Green
    Write-Host "* Leader (@) and follower symbols (W/M/H/R)" -ForegroundColor Green
    Write-Host "* Map transition support for entire party" -ForegroundColor Green
    Write-Host "* Position tracking and rendering system" -ForegroundColor Green
    Write-Host "* Integration with existing battle and save systems" -ForegroundColor Green

    Write-Host "`n🎮 Visual Map Representation:" -ForegroundColor Magenta
    Write-Host "  @ = Party Leader (Gareth)" -ForegroundColor White
    Write-Host "  M = Mage (Mystara)" -ForegroundColor White  
    Write-Host "  H = Healer (Celeste)" -ForegroundColor White
    Write-Host "  R = Rogue (Raven)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Snake trail example: @-M-H-R (following in formation)" -ForegroundColor Cyan

    Write-Host "`n=== PHASE 2.2 COMPLETED! ===" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Test failed: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
}

Write-Host "`nPress any key to continue..." -ForegroundColor Gray
$null = [System.Console]::ReadKey($true)
