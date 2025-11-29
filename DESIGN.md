# Riftwardens - Game Design Document

## Overview
**Riftwardens** is a turn-based roguelike deckbuilder with horde pressure mechanics. Players defend against waves of enemies approaching in concentric rings, using cards to deal damage, apply debuffs, and survive.

### Core Loop
1. **Select Warden** - Choose from 3 characters with unique passives
2. **Combat** - Survive waves of enemies using cards
3. **Reward** - Pick new cards, scrap, or healing
4. **Shop** - Buy cards, artifacts, services
5. **Repeat** - Progress through 12 waves to victory

---

## Game Mechanics

### Ring Battlefield
Enemies spawn in the **FAR** ring and advance toward the player each turn:
```
[MELEE] ← [CLOSE] ← [MID] ← [FAR]
   0         1        2       3
```
- Enemies in **MELEE** deal damage to the player
- Cards can target specific rings
- Some enemies stop at certain rings (ranged attackers)

#### Visual Layout + Scaling
- `scenes/Combat.tscn` anchors `BattlefieldArena` across the full viewport with only 70 px margins on the top and bottom (`offset_top = 70`, `offset_bottom = -70`). That keeps the arena’s center perfectly aligned with the screen center while letting the card bar overlap the lower edge.
- `BattlefieldArena.gd` sets `max_radius = min(size.x, size.y) * 0.58`, so the FAR ring almost touches both the top HUD and the card row on tall and wide devices.
- Enemy panels scale with the viewport: width = `clamp(shortest_side * 0.11, 70, 150)` and height = `clamp(width * 1.25, 90, 190)`. All internal labels/bars position themselves using those dynamic dimensions so the HP bar always spans `panel_width - 8` pixels and damage text centers regardless of scale.

### Turn Structure
1. **Draw Phase** - Draw cards to hand (5 by default)
2. **Player Phase** - Play cards using Energy (3 by default)
3. **Enemy Phase** - Enemies move inward and attack
4. **Wave Check** - Win if all enemies dead, lose if player dead or turn limit reached

### Card Types
| Type | Description |
|------|-------------|
| Weapon | Deal damage, some persist across turns |
| Skill | Buffs, healing, utility |
| Hex | Apply stacking damage-over-time to enemies |
| Defense | Gain armor, create barriers |

### Game Mechanics Explained

**Energy**: Resource spent to play cards. Refills to max (usually 3) each turn.

**Armor**: Absorbs damage before HP. Persists between turns until used.

**Hex**: Stacking debuff on enemies. When a hexed enemy takes damage, they take bonus damage equal to their hex stacks, then hex is consumed.

**Persistent Weapons**: Stay in play and trigger automatically each turn (e.g., "deal 4 damage to random enemy at turn start").

**Ring Targeting**: Cards specify which rings they can hit. Some require player to choose a ring, others auto-target.

---

## Detailed Card Definitions

### Currently Implemented (26 cards)

**Weapons (8 cards)**
| Card | Cost | Effect |
|------|------|--------|
| Infernal Pistol | 1 | Persistent: Deal 4 damage to random enemy in Mid/Close each turn |
| Choirbreaker Shotgun | 1 | Deal 6 damage to ALL enemies in Close ring |
| Riftshard Rifle | 2 | Deal 8 damage to single enemy in Far ring |
| Ember Grenade | 2 | Deal 4 damage to ALL enemies in target ring (requires targeting) |
| Void Revolver | 1 | Deal 3 damage to random enemy, draw 1 card |
| Scatter Shot | 1 | Deal 2 damage to 3 random enemies |
| Blood Bolt | 1 | Deal 5 damage to random enemy, heal 2 HP |
| Flamethrower | 2 | Deal 3 damage to ALL enemies in Melee and Close |

**Skills (6 cards)**
| Card | Cost | Effect |
|------|------|--------|
| Emergency Medkit | 1 | Heal 5 HP |
| Adrenaline | 1 | Gain 1 Energy this turn, draw 1 card |
| Second Wind | 2 | Heal 8 HP |
| Ritual Focus | 0 | Your next Hex card this turn deals double Hex |
| Gambit | 1 | Discard your hand, draw 5 cards |
| Quick Strike | 0 | Deal 2 damage to random enemy |

