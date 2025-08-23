# =============================================================================
# PARTY COLOR CUSTOMIZATION SYSTEM  
# =============================================================================
# Functions to customize party member colors after party creation

function Show-PartyColorCustomization {
    Clear-Host
    
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                          PARTY COLOR CUSTOMIZATION" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $global:Party -or $global:Party.Count -eq 0) {
        Write-Host "No party found! Create a party first." -ForegroundColor Red
        return
    }
    
    Write-Host "  Current Party Colors:" -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 0; $i -lt $global:Party.Count; $i++) {
        $member = $global:Party[$i]
        $position = $i + 1
        
        Write-Host "    [$position] " -NoNewline -ForegroundColor White
        Write-Host "$($member.Name)" -NoNewline -ForegroundColor Green
        Write-Host " the " -NoNewline -ForegroundColor White
        Write-Host "$($member.Class)" -NoNewline -ForegroundColor Green
        Write-Host " - Color: " -NoNewline -ForegroundColor White
        Write-Host $member.Color -ForegroundColor $member.Color
    }
    
    Write-Host ""
    Write-Host "  Select a party member to change their color (1-$($global:Party.Count)):" -ForegroundColor DarkGray
    Write-Host "  Press ESC to exit" -ForegroundColor DarkGray
}

function Set-PartyMemberColor {
    param(
        [int]$MemberIndex,
        [string]$NewColor
    )
    
    if (-not $global:Party -or $MemberIndex -lt 0 -or $MemberIndex -ge $global:Party.Count) {
        Write-Host "Invalid party member index!" -ForegroundColor Red
        return
    }
    
    # Validate color
    if ($DefaultColors -notcontains $NewColor) {
        Write-Host "Invalid color! Available colors: $($DefaultColors -join ', ')" -ForegroundColor Red
        return
    }
    
    $oldColor = $global:Party[$MemberIndex].Color
    $global:Party[$MemberIndex].Color = $NewColor
    
    Write-Host "Changed $($global:Party[$MemberIndex].Name)'s color from $oldColor to $NewColor" -ForegroundColor Green
}

function Start-PartyColorCustomization {
    if (-not $global:Party -or $global:Party.Count -eq 0) {
        Write-Host "No party found! Create a party first." -ForegroundColor Red
        return
    }
    
    do {
        Show-PartyColorCustomization
        $key = [Console]::ReadKey($true)
        
        if ($key.Key -eq "Escape") {
            break
        }
        
        # Check if it's a number key (1-4)
        $memberNum = [int]::TryParse($key.KeyChar, [ref]$null)
        if ($memberNum -and $memberNum -ge 1 -and $memberNum -le $global:Party.Count) {
            $memberIndex = $memberNum - 1
            $member = $global:Party[$memberIndex]
            
            Write-Host "`nSelected: $($member.Name) the $($member.Class)" -ForegroundColor Yellow
            Write-Host "Current color: " -NoNewline -ForegroundColor White
            Write-Host $member.Color -ForegroundColor $member.Color
            Write-Host ""
            
            # Get new color selection
            $newColor = Get-ColorSelection $member.Name $member.Class
            if ($newColor) {
                Set-PartyMemberColor $memberIndex $newColor
                Write-Host "Color updated! Press any key to continue..." -ForegroundColor Green
                [Console]::ReadKey($true) | Out-Null
            }
        }
    } while ($true)
    
    Write-Host "`nParty color customization complete!" -ForegroundColor Green
}

function Get-PartyColorSummary {
    if (-not $global:Party -or $global:Party.Count -eq 0) {
        Write-Host "No party found!" -ForegroundColor Red
        return
    }
    
    Write-Host "Party Color Summary:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $global:Party.Count; $i++) {
        $member = $global:Party[$i]
        Write-Host "  $($i + 1). " -NoNewline -ForegroundColor White
        Write-Host "$($member.Name) ($($member.Class))" -NoNewline -ForegroundColor Green
        Write-Host " - " -NoNewline -ForegroundColor White
        Write-Host $member.Color -ForegroundColor $member.Color
    }
}

Write-Host "Party Color Customization System loaded!" -ForegroundColor Green
Write-Host "  * Start-PartyColorCustomization - Interactive color customization menu" -ForegroundColor Yellow
Write-Host "  * Set-PartyMemberColor - Set specific member's color directly" -ForegroundColor Yellow
Write-Host "  * Get-PartyColorSummary - Display current party colors" -ForegroundColor Yellow
