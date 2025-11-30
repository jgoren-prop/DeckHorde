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

#### Enemy Display System (Horde Handling)
When many enemies spawn in the same ring, the system uses two strategies to prevent overlap:

**Multi-Row Distribution** (5-8 enemies in a ring):
- Enemies are distributed across inner (35% depth) and outer (75% depth) rows within the ring
- This doubles the visual capacity without changing gameplay

**Overflow Stacking** (3+ of same enemy type):
- Identical enemies collapse into a single "stack" panel with count badge (e.g., "x5")
- Stack shows aggregate HP bar and "total HP" text
- **Expand on Hover**: Hovering a stack fans out mini-panels showing each enemy's individual HP
- **Damage Feedback**: When stacked enemy takes damage, stack briefly expands to show which one was hit
- Mini-panels support hover for full enemy tooltip and individual targeting

**Constants** (in `BattlefieldArena.gd`):
- `MAX_ENEMIES_BEFORE_MULTIROW = 4` — Use single row up to this count
- `MAX_TOTAL_BEFORE_STACKING = 2` — Stacking kicks in when 3+ enemies present
- `STACK_THRESHOLD = 3` — Minimum same-type enemies to form a stack

### Turn Structure
1. **Draw Phase** - Draw cards to hand (5 by default)
2. **Player Phase** - Play cards using Energy (3 by default)
3. **Enemy Phase** - Enemies move inward and attack
4. **Wave Check** - Win if all enemies dead, lose if player HP reaches 0

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

## Card UI Specification

### Card Layout (170x260 pixels)

```
┌─────────────────────────────┐
│ [1] Card Name Here      T2  │  ← Header: Cost, Name, Tier
├─────────────────────────────┤
│           ⚔️                │  ← Type Icon (large)
│                             │
│  ┌───────────────────────┐  │
│  │   EFFECT STATS ROW    │  │  ← Stats: DMG/HEX/HEAL/ARMOR
│  │   ⚔ 4    ☠ 0    ♥ 0  │  │
│  └───────────────────────┘  │
│                             │
│  Card description text      │  ← Description (flavor text)
│  explaining what it does.   │
│                             │
├─────────────────────────────┤
│  🎯 1 Random │ ALL Rings    │  ← Target Row
├─────────────────────────────┤
│  ⚡ INSTANT    │ gun, fire   │  ← Footer: Timing Badge + Tags
└─────────────────────────────┘
```

### UI Components

#### 1. Header Row
| Element | Display | Example |
|---------|---------|---------|
| Cost | Energy cost in circle | `[1]`, `[2]`, `[0]` |
| Name | Card name | "Infernal Pistol" |
| Tier | If Tier 2+, show badge | "T2", "T3" |

#### 2. Type Icon (Center)
Large emoji/icon based on card type:
| Type | Icon | Color Tint |
|------|------|------------|
| Weapon | ⚔️ | Red/Orange |
| Skill | ✨ | Blue |
| Hex | ☠️ | Purple |
| Defense | 🛡️ | Green |
| Curse | 💀 | Gray |

#### 3. Effect Stats Row
Compact display of card's numeric effects. Only show non-zero values:

| Stat | Icon | Color | Example |
|------|------|-------|---------|
| Damage | ⚔ | Red | `⚔ 4` |
| Hex | ☠ | Purple | `☠ 3` |
| Heal | ♥ | Green | `♥ 5` |
| Armor | 🛡 | Cyan | `🛡 3` |
| Draw | 📜 | Blue | `📜 1` |
| Energy | ⚡ | Yellow | `⚡ +1` |

**Examples:**
- Infernal Pistol: `⚔ 4`
- Blood Bolt: `⚔ 5  ♥ 2`
- Soul Rend: `⚔ 3  ☠ 5`
- Adrenaline: `⚡ +1  📜 1`

#### 4. Target Row
Shows what the card hits. Two parts: **Scope** and **Rings**

**Scope Options:**
| Code | Display | Meaning |
|------|---------|---------|
| `random_enemy` + count=1 | `🎯 1 Random` | Hits 1 random enemy |
| `random_enemy` + count=3 | `🎯 3 Random` | Hits 3 random enemies |
| `ring` + requires_target=false | `🎯 Ring (auto)` | Hits all in fixed ring(s) |
| `ring` + requires_target=true | `🎯 Ring (choose)` | Player picks ring |
| `all_enemies` | `🎯 ALL Enemies` | Hits every enemy |
| `self` | `🎯 Self` | Affects player |

