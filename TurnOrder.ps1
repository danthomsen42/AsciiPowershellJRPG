# Turn Order Management Functions

# Function to create turn order based on Speed stats
function New-TurnOrder {
    param($Player, $Enemy)
    
    # Create combatants array with speed and type info
    $combatants = @()
    
    # Add player to combatants
    $combatants += @{
        Name = $Player.Name
        Speed = $Player.Speed
        Type = "Player"
        Entity = $Player
    }
    
    # Add enemy to combatants  
    $combatants += @{
        Name = $Enemy.Name
        Speed = $Enemy.Speed
        Type = "Enemy"
        Entity = $Enemy
    }
    
    # Sort by Speed (highest first), with random tiebreaker
    $turnOrder = $combatants | Sort-Object { $_.Speed + (Get-Random -Minimum 0.0 -Maximum 1.0) } -Descending
    
    return $turnOrder
}

# Function to display turn order to player
function Show-TurnOrder {
    param($TurnOrder, $CurrentTurnIndex)
    
    $orderText = "Turn Order: "
    for ($i = 0; $i -lt $TurnOrder.Count; $i++) {
        $combatant = $TurnOrder[$i]
        if ($i -eq $CurrentTurnIndex) {
            $orderText += "[$($combatant.Name)]"
        } else {
            $orderText += "$($combatant.Name)"
        }
        if ($i -lt $TurnOrder.Count - 1) {
            $orderText += " → "
        }
    }
    
    # Simple approach - just display the turn order
    Write-Host $orderText -ForegroundColor Cyan
}
