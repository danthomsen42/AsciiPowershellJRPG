# ASCII JRPG - The Thornvale Chronicles
## Comprehensive Modding & Content Creation Guide

> A complete reference for understanding, modifying, and expanding the game.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Getting Started](#2-getting-started)
3. [Project Structure](#3-project-structure)
4. [Creating & Editing Maps](#4-creating--editing-maps)
5. [Creating NPCs & Dialogue Trees](#5-creating-npcs--dialogue-trees)
6. [Creating Enemies](#6-creating-enemies)
7. [Creating Items & Equipment](#7-creating-items--equipment)
8. [Creating Shops](#8-creating-shops)
9. [Creating Quests](#9-creating-quests)
10. [Creating Secrets & Hidden Items](#10-creating-secrets--hidden-items)
11. [Creating Cutscenes](#11-creating-cutscenes)
12. [Character Classes & Stats](#12-character-classes--stats)
13. [Combat System Deep Dive](#13-combat-system-deep-dive)
14. [The Trigger System](#14-the-trigger-system)
15. [Save/Load System](#15-saveload-system)
16. [Rendering Engine Reference](#16-rendering-engine-reference)
17. [Tips & Best Practices](#17-tips--best-practices)
18. [Scripted Battles & Boss Fights](#18-scripted-battles--boss-fights)
19. [Tile Overrides](#19-tile-overrides)
20. [Multi-Target Abilities](#20-multi-target-abilities)
21. [Animated & Scripted Cutscenes](#21-animated--scripted-cutscenes)

---

## 1. Project Overview

This is a **turn-based JRPG** written entirely in **PowerShell 5.1**, rendered as ASCII art in a 120×30 console window. All game content is **data-driven** — maps, NPCs, enemies, items, quests, and cutscenes are defined in plain-text and JSON files. You can add or modify content without touching engine code.

### Key Technical Details

| Feature | Detail |
|---|---|
| **Runtime** | PowerShell 5.1 (Windows) |
| **Console Size** | 120 columns × 30 rows |
| **Rendering** | Double-buffered, diff-based (only changed cells redrawn) |
| **Performance** | C# `GameArrayHelper` compiled via `Add-Type` for fast array ops |
| **Data Format** | Plain-text maps (`.txt`) + JSON configs (`.json`) |
| **Input** | Blocking key reads, 300ms animation tick for water/idle |

### Game Modes

The game cycles through these modes:

| Mode | Description |
|---|---|
| `TitleScreen` | Main menu — New Game / Load / Quit |
| `PartyCreation` | Pick 4 classes, name each member |
| `Exploration` | Walk around maps, interact with NPCs |
| `Combat` | Turn-based battle screen |
| `Dialogue` | NPC conversation trees |
| `Menu` | Pause menu (Party, Inventory, Quests, Save) |
| `GameOver` | Party wiped screen |

---

## 2. Getting Started

### Running the Game

```powershell
cd "V2"
.\Start-Game.ps1
```

Ensure your terminal is at least **120×30 characters**. The game will attempt to resize automatically.

### Controls

| Key | Action |
|---|---|
| Arrow Keys / WASD | Move |
| E | Interact (talk to NPCs, search walls) |
| M / Escape | Open menu |
| Enter | Confirm selection |
| Up/Down | Navigate menus |

---

## 3. Project Structure

```
V2/
├── Start-Game.ps1              # Entry point — dot-sources all engines
├── Game-Guide.md               # This file
├── Design-Doc.md               # Original design document
│
├── Engine/                     # PowerShell engine modules
│   ├── Renderer.ps1            # Double-buffered rendering, Draw-Box, Set-Text
│   ├── Input.ps1               # Key reading, text input
│   ├── CharacterEngine.ps1     # Classes, leveling, party creation
│   ├── MapEngine.ps1           # Map loading, tile rendering, player movement
│   ├── CombatEngine.ps1        # Full combat system (abilities, AI, drops)
│   ├── DialogueEngine.ps1      # NPC dialogue tree player
│   ├── ShopEngine.ps1          # Buy/sell UI and item lookup
│   ├── PartyManagement.ps1     # Equipment, ability swaps, party reorder
│   ├── QuestEngine.ps1         # Quest tracking, secrets, quest log UI
│   ├── CutsceneEngine.ps1      # Cutscene playback and trigger system
│   ├── SaveLoad.ps1            # JSON save/load to Saves/ folder
│   └── Core.ps1                # Game state, main loop, HUD, menus
│
├── Data/                       # All game content (edit these!)
│   ├── Classes/
│   │   └── Classes.json        # Class definitions (stats, growth, abilities)
│   ├── Enemies/
│   │   ├── Goblin.json         # Enemy stats definition
│   │   ├── Goblin.txt          # Enemy ASCII sprite
│   │   ├── CaveBat.json
│   │   ├── CaveBat.txt
│   │   ├── Slime.json
│   │   └── Slime.txt
│   ├── Items/
│   │   └── Items.json          # All item definitions
│   ├── Maps/
│   │   ├── Map-TestTown-1.txt          # Town map layout
│   │   ├── MapConfig-TestTown-1.json   # Town tile config, NPCs, connections
│   │   ├── Map-DarkCavern-1.txt        # Cavern map layout
│   │   ├── MapConfig-DarkCavern-1.json # Cavern config with encounters
│   │   ├── Map-Shop-1.txt
│   │   ├── MapConfig-Shop-1.json
│   │   ├── Map-CastleTown-1.txt
│   │   └── MapConfig-CastleTown-1.json
│   ├── NPCs/
│   │   ├── tavern_keeper.json  # Bram's dialogue tree
│   │   ├── healer_elara.json   # Elara's dialogue tree
│   │   ├── shopkeeper_mira.json
│   │   ├── king_aldric.json
│   │   └── cavern_boss.json
│   ├── Quests.json             # Quest definitions
│   ├── Secrets.json            # Hidden item locations
│   └── Shops.json              # Shop inventories
│
├── Cutscenes/                  # Cutscene data
│   ├── Cutscenes.json          # Master index (trigger conditions)
│   ├── intro.json              # Prologue cutscene
│   ├── first_cavern_entry.json
│   ├── goblin_quest_complete.json
│   ├── amulet_quest_complete.json
│   └── amulet_discovery.json
│
├── Saves/                      # Created at runtime
│   └── Save1.json
│
└── Tests/                      # Test scripts (if present)
```

### Module Load Order

Modules are dot-sourced in dependency order in `Start-Game.ps1`:

1. `Renderer.ps1` — Must be first (provides `Set-Text`, `Draw-Box`, etc.)
2. `Input.ps1` — Key reading
3. `CharacterEngine.ps1` — Class definitions, leveling
4. `MapEngine.ps1` — Map loading/rendering
5. `CombatEngine.ps1` — Combat system
6. `DialogueEngine.ps1` — NPC dialogue
7. `ShopEngine.ps1` — Shop UI
8. `PartyManagement.ps1` — Equipment/ability management
9. `QuestEngine.ps1` — Quests and secrets
10. `CutsceneEngine.ps1` — Cutscene playback
11. `SaveLoad.ps1` — Save/load
12. `Core.ps1` — Must be last (depends on everything else)

---

## 4. Creating & Editing Maps

Maps consist of **two files**: a `.txt` layout file and a `.json` config file.

### Map Layout File (.txt)

The map is a grid of single characters. Each character represents a tile. Lines starting with `;` are comments and are ignored. The map must be enclosed in `#` borders.

**Example: `Map-MyArea-1.txt`**
```
; My custom area
####################
#..................#
#..T.....####......#
#........#..#......#
#........####......#
#........~~........#
#..................#
####################
```

**Rules:**
- `#` — Wall tiles (impassable by default)
- `.` — Floor tiles (passable by default)
- `~` — Water tiles (can be animated)
- Any single character can be used as a tile
- Map dimensions are determined by the text — no size limit
- If the map is larger than 80×24 (the viewport), it scrolls to center on the player

### Map Config File (.json)

The config defines tile behavior, colors, NPCs, connections, and encounters.

**Example: `MapConfig-MyArea-1.json`**
```json
{
    "displayName": "My Custom Area",
    "startPosition": { "x": 5, "y": 3 },
    "tiles": {
        "#": {
            "color": "DarkGray",
            "passable": false,
            "name": "Stone Wall"
        },
        ".": {
            "color": "DarkGray",
            "passable": true,
            "name": "Ground"
        },
        "~": {
            "color": "Cyan",
            "bgColor": "DarkBlue",
            "passable": false,
            "name": "Water",
            "animated": true
        },
        "T": {
            "color": "Green",
            "passable": false,
            "name": "Guard Tom",
            "action": {
                "type": "npc",
                "npcId": "guard_tom"
            }
        }
    },
    "connections": {
        "exit_south": {
            "position": { "x": 10, "y": 7 },
            "targetMap": "Map-TestTown-1",
            "targetConfig": "MapConfig-TestTown-1",
            "targetPosition": { "x": 5, "y": 2 }
        }
    },
    "encounters": {
        "enabled": false
    }
}
```

### Tile Properties

| Property | Type | Description |
|---|---|---|
| `color` | string | Foreground color (ConsoleColor name) |
| `bgColor` | string | Background color (optional, default: Black) |
| `passable` | bool | Can the player walk on it? |
| `name` | string | Display name for interaction messages |
| `animated` | bool | If true, cycles through water color animation |
| `action` | object | What happens when player presses E adjacent to it |

### Tile Actions

| Action Type | Properties | Description |
|---|---|---|
| `npc` | `npcId` | Opens dialogue from `Data/NPCs/{npcId}.json` |
| `shop` | `shopId` | Opens a shop (combined with `npcId` for greeting) |
| `sign` | `text` | Shows a message in the message bar |

### Map Connections (Doors)

Connections link positions on one map to positions on another. When the player walks onto a connection position, they are teleported.

```json
"connections": {
    "unique_name": {
        "position": { "x": 22, "y": 20 },
        "targetMap": "Map-DarkCavern-1",
        "targetConfig": "MapConfig-DarkCavern-1",
        "targetPosition": { "x": 21, "y": 1 }
    }
}
```

- `position` — The tile on THIS map that triggers the transition
- `targetMap` — Name of the map file (without .txt)
- `targetConfig` — Name of the config file (without .json)
- `targetPosition` — Where the player appears on the target map

### Random Encounters

Add to any map config to enable battles:

```json
"encounters": {
    "enabled": true,
    "chance": 12,
    "enemies": [
        {
            "name": "Goblin",
            "spriteId": "Goblin",
            "chance": 60,
            "minCount": 1,
            "maxCount": 3,
            "minLevel": 1,
            "maxLevel": 3
        },
        {
            "name": "Cave Bat",
            "spriteId": "CaveBat",
            "chance": 45,
            "minCount": 1,
            "maxCount": 4,
            "minLevel": 1,
            "maxLevel": 2
        }
    ]
}
```

| Property | Description |
|---|---|
| `enabled` | Master switch for encounters on this map |
| `chance` | Percent chance per step (e.g., 12 = 12% per step) |
| `enemies[].name` | Display name in combat |
| `enemies[].spriteId` | Filename in `Data/Enemies/` (minus extension) |
| `enemies[].chance` | Percent chance this enemy type appears |
| `enemies[].minCount/maxCount` | How many of this enemy can spawn |
| `enemies[].minLevel/maxLevel` | Level range for scaling |

### Available Console Colors

Use these names in any `color` or `bgColor` field:

```
Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta,
DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta,
Yellow, White
```

---

## 5. Creating NPCs & Dialogue Trees

### Overview

Each NPC has a dialogue file at `Data/NPCs/{npcId}.json`. The dialogue system is a **node-based tree** — each node has text, optional choices, conditions, effects, and links to other nodes.

### Dialogue File Structure

```json
{
    "npcId": "guard_tom",
    "name": "Guard Tom",
    "entryNode": "start",
    "nodes": [
        {
            "id": "start",
            "speaker": "Tom",
            "text": "Halt! State your business, traveler.",
            "choices": [
                {
                    "label": "I'm just passing through.",
                    "nextNode": "pass"
                },
                {
                    "label": "Any trouble lately?",
                    "nextNode": "rumors"
                },
                {
                    "label": "About that task...",
                    "nextNode": "quest_chat",
                    "condition": { "trigger": "quest_patrol_start" }
                }
            ]
        },
        {
            "id": "pass",
            "speaker": "Tom",
            "text": "Move along then. Stay out of trouble."
        },
        {
            "id": "rumors",
            "speaker": "Tom",
            "text": "Wolves have been spotted near the eastern road. Be careful.",
            "nextNode": "farewell"
        },
        {
            "id": "farewell",
            "speaker": "Tom",
            "text": "Safe travels.",
            "effect": "heal_party"
        }
    ]
}
```

### Node Properties

| Property | Type | Required | Description |
|---|---|---|---|
| `id` | string | Yes | Unique identifier for this node |
| `speaker` | string | No | Name shown above dialogue box (defaults to NPC name) |
| `text` | string | Yes* | The dialogue text (* empty string = routing node) |
| `choices` | array | No | Response options for the player |
| `nextNode` | string | No | Node to advance to after text (if no choices) |
| `condition` | object | No | Only enter this node if condition is met |
| `elseNode` | string | No | If condition fails, go here instead |
| `setTrigger` | string | No | Set a trigger flag when this node is reached |
| `effect` | string | No | Execute a special effect |

### Choices

Each choice object:

```json
{
    "label": "What the player sees",
    "nextNode": "node_to_go_to",
    "setTrigger": "optional_trigger_to_set",
    "condition": { "trigger": "only_show_if_this_is_true" }
}
```

- **Conditional choices** are hidden unless their condition is met
- If all conditional choices are hidden, all choices are shown as fallback

### Conditions

Conditions check the game's trigger state:

```json
// Boolean: true if trigger is set
{ "trigger": "quest_started" }

// Numeric minimum: true if trigger value >= minValue
{ "trigger": "goblin_kills", "minValue": 3 }

// Exact value: true if trigger equals specific value
{ "trigger": "door_state", "value": "open" }
```

### Routing Nodes (Silent Nodes)

A node with empty text (`""`) doesn't show any dialogue — it just checks conditions and routes:

```json
{
    "id": "quest_check_active",
    "text": "",
    "condition": { "trigger": "quest_goblin_start" },
    "nextNode": "quest_check_kills",
    "elseNode": "quest_offer"
}
```

This is useful for multi-step quest logic without showing dialogue.

### Dialogue Effects

The `effect` property triggers special actions:

| Effect | Description |
|---|---|
| `heal_party` | Fully restore all party members' HP and MP |
| `open_shop_buy` | Open the buy screen (uses `shopId` from tile action) |
| `open_shop_sell` | Open the sell screen |
| `start_quest_QUESTID` | Start a quest (e.g., `start_quest_goblin_menace`) |
| `complete_quest_QUESTID` | Complete a quest (e.g., `complete_quest_lost_amulet`) |

### Adding an NPC to a Map

1. Place a unique character in the map `.txt` file (e.g., `G` for Guard)
2. Define the tile in the map config:
```json
"G": {
    "color": "Yellow",
    "passable": false,
    "name": "Guard Tom",
    "action": {
        "type": "npc",
        "npcId": "guard_tom"
    }
}
```
3. Create `Data/NPCs/guard_tom.json` with the dialogue tree
4. NPC tiles should be **impassable** so the player can't walk through them

---

## 6. Creating Enemies

Each enemy needs **two files** in `Data/Enemies/`:

### Stats File (`EnemyName.json`)

```json
{
    "name": "Wolf",
    "spriteFile": "Wolf.txt",
    "size": "small",
    "color": "Gray",
    "baseHP": 18,
    "baseMP": 0,
    "baseStrength": 8,
    "baseIntelligence": 3,
    "baseSpeed": 12,
    "baseDefense": 5,
    "baseAccuracy": 75,
    "baseEXP": 20,
    "baseGold": 8,
    "abilities": ["Bite", "Scratch"],
    "drops": [
        { "item": "Wolf Pelt", "chance": 35 },
        { "item": "Herb", "chance": 20 }
    ],
    "levelScaling": {
        "HP": 5,
        "Strength": 2,
        "Defense": 1,
        "Speed": 1,
        "EXP": 6,
        "Gold": 3
    }
}
```

| Property | Description |
|---|---|
| `name` | Display name in combat |
| `color` | ConsoleColor for the sprite |
| `base*` | Level 1 stats |
| `abilities` | Array of ability names (from the AbilityTable) |
| `drops` | Loot table — each has `item` (item ID or name) and `chance` (%) |
| `levelScaling` | Stats added per level above 1 |

**Level scaling formula:** `stat = base + (level - 1) × scaling`

### Sprite File (`EnemyName.txt`)

ASCII art enclosed in a `#` border:

```
; Wolf - Enemy sprite
#########
#  /\_  #
# / OO\ #
#|  __| #
# \_/\_ #
#   || | #
#########
```

**Rules:**
- Lines starting with `;` are comments
- The `#` border is stripped automatically, only the inner content is displayed
- Top and bottom `#`-only lines are skipped
- Sprites display centered in the enemy area during combat

### Existing Enemy Abilities

These are already defined in the `$Script:AbilityTable` in `CombatEngine.ps1`:

| Ability | Type | Power | Description |
|---|---|---|---|
| `Scratch` | physical | 0.8 | Weak physical attack |
| `Bite` | physical | 1.0 | Standard bite |
| `Screech` | debuff | — | Disorienting screech |
| `Wing Slash` | physical | 0.9 | Sharp wing attack |
| `Acid Spit` | magic | 1.1 | Corrosive acid |
| `Absorb` | magic | 0.7 | Drains HP from target |

### Adding a New Enemy Ability

Add an entry to `$Script:AbilityTable` in `Engine/CombatEngine.ps1`:

```powershell
'Claw'  = @{ Type='physical'; Stat='Strength'; MP=0; Power=1.1; AccMod=0; Target='single'; Desc='A sharp claw attack.' }
```

### Adding an Enemy to a Map

Add the enemy to the map config's `encounters.enemies` array:

```json
{
    "name": "Wolf",
    "spriteId": "Wolf",
    "chance": 40,
    "minCount": 1,
    "maxCount": 2,
    "minLevel": 2,
    "maxLevel": 5
}
```

Remember: `spriteId` must match the filename (e.g., `Wolf.json` and `Wolf.txt`).

---

## 7. Creating Items & Equipment

All items are defined in `Data/Items/Items.json`.

### Item Types

| Type | Description |
|---|---|
| `consumable` | Usable in combat or from inventory |
| `weapon` | Equippable in the Weapon slot |
| `armor` | Equippable in the Armor slot |
| `accessory` | Equippable in the Accessory slot |
| `material` | Sell-only loot drops |

### Consumable Item

```json
{
    "id": "mega_potion",
    "name": "Mega Potion",
    "description": "Restores 100 HP to one ally.",
    "type": "consumable",
    "effect": "heal",
    "value": 100,
    "buyPrice": 80,
    "sellPrice": 40
}
```

| Effect | Description |
|---|---|
| `heal` | Restores `value` HP |
| `restoreMP` | Restores `value` MP |
| `revive` | Revives a KO'd ally with `value`% of max HP |
| `curePoison` | Cures poison status |

### Equipment Item

```json
{
    "id": "flame_sword",
    "name": "Flame Sword",
    "description": "A blade wreathed in fire. STR+7, INT+2",
    "type": "weapon",
    "effect": "none",
    "slot": "Weapon",
    "statBonus": { "Strength": 7, "Intelligence": 2 },
    "buyPrice": 500,
    "sellPrice": 250
}
```

**Stat bonus keys:** `Strength`, `Intelligence`, `Speed`, `Defense`, `Accuracy`

### Material (Sell-Only Drop)

```json
{
    "id": "wolf_pelt",
    "name": "Wolf Pelt",
    "description": "A thick fur pelt. Valuable to merchants.",
    "type": "material",
    "effect": "none",
    "value": 0,
    "buyPrice": 0,
    "sellPrice": 15
}
```

**Important:** Items referenced by enemy `drops` must match by `id` or `name`. If an enemy drops `"Wolf Pelt"`, there must be an item with `name: "Wolf Pelt"` or `id: "wolf_pelt"`.

---

## 8. Creating Shops

Shops are defined in `Data/Shops.json`.

```json
{
    "shops": {
        "blacksmith": {
            "name": "Ironhold Blacksmith",
            "greeting": "Looking for quality steel?",
            "inventory": [
                "iron_sword",
                "steel_sword",
                "chain_mail",
                "leather_armor"
            ]
        }
    }
}
```

| Property | Description |
|---|---|
| `name` | Shop window title |
| `greeting` | Shown when entering (currently unused but reserved) |
| `inventory` | Array of item IDs from `Items.json` |

### Connecting a Shop to an NPC

In the NPC's dialogue, use the `open_shop_buy` or `open_shop_sell` effect:

```json
{
    "id": "shop_menu",
    "speaker": "Mira",
    "text": "Take a look at my wares!",
    "choices": [
        { "label": "Buy", "nextNode": "buy_node" },
        { "label": "Sell", "nextNode": "sell_node" },
        { "label": "Leave", "nextNode": null }
    ]
},
{
    "id": "buy_node",
    "text": "",
    "effect": "open_shop_buy"
},
{
    "id": "sell_node",
    "text": "",
    "effect": "open_shop_sell"
}
```

The shop UI reads the `shopId` from the tile's action config:

```json
"M": {
    "color": "Yellow",
    "passable": false,
    "name": "Shopkeeper Mira",
    "action": {
        "type": "shop",
        "shopId": "general_store",
        "npcId": "shopkeeper_mira"
    }
}
```

---

## 9. Creating Quests

Quests are defined in `Data/Quests.json`.

### Quest Structure

```json
{
    "id": "wolf_hunt",
    "name": "The Wolf Hunt",
    "description": "The village elder needs you to clear the wolves from the eastern road.",
    "giver": "village_elder",
    "triggerStart": "quest_wolf_hunt_start",
    "triggerComplete": "quest_wolf_hunt_done",
    "objectives": [
        {
            "text": "Defeat wolves on the eastern road",
            "type": "counter",
            "trigger": "wolf_kills",
            "target": 5,
            "format": "Defeat wolves ({current}/{target})"
        },
        {
            "text": "Report back to the Village Elder",
            "type": "trigger",
            "trigger": "quest_wolf_hunt_done"
        }
    ],
    "rewards": {
        "gold": 100,
        "exp": 50,
        "items": ["mega_potion"]
    },
    "rewardSummary": "100 Gold, 50 EXP, Mega Potion"
}
```

### Quest Properties

| Property | Description |
|---|---|
| `id` | Unique quest identifier |
| `name` | Display name in quest log |
| `description` | Quest log description text |
| `giver` | NPC ID who gives/completes the quest |
| `triggerStart` | Trigger set when quest begins |
| `triggerComplete` | Trigger set when quest is completed |
| `objectives` | Array of trackable objectives |
| `rewards` | Gold, EXP, and item rewards |
| `rewardSummary` | Human-readable reward text for quest log |

### Objective Types

**Counter** — tracks a numeric trigger value:
```json
{
    "text": "Defeat wolves",
    "type": "counter",
    "trigger": "wolf_kills",
    "target": 5,
    "format": "Defeat wolves ({current}/{target})"
}
```
- Shows progress like `[ ] Defeat wolves (2/5)` or `[X] Defeat wolves (5/5)`
- `{current}` and `{target}` are replaced at runtime

**Trigger** — checks if a boolean trigger is set:
```json
{
    "text": "Find the hidden key",
    "type": "trigger",
    "trigger": "has_hidden_key"
}
```
- Shows `[ ]` or `[X]` based on trigger state

### Quest Flow

1. **Starting a quest:** An NPC dialogue node uses `"effect": "start_quest_wolf_hunt"`
2. **Tracking progress:** The combat system automatically tracks kills (e.g., `wolf_kills`); secrets can set triggers via rewards
3. **Completing a quest:** An NPC dialogue node uses `"effect": "complete_quest_wolf_hunt"`
4. **Turn-in dialogue:** Use conditions to check if objectives are met before allowing completion

### Example Turn-In Dialogue

```json
{
    "id": "quest_check",
    "text": "",
    "condition": { "trigger": "quest_wolf_hunt_start" },
    "nextNode": "quest_check_kills",
    "elseNode": "quest_offer"
},
{
    "id": "quest_check_kills",
    "text": "",
    "condition": { "trigger": "wolf_kills", "minValue": 5 },
    "nextNode": "quest_turn_in",
    "elseNode": "quest_not_done"
},
{
    "id": "quest_turn_in",
    "speaker": "Elder",
    "text": "Excellent work! The road is safe again. Here's your reward.",
    "effect": "complete_quest_wolf_hunt"
},
{
    "id": "quest_not_done",
    "speaker": "Elder",
    "text": "The wolves still roam. Keep hunting!"
}
```

### Kill Tracking

The combat engine automatically creates and increments kill counters in the format:

```
{enemy_name_lowercased_underscored}_kills
```

Examples:
- Goblin → `goblin_kills`
- Cave Bat → `cave_bat_kills`
- Wolf → `wolf_kills`

---

## 10. Creating Secrets & Hidden Items

Secrets are hidden rewards that players find by pressing **E** near specific wall tiles.

### Secrets Configuration

Defined in `Data/Secrets.json`, organized by map name:

```json
{
    "secrets": {
        "Map-MyArea-1": [
            {
                "id": "area_hidden_gold",
                "position": { "x": 5, "y": 3 },
                "description": "You find a hidden compartment behind the wall!",
                "emptyDescription": "The compartment is empty now.",
                "trigger": "secret_area_gold",
                "reward": {
                    "type": "gold",
                    "amount": 50
                }
            }
        ]
    }
}
```

### Secret Properties

| Property | Description |
|---|---|
| `id` | Unique identifier |
| `position` | The wall tile position (x, y) |
| `description` | Message shown on first discovery |
| `emptyDescription` | Message shown if already found |
| `trigger` | Trigger name to track discovery |
| `reward` | What the player gets |

### Reward Types

**Item:**
```json
{ "type": "item", "itemId": "potion", "count": 2 }
```

**Gold:**
```json
{ "type": "gold", "amount": 50 }
```

**Trigger (for quest items):**
```json
{ "type": "trigger", "setTrigger": "has_hidden_key" }
```

**Important:** `position` should be a **wall tile** (`#` or other impassable tile). The player must be standing **adjacent** to it and press E. The system checks all 4 adjacent tiles.

---

## 11. Creating Cutscenes

The cutscene system plays scripted sequences of narration panels, dialogue, ASCII art, and screen effects.

### Cutscene Index (`Cutscenes/Cutscenes.json`)

This master file defines when each cutscene triggers:

```json
{
    "cutscenes": [
        {
            "id": "my_cutscene",
            "name": "A Dramatic Moment",
            "trigger": {
                "type": "quest_complete",
                "questId": "wolf_hunt"
            },
            "onceTrigger": "cutscene_wolf_done"
        }
    ]
}
```

### Trigger Types

| Type | Fires When | Additional Properties |
|---|---|---|
| `game_start` | New game begins | (none) |
| `map_enter` | Player enters a map | `map`: map name (e.g., `"Map-DarkCavern-1"`) |
| `quest_complete` | A quest is completed | `questId`: quest ID |
| `interact` | Player talks to an NPC | `npcId`: NPC ID |

### Additional Trigger Conditions

```json
"trigger": {
    "type": "map_enter",
    "map": "Map-DarkCavern-1",
    "requireTrigger": "has_special_item"
}
```

`requireTrigger` — the cutscene only plays if this trigger is set. Combine with `map_enter` or other types for conditional cutscenes.

### `onceTrigger`

A trigger name that gets set when the cutscene plays. Ensures the cutscene only plays **once** per save file. If omitted, the cutscene can replay.

### Cutscene Data File (`Cutscenes/{id}.json`)

```json
{
    "id": "my_cutscene",
    "name": "A Dramatic Moment",
    "steps": [
        { "type": "effect", "effect": "fade_out" },
        {
            "type": "narration",
            "text": "The wind howled through the valley as the last wolf fell...",
            "textColor": "Cyan",
            "boxed": true,
            "borderColor": "DarkCyan"
        },
        {
            "type": "dialogue",
            "speaker": "Elder",
            "text": "You've done it! The road is safe once more!",
            "speakerColor": "Yellow",
            "textColor": "White"
        },
        {
            "type": "art",
            "art": [
                "  ___________  ",
                " |  VICTORY  | ",
                " |___________| "
            ],
            "artColor": "Yellow",
            "caption": "The village is safe!"
        },
        { "type": "effect", "effect": "fade_in" },
        { "type": "message", "text": "Quest Complete: The Wolf Hunt" }
    ]
}
```

### Step Types

#### `narration` — Full-screen text panel

```json
{
    "type": "narration",
    "text": "Your text here. Can be a long paragraph that will be word-wrapped automatically.",
    "textColor": "DarkGray",
    "boxed": true,
    "borderColor": "DarkCyan"
}
```

| Property | Default | Description |
|---|---|---|
| `text` | — | Narration text (auto word-wrapped at 90 chars) |
| `textColor` | DarkGray | Text color |
| `boxed` | false | Draw a border box around the text |
| `borderColor` | DarkCyan | Border color (if boxed) |

Clears the screen, centers the text vertically, waits for keypress.

#### `dialogue` — Speaker box at bottom

```json
{
    "type": "dialogue",
    "speaker": "Character Name",
    "text": "What they say.",
    "speakerColor": "Yellow",
    "textColor": "White",
    "borderColor": "White"
}
```

Displays in a dialogue box at the bottom of the screen (same style as NPC conversations).

#### `art` — Centered ASCII art display

```json
{
    "type": "art",
    "art": [
        "  /\\  ",
        " /  \\ ",
        "/____\\"
    ],
    "artColor": "Cyan",
    "caption": "A mountain in the distance.",
    "captionColor": "DarkGray"
}
```

Or load from a file:
```json
{
    "type": "art",
    "artFile": "mountain.txt",
    "artColor": "White"
}
```

Art files are loaded from the `Cutscenes/` folder.

#### `effect` — Screen effects

| Effect | Properties | Description |
|---|---|---|
| `fade_out` | `steps` (5), `delayMs` (150) | Clears screen progressively |
| `fade_in` | `delayMs` (500) | Pauses then forces full redraw |
| `flash` | `color` (White), `count` (3), `delayMs` (100) | Screen flashes a color |
| `shake` | `count` (4), `delayMs` (80), `text` | Shakes text on screen |
| `pause` | `delayMs` (1000) | Simple timed pause |

#### `set_trigger` — Set a trigger flag

```json
{ "type": "set_trigger", "trigger": "seen_the_dragon", "value": true }
```

#### `delay` — Timed pause

```json
{ "type": "delay", "ms": 2000 }
```

#### `clear` — Clear the screen

```json
{ "type": "clear" }
```

#### `message` — Add a game message

```json
{ "type": "message", "text": "Something important happened!" }
```

Adds text to the message bar (visible during exploration).

#### `heal_party` — Restore the party

```json
{ "type": "heal_party" }
```

Fully restores all party members' HP and MP.

#### `animated_art` — Frame-by-frame sprite animation

```json
{
    "type": "animated_art",
    "frames": [
        ["frame 0 line 1", "frame 0 line 2"],
        ["frame 1 line 1", "frame 1 line 2"]
    ],
    "frameDelayMs": 200,
    "loops": 3,
    "artColor": "Red",
    "caption": "A face in the flames...",
    "captionColor": "DarkYellow",
    "holdLastFrame": true,
    "waitForKey": true
}
```

| Property | Default | Description |
|---|---|---|
| `frames` | — | Array of frames, each frame an array of strings (like `art`) |
| `frameDelayMs` | 200 | Milliseconds between frames |
| `loops` | 1 | Number of times to cycle through all frames |
| `artColor` | White | Color for the ASCII art |
| `caption` | — | Optional text displayed below the animation |
| `captionColor` | DarkGray | Color for the caption |
| `holdLastFrame` | true | Keep the last frame visible after animation |
| `waitForKey` | true | Wait for a keypress after the last frame |

Each frame is drawn centered on screen. The engine cycles through them at the given speed, creating a flipbook-style animation.

#### `map_sequence` — Scripted map playback

```json
{
    "type": "map_sequence",
    "title": "~ A Memory ~",
    "inlineMap": [
        "##########",
        "#...T..T.#",
        "#........#",
        "##########"
    ],
    "tileColors": { "#": "DarkGreen", ".": "Green", "T": "DarkYellow" },
    "entities": [
        { "id": "mage", "char": "@", "color": "Cyan", "x": 1, "y": 2 },
        { "id": "goblin1", "char": "G", "color": "Red", "x": -1, "y": -1, "hidden": true }
    ],
    "events": [
        { "action": "move", "entity": "mage", "path": [[2,2],[3,2],[4,2]], "stepDelayMs": 200 },
        { "action": "dialogue", "speaker": "Mage", "text": "Did I hear something?", "speakerColor": "Cyan" },
        { "action": "show", "entity": "goblin1", "x": 7, "y": 2, "delayMs": 200 },
        { "action": "delay", "ms": 500 },
        { "action": "hide", "entity": "goblin1" },
        { "action": "narration", "text": "The memory fades..." },
        { "action": "effect", "effect": "fade_out" }
    ]
}
```

| Property | Default | Description |
|---|---|---|
| `mapFile` | — | Load map from `Data/Maps/{file}` (optional) |
| `inlineMap` | — | Define the map inline as an array of strings |
| `title` | — | Optional title at the top of the screen |
| `tileColors` | — | Object mapping tile characters to console colors |
| `mapWidth` | auto | Viewport width override |
| `mapHeight` | auto | Viewport height override |
| `entities` | — | Array of entity definitions (see below) |
| `events` | — | Array of scripted events (see below) |

**Entity Properties:**

| Property | Description |
|---|---|
| `id` | Unique identifier (referenced by events) |
| `char` | Single character drawn on the map |
| `color` | Console color name |
| `x`, `y` | Starting position (use -1 for off-screen) |
| `hidden` | If `true`, entity is invisible until shown |

**Event Actions:**

| Action | Properties | Description |
|---|---|---|
| `move` | `entity`, `path` (array of [x,y]), `stepDelayMs` | Animate entity moving along a path |
| `show` | `entity`, `x`, `y`, `delayMs` | Show a hidden entity (optionally at new position) |
| `hide` | `entity` | Hide an entity |
| `dialogue` | `speaker`, `text`, `speakerColor`, `textColor` | Show dialogue box over the map |
| `narration` | `text`, `textColor`, `boxed`, `borderColor` | Full narration step |
| `delay` | `ms` | Pause for the given milliseconds |
| `effect` | *(same as `effect` step type)* | Play a screen effect |

### Creating a New Cutscene Checklist

1. Create `Cutscenes/{id}.json` with your step sequence
2. Add an entry to `Cutscenes/Cutscenes.json` with trigger conditions
3. Choose a unique `onceTrigger` name to prevent replaying

---

## 12. Character Classes & Stats

Classes are defined in `Data/Classes/Classes.json`.

### Class Definition

```json
{
    "name": "Warrior",
    "symbol": "W",
    "description": "A mighty fighter skilled with weapons and heavy armor.",
    "baseHP": 45,
    "baseMP": 10,
    "baseStrength": 16,
    "baseIntelligence": 8,
    "baseSpeed": 13,
    "baseDefense": 14,
    "baseAccuracy": 85,
    "baseEXPToLevel": 100,
    "defaultMainAttack": "Slash",
    "defaultSecondaryAbilities": ["Power Strike", "Shield Bash"],
    "startingWeapon": "Iron Sword",
    "startingArmor": "Chain Mail",
    "growthRates": {
        "HP":           { "chance": 90, "minGain": 3, "maxGain": 6 },
        "MP":           { "chance": 30, "minGain": 1, "maxGain": 2 },
        "Strength":     { "chance": 85, "minGain": 1, "maxGain": 3 },
        "Intelligence": { "chance": 40, "minGain": 1, "maxGain": 1 },
        "Speed":        { "chance": 60, "minGain": 1, "maxGain": 2 },
        "Defense":      { "chance": 80, "minGain": 1, "maxGain": 3 },
        "Accuracy":     { "chance": 50, "minGain": 1, "maxGain": 2 }
    }
}
```

### Stats Explained

| Stat | Purpose |
|---|---|
| **HP** | Hit Points — reaches 0 = KO |
| **MP** | Magic Points — spent on abilities |
| **Strength** | Physical damage scaling |
| **Intelligence** | Magic damage and healing scaling |
| **Speed** | Turn order priority + Run success chance |
| **Defense** | Reduces incoming damage |
| **Accuracy** | Base hit chance (%) |

### Growth Rates

On level up, each stat has a `chance`% probability of increasing by `minGain` to `maxGain` points. The roll is random per stat.

**Example:** Warrior HP growth: 90% chance to gain 3–6 HP per level.

### Adding a New Class

1. Add a new class object to `Classes.json`
2. Choose a unique single-character `symbol`
3. Assign default abilities (must exist in AbilityTable)
4. Assign starting equipment (must exist in Items.json)
5. Balance growth rates against existing classes

### Current Classes

| Class | Symbol | HP | MP | STR | INT | SPD | DEF | ACC | Role |
|---|---|---|---|---|---|---|---|---|---|
| Warrior | W | 45 | 10 | 16 | 8 | 13 | 14 | 85 | Tank/DPS |
| Mage | M | 28 | 35 | 8 | 18 | 12 | 6 | 90 | Magic DPS |
| Rogue | R | 35 | 15 | 12 | 10 | 18 | 10 | 95 | Fast DPS |
| Cleric | C | 38 | 30 | 11 | 15 | 10 | 12 | 85 | Healer/Support |
| Ranger | A | 36 | 18 | 13 | 11 | 16 | 10 | 95 | Ranged DPS |

### Leveling Formula

- EXP threshold increases 15% per level: `EXPToNext = Floor(EXPToNext × 1.15)`
- On level up: full HP/MP restoration + stat growth rolls

---

## 13. Combat System Deep Dive

### Turn Order

Combatants are sorted by **Speed** (descending). Ties favor party members.

### Action Types (Player)

| Action | Description |
|---|---|
| **Main Attack** | Uses the character's main ability (e.g., Slash, Fire Bolt) |
| **Secondary** | Choose from secondary ability list (may cost MP) |
| **Item** | Use a consumable item on an ally |
| **Defend** | Boost defense by 50% for this round |
| **Run** | Attempt to flee (Speed-based chance) |

### Damage Formula

```
baseDmg = max(1, floor(attackerStat × abilityPower))
defense = defenderDefense (× 1.5 if defending)
rawDmg  = max(1, baseDmg - floor(defense / 2))
finalDmg = rawDmg ± 15% variance (random)
```

- **Physical abilities** use `Strength`
- **Magic abilities** use `Intelligence`

### Hit Chance

```
hitChance = clamp(attackerAccuracy + abilityAccMod, 10, 99)
hit = (random 0–99) < hitChance
```

### Healing Formula

```
base = max(5, floor(casterStat × abilityPower))
heal = base ± 10% variance
```

### Run Chance

```
chance = 40 + (memberSpeed - avgEnemySpeed) × 2
chance = clamp(chance, 10, 90)
```

Only one party member needs to succeed for the whole party to flee.

### Enemy AI

Enemies choose randomly from their ability list and target a random living party member.

### All Abilities Reference

| Ability | Class | Type | Power | MP | Target | AccMod |
|---|---|---|---|---|---|---|
| Slash | Warrior | physical | 1.0 | 0 | single | 0 |
| Power Strike | Warrior | physical | 1.6 | 5 | single | -10 |
| Shield Bash | Warrior | physical | 0.8 | 3 | single | +5 |
| **Wide Slash** | Warrior | physical | 0.9 | 4 | **cleave** | 0 |
| Fire Bolt | Mage | magic | 1.3 | 4 | single | 0 |
| Ice Shard | Mage | magic | 1.1 | 5 | all | 0 |
| Lightning | Mage | magic | 1.7 | 7 | single | -5 |
| **Chain Bolt** | Mage | magic | 1.2 | 6 | **random:3** | -5 |
| **Tidal Wave** | Mage | magic | 1.0 | 10 | all | 0 |
| Backstab | Rogue | physical | 1.2 | 0 | single | +5 |
| Poison Strike | Rogue | physical | 1.0 | 4 | single | 0 |
| Steal | Rogue | special | — | 2 | single | +10 |
| Smoke Bomb | Rogue | debuff | — | 3 | all | +100 |
| **Fan of Knives** | Rogue | physical | 0.8 | 5 | **random:3** | -10 |
| Smite | Cleric | magic | 1.2 | 3 | single | 0 |
| Heal | Cleric | heal | 1.5 | 5 | ally | auto |
| Bless | Cleric | buff | — | 4 | allAllies | auto |
| Holy Light | Cleric | magic | 1.4 | 8 | all | 0 |
| **Divine Storm** | Cleric | magic | 1.1 | 6 | **random:4** | 0 |
| Arrow Shot | Ranger | physical | 1.0 | 0 | single | +5 |
| **Multi-Shot** | Ranger | physical | 0.7 | 5 | **random:3** | -5 |
| Snare Trap | Ranger | debuff | — | 3 | single | auto |
| Nature's Cure | Ranger | heal | 1.2 | 4 | ally | auto |
| **Volley** | Ranger | physical | 0.6 | 7 | all | -5 |

### Adding a New Ability

Add to `$Script:AbilityTable` in `Engine/CombatEngine.ps1`:

```powershell
'Fireball' = @{
    Type='magic'
    Stat='Intelligence'
    MP=10
    Power=1.8
    AccMod=-10
    Target='all'
    Desc='A massive fireball engulfs all enemies.'
}
```

Then add it to a class's `defaultSecondaryAbilities` in `Classes.json`, or to an enemy's `abilities` array.

### Target Types

| Target | Description |
|---|---|
| `single` | One enemy (player chooses) |
| `all` | All living enemies |
| `ally` | One party member (player chooses) |
| `allAllies` | All living party members |
| `cleave` | Primary target + 1 adjacent enemy (player picks primary) |
| `random:N` | Up to **N** random living enemies (auto-selected) |

### Drops & Rewards

After victory:
1. Each enemy's `drops` are rolled individually
2. Total EXP and Gold are summed from all enemies
3. Living party members receive EXP (dead members get nothing)
4. Kill counters are incremented for quest tracking

---

## 14. The Trigger System

Triggers are the backbone of game state tracking. They're stored in `$Script:GameState.Triggers` — a hashtable of key-value pairs that persist across saves.

### What Uses Triggers

| System | How Triggers Are Used |
|---|---|
| **Quests** | `triggerStart` / `triggerComplete` mark quest state |
| **Dialogue** | Conditions check trigger values for branching |
| **Secrets** | Each secret sets a trigger to prevent re-discovery |
| **Combat** | Kill counters (`goblin_kills`, `cave_bat_kills`, etc.) |
| **Cutscenes** | `onceTrigger` prevents replay; `requireTrigger` for conditions |
| **Save/Load** | All triggers are serialized to the save file |

### Trigger Naming Conventions

| Pattern | Example | Purpose |
|---|---|---|
| `quest_{id}_start` | `quest_goblin_menace_start` | Quest has been accepted |
| `quest_{id}_done` | `quest_goblin_menace_done` | Quest is completed |
| `{enemy}_kills` | `goblin_kills` | Kill counter (integer) |
| `secret_{id}` | `secret_town_hidden_herb` | Secret has been found |
| `has_item_{name}` | `has_item_silver_amulet_quest` | Player found a quest item |
| `cutscene_{name}` | `cutscene_intro_seen` | Cutscene has played |

### Setting Triggers

- **Dialogue nodes:** `"setTrigger": "my_flag"`
- **Dialogue choices:** `"setTrigger": "chose_option_a"`
- **Quest start:** `Start-Quest` sets `triggerStart`
- **Quest complete:** `Complete-Quest` sets `triggerComplete`
- **Secrets:** Set via `reward.setTrigger`
- **Cutscenes:** `set_trigger` step type
- **Combat:** Auto-incremented kill counters

### Checking Triggers

- **Dialogue conditions:** `{ "trigger": "flag_name" }` or `{ "trigger": "counter", "minValue": 3 }`
- **Cutscene triggers:** `"requireTrigger": "flag_name"` in cutscene index
- **Engine code:** `$Script:GameState.Triggers["key"]`

---

## 15. Save/Load System

### Overview

The game supports **unlimited named save files**. Each save is a JSON file in the `Saves/` directory. Players can:

- **Save** from the in-game menu → opens a slot picker with "New Save" + all existing saves
- **Load** from the title screen → shows all existing saves sorted newest-first
- **Overwrite** an existing save (with confirmation prompt)
- **Name** their saves (e.g., "Mage Run", "Warrior Party 2") for easy identification

### Save File Format

Saves are stored as `Saves/{SaveName}.json`:

```json
{
    "Version": 2,
    "SaveName": "My Adventure",
    "SaveDate": "2025-01-15 14:30:00",
    "CurrentMapName": "Map-TestTown-1",
    "PlayerPosition": { "X": 20, "Y": 14 },
    "Party": [ ... ],
    "Inventory": [ ... ],
    "Gold": 150,
    "Triggers": { "quest_goblin_menace_start": true, "goblin_kills": 2 },
    "StepCounter": 342,
    "Messages": [ ... ]
}
```

### Save/Load UI

**Saving (in-game menu → Save Game):**
1. A slot picker appears showing `[ + New Save ]` at the top, then all existing saves with details (name, level, party leader, date).
2. Selecting "New Save" prompts for a name (alphanumeric, spaces, hyphens, underscores; max 30 chars).
3. Selecting an existing save asks for overwrite confirmation before saving.

**Loading (title screen → Load Game):**
1. A slot picker shows all existing saves sorted newest-first.
2. Each entry displays: save name, party leader + level, and save date.
3. Selecting a save loads it immediately.

### What Gets Saved

- Current map name and player position
- Full party data (stats, equipment, abilities, level)
- Complete inventory
- Gold
- All triggers (quest state, kill counters, secrets found, cutscenes seen)
- Step counter
- Last 10 game messages

### What Doesn't Get Saved

- Combat state (combat is transient)
- Current dialogue tree position
- Visual state (animation frame, etc.)

### Backward Compatibility

Old `Save1.json` files (Version 1) load fine — the engine derives a display name from the filename. The `Save-GameState` function still accepts a `-Slot` parameter for scripting, but the UI always uses named saves.

### Programmatic Save/Load

```powershell
# Save with a specific name
Save-GameState -SaveName "My Adventure"

# Load by filename
Load-GameState -FileName "My Adventure.json"

# Legacy slot-based (backward compat)
Save-GameState -Slot 1
Load-GameState -Slot 1

# List all saves
$slots = Get-SaveSlots   # Returns array of hashtables sorted newest-first
```

---

## 16. Rendering Engine Reference

### Key Functions

| Function | Description |
|---|---|
| `Set-Cell -X -Y -Char -FgColor -BgColor` | Set a single cell in the frame buffer |
| `Set-Text -X -Y -Text -FgColor -BgColor` | Write a string to the frame buffer |
| `Clear-FrameBuffer` | Fill the buffer with spaces |
| `Invoke-RenderFrame` | Diff and draw changes to the console |
| `Invoke-ForceFullRedraw` | Force redraw of every cell next frame |
| `Draw-Box -X -Y -Width -Height -Color -BgColor -Fill` | Draw a bordered box |
| `Draw-TextBox -X -Y -Width -Height -Title -Lines -BorderColor -TextColor` | Draw a box with text content |
| `Draw-SelectionMenu -X -Y -Width -Title -Options -BorderColor -TextColor` | Interactive menu with arrow key navigation. Returns selected index. |
| `Draw-ProgressBar -X -Y -Width -Percent -FilledColor` | Draw a horizontal bar |

### Screen Layout

```
Row 0:    [Location Name]                    [Steps: 123]
Rows 1-24: [== Map Viewport (80 cols) ==]  [== Party Panel (37 cols) ==]
Rows 26-28: [============ Message Bar (120 cols) =============]
Row 29:   [Controls hint]
```

- Map viewport: columns 0–79, rows 1–24
- Party panel: columns 82–118, rows 1–24
- Message bar: full width, rows 26–28
- The map auto-scrolls to center on the player when larger than the viewport

### Performance Notes

- The renderer uses **diff-based rendering** — only cells that changed are redrawn
- Uses compiled C# `GameArrayHelper` for array fill operations (PS5.1 has no `[Array]::Fill`)
- Map rendering uses direct buffer array access instead of `Set-Cell` calls for speed
- Tile colors are cached per map config to avoid repeated property lookups

---

## 17. Tips & Best Practices

### General

- **Test incrementally** — after adding content, run the game to verify
- **Use unique IDs** — quest IDs, trigger names, NPC IDs, and secret IDs must all be unique
- **Keep map characters unique per map** — each tile character in a map should have only one meaning

### Maps

- Always enclose maps in `#` borders
- Keep maps under ~80×24 for a single-screen experience, or go larger for scrolling areas
- Use different tile characters for different terrain visually
- Water tiles (`~`) with `"animated": true` look great for rivers and ponds

### Dialogue

- Start every dialogue tree with an `"id": "start"` node (or set `entryNode`)
- Use routing nodes (empty text) to chain condition checks without showing text
- Test all dialogue paths, especially conditional branches
- Remember: `effect` happens when the node is *processed*, even in routing nodes

### Combat Balance

- Physical classes (Warrior, Rogue, Ranger) scale off Strength
- Magic classes (Mage, Cleric) scale off Intelligence
- Higher Power abilities should cost more MP or have accuracy penalties
- Consider the party composition — ensure at least one healing option exists
- Enemy abilities with `MP: 0` always succeed the MP check

### Quests

- Always use the naming pattern `quest_{id}_start` / `quest_{id}_done` for triggers
- Kill counter triggers are auto-created as `{enemy_name_lower}_kills`
- The `rewardSummary` is display-only — actual rewards come from the `rewards` object
- Test the full quest flow: accept → progress → turn-in → completion

### Cutscenes

- Start with `fade_out` and end with `fade_in` for smooth transitions
- Don't make cutscenes too long — 4-6 narration panels is a good maximum
- Use `message` step to leave a reminder in the message bar
- Always set a unique `onceTrigger` to prevent replaying on every map enter

### Common Pitfalls

| Problem | Solution |
|---|---|
| NPC doesn't talk | Check `npcId` in map config matches the JSON filename |
| Quest won't complete | Verify the turn-in dialogue uses `complete_quest_{id}` effect, and conditions check the right triggers |
| Item drops can't be sold | Ensure the item exists in `Items.json` with a `sellPrice` > 0 |
| Cutscene replays | Make sure `onceTrigger` is set in `Cutscenes.json` |
| Map transition doesn't work | Verify `connections` position matches the exact tile coordinate, and target map/config files exist |
| Kill counter not tracking | Enemy `name` in encounters must match what the kill tracker creates (e.g., "Cave Bat" → `cave_bat_kills`) |

---

## 18. Scripted Battles & Boss Fights

Scripted battles let you create predetermined encounters (bosses, story fights, ambushes)
that trigger from NPC dialogue or cutscenes — **not** from random encounter rolls.

### How It Works

1. A battle is defined in `Data/ScriptedBattles.json` with a unique ID.
2. An NPC dialogue node uses `"effect": "start_battle_{battleId}"` to start it.
3. Alternatively, a cutscene step `{ "type": "start_battle", "battleId": "..." }` starts it.
4. On victory the engine can set a trigger, grant bonus rewards, and display a message.
5. Tile overrides (see §19) can remove the boss tile from the map once the trigger is set.

### Defining a Scripted Battle — `Data/ScriptedBattles.json`

```json
{
    "battles": {
        "cave_shadow": {
            "name": "The Shadowed Figure",
            "enemies": [
                {
                    "name": "Shadowed Figure",
                    "spriteId": "Goblin",
                    "level": 5,
                    "count": 1
                },
                {
                    "name": "Shadow Goblin",
                    "spriteId": "Goblin",
                    "level": 3,
                    "count": 2
                }
            ],
            "canRun": false,
            "victoryTrigger": "boss_cave_shadow_defeated",
            "bonusRewards": {
                "gold": 100,
                "exp": 80,
                "items": ["steel_sword"]
            },
            "victoryMessage": "The shadowed figure dissolves into darkness..."
        }
    }
}
```

| Field | Required | Description |
|---|---|---|
| `name` | Yes | Display name shown in the combat log & encounter banner |
| `enemies[]` | Yes | Array of enemy entries |
| `enemies[].name` | No | Override the enemy's display name |
| `enemies[].spriteId` | Yes | References `Data/Enemies/{spriteId}.json` for stats & `{spriteId}.txt` for art |
| `enemies[].level` | No | Fixed level (default 1) |
| `enemies[].count` | No | How many of this enemy (default 1) |
| `canRun` | No | `false` = party cannot flee (default `true`) |
| `victoryTrigger` | No | Trigger name set to `true` on victory |
| `bonusRewards.gold` | No | Extra gold on top of normal enemy drops |
| `bonusRewards.exp` | No | Extra EXP distributed to living party members |
| `bonusRewards.items` | No | Array of item IDs added to inventory on victory |
| `victoryMessage` | No | Message displayed after the victory summary |

### Triggering from NPC Dialogue

In an NPC dialogue node, add `"effect": "start_battle_{battleId}"`:

```json
{
    "id": "fight_talk",
    "speaker": "Boss Name",
    "text": "Enough talk. Prepare yourselves!",
    "effect": "start_battle_cave_shadow",
    "nextNode": null
}
```

The dialogue ends and combat begins immediately.

To **prevent repeating** the fight, add a condition on the dialogue entry node that
checks the `victoryTrigger`:

```json
{
    "id": "start",
    "condition": { "trigger": "boss_cave_shadow_defeated", "negate": true },
    "elseNode": "start_defeated",
    "text": "Pre-fight dialogue...",
    ...
},
{
    "id": "start_defeated",
    "condition": { "trigger": "boss_cave_shadow_defeated" },
    "text": "The boss is gone. Only silence remains.",
    "nextNode": null
}
```

### Triggering from a Cutscene

Add a `start_battle` step to a cutscene JSON file:

```json
{
    "type": "start_battle",
    "battleId": "cave_shadow"
}
```

> **Note:** The cutscene ends when a battle starts. The update loop switches to
> combat mode and the battle plays out normally.

### Step-by-Step: Create a New Boss Fight

1. Create an enemy data file in `Data/Enemies/` (stats + sprite) if one doesn't exist.
2. Add a battle entry to `Data/ScriptedBattles.json`.
3. Create or update an NPC dialogue to use `"effect": "start_battle_{id}"`.
4. Add a condition to prevent re-triggering after victory.
5. Add a tile override (§19) to remove the boss tile when defeated.
6. *(Optional)* Create a cutscene that plays after the battle.

---

## 19. Tile Overrides

Tile overrides let you change map tiles at runtime based on triggers —
for example, removing a boss tile after defeat or opening a passage after a quest.

### How It Works

1. Overrides are defined in the map config's `tileOverrides` array.
2. `Apply-TileOverrides` runs each time a map loads, on door transitions,
   after loading a save, and after scripted-battle victories.
3. When the condition is met, the tile character in the loaded map array
   is replaced — changing both its appearance and behaviour (passability, actions).

### Map Config Format

Add a `tileOverrides` array to any map config JSON:

```json
"tileOverrides": [
    {
        "position": { "x": 5, "y": 11 },
        "condition": {
            "trigger": "boss_cave_shadow_defeated",
            "value": true
        },
        "replaceTile": "."
    }
]
```

| Field | Required | Description |
|---|---|---|
| `position.x`, `position.y` | Yes | Tile coordinates (0-based, matching the map .txt file) |
| `condition.trigger` | Yes | The trigger name to check |
| `condition.value` | No | Expected value (default `true`). Can be any type. |
| `replaceTile` | Yes | The single character to replace the tile with |

### When Overrides Are Applied

| Event | Location |
|---|---|
| Game start | `Core.ps1` → `Invoke-LoadStartingMap` |
| Door transition | `MapEngine.ps1` → `Move-Player` |
| Save loaded | `SaveLoad.ps1` → `Load-GameState` |
| Scripted battle won | `CombatEngine.ps1` → `Resolve-Victory` |

### Common Patterns

**Remove a boss NPC after defeat:**
```json
{ "position": {"x":5,"y":11}, "condition": {"trigger": "boss_defeated"}, "replaceTile": "." }
```

**Open a locked door after quest completion:**
```json
{ "position": {"x":10,"y":5}, "condition": {"trigger": "quest_key_complete"}, "replaceTile": "D" }
```

**Reveal a hidden passage:**
```json
{ "position": {"x":3,"y":8}, "condition": {"trigger": "secret_lever_pulled"}, "replaceTile": "." }
```

### Tips

- The replacement character must be defined in the map config's `tiles` section.
- If the boss tile was impassable (`"passable": false`), replacing it with `.`
  (cave floor, passable) means the player can now walk over that spot.
- You can stack multiple overrides at different positions — they're all checked.
- Overrides are **not** saved into the save file; they're re-derived from triggers
  each time the map loads, which keeps saves clean and overrides always consistent.

---

## Quick Reference: Adding New Content

### New Map
1. Create `Data/Maps/Map-{Name}.txt` — the tile layout
2. Create `Data/Maps/MapConfig-{Name}.json` — tile defs, NPCs, connections, encounters
3. Add a connection from an existing map to reach it

### New NPC
1. Place a tile character on a map
2. Define the tile in the map config with `"action": { "type": "npc", "npcId": "..." }`
3. Create `Data/NPCs/{npcId}.json` with the dialogue tree

### New Enemy
1. Create `Data/Enemies/{Name}.json` — stats, abilities, drops, scaling
2. Create `Data/Enemies/{Name}.txt` — ASCII sprite in `#` border
3. Add to a map config's `encounters.enemies` array
4. Add any new abilities to `$Script:AbilityTable` in `CombatEngine.ps1`
5. If they drop items, ensure those items exist in `Items.json`

### New Item
1. Add to `Data/Items/Items.json`
2. If sold in shops, add the ID to the shop's `inventory` array in `Shops.json`

### New Quest
1. Add to `Data/Quests.json`
2. Create NPC dialogue to start/complete it (with `effect` properties)
3. If counter-based, verify kill tracking matches the trigger name
4. Optionally add a cutscene for completion

### New Cutscene
1. Create `Cutscenes/{id}.json` with step sequence
2. Add entry to `Cutscenes/Cutscenes.json` with trigger conditions
3. Set a unique `onceTrigger` name

### New Boss / Scripted Battle
1. Create the enemy sprite & stats if new (`Data/Enemies/`)
2. Add a battle entry to `Data/ScriptedBattles.json`
3. Create or update an NPC dialogue with `"effect": "start_battle_{id}"`
4. Add a condition + `elseNode` on the NPC start node to avoid repeat fights
5. Add a tile override in the map config to remove/replace the boss tile on defeat
6. Test: talk to the NPC → battle starts → victory sets trigger → tile changes

### New Shop
1. Add to `Data/Shops.json` with an inventory array
2. Create an NPC with dialogue that uses `open_shop_buy` / `open_shop_sell` effects
3. Set the tile action to `"type": "shop"` with the `shopId`

### New Class
1. Add to `Data/Classes/Classes.json`
2. Choose a unique symbol
3. Ensure starting equipment exists in `Items.json`
4. Ensure default abilities exist in `$Script:AbilityTable`

---

## 20. Multi-Target Abilities

The combat system supports several targeting modes beyond `single` and `all`. These allow abilities to hit a subset of enemies or adjacent foes.

### Target Types (Complete)

| Target | Player Targeting | Description |
|---|---|---|
| `single` | Player picks one enemy | Standard single-target |
| `all` | Auto (all enemies) | Hits every living enemy |
| `ally` | Player picks one ally | Healing/buff on one party member |
| `allAllies` | Auto (all allies) | Affects all living party members |
| `cleave` | Player picks one enemy | Hits chosen target **+ 1 adjacent** living enemy |
| `random:N` | Auto (random selection) | Hits up to **N** random living enemies |

### How Cleave Works

1. Player selects a primary target (same UI as `single`).
2. `Resolve-MultiTargets` finds that target's index among alive enemies.
3. The adjacent neighbor (right first, then left) is added as a second target.
4. Each target is hit separately (separate damage rolls, hit checks).
5. If only one enemy remains, cleave still hits — just the single target.

### How Random:N Works

1. No target selection needed — targets are auto-picked.
2. `Resolve-MultiTargets` shuffles alive enemies and takes the first **N**.
3. If fewer than N enemies are alive, it hits all of them.
4. Each target gets its own damage roll and hit check.
5. At execution time, random targets are **re-rolled** to account for enemies that may have died during the round.

### Defining a Multi-Target Ability

```powershell
'Chain Bolt' = @{
    Type     = 'magic'
    Stat     = 'Intelligence'
    MP       = 6
    Power    = 1.2
    AccMod   = -5
    Target   = 'random:3'      # <-- up to 3 random enemies
    Desc     = 'Lightning arcs between up to 3 foes.'
}

'Wide Slash' = @{
    Type     = 'physical'
    Stat     = 'Strength'
    MP       = 4
    Power    = 0.9
    AccMod   = 0
    Target   = 'cleave'        # <-- target + 1 adjacent
    Desc     = 'A wide arc hitting the target and its neighbor.'
}
```

### Enemy AI Multi-Target

Enemies also support all target types. When an enemy uses:
- `all` → hits every living party member
- `cleave` → picks a random party member as primary, then picks adjacent
- `random:N` → resolves N random party members
- `single` (default) → one random party member

### Design Tips

- **Balance multi-target abilities** with lower `Power` values — hitting 3 targets at full power is overpowered.
- **Cleave** is great for melee classes (Warrior, Rogue); use for "wide slash" or "sweep" attacks.
- **Random:N** works well for ranged/magic (arrows scatter, lightning arcs, knife throws).
- **Boss abilities** using `cleave` and `all` make fights more dangerous and tactical.

---

## 21. Animated & Scripted Cutscenes

Two advanced cutscene step types bring scenes to life with movement and animation.

### Animated Art (`animated_art`)

Plays frame-by-frame ASCII art animation — like a sprite sheet. Use it for:
- A campfire with flickering flames
- A villain's face morphing
- An explosion effect
- A magical portal opening

**Example: Campfire Vision** (`Cutscenes/campfire_vision.json`)

This cutscene shows an animated face forming in flames, then a sinister visage:

```json
{
    "type": "animated_art",
    "frames": [
        ["  (  ) ", " ( .. ) ", "  (\/  )", " ___/\\___ "],
        ["  ( )  ", " ( .. ) ", "  (/\\  )", " ___/\\___ "],
        ["  (  ) ", " ( /\\ ) ", "  (  \/) ", " ___/\\___ "]
    ],
    "frameDelayMs": 250,
    "loops": 3,
    "artColor": "Red",
    "caption": "A face forms in the flames..."
}
```

The engine:
1. Clears the screen.
2. Centers the current frame.
3. Draws it in `artColor`.
4. Sleeps for `frameDelayMs`.
5. Advances to the next frame.
6. Repeats for `loops` cycles.
7. On the last frame, shows "[Press any key]" and waits.

### Map Sequence (`map_sequence`)

Displays a map with scripted entities that move, appear, and speak — with **no player control**. Use it for:
- Flashback/memory scenes
- Showing events at another location
- Tutorial demonstrations
- Dramatic NPC encounters

**Example: Goblin Ambush Memory** (`Cutscenes/goblin_ambush_memory.json`)

This cutscene shows the player character walking through a forest, stopping when goblins appear:

```json
{
    "type": "map_sequence",
    "title": "~ A Memory ~",
    "inlineMap": [
        "##################################################",
        "#...T......T...........T.....T..........T.........#",
        "#..........T....T.............T.......T...........#",
        "##################################################"
    ],
    "tileColors": { "#": "DarkGreen", ".": "Green", "T": "DarkYellow" },
    "entities": [
        { "id": "mage", "char": "@", "color": "Cyan", "x": 1, "y": 1 },
        { "id": "goblin1", "char": "G", "color": "Red", "hidden": true }
    ],
    "events": [
        { "action": "move", "entity": "mage", "path": [[2,1],[3,1],[4,1]], "stepDelayMs": 150 },
        { "action": "dialogue", "speaker": "You", "text": "Too quiet..." },
        { "action": "show", "entity": "goblin1", "x": 8, "y": 1, "delayMs": 200 },
        { "action": "dialogue", "speaker": "Goblin", "text": "Get 'em!", "speakerColor": "Red" }
    ]
}
```

The engine:
1. Loads the map (from `inlineMap` or `mapFile`).
2. Draws tiles with colors from `tileColors`.
3. Draws visible entities at their positions.
4. Processes events sequentially:
   - **move** — animates the entity step-by-step along the path
   - **show** — reveals a hidden entity, optionally at a new position
   - **hide** — makes an entity invisible
   - **dialogue** — shows a dialogue box over the map, waits for keypress
   - **narration** — shows a full narration panel
   - **delay** — pauses for a set time
   - **effect** — plays a screen effect (fade, flash, etc.)

### Combining Both in One Cutscene

You can mix `animated_art`, `map_sequence`, and all other step types freely:

```json
{
    "steps": [
        { "type": "narration", "text": "You recall the day it happened..." },
        { "type": "effect", "effect": "fade_out" },
        { "type": "map_sequence", "inlineMap": [...], "entities": [...], "events": [...] },
        { "type": "animated_art", "frames": [...], "loops": 2 },
        { "type": "narration", "text": "The memory fades." }
    ]
}
```

### Tips for Good Animations

- Keep frames the **same dimensions** for smooth playback.
- Use 150–300ms `frameDelayMs` for natural-feeling animation.
- 2–4 frames of subtle variation looks better than many rapid changes.
- Use `loops: 2-3` — too many loops gets tedious.
- Add a `caption` to explain what the player is seeing.

### Tips for Map Sequences

- Keep maps small (30–50 wide, 10–15 tall) — they're meant to be vignettes.
- Use simple tile sets — the focus is on the entities and dialogue.
- Paths should be smooth (no teleporting) — step-by-step [x,y] arrays.
- Mix `move` + `dialogue` for impactful pacing.
- The `show` action with `delayMs` creates dramatic enemy reveals.

---

*Happy modding! The world of Thornvale awaits your creativity.*
