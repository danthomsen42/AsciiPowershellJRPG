$DungeonEnemyList = @($Enemy1, $Enemy2, $Enemy4)
$EnemyList = @($Enemy1, $Enemy2)
$Enemy1 = @{
    Name    = "Test"
    Level   = 1
    HP      = 20
    MaxHP   = 20
    Attack  = 5
    Defense = 2
    Speed   = 5
    MP      = 0
    MaxMP   = 0
    BaseXP  = 5
    Spells  = @() # Basic enemy - no spells
    Art     = @(
        "##########",
        "# (#_#)/ #",
        "#  -|-/  #",
        "# / ^    #",
        "#  / \   #",
        "##########"
    )
}

$Enemy2 = @{
    Name    = "Test2"
    Level   = 2
    HP      = 24
    MaxHP   = 24
    Attack  = 5
    Defense = 2
    Speed   = 7
    MP      = 6
    MaxMP   = 6
    BaseXP  = 5
    Spells  = @("Fire") # Fire caster
    Art     = @(
        "#########",
        "# \^_^/ #",
        "#########"
    )
}

$Enemy3 = @{
    Name    = "Test3"
    Level   = 3
    HP      = 26
    MaxHP   = 26
    Attack  = 5
    Defense = 2
    Speed   = 6
    MP      = 8
    MaxMP   = 8
    BaseXP  = 5
    Spells  = @("Ice", "Fire") # Dual element caster
    Art     = @(
        "#########",
        "# \v_v/ #",
        "#########"
    )
}

$Enemy4 = @{
    Name    = "Test4"
    Level   = 4
    HP      = 28
    MaxHP   = 28
    Attack  = 5
    Defense = 2
    Speed   = 4
    MP      = 9
    MaxMP   = 9
    BaseXP  = 5
    Spells  = @("Heal") # Healing enemy
    Art     = @(
        "                        \||/",
        "                |  @___oo   ",
        "      /\  /\   / (__,,,,|   ",
        "     ) /^\) ^\/ _)          ",
        "     ) <  /^\/   _)         ",
        "     )   _ /  / _)          ",
        " /\  )/\/ ||  | )_)         ",
        "<  >      |(,,) )__)        ",
        " ||      /    \)___)\       ",
        " | \___(      )___) )___    ",
        "  \______(_______;;; __;;;  "
    )
    #https://www.asciiart.eu/mythology/dragons
}

$Enemy5 = @{
    Name    = "Test5"
    Level   = 4
    HP      = 28
    MaxHP   = 28
    Attack  = 5
    Defense = 2
    Speed   = 9
    MP      = 12
    MaxMP   = 12
    BaseXP  = 5
    Spells  = @("Fire", "Ice", "Heal") # Advanced caster
    Art     = @(
        "                       ",
        "       __________      ",
        "      /          \     ",
        "      |   \   /  |     ",
        "      |     O    |     ",
        "      |          |     ",
        "      |/\/\/\/\/\|     ",
        "                       ",
        "                       "
    )
}