ASCII power shell jrpg game

Thoughts for it: 

Notes to start:    
1\. When I say Ascii, I mean either Ascii or Unicode. Basically, any visual characters that can appear on a standard installation of windows in a powershell/windows terminal.   
2\.  A common font found in standard english window’s installations that contain Unicode

1) Have copilot make an engine for me  
   1) Make it so maps are uniquely identified   
      1) Give them naming schemes like: Map-”map name”-room/floor\#  
      2) Create a rule for maps where a map must be surrounded by \#  
      3) Create a rule for maps where grid numbers are placed outside of the \# edges of a map.   
      4) Metadata below \# can be given, where symbols can be assigned different colors, so something like : ‘.’ \= red and ‘^’ \= green  
         1) If that's not possible, make a different file where it's something like: MapConfig-”map name”-room/floor\#  
         2) For rotating colors, you could do something like “‘\~’ \= blue, light blue, teal \#” where the engine knows to rotate through those colors at \# frames per second   
         3) Give certain features to tiles in certain rooms, like ‘\~’ \= impassible   
         4) Maybe tiles should be in json format? Or just treat them like inherited objects?  
         5) Map Configs can include elements such as:Tile information, enemies, difficulty lvl,  
            1) Tile information can include not just colors, but also “actions” which can include conversations (such as making a tile an NPC, object of interest, or a door (which will tell which map to then load and which tile to make your character appear on said map)), or some other action  
               1) NPC’s might be able to move around on a map on their own. Might not as it might add too much slow down.  
                  1. If that is the case, have a timer/counter for movement along with directions  
   2) Create a folder layout that is easy to read and navigate.  
      1) Example: Main Directory contains: Engine Directory, Map Directory, NPC Directory, Save Files Directory, Enemy Directory and maybe a “cutscene” directory, where a special map file can be created that has automated actions occur (like scrolling text or characters automove and talk, etc.) Map Directory contains Map Name directory, Map Config Directory  
         1) Enemy Directories will contain the “Sprite” data for each monster, along with their stats, size, (difficulty level?), color, and default EXP gained.  
            1) Enemy “Sprites” are Ascii art of various sizes. So, a small enemy might be something as simple as ‘(o)’ for a floating eye enemy, a medium one might be 3x3 big like:  
               ‘   o  
                 / | \  
                   /\  ‘ as a zombie enemy. And so on and so forth  
            2) Enemy “sprites” are made similar to maps, but have a few more rules about them.   
               1) Similar to maps, they must be surrounded by ‘\#’ characters to differentiate them for easy sizing  
               2) Enemy sprites characters can have colors given to them, similar to maps.   
                  1. Not sure if each character should be mapped to a color or if I should allow for “movement”. Probably not movement unless it can be easily done without hurting performance.  
                     1. If movement is to be done, it will be like a sprite sheet.

         

   3) Create a dialogue tree file format   
      1) Might be connected to maps  
         1) Do something like “NPC-”map name”-room/floor\#  
            1) With this, you create NPC dialogue related to character descriptions that are placed on a map along with rules for those NPC’s Dialogue  
               1) Examples might include: ‘K’ NPC gives a quest. You can choose one of three options: “Accept,” “Ask More,” or “Decline.” If you Accept, a trigger counter is added so only certain dialogue will play now, a new dialogue appears, and the king will then thank you and give you some advice before ending the conversation. You will then be free to move around. If you select “Ask More” you will be given a run down of a story that led to why ‘K’ is giving you the quest. No trigger will be activated. You will then be taken back to asking if you will “Accept,” “Ask More,” or decline. If you “Accept,” the original “Accept” actions will take, including the trigger counter and new dialogue,  And if you select “Decline” the dialogue ends, and no trigger counter is activated and you can continue to move on. However, if you talk to the NPC again, the conversation will start again.   
                  1. WIth these steps, you might be able to make a very convoluted tree and “trigger” system.   
               2) Trigger systems are designed by placing variables at the top which can be either “bools” or “Switch Cases”. This makes it easier to manage choices than dealing with endless “If Else” statements.   
                  1. Trigger states will be saved in the save folder, which may contain multiple files.  
   4) Combat will be traditional random encounter, turn based combat. Nothing unique or crazy. You move around and occasionally an enemy appears. If an enemy appears, first you attack, and then the enemy attacks  
      1) A future feature might include speed of enemies and player characters, where those with higher speeds go first, and if anyone has the same speed, a coin flip will go with advantage going to player characters, and if two enemies or two player characters have the same speed, then a coin flip will decide who goes first.  
      2) If enemies are defeated (their HP \<= 0), their sprites disappear and they can no longer attack. When all enemies on a screen are defeated, the battle resolves and the player is returned back to the spot they were on when the battle started and can move freely.  
         1) When a battle resolves, the player characters are given EXP points and rewards, which can be either an item, or gold, or both. If a character gains a certain EXP amount, they will level up.  
      3) There will be occasional battles that are not random, but those are special cases (like you talk to an NPC who is actually an enemy in disguise or a boss or something) and a special fight will occur.  
      4) Random encounters are determined by the map config files, where it will say which enemies appear, what their level range is likely to be (which determines the enemy stats), the likelihood of different enemies (a common goblin might have a 50% chance of appearing in a combat, but a troll may only have a 2% chance of showing up in some rooms)  
      5) Enemy encounters and which ones appear in a specific battle will need some special calculations  
         1) There are some absolutes that must be kept in mind:  
            1) All enemies in a battle must be visible on a single combat screen  
               1) This means that there may only be able to have 4 “large” enemies to battle at a time. However, you may be able to fight up to 16 “Small” enemies on screen at a time. (these numbers are not final). However, using this logic, you may be able to have 3 “Large” enemies, and 4 “Small” enemies. (these numbers are assuming that a “battle screen” it at least 12 characters long and 12 characters down, where a large character is 4x4, with spaces on either side of them, but small are 1x1 with spaces between them)  
            2) There needs to be space to give a character action menu in the viewable area  
               1) This will always have 5 options: Main, Secondary, Item, Defend, Run  
                  1. Main: will use whatever standard attack item you have set, whether that’s a weapon, or even a spell if that is set as your main attack. A percentage will determine if you hit or not. This may be influenced by another stat (accuracy?) that a party member has.  
                  2. Secondary: will allow you to choose a non-main attack or spell. So, if your Mage has multiple spells in their roster, they can choose one that’s not their “standard” spell. Or if your mage is out of mana, you can have them use a weapon if they have one on them. The same percentage system will then occur if it’s an attack.  
                  3. This will allow you to use an item that turn instead of an attack, for instance, a healing potion, which they can give to someone else in their party, or themselves.  
                  4. Defend: This ups their defense by 50% for the remainder of that turn. After a full turn has ended (as in, after your action and the enemy action) your defense returns to normal. You can do nothing else in that turn.  
                  5. Run: If run is selected, a percentage will determine if you get away. If all four characters select run, a percentage will roll for each of them. So even if only one party member gets a successful “run” the entire party can run. However, if none of them get a successful “run”, they are left vulnerable to attack that turn. If 1 selects run, but the other 3 select Main, the order of their speed will determine what actions are taken. So if the fastest party member attacks, that attack still lands if successful, and if the second party member runs successfully, the entire party runs and the encounter ends. No EXP is gathered on a successful run, even if enemies were defeated in that encounter.  
   5) Player characters are represented by a single Ascii character that represents their class. So if a character is a “Mage” their character will be represented by ‘M’, and a Warrior will be ‘W’, and so on and so forth.  
   6) Player character party members will be chosen at the beginning of a “new game”. Your party can consist of 4 total party members with classes you select.   
      1) Party Member stats will be a standard per the class they’re in. So a Warrior might get 16 strength, 8 Intelligence, 13 Speed, 14 Defense, and a Mage might get 8 strength, 18 intelligence, 12 speed, and 6 defense. (these stats are not final and may be modified at a later time)  
      2) When a party member levels up, their stats will increase at a “pseudo random” amount, where they will have a percentage of likelihood of getting increases to certain stats. For instance, a warrior has a 85% chance of increasing their strength stat by 1 (or two) each level, but only a 40% chance of increasing their intelligence stat. For each stat, a secondary percentage is then rolled to determine if your stats go up by 1 or 2, or rarely even 3\.  
   7) There might be reasons to generate random maps as well. This is a potential future feature. 