**Hexes (6 cards)**
| Card | Cost | Effect |
|------|------|--------|
| Simple Hex | 1 | Apply 3 Hex to all enemies in target ring |
| Mark of Gloom | 1 | Apply 4 Hex to single enemy |
| Plague Cloud | 2 | Apply 2 Hex to ALL enemies |
| Wither | 1 | Apply 3 Hex to all enemies in Close/Melee |
| Cheap Curse | 0 | Apply 2 Hex to random enemy |
| Soul Rend | 2 | Deal 3 damage + apply 5 Hex to single enemy in Melee |

**Defense (6 cards)**
| Card | Cost | Effect |
|------|------|--------|
| Glass Ward | 1 | Gain 3 Armor |
| Iron Bastion | 2 | Gain 6 Armor |
| Barrier Sigil | 1 | Create barrier on target ring: enemies crossing take 4 damage (2 turns) |
| Draining Shield | 1 | Gain 3 Armor, heal 1 HP for each enemy in Melee |
| Repulsion | 1 | Push all enemies in Melee back 1 ring |
| Shield Bash | 1 | Deal damage equal to your Armor to enemy in Melee |

---

## Detailed Enemy Definitions

### Currently Implemented (10 enemies)

**Grunt Enemies (5)**
| Enemy | HP | Damage | Speed | Behavior |
|-------|-----|--------|-------|----------|
| Husk | 8 | 4 | 1 ring/turn | Basic melee, walks toward player |
| Spitter | 6 | 3 | 1 ring/turn | Ranged, stops at Mid ring, attacks from there |
| Spinecrawler | 6 | 3 | 2 rings/turn | Fast melee, reaches player quickly |
| Bomber | 8 | 0 | 1 ring/turn | Explodes on death: deals 6 damage to player |
| Cultist | 4 | 2 | 1 ring/turn | Weak melee enemy, spawns in groups |

**Elite Enemies (4)**
| Enemy | HP | Damage | Speed | Behavior |
|-------|-----|--------|-------|----------|
| Shell Titan | 20 | 8 | 1 ring/turn | High HP tank with 2 armor, slow but deadly |
| Torchbearer | 10 | 2 | 1 ring/turn | Support: buffs nearby enemies +2 damage, stays at Close |
| Channeler | 12 | 3 | 1 ring/turn | Elite caster: spawns 1 Husk each turn, stays at Close |
| Stalker | 8 | 5 | 1 ring/turn | Ambush enemy, spawns directly in Close ring |

**Boss Enemies (1)**
| Enemy | HP | Damage | Speed | Behavior |
|-------|-----|--------|-------|----------|
| Ember Saint | 50 | 10 | 0 | BOSS: Stays at Far, 3 armor, AoE attacks, spawns Bombers |

---

## Detailed Artifact Definitions

### Currently Implemented (10 artifacts)
| Artifact | Rarity | Cost | Effect |
|----------|--------|------|--------|
| Quick Draw | Uncommon | 75 | Draw 1 extra card each turn |
| Iron Shell | Common | 50 | Start each wave with 3 Armor |
| Ember Charm | Uncommon | 80 | Gun cards deal +2 damage |
| Void Heart | Uncommon | 75 | Hex damage increased by 50% |
| Refracting Core | Uncommon | 70 | When you gain Armor, gain 1 extra |
| Blood Sigil | Uncommon | 80 | Heal 1 HP when you kill an enemy |
| Scavenger's Eye | Common | 60 | Gain +1 Scrap from enemy kills |
| Leech Tooth | Uncommon | 75 | Heal 2 HP at end of turn if you killed an enemy this turn |
| Hex Amplifier | Rare | 100 | Enemies with Hex take 1 damage at turn start |
| Gun Harness | Uncommon | 70 | First Gun card each turn costs 1 less Energy |

