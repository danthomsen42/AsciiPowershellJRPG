# Engine/PartyManagement.ps1 - Party Management Screen
# Swap main/secondary attacks, equip items, reorder party formation.

function Show-PartyManagement {
    <#
    .SYNOPSIS
        Top-level party management menu: choose a member, then manage them.
    #>
    while ($true) {
        Clear-FrameBuffer
        Draw-Box -X 5 -Y 1 -Width 110 -Height 28 -Color ([ConsoleColor]::Cyan) -BgColor ([ConsoleColor]::Black) -Fill
        Set-Text -X 7 -Y 1 -Text ' Party Management ' -FgColor ([ConsoleColor]::Cyan)

        $options = @()
        foreach ($m in $Script:GameState.Party) {
            $options += "[$($m.Symbol)] $($m.Name) the $($m.Class) - Lv.$($m.Level)"
        }
        $options += 'Reorder Party'
        $options += 'Back'

        $sel = Draw-SelectionMenu -X 20 -Y 4 -Width 80 -Title 'Select' `
                                   -Options $options `
                                   -BorderColor ([ConsoleColor]::Cyan) `
                                   -TextColor ([ConsoleColor]::Yellow)

        if ($sel -lt $Script:GameState.Party.Count) {
            Show-MemberManagement -MemberIndex $sel
        }
        elseif ($sel -eq $Script:GameState.Party.Count) {
            Show-ReorderParty
        }
        else {
            return
        }
    }
}

function Show-MemberManagement {
    <#
    .SYNOPSIS  Manage a single party member: swap attacks, equip gear.
    #>
    param([int]$MemberIndex)

    $member = $Script:GameState.Party[$MemberIndex]

    while ($true) {
        Clear-FrameBuffer
        Draw-Box -X 5 -Y 1 -Width 110 -Height 28 -Color ([ConsoleColor]::Cyan) -BgColor ([ConsoleColor]::Black) -Fill
        Set-Text -X 7 -Y 1 -Text " $($member.Name) - $($member.Class) " -FgColor ([ConsoleColor]::Cyan)

        # Show current stats
        Set-Text -X 8 -Y 3 -Text "HP: $($member.HP)/$($member.MaxHP)  MP: $($member.MP)/$($member.MaxMP)  Lv.$($member.Level)" -FgColor ([ConsoleColor]::Green)
        Set-Text -X 8 -Y 4 -Text "STR:$($member.Strength)  INT:$($member.Intelligence)  SPD:$($member.Speed)  DEF:$($member.Defense)  ACC:$($member.Accuracy)" -FgColor ([ConsoleColor]::Gray)
        Set-Text -X 8 -Y 5 -Text "Main Attack: $($member.MainAttack)" -FgColor ([ConsoleColor]::White)
        Set-Text -X 8 -Y 6 -Text "Secondary: $(($member.SecondaryAbilities -join ', '))" -FgColor ([ConsoleColor]::DarkGray)
        $weaponName = if ($member.Equipment.Weapon) { $member.Equipment.Weapon } else { '(none)' }
        $armorName  = if ($member.Equipment.Armor)  { $member.Equipment.Armor }  else { '(none)' }
        $accName    = if ($member.Equipment.Accessory) { $member.Equipment.Accessory } else { '(none)' }
        Set-Text -X 8 -Y 7 -Text "Weapon: $weaponName  |  Armor: $armorName  |  Accessory: $accName" -FgColor ([ConsoleColor]::DarkYellow)

        $menuOpts = @('Swap Main/Secondary Attack', 'Equip Weapon', 'Equip Armor', 'Equip Accessory', 'Unequip Accessory', 'Back')
        $sel = Draw-SelectionMenu -X 20 -Y 9 -Width 70 -Title "Manage $($member.Name)" `
                                   -Options $menuOpts `
                                   -BorderColor ([ConsoleColor]::Yellow) `
                                   -TextColor ([ConsoleColor]::White)

        switch ($sel) {
            0 { Invoke-SwapAttacks -Member $member }
            1 { Invoke-EquipItem -Member $member -Slot 'Weapon' }
            2 { Invoke-EquipItem -Member $member -Slot 'Armor' }
            3 { Invoke-EquipItem -Member $member -Slot 'Accessory' }
            4 { Invoke-UnequipSlot -Member $member -Slot 'Accessory' }
            default { return }
        }
    }
}

# ── Swap Main / Secondary Attacks ────────────────────────────────────────────────

