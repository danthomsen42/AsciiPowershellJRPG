$DungeonEnemyList = @($Enemy1, $Enemy2, $Enemy4)
$EnemyList = @($Enemy1, $Enemy2)
$Enemy1 = @{
    Name    = "Test"
    Level   = 1
    HP      = 20
    Attack  = 5
    Defense = 2
    MP      = 0
    BaseXP  = 5
    Spells  = @() # Add spell names here later
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
    Attack  = 5
    Defense = 2
    MP      = 0
    BaseXP  = 5
    Spells  = @() # Add spell names here later
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
    Attack  = 5
    Defense = 2
    MP      = 0
    BaseXP  = 5
    Spells  = @() # Add spell names here later
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
    Attack  = 5
    Defense = 2
    MP      = 0
    BaseXP  = 5
    Spells  = @() # Add spell names here later
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
    Attack  = 5
    Defense = 2
    MP      = 0
    BaseXP  = 5
    Spells  = @() # Add spell names here later
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