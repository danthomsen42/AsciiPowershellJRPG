$Player = @{
    Name        = "Hero"
    Level       = 1
    MaxHP       = 30
    HP          = 30
    Attack      = 6
    Defense     = 3
    Speed       = 8
    MP          = 5
    MaxMP       = 5
    XP          = 0
    Spells      = @("Fire", "Heal")
    Inventory   = @() # List of item names/IDs
    Equipped    = @{
        Weapon    = "Axe"
        Armor     = "Leather Armor"
        Accessory = $null
    }
}
