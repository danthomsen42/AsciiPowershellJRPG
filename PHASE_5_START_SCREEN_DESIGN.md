# =============================================================================
# PHASE 5: START SCREEN & CHARACTER CREATION SYSTEM - DESIGN DOCUMENT
# =============================================================================

## OVERVIEW
This phase transforms the game from a development prototype into a professional, 
complete gaming experience with proper presentation, story introduction, and 
character customization - inspired by classic 8-bit and 16-bit JRPGs.

## PHASE 5.1: MAIN MENU & START SCREEN DESIGN

### Visual Layout Concept
```
╔══════════════════════════════════════════════════════════════════════════════╗
║ Credits: ASCII Art by https://textart.io | Story by... | Music from...     ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║    ╔══════════════════════════════════════════════════════════════════╗      ║
║    ║                    ASCII QUEST CHRONICLES                        ║      ║
║    ║              ___   ____   ____  ____  ____                      ║      ║
║    ║             / _ \ / ___| / ___||  _ \|  _ \                     ║      ║
║    ║            | |_| |\___ \| |    | |_) | |_) |                    ║      ║
║    ║             \__ /  ___) | |___ |  _ <|  __/                     ║      ║
║    ║              \_/  |____/ \____||_| \_\_|                       ║      ║
║    ║                                                                  ║      ║
║    ║                    ⚔️  A PowerShell Adventure  ⚔️                ║      ║
║    ╚══════════════════════════════════════════════════════════════════╝      ║
║                                                                              ║
║                              📜 NEW GAME                                    ║
║                              💾 LOAD GAME                                   ║
║                              ⚙️  SETTINGS                                   ║
║                              📋 CREDITS                                     ║
║                              🚪 EXIT                                        ║
║                                                                              ║
║                          [Use ↑↓ to navigate, Enter to select]             ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

### Features
- **Scrolling Credits Bar**: Continuously scrolling attribution at top/bottom
- **ASCII Title Art**: Large, impressive game logo/title
- **Menu Navigation**: Arrow keys + Enter, with visual highlighting
- **Animated Elements**: Subtle decorative animations (optional)
- **Audio Integration**: Menu navigation sounds (future)

### Menu Options
1. **NEW GAME** → Character Creation System (5.3)
2. **LOAD GAME** → Enhanced Save Slot Selection (5.4)
3. **SETTINGS** → Settings Menu (Phase 4.3)
4. **CREDITS** → Full credits screen with contributors
5. **EXIT** → Graceful game termination

## PHASE 5.2: STORY INTRO SEQUENCE DESIGN

### Classic RPG Intro Flow
```
Screen 1: World Setup
╔══════════════════════════════════════════════════════════════════════════════╗
║                          🌟 Long ago... 🌟                                  ║
║                                                                              ║
║    In the realm of Aethermoor, ancient magics once flowed freely            ║
║    through crystal veins beneath the earth. The Five Kingdoms               ║
║    prospered under the protection of the Celestial Guardians...             ║
║                                                                              ║
║                              [ASCII Art of a Crystal]                       ║
║                                     ✧                                       ║
║                                   ╱╲ ╱╲                                     ║
║                                  ╱  ╲╱  ╲                                   ║
║                                 ╱________╲                                   ║
║                                                                              ║
║                          [Press SPACE to continue...]                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

Screen 2: The Crisis
╔══════════════════════════════════════════════════════════════════════════════╗
║                        ⚡ But darkness came... ⚡                           ║
║                                                                              ║
║    The Shadow Cult shattered the Great Crystal, severing the               ║
║    magical bonds that protected the realm. Monsters now roam               ║
║    freely, and the kingdoms have fallen to chaos...                        ║
║                                                                              ║
║                          [ASCII Art of Broken Crystal]                      ║
║                                     ⚡                                       ║
║                                   ╱ ╲                                       ║
║                                  ╱   ╲                                      ║
║                                 ╱_____╲                                     ║
║                                    💥                                       ║
║                                                                              ║
║                          [Press SPACE to continue...]                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