function Invoke-SwapAttacks {
    param([hashtable]$Member)

    $allAbilities = @($Member.MainAttack) + @($Member.SecondaryAbilities)
    if ($allAbilities.Count -le 1) {
        Add-GameMessage "$($Member.Name) only knows one ability!"
        return
    }

    # Show ability list — pick new main attack
    $options = @()
    foreach ($ab in $allAbilities) {
        $abDef = $Script:AbilityTable[$ab]
        $mpStr = if ($abDef -and [int]$abDef.MP -gt 0) { " (MP:$($abDef.MP))" } else { ' (free)' }
        $typeStr = if ($abDef) { $abDef.Type } else { '???' }
        $marker = if ($ab -eq $Member.MainAttack) { ' [MAIN]' } else { '' }
        $options += "$ab - $typeStr$mpStr$marker"
    }

    Clear-FrameBuffer
    $sel = Draw-SelectionMenu -X 15 -Y 6 -Width 90 -Title "Choose New Main Attack for $($Member.Name)" `
                               -Options $options `
                               -BorderColor ([ConsoleColor]::Yellow) `
                               -TextColor ([ConsoleColor]::White)

    if ($sel -ge 0 -and $sel -lt $allAbilities.Count) {
        $newMain = $allAbilities[$sel]
        if ($newMain -ne $Member.MainAttack) {
            # Build new secondary list: all abilities except the new main
            $newSecondary = @()
            foreach ($ab in $allAbilities) {
                if ($ab -ne $newMain) { $newSecondary += $ab }
            }
            $Member.MainAttack = $newMain
            $Member.SecondaryAbilities = $newSecondary
            Add-GameMessage "$($Member.Name)'s main attack is now $newMain!"
        }
    }
}

# ── Equipment Handling ───────────────────────────────────────────────────────────

function Get-ItemStatBonus {
    <#
    .SYNOPSIS  Returns a hashtable of stat bonuses from an item definition.
    #>
    param([object]$ItemDef)

    $bonus = @{}
    if ($ItemDef -and $ItemDef.statBonus -and $ItemDef.statBonus.PSObject) {
        foreach ($prop in $ItemDef.statBonus.PSObject.Properties) {
            $bonus[$prop.Name] = [int]$prop.Value
        }
    }
    return $bonus
}

function Apply-StatBonuses {
    param([hashtable]$Member, [hashtable]$Bonuses, [int]$Multiplier = 1)
    foreach ($stat in $Bonuses.Keys) {
        if ($Member.ContainsKey($stat)) {
            $Member[$stat] += [int]$Bonuses[$stat] * $Multiplier
        }
    }
}

function Invoke-EquipItem {
    <#
    .SYNOPSIS
        Shows equippable items from inventory for a given slot.
        Equipping an item removes stat bonus of old item and applies new one.
    #>
    param([hashtable]$Member, [string]$Slot)

    # Determine valid item types for this slot
    $validTypes = switch ($Slot) {
        'Weapon'    { @('weapon') }
        'Armor'     { @('armor') }
        'Accessory' { @('accessory') }
    }

    # Find equippable items in inventory
    $equippable = @()
    foreach ($item in $Script:GameState.Inventory) {
        if ($item.type -in $validTypes) {
            $equippable += $item
        } else {
            # Also check item definition
            $def = Get-ItemDefinition -ItemId $item.id
            if ($def -and $def.type -in $validTypes) {
                $equippable += $item
            }
        }
    }

    if ($equippable.Count -eq 0) {
        Add-GameMessage "No $Slot items in inventory!"
        return
    }

    $options = @()
    foreach ($item in $equippable) {
        $def = Get-ItemDefinition -ItemId $item.id
        $nameStr = if ($item.name) { $item.name } else { $item.id }
        $descStr = if ($def) { $def.description } elseif ($item.description) { $item.description } else { '' }
        $qty = if ($item.count) { $item.count } else { 1 }
        $options += "$nameStr x$qty - $descStr"
    }

    Clear-FrameBuffer
    $sel = Draw-SelectionMenu -X 15 -Y 6 -Width 90 -Title "Equip $Slot for $($Member.Name)" `
                               -Options $options `
                               -BorderColor ([ConsoleColor]::Yellow) `
                               -TextColor ([ConsoleColor]::White)

    if ($sel -ge 0 -and $sel -lt $equippable.Count) {
        $chosenInvItem = $equippable[$sel]
        $chosenDef = Get-ItemDefinition -ItemId $chosenInvItem.id
        $chosenName = if ($chosenInvItem.name) { $chosenInvItem.name } else { $chosenInvItem.id }

        # Remove old equipment stat bonuses
        $currentEquipName = $Member.Equipment[$Slot]
        if ($currentEquipName) {
            $oldDef = $Script:ItemDefinitions | Where-Object { $_.name -eq $currentEquipName }
            if ($oldDef) {
                $oldBonus = Get-ItemStatBonus -ItemDef $oldDef
                Apply-StatBonuses -Member $Member -Bonuses $oldBonus -Multiplier -1
            }
            # Return old equipment to inventory
            if ($oldDef) {
                Add-InventoryItem -ItemId $oldDef.id
            }
        }

        # Apply new equipment stat bonuses
        if ($chosenDef) {
            $newBonus = Get-ItemStatBonus -ItemDef $chosenDef
            Apply-StatBonuses -Member $Member -Bonuses $newBonus -Multiplier 1
        }

        $Member.Equipment[$Slot] = $chosenName

        # Remove from inventory (consume 1)
        $chosenInvItem.count--
        if ([int]$chosenInvItem.count -le 0) {
            $removeId = $chosenInvItem.id
            $Script:GameState.Inventory = @($Script:GameState.Inventory | Where-Object { $_.id -ne $removeId -or [int]$_.count -gt 0 })
        }

        Add-GameMessage "$($Member.Name) equipped $chosenName!"
    }
}