### Triple-Merge System
- Collect 3 copies of the same card at the same tier
- Merge into a stronger version (Tier 1 → 2 → 3)
- Higher tiers have improved stats

### Wardens (Playable Characters)
| Warden | Focus | Passive |
|--------|-------|---------|
| Ash Warden | Guns/Fire | +15% gun damage to Close/Melee |
| Gloom Warden | Hexes | Heal when hexed enemies die |
| Glass Warden | Defense | Survive fatal hit once per wave |

---

## Technical Architecture

### Autoloads (Singletons)
| Script | Purpose |
|--------|---------|
| `GameManager.gd` | Scene transitions, game state |
| `RunManager.gd` | Current run: HP, scrap, deck, wave |
| `CombatManager.gd` | Turn flow, card playing, enemy AI |
| `CardDatabase.gd` | All card definitions |
| `EnemyDatabase.gd` | All enemy definitions |
| `MergeManager.gd` | Triple-merge card upgrades |
| `ArtifactManager.gd` | Artifact effects |

### Key Scenes
| Scene | Path |
|-------|------|
| Main Menu | `scenes/MainMenu.tscn` |
| Warden Select | `scenes/WardenSelect.tscn` |
| Combat | `scenes/Combat.tscn` |
| Shop | `scenes/Shop.tscn` |
| Post-Wave Reward | `scenes/PostWaveReward.tscn` |
| Run End | `scenes/RunEnd.tscn` |
| Meta Menu | `scenes/MetaMenu.tscn` |

### Resource Classes
| Class | File | Purpose |
|-------|------|---------|
| CardDefinition | `scripts/resources/CardDefinition.gd` | Card stats and effects |
| EnemyDefinition | `scripts/resources/EnemyDefinition.gd` | Enemy stats and behavior |
| WardenDefinition | `scripts/resources/WardenDefinition.gd` | Character stats and passives |
| WaveDefinition | `scripts/resources/WaveDefinition.gd` | Wave spawn scripts |
| ArtifactDefinition | `scripts/resources/ArtifactDefinition.gd` | Artifact effects |

### Combat Classes
| Class | File | Purpose |
|-------|------|---------|
| BattlefieldState | `scripts/combat/BattlefieldState.gd` | Ring management, enemy tracking |
| EnemyInstance | `scripts/combat/EnemyInstance.gd` | Runtime enemy state |
| DeckManager | `scripts/combat/DeckManager.gd` | Deck, hand, discard zones |
| CardEffectResolver | `scripts/combat/CardEffectResolver.gd` | Execute card effects |

---

## Current Implementation Status

### ✅ Fully Working
- Main Menu → Warden Select → Combat flow
- Turn system (draw, play, enemy phase)
- Ring battlefield with enemy movement
- BattlefieldArena renders concentric rings, centered warden icon, animated enemy panels, hover tooltips with HP/damage/speed/intent, and now keeps the arena centered on screen while scaling the play space + enemy panels to fill the available area
- Card playing with all effect types (damage, heal, armor, hex, push, draw, etc.)
- 26 cards across 4 types (Weapons, Skills, Hexes, Defense)
- 10 enemies across 3 types (Grunts, Elites, Boss)
- 10 artifacts with various trigger types
- Enemy spawning from wave definitions
- Damage system (player and enemies)
- Visual polish (particles, shake, banners)
- CardEffectResolver with 18 effect types

### 🔶 Partially Implemented
- **MergeManager**: Structure exists, no UI integration
- **Artifact triggers**: Artifacts defined but not all trigger types hooked into combat

### ❓ Untested
- Shop scene (`scenes/Shop.tscn`)
- Post-Wave Reward scene (`scenes/PostWaveReward.tscn`)
- Run End scene (`scenes/RunEnd.tscn`)
- Meta Menu scene (`scenes/MetaMenu.tscn`)
- Full game loop (win wave → reward → shop → next wave)

### ❌ Not Implemented
- Sound effects
- Warden passive abilities (code exists but not wired)
- Meta progression save/load
- Enemy special abilities (bomber explosion, channeler spawning, torchbearer buffs)

---