**Ring Display:**
| Rings | Display |
|-------|---------|
| [0] | `M` (Melee) |
| [1] | `C` (Close) |
| [2] | `D` (Mid/Distance) |
| [3] | `F` (Far) |
| [0,1] | `M C` |
| [0,1,2,3] | `ALL` |
| [1,2,3] | `C D F` |

**Combined Examples:**
| Card | Target Row Display |
|------|-------------------|
| Infernal Pistol | `🎯 1 Random │ ALL` |
| Choirbreaker Shotgun | `🎯 Ring (auto) │ C` |
| Ember Grenade | `🎯 Ring (choose) │ ALL` |
| Scatter Shot | `🎯 3 Random │ ALL` |
| Soul Rend | `🎯 1 Random │ M` |
| Flamethrower | `🎯 Ring (auto) │ M C` |
| Plague Cloud | `🎯 ALL Enemies` |
| Glass Ward | `🎯 Self` |

#### 5. Footer Row (Timing + Tags)

**Timing Badges:**
| Timing | Badge | Color | When |
|--------|-------|-------|------|
| Instant | `⚡ INSTANT` | White | Effect happens once on play |
| Persistent | `🔁 PERSISTENT` | Gold | Stays in play, triggers each turn |
| Buff | `✦ BUFF` | Blue | Modifies future actions this turn |

**Tags:**
Small gray text showing card tags: `gun`, `fire`, `hex`, `armor`, etc.

### Complete Card Examples

#### Infernal Pistol (Weapon)
```
┌─────────────────────────────┐
│ [1] Infernal Pistol         │
├─────────────────────────────┤
│           ⚔️                │
│         ⚔ 4                 │
│                             │
│  Fires at a random enemy    │
│  at the start of each turn. │
│                             │
├─────────────────────────────┤
│  🎯 1 Random │ ALL          │
├─────────────────────────────┤
│  🔁 PERSISTENT │ gun        │
└─────────────────────────────┘
```

#### Blood Bolt (Weapon)
```
┌─────────────────────────────┐
│ [1] Blood Bolt              │
├─────────────────────────────┤
│           ⚔️                │
│       ⚔ 5    ♥ 2            │
│                             │
│  Drain life from a random   │
│  enemy.                     │
│                             │
├─────────────────────────────┤
│  🎯 1 Random │ ALL          │
├─────────────────────────────┤
│  ⚡ INSTANT │ gun, lifesteal│
└─────────────────────────────┘
```

#### Simple Hex (Hex)
```
┌─────────────────────────────┐
│ [1] Simple Hex              │
├─────────────────────────────┤
│           ☠️                │
│         ☠ 3                 │
│                             │
│  Curse all enemies in the   │
│  targeted ring.             │
│                             │
├─────────────────────────────┤
│  🎯 Ring (choose) │ ALL     │
├─────────────────────────────┤
│  ⚡ INSTANT │ hex           │
└─────────────────────────────┘
```

#### Barrier Sigil (Defense)
```
┌─────────────────────────────┐
│ [1] Barrier Sigil           │
├─────────────────────────────┤
│           🛡️                │
│       ⚔ 4    ⏱ 2            │
│                             │
│  Create barrier: enemies    │
│  crossing take damage.      │
│                             │
├─────────────────────────────┤
│  🎯 Ring (choose) │ C D F   │
├─────────────────────────────┤
│  ⚡ INSTANT │ barrier       │
└─────────────────────────────┘
```

### Color Scheme

**Card Background by Type:**
| Type | Background | Border |
|------|------------|--------|
| Weapon | Dark Red `#2a1515` | Red `#e66450` |
| Skill | Dark Blue `#151a2a` | Blue `#50a0e6` |
| Hex | Dark Purple `#1f152a` | Purple `#9050e6` |
| Defense | Dark Green `#152a1f` | Green `#50e690` |

**Tier Border Colors:**
| Tier | Border Color |
|------|--------------|
| Tier 1 | Gray `#b0b0b0` |
| Tier 2 | Blue `#4d99ff` |
| Tier 3 | Gold `#ffcc33` |

### Implementation Notes

1. **Stats Row**: Use `HBoxContainer` with icons + labels, hide if value is 0
2. **Target Row**: Generate text from `target_type`, `target_rings`, `requires_target`, `target_count`
3. **Timing Badge**: Check `effect_type == "weapon_persistent"` for persistent, check for buff types
4. **Ring Display**: Convert ring array `[0,1,2,3]` to letters `M C D F` or `ALL` if all 4

---

## Detailed Card Definitions

### Card Description System

Cards now display explicit effect labels in their description area:

**Instant Effects** (blue): `[color=#88ddff]Instant:[/color] Effect text`
- Displayed when card has an `instant_description` field set
- Or auto-generated based on `effect_type` for backward compatibility

