# =============================================================================
# COLOR SELECTION INTERFACE FOR CHARACTER CREATION
# =============================================================================

function Show-ColorSelection {
    param(
        [string]$CharacterName,
        [string]$Class,
        [int]$CurrentSelection = 0
    )
    
    Clear-Host
    
    # Title
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                           CHARACTER CREATION" -ForegroundColor Cyan
    Write-Host "                         Choose Color for $CharacterName" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "                          SELECT A COLOR:" -ForegroundColor Yellow
    Write-Host ""
    
    # Display color options with preview
    for ($i = 0; $i -lt $DefaultColors.Count; $i++) {
        $colorName = $DefaultColors[$i]
        $prefix = if ($i -eq $CurrentSelection) { "  > " } else { "    " }
        $displayColor = if ($i -eq $CurrentSelection) { "White" } else { "Gray" }
        $highlight = if ($i -eq $CurrentSelection) { "[$colorName]" } else { " $colorName " }
        
        Write-Host $prefix -NoNewline -ForegroundColor $displayColor
        Write-Host $highlight -NoNewline -ForegroundColor $displayColor
        Write-Host " - " -NoNewline -ForegroundColor $displayColor
        Write-Host "PREVIEW" -ForegroundColor $colorName
    }
    
    Write-Host ""
    Write-Host "                  Use Up/Down to browse, ENTER to select" -ForegroundColor DarkGray
    Write-Host "                         ESC to use default color" -ForegroundColor DarkGray
}

function Get-ColorSelection {
    param(
        [string]$CharacterName,
        [string]$Class
    )
    
    $currentSelection = 0
    
    do {
        Show-ColorSelection $CharacterName $Class $currentSelection
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up Arrow
                $currentSelection = ($currentSelection - 1 + $DefaultColors.Count) % $DefaultColors.Count
            }
            40 { # Down Arrow  
                $currentSelection = ($currentSelection + 1) % $DefaultColors.Count
            }
            13 { # Enter
                return $DefaultColors[$currentSelection]
            }
            27 { # Escape
                return Get-RandomCharacterColor  # Use random default
            }
        }
    } while ($true)
}

function Show-CharacterCustomization {
    param(
        [hashtable]$Character,
        [int]$Position
    )
    
    Clear-Host
    
    # Title
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                           CHARACTER CREATION" -ForegroundColor Cyan
    Write-Host "                        Customize Character #$Position" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Character preview
    Write-Host "                         CHARACTER PREVIEW:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    Name:    " -NoNewline -ForegroundColor White
    Write-Host $Character.Name -ForegroundColor Green
    Write-Host "    Class:   " -NoNewline -ForegroundColor White
    Write-Host $Character.Class -ForegroundColor Green
    Write-Host "    Color:   " -NoNewline -ForegroundColor White
    Write-Host $Character.Color -ForegroundColor $Character.Color
    Write-Host "    Symbol:  " -NoNewline -ForegroundColor White
    Write-Host $Character.MapSymbol -ForegroundColor $Character.Color
    
    Write-Host ""
    Write-Host "                          CUSTOMIZATION:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    [1] Change Name" -ForegroundColor Gray
    Write-Host "    [2] Change Color" -ForegroundColor Gray
    Write-Host "    [3] Accept Character" -ForegroundColor Green
    Write-Host ""
    Write-Host "                    Select option (1-3):" -ForegroundColor DarkGray
}

function Customize-Character {
    param(
        [hashtable]$Character,
        [int]$Position
    )
    
    do {
        Show-CharacterCustomization $Character $Position
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.Character) {
            '1' {
                # Change Name
                Clear-Host
                Write-Host "Enter new name for $($Character.Class) (or press ENTER to keep '$($Character.Name)'):" -ForegroundColor Yellow
                $newName = Read-Host
                if ($newName.Trim() -ne "") {
                    $Character.Name = $newName.Trim()
                }
            }
            '2' {
                # Change Color
                $newColor = Get-ColorSelection $Character.Name $Character.Class
                $Character.Color = $newColor
            }
            '3' {
                # Accept character
                return $Character
            }
        }
    } while ($true)
}

Write-Host "Character Customization System loaded! Functions available:" -ForegroundColor Green
Write-Host "  * Show-ColorSelection - Display color picker interface" -ForegroundColor Yellow
Write-Host "  * Get-ColorSelection - Interactive color selection" -ForegroundColor Yellow
Write-Host "  * Customize-Character - Full character customization menu" -ForegroundColor Yellow