function Invoke-UnequipSlot {
    param([hashtable]$Member, [string]$Slot)

    $currentName = $Member.Equipment[$Slot]
    if (-not $currentName -or $currentName -eq '(none)') {
        Add-GameMessage "$($Member.Name) has nothing equipped in $Slot slot."
        return
    }

    # Remove stat bonuses
    $def = $Script:ItemDefinitions | Where-Object { $_.name -eq $currentName }
    if ($def) {
        $bonus = Get-ItemStatBonus -ItemDef $def
        Apply-StatBonuses -Member $Member -Bonuses $bonus -Multiplier -1
        Add-InventoryItem -ItemId $def.id
    }

    $Member.Equipment[$Slot] = $null
    Add-GameMessage "$($Member.Name) unequipped $currentName."
}

# ── Reorder Party ────────────────────────────────────────────────────────────────

function Show-ReorderParty {
    <#
    .SYNOPSIS
        Let the player swap party member positions.
        First pick = member to move, second pick = position to swap with.
    #>
    $msg = 'Choose member to move:'
    while ($true) {
        $options = @()
        for ($i = 0; $i -lt $Script:GameState.Party.Count; $i++) {
            $m = $Script:GameState.Party[$i]
            $lead = if ($i -eq 0) { ' [LEAD]' } else { '' }
            $options += "$($i+1). [$($m.Symbol)] $($m.Name) the $($m.Class)$lead"
        }
        $options += 'Done'

        Clear-FrameBuffer
        Set-Text -X 20 -Y 3 -Text $msg -FgColor ([ConsoleColor]::Yellow)
        $first = Draw-SelectionMenu -X 20 -Y 5 -Width 80 -Title 'Reorder Party' `
                                     -Options $options `
                                     -BorderColor ([ConsoleColor]::Cyan) `
                                     -TextColor ([ConsoleColor]::White)

        if ($first -ge $Script:GameState.Party.Count) { return }

        $msg = "Swap $($Script:GameState.Party[$first].Name) with:"
        Clear-FrameBuffer
        Set-Text -X 20 -Y 3 -Text $msg -FgColor ([ConsoleColor]::Yellow)
        $second = Draw-SelectionMenu -X 20 -Y 5 -Width 80 -Title 'Swap With' `
                                      -Options $options `
                                      -BorderColor ([ConsoleColor]::Cyan) `
                                      -TextColor ([ConsoleColor]::White)

        if ($second -ge $Script:GameState.Party.Count -or $second -eq $first) {
            $msg = 'Choose member to move:'
            continue
        }

        # Swap
        $temp = $Script:GameState.Party[$first]
        $Script:GameState.Party[$first] = $Script:GameState.Party[$second]
        $Script:GameState.Party[$second] = $temp

        $msg = "Swapped! $($Script:GameState.Party[$first].Name) <-> $($Script:GameState.Party[$second].Name). Choose next or Done:"
        Add-GameMessage "Party reordered: $($Script:GameState.Party[$first].Name) and $($Script:GameState.Party[$second].Name) swapped positions."
    }
}