**Persistent Effects** (gold): `[color=#ffcc55]Persistent:[/color] Effect text`
- Displayed when card has a `persistent_description` field set
- Shows for `weapon_persistent` cards automatically if no explicit description

**Cards with Both Effects:**
Cards can have both `instant_description` AND `persistent_description` set to show:
```
Instant: Deal 3 to a random enemy.
Persistent: Deal 2 to a random enemy at turn start.
```

**Placeholders in descriptions:**
- `{damage}` - Scaled damage value
- `{hex_damage}` - Scaled hex value
- `{heal_amount}` - Scaled heal value
- `{armor}` - Scaled armor value
- `{duration}` - Scaled duration value
- `{draw}` - Cards to draw
- `{target_count}` - Number of targets

### Currently Implemented (27 cards)

**Weapons (9 cards)**
| Card | Cost | Stats | Target | Timing | Tags |
|------|------|-------|--------|--------|------|
| Infernal Pistol | 1 | ⚔4 | 1 Random / ALL | 🔁 Persistent | gun |
| Choirbreaker Shotgun | 1 | ⚔6 | Ring (auto) / C | ⚡ Instant | gun |
| Riftshard Rifle | 2 | ⚔8 | 1 Random / F | ⚡ Instant | gun |
| Ember Grenade | 2 | ⚔4 | Ring (choose) / ALL | ⚡ Instant | explosive |
| Void Revolver | 1 | ⚔3 📜1 | 1 Random / ALL | ⚡ Instant | gun |
| Scatter Shot | 1 | ⚔2 | 3 Random / ALL | ⚡ Instant | gun |
| Blood Bolt | 1 | ⚔5 ♥2 | 1 Random / ALL | ⚡ Instant | gun, lifesteal |
| Flamethrower | 2 | ⚔3 | Ring (auto) / M C | ⚡ Instant | fire |
| Rift Turret | 2 | ⚔3 | 1 Random / ALL | ⚡+🔁 Both | gun, persistent |

**Skills (6 cards)**
| Card | Cost | Stats | Target | Timing | Tags |
|------|------|-------|--------|--------|------|
| Emergency Medkit | 1 | ♥5 | Self | ⚡ Instant | heal |
| Adrenaline | 1 | ⚡+1 📜1 | Self | ⚡ Instant | utility |
| Second Wind | 2 | ♥8 | Self | ⚡ Instant | heal |
| Ritual Focus | 0 | ✦2x Hex | Self | ✦ Buff | hex, utility |
| Gambit | 1 | 📜5 | Self | ⚡ Instant | utility |
| Quick Strike | 0 | ⚔2 | 1 Random / ALL | ⚡ Instant | attack |

**Hexes (6 cards)**
| Card | Cost | Stats | Target | Timing | Tags |
|------|------|-------|--------|--------|------|
| Simple Hex | 1 | ☠3 | Ring (choose) / ALL | ⚡ Instant | hex |
| Mark of Gloom | 1 | ☠4 | 1 Random / ALL | ⚡ Instant | hex |
| Plague Cloud | 2 | ☠2 | ALL Enemies | ⚡ Instant | hex |
| Wither | 1 | ☠3 | Ring (auto) / M C | ⚡ Instant | hex |
| Cheap Curse | 0 | ☠2 | 1 Random / ALL | ⚡ Instant | hex |
| Soul Rend | 2 | ⚔3 ☠5 | 1 Random / M | ⚡ Instant | hex |

**Defense (6 cards)**
| Card | Cost | Stats | Target | Timing | Tags |
|------|------|-------|--------|--------|------|
| Glass Ward | 1 | 🛡3 | Self | ⚡ Instant | armor |
| Iron Bastion | 2 | 🛡6 | Self | ⚡ Instant | armor |
| Barrier Sigil | 1 | ⚔4 ⏱2 | Ring (choose) / C D F | ⚡ Instant | barrier |
| Draining Shield | 1 | 🛡3 ♥? | Self | ⚡ Instant | armor, lifesteal |
| Repulsion | 1 | ↗1 | Ring (auto) / M | ⚡ Instant | crowd_control |
| Shield Bash | 1 | ⚔=🛡 | 1 Random / M | ⚡ Instant | armor, attack |

**Legend:**
- **Stats**: ⚔=Damage, ☠=Hex, ♥=Heal, 🛡=Armor, 📜=Draw, ⚡=Energy, ⏱=Duration, ↗=Push
- **Rings**: M=Melee, C=Close, D=Mid, F=Far, ALL=All rings
- **Timing**: ⚡Instant=On play, 🔁Persistent=Each turn, ✦Buff=Modifies next action

