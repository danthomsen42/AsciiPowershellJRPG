# Engine/ShopEngine.ps1 - Buy & Sell Shop System
# Displays shop inventory, handles gold transactions, and manages buy/sell UI.

# ── Cached item definitions ──────────────────────────────────────────────────────
$Script:ItemDefinitions = $null

function Get-ItemDefinition {
    <#
    .SYNOPSIS  Looks up an item by ID from Items.json. Caches on first load.
    #>
    param([string]$ItemId)

    if ($null -eq $Script:ItemDefinitions) {
        $path = Join-Path $Script:GameRoot "Data\Items\Items.json"
        if (Test-Path $path) {
            $Script:ItemDefinitions = (Get-Content $path -Raw | ConvertFrom-Json).items
        } else {
            $Script:ItemDefinitions = @()
        }
    }
    return ($Script:ItemDefinitions | Where-Object { $_.id -eq $ItemId -or $_.name -eq $ItemId } | Select-Object -First 1)
}

function Get-ShopData {
    param([string]$ShopId)
    $path = Join-Path $Script:GameRoot "Data\Shops.json"
    if (-not (Test-Path $path)) { return $null }
    $data = Get-Content $path -Raw | ConvertFrom-Json
    $prop = $data.shops.PSObject.Properties[$ShopId]
    if ($prop) { return $prop.Value }
    return $null
}

# ── Buy Screen ───────────────────────────────────────────────────────────────────

function Show-ShopBuy {
    <#
    .SYNOPSIS  Displays the shop buy menu. Player picks items to purchase.
    #>
    param([string]$ShopId)

    $shop = Get-ShopData -ShopId $ShopId
    if (-not $shop) {
        Add-GameMessage "Shop data not found!"
        return
    }

    # Build item list
    $shopItems = @()
    foreach ($itemId in $shop.inventory) {
        $def = Get-ItemDefinition -ItemId $itemId
        if ($def -and [int]$def.buyPrice -gt 0) {
            $shopItems += $def
        }
    }
    if ($shopItems.Count -eq 0) {
        Add-GameMessage "Nothing for sale!"
        return
    }

    $sel = 0
    $msg = ''
    while ($true) {
        Clear-FrameBuffer

        # Title
        Draw-Box -X 2 -Y 1 -Width 116 -Height 28 -Color ([ConsoleColor]::DarkYellow) -BgColor ([ConsoleColor]::Black) -Fill
        Set-Text -X 4 -Y 1 -Text " $($shop.name) - BUY " -FgColor ([ConsoleColor]::Yellow)
        Set-Text -X 80 -Y 1 -Text " Gold: $($Script:GameState.Gold) " -FgColor ([ConsoleColor]::DarkYellow)

        # Column headers
        Set-Text -X 4  -Y 3 -Text 'Item Name'   -FgColor ([ConsoleColor]::Cyan)
        Set-Text -X 30 -Y 3 -Text 'Type'         -FgColor ([ConsoleColor]::Cyan)
        Set-Text -X 42 -Y 3 -Text 'Price'        -FgColor ([ConsoleColor]::Cyan)
        Set-Text -X 52 -Y 3 -Text 'Description'  -FgColor ([ConsoleColor]::Cyan)

        # Scrollable item list
        $maxVisible = 20
        $scrollOffset = 0
        if ($sel -ge $maxVisible) { $scrollOffset = $sel - $maxVisible + 1 }

        for ($i = 0; $i -lt $maxVisible -and ($i + $scrollOffset) -lt $shopItems.Count; $i++) {
            $item = $shopItems[$i + $scrollOffset]
            $rowY = 4 + $i
            $idx = $i + $scrollOffset

            $nameStr = $item.name
            $typeStr = $item.type
            $priceStr = "$([int]$item.buyPrice)g"
            $descStr = $item.description
            if ($descStr.Length -gt 60) { $descStr = $descStr.Substring(0, 57) + '...' }

            if ($idx -eq $sel) {
                Set-Text -X 4  -Y $rowY -Text "> $nameStr" -FgColor ([ConsoleColor]::Black) -BgColor ([ConsoleColor]::White)
                Set-Text -X 30 -Y $rowY -Text $typeStr -FgColor ([ConsoleColor]::Black) -BgColor ([ConsoleColor]::White)
                Set-Text -X 42 -Y $rowY -Text $priceStr -FgColor ([ConsoleColor]::Black) -BgColor ([ConsoleColor]::White)
                Set-Text -X 52 -Y $rowY -Text $descStr -FgColor ([ConsoleColor]::Black) -BgColor ([ConsoleColor]::White)
                # Fill gaps
                $fillEnd = 116
                $lastText = 52 + $descStr.Length
                if ($lastText -lt $fillEnd) {
                    Set-Text -X $lastText -Y $rowY -Text (' ' * ($fillEnd - $lastText)) -FgColor ([ConsoleColor]::Black) -BgColor ([ConsoleColor]::White)
                }
            } else {
                $canAfford = ([int]$item.buyPrice -le $Script:GameState.Gold)
                $priceColor = if ($canAfford) { [ConsoleColor]::Green } else { [ConsoleColor]::Red }
                Set-Text -X 4  -Y $rowY -Text "  $nameStr" -FgColor ([ConsoleColor]::Gray)
                Set-Text -X 30 -Y $rowY -Text $typeStr -FgColor ([ConsoleColor]::DarkGray)
                Set-Text -X 42 -Y $rowY -Text $priceStr -FgColor $priceColor
                Set-Text -X 52 -Y $rowY -Text $descStr -FgColor ([ConsoleColor]::DarkGray)
            }
        }

        # Message area
        if ($msg) {
            Set-Text -X 4 -Y 26 -Text $msg -FgColor ([ConsoleColor]::Yellow)
        }

        Set-Text -X 4 -Y 27 -Text '[Up/Down] Navigate  [Enter] Buy  [Esc] Exit' -FgColor ([ConsoleColor]::DarkGray)
        Invoke-RenderFrame

        $key = Wait-ForKey
        switch ($key.Key) {
            'UpArrow'   { $sel--; if ($sel -lt 0) { $sel = $shopItems.Count - 1 }; $msg = '' }
            'DownArrow' { $sel++; if ($sel -ge $shopItems.Count) { $sel = 0 }; $msg = '' }
            'Enter' {
                $chosen = $shopItems[$sel]
                $price = [int]$chosen.buyPrice
                if ($Script:GameState.Gold -ge $price) {
                    $Script:GameState.Gold -= $price
                    Add-InventoryItem -ItemId $chosen.id
                    $msg = "Bought $($chosen.name) for ${price}g!"
                    Add-GameMessage $msg
                } else {
                    $msg = "Not enough gold! Need ${price}g, have $($Script:GameState.Gold)g."
                }
            }
            'Escape' { return }
        }
    }
}