Screen 3: The Call to Adventure
╔══════════════════════════════════════════════════════════════════════════════╗
║                        🗡️  A new hope emerges... 🗡️                        ║
║                                                                              ║
║    You are among the chosen few who can still channel the ancient          ║
║    magic. Gather your companions, brave the corrupted lands, and           ║
║    restore the crystal shards to save Aethermoor!                          ║
║                                                                              ║
║                              [ASCII Art of Heroes]                          ║
║                                  @  @  @  @                                 ║
║                                 /|\/|\/|\/|\                                ║
║                                  ^  ^  ^  ^                                 ║
║                                                                              ║
║                      [Press SPACE to begin your quest...]                   ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

### Features
- **Multi-Screen Narrative**: 3-5 screens with story progression
- **ASCII Illustrations**: Visual elements to accompany each story beat
- **Pacing Control**: Manual advancement with SPACE key
- **Skip Option**: ESC key to skip for repeat playthroughs
- **Story State Saving**: Remember if intro has been seen

## PHASE 5.3: CHARACTER CREATION SYSTEM DESIGN

### Final Fantasy 1 Inspired Flow

#### Step 1: Party Size Selection
```
╔══════════════════════════════════════════════════════════════════════════════╗
║                        🏰 Form Your Adventure Party 🏰                      ║
║                                                                              ║
║        How many companions will join you on this perilous quest?            ║
║                                                                              ║
║                              ○ Solo Adventure (1 Hero)                      ║
║                              ● Classic Party (4 Heroes) [RECOMMENDED]       ║
║                              ○ Small Band (2 Heroes)                        ║
║                              ○ Trio Quest (3 Heroes)                        ║
║                                                                              ║
║                          [Use ↑↓ to select, Enter to confirm]              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

#### Step 2: Class Selection (for each character)
```
╔══════════════════════════════════════════════════════════════════════════════╗
║                        ⚔️  Choose Your Class  ⚔️                           ║
║                                Character 1 of 4                             ║
║                                                                              ║
║   ┌─ WARRIOR ─┐   ┌─ MAGE ────┐   ┌─ HEALER ──┐   ┌─ ROGUE ───┐            ║
║   │    ⚔️     │   │    🔮     │   │    ✨     │   │    🗡️     │            ║
║   │           │   │           │   │           │   │           │            ║
║   │ High HP   │   │ High MP   │   │ Healing   │   │ High Speed│            ║
║   │ Strong    │   │ Spells    │   │ Support   │   │ Critical  │            ║
║   │ Defense   │   │ Elemental │   │ Magic     │   │ Hits      │            ║
║   │           │   │ Damage    │   │           │   │ Stealth   │            ║
║   └───────────┘   └───────────┘   └───────────┘   └───────────┘            ║
║                                                                              ║
║              Starting Stats: HP: 35  MP: 5   ATK: 8   DEF: 6               ║
║              Starting Weapon: Iron Sword    Armor: Chain Mail               ║
║                                                                              ║
║                          [Use ←→ to select, Enter to confirm]              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

#### Step 3: Name Entry
```
╔══════════════════════════════════════════════════════════════════════════════╗
║                          📝 Name Your Hero 📝                              ║
║                             Warrior - Character 1                           ║
║                                                                              ║
║                    What shall this brave warrior be called?                 ║
║                                                                              ║
║                              Name: [________]                               ║
║                                                                              ║
║                              Suggestions:                                   ║
║                            • Gareth    • Theron                            ║
║                            • Lyanna    • Cassian                           ║
║                            • Random    • Default                           ║
║                                                                              ║
║                   [Type name or select suggestion with ↑↓]                 ║
║                        [Enter to confirm, ESC to go back]                   ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

#### Step 4: Party Summary & Confirmation
```
╔══════════════════════════════════════════════════════════════════════════════╗
║                        🎊 Your Adventure Party 🎊                          ║
║                                                                              ║
║   1. Gareth    [Warrior] ⚔️   HP: 35  MP: 5   ATK: 8   DEF: 6              ║
║   2. Mystara   [Mage]    🔮   HP: 20  MP: 15  ATK: 4   DEF: 3              ║
║   3. Celeste   [Healer]  ✨   HP: 25  MP: 12  ATK: 5   DEF: 4              ║
║   4. Raven     [Rogue]   🗡️   HP: 28  MP: 7   ATK: 7   DEF: 5              ║
║                                                                              ║
║              Are you ready to begin your quest to save Aethermoor?          ║
║                                                                              ║
║                         [B]egin Adventure    [R]edo Party                   ║
║                                                                              ║
║          "May the ancient magics guide your path, brave adventurers..."     ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