---

## Detailed Enemy Definitions

### Currently Implemented (10 enemies)

**Grunt Enemies (5)**
| Enemy | HP | Damage | Speed | Badge | Behavior |
|-------|-----|--------|-------|-------|----------|
| Husk | 8 | 4 | 1 ring/turn | 🏃 RUSHER | Basic melee, walks toward player |
| Spitter | 6 | 3 | 1 ring/turn | 🏹 RANGED | Ranged, stops at Mid ring, attacks from there |
| Spinecrawler | 6 | 3 | 2 rings/turn | ⚡ FAST | Fast melee, reaches player quickly |
| Bomber | 8 | 0 | 1 ring/turn | 💣 BOMBER | Explodes on death: deals 6 damage to player |
| Cultist | 4 | 2 | 1 ring/turn | 🏃 RUSHER | Weak melee enemy, spawns in groups |

**Elite Enemies (4)**
| Enemy | HP | Damage | Speed | Badge | Behavior |
|-------|-----|--------|-------|-------|----------|
| Shell Titan | 20 | 8 | 1 ring/turn | 🛡️ TANK | High HP tank with 2 armor, slow but deadly |
| Torchbearer | 10 | 2 | 1 ring/turn | 📢 BUFFER | Support: buffs nearby enemies +2 damage, stays at Close |
| Channeler | 12 | 3 | 1 ring/turn | ⚙️ SPAWNER | Elite caster: spawns 1 Husk each turn, stays at Close |
| Stalker | 8 | 5 | 1 ring/turn | 🗡️ AMBUSH | Ambush enemy, spawns directly in Close ring |

**Boss Enemies (1)**
| Enemy | HP | Damage | Speed | Badge | Behavior |
|-------|-----|--------|-------|-------|----------|
| Ember Saint | 50 | 10 | 0 | 👑 BOSS | BOSS: Stays at Far, 3 armor, AoE attacks, spawns Bombers |

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
| `SettingsManager.gd` | User settings persistence (audio, display, gameplay) |
| `GameManager.gd` | Scene transitions, game state |
| `RunManager.gd` | Current run: HP, scrap, deck, wave |
| `CombatManager.gd` | Turn flow, card playing, enemy AI |
| `CardDatabase.gd` | All card definitions |
| `EnemyDatabase.gd` | All enemy definitions |
| `MergeManager.gd` | Triple-merge card upgrades |
| `ArtifactManager.gd` | Artifact effects |
| `AudioManager.gd` | Sound effect handling |
| `CombatAnimationManager.gd` | Combat visual effects and animation sequencing |

