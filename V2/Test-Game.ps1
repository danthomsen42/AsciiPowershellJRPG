# Quick test script - verifies all modules load and basic data works
$ErrorActionPreference = 'Stop'
$Script:GameRoot = $PSScriptRoot

try {
    . "$Script:GameRoot\Engine\Renderer.ps1"
    Write-Host "OK: Renderer.ps1" -ForegroundColor Green

    . "$Script:GameRoot\Engine\Input.ps1"
    Write-Host "OK: Input.ps1" -ForegroundColor Green

    . "$Script:GameRoot\Engine\CharacterEngine.ps1"
    Write-Host "OK: CharacterEngine.ps1" -ForegroundColor Green

    . "$Script:GameRoot\Engine\MapEngine.ps1"
    Write-Host "OK: MapEngine.ps1" -ForegroundColor Green

    . "$Script:GameRoot\Engine\CombatEngine.ps1"
    Write-Host "OK: CombatEngine.ps1" -ForegroundColor Green

    . "$Script:GameRoot\Engine\DialogueEngine.ps1"
    Write-Host "OK: DialogueEngine.ps1" -ForegroundColor Green

    . "$Script:GameRoot\Engine\ShopEngine.ps1"
    Write-Host "OK: ShopEngine.ps1" -ForegroundColor Green

    . "$Script:GameRoot\Engine\PartyManagement.ps1"
    Write-Host "OK: PartyManagement.ps1" -ForegroundColor Green

    . "$Script:GameRoot\Engine\QuestEngine.ps1"
    Write-Host "OK: QuestEngine.ps1" -ForegroundColor Green

    . "$Script:GameRoot\Engine\SaveLoad.ps1"
    Write-Host "OK: SaveLoad.ps1" -ForegroundColor Green

    . "$Script:GameRoot\Engine\Core.ps1"
    Write-Host "OK: Core.ps1" -ForegroundColor Green

    # Test class loading
    Load-ClassDefinitions
    $classNames = ($Script:ClassDefinitions.classes | ForEach-Object { $_.name }) -join ", "
    Write-Host "Classes: $classNames" -ForegroundColor Cyan

    # Test party member creation (now includes Accessory slot)
    $testMember = New-PartyMember -Name "TestWarrior" -ClassName "Warrior"
    Write-Host "Created: $($testMember.Name) HP:$($testMember.HP) STR:$($testMember.Strength) Accessory:$($testMember.Equipment.Accessory)" -ForegroundColor Cyan

    # Test map loading
    $map = Load-Map -MapName "Map-TestTown-1"
    Write-Host "Map: $($map.Name) ($($map.Width)x$($map.Height))" -ForegroundColor Cyan

    # Test config loading
    $config = Load-MapConfig -ConfigName "MapConfig-TestTown-1"
    Write-Host "Config: $($config.displayName)" -ForegroundColor Cyan

    # Test start position
    $sx = [int]$config.startPosition.x
    $sy = [int]$config.startPosition.y
    $startTile = $map.Tiles[$sx, $sy]
    $passable = Test-TilePassable -TileChar $startTile -MapConfig $config
    Write-Host "Start position ($sx, $sy): tile='$startTile' passable=$passable" -ForegroundColor Cyan

    # Test cavern map
    $caveMap = Load-Map -MapName "Map-DarkCavern-1"
    $caveConfig = Load-MapConfig -ConfigName "MapConfig-DarkCavern-1"
    Write-Host "Cave: $($caveMap.Name) ($($caveMap.Width)x$($caveMap.Height)) - $($caveConfig.displayName)" -ForegroundColor Cyan

    # Test shop map
    $shopMap = Load-Map -MapName "Map-Shop-1"
    $shopConfig = Load-MapConfig -ConfigName "MapConfig-Shop-1"
    Write-Host "Shop: $($shopMap.Name) ($($shopMap.Width)x$($shopMap.Height)) - $($shopConfig.displayName)" -ForegroundColor Cyan

    # Test shop data loading
    $shopData = Get-ShopData -ShopId 'general_store'
    Write-Host "Shop items: $($shopData.inventory.Count) items in general_store" -ForegroundColor Cyan

    # Test item definitions
    $potionDef = Get-ItemDefinition -ItemId 'potion'
    $swordDef  = Get-ItemDefinition -ItemId 'iron_sword'
    Write-Host "Items: $($potionDef.name) (buy:$($potionDef.buyPrice)), $($swordDef.name) (buy:$($swordDef.buyPrice))" -ForegroundColor Cyan

    # Test quest loading
    Load-QuestDefinitions
    $questCount = $Script:QuestDefinitions.Count
    Write-Host "Quests: $questCount defined" -ForegroundColor Cyan

    # Test secrets loading
    Load-SecretDefinitions
    $secretMapCount = ($Script:SecretDefinitions.PSObject.Properties | Measure-Object).Count
    Write-Host "Secret maps: $secretMapCount maps with secrets" -ForegroundColor Cyan

    # Test renderer init
    Initialize-Renderer
    Write-Host "Renderer initialized" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "ALL TESTS PASSED!" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "At: $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
}
