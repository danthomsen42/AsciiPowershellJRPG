# Test Party System Integration
Write-Host "Testing Party System..." -ForegroundColor Green

# Load required scripts
. "$PSScriptRoot\Player.ps1"
. "$PSScriptRoot\PartySystem.ps1"

try {
    # Create default party
    Write-Host "`nCreating default party..." -ForegroundColor Yellow
    $Party = New-DefaultParty
    
    Write-Host "Party created successfully!" -ForegroundColor Green
    Write-Host "`nParty Members:" -ForegroundColor Cyan
    
    foreach ($member in $Party) {
        Write-Host "  $($member.Name) ($($member.Class)) - Level $($member.Level)" -ForegroundColor White
        Write-Host "    HP: $($member.HP)/$($member.MaxHP)  MP: $($member.MP)/$($member.MaxMP)" -ForegroundColor Gray
        Write-Host "    Attack: $($member.Attack)  Defense: $($member.Defense)  Speed: $($member.Speed)" -ForegroundColor Gray
        Write-Host "    Spells: $($member.Spells -join ', ')" -ForegroundColor Gray
        Write-Host ""
    }
    
    # Test party turn order
    Write-Host "Testing party turn order..." -ForegroundColor Yellow
    $enemy = @{
        Name = "Test Goblin"
        Type = "Enemy"
        HP = 50
        MaxHP = 50
        MP = 10
        MaxMP = 10
        Attack = 15
        Defense = 8
        Speed = 12
        Level = 3
        BaseXP = 10
        Spells = @("Fireball")
    }
    
    $turnOrder = New-PartyTurnOrder $Party $enemy
    Write-Host "`nTurn Order:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $turnOrder.Count; $i++) {
        $combatant = $turnOrder[$i]
        Write-Host "  $($i+1). $($combatant.Character.Name) ($($combatant.Type)) - Speed: $($combatant.Character.Speed)" -ForegroundColor White
    }
    
    Write-Host "`nParty system test completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "Error testing party system: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