### Key Scenes
| Scene | Path |
|-------|------|
| Main Menu | `scenes/MainMenu.tscn` |
| Settings | `scenes/Settings.tscn` |
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
- Enemy display system with multi-row distribution (5-8 enemies use inner/outer rows) and overflow stacking (9+ enemies of same type collapse into "x5" stacks)
- Stack panels expand on hover to show individual enemy HP bars for tactical targeting
- Damage feedback on stacked enemies shows brief expand animation with flashing mini-panel
- Card playing with all effect types (damage, heal, armor, hex, push, draw, etc.)
- 27 cards across 4 types (Weapons, Skills, Hexes, Defense)
- 10 enemies across 3 types (Grunts, Elites, Boss)
- 10 artifacts with various trigger types, ALL hooked into combat
- Enemy spawning from wave definitions
- Damage system (player and enemies)
- Visual polish (particles, shake, banners)
- CardEffectResolver with 18 effect types
- **Enemy special abilities**: Bomber explosion (6 damage on death), Channeler spawns Husks, Torchbearer buffs +2 damage, Ember Saint spawns Bombers
- **All 10 artifact triggers wired**: on_turn_start (Quick Draw, Hex Amplifier), on_wave_start (Iron Shell), on_card_play (Ember Charm, Refracting Core), on_kill (Blood Sigil, Scavenger's Eye), on_turn_end (Leech Tooth), passive (Void Heart hex mult, Gun Harness cost reduction)
- **All 3 Warden passives implemented**:
  - Ash Warden: Gun cards deal +15% damage to Close/Melee rings
  - Gloom Warden: Heal 1 HP when hexed enemies die
  - Glass Warden: Survive fatal hit once per wave at 1 HP

### ✅ Fully Implemented
- **MergeManager**: Full triple-merge system with shop UI integration
- **AudioManager**: Procedural placeholder SFX for all game events
- **Screen Transitions**: Fade effects on scene changes via GameManager
- **Combat Clarity System**: Three-layer UX system to reduce cognitive overload:
  - **Behavior Badges**: Each enemy panel shows an archetype badge (🏃⚡🏹💣📢⚙️🛡️🗡️👑) in top-left corner
  - **Ring Threat Colors**: Ring borders change color based on threat level (green/yellow/orange/red, pulses red for lethal damage)
  - **Aggregated Intent Bar**: Top bar shows: ⚔️ incoming damage, 💣 bomber count, 📢 buff status, ⚙️ spawner status, ⚡ fast enemy count
- **Combat Visual Feedback System**: Slay the Spire-style telegraphed animations:
  - **Attack Indicators**: Target reticles (┌┐└┘) pulse around enemies before they're hit
  - **Projectile Effects**: Bullets fly from warden to targets with trailing effects
  - **Enemy Shake**: Hit enemies shake with intensity based on damage dealt
  - **Hex Flash**: Purple flash when hex damage triggers
  - **Stack Expansion**: When attacking grouped enemies, stack expands to show which one was hit
  - **Card Fly Animation**: Cards animate flying from hand to target position when played
  - **Weapon Icons**: Active persistent weapons shown as icons (not just text) with fire animations
  - **Barrier Visuals**: Ring barriers shown with pulsing green glow, icons (🚧), and damage/duration stats

### ❓ Untested
- Meta Menu scene (`scenes/MetaMenu.tscn`)

### ❌ Not Implemented
- Meta progression save/load
- Real audio files (currently using procedural placeholders)

### Settings System
**SettingsManager** (`scripts/autoloads/SettingsManager.gd`) handles persistent user settings:

| Category | Settings |
|----------|----------|
| Audio | Master Volume (0-100%), SFX Volume (0-100%), Music Volume (0-100%), Mute All |
| Gameplay | Screen Shake (on/off), Damage Numbers (on/off), Auto End Turn (on/off) |
| Display | Fullscreen (on/off), VSync (on/off) |

Settings are saved to `user://settings.cfg` and loaded automatically on game start. The Settings scene (`scenes/Settings.tscn`) provides a UI for adjusting all options with immediate feedback.

---

## What Needs To Be Done

### ✅ COMPLETED - Full Game Loop
1. ✅ Win a wave → goes to PostWaveReward
2. ✅ Pick reward → goes to Shop
3. ✅ Leave shop → starts next wave
4. ✅ Reach wave 12 → boss fight
5. ✅ Win/lose → RunEnd screen

### ✅ COMPLETED - Enemy Special Abilities
- **Bomber**: ✅ Explodes on death, deals 6 damage to player
- **Channeler**: ✅ Spawns 1 Husk each turn at Far ring (when at target ring)
- **Torchbearer**: ✅ Buffs nearby enemy damage +2 (when at target ring)
- **Ember Saint**: ✅ Spawns 1 Bomber each turn at Far ring
- **Stalker**: ✅ Spawn directly in Close ring (handled by WaveDefinition)

### ✅ COMPLETED - Artifact Triggers
All 10 artifacts are wired into CombatManager:
- `on_turn_start`: Quick Draw (draw +1), Hex Amplifier (1 damage to hexed)
- `on_turn_end`: Leech Tooth (heal 2 if killed this turn)
- `on_kill`: Blood Sigil (heal 1), Scavenger's Eye (+1 scrap)
- `on_wave_start`: Iron Shell (gain 3 armor)
- `on_card_play`: Ember Charm (+2 gun damage), Refracting Core (+1 armor)
- `passive`: Void Heart (hex +50%), Gun Harness (first gun -1 cost)

### ✅ COMPLETED - Warden Passives
All 3 Warden passives are implemented:
- **Ash Warden**: Gun cards deal +15% damage to Close/Melee rings
- **Gloom Warden**: Heal 1 HP when hexed enemies die
- **Glass Warden**: Survive fatal hit once per wave (reset each wave)

### ✅ COMPLETED - Polish
- ✅ Sound effects via AudioManager (procedural placeholders)
- ✅ Screen transitions (fade effect in GameManager)
- ✅ Death burst particles

### ✅ COMPLETED - MergeManager UI
- ✅ Triple-merge UI integrated into Shop screen
- ✅ "Available Merges" section shows when 3+ copies exist
- ✅ Merge/Decline buttons with scrap cost

### Priority 1: Balance & Content ⬅️ NEXT
- Tune difficulty curve
- Test all wave compositions
- Verify artifact and warden balance

### Priority 2: Real Audio Assets
- Replace procedural SFX with real audio files
- Add background music

### Priority 3: Meta Progression
- Save/load system for unlocks
- Meta Menu functionality

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

