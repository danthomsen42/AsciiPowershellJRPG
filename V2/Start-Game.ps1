# Start-Game.ps1 - ASCII PowerShell JRPG Entry Point
# Run this script to start the game: .\Start-Game.ps1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Script:GameRoot = $PSScriptRoot

# Store original console state for restoration
$Script:OriginalTitle = $Host.UI.RawUI.WindowTitle
$Script:OriginalCursorVisible = [Console]::CursorVisible
$Script:OriginalFgColor = [Console]::ForegroundColor
$Script:OriginalBgColor = [Console]::BackgroundColor

try {
    # Set up console
    [Console]::Title = "ASCII JRPG - Thornvale Chronicles"
    [Console]::CursorVisible = $false
    [Console]::BackgroundColor = 'Black'
    [Console]::ForegroundColor = 'Gray'

    # Enable UTF-8 for proper Unicode character display (box-drawing, special chars, etc.)
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null

    # Attempt to set console size
    try {
        # Buffer must be >= window, so set buffer first if enlarging
        $targetWidth = 120
        $targetHeight = 30
        if ([Console]::BufferWidth -lt $targetWidth) { [Console]::BufferWidth = $targetWidth }
        if ([Console]::BufferHeight -lt $targetHeight) { [Console]::BufferHeight = $targetHeight }
        if ([Console]::WindowWidth -lt $targetWidth) { [Console]::WindowWidth = $targetWidth }
        if ([Console]::WindowHeight -lt $targetHeight) { [Console]::WindowHeight = $targetHeight }
    }
    catch {
        Write-Warning "Could not resize console. Please ensure your terminal is at least 120x30."
        Write-Warning "Press any key to continue anyway..."
        [Console]::ReadKey($true) | Out-Null
    }

    [Console]::Clear()

    # Dot-source engine modules in dependency order
    . "$Script:GameRoot\Engine\Renderer.ps1"
    . "$Script:GameRoot\Engine\Input.ps1"
    . "$Script:GameRoot\Engine\CharacterEngine.ps1"
    . "$Script:GameRoot\Engine\MapEngine.ps1"
    . "$Script:GameRoot\Engine\CombatEngine.ps1"
    . "$Script:GameRoot\Engine\DialogueEngine.ps1"
    . "$Script:GameRoot\Engine\ShopEngine.ps1"
    . "$Script:GameRoot\Engine\PartyManagement.ps1"
    . "$Script:GameRoot\Engine\QuestEngine.ps1"
    . "$Script:GameRoot\Engine\CutsceneEngine.ps1"
    . "$Script:GameRoot\Engine\SaveLoad.ps1"
    . "$Script:GameRoot\Engine\Core.ps1"

    # Start the game
    Initialize-Game
    Start-GameLoop
}
catch {
    # Show error before restoring console
    [Console]::CursorVisible = $true
    [Console]::SetCursorPosition(0, 0)
    Write-Host "FATAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    [Console]::ReadKey($true) | Out-Null
}
finally {
    # Restore console state
    [Console]::CursorVisible = $Script:OriginalCursorVisible
    [Console]::Title = $Script:OriginalTitle
    [Console]::ForegroundColor = $Script:OriginalFgColor
    [Console]::BackgroundColor = $Script:OriginalBgColor
    [Console]::Clear()
    Write-Host "Thanks for playing!" -ForegroundColor Cyan
}
