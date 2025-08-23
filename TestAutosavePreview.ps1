# Test the Get-SaveFilePreview function with autosave.json

function Get-SaveFilePreview {
    param($saveFilePath)
    <#
    Get preview information from enhanced save file
    #>
    
    try {
        $saveData = Get-Content $saveFilePath -Raw | ConvertFrom-Json
        
        # Extract info from enhanced save structure
        $location = if ($saveData.Location.CurrentMap) { $saveData.Location.CurrentMap } else { "Unknown" }
        
        # Get first party member info (leader)
        if ($saveData.Party.Members -and $saveData.Party.Members.Count -gt 0) {
            $leader = $saveData.Party.Members[0]
            return @{
                Location = $location
                Level = $leader.Level
                HP = $leader.HP
                MaxHP = $leader.MaxHP
                PartySize = $saveData.Party.Members.Count
                SaveType = $saveData.GameInfo.SaveType
                PlayTime = $saveData.GameInfo.PlayTime
            }
        } else {
            # Fallback for saves without party data
            return @{
                Location = $location
                Level = "?"
                HP = "?"
                MaxHP = "?"
                PartySize = 0
                SaveType = "unknown"
                PlayTime = 0
            }
        }
    }
    catch {
        return @{
            Location = "Unknown"
            Level = "?"
            HP = "?"
            MaxHP = "?"
            PartySize = 0
            SaveType = "corrupted"
            PlayTime = 0
        }
    }
}

Write-Host "Testing Get-SaveFilePreview with autosave.json..." -ForegroundColor Yellow

$testFile = "$PSScriptRoot\saves\autosave.json"
if (Test-Path $testFile) {
    Write-Host "Testing with: autosave.json" -ForegroundColor Cyan
    
    $result = Get-SaveFilePreview $testFile
    Write-Host "Preview result:" -ForegroundColor White
    $result | Format-List
    
    # Also show raw save data structure
    Write-Host "`nRaw save data structure:" -ForegroundColor Yellow
    $rawData = Get-Content $testFile -Raw | ConvertFrom-Json
    Write-Host "Location: $($rawData.Location)" -ForegroundColor Gray
    Write-Host "Party: $($rawData.Party)" -ForegroundColor Gray
    Write-Host "GameInfo: $($rawData.GameInfo)" -ForegroundColor Gray
} else {
    Write-Host "autosave.json not found" -ForegroundColor Red
}