## What Needs To Be Done

### Priority 1: Test Full Game Loop ⬅️ CURRENT
1. Win a wave → should go to PostWaveReward
2. Pick reward → should go to Shop
3. Leave shop → should start next wave
4. Reach wave 12 → boss fight
5. Win/lose → RunEnd screen

### Priority 2: Wire Enemy Special Abilities
- **Bomber**: Explode on death, deal damage to player
- **Channeler**: Spawn Husks each turn
- **Torchbearer**: Buff nearby enemy damage
- **Stalker**: Spawn directly in Close ring (handled by WaveDefinition)

### Priority 3: Wire Artifact Triggers
- Hook artifact triggers into CombatManager:
  - `on_turn_start`: Quick Draw, Hex Amplifier
  - `on_turn_end`: Leech Tooth
  - `on_kill`: Blood Sigil, Scavenger's Eye
  - `on_wave_start`: Iron Shell
  - `on_card_play`: Ember Charm, Refracting Core

### Priority 4: Polish
- Sound effects for card play, damage, death
- More particle effects
- Screen transitions
- Warden passive abilities

---

## How to Test

### Quick Test (Headless)
```bash
godot --headless --path "." "res://scenes/Combat.tscn"
```

### Visual Test
1. Open project in Godot 4.5+
2. Press F5
3. New Run → Select Warden → Start
4. Play cards, end turns, watch enemies

### Check for Errors
```bash
godot --headless --check-only --path "."
```

---

## File Structure
```
DeckHorde/
├── scenes/
│   ├── MainMenu.tscn
│   ├── WardenSelect.tscn
│   ├── Combat.tscn
│   ├── BattlefieldArena.tscn
│   ├── Shop.tscn
│   ├── PostWaveReward.tscn
│   ├── RunEnd.tscn
│   ├── MetaMenu.tscn
│   └── ui/
│       └── CardUI.tscn
├── scripts/
│   ├── autoloads/
│   │   ├── GameManager.gd
│   │   ├── RunManager.gd
│   │   ├── CombatManager.gd
│   │   ├── CardDatabase.gd
│   │   ├── EnemyDatabase.gd
│   │   ├── MergeManager.gd
│   │   └── ArtifactManager.gd
│   ├── resources/
│   │   ├── CardDefinition.gd
│   │   ├── EnemyDefinition.gd
│   │   ├── WardenDefinition.gd
│   │   ├── WaveDefinition.gd
│   │   └── ArtifactDefinition.gd
│   ├── combat/
│   │   ├── BattlefieldState.gd
│   │   ├── BattlefieldArena.gd
│   │   ├── EnemyInstance.gd
│   │   ├── DeckManager.gd
│   │   └── CardEffectResolver.gd
│   └── ui/
│       ├── MainMenu.gd
│       ├── WardenSelect.gd
│       ├── CombatScreen.gd
│       ├── CardUI.gd
│       ├── Shop.gd
│       ├── PostWaveReward.gd
│       ├── RunEnd.gd
│       └── MetaMenu.gd
├── data/
│   ├── cards/
│   ├── enemies/
│   ├── wardens/
│   ├── waves/
│   └── artifacts/
├── textures/
├── project.godot
├── AGENTS.md          # Agent guidelines
├── DESIGN.md          # This file
└── PROGRESS.md        # Status tracker
```

---

## Agent Quick Start

### To add a new card:
1. Open `scripts/autoloads/CardDatabase.gd`
2. Find `_create_default_cards()` function
3. Copy an existing card block and modify
4. Test with `godot --headless --check-only --path "."`

### To add a new enemy:
1. Open `scripts/autoloads/EnemyDatabase.gd`
2. Find `_create_default_enemies()` function
3. Copy an existing enemy block and modify
4. Test headless

### To fix a bug:
1. Run `godot --headless --path "." "res://scenes/[Scene].tscn" 2>&1`
2. Read error output
3. Fix the indicated file/line
4. Re-test

### To test full game:
1. Open Godot editor
2. F5 to run
3. Play through Main Menu → Warden Select → Combat

