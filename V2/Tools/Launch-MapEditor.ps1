<#
.SYNOPSIS
    Launches the ASCII JRPG Map Editor in your default browser.

.DESCRIPTION
    Opens the MapEditor.html file directly in your default browser.
    No server, no dependencies — the editor uses the browser's
    File System Access API (Chrome / Edge) to read and write
    map files directly in your Data\Maps folder.

.NOTES
    If your default browser is not Chrome or Edge, the
    "Open Folder" feature won't work. In that case, use the
    Import/Export buttons instead, or open the file manually
    in Chrome or Edge.
#>

$editorPath = Join-Path $PSScriptRoot 'MapEditor.html'

if (-not (Test-Path $editorPath)) {
    Write-Host "ERROR: MapEditor.html not found at: $editorPath" -ForegroundColor Red
    Write-Host "Make sure this script is in the Tools\ folder alongside MapEditor.html." -ForegroundColor Yellow
    Read-Host 'Press Enter to exit'
    exit 1
}

# Prefer Edge or Chrome for File System Access API support
$edgePath   = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$chromePath  = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
$chromePath2 = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"

$fileUri = "file:///$($editorPath -replace '\\','/')"

if (Test-Path $edgePath) {
    Write-Host 'Launching Map Editor in Microsoft Edge...' -ForegroundColor Cyan
    Start-Process $edgePath $fileUri
}
elseif (Test-Path $chromePath) {
    Write-Host 'Launching Map Editor in Google Chrome...' -ForegroundColor Cyan
    Start-Process $chromePath $fileUri
}
elseif (Test-Path $chromePath2) {
    Write-Host 'Launching Map Editor in Google Chrome...' -ForegroundColor Cyan
    Start-Process $chromePath2 $fileUri
}
else {
    Write-Host 'Launching Map Editor in default browser...' -ForegroundColor Cyan
    Write-Host '  Note: "Open Folder" requires Chrome or Edge.' -ForegroundColor Yellow
    Start-Process $fileUri
}

Write-Host 'Map Editor launched! You can close this window.' -ForegroundColor Green
