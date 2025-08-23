# =============================================================================
# SIMPLE START SCREEN TEST
# =============================================================================

$global:SimpleTitleArt = @"
  ╔══════════════════════════════════════════════════════════════════════════╗
  ║                                                                          ║
  ║     █████╗ ███████╗ ██████╗██╗██╗    ██████╗  ██████╗ ██╗    ██╗███████╗ ║
  ║    ██╔══██╗██╔════╝██╔════╝██║██║    ██╔══██╗██╔═══██╗██║    ██║██╔════╝ ║
  ║    ███████║███████╗██║     ██║██║    ██████╔╝██║   ██║██║ █╗ ██║█████╗   ║
  ║    ██╔══██║╚════██║██║     ██║██║    ██╔═══╝ ██║   ██║██║███╗██║██╔══╝   ║
  ║    ██║  ██║███████║╚██████╗██║██║    ██║     ╚██████╔╝╚███╔███╔╝███████╗ ║
  ║    ╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝╚═╝    ╚═╝      ╚═════╝  ╚══╝╚══╝ ╚══════╝ ║
  ║                                                                          ║
  ║                        PowerShell JRPG Adventure                         ║
  ║                                                                          ║
  ╚══════════════════════════════════════════════════════════════════════════╝
"@

function Show-SimpleMenu {
    $menuItems = @("New Game", "Load Game", "Settings", "Exit")
    $currentSelection = 0
    
    Write-Host $global:SimpleTitleArt -ForegroundColor Cyan
    Write-Host ""
    Write-Host "MAIN MENU" -ForegroundColor Yellow
    Write-Host "=========" -ForegroundColor DarkYellow
    Write-Host ""
    
    for ($i = 0; $i -lt $menuItems.Count; $i++) {
        $prefix = if ($i -eq $currentSelection) { "> " } else { "  " }
        $color = if ($i -eq $currentSelection) { "White" } else { "Gray" }
        Write-Host "$prefix$($menuItems[$i])" -ForegroundColor $color
    }
    
    Write-Host ""
    Write-Host "Use arrow keys and ENTER to navigate"
}

Write-Host "Simple Start Screen Test loaded!" -ForegroundColor Green