# ── Sell Screen ──────────────────────────────────────────────────────────────────

function Show-ShopSell {
    $sel = 0
    $msg = ''
    while ($true) {
        # Rebuild sellable list each frame (quantities change)
        $sellable = @()
        foreach ($item in $Script:GameState.Inventory) {
            $def = Get-ItemDefinition -ItemId $item.id
            $sellPrice = 0
            if ($def -and [int]$def.sellPrice -gt 0) { $sellPrice = [int]$def.sellPrice }
            elseif ($item.sellPrice) { $sellPrice = [int]$item.sellPrice }
            if ($sellPrice -gt 0) {
                $sellable += @{ Ref = $item; SellPrice = $sellPrice; Def = $def }
            }
        }

        if ($sellable.Count -eq 0) {
            Clear-FrameBuffer
            Draw-TextBox -X 20 -Y 10 -Width 80 -Height 5 -Title 'Sell' `
                         -Lines @('You have nothing to sell!') `
                         -BorderColor ([ConsoleColor]::Yellow) -TextColor ([ConsoleColor]::Gray)
            Set-Text -X 22 -Y 16 -Text 'Press any key to go back...' -FgColor ([ConsoleColor]::DarkGray)
            Invoke-RenderFrame
            Wait-ForKey | Out-Null
            return
        }

        if ($sel -ge $sellable.Count) { $sel = $sellable.Count - 1 }

        Clear-FrameBuffer
        Draw-Box -X 2 -Y 1 -Width 116 -Height 28 -Color ([ConsoleColor]::DarkYellow) -BgColor ([ConsoleColor]::Black) -Fill
        Set-Text -X 4 -Y 1 -Text ' SELL ' -FgColor ([ConsoleColor]::Yellow)
        Set-Text -X 80 -Y 1 -Text " Gold: $($Script:GameState.Gold) " -FgColor ([ConsoleColor]::DarkYellow)

        Set-Text -X 4  -Y 3 -Text 'Item Name'   -FgColor ([ConsoleColor]::Cyan)
        Set-Text -X 30 -Y 3 -Text 'Qty'          -FgColor ([ConsoleColor]::Cyan)
        Set-Text -X 36 -Y 3 -Text 'Sell Price'   -FgColor ([ConsoleColor]::Cyan)
        Set-Text -X 50 -Y 3 -Text 'Description'  -FgColor ([ConsoleColor]::Cyan)

        $maxVisible = 20
        $scrollOffset = 0
        if ($sel -ge $maxVisible) { $scrollOffset = $sel - $maxVisible + 1 }

        for ($i = 0; $i -lt $maxVisible -and ($i + $scrollOffset) -lt $sellable.Count; $i++) {
            $entry = $sellable[$i + $scrollOffset]
            $rowY = 4 + $i
            $idx = $i + $scrollOffset
            $item = $entry.Ref

            $nameStr = if ($item.name) { $item.name } else { $item.id }
            $qty = if ($item.count) { $item.count } elseif ($item.Quantity) { $item.Quantity } else { 1 }
            $priceStr = "$($entry.SellPrice)g"
            $descStr = if ($item.description) { $item.description } else { '' }
            if ($descStr.Length -gt 60) { $descStr = $descStr.Substring(0, 57) + '...' }

            if ($idx -eq $sel) {
                Set-Text -X 4  -Y $rowY -Text "> $nameStr" -FgColor ([ConsoleColor]::Black) -BgColor ([ConsoleColor]::White)
                Set-Text -X 30 -Y $rowY -Text "x$qty" -FgColor ([ConsoleColor]::Black) -BgColor ([ConsoleColor]::White)
                Set-Text -X 36 -Y $rowY -Text $priceStr -FgColor ([ConsoleColor]::Black) -BgColor ([ConsoleColor]::White)
                Set-Text -X 50 -Y $rowY -Text $descStr -FgColor ([ConsoleColor]::Black) -BgColor ([ConsoleColor]::White)
                $fillEnd = 116
                $lastText = 50 + $descStr.Length
                if ($lastText -lt $fillEnd) {
                    Set-Text -X $lastText -Y $rowY -Text (' ' * ($fillEnd - $lastText)) -FgColor ([ConsoleColor]::Black) -BgColor ([ConsoleColor]::White)
                }
            } else {
                Set-Text -X 4  -Y $rowY -Text "  $nameStr" -FgColor ([ConsoleColor]::Gray)
                Set-Text -X 30 -Y $rowY -Text "x$qty" -FgColor ([ConsoleColor]::DarkGray)
                Set-Text -X 36 -Y $rowY -Text $priceStr -FgColor ([ConsoleColor]::Green)
                Set-Text -X 50 -Y $rowY -Text $descStr -FgColor ([ConsoleColor]::DarkGray)
            }
        }

        if ($msg) {
            Set-Text -X 4 -Y 26 -Text $msg -FgColor ([ConsoleColor]::Yellow)
        }
        Set-Text -X 4 -Y 27 -Text '[Up/Down] Navigate  [Enter] Sell 1  [Esc] Exit' -FgColor ([ConsoleColor]::DarkGray)
        Invoke-RenderFrame

        $key = Wait-ForKey
        switch ($key.Key) {
            'UpArrow'   { $sel--; if ($sel -lt 0) { $sel = $sellable.Count - 1 }; $msg = '' }
            'DownArrow' { $sel++; if ($sel -ge $sellable.Count) { $sel = 0 }; $msg = '' }
            'Enter' {
                $entry = $sellable[$sel]
                $item = $entry.Ref
                $price = $entry.SellPrice
                $Script:GameState.Gold += $price
                $itemName = if ($item.name) { $item.name } else { $item.id }

                $item.count--
                if ([int]$item.count -le 0) {
                    $Script:GameState.Inventory = @($Script:GameState.Inventory | Where-Object { $_.id -ne $item.id -or [int]$_.count -gt 0 })
                }
                $msg = "Sold $itemName for ${price}g!"
                Add-GameMessage $msg
            }
            'Escape' { return }
        }
    }
}
