# Stick figure waving animation in PowerShell
# Loops until user presses 'Q' or 'Enter'

# Define frames
$frames = @'
  o
 /|\
 / \
'@, @'
  o
 \|\
 / \
'@, @'
  o
 \|/
 / \
'@, @'
  o
 \|\
 / \
'@

# Set console to not display pressed keys
[Console]::TreatControlCAsInput = $true

Write-Host "Press 'Q' or 'Enter' to quit..." -ForegroundColor Cyan

# Loop until key is pressed
while ($true) {
    foreach ($frame in $frames) {
        # Check if a key was pressed
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq 'Q' -or $key.Key -eq 'Enter') {
                break 2  # Exit both loops
            }
        }

        Clear-Host
        Write-Host "Press 'Q' or 'Enter' to quit..." -ForegroundColor Cyan
        Write-Host $frame
        Start-Sleep -Milliseconds 300
    }
}