### Character Classes Details

#### 🗡️ WARRIOR
- **Primary Role**: Tank/Physical DPS
- **Starting Stats**: High HP (35), Low MP (5), High ATK (8), High DEF (6)
- **Starting Equipment**: Iron Sword, Chain Mail
- **Abilities**: Shield Wall, Power Attack, Taunt
- **Growth**: +3 HP, +1 ATK, +1 DEF per level

#### 🔮 MAGE  
- **Primary Role**: Magical DPS/Elemental
- **Starting Stats**: Low HP (20), High MP (15), Low ATK (4), Low DEF (3)
- **Starting Equipment**: Oak Staff, Cloth Robes
- **Abilities**: Fire, Ice, Lightning, Magic Missile
- **Growth**: +2 HP, +3 MP, +1 ATK per level

#### ✨ HEALER
- **Primary Role**: Support/Healing
- **Starting Stats**: Medium HP (25), High MP (12), Low ATK (5), Medium DEF (4)
- **Starting Equipment**: Blessed Mace, Holy Vestments
- **Abilities**: Heal, Cure, Protect, Blessing
- **Growth**: +2 HP, +2 MP, +1 DEF per level

#### 🗡️ ROGUE
- **Primary Role**: Speed/Critical Damage
- **Starting Stats**: Medium HP (28), Low MP (7), High ATK (7), Medium DEF (5)
- **Starting Equipment**: Silver Dagger, Leather Armor
- **Abilities**: Backstab, Steal, Hide, Poison Strike
- **Growth**: +2 HP, +1 MP, +2 ATK per level

## PHASE 5.4: ENHANCED LOAD GAME INTEGRATION

### Save Slot Display Design
```
╔══════════════════════════════════════════════════════════════════════════════╗
║                             💾 Load Game 💾                                ║
║                                                                              ║
║ Slot 1: ┌─────────────────────────────────────────────────────────────────┐ ║
║         │ The Crystal Seekers          Play Time: 2h 34m    Aug 4, 2025   │ ║
║         │ Gareth⚔️Lv3  Myst🔮Lv3  Cel✨Lv3  Rav🗡️Lv3   📍 Crystal Caves  │ ║
║         └─────────────────────────────────────────────────────────────────┘ ║
║                                                                              ║
║ Slot 2: ┌─────────────────────────────────────────────────────────────────┐ ║
║         │ [Empty Slot]                                                     │ ║
║         └─────────────────────────────────────────────────────────────────┘ ║
║                                                                              ║
║ Slot 3: ┌─────────────────────────────────────────────────────────────────┐ ║
║         │ Solo Hero Run               Play Time: 45m      Aug 3, 2025    │ ║
║         │ Adventurer⚔️Lv5                              📍 Town Square     │ ║
║         └─────────────────────────────────────────────────────────────────┘ ║
║                                                                              ║
║            [↑↓ Select] [Enter Load] [Del Delete] [ESC Back to Menu]         ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## TECHNICAL IMPLEMENTATION PLAN

### File Structure
```
StartScreen.ps1       # Main menu and navigation
StoryIntro.ps1        # Intro sequence management  
CharacterCreation.ps1 # Party creation system
Credits.ps1           # Scrolling credits system
```

### Integration Points
1. **Entry Point**: Modify Display.ps1 to start with StartScreen.ps1
2. **Save System**: Extend Phase 1.4 save system for party data
3. **Party System**: Requires Phase 2.1 multi-character support
4. **Settings**: Integrate with Phase 4.3 settings menu

### Development Milestones
- **Week 1**: Basic start screen menu and navigation
- **Week 2**: Story intro sequence with skip functionality  
- **Week 3**: Character creation system (requires Party System)
- **Week 4**: Enhanced load game integration and polish

## CLASSIC RPG INSPIRATIONS

### Visual Style References
- **Final Fantasy 1**: Class selection, party naming
- **Dragon Quest**: Story intro presentation
- **Chrono Trigger**: Menu aesthetics and flow
- **Secret of Mana**: Character creation UI

### Modern Touches
- **Save file thumbnails** with party composition
- **Random name generators** for each class
- **Skip options** for experienced players
- **Credits attribution** for community resources

This system will transform your game from a prototype into a complete, professional 
RPG experience that rivals classic 8-bit and 16-bit adventures!
