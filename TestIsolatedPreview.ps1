# Test the Get-SaveFilePreview function in isolation

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

Write-Host "Testing isolated Get-SaveFilePreview function..." -ForegroundColor Yellow

# Find a save file to test with
$saveFiles = Get-ChildItem "$PSScriptRoot\saves" -Filter "*.json" | Sort-Object CreationTime -Descending
if ($saveFiles.Count -gt 0) {
    $testFile = $saveFiles[0].FullName
    Write-Host "Testing with: $($saveFiles[0].Name)" -ForegroundColor Cyan
    
    $result = Get-SaveFilePreview $testFile
    Write-Host "Preview result:" -ForegroundColor White
    $result | Format-List
} else {
    Write-Host "No save files found to test with" -ForegroundColor Yellow
}
