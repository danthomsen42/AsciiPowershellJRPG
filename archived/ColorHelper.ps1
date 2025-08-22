# Helper script to find coordinates for coloring tiles
# This shows the current player position and helps you identify coordinates

Write-Host "=== COLOR COORDINATE HELPER ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "HOW TO FIND COORDINATES FOR COLORING:" -ForegroundColor Yellow
Write-Host "1. Run your game (.\Display.ps1)" -ForegroundColor White
Write-Host "2. Move your player (@) to the tile you want to color" -ForegroundColor White  
Write-Host "3. Look at the header: 'Map: Town | Player: (X,Y)'" -ForegroundColor White
Write-Host "4. Those (X,Y) numbers are the coordinates to use!" -ForegroundColor White
Write-Host ""

Write-Host "EXAMPLE WORKFLOW:" -ForegroundColor Green
Write-Host "1. Move player to a tree (#) - see 'Player: (15,8)'" -ForegroundColor White
Write-Host "2. Add this line to ColorZones.ps1:" -ForegroundColor White
Write-Host '   "15,8" = @{ Char = "#"; Color = "DarkYellow" }' -ForegroundColor DarkYellow
Write-Host "3. Save and restart game - tree should be brown!" -ForegroundColor White
Write-Host ""

Write-Host "QUICK COLOR TEST IDEAS:" -ForegroundColor Magenta
Write-Host "- Find a few grass dots (.) and make them different shades of green" -ForegroundColor White
Write-Host "- Find tree symbols (#) and make them brown (DarkYellow)" -ForegroundColor White
Write-Host "- Find walls (| or -) and make them gray" -ForegroundColor White
Write-Host "- Find water (~) and make it blue" -ForegroundColor White
Write-Host "- Find doors (+) and make them yellow" -ForegroundColor White
Write-Host ""

Write-Host "PERFORMANCE TIP:" -ForegroundColor Red
Write-Host "Only add colors to tiles you can actually see in the game." -ForegroundColor White
Write-Host "The system is fast because it only processes the specific positions you define!" -ForegroundColor White

Read-Host "Press Enter to continue"
